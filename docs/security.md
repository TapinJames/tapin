# Security — authentication, authorization, secrets, mobile

Owner: tech-lead chat. v01 (2026-08-25). An AppSec engineer reviews this before week 5; pilot-scope pentest before go-live.

## Principles
Clients are untrusted. Authorization is decided by the database (RLS) and by Edge Functions running with the service role — never by the app or the browser. Secrets exist only on the server. Every table with student data has RLS and a test proving a teacher cannot read another teacher's section.

## Identities and roles
- **Staff (teacher, school_admin, district_admin):** Supabase Auth users (email magic link now; SSO later). Role and scope come from `people` (`role`, `school_id`, `district_id`) joined on `auth_user_id` — never from the client.
- **Students:** no email, no password. At class-code join, the `join` function creates the `people` row (if the teacher's roster has the name) and a `devices` row, and returns a **device credential** — a random 256-bit secret; the server stores only its hash. The app stores it in the Keychain. Every call from the phone presents it; functions resolve `device → person → enrollments`. Rotation: re-join with a new class code; revocation: teacher removes the device.
- **Service role:** Edge Functions only. Never in a client, never in CI logs.

## Row Level Security (v1 policy sketch)
- `people`, `enrollments`, `attendance`, `taps`, `lock_sessions`, `alerts`: teacher → rows where the section has a teacher enrollment for `auth.uid()`; school_admin → same `school_id`; district_admin → same `district_id`; student devices never query these tables directly (they go through functions).
- `policies`, `app_catalog`: readable by staff of the school; `app_catalog` global read-only.
- `audit_log`, `taps`: insert-only for staff; no update/delete except service.
- Tests: `supabase/tests/rls.test.sql` — for each table, a cross-tenant read returns zero rows.

## Functions (server-side rules)
- `tap`: verifies the tag (SDM signature + counter for NTAG 424 DNA; plain id for dev tags with a `dev` flag on the school), resolves the section from the tag's room + the day's bell schedule, upserts `attendance`, inserts `taps` and `lock_sessions` in one transaction, returns the policy. Rejects replays (counter), unknown tags, devices not enrolled in any section in that room at that time.
- `status`: device reports `screentime_*` / `vpn_*`; the function writes `devices` + opens/resolves `alerts`. Rate-limited per device.
- `unlock`: staff only; checks the caller teaches the section; marks sessions; sends silent pushes.
- `policy`: staff edits Blocked/Approved; compiles bundle ids + domains from `app_catalog`; new `policies` row; audit entry.
- Input validation on every function (typed schema); consistent error shape `{error: {code, message}}`; no stack traces or SQL to clients.

## Secrets
- Supabase service role key, NTAG 424 DNA keys, APNs key, FCM key: Supabase project secrets (`supabase secrets set`) — never in git, never in the app.
- Supabase **anon** key + project URL: public by design (RLS protects); shipped in apps and the web bundle.
- `.env.example` lists variable names only. CI runs a secret scanner on every PR. `.gitignore` blocks `.env*`, `*.p8`, `*.p12`, `*.mobileprovision`, `*.keystore`.
- Admin accounts (Supabase, Vercel, Apple, GitHub): MFA on; hardware keys when James adopts them.

## Mobile
- Device credential in Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`); nothing sensitive in UserDefaults or logs.
- No API secrets in the binary. The app can be decompiled; assume everything in it is public.
- Transport: HTTPS only; ATS default. Pin nothing in v1 (rotation risk outweighs benefit for the pilot).
- Push: silent pushes carry no student data — only "check in" / "policy changed" / "unlocked".

## Web
- Supabase Auth session in httpOnly cookies via `@supabase/ssr`; magic-link expiry 10 minutes; sessions 12 hours for staff.
- Content-Security-Policy, no inline scripts beyond Next.js defaults; CSRF covered by same-site cookies + Supabase JWT.
- Destructive actions (remove student, delete section, change policy) require a confirmation and write `audit_log`.

## Abuse cases to test before pilot
Tag photographed and replayed (SDM counter) · device credential copied to another phone (bound to `device_id`; one active device per person per platform) · teacher A reads teacher B's class (RLS) · student calls `unlock` (staff-only) · flood of `status` calls (rate limit) · malformed CSV upload (size + schema validation) · deleted student still tapping (device revoked at removal).

## Incident basics (pilot)
Rotate: Supabase keys (project settings), device credentials (force re-join), APNs key. Contact: James (Google Voice line for teachers). Log: Sentry + Supabase logs, request ids on every function call. Write the fuller incident-response runbook before go-live (`docs/runbooks/`).

# Privacy — what we store, what we don't, retention, deletion

Owner: tech-lead chat. v01 (2026-08-25). This describes technical controls. It is not a legal opinion; an education/privacy attorney reviews the district data privacy agreement and the parent letter before any school uses the product. Never claim "FERPA compliant" or "COPPA compliant" in code, docs or UI — say the architecture supports the controls typically required.

## What we store about a student
Name · school · section(s) · device platform + app version · tap times · lock-session state · exemption flag (true/false only) · alert events (bypass on/off). That is the whole list.

## What we deliberately do not store
Date of birth · address · phone number · email (students) · parent details · demographics · grades · location (a tap is "this tag, this time" — the tag is a room, not GPS) · which apps were opened · DNS queries or browsing (the VPN filters on the phone and logs nothing) · message content · photos.

## Data minimization rules for code
- Rostering imports only `first_name`, `last_name`, section membership, and an external id. Clever provides more; we don't persist it (`roster-and-clever.md`).
- Logs (Sentry, function logs) carry ids and request ids, never names next to device ids, never tokens.
- Analytics = counts and rates computed in the database; no per-student analytics leave the district's dashboard.
- Exemption reason is never recorded anywhere — the flag is enough for the product.

## Access
Teacher: own sections. School admin: own school. District admin: own district. Tap in staff (James): only through the service role for support, every such access written to `audit_log`. Students see only themselves in the app.

## Retention (v1 defaults, district-adjustable later)
- `taps`, `lock_sessions`, `alerts`: 13 months (one school year + a term), then deleted by a scheduled job.
- `attendance`: kept for the district per its records policy (SIS is the system of record once write-back exists); default 13 months in Tap in.
- `audit_log`: 3 years.
- Sentry events: 30 days; no PII in them.
- Backups: Supabase daily backups (7 days on Pro); deleted rows leave backups when the backup window rolls.

## Deletion workflows (design before launch; build in week 6)
- **Remove a student:** `remove_person(person_id)` — deletes devices (revoking credentials), enrollments, lock_sessions, alerts; anonymizes `taps`/`attendance` rows (person_id → null, keeps counts) or deletes them per district instruction; writes `audit_log`.
- **Remove a section / school / district:** cascade in that order; district offboarding exports a CSV for the district first, then deletes.
- **"What do you have about my child?"** — `export_person(person_id)` returns every row keyed to the person as CSV; runs in seconds.
- **SIS deprovisioning (later):** a student missing from a sync → enrollments end-dated; person removed after the retention window.

## Third parties (pilot)
Supabase (database/hosting, US region), Vercel (dashboards), Apple/Google (push, app distribution), Sentry (errors, no PII), Google Voice (support line). Each gets the minimum. No AI provider receives student data. No advertising or analytics SDKs in the apps.

## Parent-facing sentence (for the letter, attorney to confirm)
"Tap in records when your student taps into class and whether class mode is on. It does not track location, does not see what your student does on the phone, and never blocks calls or texts."

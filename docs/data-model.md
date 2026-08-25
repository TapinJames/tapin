# Data model v1 — entities and rules

Owner: tech-lead chat. Draft for the SQL migration in T-005 (week 2). Every table has `id uuid primary key default gen_random_uuid()`, `created_at timestamptz default now()`, and — for tenant tables — `district_id` for Row Level Security. External identifiers (Clever, Genesis) are columns, never primary keys.

## Tenancy

```
district → school → section (a class meeting in a room, bounded by a term)
                 └→ person (student | teacher | school_admin) ; district_admin at district level
section → enrollment (person × section, role student|teacher)
school  → bell_schedule → period (P1 8:00–8:50 …) ; school day variants (early dismissal, assembly)
school  → room → tag (NFC tag id, key reference, status)
```

## Tables (v1)

| Table | Purpose | Key columns | Notes |
|---|---|---|---|
| `districts` | tenant root | `name`, `state` | |
| `schools` | | `district_id`, `name`, `short_name`, `grades`, `timezone` | |
| `people` | students, teachers, admins | `district_id`, `school_id` (null for district admins), `role`, `first_name`, `last_name`, `auth_user_id` (nullable), `external_ids jsonb` (`{clever: "...", genesis: "..."}`) | **Minimal:** no DOB, email only for staff, no addresses, no demographics |
| `sections` | a class | `school_id`, `name` ("Biology I"), `period_no`, `room_id`, `term_start`, `term_end`, `class_code` (unique, rotating) | |
| `enrollments` | who is in a section | `section_id`, `person_id`, `role` (`student`/`teacher`), `exempt boolean` (504/IEP/medical — a flag, never the reason) | **Unique (section_id, person_id)** |
| `bell_schedules` / `periods` | school day structure | `school_id`, `name` (Regular / Early dismissal), `is_default`; periods: `period_no`, `label`, `starts`, `ends` | `sections.period_no` resolves against the day's schedule |
| `school_days` | which schedule applies on a date | `school_id`, `date`, `bell_schedule_id`, `is_school_day` | seeded from the calendar; default Regular |
| `rooms` | | `school_id`, `name` ("214") | |
| `tags` | NFC tags | `school_id`, `room_id`, `tag_uid`, `kind` (`ntag215`/`ntag424dna`), `key_ref` (name of the server secret, never the key), `sdm_counter` (last accepted counter, replay protection), `status` (`healthy`/`failing`/`retired`), `installed_at` | |
| `devices` | student phones | `person_id`, `platform` (`ios`/`android`), `token_hash` (device credential hash), `push_token`, `screen_time_status` (`granted`/`revoked`/`unavailable`/`unknown`), `vpn_status` (`on`/`off`/`not_installed`/`unknown`), `app_version`, `last_seen_at` | one person may have several devices; the *current* one is the last seen |
| `taps` | the event | `tag_id`, `device_id`, `person_id`, `section_id` (resolved), `tapped_at` (server time), `client_time`, `result` (`in`/`late`/`no_section`/`replay`/`unknown_tag`), `sdm_counter` | append-only |
| `attendance` | one row per person × section × school day | `section_id`, `person_id`, `date`, `status` (`present`/`tardy`/`absent`/`manual_present`), `source` (`tap`/`teacher`/`sis`), `first_tap_id` | **Unique (section_id, person_id, date)**; the dashboard's Attendance pill |
| `lock_sessions` | the "apps locked until 9:50" state | `device_id`, `section_id`, `date`, `starts_at`, `ends_at`, `state` (`locked`/`unlocked_by_teacher`/`bypassed`/`ended`), `policy_version` | the Compliance pill |
| `policies` | per-school blocking policy | `school_id`, `version`, `blocked_apps jsonb` (catalog ids), `approved_apps jsonb`, `blocked_domains text[]`, `compiled jsonb` (`{ios_bundle_ids:[…], domains:[…]}`), `updated_by`, `updated_at` | new row per change; phones cache by `version` |
| `app_catalog` | our maintained list of apps | `name`, `category` (`social`/`games`/`streaming`/`shopping`/`education`/`utility`), `ios_bundle_id`, `android_package`, `domains text[]`, `default_blocked boolean` | global, not tenant-scoped |
| `alerts` | what the teacher sees | `district_id`, `school_id`, `section_id`, `person_id`, `device_id`, `kind` (`bypass_vpn_off`/`bypass_screentime`/`no_tap`/`tag_failing`/`low_compliance`), `level`, `opened_at`, `resolved_at`, `resolved_by` | |
| `audit_log` | admin actions | `district_id`, `actor_person_id`, `action`, `target`, `details jsonb`, `at` | append-only; writes only via functions |
| `sync_jobs` (later) | roster sync runs | `provider`, `district_id`, `status` (`pending`/`running`/`completed`/`partially_failed`/`failed`/`cancelled`), `checkpoint jsonb`, `stats jsonb`, `error` | week 7+ |

## Rules enforced in the database (not just in code)

- A student cannot be enrolled twice in a section: unique `(section_id, person_id)`.
- One attendance row per student per section per day: unique `(section_id, person_id, date)`.
- A tap's `sdm_counter` must be greater than the tag's last accepted counter (NTAG 424 DNA replay protection) — checked in the `tap` function inside a transaction.
- `exempt = true` ⇒ no `lock_session` is ever created for that person (function-level rule + test).
- RLS: teachers read/write only sections where they have a `teacher` enrollment; students read only their own rows; school admins their school; district admins their district; the service role (functions) bypasses RLS and is never used from a client.
- `taps`, `audit_log` are insert-only for every role except service.

## Derived numbers (match the demos exactly)

- **Attendance pill:** present = statuses `present + tardy + manual_present`; `"25 / 26 present"` = present / enrolled.
- **Compliance pill:** expected = present − exempt; locked = lock_sessions in state `locked` for present students; `"24 / 24 locked"`.
- **Late tap:** `tapped_at` > period start + grace window (school setting, default 5 min) ⇒ `tardy`.
- **Tap before the bell** counts as on time (students tap as they arrive, up to the school's pre-bell window, default 10 min).

## Seed (mock school)

Brookfield Township Public Schools (NJ): Brookfield HS, Riverside MS, Cedar Lane MS; Ms. Dana Alvarez, Room 214, five sections; the P2 roster of 26 named students incl. Jordan Ellis; bell schedule P1 8:00–8:50 … P7 14:00–14:50 (P5 lunch). Source of truth: `docs/design/tapin-data_v05.json` — the seed script reads it so the real dashboards look like the demos on day one.

## What we deliberately do not store

Date of birth, home address, phone number, parent details, demographics, grades/marks, location, app-usage content, DNS queries, message content. Exemptions are a boolean, never a diagnosis. See `privacy.md`.

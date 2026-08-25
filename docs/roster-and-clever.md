# Rostering — RosterProvider, class code / CSV now, Clever later

Owner: tech-lead chat. v01 (2026-08-25).

## Why an abstraction
Districts roster three ways we'll meet in year one: nothing (a teacher types names), Clever, and an SIS like Genesis (Cherry Hill) or PowerSchool. The core product must not know which. So every roster source implements one interface and the rest of the system talks only to that.

```ts
interface RosterProvider {
  kind: 'class_code_csv' | 'clever' | 'genesis' | 'oneroster'
  // create or update a section's roster from the source; returns a diff
  importSection(sectionId: string, input: unknown): Promise<RosterDiff>
  // full reconcile for a school/district (later providers)
  reconcile(scope: { districtId: string; schoolId?: string }, job: SyncJob): Promise<SyncResult>
}
type RosterDiff = { added: Person[]; removed: Person[]; unchanged: number; warnings: string[] }
```

Rules for every provider: idempotent (running twice changes nothing), external ids preserved in `people.external_ids`, SIS-owned fields (names, membership) are never edited by teachers in the app, application-owned fields (exemption flag, settings) never come from the SIS.

## v1 — `ClassCodeCsvProvider` (the pilot)
- Teacher creates a section in the dashboard → gets a 6-character **class code** (unambiguous alphabet, no 0/O/1/I; rotates on demand; expires when the teacher closes joining).
- Roster comes from either a **CSV upload** (`first_name,last_name` — nothing else accepted; extra columns are dropped with a warning) or the teacher **typing names**.
- Student joins by entering the class code in the app and picking their name from the section's list (or typing it if the teacher allowed self-add). The `join` function matches to an existing `people` row in that section or creates one flagged `self_reported = true` for the teacher to confirm.
- Cherry Hill: the teacher exports names from Genesis as CSV. No integration needed for the classroom pilot.

## v2 — `CleverProvider` (week 7+, against Clever's sandbox; production only when a district requires it)
Verified facts (dev.clever.com, Aug 2026): every developer app gets a free sandbox district (5 schools, 33 sections, 41 users); a larger "Clearwater ISD" dataset exists; a custom sandbox with our own data needs Clever's paid tier; partner pricing is quote-based ("Starter Pack": one-time integration fee, first five schools included). **Use the current official docs when implementing — do not invent endpoints, scopes or fields.**
- Login: Clever OAuth via the backend (secrets server-side; PKCE; state check; redirect URI validated). Never a client secret in the app.
- Data: Secure Sync (districts → schools → sections → users → enrollments). Store `clever_id` in `external_ids`; map schools/sections by Clever ids, never by names or emails.
- Sync engine: `sync_jobs` rows (`pending → running → completed | partially_failed | failed | cancelled`), checkpoints, retries with backoff, idempotent upserts keyed on external ids, deletion handling (end-date enrollments; remove people after retention), orphan detection, per-run stats and error report visible on the district SIS page (the `_v05` SIS view is the UI).
- Clever does **not** write attendance back; that is per-SIS (Genesis/PowerSchool) and phase two.

## Phase two — attendance write-back (`GenesisProvider`, `PowerSchoolProvider`)
Each is its own provider with its own credentials per district, an `attendance_export` job at the bell, and a reconciliation report. Cherry Hill's tech director (Marc Plevinsky) is the contact for Genesis specifics; nothing of ours runs on their systems — they evaluate a one-page integration spec and a security questionnaire.

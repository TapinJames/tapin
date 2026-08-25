# supabase — rules for Claude Code (starts week 2, T-005)

Read the root `CLAUDE.md` first. Then `docs/data-model.md`, `docs/security.md`, `docs/privacy.md`.

- Supabase CLI project. `migrations/` are numbered SQL files, forward-only, reviewed in PRs; never edit an applied migration — add a new one. `seed/` builds the Brookfield mock school from `docs/design/tapin-data_v05.json`.
- Every tenant table: `district_id`, RLS enabled, policies per role, and a test in `tests/rls.test.sql` proving cross-tenant reads return nothing.
- Database-level invariants (unique enrollments, unique attendance per day, tap counters) live in the schema, not only in code.
- Edge Functions (`functions/<name>/index.ts`, Deno, TypeScript strict): validate input with a typed schema, run with the service role, return `{ error: { code, message } }` on failure, never leak SQL or stack traces, log a request id — never names next to device ids.
- Secrets via `supabase secrets set`; `.env.example` lists names only. Two projects: `tapin-dev` (now) and `tapin-pilot` (October) — the pilot ref is never used from a dev machine without James saying so.
- Deletion/export functions (`remove_person`, `export_person`) are part of v1 (week 6), not "later".

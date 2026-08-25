# apps/web — rules for Claude Code (starts week 3)

Read the root `CLAUDE.md` first. Then `docs/design/README.md`.

- Next.js (App Router) + TypeScript strict + `@supabase/ssr` + `@supabase/supabase-js`; deployed on Vercel. Tailwind is fine; keep the demos' exact palette (`#367acc`, `#285b99`, `#c9def4`, `#edf3fb`).
- One app, two roles (teacher, district). Routes: `/teacher/...`, `/district/...`. Every page is server-rendered with the user's Supabase session; RLS does the authorization — never filter by role in the client only.
- Build to `docs/design/tapin-teacher-dashboard_v05.html` and `tapin-district-dashboard_v05.html`. Same layout, same cards, same status pills and math (`docs/data-model.md` → Derived numbers). Do not redesign; propose changes in the report.
- Realtime: subscribe to `taps`, `lock_sessions`, `alerts` for the live feed and pills.
- Tests: Vitest for the pill/attendance math and policy compilation; Playwright for the two main pages against the seeded dev project. Screenshot every visual change (Playwright) and attach it to the PR.
- Env: `.env.local` (git-ignored) from `.env.example`. Only `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are public; nothing else is exposed to the browser.

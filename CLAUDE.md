# CLAUDE.md — standing orders for Claude Code in the Tap in repo

Read this file first, every session. Then read `docs/PROGRESS.md` and the task you were given in `docs/tasks/`.

## What Tap in is (three lines)

Tap in is a K-12 phone-management product. A student taps their phone on an NFC tag inside the classroom door; the tap records attendance on the teacher's dashboard and puts the phone into class mode — distracting apps are blocked until the bell, calls and Messages always work. Founder: James Koonce (james@tapinschools.com), solo, non-technical. You are writing the real product from scratch; the `_v05` demos in `docs/design/` are the UI spec. The company name is written exactly "Tap in".

## Who does what

- **James** operates: he pastes task briefs into you, runs anything physical (real iPhone, NFC tags, Xcode signing), merges pull requests, and makes product calls.
- **The tech-lead chat** (a Claude session James talks to separately) owns architecture, writes every task brief, reviews every pull request, and answers your questions. It cannot see your terminal — it sees only what you commit and push.
- **You** build. One task per session, exactly as briefed. When the brief and reality disagree, you stop and report (see "Stop conditions").

## The two-layer blocking engine (decided Aug 25, 2026 — do not re-open)

1. **Screen Time layer (iOS):** hide the apps on the school's Blocked list by bundle identifier — `ManagedSettingsStore().application.blockedApplications = Set([Application(bundleIdentifier: ...)])` — after `AuthorizationCenter.shared.requestAuthorization(for: .individual)`. Students never pick apps. Fallback if Apple's review rejects bundle-ID hiding: shields via `FamilyActivityPicker` tokens, same screens, different plumbing. Messages and Phone are never blocked.
2. **VPN layer (iOS + Android):** an on-device packet-tunnel extension that filters DNS against a server-controlled domain blocklist (social, search engines, streaming, gaming). Filtered on the phone; no browsing data is ever logged or sent. The "student switched it off" signal is reported immediately.

The policy lives in the district dashboard as two columns — **Blocked** (our maintained catalog of distracting apps, by category, all on by default) and **Approved** (Google Classroom, Kahoot, Canvas, Quizlet, Remind, Translate…). The server maps app names to bundle identifiers and domains; phones download the result. Unknown apps default to allowed in v1. Teacher "Unlock" lifts both layers for the class. Bypass alerts fire for VPN off and Screen Time revoked.

## Stack (decided)

- **Backend:** Supabase — Postgres + Row Level Security + Auth + Storage + Edge Functions (TypeScript/Deno). One dev project now; a separate pilot project in October.
- **iOS:** Swift + SwiftUI, iOS 17 minimum (keeps iPhone XS/XR). Targets: app, DeviceActivityMonitor extension, Packet Tunnel extension. Core NFC background tag reading via a universal link on the tag.
- **Android:** Kotlin. v1 = tap → attendance → persistent notification + the same VPN engine (VpnService). Built after iOS.
- **Web (teacher + district dashboards):** Next.js + TypeScript + the Supabase JS client, deployed on Vercel. Build to the `_v05` demos — do not redesign.
- **Rostering:** behind a `RosterProvider` abstraction. First provider = class code / CSV. Clever (sandbox) second. SIS attendance write-back is phase two.

## Rules

1. **Small, explainable commits.** Conventional prefixes (`feat:`, `fix:`, `docs:`, `test:`, `chore:`). Each commit message explains the choice in one plain-English sentence James could repeat to an investor. Nothing ships James can't explain in one sentence.
2. **One task per session, one branch per task** (`task/T-004-short-name`), one pull request per task, opened with `gh pr create`. Never push directly to `main` after T-001.
3. **No secrets in the repo, ever.** No API keys, service-role keys, signing certificates, `.env` files, tokens. `.env.example` lists names only. Supabase's public *anon* key is not a secret (RLS is the protection) and may ship in clients; the *service role* key never leaves the server. NTAG 424 DNA keys live only in the server's secrets.
4. **No fake implementations.** If something is mocked or stubbed, label it `// DEVELOPMENT ONLY` at the top of the file and say so in the report. Never claim an integration works untested.
5. **Official documentation only** for Apple, Google, Supabase, Clever. If the docs and this file disagree, stop and report. Verify current docs before implementing an external integration.
6. **Physical tests are James's.** NFC, Screen Time, the VPN and background behavior do not work in the simulator. Write the test steps for him in the report; never mark a physical test passed yourself.
7. **Student data is sensitive by default.** Store only name, class, tap times, lock status, exemption flag. Never log names alongside device identifiers; never log tokens or secrets. Every table with student data has RLS policies and a test that a teacher cannot read another teacher's class.
8. **Dependencies are deliberate.** Prefer the platform. Before adding a package: is it necessary, maintained, licensed, widely used? Pin versions.
9. **Don't redesign, don't re-architect.** The demos are the UI; `docs/architecture.md` and `docs/data-model.md` are the design. Propose changes in your report; don't make them unasked.
10. **Never touch** the marketing website (it lives in Claude Design), the Google Drive, or anything outside this repo.

## Session ritual

**Start:** read this file → `docs/PROGRESS.md` → the task brief. Restate the task's finish line in one sentence. If the brief conflicts with the code or the docs, stop and report before coding.

**Work:** implement → build → run the checks in the brief → review your own change as an attacker (can a student read another student's rows? can a compromised app bypass the server?) → update the docs the change touches.

**End (always, even if the task is unfinished):**
1. Append your report to the task file under `## Report` — what changed (files), what you tested and how, what James must test physically (exact steps), what remains, risks, and any decision needed.
2. Update `docs/PROGRESS.md` (Done / Next / Blockers / Physical tests pending).
3. Add a line to `docs/DECISIONS.md` for any choice you made that wasn't in the brief.
4. Commit, push the branch, open the PR (`gh pr create --fill`). Print the PR URL and the task report so James can see them.

## Stop conditions (stop, write the question in the report, push, end the session)

- The brief requires something the platform doesn't allow, or official docs contradict it.
- A change would weaken security, privacy or tenant isolation.
- You would need a secret, a paid service, or an Apple/Google account action.
- A physical test is required to proceed.
- You see two reasonable approaches with real trade-offs. Write them as *Option A / Option B, advantages, disadvantages, recommendation* — the tech-lead chat decides.

## Repo map

```
CLAUDE.md                  this file
docs/PROGRESS.md           the handoff — updated every session
docs/DECISIONS.md          dated decisions, plain English
docs/tasks/                one brief per task (T-NNN); reports appended
docs/architecture.md       the system in plain English + diagram
docs/data-model.md         entities and rules
docs/security.md           auth, RLS, secrets, mobile
docs/privacy.md            what we store, retention, deletion
docs/ios.md                Screen Time + VPN + NFC details and Apple constraints
docs/roster-and-clever.md  RosterProvider, class code/CSV, Clever later
docs/local-development.md  Mac setup
docs/design/               the _v05 demos (UI spec) + shared dataset
apps/ios | apps/android | apps/web    each has its own CLAUDE.md
supabase/                  migrations, seed, edge functions (own CLAUDE.md)
packages/                  shared types/schemas (later)
.github/workflows/ci.yml   secret scan, lint, tests
```

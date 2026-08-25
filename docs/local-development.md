# Local development — James's Mac

Owner: tech-lead chat. Kept current by Claude Code (T-001 fills in versions).

## One-time setup (done in T-001)
- Xcode (latest release from the App Store) + Command Line Tools: `xcode-select --install`
- Homebrew: https://brew.sh
- `brew install git gh supabase/tap/supabase xcodegen node@22`
- `gh auth login` (browser) — GitHub; `git config --global user.name / user.email`
- Claude Code installed and run from the repo root: `cd ~/code/tapin && claude`
- iPhone: plugged in once, "Trust this computer", Developer Mode on (Settings → Privacy & Security → Developer Mode), registered in Xcode (Window → Devices).
- Apple Developer: James's paid membership signed into Xcode (Settings → Accounts).

## Repo layout
See `CLAUDE.md` → Repo map.

## iOS
```
cd apps/ios
xcodegen generate          # writes TapIn.xcodeproj from project.yml
open TapIn.xcodeproj       # select the TapIn scheme + James's iPhone → Run
```
Or from the terminal: `xcodebuild -scheme TapIn -destination 'platform=iOS,name=<James's iPhone>' build` then `xcrun devicectl device install app --device <id> <path>.app` (Claude Code fills the exact commands after T-002).

## Supabase (from T-005)
```
supabase login
supabase link --project-ref <tapin-dev ref>
supabase db push            # apply migrations
supabase db reset           # local: wipe + migrate + seed
supabase functions serve    # run edge functions locally
```
Local stack: `supabase start` (Docker Desktop required).

## Web (from T-011)
```
cd apps/web && npm install && npm run dev
```

## Environment variables
Copy `.env.example` to `.env.local` in each app folder and fill values from the Supabase dashboard. Never commit `.env*`.

## Checks before every PR
`npm run lint && npm run typecheck && npm test` (web / functions); `xcodebuild ... build` succeeds (iOS); `gitleaks detect` clean (CI runs it too).

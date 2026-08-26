# Local development — James's Mac

Owner: tech-lead chat. Kept current by Claude Code (T-001 fills in versions).

## One-time setup (done in T-001)

**Versions installed on James's Mac (Aug 25, 2026):**
- macOS: 26.1 (Tahoe)
- Xcode: 26.1.1
- Homebrew: 5.0.13
- git: 2.50.1
- gh (GitHub CLI): 2.86.0
- supabase: 2.72.7
- xcodegen: 2.46.0
- node: 25.2.1
- gitleaks: 8.30.1

**Setup steps:**
- Xcode (latest release from the App Store) + Command Line Tools: `xcode-select --install`
- Homebrew: https://brew.sh
- `brew install git gh supabase/tap/supabase xcodegen node@22 gitleaks`
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

**First time setup:** Open the project in Xcode, go to TapIn target → Signing & Capabilities. If prompted, click "Try Again" to register the App ID and capabilities with Apple. You may need to enable Family Controls capability manually the first time.

**Terminal build (T-002+):**
```bash
# Build for device (requires signing set up in Xcode first)
cd apps/ios
xcodebuild -scheme TapIn -destination 'platform=iOS,name=iPhone (3)' -configuration Debug build

# Install to device (get device ID from: xcrun devicectl list devices)
xcrun devicectl device install app \
  --device 355F9006-83E7-50C4-B3C4-397121D6CD29 \
  ~/Library/Developer/Xcode/DerivedData/TapIn-*/Build/Products/Debug-iphoneos/TapIn.app
```

**Note:** Family Controls, DeviceActivity, and NFC do not work in the simulator — always test on a real device.

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

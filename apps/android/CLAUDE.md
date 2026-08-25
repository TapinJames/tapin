# apps/android — rules for Claude Code (starts week 5)

Read the root `CLAUDE.md` first.

- Kotlin, Jetpack Compose, minSdk 26. Gradle Kotlin DSL. No product code here until the brief for Android v1 arrives.
- v1 scope: NFC intent → `tap` → attendance → persistent "Class mode until 9:50" notification → the same DNS-filtering VPN engine via `VpnService` (port of the iOS design in `docs/ios.md`, Layer 2). No Screen Time equivalent on Android; say so in the UI ("network block only").
- Same rules as iOS for secrets (anon key public, nothing else), logging (no names/tokens/DNS names), and physical testing (James's Android test phone).

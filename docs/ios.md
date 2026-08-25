# iOS — Screen Time, VPN, NFC: how it works and what Apple allows

Owner: tech-lead chat. v01 (2026-08-25). Verified against Apple documentation and Apple engineers' forum answers on the dates noted; re-verify before relying on anything marked *verify*.

## Requirements
- iPhone XS or newer (background NFC tag reading). Deployment target iOS 17.0.
- A **paid** Apple Developer membership (Family Controls and Network Extensions do not work under a free Personal Team).
- Development on James's own phone needs no Apple approval. **Distribution** (TestFlight/App Store) needs: an **organization** account for a VPN app (App Store Review Guideline 5.4) and the **Family Controls distribution entitlement**, requested by the Account Holder (weeks). See Risk R2 in `PROGRESS.md`.
- Nothing here runs in the simulator: NFC, Family Controls, DeviceActivity, Network Extension all need a real device.

## Targets and capabilities

| Target | Bundle id | Capabilities / entitlements |
|---|---|---|
| `TapIn` (app) | `com.tapinschools.tapin` | Family Controls; Network Extensions (packet-tunnel-provider); App Groups (`group.com.tapinschools.tapin`); Associated Domains (`applinks:t.tapinschools.com`); Near Field Communication Tag Reading (NDEF, with `com.apple.developer.nfc.readersession.formats` = `NDEF`, `TAG`); Push Notifications; Background Modes (remote-notification) |
| `TapInMonitor` (DeviceActivityMonitor extension) | `com.tapinschools.tapin.monitor` | Family Controls; App Groups |
| `TapInTunnel` (Packet Tunnel extension) | `com.tapinschools.tapin.tunnel` | Network Extensions (packet-tunnel-provider); App Groups |

XcodeGen (`project.yml`) generates the Xcode project so targets and entitlements are text in git. If Xcode's automatic signing fails to enable a capability, open the project → target → Signing & Capabilities → add it once by hand; Xcode registers it on the App ID.

## Layer 1 — Screen Time

**Authorization (once):** `try await AuthorizationCenter.shared.requestAuthorization(for: .individual)` — the phone's owner approves with Face ID / passcode. Status is `AuthorizationCenter.shared.authorizationStatus` (`approved` / `denied` / `notDetermined`); observe it and report changes to the server.

**Primary mechanism — hide by bundle identifier (no picker):**
```swift
import ManagedSettings
let store = ManagedSettingsStore(named: .init("classMode"))
store.application.blockedApplications = Set(bundleIds.map { Application(bundleIdentifier: $0) })
// lift:
store.application.blockedApplications = nil   // or store.clearAllSettings()
```
Documented behavior: "The system hides blocked applications and prevents the user from launching them." Apple frameworks engineer showed this exact pattern with individual authorization (developer.apple.com/forums/thread/716519). **Known caveats:** hidden apps may return at a different Home Screen position; App Review has rejected at least two apps for using this to hide apps (threads 758959, 776058) citing guideline 2.5.1 — which is why the fallback below is built, not just planned.

**Fallback — shields via picker tokens:** `FamilyActivityPicker` bound to a `FamilyActivitySelection`; then `store.shield.applications = selection.applicationTokens` and/or `store.shield.applicationCategories = .specific(selection.categoryTokens)`. Tokens are opaque; the app cannot read names or bundle ids (by design; DTS: thread 775626). `.all(except:)` exists but has a bug history (FB15500605) — test on the current iOS before using it. Apps in the user's Screen Time "Always Allowed" list (Phone; Messages by default) are never shielded by a category shield.

**Web domains by name (no picker):** `store.webContent.blockedByFilter = .specific(Set(domains.map { WebDomain(domain: $0) }))` — Safari/WebKit only; the VPN covers the rest.

**Scheduling — DeviceActivity:** the app calls `DeviceActivityCenter().startMonitoring(name, during: DeviceActivitySchedule(intervalStart:, intervalEnd:, repeats: false))` for the current class (minimum interval length 15 minutes — *verify*). The `TapInMonitor` extension's `DeviceActivityMonitor` subclass applies the block in `intervalDidStart` and clears it in `intervalDidEnd`; the app also applies immediately at tap time so there is no gap. Both app and extension use the same named `ManagedSettingsStore`.

**Detecting revocation:** no callback when the user turns off Screen Time access. Check `authorizationStatus` at every tap, at every app foreground, and when a silent push arrives (server sends one at each period start to enrolled devices); report `screentime_revoked` / `screentime_granted` via `status`.

## Layer 2 — VPN (DNS filter)

`NEPacketTunnelProvider` in `TapInTunnel`. Split tunnel: the tunnel claims only a private address (e.g. `10.7.0.1/32`) and sets itself as the DNS server for all domains (`NEDNSSettings(servers: ["10.7.0.1"])`, `matchDomains = [""]`); routes include only that address, so all other traffic bypasses the tunnel. The provider reads packets from `packetFlow`, parses UDP/53 queries, answers blocked names with an empty/NXDOMAIN response (or `0.0.0.0`), and forwards everything else to an upstream resolver over UDP via `NWConnection`, writing the answers back. Blocklist = suffix match against the policy's `domains` (e.g. `tiktok.com` blocks `api.tiktok.com`). The list lives in the App Group container; the app refreshes it when `policy_version` changes.

Install flow: `NETunnelProviderManager` → `loadAllFromPreferences` → configure `NETunnelProviderProtocol` (`providerBundleIdentifier`, `serverAddress = "Tap in"`) → `saveToPreferences` (iOS shows the "Allow Tap in to add VPN configurations" prompt once) → `connection.startVPNTunnel()`. `isOnDemandEnabled = true` with an "always connect" rule keeps it re-connecting after reboots (the user can still turn it off in Settings; that is by Apple's design).

**Switched-off signal:** iOS calls `stopTunnel(with:completionHandler:)`; reason `.userInitiated` means the student turned it off. Post `status(vpn_off)` to the server *before* calling the completion handler (short timeout), and write a marker to the App Group so the app reports it on next launch if the post failed. `NEVPNStatusDidChange` in the app covers the in-app view.

**Limits (say them out loud in the product):** DNS filtering does not stop apps that hard-code IP addresses or use their own encrypted DNS (Chrome/Firefox with DoH); the Screen Time layer covers the app case. Only one VPN can be active — a student starting another VPN disconnects ours (→ `vpn_off` alert). The VPN icon appears in the status bar. Nothing about DNS queries is logged or sent — filtering is on-device.

## NFC — background tag reading

Tags carry an NDEF URL record `https://t.tapinschools.com/t/<tag_uid>` (pilot tags append the NTAG 424 DNA SDM parameters: `?picc=<enc>&cmac=<mac>`). iPhone XS+ reads NDEF tags in the background (screen on, not in Control Center/Wallet); iOS opens the app through the **universal link** (Associated Domains + an `apple-app-site-association` file served from `t.tapinschools.com`). Handle `onOpenURL` / `NSUserActivity` → call `tap`. Foreground fallback: a "Tap now" button that starts an `NFCNDEFReaderSession` for phones where background reading is off.

## Onboarding flow (build directly in SwiftUI — no mockups; copy in the brief)

1. Welcome → **Enter your class code** (6 characters from the teacher).
2. **Screen Time** — "Tap in hides distracting apps during class and brings them back at the bell. Calls and Messages always work." → Apple prompt.
3. **Class-mode filter (VPN)** — "Blocks distracting sites during class. Nothing you do online is recorded." → Apple prompt.
4. **You're set** — "Tap the tag inside the classroom door as you walk in." Shows the Today screen from the demo.
States to build: Focus needs attention (Screen Time off / VPN off, with the fix button), Teacher unlocked apps for an activity, No internet (tap queued), Tag not recognized.

## Physical test protocol (James)
Every iOS task ends with steps James runs on his iPhone: what to tap, what he should see, how long to wait, what to screenshot. Claude Code never marks these passed.

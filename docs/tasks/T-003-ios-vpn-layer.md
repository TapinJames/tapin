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
Files; the DNS response choice and why; how TCP/53 and IPv6 are handled (or explicitly not); anything Apple's docs say that differs from `docs/ios.md`; the physical steps as built; open questions.

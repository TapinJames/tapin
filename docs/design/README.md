# Design spec — the `_v05` demos

These three single-file HTML mockups are the UI specification for the real product. Build to them; do not redesign. Open them in a browser (or drive them with Playwright) to see every state.

| File | Surface | What it defines |
|---|---|---|
| `tapin-teacher-dashboard_v05.html` | Teacher web app | Dashboard (period tabs, Attendance table with status pills, Compliance card with active bypass timers + previous bypasses, Unlock button, live clock), Reports (weekly table, week navigation, review pop-out, CSV export), Settings (session rules, notifications, classroom tag card). **Its "Blocked app group" toggles are superseded** by the Blocked / Approved two-column policy page (district Settings) — keep the visual language, change the model. |
| `tapin-district-dashboard_v05.html` | District web app | Overview (hero attendance %, KPI tiles, school cards, daily attendance + compliance charts with Chart/Data toggles and date ranges, compliance alert list), per-school drill-in, SIS sync page (mapping + history), Settings (district policy, alerts & reports). |
| `tapin-ios-app_v05.html` | Student iOS app | Today (greeting, day chips, Now card → tap → Locked card with countdown ring and "until apps unlock", Up next), Schedule, Profile (streak, Screen Time authorization, exemption status, "Why is my phone locked?"). Onboarding and error states are specified in words in `docs/ios.md`. |
| `tapin-data_v05.js` / `.json` | Shared dataset | Brookfield Township Public Schools, bell schedule, Ms. Alvarez's five sections, the P2 roster, feed, alerts, reports, tag, sync history. Seed source for the mock school. Status model: `in · late · pend · flag · absent · exempt`. |

Brand: all blues `#367acc` (deep `#285b99`, tint `#c9def4`, wash `#edf3fb`). Logo: the PNG embedded in the demos (data URL) — extract once into `apps/web/public/` and the iOS asset catalog.

Demo clock: Tuesday, May 12, 2026, 9:22:15 AM; P2 live; Jordan Ellis tapped 8:56 AM; 26 enrolled = 25 present + 1 absent; lockable = present − exempt. Keep demo data internally consistent when extending it.

# T-004 — Procedure: Family Sharing test on teenagers' phones (Risk 1)

**Goal:** a written answer to "does Tap in's Screen Time permission work on a teenager's iPhone whose Apple Account is a child account in a parent's Family Sharing?" — on two or three real phones.

**Why:** most high-schoolers' Apple accounts are managed under a parent. If `.individual` authorization fails on those, onboarding must route through parents, which changes the parent letter and day-one logistics. We need to know in week 1, not in November. This is mostly a procedure for James; Claude Code prepares the build and the checklist and records the results.

**Scope — in:** the T-002 + T-003 build installed on 2–3 volunteer phones; a results table in the report; a status update in `docs/PROGRESS.md` (Risk R1). **Out:** any code beyond what's needed to install on another phone and display the authorization error text.

## Steps (Claude Code)
1. Make sure the T-002 screen shows the **exact error** when authorization fails (`FamilyControlsError` description) and the account type if obtainable — a human-readable line James can photograph.
2. Write the install path for a volunteer phone with James's *individual* membership: connect the phone by cable → Xcode → Window → Devices → it registers (counts toward the 100-device/year cap) → Run. Put the steps in the report.
3. Prepare the results table below in the report; James fills it in; you copy the outcome into `docs/PROGRESS.md` (R1) in the next session.

## Physical procedure (James)
Find two or three teenagers (13–17) whose iPhones are in a parent's Family Sharing group as **child** accounts (Settings → [name] → Family → the teen shows under "Children"). Also one adult phone that is *not* in Family Sharing as a control. For each phone:
1. Connect by cable, trust the Mac, run the app from Xcode.
2. Tap **Allow Screen Time**. Record: prompt shown? approved with Face ID/passcode? error text?
3. If approved: Start class mode → do Instagram/TikTok hide? End → do they return?
4. Tap **Install & start filter** (VPN). Record: prompt shown? VPN starts? Does a blocked site fail?
5. Settings → Screen Time on that phone: does a parent's Screen Time passcode exist? Does "Tap in" appear under Apps with Screen Time access?
6. Thank them; remove the app if they want.

| Phone | iOS version | Account: child in Family Sharing? | Parent Screen Time passcode? | Screen Time prompt result | Hide/return worked? | VPN prompt + block worked? | Notes |
|---|---|---|---|---|---|---|---|
| A | | | | | | | |
| B | | | | | | | |
| C | | | | | | | |
| Control (adult) | | | | | | | |

## Finish line
The table is filled for at least two child-account phones and the control, and `docs/PROGRESS.md` R1 says one of: **works as individual** / **requires parent approval (describe the flow seen)** / **blocked (describe)** — with the error text.

## Report
The results table; the install steps used; any Apple documentation on `.child` vs `.individual` authorization you verified; recommendation for the onboarding flow given the results (the tech lead decides).

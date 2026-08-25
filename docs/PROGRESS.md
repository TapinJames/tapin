# PROGRESS — the handoff file

Updated by Claude Code at the end of every session. Read by the tech-lead chat and by James. Newest state only — history lives in git and in `docs/tasks/*/Report`.

## Where we are

- **Phase:** Week 0 — repo initialized, no product code yet.
- **Current task:** T-001 (initialize the repo). Next: T-002 (iOS Screen Time core loop).
- **Last session:** — (none yet)

## Done

- Repo skeleton, standing orders, docs package, task briefs T-001 – T-004 (written by the tech-lead chat, Aug 25, 2026).

## Next

1. T-001 — initialize the repo on James's Mac, install tools, first push to `main`.
2. T-002 — iOS: Screen Time authorization → hide apps by bundle identifier → scheduled unlock, on James's iPhone.
3. T-003 — iOS: VPN layer (DNS-filtering packet tunnel) with the "switched off" signal.
4. T-004 — procedure: Family Sharing test on two or three teenagers' phones (Risk 1).

## Blockers / decisions needed

- None.

## Physical tests pending (James)

- None yet.

## Risk register (short)

| Risk | Status | Owner |
|---|---|---|
| R1 — Screen Time `.individual` authorization fails on Family Sharing child accounts | Untested — T-004 | James + Claude Code |
| R2 — Apple's Family Controls *distribution* entitlement (weeks; needs the organization account) | Not started — James's timing | James |
| R3 — App Review rejects bundle-ID hiding | Unknown until first TestFlight build (week 5) — picker fallback designed | Tech lead |
| R4 — `.all(except:)` / shield bugs on current iOS | Only matters for the fallback — test in T-002 stretch step | Claude Code |

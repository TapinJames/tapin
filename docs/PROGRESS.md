# PROGRESS — the handoff file

Updated by Claude Code at the end of every session. Read by the tech-lead chat and by James. Newest state only — history lives in git and in `docs/tasks/*/Report`.

## Where we are

- **Phase:** Week 0 — repo initialized, no product code yet.
- **Current task:** T-001 complete. Next: T-002 (iOS Screen Time core loop).
- **Last session:** Aug 25, 2026 — T-001 completed.

## Done

- Repo skeleton, standing orders, docs package, task briefs T-001 – T-004 (written by the tech-lead chat, Aug 25, 2026).
- **T-001:** Repo initialized on GitHub (TapinJames/tapin), tools installed (xcodegen 2.46.0, gitleaks 8.30.1, supabase 2.72.7), CI green.

## Next

1. T-002 — iOS: Screen Time authorization → hide apps by bundle identifier → scheduled unlock, on James's iPhone.
2. T-003 — iOS: VPN layer (DNS-filtering packet tunnel) with the "switched off" signal.
3. T-004 — procedure: Family Sharing test on two or three teenagers' phones (Risk 1).

**CI note:** Re-enable the `supabase` CI job in T-005 (when `supabase/config.toml` lands) and the `web` CI job in the first web task (when `apps/web/package.json` lands). No path filters needed.

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

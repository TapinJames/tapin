# Tasks — how work flows

- The **tech-lead chat** writes one brief per task (`T-NNN-short-name.md`). A brief has: Goal (one sentence), Why (plain English), Scope (in / out), Steps, Finish line (the test), Physical test (for James), Report (what to write back).
- **James** starts a Claude Code session in the repo root and says: `Do docs/tasks/T-NNN-short-name.md` — nothing else is needed.
- **Claude Code** follows `CLAUDE.md`'s session ritual, works on branch `task/T-NNN-short-name`, appends `## Report` to the brief, updates `docs/PROGRESS.md`, pushes, opens the PR, and prints the PR URL + report.
- **James** runs the physical test if there is one, pastes the printed report (or just the PR link) to the tech-lead chat, and merges when the tech lead says it's good.

Task numbers never reuse. A task that grows gets split into `T-NNNa`, `T-NNNb` by the tech lead, not by Claude Code.

| Task | Title | Week | Status |
|---|---|---|---|
| T-001 | Initialize the repo on the Mac | 0 | pending |
| T-002 | iOS: Screen Time core loop on James's iPhone | 1 | pending |
| T-003 | iOS: VPN layer (DNS filter) with the switched-off signal | 1 | pending |
| T-004 | Procedure: Family Sharing test on teenagers' phones (Risk 1) | 1 | pending |
| T-005 | Supabase project, data model v1, Brookfield seed | 2 | not yet written |
| T-006 | iOS: NFC background read + universal link → `tap` | 2 | not yet written |

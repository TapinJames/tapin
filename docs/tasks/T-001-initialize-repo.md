# T-001 — Initialize the repo on James's Mac

**Goal:** the `tapin` repository exists on GitHub with this skeleton as its first commit, and James's Mac has every tool the next tasks need.

**Why:** GitHub is the middleman between Claude Code (which builds) and the tech-lead chat (which reviews). Nothing else can start until the repo exists and pushes work.

**Scope — in:** tool installs, git setup, first commit to `main`, a green CI run, filling in `docs/local-development.md` with the exact versions installed. **Out:** any product code, any Xcode project, any Supabase project.

## Before you start
James has already: created the GitHub organization and an empty private repository `tapin` (no README), and unzipped this skeleton into `~/code/tapin` on the Mac. Confirm both with him if either is missing — do not create the GitHub repo yourself.

## Steps
1. Read `CLAUDE.md`, `docs/PROGRESS.md`, and this brief. Restate the finish line in one sentence.
2. Tools (check each with `--version` first; install only what's missing):
   - Xcode Command Line Tools (`xcode-select -p`; if missing, `xcode-select --install` — James clicks the dialog).
   - Homebrew.
   - `brew install git gh supabase/tap/supabase xcodegen node@22 gitleaks`
   - `gh auth login` → James completes the browser step. Verify with `gh auth status`.
   - `git config --global user.name "James Koonce"` and `user.email` = the email on his GitHub account (ask him which).
3. In `~/code/tapin`: `git init -b main`, add the GitHub remote (`gh repo view <org>/tapin` to confirm the URL), `git add -A`, review `git status` — confirm no `.env`, no keys, no binaries — then commit: `chore: initialize repo with standing orders, docs package and task briefs`.
4. `git push -u origin main`. Confirm the CI workflow ran on GitHub (`gh run list`) and is green. If gitleaks flags anything, stop and report — do not suppress.
5. Fill in `docs/local-development.md` → "One-time setup" with the versions you installed (Xcode, macOS, Homebrew, node, supabase, xcodegen). Commit `docs: record tool versions` and push.
6. Do the session-end ritual: report below, `docs/PROGRESS.md` (Done: T-001; Next: T-002), push. This task is the only one that pushes to `main` directly.

## Finish line
`gh repo view` shows the repo; `git log` shows two commits on `main`; CI is green; `xcodegen --version`, `supabase --version`, `gh auth status` all succeed on the Mac.

## Physical test (James)
None. James does: click through `gh auth login`, the Xcode tools dialog if it appears, and tell Claude Code which email to use for git.

## Report

**Date:** Aug 25, 2026

### Tool versions installed
| Tool | Version |
|------|---------|
| macOS | 26.1 (Tahoe) |
| Xcode | 26.1.1 |
| Homebrew | 5.0.13 |
| git | 2.50.1 |
| gh (GitHub CLI) | 2.86.0 |
| supabase | 2.72.7 |
| xcodegen | 2.46.0 |
| node | 25.2.1 |
| gitleaks | 8.30.1 |

### Repo URL
https://github.com/TapinJames/tapin

### CI run (green)
https://github.com/TapinJames/tapin/actions/runs/32905182165

### What changed
- `.github/workflows/ci.yml`: Fixed YAML syntax (expanded inline flow style), disabled web/supabase jobs until those codebases exist (hashFiles() fails at job-level before checkout), excluded `.env.example` from forbidden file check.
- `docs/local-development.md`: Added tool versions table.
- `docs/PROGRESS.md`: Updated to mark T-001 done.

### Installation notes
- `xcodegen` and `gitleaks` were installed fresh via Homebrew.
- `gh auth` required switching from the JamesK32 account to TapinJames account and adding the `workflow` scope to push CI files.
- git user configured: James Koonce <james@tapinschools.com>

### Questions for tech lead
1. **CI web/supabase jobs:** I commented them out because `hashFiles()` at job-level `if:` fails before checkout runs (no workspace yet). Should I rewrite them using path filters on the workflow trigger instead, or just re-enable them when the code lands?

### Finish line verification
```
✓ gh repo view → TapinJames/tapin exists
✓ git log → 4 commits on main
✓ CI → green (run 32905182165)
✓ xcodegen --version → 2.46.0
✓ supabase --version → 2.72.7
✓ gh auth status → TapinJames (active)
```

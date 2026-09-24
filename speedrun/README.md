# Git Speedrun — Instructor Guide

A 24-task Git competition kit for a workshop with many teams. Base Round
(tasks 1–16) is for everyone; Bonus Round (17–24) is for teams that finish
early. Every team gets an identical, pre-seeded repo so tasks like "resolve
this merge conflict" work the same way for every team, every time.

## What's in this folder

| File | Purpose |
|---|---|
| `tasks.md` | The 24-task list, handed to every team as `TASKS.md`. |
| `setup-team.sh` / `.ps1` | Generates one team's starter environment. Run by you or by each team. |
| `check-progress.sh` / `.ps1` | Verifies a team's repo state and prints a score. |
| `build-all-teams.sh` / `.ps1` | Optional: pre-generates and zips every team's folder in one go. |

The `.sh` scripts run under Git Bash (Windows), macOS, or Linux. The `.ps1`
scripts run under native Windows PowerShell. Both produce identical repo
history — pick whichever fits a team's machine.

## Quick start

**Option A — teams generate their own (recommended, no zip handling):**

Hand out `setup-team.sh` and `setup-team.ps1` (e.g. via a shared drive or a
repo teams clone). Each team runs one command in an empty folder:

```bash
./setup-team.sh TEAM07
```

or, on native PowerShell:

```powershell
.\setup-team.ps1 TEAM07
```

This creates a `TEAM07/` folder containing everything the team needs —
nothing else to distribute.

**Option B — you pre-build everything:**

```bash
./build-all-teams.sh 35 TEAM dist
```

or:

```powershell
.\build-all-teams.ps1 -Count 35 -Prefix TEAM -OutDir dist
```

This drops `dist/TEAM01/` … `dist/TEAM35/` plus a matching `.zip` for each,
ready to hand out from a USB drive, shared folder, or LMS.

## What each team gets

```
TEAM07/
  warmup/                       empty folder -- tasks 1-4 (git init from scratch)
  cafe-project/                 seeded repo, 9 commits + 4 feature branches -- tasks 5-24
  cafe-project-origin.git/      bare repo wired as "origin" -- the local fake remote
  TASKS.md                      the task list
```

The seed content is a small fictional "Trailhead Cafe" project (menu, about
page, changelog) with a guaranteed merge conflict between two branches, a
branch ready to cherry-pick, a branch ready to push, a teammate commit
waiting on the remote (for fetch/pull), and a local bare repo standing in for
a GitHub-style remote so nobody needs a GitHub account.

If you ever need to change the seed data, read through `setup-team.sh` and
`.ps1` together first — they must stay byte-identical in what they generate,
so a change to one needs the matching change in the other.

## Running the workshop

1. Generate or hand out starter environments (see Quick Start above).
2. Give every team `TASKS.md` (already copied into their folder).
3. Teams work through the Base Round in order, then the Bonus Round if they
   finish early. `tasks.md` tells them which folder to work in and gives the
   exact commands.

## Scoring

```bash
./check-progress.sh path/to/TEAM07
```

or:

```powershell
.\check-progress.ps1 path\to\TEAM07
```

Prints `[PASS]` / `[FAIL]` / `[SKIP]` per task plus a running score. About
half the tasks are automatically checkable via git state (branches, commits,
remote refs, tags); the rest are inherently transient (a `git diff` you
looked at, a stash you popped) and are marked `SKIP (manual)` rather than
faked — spot-check those by walking around, or ask teams to demo them.

Re-run `check-progress` anytime — it's read-only and never modifies a team's
repo.

## Troubleshooting

- **"already exists" when running setup-team**: pick a different team name,
  or remove the existing folder first (`rm -rf TEAMNAME` — this discards that
  team's progress, so only do this if it's meant to be a reset).
- **A team's repo gets into a mess mid-task** (stuck merge, etc.):
  `git merge --abort` gets them out of a conflict. If it's unrecoverable,
  delete and re-run `setup-team` for just that team; everyone else is
  unaffected.
- **A text editor full of `~` pops up**: the team forgot `-m` or `--no-edit`.
  `Esc`, then `:wq`, then `Enter`.
- **`zip: command not found`** (batch build only): Git Bash on Windows
  doesn't ship `zip` by default. `build-all-teams.sh` falls back to Python's
  `zipfile` module automatically, so this only bites if neither `zip` nor a
  working `python`/`python3` is on PATH. Use `build-all-teams.ps1` instead
  (PowerShell's `Compress-Archive` needs nothing extra).

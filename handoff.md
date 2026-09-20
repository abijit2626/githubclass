# Handoff — Git Workshop Toolkit

Context for picking this up in a fresh session (e.g. `claude` in a terminal). Read this whole file before doing anything.

## Who this is for

Instructor running a hands-on Git workshop for ~70 junior devs (35 pairs/teams). Two deliverables were requested:

1. An animated git-command visualizer (website) — **DONE**.
2. A "Git Speedrun" competition kit: 38 challenge tasks (Base Round 1–20, Bonus Round 21–38) with per-team starter repos, a seeded merge conflict, a local fake "remote", packaging, and optional auto-verification — **DONE**. All files listed in the target layout below exist under `speedrun/`, tested end-to-end (both `.sh` and `.ps1` generators run clean, produce identical repo state/hashes, and both verification scripts report identical PASS/FAIL/SKIP results). The rest of this section is now a reference for the design rationale, not a to-do list — see `speedrun/README.md` for the instructor-facing usage guide.

**Independent re-verification (2026-09-21)**: re-ran both generators, diffed their output trees (byte-identical across every branch), manually completed a representative task from every category (merge conflict, rebase conflict, bisect, pickaxe search, push, pull, fetch, cherry-pick, tag, cherry-pick, gitignore/untrack) against the real repos and confirmed `check-progress` flips FAIL→PASS correctly for each, and confirmed the `.answers`/`ANSWERS.md` hash-matching mechanism for tasks 22/23 works end-to-end. Found and fixed one real bug: `build-all-teams.sh` hard-required the `zip` binary, which plain Git Bash on Windows doesn't ship — it now falls back to Python's `zipfile` module (probing that `python`/`python3` actually runs, not just that they're on PATH, since a Microsoft Store stub can satisfy `command -v` while failing at runtime). No other issues found; the kit is genuinely ready to use, not just claimed-ready.

## Decisions already made (don't re-ask these)

Asked via clarifying questions earlier in the session:
- **Participant OS**: Mixed Windows/Mac/Linux. Build both a `.sh` (bash — works via Git Bash on Windows, native on Mac/Linux) and a `.ps1` (native PowerShell) version of any script participants run. Both must produce **identical repo state** (same commit content/order), so write them in parallel, not as approximations of each other.
- **Task content**: User does not have an existing task list — draft all 38 tasks myself, calibrated for junior devs.
- **Distribution**: User was unsure ("wdym") when asked zip-vs-self-run-script. I proposed and the user did not object to: build ONE generator script each team runs locally to produce their own repo + bare "origin" remote (no manual zip handling needed), while keeping it possible to loop the same script 35 times in advance to pre-build zips if the instructor ever wants that instead. Treat this as the default — not yet reconfirmed explicitly, flag it to the user once kit is built.
- **Verification**: Yes, build a lightweight auto-check script. It doesn't need to cover all 38 tasks perfectly — cover what's cleanly checkable via git state, mark the rest as manual/instructor-observed rather than faking coverage.

## Deliverable 1 — Visualizer (COMPLETE)

- File: `visualizer/index.html` — single self-contained HTML/CSS/JS page, no build step, no dependencies except Google Fonts (Sora / Source Sans 3 / JetBrains Mono).
- Published as an Artifact: https://claude.ai/artifact/Xo76ztsw5spyxRPwxseNUd (title "Git Stage Theatre"). If it needs updating, republish the same file path from a session that has this conversation's context, or pass that URL as `url` to Artifact from any session.
- Covers all 21 requested command variants (19 named commands + reset's 3 modes: soft/mixed/hard) across categories Setup & Basics, Look Around, Stage & Commit, Branch & Merge, Undo Tools, Remote.
- Architecture: each command has a hardcoded `before` state snapshot (chips in Working Dir/Staging, commit chains in Local Repo/Remote) and an ordered `steps` array of animation primitives (moveChip, newCommit, moveHead, setBranches, stashTuck/Pop, popup bubbles, etc.), played back via a generic FLIP-based DOM animator. This was a deliberate simplification over a general git-state simulator — keeps every demo correct and clear instead of generic-but-fragile.
- Tested in-browser: command picker/search, box layout at desktop + narrow widths, dark mode via `prefers-color-scheme` and manual toggle, and spot-checked animations (merge with two-lane graph → single merge commit, stash tuck+pop, reset variants) — all ran without console errors after one bug fix (`stepMergeCommit` was reading `current.before.lanes` instead of `current.before.local.lanes`).
- Nothing else needed here unless the user reports something visibly broken.

## Deliverable 2 — Git Speedrun Kit (DESIGN DONE, NOT BUILT)

Target layout under `speedrun/` (currently just an empty folder — nothing else exists yet):

```
speedrun/
  README.md              instructor-facing overview + run order
  tasks.md                all 38 tasks, Base Round 1-20 / Bonus Round 21-38, plain-language, actionable
  setup-team.sh           bash generator — run per team, e.g. ./setup-team.sh TEAM07
  setup-team.ps1          PowerShell equivalent, same repo state
  check-progress.sh       bash verification script, run against a team folder
  check-progress.ps1      PowerShell equivalent
  build-all-teams.sh      loops setup-team.sh for TEAM01..TEAM35 and zips each (optional batch mode)
  build-all-teams.ps1     same, PowerShell
```

### What `setup-team.sh <TEAMNAME>` must produce

A folder `./<TEAMNAME>/` containing:

```
<TEAMNAME>/
  warmup/                       EMPTY folder, not yet a git repo — for tasks 1-4 (init/status/add/commit from scratch)
  cafe-project/                 pre-seeded repo with real history — for tasks 5-38 (except task 20)
  cafe-project-origin.git/      bare repo wired as `origin` of cafe-project — the local "remote"
  bisect-check.sh / .ps1        helper script for the bisect task (task 23), greps for the unresolved bug string
  TASKS.md                      copy of tasks.md for convenience
```

Task 20 (clone) has the team clone `cafe-project-origin.git` into a fresh `cafe-project-clone/` to prove the bare repo works standalone — don't pre-create that folder, that's the point of the task.

### `cafe-project` seed content ("Trailhead Cafe" theme)

Files: `README.md`, `menu.txt`, `about.txt`, `CHANGELOG.md`, `debug.log` (committed by mistake — for the .gitignore/untrack task).

`menu.txt` needs clearly separated, exact-text lines since two different conflict scenarios below depend on editing the *same literal line* from a common ancestor differently (that's what guarantees a real conflict — don't let the two sides drift to different wording or git may auto-merge cleanly). Suggested lines:
```
Drip Coffee ......... $2.50
Latte ......... $4.50
Muffin ......... $3.25
Bagel ......... $2.75
```

**Commit sequence on `main`** (use fixed, incrementing `GIT_AUTHOR_DATE`/`GIT_COMMITTER_DATE` per commit so history is deterministic and reproducible across every team; set repo-local `git config user.name/user.email` so the script never depends on the machine having a global git identity configured):

| # | Message | Change | Author |
|---|---|---|---|
| C1 | Initial commit | add README.md | default (e.g. "Instructor Seed") |
| C2 | Add menu | add menu.txt (4 lines above) | default |
| C3 | Add about page | add about.txt, contact = `hello@trailheadcafe.dev` | default |
| C4 | Oops: commit debug.log by mistake | add debug.log (junk content) | default |
| C5 | BUG: typo in latte price | menu.txt Latte `$4.50` → `$4.05` | **Sam Rivera <sam@cafe.dev>** |
| C6 | Fix latte price | menu.txt Latte `$4.05` → `$4.50` | default |
| C7 | Add daily specials | menu.txt: add "Today's Special: Chai Latte" line, AND bump Muffin `$3.25` → `$3.50` | default |
| C8 | BUG: broken contact email | about.txt `hello@trailheadcafe.dev` → `hello@trailheadcaf.dev` (typo, **left broken** — never fixed in seed history) | **Sam Rivera <sam@cafe.dev>** |
| C9 | Add changelog | add CHANGELOG.md | default |

Local `main` HEAD stops at C9. This is deliberate — see remote section below.

Why these specific bugs exist:
- Bug A (C5→C6, latte price): fixed within the seed history. Used for `git log -S` pickaxe search (task 22, search `"4.05"`) and `git blame`/`git show` (tasks 24-25).
- Bug B (C8, contact email): **left broken** at HEAD on purpose. Used for `git bisect` (task 23) — good commit = C1 (or any pre-C8 commit), bad = HEAD. `bisect-check.sh`/`.ps1` should `grep`/`Select-String` about.txt for the broken domain and exit non-zero (bad) or zero (good), so `git bisect run ./bisect-check.sh` works.

**Branches** (create all after C9, none pre-merged into main):

- `feature/happy-hour` — from **C6** (before C7 touches other lines). One commit: change the `Latte` line to `Latte ......... $3.75  (Happy Hour special)`.
- `feature/weekend-special` — from **C6** too (same ancestor as happy-hour — required for the conflict). One commit: change the *same* `Latte` line to `Latte ......... $5.00  (Weekend Special blend)`.
  - Task 12 (merge conflict) = switch to `feature/happy-hour`, merge `feature/weekend-special` into it. Both changed the same line from the same ancestor differently → guaranteed conflict. (Do **not** merge either into `main` for this — main moved on independently after C6 and wouldn't conflict.)
- `feature/pricing-update` — from **C6**. One commit: change `Muffin` line from `$3.25` to `$3.75`. Since main's C7 *also* changes that same Muffin line (to `$3.50`) from the same C6 ancestor, rebasing this branch onto `main` (task 35) produces a guaranteed conflict on that line.
- `feature/social-links` — from **C9**. One commit: edit about.txt to add a "Follow us: @trailheadcafe" line. Kept isolated so it cherry-picks cleanly onto main (task 31).
- `feature/wip-styles` — from **C9**. Three small commits ("WIP: start style tweaks", "WIP: more tweaks", "Fix typo in WIP commit") touching a small new file (e.g. `styles-notes.txt`) — messy history to squash via interactive rebase (task 32), then `git rebase main` (task 33). Since local main never moves past C9, this rebase will be a near-no-op — note that explicitly in the task text so it doesn't read as broken; the lesson is the mechanics, not drama.

**"Lost commit" for reflog recovery (task 34)** — do this as the very last step of the script, on `cafe-project`, after everything else:
1. Check out C9 **detached** (`git checkout <C9-hash>`).
2. Commit "Experimental: dark mode toggle" (some trivial file change) while detached.
3. Check out `main` again — this abandons the commit with no branch/tag pointing at it. It's still recoverable via `git reflog` since it's fresh in the reflog, which is exactly the exercise.

**"Remote" setup**:
1. `git init --bare cafe-project-origin.git` alongside `cafe-project`.
2. In `cafe-project`, `git remote add origin ../cafe-project-origin.git`, then push `main` (C1–C9) — do this push **before** creating any of the feature branches above, doesn't matter which branches exist yet as long as they're not pushed.
3. Simulate a teammate: clone `cafe-project-origin.git` into a throwaway temp dir, there add one commit **fixing** the Bug B email typo (`hello@trailheadcaf.dev` → `hello@trailheadcafe.dev`), authored as **Jordan Lee <jordan@cafe.dev>**, push it to origin's `main`, then delete the temp clone. Now `origin/main` is ahead of local `main` by exactly one commit the team hasn't fetched — this is what makes tasks 29 (pull) and 30 (fetch) work identically for every team, cleanly (no divergence, since local `main` never advanced past C9 on its own).
4. `feature/loyalty-card` — create from `main` (post-push, so it doesn't matter it's not pushed): one commit "Add loyalty card note". Never push it during setup. This is what task 28 (push) uses — pushing a brand-new branch ref is a clean, always-succeeds push with zero divergence risk, unlike main (deliberately keep push and pull/fetch on separate branches so neither task can accidentally block the other across 35 unattended team runs).

This design was chosen specifically to avoid non-fast-forward / merge-required pushes for task 28, since that would make an already-complex bonus task fragile across many teams. If a "Git rejected my push, now what" lesson is wanted later, that can be a deliberate *additional* stretch task rather than baked into the base scenario.

### Full 38-task list (draft these into `tasks.md`, one task = short title + exact git concept + concrete instructions + a one-line "success looks like" check)

**Base Round (1–20, everyone completes, work in `warmup/` for 1–4 then `cafe-project/` for 5–20):**
1. `git init` in `warmup/`
2. `git status` (on the still-empty warmup repo, then after creating a file)
3. Create a file + `git add`
4. `git commit`
5. `git log` (in cafe-project)
6. `git diff` (unstaged) — student edits a file first
7. `git diff --staged` — student stages first
8. `git commit --amend` — fix the previous commit's message or content
9. `git branch <name>` — create a throwaway branch
10. `git switch`/`git checkout` — switch to it and back
11. Fast-forward `git merge`
12. Merge conflict: `feature/happy-hour` ← `feature/weekend-special` (seeded, see above) — resolve by hand
13. `git restore <file>` — discard an unstaged change
14. `git restore --staged <file>` — unstage without discarding
15. `git reset --soft`
16. `git reset --mixed`
17. `git reset --hard` (with a warning about data loss)
18. `git revert <commit>`
19. `git stash` + `git stash pop`
20. `git clone` — clone `cafe-project-origin.git` into `cafe-project-clone/`

**Bonus Round (21–38, faster teams, all in `cafe-project/` unless noted):**
21. `git log` filters (`--author`, `--grep`, `-n`) — use the Sam Rivera commits
22. `git log -S "4.05"` — pickaxe search to find the bug-introducing commit (C5)
23. `git bisect` (+ `bisect-check.sh`) — find the commit that broke the contact email (C8)
24. `git blame about.txt` — find who/when last touched the broken email line
25. `git show <commit>` — inspect C6 (the fix) in detail
26. `git tag` — create a lightweight and an annotated tag
27. `git remote -v` — inspect origin, then add a second remote alias pointing at the same bare repo
28. `git push` — push `feature/loyalty-card` to origin (clean, no divergence)
29. `git pull` — pull Jordan's email-fix commit into local `main`
30. `git fetch` + inspect `origin/main` vs `main` without merging (do this *before* task 29 if teaching fetch-then-decide, or reseed — pick one ordering and make it explicit in tasks.md since fetch after pull has nothing new to show)
31. `git cherry-pick` — bring `feature/social-links`'s one commit onto `main`
32. Interactive rebase (`git rebase -i`) — squash `feature/wip-styles`'s 3 commits into 1
33. `git rebase main` — rebase `feature/wip-styles` onto main (near-no-op, see note above)
34. `git reflog` — recover the "Experimental: dark mode toggle" commit lost in setup
35. Rebase conflict — `git rebase main` on `feature/pricing-update` (guaranteed conflict on the Muffin line), resolve it
36. `.gitignore` + `git rm --cached debug.log` — stop tracking the accidentally-committed file
37. `git diff branchA..branchB` — compare two branches
38. Detached HEAD — check out an old commit directly, make an experimental commit, then save it with `git switch -c <new-branch>` before it gets lost like task 34's did

**Note on task 30 ordering**: task 29 (pull) and task 30 (fetch) both key off the same single seeded divergence (Jordan's commit on origin, not yet in local main). Doing pull first consumes the divergence, leaving nothing for fetch to show. Either reorder so fetch (30) comes before pull (29) in the actual task numbering/instructions, or have task 30's instructions explicitly say "if you already pulled in task 29, that's fine — run `git fetch` anyway and note that `origin/main` and `main` now match, which is itself worth seeing." Pick whichever reads more naturally when writing tasks.md; don't leave it unresolved.

### `check-progress.sh` / `.ps1` — verification script

Run against a team's folder (`./check-progress.sh path/to/TEAMNAME`), prints PASS/FAIL/SKIP per task plus a total score. Aim to automatically verify what's cleanly checkable via git plumdbing; mark the rest `SKIP (manual)` rather than faking coverage. Good automatable candidates:
- warmup/ is a git repo with ≥1 commit (tasks 1-4)
- `cafe-project` working tree is clean + specific branches exist (various)
- Task 12: `feature/happy-hour` has a merge commit with 2 parents, working tree clean, no conflict markers in menu.txt
- Task 22/23: correct commit identified — hard to verify "the student typed the right answer" without them recording it somewhere; consider having tasks.md ask students to write the commit hash into a small `ANSWERS.md` in their team folder, which check-progress.sh can then diff against known-correct hashes (compute those hashes once during setup-team.sh and stash them in a hidden `.answers` file for the checker to compare against — don't show `.answers` to students)
- Task 28/29/30: compare `git rev-parse` of local vs `git --git-dir=cafe-project-origin.git rev-parse main` and the relevant branch
- Task 31 (cherry-pick): main's log contains a commit with the same patch-id as `feature/social-links`'s commit (`git patch-id`)
- Task 34/38: a reachable ref (branch/tag) exists pointing at a commit whose message matches the "lost"/experimental commit
- Task 36: `debug.log` untracked but present, and mentioned in `.gitignore`
- Reset/restore/stash tasks (13-19): inherently transient/practice — hard to verify after the fact since later tasks overwrite the state; mark these manual/instructor-observed, or have students commit a marker file after each as an "I did this" breadcrumb if scoring precision matters more than workshop flow

Decide the `ANSWERS.md`-based checking approach (or drop it for a simpler subset of checks) when actually implementing — it's the one part of this design not fully pinned down.

### Packaging

- `build-all-teams.sh` / `.ps1`: loop `TEAM01`..`TEAM35`, call `setup-team.sh $name` for each into a common output dir, then zip each team folder. Keep `setup-team.sh` itself simple/standalone (no dependency on the batch wrapper) since the primary distribution mode is "hand each team the script, they run it themselves" — batch zipping is the optional secondary mode.

## Next steps

1. Write `tasks.md` with the full 38-task text (see table above for the git mechanics; still need the plain-language framing/success-criteria per task).
2. Write `setup-team.sh` implementing the commit/branch/remote sequence above exactly, with deterministic dates and repo-local git identity.
3. Write `setup-team.ps1` as a faithful PowerShell port — same git commands, same order, same content. Test both produce identical `git log --oneline --all --graph` output for a given team name (only the team name / any team-specific file content should differ, not the base structure).
4. Test end-to-end: run `setup-team.sh TEST01`, manually complete a few tasks (especially task 12's conflict and task 23's bisect), confirm they behave as designed.
5. Write `check-progress.sh`/`.ps1` against the real generated structure, decide on the `ANSWERS.md` mechanism or simplify.
6. Write `build-all-teams.sh`/`.ps1`.
7. Write `README.md` tying it together for the instructor (run order, how to hand out, how to score).
8. Confirm the distribution-mode assumption with the user (self-run script vs pre-zipped) since it was never explicitly reconfirmed after "wdym."

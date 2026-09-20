# Live Demo Script — Git Stage Theatre walkthrough

For teaching at the front of the room: project the **[Git Stage Theatre
visualizer](https://claude.ai/artifact/Xo76ztsw5spyxRPwxseNUd)** on one
screen/window and a terminal in `instructor-demo/` on another (or switch
between them). For each command below: click it in the visualizer, hit
**Run**, talk through the animation, then type the real thing live so
students see the animation and the actual tool agree.

## Setup (once, before class)

```bash
cd demo
./start-demo.sh
```

or on native PowerShell:

```powershell
cd demo
.\start-demo.ps1
```

This creates `instructor-demo/` next to this file, with the same structure
every team gets:

```
instructor-demo/
  warmup/                   empty -- for the first few live commands
  cafe-project/              seeded repo -- for everything else
  cafe-project-origin.git/   the local fake remote
```

**Before every class / rehearsal**, wipe it back to a clean slate:

```bash
./start-demo.sh --reset
```
```powershell
.\start-demo.ps1 -Reset
```

Do this liberally — several demos below (merge conflict, reset --hard,
reflog recovery) permanently change the demo repo's state, and re-running
`--reset` is instant and always gets you back to exactly the same starting
point.

---

## Part 1 — Setup & Basics (work in `instructor-demo/warmup/`)

### `git init`
**Say:** "This turns an ordinary folder into a Git repository. Nothing else
happens yet."
**Type:**
```bash
cd instructor-demo/warmup
git init
git config user.email "you@example.com"   # skip these two lines if this
git config user.name "Your Name"          # machine already has git identity set
```
**Watch for:** `Initialized empty Git repository in .../warmup/.git/`
**Say:** "If your very first commit later fails with 'Please tell me who you
are,' this is why — those two config lines only need to be run once per
repo."

### `git status`
**Say:** "Status never changes anything — it's always safe to run. Use it
constantly."
**Type:**
```bash
git status
echo "Buy oat milk" > notes.txt
git status
```
**Watch for:** clean tree first, then `notes.txt` listed as untracked.

### `git add`
**Say:** "Add copies a change into the staging area — it doesn't save it
permanently yet, just marks it 'ready.'"
**Type:**
```bash
git add notes.txt
git status
```
**Watch for:** `notes.txt` now under "Changes to be committed," in green.

### `git commit`
**Say:** "Commit takes everything staged and permanently records it as a
snapshot. This is the only step that's actually saved to history."
**Type:**
```bash
git commit -m "Add notes"
git log --oneline
```
**Watch for:** one commit in the log.

### `git clone`
**Say:** "Clone downloads an entire project's history in one step and checks
out a working copy — this is usually the very first command you run on a new
machine."
**Type** (from `instructor-demo/`, one level up):
```bash
cd ..
git clone cafe-project-origin.git cafe-project-clone-demo
cd cafe-project-clone-demo && git log --oneline && cd ..
```
**Watch for:** a full 9-commit history appears instantly, and `origin` is
already configured (`git remote -v` inside it proves it).
**Cleanup:** `rm -rf cafe-project-clone-demo` when done — it's disposable.

---

## Part 2 — Look Around (switch to `instructor-demo/cafe-project/`)

```bash
cd instructor-demo/cafe-project
```

### `git log`
**Say:** "This is the project's real history — a small fictional cafe site.
Nine commits, oldest at the bottom."
**Type:**
```bash
git log --oneline
```

### `git diff`
**Say:** "Diff shows exactly what changed, before you've staged it."
**Type:**
```bash
echo "Oat milk ......... +\$0.60" >> menu.txt
git diff
```
**Watch for:** a `+` line for what you just added.
**Cleanup:** `git restore menu.txt` (this also previews Part 4's `restore`).

### `git show`
**Say:** "Show gives you the full story of one commit — message, author, and
diff — without digging through the whole log."
**Type:**
```bash
git show 563a743
```
(`563a743` is "Fix latte price" — if the hash ever changes after a reseed,
grab a fresh one with `git log --oneline`.)
**Watch for:** the exact line change, `$4.05` → `$4.50`.

---

## Part 3 — Stage & Commit, Branch & Merge

### `git branch`
**Say:** "Branch just creates a new label pointing at your current commit —
you don't move onto it yet."
**Type:**
```bash
git branch demo-topic
git branch
```
**Watch for:** `demo-topic` listed, `*` still on `main`.

### `git switch`
**Type:**
```bash
git switch demo-topic
echo "New: seasonal pumpkin spice latte" >> menu.txt
git commit -am "Add pumpkin spice latte"
git switch main
```
**Watch for:** the `*` moves; back on `main`, `menu.txt` doesn't have the new
line yet.

### `git merge` (fast-forward)
**Say:** "Since main hasn't moved since we branched, this just fast-forwards
— no new merge commit needed."
**Type:**
```bash
git merge demo-topic
git log --oneline -3
```
**Watch for:** `Fast-forward` in the output.

### `git merge` (real conflict)
**Say:** "Now the interesting case — two branches changed the *same line*
differently. Git can't guess which one you want."
**Type:**
```bash
git switch feature/happy-hour
git merge feature/weekend-special
```
**Watch for:** `CONFLICT (content): Merge conflict in menu.txt`. Open the
file live, show the `<<<<<<<` / `=======` / `>>>>>>>` markers on the `Latte`
line.
**Resolve live:**
```bash
# pick one, combine them, or write something new -- then:
git add menu.txt
git commit -m "Merge weekend-special into happy-hour"
git switch main
```
**Talking point:** this is *exactly* what tasks.md task 12 asks every team to
do themselves — you're showing them the move before they do it.

---

## Part 4 — Undo Tools (dedicated scratch file so nothing else is disturbed)

```bash
echo "line one" > scratch.txt && git add scratch.txt && git commit -m "scratch: baseline"
```

### `git restore`
**Type:**
```bash
echo "oops a typo" >> scratch.txt
git status
git restore scratch.txt
git status
```
**Watch for:** the edit is gone, back to the committed version — file
unchanged since baseline.

### `git restore --staged`
**Type:**
```bash
echo "a real change" >> scratch.txt
git add scratch.txt
git restore --staged scratch.txt
git status
```
**Watch for:** the change is still there, just unstaged again.

### `git reset --soft` / `--mixed` / `--hard`
**Say:** "All three move your branch pointer back one commit. The difference
is what happens to the change itself."
**Type:**
```bash
git add scratch.txt && git commit -m "scratch: change A"
git reset --soft HEAD~1
git status                     # still staged, ready to re-commit
git commit -m "scratch: change A again"

git reset --mixed HEAD~1
git status                     # change is back, but unstaged

git add scratch.txt && git commit -m "scratch: change B"
git reset --hard HEAD~1
git status                     # completely clean -- the change is GONE
```
**Say (before `--hard`):** "This one actually deletes the uncommitted work.
There's no `git restore` for this — say it out loud every time you use it in
real life."

### `git stash`
**Type:**
```bash
echo "half-finished idea" >> scratch.txt
git status
git stash
git status              # clean again
git stash pop
git status              # the edit is back -- but uncommitted
git restore scratch.txt # tidy up before the next demo
```

### `git revert`
**Say:** "Last one for this section. Unlike the scratch file, this one works
on real project history — reverting undoes an already-committed (and, in
real life, already-shared) change safely, by adding a new commit on top."
**Type:**
```bash
git log --oneline -5
git revert 43f03b4 --no-edit   # "Add changelog" -- pick any real hash from the log above
git log --oneline -2
ls CHANGELOG.md   # gone
```
**Watch for:** a *new* commit ("Revert 'Add changelog'") sits on top;
`CHANGELOG.md` is gone from the working directory, but the original commit
is still sitting right there in `git log` — nothing was deleted from
history, unlike `reset --hard`. This is why revert is the safe choice once
something's been pushed/shared.
**Note:** stick to reverting the changelog commit specifically if you've run
the earlier `menu.txt`-touching demos in this same session (fast-forward
merge, the conflict resolve) — reverting a commit that touches `menu.txt`
can legitimately conflict with those, which is a fine bonus lesson if it
happens (`git revert --abort` gets you out), but not what this step is
trying to demonstrate.

---

## Part 5 — Remote (push / pull / fetch)

**Say before starting:** "`origin` here isn't GitHub — it's a plain folder
on this machine (`cafe-project-origin.git`) acting as a stand-in remote. Same
commands, same behavior, no account needed. Every team's repo has one of
these too."

### `git remote -v`
**Type:**
```bash
git remote -v
```

### `git push`
**Say:** "This branch only exists locally so far — pushing it is a clean,
no-surprises upload."
**Type:**
```bash
git push origin feature/loyalty-card
```
**Watch for:** git reports the new branch created on the remote, no
conflicts.

### `git fetch`
**Say:** "A teammate — Jordan — already pushed a fix to `origin/main` that
we don't have locally yet. Fetch downloads it *without* touching our files."
**Type:**
```bash
git fetch origin
git log main --oneline -1
git log origin/main --oneline -1
```
**Watch for:** `main` and `origin/main` point at different commits — Jordan's
fix is visible but not merged in yet.

### `git pull`
**Say:** "Pull is fetch *plus* merge, in one step."
**Type:**
```bash
git pull origin main
git log --oneline -3
```
**Watch for:** Jordan's "Fix contact email typo" change is now on `main`. If
your local `main` had no extra commits of its own since you started this
demo, git fast-forwards silently; if you've run other demos that added
commits to `main` earlier in this session (the fast-forward-merge or revert
steps above both do), you'll see git create a real merge commit instead —
either way works and is worth narrating ("see, pull really is just fetch +
merge — here it had to actually merge instead of fast-forward").
```bash
cat about.txt   # contact email is fixed now
```

---

## Wrap-up talking points

- Every animation in the visualizer has a real command behind it — nothing
  you just did was special-cased for the demo.
- Point out that **every team's repo starts in exactly this same state** —
  the merge conflict, the remote setup, all of it — so what you just showed
  live is precisely what they're about to do themselves in `tasks.md`.
- Before the next session (or the next run-through), reset:
  ```bash
  cd demo && ./start-demo.sh --reset
  ```

## If something goes sideways live

- Mid-conflict and want out: `git merge --abort` (or `git rebase --abort`
  during a rebase).
- Repo's just confusing at this point: `./start-demo.sh --reset` from the
  `demo/` folder — 10 seconds, fully clean, no harm done.
- `git status` any time you're not sure what state you're in — always safe,
  never changes anything.
- On Windows, `--reset` can occasionally fail with "Device or resource busy"
  if your terminal is still `cd`'d inside `instructor-demo/` (a transient
  file-lock, not a real error) — `cd` back out to `demo/` first, or just run
  `--reset` again.

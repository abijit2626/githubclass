# Git Speedrun — Task List

Work through the **Base Round** first (tasks 1–20). Everyone should finish these. If your team finishes early, move on to the **Bonus Round** (21–38) in order — some of them build on earlier ones, so don't skip around.

Two folders matter:
- `warmup/` — completely empty, not yet a git repo. Used for tasks 1–4.
- `cafe-project/` — a repo with real history already in it, themed around a fictional "Trailhead Cafe." Used for tasks 5–38 (except task 20, which creates its own folder).

Run all commands from inside the relevant folder unless a task says otherwise.

---

## Base Round (everyone does these)

### 1. `git init`
**Concept:** starting a brand-new repo.
**Do:** `cd` into `warmup/` and run `git init`. If you've never used git on this machine before, also run `git config user.email "you@example.com"` and `git config user.name "Your Name"` (any values work) — otherwise your first commit in task 4 will fail with "Please tell me who you are."
**Success looks like:** `git status` runs without "not a git repository" — a `.git` folder now exists inside `warmup/`.

### 2. `git status`
**Concept:** checking what git sees.
**Do:** Run `git status` on the empty repo. Then create any file (e.g. `notes.txt`) and run `git status` again.
**Success looks like:** the first run shows "nothing to commit," the second shows your new file listed as untracked.

### 3. Create a file + `git add`
**Concept:** staging changes.
**Do:** Put some text in `notes.txt`, then run `git add notes.txt`.
**Success looks like:** `git status` shows `notes.txt` in green / under "Changes to be committed."

### 4. `git commit`
**Concept:** saving a snapshot.
**Do:** `git commit -m "Add notes"`.
**Success looks like:** `git log` shows one commit with that message.

### 5. `git log`
**Concept:** viewing history.
**Do:** In `cafe-project/`, run `git log` and `git log --oneline`.
**Success looks like:** you can see 9 commits, oldest being "Initial commit."

### 6. `git diff` (unstaged)
**Concept:** seeing what changed before staging.
**Do:** Edit `menu.txt` (change anything), don't stage it, run `git diff`.
**Success looks like:** the diff output shows your edit with `-`/`+` lines. Run `git restore menu.txt` afterward to clean up before continuing.

### 7. `git diff --staged`
**Concept:** seeing what's staged vs. what's committed.
**Do:** Edit `menu.txt` again, run `git add menu.txt`, then `git diff --staged`.
**Success looks like:** the diff shows up under `--staged` and plain `git diff` now shows nothing. Commit it or `git restore --staged` + `git restore` to reset before moving on.

### 8. `git commit --amend`
**Concept:** fixing the most recent commit.
**Do:** Make a small commit (any change), then run `git commit --amend -m "<a better message>"`.
**Success looks like:** `git log` still shows the same number of commits, but the message changed and the commit hash is different.

### 9. `git branch <name>`
**Concept:** creating a branch pointer.
**Do:** `git branch scratch`.
**Success looks like:** `git branch` lists `scratch` alongside `main`, and you're still on `main`.

### 10. `git switch` / `git checkout`
**Concept:** moving between branches.
**Do:** `git switch scratch`, confirm with `git branch`, then `git switch main`.
**Success looks like:** the `*` in `git branch` output moves to `scratch` and back to `main`.

### 11. Fast-forward `git merge`
**Concept:** merging when there's nothing to reconcile.
**Do:** On `scratch`, make one commit (any small file change). Switch to `main`, run `git merge scratch`.
**Success looks like:** git says "Fast-forward," and `main` now includes that commit with no new merge commit created.

### 12. Merge conflict
**Concept:** resolving a real conflict by hand.
**Do:** `git switch feature/happy-hour`, then `git merge feature/weekend-special`. Git will stop and report a conflict in `menu.txt`. Open the file, find the `<<<<<<<` / `=======` / `>>>>>>>` markers on the `Latte` line, pick or combine the wording, delete the markers, then `git add menu.txt` and `git commit`.
**Success looks like:** `git status` shows a clean working tree, no `<<<<<<<` markers remain anywhere in `menu.txt`, and `git log --graph --oneline` shows a merge commit with two parents.

### 13. `git restore <file>`
**Concept:** discarding an unstaged change.
**Do:** Edit `about.txt` (don't stage it), then `git restore about.txt`.
**Success looks like:** `git diff` is empty and the file is back to its committed content.

### 14. `git restore --staged <file>`
**Concept:** unstaging without losing the edit.
**Do:** Edit `about.txt`, `git add about.txt`, then `git restore --staged about.txt`.
**Success looks like:** `git status` shows the file as modified-but-unstaged (not staged) — your edit is still there, just not staged.

### 15. `git reset --soft`
**Concept:** undoing a commit but keeping everything staged.
**Do:** Make a small commit, then `git reset --soft HEAD~1`.
**Success looks like:** `git log` shows one fewer commit, but `git status` shows your change still staged and ready to commit again.

### 16. `git reset --mixed`
**Concept:** undoing a commit and unstaging it (default reset mode).
**Do:** Commit again, then `git reset --mixed HEAD~1` (or just `git reset HEAD~1`).
**Success looks like:** the commit is gone from `git log`, and the change is present but unstaged in `git status`.

### 17. `git reset --hard`
**Concept:** undoing a commit and throwing away the change entirely. **This deletes work — there's no undo for the file content itself.**
**Do:** Commit one more small change, then `git reset --hard HEAD~1`.
**Success looks like:** the commit is gone from `git log` and `git status` is completely clean — the edit is gone, not just unstaged.

### 18. `git revert <commit>`
**Concept:** undoing a commit safely, by adding a new commit that cancels it out — good for shared history you don't want to rewrite.
**Do:** Pick any commit hash from `git log` on `main` (not the very first one) and run `git revert <hash>`. Git may open an editor for the commit message — save and close it.
**Success looks like:** `git log` has a new commit on top whose message starts with "Revert," and the original commit is still visible further back in history (nothing was deleted).

### 19. `git stash` + `git stash pop`
**Concept:** temporarily shelving unfinished work.
**Do:** Edit a file without committing, run `git stash`, confirm with `git status` (clean), then `git stash pop`.
**Success looks like:** after `git stash`, your edit disappears from `git status`; after `git stash pop`, it's back.

### 20. `git clone`
**Concept:** getting a full copy of a repo, including all its history.
**Do:** From your team folder (one level above `cafe-project/`), run `git clone cafe-project-origin.git cafe-project-clone`.
**Success looks like:** a new `cafe-project-clone/` folder exists with a full working copy, and `git log` inside it matches `origin`'s history.

---

## Bonus Round (if you finish early)

All of these are in `cafe-project/` unless noted.

### 21. `git log` filters
**Concept:** narrowing down history.
**Do:** Try `git log --author="Sam Rivera"`, `git log --grep="BUG"`, and `git log -n 3`.
**Success looks like:** the author filter shows exactly 2 commits; the grep filter shows the 2 "BUG:" commits.

### 22. `git log -S` (pickaxe search)
**Concept:** finding the commit that introduced or removed a specific piece of text, not just a matching commit message.
**Do:** Run `git log -S "4.05" --oneline`. This finds every commit that changed *how many times* "4.05" appears in the file — so it'll catch both where it was introduced and where it was removed.
**Success looks like:** two commits show up — "BUG: typo in latte price" (introduced it) and "Fix latte price" (removed it). Write the short hash of the **BUG** commit into `ANSWERS.md` in your team folder as `task22=<hash>`.

### 23. `git bisect`
**Concept:** binary-searching history to find the exact commit that broke something, without eyeballing every commit.
**Do:** From inside `cafe-project/`, run:
```
git bisect start
git bisect bad HEAD
git bisect good <hash of the "Add about page" commit>
git bisect run bash ../bisect-check.sh
```
(On Windows without Git Bash, use `git bisect run pwsh ../bisect-check.ps1` instead — or `powershell -File ../bisect-check.ps1`.)
Git will walk the history automatically and report the first bad commit. Run `git bisect reset` afterward to return to `main`.
**Do this before task 29 (pull)** — pulling brings in a fix for this exact bug, which would make the bug disappear before you get to hunt for it. If your team already pulled, ask your instructor for a pre-pull commit hash to bisect against instead.
**Success looks like:** git reports the "BUG: broken contact email" commit as the first bad commit. Write its short hash into `ANSWERS.md` as `task23=<hash>`.

### 24. `git blame`
**Concept:** seeing who last touched each line of a file, and in which commit.
**Do:** Run `git blame about.txt`.
**Success looks like:** you can point to the line with the contact email and name both the commit and author (Sam Rivera) that last changed it.

### 25. `git show <commit>`
**Concept:** inspecting one commit in detail — message, author, and full diff.
**Do:** Run `git show` on the "Fix latte price" commit hash.
**Success looks like:** you can see the exact line change ($4.05 → $4.50) in the output.

### 26. `git tag`
**Concept:** marking a specific commit with a permanent, memorable name.
**Do:** Create a lightweight tag: `git tag v0.1-lightweight`. Create an annotated tag: `git tag -a v0.1-annotated -m "First stable menu"`.
**Success looks like:** `git tag` lists both, and `git show v0.1-annotated` displays your message (lightweight tags won't show a message this way — that's the difference).

### 27. `git remote -v`
**Concept:** seeing what remotes a repo is configured with.
**Do:** Run `git remote -v`, then add a second remote pointing at the same bare repo: `git remote add backup ../cafe-project-origin.git`.
**Success looks like:** `git remote -v` now lists both `origin` and `backup`, both pointing at `cafe-project-origin.git`.

### 28. `git push`
**Concept:** sending local commits to a remote.
**Do:** Run `git push origin feature/loyalty-card`.
**Success looks like:** git reports the push succeeded and creates the branch on the remote — no errors, no "rejected."

### 29. `git pull`
**Concept:** fetching and merging remote changes in one step.
**Do:** From `main`, run `git pull origin main`.
**Success looks like:** you get a new commit fixing the contact-page typo, authored by Jordan Lee, that you didn't write yourself.

### 30. `git fetch`
**Concept:** downloading remote changes without merging them yet, so you can inspect first.
**Do:** Run `git fetch origin`, then compare `git log main` against `git log origin/main`.
**Success looks like:** if you haven't done task 29 yet, `origin/main` shows one commit ahead of `main` that you haven't merged in. If you already did task 29, that's fine — run `git fetch` anyway and confirm `main` and `origin/main` now point at the same commit, which is itself worth seeing.

### 31. `git cherry-pick`
**Concept:** copying one specific commit from another branch onto your current branch.
**Do:** From `main`, run `git cherry-pick` with the hash of `feature/social-links`'s one commit (find it with `git log feature/social-links`).
**Success looks like:** `main` now has a new commit adding `social.txt` (with the "Follow us" line), and `feature/social-links` itself is untouched.

### 32. Interactive rebase — squash
**Concept:** cleaning up messy WIP commits into one before sharing them.
**Do:** `git switch feature/wip-styles`, then `git rebase -i HEAD~3`. In the editor, change the second and third commits' `pick` to `squash` (or `s`), save, then save the combined commit message.
**Success looks like:** `git log feature/wip-styles --oneline` shows 1 commit instead of 3, and `styles-notes.txt` still has all the content from all three original commits.

### 33. `git rebase main`
**Concept:** replaying your branch's commits on top of the latest `main`.
**Do:** Still on `feature/wip-styles`, run `git rebase main`.
**Success looks like:** the rebase completes with no conflicts (this one's quiet on purpose — `main` hasn't moved since this branch was created, so there's nothing to replay past). The lesson is the mechanics: know the command and what "replaying commits" means, even when the result is uneventful.

### 34. `git reflog`
**Concept:** recovering a commit that no branch or tag points to anymore.
**Do:** Run `git reflog`. Somewhere in the list you'll find a commit titled "Experimental: dark mode toggle" that isn't reachable from any branch. Recover it: `git switch -c recovered-dark-mode <hash>`.
**Success looks like:** a new branch `recovered-dark-mode` exists and `git log` on it shows the "Experimental: dark mode toggle" commit.

### 35. Rebase conflict
**Concept:** resolving a conflict that comes up mid-rebase (different workflow than a merge conflict — same markers, different commands to finish).
**Do:** `git switch feature/pricing-update`, then `git rebase main`. Git will stop on a conflict in `menu.txt` (the Muffin line). Fix the file, remove the `<<<<<<<`/`=======`/`>>>>>>>` markers, then `git add menu.txt` and `git rebase --continue` (not `git commit` — that's the merge-conflict habit, rebase is different).
**Success looks like:** `git rebase --continue` finishes with no more conflicts, `git status` is clean, and no conflict markers remain in `menu.txt`.

### 36. `.gitignore` + `git rm --cached`
**Concept:** stopping git from tracking a file that got committed by mistake, without deleting it from disk.
**Do:** On `main`, create a `.gitignore` file containing `debug.log`, then run `git rm --cached debug.log`, then commit both changes.
**Success looks like:** `debug.log` still exists on disk, `git status` no longer lists it as tracked, and future edits to it don't show up in `git status` at all.

### 37. `git diff branchA..branchB`
**Concept:** comparing two branches directly.
**Do:** Run `git diff feature/happy-hour..feature/weekend-special`.
**Success looks like:** you can see both branches' different edits to the same Latte line side by side in one diff.

### 38. Detached HEAD
**Concept:** knowing when you're not on a branch, and how to save work from that state before it's lost.
**Do:** Check out an old commit directly by hash (not a branch name) — git will warn you that you're in "detached HEAD" state. Make a small experimental commit here. Before switching away, run `git switch -c my-experiment` to save it onto a real branch.
**Success looks like:** `git branch` shows your new branch pointing at the experimental commit — you avoided the same "orphaned commit" situation task 34 asked you to recover from.

---

## Notes

- If you make a genuine mess, ask your instructor rather than deleting your team folder and starting over — most of these tasks are designed to be recoverable, and recovering from a mess is half the lesson.
- `git status` is always safe to run and never changes anything. When unsure what state you're in, run it.

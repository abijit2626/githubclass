# Git Speedrun — Task List

24 short tasks. Do the **Base Round** (1–16) first, in order. Finished early? Try the **Bonus Round** (17–24).

Two folders matter:
- `warmup/` — empty, not a git repo yet. Tasks 1–4.
- `cafe-project/` — a repo with history already in it (a made-up "Trailhead Cafe"). Tasks 5–24, except task 16, which makes its own folder.

Run every command from inside the folder the task names.

Text editor popped up (looks scary, full of `~`)? You forgot `-m` or `--no-edit`. Press `Esc`, type `:wq`, press `Enter`.

---

## Base Round

### 1. `git init`
**Do:** `cd warmup`, then `git init`.
First time using git on this computer? Also run these two lines (any values work) or task 4 will fail:
`git config user.email "you@example.com"`
`git config user.name "Your Name"`
**Done when:** a hidden `.git` folder exists inside `warmup/`.

### 2. `git status`
**Do:** run `git status`. Create a file, `notes.txt`, with any text. Run `git status` again.
**Done when:** the second run lists `notes.txt` as untracked.

### 3. `git add`
**Do:** `git add notes.txt`, then `git status`.
**Done when:** `notes.txt` is listed under "Changes to be committed".

### 4. `git commit`
**Do:** `git commit -m "Add notes"`
**Done when:** `git log` shows your commit.

### 5. `git log`
**Do:** `cd ../cafe-project`, then run `git log --oneline`.
**Done when:** you can count 9 commits, oldest is "Initial commit".

### 6. `git diff`
**Do:** edit `menu.txt` (change any price), then run `git diff`.
**Done when:** you see your change as a `-` line and a `+` line.

### 7. `git restore`
**Do:** `git restore menu.txt`
**Done when:** `git status` says nothing to commit and your edit is gone.

### 8. `git branch`
**Do:** `git branch scratch`
**Done when:** `git branch` lists `scratch` next to `main`.

### 9. `git switch`
**Do:** `git switch scratch`, run `git branch`, then `git switch main`.
**Done when:** the `*` moved to `scratch` and back to `main`.

### 10. Fast-forward merge
**Do:** `git switch scratch`. Edit `menu.txt`, then `git commit -am "Scratch change"`. Now `git switch main` and `git merge scratch`.
**Done when:** git says `Fast-forward`.

### 11. Merge conflict
**Do:**
`git switch feature/happy-hour`
`git merge feature/weekend-special`
Git stops and says CONFLICT in `menu.txt`. Open `menu.txt`, find the `<<<<<<<`, `=======`, `>>>>>>>` lines around `Latte`. Keep the line(s) you want and delete the three marker lines. Then:
`git add menu.txt`
`git commit -m "Resolve latte conflict"`
**Done when:** `git status` is clean and `menu.txt` has no `<<<<<<<`.

### 12. `git reset --soft`
**Do:** `git switch main`. Edit `menu.txt`, then `git commit -am "Oops"`. Run `git reset --soft HEAD~1`.
**Done when:** the "Oops" commit is gone from `git log`, but `git status` still shows your change staged.

### 13. `git reset --hard`
**Careful: this deletes work for good.**
**Do:** `git commit -m "Oops again"` (your change is still staged), then run `git reset --hard HEAD~1`.
**Done when:** the commit is gone from `git log` and `git status` is completely clean.

### 14. `git revert`
**Do:** run `git log --oneline`, copy the short hash of "Add changelog", then `git revert <that-hash> --no-edit`.
**Done when:** a new commit called `Revert "Add changelog"` is on top, and `CHANGELOG.md` is gone.

### 15. `git stash`
**Do:** edit `about.txt`. Run `git stash`, check `git status` (clean), then run `git stash pop`.
**Done when:** the edit disappeared after `stash` and came back after `stash pop`.
Tidy up: `git restore about.txt`

### 16. `git clone`
**Do:** go up one folder (`cd ..`) so you can see `cafe-project-origin.git`, then run `git clone cafe-project-origin.git cafe-project-clone`
**Done when:** a new `cafe-project-clone/` folder exists and `git log` inside it shows history.

---

## Bonus Round

Back in `cafe-project/` for all of these.

### 17. `git show`
**Do:** find "Fix latte price" in `git log --oneline`, then `git show <its-hash>`.
**Done when:** you can see the price change from `$4.05` to `$4.50`.

### 18. `git tag`
**Do:** `git tag v1-light`, then `git tag -a v1-note -m "First version"`
**Done when:** `git tag` lists both.

### 19. `git remote`
**Do:** `git remote -v`, then `git remote add backup ../cafe-project-origin.git`
**Done when:** `git remote -v` lists `origin` and `backup`.

### 20. `git push`
**Do:** `git push origin feature/loyalty-card`
**Done when:** git says `new branch` and there's no error.

### 21. `git fetch`
A teammate (Jordan) already pushed a fix to the remote. Go get it without changing your files.
**Do:** `git fetch origin`, then compare `git log main --oneline -1` with `git log origin/main --oneline -1`.
**Done when:** `origin/main` shows a commit that `main` doesn't have.

### 22. `git pull`
**Do:** `git switch main`, then `git pull --no-edit origin main`
**Done when:** `about.txt` now says `hello@trailheadcafe.dev` (Jordan's fix).

### 23. `git cherry-pick`
**Do:** find the hash with `git log feature/social-links --oneline -1`, then on `main` run `git cherry-pick <that-hash>`
**Done when:** `social.txt` exists on `main`.

### 24. `.gitignore`
`debug.log` was committed by mistake. Make git stop tracking it, without deleting the file.
**Do:**
Create a file named `.gitignore` in your editor, containing one line: `debug.log`
`git rm --cached debug.log`
`git add .gitignore`
`git commit -m "Stop tracking debug.log"`
**Done when:** `debug.log` is still in your folder, but `git status` no longer mentions it.

---

Stuck or made a mess? Ask the instructor. `git status` is always safe to run.

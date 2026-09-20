#!/usr/bin/env bash
# Checks a team's progress through the Git Speedrun tasks.
#
# Usage: ./check-progress.sh path/to/TEAMNAME
#
# Every check here is read-only: it inspects git plumbing (refs, objects,
# ls-remote) without checking out branches or touching the student's working
# tree. Tasks that are inherently transient (a diff you looked at, a stash
# you popped) can't be verified after the fact and are marked SKIP rather
# than faked. See speedrun/tasks.md for what each task actually asks for.

set -uo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <path-to-team-folder>" >&2
  exit 1
fi

if [ ! -d "$1" ]; then
  echo "Error: '$1' is not a directory." >&2
  exit 1
fi

TEAM_DIR="$(cd "$1" && pwd)"
WARMUP="$TEAM_DIR/warmup"
CAFE="$TEAM_DIR/cafe-project"
ORIGIN="$TEAM_DIR/cafe-project-origin.git"
CLONE_DIR="$TEAM_DIR/cafe-project-clone"
ANSWERS_FILE="$TEAM_DIR/.answers"
STUDENT_ANSWERS="$TEAM_DIR/ANSWERS.md"

PASS=0
FAIL=0
SKIPN=0

pass() { echo "[PASS] Task $1 - $2"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] Task $1 - $2"; FAIL=$((FAIL+1)); }
skip() { echo "[SKIP] Task $1 - $2 (manual/instructor-observed)"; SKIPN=$((SKIPN+1)); }

gcafe() { git -C "$CAFE" "$@" 2>/dev/null; }

echo "Checking team folder: $TEAM_DIR"
echo ""

# ---------------- Base Round ----------------

if [ -d "$WARMUP/.git" ]; then
  pass 1 "warmup/ is a git repo"
else
  fail 1 "warmup/ is a git repo"
fi

skip 2 "git status"
skip 3 "git add (staging is transient, not checkable after the fact)"

if [ -d "$WARMUP/.git" ] && [ "$(git -C "$WARMUP" log --oneline 2>/dev/null | wc -l)" -ge 1 ]; then
  pass 4 "warmup/ has at least one commit"
else
  fail 4 "warmup/ has at least one commit"
fi

skip 5 "git log (read-only, leaves no trace to check)"
skip 6 "git diff (unstaged, transient)"
skip 7 "git diff --staged (transient)"
skip 8 "git commit --amend (transient, no fixed marker to check)"

if gcafe rev-parse --verify refs/heads/scratch >/dev/null 2>&1; then
  pass 9 "branch 'scratch' was created"
else
  fail 9 "branch 'scratch' exists (if already deleted post-merge, check manually)"
fi

skip 10 "git switch / checkout (transient)"

if gcafe rev-parse --verify refs/heads/scratch >/dev/null 2>&1 \
  && gcafe merge-base --is-ancestor scratch main; then
  pass 11 "scratch was fast-forward merged into main"
else
  fail 11 "scratch was fast-forward merged into main"
fi

HH_MERGE=$(gcafe log --merges --format=%H feature/happy-hour 2>/dev/null | head -1)
if [ -n "$HH_MERGE" ] \
  && [ "$(gcafe cat-file -p "$HH_MERGE" 2>/dev/null | grep -c '^parent ')" = "2" ] \
  && ! gcafe show "$HH_MERGE:menu.txt" 2>/dev/null | grep -q '<<<<<<<'; then
  pass 12 "feature/happy-hour has a clean merge commit resolving the conflict"
else
  fail 12 "feature/happy-hour has a clean merge commit resolving the conflict"
fi

skip 13 "git restore (transient)"
skip 14 "git restore --staged (transient)"
skip 15 "git reset --soft (transient)"
skip 16 "git reset --mixed (transient)"
skip 17 "git reset --hard (transient)"

if [ -n "$(gcafe log main --grep='^Revert ' -n1 --format=%H)" ]; then
  pass 18 "a revert commit exists on main"
else
  fail 18 "a revert commit exists on main"
fi

skip 19 "git stash / stash pop (transient)"

if [ -d "$CLONE_DIR/.git" ] && [ -n "$(git -C "$CLONE_DIR" log --oneline -1 2>/dev/null)" ]; then
  pass 20 "cafe-project-clone/ was created via git clone"
else
  fail 20 "cafe-project-clone/ was created via git clone"
fi

# ---------------- Bonus Round ----------------

skip 21 "git log filters (transient)"

TASK22_ANSWER=""
TASK23_ANSWER=""
if [ -f "$STUDENT_ANSWERS" ]; then
  TASK22_ANSWER=$(grep -oE 'task22[[:space:]]*=[[:space:]]*[0-9a-f]+' "$STUDENT_ANSWERS" | head -1 | grep -oE '[0-9a-f]+$')
  TASK23_ANSWER=$(grep -oE 'task23[[:space:]]*=[[:space:]]*[0-9a-f]+' "$STUDENT_ANSWERS" | head -1 | grep -oE '[0-9a-f]+$')
fi
EXPECT22=$(grep '^task22=' "$ANSWERS_FILE" 2>/dev/null | cut -d= -f2)
EXPECT23=$(grep '^task23=' "$ANSWERS_FILE" 2>/dev/null | cut -d= -f2)

hash_matches() { # $1=expected short hash, $2=student-provided hash
  [ -n "$1" ] && [ -n "$2" ] && { [[ "$1" == "$2"* ]] || [[ "$2" == "$1"* ]]; }
}

if hash_matches "$EXPECT22" "$TASK22_ANSWER"; then
  pass 22 "correct commit found via git log -S (ANSWERS.md)"
else
  fail 22 "correct commit found via git log -S (write task22=<hash> into ANSWERS.md)"
fi

if hash_matches "$EXPECT23" "$TASK23_ANSWER"; then
  pass 23 "correct commit found via git bisect (ANSWERS.md)"
else
  fail 23 "correct commit found via git bisect (write task23=<hash> into ANSWERS.md)"
fi

skip 24 "git blame (transient)"
skip 25 "git show (transient)"

TAG_TYPES=$(gcafe for-each-ref refs/tags --format='%(objecttype)' | sort -u)
if echo "$TAG_TYPES" | grep -qx "tag" && echo "$TAG_TYPES" | grep -qx "commit"; then
  pass 26 "both a lightweight and an annotated tag exist"
else
  fail 26 "both a lightweight and an annotated tag exist"
fi

REMOTE_COUNT=$(gcafe remote | wc -l | tr -d ' ')
if [ "$REMOTE_COUNT" -ge 2 ]; then
  pass 27 "a second remote was added"
else
  fail 27 "a second remote was added"
fi

if [ -d "$ORIGIN" ]; then
  LOCAL_LC=$(gcafe rev-parse feature/loyalty-card 2>/dev/null)
  REMOTE_LC=$(git ls-remote "$ORIGIN" refs/heads/feature/loyalty-card 2>/dev/null | cut -f1)
  if [ -n "$LOCAL_LC" ] && [ "$LOCAL_LC" = "$REMOTE_LC" ]; then
    pass 28 "feature/loyalty-card was pushed to origin"
  else
    fail 28 "feature/loyalty-card was pushed to origin"
  fi

  REMOTE_MAIN=$(git ls-remote "$ORIGIN" refs/heads/main 2>/dev/null | cut -f1)
  LOCAL_MAIN=$(gcafe rev-parse main 2>/dev/null)
  if [ -n "$LOCAL_MAIN" ] && [ "$LOCAL_MAIN" = "$REMOTE_MAIN" ]; then
    pass 29 "local main matches origin/main (pulled)"
  else
    fail 29 "local main matches origin/main (pulled)"
  fi

  TRACKING_MAIN=$(gcafe rev-parse refs/remotes/origin/main 2>/dev/null)
  if [ -n "$TRACKING_MAIN" ] && [ "$TRACKING_MAIN" = "$REMOTE_MAIN" ]; then
    pass 30 "local origin/main tracking ref is up to date (fetched)"
  else
    fail 30 "local origin/main tracking ref is up to date (fetched)"
  fi
else
  fail 28 "cafe-project-origin.git not found"
  fail 29 "cafe-project-origin.git not found"
  fail 30 "cafe-project-origin.git not found"
fi

SOCIAL_COMMIT=$(gcafe log feature/social-links --format=%H -n1)
CHERRY_FOUND=""
if [ -n "$SOCIAL_COMMIT" ]; then
  SOCIAL_PID=$(gcafe show "$SOCIAL_COMMIT" | gcafe patch-id | awk '{print $1}')
  for h in $(gcafe log main --format=%H); do
    pid=$(gcafe show "$h" | gcafe patch-id | awk '{print $1}')
    if [ -n "$SOCIAL_PID" ] && [ "$pid" = "$SOCIAL_PID" ]; then
      CHERRY_FOUND="yes"
      break
    fi
  done
fi
if [ "$CHERRY_FOUND" = "yes" ]; then
  pass 31 "feature/social-links commit was cherry-picked onto main"
else
  fail 31 "feature/social-links commit was cherry-picked onto main"
fi

WIP_BASE=$(gcafe merge-base feature/wip-styles main 2>/dev/null)
if [ -n "$WIP_BASE" ]; then
  WIP_COUNT=$(gcafe rev-list --count "$WIP_BASE..feature/wip-styles" 2>/dev/null)
  if [ "$WIP_COUNT" = "1" ]; then
    pass 32 "feature/wip-styles was squashed into a single commit"
  else
    fail 32 "feature/wip-styles was squashed into a single commit (found $WIP_COUNT commits ahead of main)"
  fi
else
  fail 32 "feature/wip-styles branch not found"
fi
skip 33 "git rebase main (near-no-op by design -- state looks identical whether run or not)"

if gcafe for-each-ref refs/heads --format='%(subject)' | grep -qFx "Experimental: dark mode toggle"; then
  pass 34 "the lost 'Experimental: dark mode toggle' commit was recovered onto a branch"
else
  fail 34 "the lost 'Experimental: dark mode toggle' commit was recovered onto a branch"
fi

if gcafe merge-base --is-ancestor main feature/pricing-update 2>/dev/null \
  && ! gcafe show feature/pricing-update:menu.txt 2>/dev/null | grep -q '<<<<<<<'; then
  pass 35 "feature/pricing-update rebase conflict was resolved"
else
  fail 35 "feature/pricing-update rebase conflict was resolved"
fi

GITIGNORE=$(gcafe show main:.gitignore 2>/dev/null)
DEBUG_TRACKED=$(gcafe ls-tree -r main --name-only 2>/dev/null | grep -Fx "debug.log")
if echo "$GITIGNORE" | grep -Fq "debug.log" && [ -z "$DEBUG_TRACKED" ] && [ -f "$CAFE/debug.log" ]; then
  pass 36 ".gitignore added and debug.log untracked (still present on disk)"
else
  fail 36 ".gitignore added and debug.log untracked (still present on disk)"
fi

skip 37 "git diff branchA..branchB (transient)"
skip 38 "detached HEAD experiment + git switch -c (student-chosen content, spot-check manually)"

echo ""
echo "Score: $PASS/$((PASS+FAIL)) automated checks passed ($SKIPN marked manual/instructor-observed, $((PASS+FAIL+SKIPN)) tasks total)"

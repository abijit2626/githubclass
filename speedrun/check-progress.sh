#!/usr/bin/env bash
# Checks a team's progress through the Git Speedrun tasks (24 tasks).
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

PASS=0
FAIL=0
SKIPN=0

pass() { echo "[PASS] Task $1 - $2"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] Task $1 - $2"; FAIL=$((FAIL+1)); }
skip() { echo "[SKIP] Task $1 - $2 (manual/instructor-observed)"; SKIPN=$((SKIPN+1)); }

gcafe() { git -C "$CAFE" "$@" 2>/dev/null; }

echo "Checking team folder: $TEAM_DIR"
echo ""

# ---------------- Base Round (1-16) ----------------

if [ -d "$WARMUP/.git" ]; then
  pass 1 "warmup/ is a git repo"
else
  fail 1 "warmup/ is a git repo"
fi

skip 2 "git status (read-only, leaves no trace)"
skip 3 "git add (staging is transient, not checkable after the fact)"

if [ -d "$WARMUP/.git" ] && [ "$(git -C "$WARMUP" log --oneline 2>/dev/null | wc -l)" -ge 1 ]; then
  pass 4 "warmup/ has at least one commit"
else
  fail 4 "warmup/ has at least one commit"
fi

skip 5 "git log (read-only, leaves no trace)"
skip 6 "git diff (transient)"
skip 7 "git restore (transient)"

if gcafe rev-parse --verify refs/heads/scratch >/dev/null 2>&1; then
  pass 8 "branch 'scratch' was created"
else
  fail 8 "branch 'scratch' exists (if already deleted post-merge, check manually)"
fi

skip 9 "git switch (transient)"

# scratch must be merged into main AND carry its own commit (>9 = beyond the 9 seed commits)
if gcafe rev-parse --verify refs/heads/scratch >/dev/null 2>&1 \
  && gcafe merge-base --is-ancestor scratch main \
  && [ "$(gcafe rev-list --count scratch)" -ge 10 ]; then
  pass 10 "scratch (with its own commit) was fast-forward merged into main"
else
  fail 10 "scratch (with its own commit) was fast-forward merged into main"
fi

HH_MERGE=$(gcafe log --merges --format=%H feature/happy-hour 2>/dev/null | head -1)
if [ -n "$HH_MERGE" ] \
  && [ "$(gcafe cat-file -p "$HH_MERGE" 2>/dev/null | grep -c '^parent ')" = "2" ] \
  && ! gcafe show "$HH_MERGE:menu.txt" 2>/dev/null | grep -q '<<<<<<<'; then
  pass 11 "feature/happy-hour has a clean merge commit resolving the conflict"
else
  fail 11 "feature/happy-hour has a clean merge commit resolving the conflict"
fi

skip 12 "git reset --soft (transient)"
skip 13 "git reset --hard (transient)"

if [ -n "$(gcafe log main --grep='^Revert ' -n1 --format=%H)" ]; then
  pass 14 "a revert commit exists on main"
else
  fail 14 "a revert commit exists on main"
fi

skip 15 "git stash / stash pop (transient)"

if [ -d "$CLONE_DIR/.git" ] && [ -n "$(git -C "$CLONE_DIR" log --oneline -1 2>/dev/null)" ]; then
  pass 16 "cafe-project-clone/ was created via git clone"
else
  fail 16 "cafe-project-clone/ was created via git clone"
fi

# ---------------- Bonus Round (17-24) ----------------

skip 17 "git show (transient)"

TAG_TYPES=$(gcafe for-each-ref refs/tags --format='%(objecttype)' | sort -u)
if echo "$TAG_TYPES" | grep -qx "tag" && echo "$TAG_TYPES" | grep -qx "commit"; then
  pass 18 "both a lightweight and an annotated tag exist"
else
  fail 18 "both a lightweight and an annotated tag exist"
fi

REMOTE_COUNT=$(gcafe remote | wc -l | tr -d ' ')
if [ "$REMOTE_COUNT" -ge 2 ]; then
  pass 19 "a second remote was added"
else
  fail 19 "a second remote was added"
fi

if [ -d "$ORIGIN" ]; then
  LOCAL_LC=$(gcafe rev-parse feature/loyalty-card 2>/dev/null)
  REMOTE_LC=$(git ls-remote "$ORIGIN" refs/heads/feature/loyalty-card 2>/dev/null | cut -f1)
  if [ -n "$LOCAL_LC" ] && [ "$LOCAL_LC" = "$REMOTE_LC" ]; then
    pass 20 "feature/loyalty-card was pushed to origin"
  else
    fail 20 "feature/loyalty-card was pushed to origin"
  fi

  REMOTE_MAIN=$(git ls-remote "$ORIGIN" refs/heads/main 2>/dev/null | cut -f1)

  TRACKING_MAIN=$(gcafe rev-parse refs/remotes/origin/main 2>/dev/null)
  if [ -n "$TRACKING_MAIN" ] && [ "$TRACKING_MAIN" = "$REMOTE_MAIN" ]; then
    pass 21 "origin/main is up to date locally (fetched)"
  else
    fail 21 "origin/main is up to date locally (fetched)"
  fi

  # Pulled = the remote's latest main commit is now part of local main's history.
  if [ -n "$REMOTE_MAIN" ] && gcafe merge-base --is-ancestor "$REMOTE_MAIN" main; then
    pass 22 "local main contains the teammate's commit (pulled)"
  else
    fail 22 "local main contains the teammate's commit (pulled)"
  fi
else
  fail 20 "cafe-project-origin.git not found"
  fail 21 "cafe-project-origin.git not found"
  fail 22 "cafe-project-origin.git not found"
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
  pass 23 "feature/social-links commit was cherry-picked onto main"
else
  fail 23 "feature/social-links commit was cherry-picked onto main"
fi

GITIGNORE=$(gcafe show main:.gitignore 2>/dev/null)
DEBUG_TRACKED=$(gcafe ls-tree -r main --name-only 2>/dev/null | grep -Fx "debug.log")
if echo "$GITIGNORE" | grep -Fq "debug.log" && [ -z "$DEBUG_TRACKED" ] && [ -f "$CAFE/debug.log" ]; then
  pass 24 ".gitignore added and debug.log untracked (still present on disk)"
else
  fail 24 ".gitignore added and debug.log untracked (still present on disk)"
fi

echo ""
echo "Score: $PASS/$((PASS+FAIL)) automated checks passed ($SKIPN marked manual/instructor-observed, $((PASS+FAIL+SKIPN)) tasks total)"

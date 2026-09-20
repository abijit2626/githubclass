#!/usr/bin/env bash
# Generates one team's Git Speedrun repo set: warmup/, cafe-project/,
# cafe-project-origin.git, helper scripts, and task docs.
#
# Usage: ./setup-team.sh TEAMNAME
#
# Must produce byte-identical repo state (same commit content, order, and
# author dates) to setup-team.ps1 for the same team name. If you change
# content or ordering here, make the matching change there.

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <TEAMNAME>" >&2
  exit 1
fi

TEAM="$1"
if ! [[ "$TEAM" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Error: team name must contain only letters, numbers, - and _." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(pwd)"
OUT_ABS="$BASE_DIR/$TEAM"

if [ -e "$OUT_ABS" ]; then
  echo "Error: '$TEAM' already exists in $BASE_DIR. Remove it or pick a different name." >&2
  exit 1
fi

WARMUP="$OUT_ABS/warmup"
CAFE="$OUT_ABS/cafe-project"
ORIGIN="$OUT_ABS/cafe-project-origin.git"

SEED_NAME="Instructor Seed"
SEED_EMAIL="seed@trailheadcafe.dev"
SAM_NAME="Sam Rivera"
SAM_EMAIL="sam@cafe.dev"
JORDAN_NAME="Jordan Lee"
JORDAN_EMAIL="jordan@cafe.dev"

# Fixed unix-epoch timestamps (raw git date format: "<epoch> <tz>"), one per
# seeded commit, so every generated repo has identical history regardless of
# when or where the script runs. See handoff notes for index -> commit map.
DATES=(
  "1705309200 +0000" # 0  C1 Initial commit
  "1705312800 +0000" # 1  C2 Add menu
  "1705316400 +0000" # 2  C3 Add about page
  "1705320000 +0000" # 3  C4 Oops: commit debug.log by mistake
  "1705323600 +0000" # 4  C5 BUG: typo in latte price
  "1705327200 +0000" # 5  C6 Fix latte price
  "1705330800 +0000" # 6  C7 Add daily specials
  "1705334400 +0000" # 7  C8 BUG: broken contact email
  "1705338000 +0000" # 8  C9 Add changelog
  "1705395600 +0000" # 9  feature/happy-hour commit
  "1705399200 +0000" # 10 feature/weekend-special commit
  "1705402800 +0000" # 11 feature/pricing-update commit
  "1705406400 +0000" # 12 feature/social-links commit
  "1705410000 +0000" # 13 feature/wip-styles commit 1
  "1705413600 +0000" # 14 feature/wip-styles commit 2
  "1705417200 +0000" # 15 feature/wip-styles commit 3
  "1705420800 +0000" # 16 Jordan's email-fix commit (pushed to origin/main)
  "1705424400 +0000" # 17 feature/loyalty-card commit
  "1705482000 +0000" # 18 lost "Experimental: dark mode toggle" commit
)

commit_as() {
  local msg="$1" name="$2" email="$3" idx="$4" d="${DATES[$4]}"
  GIT_AUTHOR_NAME="$name" GIT_AUTHOR_EMAIL="$email" GIT_AUTHOR_DATE="$d" \
  GIT_COMMITTER_NAME="$name" GIT_COMMITTER_EMAIL="$email" GIT_COMMITTER_DATE="$d" \
  git commit -q --no-gpg-sign -m "$msg"
}

echo "Building team '$TEAM' in $OUT_ABS ..."

mkdir -p "$WARMUP"

mkdir -p "$CAFE"
cd "$CAFE"
git init -q
git symbolic-ref HEAD refs/heads/main
git config user.name "$SEED_NAME"
git config user.email "$SEED_EMAIL"
git config commit.gpgsign false
git config core.autocrlf false

# --- C1: Initial commit ---
cat > README.md <<'EOF'
# Trailhead Cafe

A cozy neighborhood coffee shop. This repo tracks our menu, site content,
and notes.
EOF
git add README.md
commit_as "Initial commit" "$SEED_NAME" "$SEED_EMAIL" 0

# --- C2: Add menu ---
cat > menu.txt <<'EOF'
Drip Coffee ......... $2.50
Latte ......... $4.50
Muffin ......... $3.25
Bagel ......... $2.75
EOF
git add menu.txt
commit_as "Add menu" "$SEED_NAME" "$SEED_EMAIL" 1

# --- C3: Add about page ---
cat > about.txt <<'EOF'
About Trailhead Cafe

We're a small cafe serving coffee, tea, and baked goods.

Contact: hello@trailheadcafe.dev
EOF
git add about.txt
commit_as "Add about page" "$SEED_NAME" "$SEED_EMAIL" 2

# --- C4: Oops: commit debug.log by mistake ---
cat > debug.log <<'EOF'
[2024-01-15 08:55:00] DEBUG starting local dev server
[2024-01-15 08:55:01] DEBUG loaded config
EOF
git add debug.log
commit_as "Oops: commit debug.log by mistake" "$SEED_NAME" "$SEED_EMAIL" 3

# --- C5: BUG: typo in latte price ---
cat > menu.txt <<'EOF'
Drip Coffee ......... $2.50
Latte ......... $4.05
Muffin ......... $3.25
Bagel ......... $2.75
EOF
git add menu.txt
commit_as "BUG: typo in latte price" "$SAM_NAME" "$SAM_EMAIL" 4
C5_HASH=$(git rev-parse HEAD)

# --- C6: Fix latte price ---
cat > menu.txt <<'EOF'
Drip Coffee ......... $2.50
Latte ......... $4.50
Muffin ......... $3.25
Bagel ......... $2.75
EOF
git add menu.txt
commit_as "Fix latte price" "$SEED_NAME" "$SEED_EMAIL" 5
C6_HASH=$(git rev-parse HEAD)

# --- C7: Add daily specials ---
cat > menu.txt <<'EOF'
Drip Coffee ......... $2.50
Latte ......... $4.50
Muffin ......... $3.50
Bagel ......... $2.75
Today's Special: Chai Latte
EOF
git add menu.txt
commit_as "Add daily specials" "$SEED_NAME" "$SEED_EMAIL" 6

# --- C8: BUG: broken contact email (left broken) ---
cat > about.txt <<'EOF'
About Trailhead Cafe

We're a small cafe serving coffee, tea, and baked goods.

Contact: hello@trailheadcaf.dev
EOF
git add about.txt
commit_as "BUG: broken contact email" "$SAM_NAME" "$SAM_EMAIL" 7
C8_HASH=$(git rev-parse HEAD)

# --- C9: Add changelog ---
cat > CHANGELOG.md <<'EOF'
# Changelog

- Initial menu and about page
- Daily specials added
EOF
git add CHANGELOG.md
commit_as "Add changelog" "$SEED_NAME" "$SEED_EMAIL" 8
C9_HASH=$(git rev-parse HEAD)

# --- wire up the local "remote" and push main ---
git init -q --bare "$ORIGIN"
git remote add origin "$ORIGIN"
git push -q -u origin main

# --- simulate a teammate fixing the email typo on origin ---
TMPCLONE="$(mktemp -d)"
git clone -q "$ORIGIN" "$TMPCLONE/jordan-clone"
(
  cd "$TMPCLONE/jordan-clone"
  git config user.name "$JORDAN_NAME"
  git config user.email "$JORDAN_EMAIL"
  git config commit.gpgsign false
  git config core.autocrlf false
  cat > about.txt <<'EOF'
About Trailhead Cafe

We're a small cafe serving coffee, tea, and baked goods.

Contact: hello@trailheadcafe.dev
EOF
  git add about.txt
  commit_as "Fix contact email typo" "$JORDAN_NAME" "$JORDAN_EMAIL" 16
  git push -q origin main
)
rm -rf "$TMPCLONE"

# --- feature branches (local only, not pushed) ---

git switch -q -c feature/happy-hour "$C6_HASH"
cat > menu.txt <<'EOF'
Drip Coffee ......... $2.50
Latte ......... $3.75  (Happy Hour special)
Muffin ......... $3.25
Bagel ......... $2.75
EOF
git add menu.txt
commit_as "Add happy hour pricing" "$SEED_NAME" "$SEED_EMAIL" 9

git switch -q -c feature/weekend-special "$C6_HASH"
cat > menu.txt <<'EOF'
Drip Coffee ......... $2.50
Latte ......... $5.00  (Weekend Special blend)
Muffin ......... $3.25
Bagel ......... $2.75
EOF
git add menu.txt
commit_as "Add weekend special pricing" "$SEED_NAME" "$SEED_EMAIL" 10

git switch -q -c feature/pricing-update "$C6_HASH"
cat > menu.txt <<'EOF'
Drip Coffee ......... $2.50
Latte ......... $4.50
Muffin ......... $3.75
Bagel ......... $2.75
EOF
git add menu.txt
commit_as "Bump muffin price" "$SEED_NAME" "$SEED_EMAIL" 11

git switch -q -c feature/social-links "$C9_HASH"
cat > social.txt <<'EOF'
Follow us: @trailheadcafe
EOF
git add social.txt
commit_as "Add social links" "$SEED_NAME" "$SEED_EMAIL" 12

git switch -q -c feature/wip-styles "$C9_HASH"
cat > styles-notes.txt <<'EOF'
TODO: style ideas
EOF
git add styles-notes.txt
commit_as "WIP: start style tweaks" "$SEED_NAME" "$SEED_EMAIL" 13

cat > styles-notes.txt <<'EOF'
TODO: style ideas
- reduce paddingg on buttons
EOF
git add styles-notes.txt
commit_as "WIP: more tweaks" "$SEED_NAME" "$SEED_EMAIL" 14

cat > styles-notes.txt <<'EOF'
TODO: style ideas
- reduce padding on buttons
EOF
git add styles-notes.txt
commit_as "Fix typo in WIP commit" "$SEED_NAME" "$SEED_EMAIL" 15

git switch -q main
git switch -q -c feature/loyalty-card
cat > loyalty-card.txt <<'EOF'
Buy 9 coffees, get the 10th free. Ask staff to stamp your card at checkout.
EOF
git add loyalty-card.txt
commit_as "Add loyalty card note" "$SEED_NAME" "$SEED_EMAIL" 17

git switch -q main

# --- lost commit for reflog recovery: last step, on purpose ---
git checkout -q "$C9_HASH"
cat > dark-mode-notes.txt <<'EOF'
Prototype idea: dark mode toggle in the top nav. Needs design review before
shipping.
EOF
git add dark-mode-notes.txt
commit_as "Experimental: dark mode toggle" "$SEED_NAME" "$SEED_EMAIL" 18
git switch -q main

cd "$BASE_DIR"

# --- helper scripts for the bisect task ---
cat > "$OUT_ABS/bisect-check.sh" <<'EOF'
#!/usr/bin/env bash
# Exit 0 = contact email is correct ("good"), exit 1 = still broken ("bad").
# Run from inside cafe-project/, e.g.: git bisect run bash ../bisect-check.sh
if [ ! -f about.txt ]; then
  exit 125
fi
if grep -F "hello@trailheadcaf.dev" about.txt > /dev/null 2>&1; then
  exit 1
else
  exit 0
fi
EOF
chmod +x "$OUT_ABS/bisect-check.sh"

cat > "$OUT_ABS/bisect-check.ps1" <<'EOF'
# Exit 0 = contact email is correct ("good"), exit 1 = still broken ("bad").
# Run from inside cafe-project/, e.g.: git bisect run pwsh ../bisect-check.ps1
if (-not (Test-Path about.txt)) {
  exit 125
}
$content = Get-Content about.txt -Raw
if ($content -like "*hello@trailheadcaf.dev*") {
  exit 1
} else {
  exit 0
}
EOF

cp "$SCRIPT_DIR/tasks.md" "$OUT_ABS/TASKS.md"

# --- answer key for check-progress.sh (not shown to students) ---
cat > "$OUT_ABS/.answers" <<EOF
task22=$(git -C "$CAFE" rev-parse --short "$C5_HASH")
task23=$(git -C "$CAFE" rev-parse --short "$C8_HASH")
EOF

echo "Done. Team '$TEAM' is ready in $OUT_ABS"
echo "  warmup/                empty, ready for git init"
echo "  cafe-project/           seeded repo on branch main (9 commits) + 6 feature branches"
echo "  cafe-project-origin.git local \"remote\", main pushed, one unfetched commit from Jordan"
echo "  TASKS.md, bisect-check.sh/.ps1"

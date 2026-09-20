#!/usr/bin/env bash
# Batch-generates every team's starter environment and zips each one.
#
# Usage: ./build-all-teams.sh [COUNT] [PREFIX] [OUTDIR]
#   COUNT   number of teams to generate (default: 35)
#   PREFIX  team name prefix (default: TEAM)
#   OUTDIR  where to put the generated folders + zips (default: ./dist)
#
# This is the optional batch-packaging path. The primary distribution mode
# is handing out setup-team.sh/.ps1 and letting each team run it themselves
# (no zip handling needed) -- use this script only if you'd rather pre-build
# everything and hand out finished folders/zips instead.

set -euo pipefail

COUNT="${1:-35}"
PREFIX="${2:-TEAM}"
OUTDIR="${3:-dist}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Plain Git Bash on Windows usually ships without a 'zip' binary. Fall back
# to python's zipfile module (python/python3 is commonly present, including
# via Git for Windows' own installers) before giving up. On Windows,
# 'python3' on PATH can be a Microsoft Store stub that fails at runtime even
# though `command -v` finds it, so actually probe each candidate rather than
# trusting PATH lookup alone.
ZIP_MODE=""
if command -v zip >/dev/null 2>&1; then
  ZIP_MODE="zip"
elif command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
  ZIP_MODE="python3"
elif command -v python >/dev/null 2>&1 && python --version >/dev/null 2>&1; then
  ZIP_MODE="python"
else
  echo "Error: no 'zip' command and no python found to zip with." >&2
  echo "Install one of: 'zip' (e.g. 'apt install zip' / 'brew install zip'), or Python 3." >&2
  echo "On Windows you can also skip this script and use build-all-teams.ps1 instead (uses PowerShell's built-in Compress-Archive)." >&2
  exit 1
fi

make_zip() {
  local team_dir="$1" zip_path="$2" team="$3"
  case "$ZIP_MODE" in
    zip) (cd "$OUTDIR_ABS" && zip -qr "$zip_path" "$team") ;;
    python3|python) (cd "$OUTDIR_ABS" && "$ZIP_MODE" -c "
import shutil, sys
base = sys.argv[1][:-4] if sys.argv[1].endswith('.zip') else sys.argv[1]
shutil.make_archive(base, 'zip', '.', sys.argv[2])
" "$zip_path" "$team") ;;
  esac
}

mkdir -p "$OUTDIR"
OUTDIR_ABS="$(cd "$OUTDIR" && pwd)"

echo "Generating $COUNT team(s) with prefix '$PREFIX' into $OUTDIR_ABS ..."
echo "(zipping via: $ZIP_MODE)"
echo ""

for i in $(seq -w 1 "$COUNT"); do
  TEAM="${PREFIX}${i}"
  TEAM_DIR="$OUTDIR_ABS/$TEAM"
  if [ -e "$TEAM_DIR" ]; then
    echo "Skipping $TEAM: '$TEAM_DIR' already exists."
    continue
  fi
  (cd "$OUTDIR_ABS" && "$SCRIPT_DIR/setup-team.sh" "$TEAM" >/dev/null)
  make_zip "$TEAM_DIR" "${TEAM}.zip" "$TEAM"
  echo "  $TEAM -> ${TEAM_DIR}.zip"
done

echo ""
echo "Done. $COUNT team folder(s) and zip(s) are in $OUTDIR_ABS"

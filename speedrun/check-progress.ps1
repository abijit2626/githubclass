#Requires -Version 5.1
<#
Checks a team's progress through the Git Speedrun tasks (24 tasks).

Usage: ./check-progress.ps1 path/to/TEAMNAME

Every check here is read-only: it inspects git plumbing (refs, objects,
ls-remote) without checking out branches or touching the student's working
tree. Tasks that are inherently transient (a diff you looked at, a stash you
popped) can't be verified after the fact and are marked SKIP rather than
faked. See speedrun/tasks.md for what each task actually asks for.

Must report the same PASS/FAIL/SKIP verdicts as check-progress.sh for the
same team folder. If you change a check here, make the matching change there.
#>

param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$TeamPath
)

if (-not (Test-Path $TeamPath -PathType Container)) {
  Write-Error "'$TeamPath' is not a directory."
  exit 1
}

$TeamDir = (Resolve-Path $TeamPath).Path
$Warmup = Join-Path $TeamDir "warmup"
$Cafe = Join-Path $TeamDir "cafe-project"
$OriginDir = Join-Path $TeamDir "cafe-project-origin.git"
$CloneDir = Join-Path $TeamDir "cafe-project-clone"

$script:PassCount = 0
$script:FailCount = 0
$script:SkipCount = 0

function Pass($n, $desc) { Write-Host "[PASS] Task $n - $desc"; $script:PassCount++ }
function Fail($n, $desc) { Write-Host "[FAIL] Task $n - $desc"; $script:FailCount++ }
function Skip($n, $desc) { Write-Host "[SKIP] Task $n - $desc (manual/instructor-observed)"; $script:SkipCount++ }

function GCafe {
  $out = & git -C $Cafe @args 2>$null
  return $out
}
function GCafeOk {
  & git -C $Cafe @args *> $null
  return ($LASTEXITCODE -eq 0)
}

Write-Host "Checking team folder: $TeamDir"
Write-Host ""

# ---------------- Base Round (1-16) ----------------

if (Test-Path (Join-Path $Warmup ".git")) {
  Pass 1 "warmup/ is a git repo"
} else {
  Fail 1 "warmup/ is a git repo"
}

Skip 2 "git status (read-only, leaves no trace)"
Skip 3 "git add (staging is transient, not checkable after the fact)"

$warmupLog = @()
if (Test-Path (Join-Path $Warmup ".git")) {
  $warmupLog = & git -C $Warmup log --oneline 2>$null
}
if ($warmupLog.Count -ge 1) {
  Pass 4 "warmup/ has at least one commit"
} else {
  Fail 4 "warmup/ has at least one commit"
}

Skip 5 "git log (read-only, leaves no trace)"
Skip 6 "git diff (transient)"
Skip 7 "git restore (transient)"

if (GCafeOk rev-parse --verify refs/heads/scratch) {
  Pass 8 "branch 'scratch' was created"
} else {
  Fail 8 "branch 'scratch' exists (if already deleted post-merge, check manually)"
}

Skip 9 "git switch (transient)"

# scratch must be merged into main AND carry its own commit (>9 = beyond the 9 seed commits)
$scratchExists = GCafeOk rev-parse --verify refs/heads/scratch
$scratchCount = 0
if ($scratchExists) { $scratchCount = [int](GCafe rev-list --count scratch) }
if ($scratchExists -and (GCafeOk merge-base --is-ancestor scratch main) -and ($scratchCount -ge 10)) {
  Pass 10 "scratch (with its own commit) was fast-forward merged into main"
} else {
  Fail 10 "scratch (with its own commit) was fast-forward merged into main"
}

$hhMerge = (GCafe log --merges --format=%H feature/happy-hour) | Select-Object -First 1
$hhMergeOk = $false
if ($hhMerge) {
  $parentCount = (GCafe cat-file -p $hhMerge | Select-String '^parent ').Count
  $conflictMarkers = GCafe show "${hhMerge}:menu.txt" | Select-String '<<<<<<<'
  if ($parentCount -eq 2 -and -not $conflictMarkers) { $hhMergeOk = $true }
}
if ($hhMergeOk) {
  Pass 11 "feature/happy-hour has a clean merge commit resolving the conflict"
} else {
  Fail 11 "feature/happy-hour has a clean merge commit resolving the conflict"
}

Skip 12 "git reset --soft (transient)"
Skip 13 "git reset --hard (transient)"

$revertCommit = GCafe log main --grep='^Revert ' -n1 --format=%H
if ($revertCommit) {
  Pass 14 "a revert commit exists on main"
} else {
  Fail 14 "a revert commit exists on main"
}

Skip 15 "git stash / stash pop (transient)"

$cloneHasCommit = $false
if (Test-Path (Join-Path $CloneDir ".git")) {
  $cloneLog = & git -C $CloneDir log --oneline -1 2>$null
  if ($cloneLog) { $cloneHasCommit = $true }
}
if ($cloneHasCommit) {
  Pass 16 "cafe-project-clone/ was created via git clone"
} else {
  Fail 16 "cafe-project-clone/ was created via git clone"
}

# ---------------- Bonus Round (17-24) ----------------

Skip 17 "git show (transient)"

$tagTypes = (GCafe for-each-ref refs/tags --format='%(objecttype)') | Sort-Object -Unique
if (($tagTypes -contains "tag") -and ($tagTypes -contains "commit")) {
  Pass 18 "both a lightweight and an annotated tag exist"
} else {
  Fail 18 "both a lightweight and an annotated tag exist"
}

$remoteCount = (GCafe remote | Measure-Object -Line).Lines
if ($remoteCount -ge 2) {
  Pass 19 "a second remote was added"
} else {
  Fail 19 "a second remote was added"
}

if (Test-Path $OriginDir) {
  $localLc = GCafe rev-parse feature/loyalty-card
  $remoteLcLine = & git ls-remote $OriginDir refs/heads/feature/loyalty-card 2>$null
  $remoteLc = if ($remoteLcLine) { ($remoteLcLine -split "`t")[0] } else { $null }
  if ($localLc -and ($localLc -eq $remoteLc)) {
    Pass 20 "feature/loyalty-card was pushed to origin"
  } else {
    Fail 20 "feature/loyalty-card was pushed to origin"
  }

  $remoteMainLine = & git ls-remote $OriginDir refs/heads/main 2>$null
  $remoteMain = if ($remoteMainLine) { ($remoteMainLine -split "`t")[0] } else { $null }

  $trackingMain = GCafe rev-parse refs/remotes/origin/main
  if ($trackingMain -and ($trackingMain -eq $remoteMain)) {
    Pass 21 "origin/main is up to date locally (fetched)"
  } else {
    Fail 21 "origin/main is up to date locally (fetched)"
  }

  # Pulled = the remote's latest main commit is now part of local main's history.
  if ($remoteMain -and (GCafeOk merge-base --is-ancestor $remoteMain main)) {
    Pass 22 "local main contains the teammate's commit (pulled)"
  } else {
    Fail 22 "local main contains the teammate's commit (pulled)"
  }
} else {
  Fail 20 "cafe-project-origin.git not found"
  Fail 21 "cafe-project-origin.git not found"
  Fail 22 "cafe-project-origin.git not found"
}

$socialCommit = GCafe log feature/social-links --format=%H -n1
$cherryFound = $false
if ($socialCommit) {
  $socialPid = ((GCafe show $socialCommit) | & git -C $Cafe patch-id 2>$null) -split '\s+' | Select-Object -First 1
  $mainHashes = GCafe log main --format=%H
  foreach ($h in $mainHashes) {
    $pid_ = ((GCafe show $h) | & git -C $Cafe patch-id 2>$null) -split '\s+' | Select-Object -First 1
    if ($socialPid -and ($pid_ -eq $socialPid)) { $cherryFound = $true; break }
  }
}
if ($cherryFound) {
  Pass 23 "feature/social-links commit was cherry-picked onto main"
} else {
  Fail 23 "feature/social-links commit was cherry-picked onto main"
}

$gitignoreContent = GCafe show main:.gitignore
$debugTracked = (GCafe ls-tree -r main --name-only) | Where-Object { $_ -eq "debug.log" }
$debugOnDisk = Test-Path (Join-Path $Cafe "debug.log")
if (($gitignoreContent -match "debug\.log") -and (-not $debugTracked) -and $debugOnDisk) {
  Pass 24 ".gitignore added and debug.log untracked (still present on disk)"
} else {
  Fail 24 ".gitignore added and debug.log untracked (still present on disk)"
}

Write-Host ""
$total = $script:PassCount + $script:FailCount
$grandTotal = $total + $script:SkipCount
Write-Host "Score: $($script:PassCount)/$total automated checks passed ($($script:SkipCount) marked manual/instructor-observed, $grandTotal tasks total)"

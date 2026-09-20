#Requires -Version 5.1
<#
Checks a team's progress through the Git Speedrun tasks.

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
$AnswersFile = Join-Path $TeamDir ".answers"
$StudentAnswers = Join-Path $TeamDir "ANSWERS.md"

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

# ---------------- Base Round ----------------

if (Test-Path (Join-Path $Warmup ".git")) {
  Pass 1 "warmup/ is a git repo"
} else {
  Fail 1 "warmup/ is a git repo"
}

Skip 2 "git status"
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

Skip 5 "git log (read-only, leaves no trace to check)"
Skip 6 "git diff (unstaged, transient)"
Skip 7 "git diff --staged (transient)"
Skip 8 "git commit --amend (transient, no fixed marker to check)"

if (GCafeOk rev-parse --verify refs/heads/scratch) {
  Pass 9 "branch 'scratch' was created"
} else {
  Fail 9 "branch 'scratch' exists (if already deleted post-merge, check manually)"
}

Skip 10 "git switch / checkout (transient)"

if ((GCafeOk rev-parse --verify refs/heads/scratch) -and (GCafeOk merge-base --is-ancestor scratch main)) {
  Pass 11 "scratch was fast-forward merged into main"
} else {
  Fail 11 "scratch was fast-forward merged into main"
}

$hhMerge = (GCafe log --merges --format=%H feature/happy-hour) | Select-Object -First 1
$hhMergeOk = $false
if ($hhMerge) {
  $parentCount = (GCafe cat-file -p $hhMerge | Select-String '^parent ').Count
  $conflictMarkers = GCafe show "${hhMerge}:menu.txt" | Select-String '<<<<<<<'
  if ($parentCount -eq 2 -and -not $conflictMarkers) { $hhMergeOk = $true }
}
if ($hhMergeOk) {
  Pass 12 "feature/happy-hour has a clean merge commit resolving the conflict"
} else {
  Fail 12 "feature/happy-hour has a clean merge commit resolving the conflict"
}

Skip 13 "git restore (transient)"
Skip 14 "git restore --staged (transient)"
Skip 15 "git reset --soft (transient)"
Skip 16 "git reset --mixed (transient)"
Skip 17 "git reset --hard (transient)"

$revertCommit = GCafe log main --grep='^Revert ' -n1 --format=%H
if ($revertCommit) {
  Pass 18 "a revert commit exists on main"
} else {
  Fail 18 "a revert commit exists on main"
}

Skip 19 "git stash / stash pop (transient)"

$cloneHasCommit = $false
if (Test-Path (Join-Path $CloneDir ".git")) {
  $cloneLog = & git -C $CloneDir log --oneline -1 2>$null
  if ($cloneLog) { $cloneHasCommit = $true }
}
if ($cloneHasCommit) {
  Pass 20 "cafe-project-clone/ was created via git clone"
} else {
  Fail 20 "cafe-project-clone/ was created via git clone"
}

# ---------------- Bonus Round ----------------

Skip 21 "git log filters (transient)"

$task22Answer = $null
$task23Answer = $null
if (Test-Path $StudentAnswers) {
  $content = Get-Content $StudentAnswers -Raw
  $m22 = [regex]::Match($content, 'task22\s*=\s*([0-9a-f]+)')
  $m23 = [regex]::Match($content, 'task23\s*=\s*([0-9a-f]+)')
  if ($m22.Success) { $task22Answer = $m22.Groups[1].Value }
  if ($m23.Success) { $task23Answer = $m23.Groups[1].Value }
}
$expect22 = $null
$expect23 = $null
if (Test-Path $AnswersFile) {
  $answersContent = Get-Content $AnswersFile
  foreach ($line in $answersContent) {
    if ($line -match '^task22=(.+)$') { $expect22 = $matches[1] }
    if ($line -match '^task23=(.+)$') { $expect23 = $matches[1] }
  }
}

function HashMatches($expected, $given) {
  if (-not $expected -or -not $given) { return $false }
  return ($expected.StartsWith($given) -or $given.StartsWith($expected))
}

if (HashMatches $expect22 $task22Answer) {
  Pass 22 "correct commit found via git log -S (ANSWERS.md)"
} else {
  Fail 22 "correct commit found via git log -S (write task22=<hash> into ANSWERS.md)"
}

if (HashMatches $expect23 $task23Answer) {
  Pass 23 "correct commit found via git bisect (ANSWERS.md)"
} else {
  Fail 23 "correct commit found via git bisect (write task23=<hash> into ANSWERS.md)"
}

Skip 24 "git blame (transient)"
Skip 25 "git show (transient)"

$tagTypes = (GCafe for-each-ref refs/tags --format='%(objecttype)') | Sort-Object -Unique
if (($tagTypes -contains "tag") -and ($tagTypes -contains "commit")) {
  Pass 26 "both a lightweight and an annotated tag exist"
} else {
  Fail 26 "both a lightweight and an annotated tag exist"
}

$remoteCount = (GCafe remote | Measure-Object -Line).Lines
if ($remoteCount -ge 2) {
  Pass 27 "a second remote was added"
} else {
  Fail 27 "a second remote was added"
}

if (Test-Path $OriginDir) {
  $localLc = GCafe rev-parse feature/loyalty-card
  $remoteLcLine = & git ls-remote $OriginDir refs/heads/feature/loyalty-card 2>$null
  $remoteLc = if ($remoteLcLine) { ($remoteLcLine -split "`t")[0] } else { $null }
  if ($localLc -and ($localLc -eq $remoteLc)) {
    Pass 28 "feature/loyalty-card was pushed to origin"
  } else {
    Fail 28 "feature/loyalty-card was pushed to origin"
  }

  $remoteMainLine = & git ls-remote $OriginDir refs/heads/main 2>$null
  $remoteMain = if ($remoteMainLine) { ($remoteMainLine -split "`t")[0] } else { $null }
  $localMain = GCafe rev-parse main
  if ($localMain -and ($localMain -eq $remoteMain)) {
    Pass 29 "local main matches origin/main (pulled)"
  } else {
    Fail 29 "local main matches origin/main (pulled)"
  }

  $trackingMain = GCafe rev-parse refs/remotes/origin/main
  if ($trackingMain -and ($trackingMain -eq $remoteMain)) {
    Pass 30 "local origin/main tracking ref is up to date (fetched)"
  } else {
    Fail 30 "local origin/main tracking ref is up to date (fetched)"
  }
} else {
  Fail 28 "cafe-project-origin.git not found"
  Fail 29 "cafe-project-origin.git not found"
  Fail 30 "cafe-project-origin.git not found"
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
  Pass 31 "feature/social-links commit was cherry-picked onto main"
} else {
  Fail 31 "feature/social-links commit was cherry-picked onto main"
}

$wipBase = GCafe merge-base feature/wip-styles main
if ($wipBase) {
  $wipCount = (GCafe rev-list --count "$wipBase..feature/wip-styles")
  if ($wipCount -eq "1") {
    Pass 32 "feature/wip-styles was squashed into a single commit"
  } else {
    Fail 32 "feature/wip-styles was squashed into a single commit (found $wipCount commits ahead of main)"
  }
} else {
  Fail 32 "feature/wip-styles branch not found"
}
Skip 33 "git rebase main (near-no-op by design -- state looks identical whether run or not)"

$darkModeSubjects = GCafe for-each-ref refs/heads --format='%(subject)'
if ($darkModeSubjects -contains "Experimental: dark mode toggle") {
  Pass 34 "the lost 'Experimental: dark mode toggle' commit was recovered onto a branch"
} else {
  Fail 34 "the lost 'Experimental: dark mode toggle' commit was recovered onto a branch"
}

$pricingRebased = GCafeOk merge-base --is-ancestor main feature/pricing-update
$pricingConflict = GCafe show feature/pricing-update:menu.txt | Select-String '<<<<<<<'
if ($pricingRebased -and -not $pricingConflict) {
  Pass 35 "feature/pricing-update rebase conflict was resolved"
} else {
  Fail 35 "feature/pricing-update rebase conflict was resolved"
}

$gitignoreContent = GCafe show main:.gitignore
$debugTracked = (GCafe ls-tree -r main --name-only) | Where-Object { $_ -eq "debug.log" }
$debugOnDisk = Test-Path (Join-Path $Cafe "debug.log")
if (($gitignoreContent -match "debug\.log") -and (-not $debugTracked) -and $debugOnDisk) {
  Pass 36 ".gitignore added and debug.log untracked (still present on disk)"
} else {
  Fail 36 ".gitignore added and debug.log untracked (still present on disk)"
}

Skip 37 "git diff branchA..branchB (transient)"
Skip 38 "detached HEAD experiment + git switch -c (student-chosen content, spot-check manually)"

Write-Host ""
$total = $script:PassCount + $script:FailCount
$grandTotal = $total + $script:SkipCount
Write-Host "Score: $($script:PassCount)/$total automated checks passed ($($script:SkipCount) marked manual/instructor-observed, $grandTotal tasks total)"

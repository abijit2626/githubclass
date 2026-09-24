#Requires -Version 5.1
<#
Generates one team's Git Speedrun repo set: warmup/, cafe-project/,
cafe-project-origin.git, and the task sheet.

Usage: ./setup-team.ps1 TEAMNAME

Must produce byte-identical repo state (same commit content, order, and
author dates) to setup-team.sh for the same team name. If you change
content or ordering here, make the matching change there.
#>

param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$TeamName
)

$ErrorActionPreference = "Stop"

if ($TeamName -notmatch '^[A-Za-z0-9_-]+$') {
  Write-Error "Team name must contain only letters, numbers, - and _."
  exit 1
}

function Invoke-Git {
  & git @args
  if ($LASTEXITCODE -ne 0) {
    throw "git $($args -join ' ') failed with exit code $LASTEXITCODE"
  }
}

function Write-Utf8NoBomLF {
  param([string]$Path, [string]$Content)
  # .NET's CurrentDirectory doesn't reliably track PowerShell's Set-Location,
  # so resolve relative paths against $PWD explicitly before writing.
  if (-not [System.IO.Path]::IsPathRooted($Path)) {
    $Path = Join-Path (Get-Location).Path $Path
  }
  $normalized = $Content -replace "`r`n", "`n"
  # PowerShell here-strings drop the trailing newline bash heredocs always
  # keep; add it back so file bytes match setup-team.sh exactly.
  if (-not $normalized.EndsWith("`n")) {
    $normalized += "`n"
  }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

$ScriptDir = $PSScriptRoot
$BaseDir = (Get-Location).Path
$OutAbs = Join-Path $BaseDir $TeamName

if (Test-Path $OutAbs) {
  Write-Error "'$TeamName' already exists in $BaseDir. Remove it or pick a different name."
  exit 1
}

$Warmup = Join-Path $OutAbs "warmup"
$Cafe = Join-Path $OutAbs "cafe-project"
$Origin = Join-Path $OutAbs "cafe-project-origin.git"

$SeedName = "Instructor Seed"
$SeedEmail = "seed@trailheadcafe.dev"
$SamName = "Sam Rivera"
$SamEmail = "sam@cafe.dev"
$JordanName = "Jordan Lee"
$JordanEmail = "jordan@cafe.dev"

# Fixed unix-epoch timestamps (raw git date format: "<epoch> <tz>"), one per
# seeded commit, so every generated repo has identical history regardless of
# when or where the script runs.
$Dates = @(
  "1705309200 +0000", # 0  C1 Initial commit
  "1705312800 +0000", # 1  C2 Add menu
  "1705316400 +0000", # 2  C3 Add about page
  "1705320000 +0000", # 3  C4 Oops: commit debug.log by mistake
  "1705323600 +0000", # 4  C5 BUG: typo in latte price
  "1705327200 +0000", # 5  C6 Fix latte price
  "1705330800 +0000", # 6  C7 Add daily specials
  "1705334400 +0000", # 7  C8 BUG: broken contact email
  "1705338000 +0000", # 8  C9 Add changelog
  "1705395600 +0000", # 9  feature/happy-hour commit
  "1705399200 +0000", # 10 feature/weekend-special commit
  "1705406400 +0000", # 11 feature/social-links commit
  "1705420800 +0000", # 12 Jordan's email-fix commit (pushed to origin/main)
  "1705424400 +0000"  # 13 feature/loyalty-card commit
)

function Commit-As {
  param([string]$Message, [string]$Name, [string]$Email, [int]$Idx)
  $d = $Dates[$Idx]
  $env:GIT_AUTHOR_NAME = $Name
  $env:GIT_AUTHOR_EMAIL = $Email
  $env:GIT_AUTHOR_DATE = $d
  $env:GIT_COMMITTER_NAME = $Name
  $env:GIT_COMMITTER_EMAIL = $Email
  $env:GIT_COMMITTER_DATE = $d
  Invoke-Git commit -q --no-gpg-sign -m $Message
}

Write-Host "Building team '$TeamName' in $OutAbs ..."

New-Item -ItemType Directory -Path $Warmup -Force | Out-Null

New-Item -ItemType Directory -Path $Cafe -Force | Out-Null
Set-Location $Cafe
Invoke-Git init -q
Invoke-Git symbolic-ref HEAD refs/heads/main
Invoke-Git config user.name $SeedName
Invoke-Git config user.email $SeedEmail
Invoke-Git config commit.gpgsign false
Invoke-Git config core.autocrlf false
Invoke-Git config pull.rebase false

# --- C1: Initial commit ---
Write-Utf8NoBomLF "README.md" @'
# Trailhead Cafe

A cozy neighborhood coffee shop. This repo tracks our menu, site content,
and notes.
'@
Invoke-Git add README.md
Commit-As "Initial commit" $SeedName $SeedEmail 0

# --- C2: Add menu ---
Write-Utf8NoBomLF "menu.txt" @'
Drip Coffee ......... $2.50
Latte ......... $4.50
Muffin ......... $3.25
Bagel ......... $2.75
'@
Invoke-Git add menu.txt
Commit-As "Add menu" $SeedName $SeedEmail 1

# --- C3: Add about page ---
Write-Utf8NoBomLF "about.txt" @'
About Trailhead Cafe

We're a small cafe serving coffee, tea, and baked goods.

Contact: hello@trailheadcafe.dev
'@
Invoke-Git add about.txt
Commit-As "Add about page" $SeedName $SeedEmail 2

# --- C4: Oops: commit debug.log by mistake ---
Write-Utf8NoBomLF "debug.log" @'
[2024-01-15 08:55:00] DEBUG starting local dev server
[2024-01-15 08:55:01] DEBUG loaded config
'@
Invoke-Git add debug.log
Commit-As "Oops: commit debug.log by mistake" $SeedName $SeedEmail 3

# --- C5: BUG: typo in latte price ---
Write-Utf8NoBomLF "menu.txt" @'
Drip Coffee ......... $2.50
Latte ......... $4.05
Muffin ......... $3.25
Bagel ......... $2.75
'@
Invoke-Git add menu.txt
Commit-As "BUG: typo in latte price" $SamName $SamEmail 4

# --- C6: Fix latte price ---
Write-Utf8NoBomLF "menu.txt" @'
Drip Coffee ......... $2.50
Latte ......... $4.50
Muffin ......... $3.25
Bagel ......... $2.75
'@
Invoke-Git add menu.txt
Commit-As "Fix latte price" $SeedName $SeedEmail 5
$C6Hash = (git rev-parse HEAD).Trim()

# --- C7: Add daily specials ---
Write-Utf8NoBomLF "menu.txt" @'
Drip Coffee ......... $2.50
Latte ......... $4.50
Muffin ......... $3.50
Bagel ......... $2.75
Today's Special: Chai Latte
'@
Invoke-Git add menu.txt
Commit-As "Add daily specials" $SeedName $SeedEmail 6

# --- C8: BUG: broken contact email (left broken) ---
Write-Utf8NoBomLF "about.txt" @'
About Trailhead Cafe

We're a small cafe serving coffee, tea, and baked goods.

Contact: hello@trailheadcaf.dev
'@
Invoke-Git add about.txt
Commit-As "BUG: broken contact email" $SamName $SamEmail 7

# --- C9: Add changelog ---
Write-Utf8NoBomLF "CHANGELOG.md" @'
# Changelog

- Initial menu and about page
- Daily specials added
'@
Invoke-Git add CHANGELOG.md
Commit-As "Add changelog" $SeedName $SeedEmail 8
$C9Hash = (git rev-parse HEAD).Trim()

# --- wire up the local "remote" and push main ---
Invoke-Git init -q --bare $Origin
Invoke-Git remote add origin $Origin
Invoke-Git push -q -u origin main

# --- simulate a teammate fixing the email typo on origin ---
$TmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("gitclass-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TmpRoot -Force | Out-Null
$JordanClone = Join-Path $TmpRoot "jordan-clone"
Invoke-Git clone -q $Origin $JordanClone

Push-Location $JordanClone
Invoke-Git config user.name $JordanName
Invoke-Git config user.email $JordanEmail
Invoke-Git config commit.gpgsign false
Invoke-Git config core.autocrlf false
Write-Utf8NoBomLF "about.txt" @'
About Trailhead Cafe

We're a small cafe serving coffee, tea, and baked goods.

Contact: hello@trailheadcafe.dev
'@
Invoke-Git add about.txt
Commit-As "Fix contact email typo" $JordanName $JordanEmail 12
Invoke-Git push -q origin main
Pop-Location
Remove-Item -Recurse -Force $TmpRoot

# --- feature branches (local only, not pushed) ---

Invoke-Git switch -q -c feature/happy-hour $C6Hash
Write-Utf8NoBomLF "menu.txt" @'
Drip Coffee ......... $2.50
Latte ......... $3.75  (Happy Hour special)
Muffin ......... $3.25
Bagel ......... $2.75
'@
Invoke-Git add menu.txt
Commit-As "Add happy hour pricing" $SeedName $SeedEmail 9

Invoke-Git switch -q -c feature/weekend-special $C6Hash
Write-Utf8NoBomLF "menu.txt" @'
Drip Coffee ......... $2.50
Latte ......... $5.00  (Weekend Special blend)
Muffin ......... $3.25
Bagel ......... $2.75
'@
Invoke-Git add menu.txt
Commit-As "Add weekend special pricing" $SeedName $SeedEmail 10

Invoke-Git switch -q -c feature/social-links $C9Hash
Write-Utf8NoBomLF "social.txt" @'
Follow us: @trailheadcafe
'@
Invoke-Git add social.txt
Commit-As "Add social links" $SeedName $SeedEmail 11

Invoke-Git switch -q main
Invoke-Git switch -q -c feature/loyalty-card
Write-Utf8NoBomLF "loyalty-card.txt" @'
Buy 9 coffees, get the 10th free. Ask staff to stamp your card at checkout.
'@
Invoke-Git add loyalty-card.txt
Commit-As "Add loyalty card note" $SeedName $SeedEmail 13

Invoke-Git switch -q main

Set-Location $BaseDir

Copy-Item (Join-Path $ScriptDir "tasks.md") (Join-Path $OutAbs "TASKS.md")

Write-Host "Done. Team '$TeamName' is ready in $OutAbs"
Write-Host "  warmup/                empty, ready for git init"
Write-Host "  cafe-project/           seeded repo on branch main (9 commits) + 4 feature branches"
Write-Host "  cafe-project-origin.git local ""remote"", main pushed, one unfetched commit from Jordan"
Write-Host "  TASKS.md"

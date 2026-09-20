#Requires -Version 5.1
<#
Batch-generates every team's starter environment and zips each one.

Usage: ./build-all-teams.ps1 [-Count 35] [-Prefix TEAM] [-OutDir dist]

This is the optional batch-packaging path. The primary distribution mode is
handing out setup-team.sh/.ps1 and letting each team run it themselves (no
zip handling needed) -- use this script only if you'd rather pre-build
everything and hand out finished folders/zips instead.
#>

param(
  [int]$Count = 35,
  [string]$Prefix = "TEAM",
  [string]$OutDir = "dist"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$OutDirAbs = (Resolve-Path $OutDir).Path

Write-Host "Generating $Count team(s) with prefix '$Prefix' into $OutDirAbs ..."
Write-Host ""

$Width = ([string]$Count).Length
if ($Width -lt 2) { $Width = 2 }

for ($n = 1; $n -le $Count; $n++) {
  $Suffix = $n.ToString().PadLeft($Width, '0')
  $Team = "$Prefix$Suffix"
  $TeamDir = Join-Path $OutDirAbs $Team

  if (Test-Path $TeamDir) {
    Write-Host "Skipping $Team`: '$TeamDir' already exists."
    continue
  }

  Push-Location $OutDirAbs
  try {
    & $ScriptDir\setup-team.ps1 $Team | Out-Null
  } finally {
    Pop-Location
  }

  $ZipPath = Join-Path $OutDirAbs "$Team.zip"
  Compress-Archive -Path $TeamDir -DestinationPath $ZipPath -Force
  Write-Host "  $Team -> $ZipPath"
}

Write-Host ""
Write-Host "Done. $Count team folder(s) and zip(s) are in $OutDirAbs"

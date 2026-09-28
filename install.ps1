param(
  [switch]$DryRun,
  [switch]$GenericOnly,
  [string]$TargetRoot = "$env:USERPROFILE\.codex\skills"
)

$ErrorActionPreference = "Stop"
$sourceRoot = Join-Path $PSScriptRoot "skills"
$registryPath = Join-Path $PSScriptRoot "REGISTRY.json"

if (-not (Test-Path $registryPath)) {
  throw "Missing REGISTRY.json"
}

$registry = Get-Content $registryPath -Raw | ConvertFrom-Json
$entries = @($registry.skills)
if ($GenericOnly) {
  $entries = @($entries | Where-Object { $_.kind -eq "generic" })
}

if (-not (Test-Path $TargetRoot)) {
  if ($DryRun) {
    Write-Output "[DRY RUN] Would create $TargetRoot"
  } else {
    New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
  }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $TargetRoot "_skill-backups\$stamp"

foreach ($entry in $entries) {
  $name = [string]$entry.name
  $src = Join-Path $PSScriptRoot ([string]$entry.path)
  $dst = Join-Path $TargetRoot $name

  if (-not (Test-Path (Join-Path $src "SKILL.md"))) {
    throw "Invalid registry entry or bundle: $name"
  }

  if (Test-Path $dst) {
    if ($DryRun) {
      Write-Output "[DRY RUN] Would back up $dst -> $backupRoot"
    } else {
      New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
      Copy-Item $dst (Join-Path $backupRoot $name) -Recurse -Force
    }
  }

  if ($DryRun) {
    Write-Output "[DRY RUN] Would install $name -> $dst"
  } else {
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $src $dst -Recurse -Force
    Write-Output "[INSTALLED] $name"
  }
}

Write-Output "Done."

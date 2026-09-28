param(
  [switch]$DryRun,
  [switch]$GenericOnly,
  [string]$TargetRoot = "$env:USERPROFILE\.codex\skills"
)

$ErrorActionPreference = "Stop"
$sourceRoot = Join-Path $PSScriptRoot "skills"

$generic = @(
  "typescript-node-architecture",
  "monorepo-typescript",
  "sqlite-data-modeling",
  "resilient-crawler-engineering",
  "application-security-local-first",
  "testing-typescript-systems"
)

$skills = @($generic)
if (-not $GenericOnly) {
  $skills += "growthops-engineering"
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

foreach ($name in $skills) {
  $src = Join-Path $sourceRoot $name
  $dst = Join-Path $TargetRoot $name

  if (-not (Test-Path (Join-Path $src "SKILL.md"))) {
    throw "Invalid bundle: missing $name\SKILL.md"
  }

  if (Test-Path $dst) {
    if ($DryRun) {
      Write-Output "[DRY RUN] Would back up existing $dst to $backupRoot"
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

if (-not $DryRun) {
  $validator = Join-Path $TargetRoot "growthops-engineering\scripts\validate-suite.ps1"
  if ((-not $GenericOnly) -and (Test-Path $validator)) {
    & powershell -ExecutionPolicy Bypass -File $validator -SkillsRoot $TargetRoot
    if ($LASTEXITCODE -ne 0) {
      throw "Post-install validation failed."
    }
  }
}

Write-Output "Done."

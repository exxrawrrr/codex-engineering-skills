$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$installer = Join-Path $repoRoot "install.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-skills-installer-" + [guid]::NewGuid().ToString("N"))

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )
  if (-not $Condition) { throw $Message }
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $target = Join-Path $tempRoot "skills"
  $first = & $installer -TargetRoot $target -SkillName "sqlite-data-modeling" | Out-String

  Assert-True (Test-Path (Join-Path $target "sqlite-data-modeling\SKILL.md")) "Selected skill was not installed"
  Assert-True (-not (Test-Path (Join-Path $target "testing-typescript-systems"))) "Unselected skill was installed"
  Assert-True (-not (Test-Path (Join-Path $target "growthops-engineering"))) "Project skill leaked into explicit install"
  Assert-True ($first.Contains("[INSTALLED] sqlite-data-modeling")) "Install output did not report selected skill"

  $marker = Join-Path $target "sqlite-data-modeling\local-marker.txt"
  Set-Content -Path $marker -Value "preserve-me"

  $second = & $installer -TargetRoot $target -SkillName "sqlite-data-modeling" | Out-String
  $backupBase = Join-Path $tempRoot "skills-backups"

  Assert-True (Test-Path $backupBase) "Reinstall did not create sibling backup root"
  Assert-True (-not (Test-Path (Join-Path $target "_skill-backups"))) "Backup directory exists inside active skill root"
  $backedUpMarker = @(Get-ChildItem $backupBase -Recurse -File -Filter "local-marker.txt")
  Assert-True ($backedUpMarker.Count -eq 1) "Existing installed skill was not backed up exactly once"
  Assert-True ($second.Contains("[INSTALLED] sqlite-data-modeling")) "Reinstall output did not report selected skill"

  $dryTarget = Join-Path $tempRoot "dry-skills"
  $dry = & $installer -DryRun -TargetRoot $dryTarget -SkillName "sqlite-data-modeling,testing-typescript-systems" | Out-String

  Assert-True (-not (Test-Path $dryTarget)) "Dry run created target directory"
  Assert-True ($dry.Contains("sqlite-data-modeling")) "Dry run omitted first selected skill"
  Assert-True ($dry.Contains("testing-typescript-systems")) "Dry run omitted second selected skill"
  Assert-True (-not $dry.Contains("growthops-engineering")) "Dry run included an unselected skill"

  $unknownFailed = $false
  try {
    & $installer -DryRun -TargetRoot (Join-Path $tempRoot "unknown") -SkillName "does-not-exist" | Out-Null
  } catch {
    $unknownFailed = $true
  }
  Assert-True $unknownFailed "Unknown explicit skill name did not fail"

  $ambiguousFailed = $false
  try {
    & $installer -DryRun -TargetRoot (Join-Path $tempRoot "ambiguous") -GenericOnly -SkillName "sqlite-data-modeling" | Out-Null
  } catch {
    $ambiguousFailed = $true
  }
  Assert-True $ambiguousFailed "GenericOnly + SkillName ambiguity did not fail"

  $insideBackupFailed = $false
  try {
    $insideTarget = Join-Path $tempRoot "inside-target"
    & $installer -DryRun -TargetRoot $insideTarget -BackupRoot (Join-Path $insideTarget "backups") -SkillName "sqlite-data-modeling" | Out-Null
  } catch {
    $insideBackupFailed = $true
  }
  Assert-True $insideBackupFailed "BackupRoot inside TargetRoot was not rejected"

  Write-Output "[PASS] explicit installer selection"
  Write-Output "[PASS] sibling backup root outside discovery tree"
  Write-Output "[PASS] dry-run remains non-mutating"
  Write-Output "[PASS] invalid/ambiguous installer inputs fail closed"
} finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force
  }
}

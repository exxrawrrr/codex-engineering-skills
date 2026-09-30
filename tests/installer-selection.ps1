
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$installer = Join-Path $repoRoot "install.ps1"
$registry = Get-Content (Join-Path $repoRoot "REGISTRY.json") -Raw | ConvertFrom-Json
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-skills-installer-" + [guid]::NewGuid().ToString("N"))

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )
  if (-not $Condition) { throw $Message }
}

function Assert-SameStringSet {
  param(
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Actual,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Expected,
    [Parameter(Mandatory = $true)][string]$Message
  )

  $actualSorted = @($Actual | Sort-Object -Unique -CaseSensitive)
  $expectedSorted = @($Expected | Sort-Object -Unique -CaseSensitive)
  Assert-True ($actualSorted.Count -eq $expectedSorted.Count) "$Message (count mismatch)"
  Assert-True (($actualSorted -join [char]0x001F) -ceq ($expectedSorted -join [char]0x001F)) $Message
}

function Get-DryRunInstallNames {
  param([Parameter(Mandatory = $true)][string]$Output)

  return @(
    foreach ($line in ($Output -split "\r?\n")) {
      if ($line -match "^\[DRY RUN\] Would stage and install ([^ ]+) -> ") {
        $Matches[1]
      }
    }
  )
}

function New-DirectoryAlias {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Target
  )

  if ([System.OperatingSystem]::IsWindows()) {
    New-Item -ItemType Junction -Path $Path -Target $Target -Force | Out-Null
  } else {
    New-Item -ItemType SymbolicLink -Path $Path -Target $Target -Force | Out-Null
  }
}

function Invoke-ExpectFailure {
  param(
    [Parameter(Mandatory = $true)][scriptblock]$Action,
    [Parameter(Mandatory = $true)][string]$Message,
    [string]$ExpectedText
  )

  $failed = $false
  $observed = ""
  try {
    & $Action
  } catch {
    $failed = $true
    $observed = [string]$_.Exception.Message
  }

  Assert-True $failed $Message
  if (-not [string]::IsNullOrWhiteSpace($ExpectedText)) {
    Assert-True ($observed.Contains($ExpectedText)) "$Message (wrong failure: $observed)"
  }
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $allRegistryNames = @($registry.skills | ForEach-Object { [string]$_.name })
  $genericRegistryNames = @(
    $registry.skills |
      Where-Object { [string]$_.kind -eq "generic" } |
      ForEach-Object { [string]$_.name }
  )

  $defaultDryTarget = Join-Path (Join-Path $tempRoot "default-dry") "skills"
  $defaultDry = & $installer -DryRun -TargetRoot $defaultDryTarget | Out-String
  Assert-SameStringSet -Actual (Get-DryRunInstallNames -Output $defaultDry) -Expected $allRegistryNames -Message "Default dry-run did not select exactly the full registry"
  Assert-True (-not (Test-Path -LiteralPath $defaultDryTarget)) "Default dry-run mutated the target"

  $genericDryTarget = Join-Path (Join-Path $tempRoot "generic-dry") "skills"
  $genericDry = & $installer -DryRun -TargetRoot $genericDryTarget -GenericOnly | Out-String
  Assert-SameStringSet -Actual (Get-DryRunInstallNames -Output $genericDry) -Expected $genericRegistryNames -Message "GenericOnly dry-run did not select exactly registry generic skills"
  Assert-True (-not (Test-Path -LiteralPath $genericDryTarget)) "GenericOnly dry-run mutated the target"

  $explicitDryTarget = Join-Path (Join-Path $tempRoot "explicit-dry") "skills"
  $explicitDry = & $installer -DryRun -TargetRoot $explicitDryTarget -SkillName @("testing-typescript-systems,sqlite-data-modeling","sqlite-data-modeling") | Out-String
  Assert-SameStringSet -Actual (Get-DryRunInstallNames -Output $explicitDry) -Expected @("sqlite-data-modeling","testing-typescript-systems") -Message "Explicit dry-run did not show exactly the selected skills"
  Assert-True (-not (Test-Path -LiteralPath $explicitDryTarget)) "Explicit dry-run mutated the target"
  Assert-True (-not $explicitDry.Contains("growthops-engineering")) "Explicit dry-run leaked an unselected project skill"

  $target = Join-Path $tempRoot "skills"
  $unselectedDir = Join-Path $target "testing-typescript-systems"
  New-Item -ItemType Directory -Path $unselectedDir -Force | Out-Null
  $unselectedMarker = Join-Path $unselectedDir "local-only-marker.txt"
  Set-Content -LiteralPath $unselectedMarker -Value "do-not-touch" -Encoding utf8NoBOM
  $unselectedBefore = (Get-FileHash -LiteralPath $unselectedMarker -Algorithm SHA256).Hash

  $first = & $installer -TargetRoot $target -SkillName "sqlite-data-modeling" | Out-String
  Assert-True (Test-Path -LiteralPath (Join-Path (Join-Path $target "sqlite-data-modeling") "SKILL.md")) "Selected skill was not installed"
  Assert-True (Test-Path -LiteralPath $unselectedMarker) "Existing unselected skill content was removed"
  Assert-True (((Get-FileHash -LiteralPath $unselectedMarker -Algorithm SHA256).Hash -eq $unselectedBefore)) "Existing unselected skill content was modified"
  Assert-True ($first.Contains("[INSTALLED] sqlite-data-modeling")) "Install output did not report selected skill"

  $marker = Join-Path (Join-Path $target "sqlite-data-modeling") "local-marker.txt"
  Set-Content -LiteralPath $marker -Value "preserve-me" -Encoding utf8NoBOM

  $second = & $installer -TargetRoot $target -SkillName "sqlite-data-modeling" | Out-String
  $backupBase = Join-Path $tempRoot "skills-backups"

  Assert-True (Test-Path -LiteralPath $backupBase) "Reinstall did not create sibling backup root"
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $target "_skill-backups"))) "Backup directory exists inside active skill root"
  $backupRuns = @(Get-ChildItem -LiteralPath $backupBase -Directory)
  Assert-True ($backupRuns.Count -eq 1) "Reinstall did not create exactly one backup run directory"
  Assert-True ($backupRuns[0].Name -match "^\d{8}-\d{6}-\d{3}-[0-9a-f]{32}$") "Backup run id is not timestamp + GUID collision-resistant format"
  $backedUpMarker = @(Get-ChildItem -LiteralPath $backupBase -Recurse -File -Filter "local-marker.txt")
  Assert-True ($backedUpMarker.Count -eq 1) "Existing selected skill was not backed up exactly once"
  Assert-True ($second.Contains("[INSTALLED] sqlite-data-modeling")) "Reinstall output did not report selected skill"
  Assert-True (((Get-FileHash -LiteralPath $unselectedMarker -Algorithm SHA256).Hash -eq $unselectedBefore)) "Reinstall touched an unselected skill"

  $unknownTarget = Join-Path (Join-Path $tempRoot "unknown-mixed") "skills"
  New-Item -ItemType Directory -Path $unknownTarget -Force | Out-Null
  $sentinel = Join-Path $unknownTarget "sentinel.txt"
  Set-Content -LiteralPath $sentinel -Value "still-here" -Encoding utf8NoBOM
  Invoke-ExpectFailure -Action { & $installer -TargetRoot $unknownTarget -SkillName "sqlite-data-modeling,does-not-exist" | Out-Null } -Message "Mixed valid+unknown selection did not fail closed" -ExpectedText "Unknown skill name(s): does-not-exist"
  Assert-True ((Get-Content -LiteralPath $sentinel -Raw).Trim() -eq "still-here") "Unknown selection mutated existing target content"
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $unknownTarget "sqlite-data-modeling"))) "Unknown selection installed the valid subset before failing"
  Assert-True (-not (Test-Path -LiteralPath (Join-Path (Split-Path $unknownTarget -Parent) "skills-backups"))) "Unknown selection created backups"

  Invoke-ExpectFailure -Action { & $installer -DryRun -TargetRoot (Join-Path $tempRoot "blank") -SkillName " , " | Out-Null } -Message "Blank SkillName did not fail" -ExpectedText "no skill names were supplied"
  Invoke-ExpectFailure -Action { & $installer -DryRun -TargetRoot (Join-Path $tempRoot "ambiguous") -GenericOnly -SkillName "sqlite-data-modeling" | Out-Null } -Message "GenericOnly + SkillName ambiguity did not fail" -ExpectedText "Use either -GenericOnly or -SkillName"
  Invoke-ExpectFailure -Action { & $installer -DryRun -TargetRoot (Join-Path $tempRoot "wrong-case") -SkillName "SQLite-Data-Modeling" | Out-Null } -Message "Non-canonical skill-name casing did not fail" -ExpectedText "Unknown skill name(s): SQLite-Data-Modeling"

  $insideTarget = Join-Path $tempRoot "inside-target"
  Invoke-ExpectFailure -Action { & $installer -DryRun -TargetRoot $insideTarget -BackupRoot (Join-Path $insideTarget "backups") -SkillName "sqlite-data-modeling" | Out-Null } -Message "BackupRoot inside TargetRoot was not rejected" -ExpectedText "BackupRoot must be outside TargetRoot"

  $customTarget = Join-Path (Join-Path $tempRoot "custom-target") "skills"
  $customBackup = Join-Path $tempRoot "custom-backups"
  $customDry = & $installer -DryRun -TargetRoot $customTarget -BackupRoot $customBackup -SkillName "sqlite-data-modeling" | Out-String
  Assert-True ($customDry.Contains("[DRY RUN] Would stage and install sqlite-data-modeling")) "Valid custom backup root prevented dry-run selection"
  Assert-True (-not (Test-Path -LiteralPath $customTarget)) "Custom-backup dry-run created target"
  Assert-True (-not (Test-Path -LiteralPath $customBackup)) "Custom-backup dry-run created backup directory"

  $aliasTarget = Join-Path $tempRoot "alias-target"
  $insideAliasDestination = Join-Path $aliasTarget "hidden-backups"
  New-Item -ItemType Directory -Path $insideAliasDestination -Force | Out-Null
  $backupAlias = Join-Path $tempRoot "backup-alias"
  New-DirectoryAlias -Path $backupAlias -Target $insideAliasDestination
  Invoke-ExpectFailure -Action { & $installer -DryRun -TargetRoot $aliasTarget -BackupRoot $backupAlias -SkillName "sqlite-data-modeling" | Out-Null } -Message "BackupRoot symlink/junction alias was not rejected" -ExpectedText "must not traverse a symlink, junction, or reparse-point alias"

  $outsideSkill = Join-Path $tempRoot "outside-skill"
  New-Item -ItemType Directory -Path $outsideSkill -Force | Out-Null
  Set-Content -LiteralPath (Join-Path $outsideSkill "sentinel.txt") -Value "external" -Encoding utf8NoBOM
  $aliasSkillTarget = Join-Path (Join-Path $tempRoot "alias-skill-target") "skills"
  New-Item -ItemType Directory -Path $aliasSkillTarget -Force | Out-Null
  $installedAlias = Join-Path $aliasSkillTarget "sqlite-data-modeling"
  New-DirectoryAlias -Path $installedAlias -Target $outsideSkill
  Invoke-ExpectFailure -Action { & $installer -TargetRoot $aliasSkillTarget -SkillName "sqlite-data-modeling" | Out-Null } -Message "Installed-skill path alias was not rejected" -ExpectedText "Installed skill destination 'sqlite-data-modeling' must not contain symlinks"
  Assert-True ((Get-Content -LiteralPath (Join-Path $outsideSkill "sentinel.txt") -Raw).Trim() -eq "external") "Rejected installed-skill alias mutated external content"

  $sourceNestedTarget = Join-Path (Join-Path $repoRoot "skills") "_installer-test-target"
  Invoke-ExpectFailure -Action { & $installer -DryRun -TargetRoot $sourceNestedTarget -SkillName "sqlite-data-modeling" | Out-Null } -Message "TargetRoot inside repository source skill root was not rejected" -ExpectedText "TargetRoot must not overlap the repository source skill root"

  $sourceNestedBackup = Join-Path (Join-Path $repoRoot "skills") "_installer-test-backups"
  Invoke-ExpectFailure -Action { & $installer -DryRun -TargetRoot (Join-Path $tempRoot "source-overlap-target") -BackupRoot $sourceNestedBackup -SkillName "sqlite-data-modeling" | Out-Null } -Message "BackupRoot inside repository source skill root was not rejected" -ExpectedText "BackupRoot must not overlap the repository source skill root"

  $caseRoot = Join-Path $tempRoot "case-semantics"
  $caseTarget = Join-Path $caseRoot "skills"
  $caseBackup = Join-Path (Join-Path $caseRoot "SKILLS") "backups"
  if ([System.OperatingSystem]::IsWindows()) {
    Invoke-ExpectFailure -Action { & $installer -DryRun -TargetRoot $caseTarget -BackupRoot $caseBackup -SkillName "sqlite-data-modeling" | Out-Null } -Message "Windows case-insensitive containment was not enforced" -ExpectedText "BackupRoot must be outside TargetRoot"
  } else {
    $caseDry = & $installer -DryRun -TargetRoot $caseTarget -BackupRoot $caseBackup -SkillName "sqlite-data-modeling" | Out-String
    Assert-True ($caseDry.Contains("Would stage and install sqlite-data-modeling")) "Unix case-sensitive distinct path was incorrectly rejected"
  }

  Write-Output "[PASS] default install selects the full registry"
  Write-Output "[PASS] GenericOnly selects exactly generic registry skills"
  Write-Output "[PASS] explicit installer selection is exact and leaves unselected skills untouched"
  Write-Output "[PASS] unknown/blank/ambiguous/non-canonical selections fail before mutation"
  Write-Output "[PASS] backup root stays outside discovery/source trees with collision-resistant run ids"
  Write-Output "[PASS] symlink/junction aliases cannot bypass installer path boundaries"
  Write-Output "[PASS] path containment follows Windows/Unix case semantics"
  Write-Output "[PASS] dry-run remains non-mutating"
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

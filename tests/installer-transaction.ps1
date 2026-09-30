$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourceInstaller = Join-Path $repoRoot "install.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-skills-transaction-" + [guid]::NewGuid().ToString("N"))

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )
  if (-not $Condition) { throw $Message }
}

function Write-SkillBundle {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Version
  )

  New-Item -ItemType Directory -Path $Path -Force | Out-Null
  $body = @"
---
name: $Name
description: "Installer transaction fixture for $Name."
---

# $Name

version-marker: $Version
"@
  [System.IO.File]::WriteAllText(
    (Join-Path $Path "SKILL.md"),
    $body,
    [System.Text.UTF8Encoding]::new($false)
  )
}

function Read-Version {
  param([Parameter(Mandatory = $true)][string]$SkillPath)

  $skillFile = Join-Path $SkillPath "SKILL.md"
  if (-not (Test-Path -LiteralPath $skillFile)) { return $null }

  $raw = Get-Content -LiteralPath $skillFile -Raw
  if ($raw -match "version-marker:\s*([^\r\n]+)") {
    return $Matches[1].Trim()
  }
  return $null
}

function New-Sandbox {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string[]]$SkillNames,
    [string[]]$ExistingNames = @()
  )

  $root = Join-Path $tempRoot $Name
  $fakeRepo = Join-Path $root "repo"
  $skillsRoot = Join-Path $fakeRepo "skills"
  $targetRoot = Join-Path (Join-Path $root "target") "skills"

  New-Item -ItemType Directory -Path $skillsRoot -Force | Out-Null
  Copy-Item -LiteralPath $sourceInstaller -Destination (Join-Path $fakeRepo "install.ps1")

  $registrySkills = @()
  foreach ($skillName in $SkillNames) {
    Write-SkillBundle -Path (Join-Path $skillsRoot $skillName) -Name $skillName -Version "$skillName-source-v2"
    $registrySkills += [ordered]@{
      name = $skillName
      kind = "generic"
      path = "skills/$skillName"
      tags = @("fixture")
      status = "stable"
      evidence_tier = "none"
      evidence_refs = @()
    }
  }

  [ordered]@{
    schema_version = 2
    suite = "installer-transaction-fixture"
    version = "0.0.0"
    skills = $registrySkills
  } | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $fakeRepo "REGISTRY.json") -Encoding utf8NoBOM

  foreach ($skillName in $ExistingNames) {
    Write-SkillBundle -Path (Join-Path $targetRoot $skillName) -Name $skillName -Version "$skillName-existing-v1"
  }

  return @{
    Root = $root
    Repo = $fakeRepo
    Installer = Join-Path $fakeRepo "install.ps1"
    TargetRoot = $targetRoot
    TargetParent = Split-Path $targetRoot -Parent
    BackupRoot = Join-Path (Split-Path $targetRoot -Parent) "skills-backups"
  }
}

function New-InjectedInstaller {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$FileName,
    [Parameter(Mandatory = $true)][string]$Needle,
    [Parameter(Mandatory = $true)][string]$Replacement
  )

  $baseText = Get-Content -LiteralPath $Sandbox.Installer -Raw
  Assert-True ($baseText.Contains($Needle)) "Injection anchor not found for $FileName"

  $path = Join-Path $Sandbox.Repo $FileName
  [System.IO.File]::WriteAllText(
    $path,
    $baseText.Replace($Needle, $Replacement),
    [System.Text.UTF8Encoding]::new($false)
  )
  return $path
}

function Invoke-ExpectedFailure {
  param(
    [Parameter(Mandatory = $true)][string]$Installer,
    [Parameter(Mandatory = $true)][string]$TargetRoot,
    [Parameter(Mandatory = $true)][string]$SkillName,
    [Parameter(Mandatory = $true)][string]$ExpectedErrorText
  )

  $output = New-Object System.Collections.Generic.List[string]
  $failed = $false
  $errorMessage = ""

  try {
    & $Installer -TargetRoot $TargetRoot -SkillName $SkillName |
      ForEach-Object { $output.Add([string]$_) }
  } catch {
    $failed = $true
    $errorMessage = [string]$_.Exception.Message
  }

  Assert-True $failed "Expected injected installer failure"
  Assert-True ($errorMessage.Contains($ExpectedErrorText)) "Failure reason mismatch. Expected '$ExpectedErrorText', observed '$errorMessage'"

  return @{
    Error = $errorMessage
    Output = ($output -join [Environment]::NewLine)
  }
}

function Assert-NoCurrentRunStagingLeak {
  param(
    [Parameter(Mandatory = $true)][string]$TargetParent,
    [string]$AllowedName
  )

  $dirs = @(
    Get-ChildItem -LiteralPath $TargetParent -Directory -Filter ".skill-install-staging-*" -ErrorAction SilentlyContinue |
      Where-Object { [string]::IsNullOrWhiteSpace($AllowedName) -or $_.Name -ne $AllowedName }
  )
  Assert-True ($dirs.Count -eq 0) "Installer left a staging directory owned by the completed/failed invocation"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $base = New-Sandbox -Name "baseline" -SkillNames @("fixture-skill") -ExistingNames @("fixture-skill")
  $first = & $base.Installer -TargetRoot $base.TargetRoot -SkillName "fixture-skill" | Out-String

  Assert-True ((Read-Version (Join-Path $base.TargetRoot "fixture-skill")) -eq "fixture-skill-source-v2") "Initial replacement did not install source v2"
  Assert-True ($first.Contains("[INSTALLED] fixture-skill")) "Initial replacement was not reported as installed"

  $backupSkills = @(Get-ChildItem -LiteralPath $base.BackupRoot -Recurse -Directory -Filter "fixture-skill")
  Assert-True ($backupSkills.Count -eq 1) "Initial replacement did not create exactly one verified backup"
  Assert-True ((Read-Version $backupSkills[0].FullName) -eq "fixture-skill-existing-v1") "Backup did not preserve existing v1"

  $backupFileCountBefore = @(Get-ChildItem -LiteralPath $base.BackupRoot -Recurse -File).Count
  $second = & $base.Installer -TargetRoot $base.TargetRoot -SkillName "fixture-skill" | Out-String
  $backupFileCountAfter = @(Get-ChildItem -LiteralPath $base.BackupRoot -Recurse -File).Count

  Assert-True ($second.Contains("[UNCHANGED] fixture-skill")) "Identical reinstall was not idempotent"
  Assert-True ($backupFileCountAfter -eq $backupFileCountBefore) "Identical reinstall created an unnecessary backup"

  $stageAll = New-Sandbox -Name "stage-all" -SkillNames @("skill-a","skill-b") -ExistingNames @("skill-a","skill-b")
  $stageNeedle = @'
    Copy-Item -LiteralPath $src -Destination $stagePath -Recurse -Force
    Assert-SkillBundle -Path $stagePath -ExpectedName $name
'@
  $stageInjected = @'
    Copy-Item -LiteralPath $src -Destination $stagePath -Recurse -Force
    if ($name -eq "skill-b") {
      $skillFile = Join-Path $stagePath "SKILL.md"
      (Get-Content -LiteralPath $skillFile -Raw).Replace("name: skill-b", "name: wrong-skill") |
        Set-Content -LiteralPath $skillFile -Encoding utf8NoBOM
    }
    Assert-SkillBundle -Path $stagePath -ExpectedName $name
'@
  $stageInstaller = New-InjectedInstaller -Sandbox $stageAll -FileName "install-stage-failure.ps1" -Needle $stageNeedle -Replacement $stageInjected
  Invoke-ExpectedFailure -Installer $stageInstaller -TargetRoot $stageAll.TargetRoot -SkillName "skill-a,skill-b" -ExpectedErrorText "frontmatter name mismatch" | Out-Null

  Assert-True ((Read-Version (Join-Path $stageAll.TargetRoot "skill-a")) -eq "skill-a-existing-v1") "Later stage failure mutated earlier skill-a"
  Assert-True ((Read-Version (Join-Path $stageAll.TargetRoot "skill-b")) -eq "skill-b-existing-v1") "Stage failure mutated skill-b"
  Assert-True (-not (Test-Path -LiteralPath $stageAll.BackupRoot)) "Stage failure created backups before every stage verified"
  Assert-NoCurrentRunStagingLeak -TargetParent $stageAll.TargetParent

  $backupFail = New-Sandbox -Name "backup-failure" -SkillNames @("skill-a","skill-b") -ExistingNames @("skill-a","skill-b")
  $backupNeedle = @'
      Copy-Item -LiteralPath $plan.Destination -Destination $backupPath -Recurse -Force

      if ((Get-DirectoryFingerprint -Path $backupPath) -ne $plan.DestinationFingerprint) {
'@
  $backupInjected = @'
      Copy-Item -LiteralPath $plan.Destination -Destination $backupPath -Recurse -Force
      if ($plan.Name -eq "skill-b") {
        Add-Content -LiteralPath (Join-Path $backupPath "SKILL.md") -Value "corrupt-backup" -Encoding utf8
      }

      if ((Get-DirectoryFingerprint -Path $backupPath) -ne $plan.DestinationFingerprint) {
'@
  $backupInstaller = New-InjectedInstaller -Sandbox $backupFail -FileName "install-backup-failure.ps1" -Needle $backupNeedle -Replacement $backupInjected
  Invoke-ExpectedFailure -Installer $backupInstaller -TargetRoot $backupFail.TargetRoot -SkillName "skill-a,skill-b" -ExpectedErrorText "Backup preparation failed before target mutation" | Out-Null

  Assert-True ((Read-Version (Join-Path $backupFail.TargetRoot "skill-a")) -eq "skill-a-existing-v1") "Backup verification failure mutated skill-a"
  Assert-True ((Read-Version (Join-Path $backupFail.TargetRoot "skill-b")) -eq "skill-b-existing-v1") "Backup verification failure mutated skill-b"
  $backupRunDirs = if (Test-Path -LiteralPath $backupFail.BackupRoot) { @(Get-ChildItem -LiteralPath $backupFail.BackupRoot -Directory) } else { @() }
  Assert-True ($backupRunDirs.Count -eq 0) "Failed unverified backup run was left behind"
  Assert-NoCurrentRunStagingLeak -TargetParent $backupFail.TargetParent

  $multi = New-Sandbox -Name "multi-swap" -SkillNames @("skill-a","skill-b") -ExistingNames @("skill-a","skill-b")
  $swapNeedle = @'
      Move-Item -LiteralPath $plan.StagePath -Destination $plan.Destination
      Assert-SkillBundle -Path $plan.Destination -ExpectedName $plan.Name
'@
  $swapInjected = @'
      if ($plan.Name -eq "skill-b") { throw "Injected second-skill swap failure" }
      Move-Item -LiteralPath $plan.StagePath -Destination $plan.Destination
      Assert-SkillBundle -Path $plan.Destination -ExpectedName $plan.Name
'@
  $swapInstaller = New-InjectedInstaller -Sandbox $multi -FileName "install-second-swap-failure.ps1" -Needle $swapNeedle -Replacement $swapInjected
  $swapResult = Invoke-ExpectedFailure -Installer $swapInstaller -TargetRoot $multi.TargetRoot -SkillName "skill-a,skill-b" -ExpectedErrorText "all applied changes were rolled back"

  Assert-True ((Read-Version (Join-Path $multi.TargetRoot "skill-a")) -eq "skill-a-existing-v1") "Second-skill failure did not roll back earlier skill-a"
  Assert-True ((Read-Version (Join-Path $multi.TargetRoot "skill-b")) -eq "skill-b-existing-v1") "Second-skill failure did not restore skill-b"
  Assert-True ($swapResult.Output.Contains("[INSTALLED] skill-a")) "Fault injection did not prove first skill installed before second failed"
  Assert-True ($swapResult.Output.Contains("[RESTORED] skill-a")) "Earlier successful skill was not reported restored"
  Assert-True ($swapResult.Output.Contains("[RESTORED] skill-b")) "Failed second skill was not reported restored"
  Assert-True (@(Get-ChildItem -LiteralPath $multi.BackupRoot -Recurse -Directory -Filter "skill-a").Count -eq 1) "Verified skill-a backup was not retained"
  Assert-True (@(Get-ChildItem -LiteralPath $multi.BackupRoot -Recurse -Directory -Filter "skill-b").Count -eq 1) "Verified skill-b backup was not retained"
  Assert-NoCurrentRunStagingLeak -TargetParent $multi.TargetParent

  $postVerify = New-Sandbox -Name "post-verify" -SkillNames @("skill-a","skill-b") -ExistingNames @("skill-a","skill-b")
  $verifyNeedle = @'
      Move-Item -LiteralPath $plan.StagePath -Destination $plan.Destination
      Assert-SkillBundle -Path $plan.Destination -ExpectedName $plan.Name

      if ((Get-DirectoryFingerprint -Path $plan.Destination) -ne $plan.SourceFingerprint) {
'@
  $verifyInjected = @'
      Move-Item -LiteralPath $plan.StagePath -Destination $plan.Destination
      Assert-SkillBundle -Path $plan.Destination -ExpectedName $plan.Name
      if ($plan.Name -eq "skill-b") {
        Add-Content -LiteralPath (Join-Path $plan.Destination "SKILL.md") -Value "post-install-corruption" -Encoding utf8
      }

      if ((Get-DirectoryFingerprint -Path $plan.Destination) -ne $plan.SourceFingerprint) {
'@
  $verifyInstaller = New-InjectedInstaller -Sandbox $postVerify -FileName "install-post-verify-failure.ps1" -Needle $verifyNeedle -Replacement $verifyInjected
  Invoke-ExpectedFailure -Installer $verifyInstaller -TargetRoot $postVerify.TargetRoot -SkillName "skill-a,skill-b" -ExpectedErrorText "Installed verification failed for skill-b" | Out-Null

  Assert-True ((Read-Version (Join-Path $postVerify.TargetRoot "skill-a")) -eq "skill-a-existing-v1") "Post-install verification failure did not restore skill-a"
  Assert-True ((Read-Version (Join-Path $postVerify.TargetRoot "skill-b")) -eq "skill-b-existing-v1") "Post-install verification failure did not restore skill-b"
  Assert-NoCurrentRunStagingLeak -TargetParent $postVerify.TargetParent

  $fresh = New-Sandbox -Name "fresh-failure" -SkillNames @("fresh-skill")
  $freshInjected = $verifyInjected.Replace('skill-b','fresh-skill')
  $freshInstaller = New-InjectedInstaller -Sandbox $fresh -FileName "install-fresh-post-verify-failure.ps1" -Needle $verifyNeedle -Replacement $freshInjected
  Invoke-ExpectedFailure -Installer $freshInstaller -TargetRoot $fresh.TargetRoot -SkillName "fresh-skill" -ExpectedErrorText "Installed verification failed for fresh-skill" | Out-Null

  Assert-True (-not (Test-Path -LiteralPath (Join-Path $fresh.TargetRoot "fresh-skill"))) "Failed fresh install left an active destination"
  Assert-True (-not (Test-Path -LiteralPath $fresh.TargetRoot)) "Failed fresh install left a target root created only by the failed invocation"
  Assert-NoCurrentRunStagingLeak -TargetParent $fresh.TargetParent

  $restoreFail = New-Sandbox -Name "restore-failure" -SkillNames @("fixture-skill") -ExistingNames @("fixture-skill")
  $restoreNeedle = @'
          Copy-Item -LiteralPath $plan.BackupPath -Destination $plan.Destination -Recurse -Force
          if ((Get-DirectoryFingerprint -Path $plan.Destination) -ne $plan.DestinationFingerprint) {
'@
  $restoreInjected = @'
          Copy-Item -LiteralPath $plan.BackupPath -Destination $plan.Destination -Recurse -Force
          Add-Content -LiteralPath (Join-Path $plan.Destination "SKILL.md") -Value "restore-corruption" -Encoding utf8
          if ((Get-DirectoryFingerprint -Path $plan.Destination) -ne $plan.DestinationFingerprint) {
'@
  $restoreBase = New-InjectedInstaller -Sandbox $restoreFail -FileName "install-restore-failure-base.ps1" -Needle $restoreNeedle -Replacement $restoreInjected
  $restoreBaseText = Get-Content -LiteralPath $restoreBase -Raw
  Assert-True ($restoreBaseText.Contains($swapNeedle)) "Restore-failure swap injection anchor missing"
  $restoreInstaller = Join-Path $restoreFail.Repo "install-restore-failure.ps1"
  [System.IO.File]::WriteAllText(
    $restoreInstaller,
    $restoreBaseText.Replace($swapNeedle, $swapInjected.Replace('skill-b','fixture-skill')),
    [System.Text.UTF8Encoding]::new($false)
  )

  $restoreResult = Invoke-ExpectedFailure -Installer $restoreInstaller -TargetRoot $restoreFail.TargetRoot -SkillName "fixture-skill" -ExpectedErrorText "automatic rollback was incomplete"
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $restoreFail.TargetRoot "fixture-skill"))) "Failed restore left an unverified active skill"
  Assert-True ($restoreResult.Error.Contains("Verified backups:")) "Incomplete rollback error omitted recovery backup path"
  Assert-True (Test-Path -LiteralPath $restoreFail.BackupRoot) "Incomplete rollback removed the verified backup needed for manual recovery"
  Assert-True (@(Get-ChildItem -LiteralPath $restoreFail.BackupRoot -Recurse -Directory -Filter "fixture-skill").Count -eq 1) "Verified recovery backup is missing after incomplete rollback"
  Assert-NoCurrentRunStagingLeak -TargetParent $restoreFail.TargetParent

  $stale = New-Sandbox -Name "staging-ownership" -SkillNames @("fixture-skill") -ExistingNames @("fixture-skill")
  $preexistingStagingName = ".skill-install-staging-stale-sentinel"
  $preexistingStaging = Join-Path $stale.TargetParent $preexistingStagingName
  New-Item -ItemType Directory -Path $preexistingStaging -Force | Out-Null
  Set-Content -LiteralPath (Join-Path $preexistingStaging "owner.txt") -Value "do-not-delete" -Encoding utf8NoBOM

  & $stale.Installer -TargetRoot $stale.TargetRoot -SkillName "fixture-skill" | Out-Null
  Assert-True (Test-Path -LiteralPath (Join-Path $preexistingStaging "owner.txt")) "Installer deleted a staging directory it did not create"
  Assert-NoCurrentRunStagingLeak -TargetParent $stale.TargetParent -AllowedName $preexistingStagingName

  Write-Output "[PASS] changed skills are fully staged before any destination mutation"
  Write-Output "[PASS] every required backup is verified before the first swap"
  Write-Output "[PASS] failed unverified backup runs are discarded before mutation"
  Write-Output "[PASS] multi-skill invocation rolls back earlier successful changes"
  Write-Output "[PASS] post-install verification failure rolls back the full invocation"
  Write-Output "[PASS] failed fresh install restores pre-run absence"
  Write-Output "[PASS] incomplete restore removes unsafe active content and preserves verified recovery backup"
  Write-Output "[PASS] identical reinstall is idempotent and creates no redundant backup"
  Write-Output "[PASS] current-run staging is cleaned without deleting unrelated staging directories"
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

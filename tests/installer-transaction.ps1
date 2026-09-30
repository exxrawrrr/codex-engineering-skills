$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$sourceInstaller = Join-Path $repoRoot "install.ps1"
$existingFixture = Join-Path $repoRoot "evidence\fixtures\installer\existing-skill"
$replacementFixture = Join-Path $repoRoot "evidence\fixtures\installer\replacement-skill"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-skills-transaction-" + [guid]::NewGuid().ToString("N"))

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )
  if (-not $Condition) { throw $Message }
}

function Read-Marker {
  param([Parameter(Mandatory = $true)][string]$SkillPath)
  $raw = Get-Content (Join-Path $SkillPath "SKILL.md") -Raw
  if ($raw -match "version-marker:\s*([^\r\n]+)") { return $Matches[1].Trim() }
  return $null
}

try {
  $fakeRepo = Join-Path $tempRoot "repo"
  $fakeSkills = Join-Path $fakeRepo "skills\fixture-skill"
  $targetRoot = Join-Path $tempRoot "target\skills"

  New-Item -ItemType Directory -Path $fakeSkills -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $targetRoot "fixture-skill") -Force | Out-Null

  Copy-Item $sourceInstaller (Join-Path $fakeRepo "install.ps1")
  Copy-Item (Join-Path $replacementFixture "*") $fakeSkills -Recurse -Force
  Copy-Item (Join-Path $existingFixture "*") (Join-Path $targetRoot "fixture-skill") -Recurse -Force

  @'
{
  "schema_version": 1,
  "suite": "installer-fixture",
  "version": "0.0.0",
  "skills": [
    {
      "name": "fixture-skill",
      "kind": "generic",
      "path": "skills/fixture-skill",
      "tags": ["fixture"],
      "status": "stable"
    }
  ]
}
'@ | Set-Content (Join-Path $fakeRepo "REGISTRY.json")

  $installer = Join-Path $fakeRepo "install.ps1"

  $first = & $installer -TargetRoot $targetRoot -SkillName "fixture-skill" | Out-String
  Assert-True ((Read-Marker (Join-Path $targetRoot "fixture-skill")) -eq "replacement-v2") "Initial replacement did not install v2"
  Assert-True ($first.Contains("[INSTALLED] fixture-skill")) "Initial replacement was not reported as installed"

  $backupRoot = Join-Path (Split-Path $targetRoot -Parent) "skills-backups"
  $backupSkills = @(Get-ChildItem $backupRoot -Recurse -Directory -Filter "fixture-skill")
  Assert-True ($backupSkills.Count -eq 1) "Initial replacement did not create exactly one backup"
  Assert-True ((Read-Marker $backupSkills[0].FullName) -eq "existing-v1") "Backup did not preserve existing v1"

  $backupFileCountBefore = @(Get-ChildItem $backupRoot -Recurse -File).Count
  $second = & $installer -TargetRoot $targetRoot -SkillName "fixture-skill" | Out-String
  $backupFileCountAfter = @(Get-ChildItem $backupRoot -Recurse -File).Count

  Assert-True ($second.Contains("[UNCHANGED] fixture-skill")) "Identical reinstall was not idempotent"
  Assert-True ($backupFileCountAfter -eq $backupFileCountBefore) "Identical reinstall created an unnecessary backup"

  $baseInstallerText = Get-Content $installer -Raw

  $validationNeedle = @'
    Copy-Item $src $stagePath -Recurse -Force

    Assert-SkillBundle -Path $stagePath -ExpectedName $name
'@
  $validationInjected = @'
    Copy-Item $src $stagePath -Recurse -Force

    if ($name -eq "fixture-skill") {
      (Get-Content (Join-Path $stagePath "SKILL.md") -Raw).Replace("name: fixture-skill", "name: wrong-skill") |
        Set-Content (Join-Path $stagePath "SKILL.md")
    }

    Assert-SkillBundle -Path $stagePath -ExpectedName $name
'@
  Assert-True ($baseInstallerText.Contains($validationNeedle)) "Validation injection anchor not found"

  $validationInstaller = Join-Path $fakeRepo "install-validation-failure.ps1"
  Set-Content $validationInstaller ($baseInstallerText.Replace($validationNeedle, $validationInjected))

  $validationFailed = $false
  try {
    & $validationInstaller -TargetRoot $targetRoot -SkillName "fixture-skill" | Out-Null
  } catch {
    $validationFailed = $true
  }

  Assert-True $validationFailed "Injected staged validation failure did not fail"
  Assert-True ((Read-Marker (Join-Path $targetRoot "fixture-skill")) -eq "replacement-v2") "Staged validation failure mutated installed v2"
  Assert-True (@(Get-ChildItem $backupRoot -Recurse -File).Count -eq $backupFileCountAfter) "Staged validation failure created a backup before validation"

  $v3 = (Get-Content (Join-Path $fakeSkills "SKILL.md") -Raw).Replace("replacement-v2", "replacement-v3")
  Set-Content (Join-Path $fakeSkills "SKILL.md") $v3

  $swapNeedle = @'
    try {
      if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
      Move-Item $stagePath $dst
'@
  $swapInjected = @'
    try {
      if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
      if ($name -eq "fixture-skill") { throw "Injected swap failure" }
      Move-Item $stagePath $dst
'@
  Assert-True ($baseInstallerText.Contains($swapNeedle)) "Swap injection anchor not found"

  $swapInstaller = Join-Path $fakeRepo "install-swap-failure.ps1"
  Set-Content $swapInstaller ($baseInstallerText.Replace($swapNeedle, $swapInjected))

  $swapFailed = $false
  try {
    & $swapInstaller -TargetRoot $targetRoot -SkillName "fixture-skill" | Out-Null
  } catch {
    $swapFailed = $true
  }

  Assert-True $swapFailed "Injected swap failure did not fail"
  Assert-True (Test-Path (Join-Path $targetRoot "fixture-skill\SKILL.md")) "Swap failure did not restore installed skill"
  Assert-True ((Read-Marker (Join-Path $targetRoot "fixture-skill")) -eq "replacement-v2") "Swap failure did not restore previous v2 content"

  $stagingLeaks = @(Get-ChildItem (Split-Path $targetRoot -Parent) -Directory -Filter ".skill-install-staging-*" -ErrorAction SilentlyContinue)
  Assert-True ($stagingLeaks.Count -eq 0) "Installer left staging directories after failure"

  Write-Output "[PASS] stage validation happens before destination mutation"
  Write-Output "[PASS] identical reinstall is idempotent"
  Write-Output "[PASS] injected swap failure restores previous installed skill"
  Write-Output "[PASS] staging directories are cleaned after failure"
} finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force
  }
}

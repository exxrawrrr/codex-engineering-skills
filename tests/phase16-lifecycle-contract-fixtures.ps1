$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "tests/phase16-lifecycle-contract.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-phase16-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  New-Item -ItemType Directory -Path $root -Force | Out-Null

  foreach ($dir in @("skills","evidence/incubation","evidence/lifecycle")) {
    New-Item -ItemType Directory -Path (Join-Path $root $dir) -Force | Out-Null
  }

  Copy-Item -LiteralPath (Join-Path $repoRoot "REGISTRY.json") -Destination (Join-Path $root "REGISTRY.json")
  Copy-Item -LiteralPath (Join-Path $repoRoot "validate.ps1") -Destination (Join-Path $root "validate.ps1")
  Copy-Item -LiteralPath (Join-Path $repoRoot "evidence/lifecycle/phase16-review-2026-10-01.json") -Destination (Join-Path $root "evidence/lifecycle/phase16-review-2026-10-01.json")

  Get-ChildItem -LiteralPath (Join-Path $repoRoot "skills") -Directory | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $root "skills" $_.Name) -Recurse
  }
  Get-ChildItem -LiteralPath (Join-Path $repoRoot "evidence/incubation") -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $root "evidence/incubation" $_.Name)
  }

  return @{
    Root = $root
    ReviewPath = Join-Path $root "evidence/lifecycle/phase16-review-2026-10-01.json"
    RegistryPath = Join-Path $root "REGISTRY.json"
    SkillRoot = Join-Path $root "skills"
    IncubationRoot = Join-Path $root "evidence/incubation"
    RootValidatorPath = Join-Path $root "validate.ps1"
  }
}

function Save-Json {
  param([string]$Path,[object]$Value)
  $Value | ConvertTo-Json -Depth 60 | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

function Invoke-Contract {
  param([hashtable]$Sandbox)
  $output = & pwsh -NoProfile -File $validator -ReviewPath $Sandbox.ReviewPath -RegistryPath $Sandbox.RegistryPath -SkillRoot $Sandbox.SkillRoot -IncubationRoot $Sandbox.IncubationRoot -RootValidatorPath $Sandbox.RootValidatorPath 2>&1
  return @{ ExitCode = $LASTEXITCODE; Text = (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine) }
}

function Assert-Passes {
  param([hashtable]$Sandbox)
  $r = Invoke-Contract -Sandbox $Sandbox
  if ($r.ExitCode -ne 0) { throw "Expected Phase 16 contract to pass. Output: $($r.Text)" }
  if (-not $r.Text.Contains("PHASE16_CONTRACT STATE=COMPLETE SKILLS=13 DEFERRED=3 CLEANUP_PENDING=0 FAIL=0")) {
    throw "Phase 16 contract passed without expected final summary. Output: $($r.Text)"
  }
  Write-Output "[PASS] valid locked Phase 16 lifecycle review"
}

function Assert-Rejected {
  param([hashtable]$Sandbox,[string]$ExpectedText)
  $r = Invoke-Contract -Sandbox $Sandbox
  if ($r.ExitCode -eq 0) { throw "Expected Phase 16 rejection containing '$ExpectedText'. Output: $($r.Text)" }
  if (-not $r.Text.Contains($ExpectedText)) { throw "Phase 16 rejected for wrong reason. Expected '$ExpectedText'. Output: $($r.Text)" }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $valid = New-Sandbox -Name "valid"
  Assert-Passes -Sandbox $valid

  $promotion = New-Sandbox -Name "promotion-overclaim"
  $d = Get-Content -LiteralPath $promotion.ReviewPath -Raw | ConvertFrom-Json
  (@($d.lifecycle_decisions | Where-Object { $_.skill -eq "api-contract-testing" })[0]).decision = "KEEP_STABLE"
  Save-Json -Path $promotion.ReviewPath -Value $d
  Assert-Rejected -Sandbox $promotion -ExpectedText "api-contract-testing: incubating skill must remain KEEP_INCUBATING in Phase 16"

  $evidenceOverclaim = New-Sandbox -Name "evidence-overclaim"
  $d = Get-Content -LiteralPath $evidenceOverclaim.ReviewPath -Raw | ConvertFrom-Json
  (@($d.lifecycle_decisions | Where-Object { $_.skill -eq "software-supply-chain-integrity" })[0]).evidence_state = "VERIFIED"
  Save-Json -Path $evidenceOverclaim.ReviewPath -Value $d
  Assert-Rejected -Sandbox $evidenceOverclaim -ExpectedText "software-supply-chain-integrity: incubating skill must remain UNPROVEN"

  $deferredLeak = New-Sandbox -Name "deferred-leak"
  $registry = Get-Content -LiteralPath $deferredLeak.RegistryPath -Raw | ConvertFrom-Json
  $registry.skills = @($registry.skills) + @([pscustomobject]@{
    name="observability-diagnostics";kind="generic";path="skills/observability-diagnostics";tags=@();status="incubating";evidence_tier="none";evidence_refs=@()
  })
  Save-Json -Path $deferredLeak.RegistryPath -Value $registry
  Assert-Rejected -Sandbox $deferredLeak -ExpectedText "lifecycle skill set mismatch"

  $badCleanup = New-Sandbox -Name "bad-cleanup"
  $d = Get-Content -LiteralPath $badCleanup.ReviewPath -Raw | ConvertFrom-Json
  (@($d.consolidation_decisions | Where-Object { $_.path -eq "skills/growthops-engineering/scripts/validate-suite.ps1" })[0]).decision = "KEEP"
  Save-Json -Path $badCleanup.ReviewPath -Value $d
  Assert-Rejected -Sandbox $badCleanup -ExpectedText "Phase 16 cleanup decision must be 'REMOVED_IN_16B' for completion_state 'COMPLETE'"

  $missingLockDate = New-Sandbox -Name "missing-lock-date"
  $d = Get-Content -LiteralPath $missingLockDate.ReviewPath -Raw | ConvertFrom-Json
  $d.locked_on = $null
  Save-Json -Path $missingLockDate.ReviewPath -Value $d
  Assert-Rejected -Sandbox $missingLockDate -ExpectedText "COMPLETE state requires locked_on=2026-10-01"

  $pendingRemoval = New-Sandbox -Name "pending-removal"
  $d = Get-Content -LiteralPath $pendingRemoval.ReviewPath -Raw | ConvertFrom-Json
  $d.removals_pending_16B = @("skills/growthops-engineering/scripts/validate-suite.ps1")
  Save-Json -Path $pendingRemoval.ReviewPath -Value $d
  Assert-Rejected -Sandbox $pendingRemoval -ExpectedText "COMPLETE state requires removals_pending_16B to be empty"

  $reintroducedCleanup = New-Sandbox -Name "reintroduced-cleanup"
  $scriptDir = Join-Path $reintroducedCleanup.Root "skills/growthops-engineering/scripts"
  New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
  Set-Content -LiteralPath (Join-Path $scriptDir "validate-suite.ps1") -Value "Write-Output 'stale'" -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $reintroducedCleanup -ExpectedText "COMPLETE state requires redundant validate-suite.ps1 to be removed"

  $badLockClaim = New-Sandbox -Name "bad-lock-claim"
  $d = Get-Content -LiteralPath $badLockClaim.ReviewPath -Raw | ConvertFrom-Json
  $d.lock_claim = "Phase 16 complete."
  Save-Json -Path $badLockClaim.ReviewPath -Value $d
  Assert-Rejected -Sandbox $badLockClaim -ExpectedText "COMPLETE state requires an explicit UNPROVEN / no evidence-tier promotion lock claim"

  $missingSkill = New-Sandbox -Name "missing-skill"
  $d = Get-Content -LiteralPath $missingSkill.ReviewPath -Raw | ConvertFrom-Json
  $d.lifecycle_decisions = @($d.lifecycle_decisions | Where-Object { $_.skill -ne "agent-skill-authoring" })
  Save-Json -Path $missingSkill.ReviewPath -Value $d
  Assert-Rejected -Sandbox $missingSkill -ExpectedText "lifecycle skill set mismatch"

  Write-Output "[PASS] Phase 16 lifecycle overclaim, deferred-leak, completed-cleanup, lock, and completeness fixtures are regression-covered"
} finally {
  if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

exit 0

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "tests/wave-b-incubation-contract.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-wave-b-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  $skillRoot = Join-Path $root "skills"
  $incubationRoot = Join-Path $root "evidence/incubation"
  New-Item -ItemType Directory -Path $skillRoot -Force | Out-Null
  New-Item -ItemType Directory -Path $incubationRoot -Force | Out-Null

  Copy-Item -LiteralPath (Join-Path $repoRoot "evidence/incubation/wave-b-decisions-2026-09-30.json") -Destination (Join-Path $incubationRoot "wave-b-decisions-2026-09-30.json")
  Copy-Item -LiteralPath (Join-Path $repoRoot "REGISTRY.json") -Destination (Join-Path $root "REGISTRY.json")

  foreach ($target in @("runtime-compatibility-engineering","software-supply-chain-integrity")) {
    $sourceSkill = Join-Path (Join-Path $repoRoot "skills") $target
    if (Test-Path -LiteralPath $sourceSkill) {
      Copy-Item -LiteralPath $sourceSkill -Destination (Join-Path $skillRoot $target) -Recurse
    }
    $sourceRecord = Join-Path (Join-Path $repoRoot "evidence/incubation") ($target + ".json")
    if (Test-Path -LiteralPath $sourceRecord) {
      Copy-Item -LiteralPath $sourceRecord -Destination (Join-Path $incubationRoot ($target + ".json"))
    }
  }

  return @{
    Root = $root
    DecisionPath = Join-Path $incubationRoot "wave-b-decisions-2026-09-30.json"
    RegistryPath = Join-Path $root "REGISTRY.json"
    SkillRoot = $skillRoot
    IncubationRoot = $incubationRoot
  }
}

function Save-Json {
  param([Parameter(Mandatory = $true)][string]$Path,[Parameter(Mandatory = $true)][object]$Value)
  $Value | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

function Invoke-Contract {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)
  $output = & pwsh -NoProfile -File $validator -DecisionPath $Sandbox.DecisionPath -RegistryPath $Sandbox.RegistryPath -SkillRoot $Sandbox.SkillRoot -IncubationRoot $Sandbox.IncubationRoot 2>&1
  return @{ ExitCode = $LASTEXITCODE; Text = (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine) }
}

function Assert-Passes {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)
  $result = Invoke-Contract -Sandbox $Sandbox
  if ($result.ExitCode -ne 0) { throw "Expected Wave B contract to pass. Output: $($result.Text)" }
  if (-not $result.Text.Contains("WAVE_B_CONTRACT STATE=IMPLEMENTATION_IN_PROGRESS_15B DECISIONS=5 CREATED=1 PENDING=1 DEFERRED=3 FAIL=0")) {
    throw "Wave B contract passed without expected admission summary. Output: $($result.Text)"
  }
  Write-Output "[PASS] valid Wave B 15B progress ledger"
}

function Assert-Rejected {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox,[Parameter(Mandatory = $true)][string]$ExpectedText)
  $result = Invoke-Contract -Sandbox $Sandbox
  if ($result.ExitCode -eq 0) { throw "Expected Wave B rejection containing '$ExpectedText'. Output: $($result.Text)" }
  if (-not $result.Text.Contains($ExpectedText)) { throw "Wave B rejected for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)" }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $valid = New-Sandbox -Name "valid"
  Assert-Passes -Sandbox $valid

  $missingCandidate = New-Sandbox -Name "missing-candidate"
  $d = Get-Content -LiteralPath $missingCandidate.DecisionPath -Raw | ConvertFrom-Json
  $d.decisions = @($d.decisions | Where-Object { $_.candidate -ne "observability-diagnostics" })
  Save-Json -Path $missingCandidate.DecisionPath -Value $d
  Assert-Rejected -Sandbox $missingCandidate -ExpectedText "decision candidates mismatch"

  $promoteDeferred = New-Sandbox -Name "promote-deferred"
  $d = Get-Content -LiteralPath $promoteDeferred.DecisionPath -Raw | ConvertFrom-Json
  (@($d.decisions | Where-Object { $_.candidate -eq "release-rollback-engineering" })[0]).decision = "ADOPT"
  Save-Json -Path $promoteDeferred.DecisionPath -Value $d
  Assert-Rejected -Sandbox $promoteDeferred -ExpectedText "decision must be 'DEFER'"

  $deferTarget = New-Sandbox -Name "defer-target"
  $d = Get-Content -LiteralPath $deferTarget.DecisionPath -Raw | ConvertFrom-Json
  $row = @($d.decisions | Where-Object { $_.candidate -eq "observability-diagnostics" })[0]
  $row.target_skill = "observability-diagnostics"
  Save-Json -Path $deferTarget.DecisionPath -Value $d
  Assert-Rejected -Sandbox $deferTarget -ExpectedText "DEFER must not define target_skill"

  $overclaim = New-Sandbox -Name "effectiveness-overclaim"
  $d = Get-Content -LiteralPath $overclaim.DecisionPath -Raw | ConvertFrom-Json
  (@($d.decisions | Where-Object { $_.candidate -eq "compatibility-engineering" })[0]).evidence_state = "OBSERVED"
  Save-Json -Path $overclaim.DecisionPath -Value $d
  Assert-Rejected -Sandbox $overclaim -ExpectedText "effectiveness must remain UNPROVEN / evidence_tier none"

  $badCompatTarget = New-Sandbox -Name "bad-compat-target"
  $d = Get-Content -LiteralPath $badCompatTarget.DecisionPath -Raw | ConvertFrom-Json
  (@($d.decisions | Where-Object { $_.candidate -eq "compatibility-engineering" })[0]).target_skill = "compatibility-engineering"
  Save-Json -Path $badCompatTarget.DecisionPath -Value $d
  Assert-Rejected -Sandbox $badCompatTarget -ExpectedText "target_skill must be 'runtime-compatibility-engineering'"

  $badSupplyTarget = New-Sandbox -Name "bad-supply-target"
  $d = Get-Content -LiteralPath $badSupplyTarget.DecisionPath -Raw | ConvertFrom-Json
  (@($d.decisions | Where-Object { $_.candidate -eq "supply-chain-security" })[0]).target_skill = "supply-chain-security"
  Save-Json -Path $badSupplyTarget.DecisionPath -Value $d
  Assert-Rejected -Sandbox $badSupplyTarget -ExpectedText "target_skill must be 'software-supply-chain-integrity'"

  $premature = New-Sandbox -Name "premature-registration"
  $registry = Get-Content -LiteralPath $premature.RegistryPath -Raw | ConvertFrom-Json
  $registry.skills = @($registry.skills) + @([pscustomobject]@{
    name="software-supply-chain-integrity";kind="generic";path="skills/software-supply-chain-integrity";tags=@("supply-chain");status="incubating";evidence_tier="none";evidence_refs=@()
  })
  Save-Json -Path $premature.RegistryPath -Value $registry
  Assert-Rejected -Sandbox $premature -ExpectedText "PENDING_15B target 'software-supply-chain-integrity' must not be prematurely registered"

  $runtimeCase = New-Sandbox -Name "runtime-case-overclaim"
  $recordPath = Join-Path $runtimeCase.IncubationRoot "runtime-compatibility-engineering.json"
  $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
  $record.representative_case_plan.execution_status = "COMPLETED"
  Save-Json -Path $recordPath -Value $record
  Assert-Rejected -Sandbox $runtimeCase -ExpectedText "representative case must remain NOT_RUN"

  $badState = New-Sandbox -Name "bad-state"
  $d = Get-Content -LiteralPath $badState.DecisionPath -Raw | ConvertFrom-Json
  $d.completion_state = "IMPLEMENTATION_COMPLETE_PENDING_LOCK"
  $d.split = "15B"
  Save-Json -Path $badState.DecisionPath -Value $d
  Assert-Rejected -Sandbox $badState -ExpectedText "created targets mismatch"

  Write-Output "[PASS] Wave B defer, scope-narrowing, overclaim, and premature-registration fixtures are regression-covered"
} finally {
  if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

exit 0

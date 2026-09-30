$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "tests/wave-a-incubation-contract.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-wave-a-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  $skillRoot = Join-Path $root "skills"
  $incubationRoot = Join-Path $root "evidence/incubation"
  New-Item -ItemType Directory -Path $skillRoot -Force | Out-Null
  New-Item -ItemType Directory -Path $incubationRoot -Force | Out-Null

  Copy-Item -LiteralPath (Join-Path $repoRoot "evidence/incubation/wave-a-decisions-2026-09-30.json") -Destination (Join-Path $incubationRoot "wave-a-decisions-2026-09-30.json")
  Copy-Item -LiteralPath (Join-Path $repoRoot "REGISTRY.json") -Destination (Join-Path $root "REGISTRY.json")
  Copy-Item -LiteralPath (Join-Path $repoRoot "PROVENANCE.json") -Destination (Join-Path $root "PROVENANCE.json")

  foreach ($target in @("agent-skill-evaluation","api-contract-testing","ci-pipeline-reliability")) {
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
    DecisionPath = Join-Path $incubationRoot "wave-a-decisions-2026-09-30.json"
    RegistryPath = Join-Path $root "REGISTRY.json"
    ProvenancePath = Join-Path $root "PROVENANCE.json"
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
  $output = & pwsh -NoProfile -File $validator -DecisionPath $Sandbox.DecisionPath -RegistryPath $Sandbox.RegistryPath -ProvenancePath $Sandbox.ProvenancePath -SkillRoot $Sandbox.SkillRoot -IncubationRoot $Sandbox.IncubationRoot 2>&1
  return @{ ExitCode = $LASTEXITCODE; Text = (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine) }
}

function Assert-Passes {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)
  $result = Invoke-Contract -Sandbox $Sandbox
  if ($result.ExitCode -ne 0) { throw "Expected Wave A contract to pass. Output: $($result.Text)" }
  if (-not $result.Text.Contains("WAVE_A_CONTRACT STATE=IMPLEMENTATION_IN_PROGRESS_14B DECISIONS=3 CREATED=2 PENDING=1 FAIL=0")) {
    throw "Wave A contract passed without expected progress summary. Output: $($result.Text)"
  }
  Write-Output "[PASS] valid Wave A 14B progress ledger"
}

function Assert-Rejected {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox,[Parameter(Mandatory = $true)][string]$ExpectedText)
  $result = Invoke-Contract -Sandbox $Sandbox
  if ($result.ExitCode -eq 0) { throw "Expected Wave A rejection containing '$ExpectedText'. Output: $($result.Text)" }
  if (-not $result.Text.Contains($ExpectedText)) { throw "Wave A rejected for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)" }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $valid = New-Sandbox -Name "valid"
  Assert-Passes -Sandbox $valid

  $missingCandidate = New-Sandbox -Name "missing-candidate"
  $d = Get-Content -LiteralPath $missingCandidate.DecisionPath -Raw | ConvertFrom-Json
  $d.decisions = @($d.decisions | Where-Object { $_.candidate -ne "api-contract-testing" })
  Save-Json -Path $missingCandidate.DecisionPath -Value $d
  Assert-Rejected -Sandbox $missingCandidate -ExpectedText "decision candidates mismatch"

  $stable = New-Sandbox -Name "stable-promotion"
  $d = Get-Content -LiteralPath $stable.DecisionPath -Raw | ConvertFrom-Json
  (@($d.decisions | Where-Object { $_.candidate -eq "api-contract-testing" })[0]).lifecycle_status = "stable"
  Save-Json -Path $stable.DecisionPath -Value $d
  Assert-Rejected -Sandbox $stable -ExpectedText "Wave A candidate must remain incubating"

  $overclaim = New-Sandbox -Name "effectiveness-overclaim"
  $d = Get-Content -LiteralPath $overclaim.DecisionPath -Raw | ConvertFrom-Json
  (@($d.decisions | Where-Object { $_.candidate -eq "api-contract-testing" })[0]).evidence_state = "OBSERVED"
  Save-Json -Path $overclaim.DecisionPath -Value $d
  Assert-Rejected -Sandbox $overclaim -ExpectedText "effectiveness must remain UNPROVEN / evidence_tier none"

  $noOverlap = New-Sandbox -Name "missing-overlap"
  $d = Get-Content -LiteralPath $noOverlap.DecisionPath -Raw | ConvertFrom-Json
  (@($d.decisions | Where-Object { $_.candidate -eq "api-contract-testing" })[0]).overlap_review = [pscustomobject]@{}
  Save-Json -Path $noOverlap.DecisionPath -Value $d
  Assert-Rejected -Sandbox $noOverlap -ExpectedText "overlap_review must name at least one neighboring skill/wave"

  $badModify = New-Sandbox -Name "bad-modify"
  $d = Get-Content -LiteralPath $badModify.DecisionPath -Raw | ConvertFrom-Json
  (@($d.decisions | Where-Object { $_.candidate -eq "ci-cd-reliability" })[0]).target_skill = "ci-cd-reliability"
  Save-Json -Path $badModify.DecisionPath -Value $d
  Assert-Rejected -Sandbox $badModify -ExpectedText "target_skill must be 'ci-pipeline-reliability'"

  $premature = New-Sandbox -Name "premature-ci-registration"
  $registry = Get-Content -LiteralPath $premature.RegistryPath -Raw | ConvertFrom-Json
  $registry.skills = @($registry.skills) + @([pscustomobject]@{
    name="ci-pipeline-reliability";kind="generic";path="skills/ci-pipeline-reliability";tags=@("ci");status="incubating";evidence_tier="none";evidence_refs=@()
  })
  Save-Json -Path $premature.RegistryPath -Value $registry
  Assert-Rejected -Sandbox $premature -ExpectedText "PENDING_14B target 'ci-pipeline-reliability' must not be prematurely registered"

  $apiCase = New-Sandbox -Name "api-case-overclaim"
  $recordPath = Join-Path $apiCase.IncubationRoot "api-contract-testing.json"
  $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
  $record.representative_case_plan.execution_status = "COMPLETED"
  Save-Json -Path $recordPath -Value $record
  Assert-Rejected -Sandbox $apiCase -ExpectedText "representative case must remain NOT_RUN"

  $missingLimit = New-Sandbox -Name "missing-api-limitations"
  $skillPath = Join-Path (Join-Path $missingLimit.SkillRoot "api-contract-testing") "SKILL.md"
  $skillText = Get-Content -LiteralPath $skillPath -Raw
  $skillText = $skillText.Replace("## Limitations","## Notes")
  Set-Content -LiteralPath $skillPath -Value $skillText -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $missingLimit -ExpectedText "SKILL.md missing boundary marker: ## Limitations"

  Write-Output "[PASS] Wave A lifecycle, overclaim, pending-registration, and created-skill fixtures are regression-covered"
} finally {
  if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

exit 0

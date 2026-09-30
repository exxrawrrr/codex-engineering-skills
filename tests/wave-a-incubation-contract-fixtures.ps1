$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "tests/wave-a-incubation-contract.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-wave-a-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  New-Item -ItemType Directory -Path (Join-Path $root "evidence/incubation") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $root "skills/agent-skill-evaluation") -Force | Out-Null

  Copy-Item -LiteralPath (Join-Path $repoRoot "evidence/incubation/wave-a-decisions-2026-09-30.json") -Destination (Join-Path $root "evidence/incubation/wave-a-decisions-2026-09-30.json")
  Copy-Item -LiteralPath (Join-Path $repoRoot "evidence/incubation/agent-skill-evaluation.json") -Destination (Join-Path $root "evidence/incubation/agent-skill-evaluation.json")
  Copy-Item -LiteralPath (Join-Path $repoRoot "skills/agent-skill-evaluation/SKILL.md") -Destination (Join-Path $root "skills/agent-skill-evaluation/SKILL.md")
  Copy-Item -LiteralPath (Join-Path $repoRoot "REGISTRY.json") -Destination (Join-Path $root "REGISTRY.json")
  Copy-Item -LiteralPath (Join-Path $repoRoot "PROVENANCE.json") -Destination (Join-Path $root "PROVENANCE.json")

  return @{
    Root = $root
    DecisionPath = Join-Path $root "evidence/incubation/wave-a-decisions-2026-09-30.json"
    AgentRecordPath = Join-Path $root "evidence/incubation/agent-skill-evaluation.json"
    AgentSkillPath = Join-Path $root "skills/agent-skill-evaluation/SKILL.md"
    RegistryPath = Join-Path $root "REGISTRY.json"
    ProvenancePath = Join-Path $root "PROVENANCE.json"
  }
}

function Save-Json {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][object]$Value
  )
  $Value | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

function Invoke-Contract {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)

  $output = & pwsh -NoProfile -File $validator -DecisionPath $Sandbox.DecisionPath -AgentRecordPath $Sandbox.AgentRecordPath -AgentSkillPath $Sandbox.AgentSkillPath -RegistryPath $Sandbox.RegistryPath -ProvenancePath $Sandbox.ProvenancePath 2>&1
  return @{
    ExitCode = $LASTEXITCODE
    Text = (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
  }
}

function Assert-Passes {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)
  $result = Invoke-Contract -Sandbox $Sandbox
  if ($result.ExitCode -ne 0) {
    throw "Expected Wave A contract to pass. Output: $($result.Text)"
  }
  if (-not $result.Text.Contains("WAVE_A_CONTRACT DECISIONS=3 CREATED=1 PENDING=2 FAIL=0")) {
    throw "Wave A contract passed without expected summary. Output: $($result.Text)"
  }
  Write-Output "[PASS] valid Wave A admission ledger"
}

function Assert-Rejected {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )
  $result = Invoke-Contract -Sandbox $Sandbox
  if ($result.ExitCode -eq 0) {
    throw "Expected Wave A rejection containing '$ExpectedText'. Output: $($result.Text)"
  }
  if (-not $result.Text.Contains($ExpectedText)) {
    throw "Wave A rejected for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)"
  }
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
  Assert-Rejected -Sandbox $stable -ExpectedText "Wave A candidate must not be stable"

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
  $row = @($d.decisions | Where-Object { $_.candidate -eq "ci-cd-reliability" })[0]
  $row.target_skill = "ci-cd-reliability"
  Save-Json -Path $badModify.DecisionPath -Value $d
  Assert-Rejected -Sandbox $badModify -ExpectedText "MODIFY must change target_skill or scope identity"

  $premature = New-Sandbox -Name "premature-registration"
  $registry = Get-Content -LiteralPath $premature.RegistryPath -Raw | ConvertFrom-Json
  $newEntry = [pscustomobject]@{
    name = "api-contract-testing"
    kind = "generic"
    path = "skills/api-contract-testing"
    tags = @("api","contracts")
    status = "incubating"
    evidence_tier = "none"
    evidence_refs = @()
  }
  $registry.skills = @($registry.skills) + @($newEntry)
  Save-Json -Path $premature.RegistryPath -Value $registry
  Assert-Rejected -Sandbox $premature -ExpectedText "PENDING_14B target 'api-contract-testing' must not be prematurely registered"

  $agentCase = New-Sandbox -Name "agent-case-overclaim"
  $record = Get-Content -LiteralPath $agentCase.AgentRecordPath -Raw | ConvertFrom-Json
  $record.representative_case_plan.execution_status = "PASS"
  Save-Json -Path $agentCase.AgentRecordPath -Value $record
  Assert-Rejected -Sandbox $agentCase -ExpectedText "representative case must remain NOT_RUN in 14A"

  $missingLimit = New-Sandbox -Name "missing-limitations"
  $skillText = Get-Content -LiteralPath $missingLimit.AgentSkillPath -Raw
  $skillText = $skillText.Replace("## Limitations","## Notes")
  Set-Content -LiteralPath $missingLimit.AgentSkillPath -Value $skillText -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $missingLimit -ExpectedText "SKILL.md missing boundary marker: ## Limitations"

  Write-Output "[PASS] Wave A admission drift and overclaim fixtures are regression-covered"
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

exit 0

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "tests/compatibility-contract.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-compat-contract-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  New-Item -ItemType Directory -Path $root -Force | Out-Null

  $matrixPath = Join-Path $root "matrix.json"
  $docPath = Join-Path $root "COMPATIBILITY.md"
  $workflowPath = Join-Path $root "validate.yml"

  Copy-Item -LiteralPath (Join-Path $repoRoot "evidence/compatibility/2026-09-30.json") -Destination $matrixPath
  Copy-Item -LiteralPath (Join-Path $repoRoot "COMPATIBILITY.md") -Destination $docPath
  Copy-Item -LiteralPath (Join-Path $repoRoot ".github/workflows/validate.yml") -Destination $workflowPath

  return @{
    Root = $root
    MatrixPath = $matrixPath
    DocPath = $docPath
    WorkflowPath = $workflowPath
  }
}

function Invoke-Validator {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)

  $output = & pwsh -NoProfile -File $validator -MatrixPath $Sandbox.MatrixPath -CompatibilityPath $Sandbox.DocPath -WorkflowPath $Sandbox.WorkflowPath 2>&1

  return @{
    ExitCode = $LASTEXITCODE
    Text = (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
  }
}

function Assert-Passes {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )

  $result = Invoke-Validator -Sandbox $Sandbox
  if ($result.ExitCode -ne 0) {
    throw "Expected compatibility validator to pass. Output: $($result.Text)"
  }
  if (-not $result.Text.Contains($ExpectedText)) {
    throw "Compatibility validator passed without '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] $ExpectedText"
}

function Assert-Rejected {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )

  $result = Invoke-Validator -Sandbox $Sandbox
  if ($result.ExitCode -eq 0) {
    throw "Expected compatibility validator rejection containing '$ExpectedText'. Output: $($result.Text)"
  }
  if (-not $result.Text.Contains($ExpectedText)) {
    throw "Compatibility validator rejected for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $valid = New-Sandbox -Name "valid"
  Assert-Passes -Sandbox $valid -ExpectedText "COMPATIBILITY_CONTRACT ENVIRONMENTS=5 FAIL=0 EVIDENCE_RUN=36686190812"

  $oldSchema = New-Sandbox -Name "old-schema"
  $matrix = Get-Content -LiteralPath $oldSchema.MatrixPath -Raw | ConvertFrom-Json
  $matrix.schema_version = 1
  $matrix | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $oldSchema.MatrixPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $oldSchema -ExpectedText "Unsupported compatibility schema_version '1'; expected 2"

  $runtimeOverclaim = New-Sandbox -Name "runtime-overclaim"
  $matrix = Get-Content -LiteralPath $runtimeOverclaim.MatrixPath -Raw | ConvertFrom-Json
  $row = @($matrix.environments | Where-Object { $_.id -eq "windows-github-hosted-pwsh-tooling" })[0]
  $row.runtime_loading = "TESTED"
  $matrix | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $runtimeOverclaim.MatrixPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $runtimeOverclaim -ExpectedText "runtime_loading must be 'NOT_RUN'"

  $macOverclaim = New-Sandbox -Name "mac-overclaim"
  $matrix = Get-Content -LiteralPath $macOverclaim.MatrixPath -Raw | ConvertFrom-Json
  $row = @($matrix.environments | Where-Object { $_.id -eq "macos-pwsh-filesystem-skills" })[0]
  $row.tested_execution = "TESTED"
  $matrix | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $macOverclaim.MatrixPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $macOverclaim -ExpectedText "tested_execution must be 'NOT_RUN'"

  $staleRun = New-Sandbox -Name "stale-run"
  $matrix = Get-Content -LiteralPath $staleRun.MatrixPath -Raw | ConvertFrom-Json
  $matrix.evidence_basis.pull_request = 12
  $matrix.evidence_basis.pull_request_ci_run = 36667646038
  $matrix | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $staleRun.MatrixPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $staleRun -ExpectedText "pull_request must be 26"

  $docDrift = New-Sandbox -Name "doc-drift"
  $doc = Get-Content -LiteralPath $docDrift.DocPath -Raw
  $doc = $doc.Replace(
    "| GitHub-hosted Ubuntu + PowerShell Core repository tooling | COMPATIBLE_BY_FORMAT | COMPATIBLE_BY_DESIGN | **TESTED** | **NOT RUN** |",
    "| GitHub-hosted Ubuntu + PowerShell Core repository tooling | COMPATIBLE_BY_FORMAT | COMPATIBLE_BY_DESIGN | **TESTED** | **TESTED** |"
  )
  Set-Content -LiteralPath $docDrift.DocPath -Value $doc -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $docDrift -ExpectedText "COMPATIBILITY.md matrix row drifted"

  $workflowDrift = New-Sandbox -Name "workflow-drift"
  $workflow = Get-Content -LiteralPath $workflowDrift.WorkflowPath -Raw
  $workflow = $workflow.Replace('throw "CI requires PowerShell 7+; observed $($PSVersionTable.PSVersion)"','throw "PowerShell version is unsupported"')
  Set-Content -LiteralPath $workflowDrift.WorkflowPath -Value $workflow -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $workflowDrift -ExpectedText "Workflow no longer asserts PowerShell 7+"

  $otherAgentOverclaim = New-Sandbox -Name "other-agent-overclaim"
  $matrix = Get-Content -LiteralPath $otherAgentOverclaim.MatrixPath -Raw | ConvertFrom-Json
  $row = @($matrix.environments | Where-Object { $_.id -eq "other-filesystem-agent-same-convention" })[0]
  $row.tested_execution = "TESTED"
  $matrix | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $otherAgentOverclaim.MatrixPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $otherAgentOverclaim -ExpectedText "tested_execution must be 'NOT_RUN'"

  Write-Output "[PASS] compatibility overclaim/staleness fixtures are regression-covered"
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

exit 0

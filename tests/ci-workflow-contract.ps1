param(
  [string]$WorkflowPath = "$PSScriptRoot\..\.github\workflows\validate.yml"
)

$ErrorActionPreference = "Stop"

function Assert-ContainsOnce {
  param(
    [Parameter(Mandatory = $true)][string]$Text,
    [Parameter(Mandatory = $true)][string]$Needle,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $count = ([regex]::Matches($Text, [regex]::Escape($Needle))).Count
  if ($count -ne 1) {
    throw "$Label must appear exactly once; observed $count"
  }
}

if (-not (Test-Path -LiteralPath $WorkflowPath)) {
  throw "Missing CI workflow: $WorkflowPath"
}

$workflow = Get-Content -LiteralPath $WorkflowPath -Raw

if ($workflow -notmatch "(?m)^\s*fail-fast:\s*false\s*$") {
  throw "CI matrix must keep fail-fast: false so Windows and Ubuntu report independently"
}

if ($workflow -notmatch "(?m)^\s*os:\s*\[windows-latest,\s*ubuntu-latest\]\s*$") {
  throw "CI matrix must contain exactly windows-latest and ubuntu-latest"
}

if ($workflow -match "(?m)^\s*(include|exclude):\s*$") {
  throw "CI matrix must not silently include/exclude platform variants"
}

if ($workflow -notmatch '(?m)^\s*runs-on:\s*\$\{\{\s*matrix\.os\s*\}\}\s*$') {
  throw "CI validate job must run directly on matrix.os"
}

if ($workflow -match "(?m)^\s*continue-on-error:\s*true\s*$") {
  throw "CI validation steps must not use continue-on-error: true"
}

if ($workflow -match "(?m)^\s*if:\s*") {
  throw "CI validation workflow must not conditionally skip matrix validation steps"
}

if ($workflow -notmatch "(?m)^permissions:\s*\r?\n\s*contents:\s*read\s*$") {
  throw "CI workflow must keep read-only contents permission"
}

Assert-ContainsOnce -Text $workflow -Needle "actions/checkout@v7.0.1" -Label "Pinned checkout action"
Assert-ContainsOnce -Text $workflow -Needle "name: Report PowerShell runtime" -Label "PowerShell runtime evidence step"
Assert-ContainsOnce -Text $workflow -Needle "name: Validate CI workflow contract" -Label "CI self-contract step"

$requiredCommands = @(
  "./tests/ci-workflow-contract.ps1",
  "./validate.ps1 -SkillsRoot ./skills",
  "./tests/baseline-lock.ps1",
  "./tests/text-hygiene.ps1",
  "./tests/validator-fixtures.ps1",
  "./tests/static-validator-contract.ps1",
  "./tests/evidence-model-contract.ps1",
  "./tests/evaluation-harness.ps1",
  "./tests/evaluation-harness-contract.ps1",
  "./tests/context-benchmark.ps1",
  "./tests/context-benchmark-contract.ps1",
  "./tests/router-evaluation.ps1",
  "./tests/router-evaluation-contract.ps1",
  "./tests/growthops-case-study.ps1",
  "./tests/growthops-case-study-contract.ps1",
  "./tests/installer-selection.ps1",
  "./tests/installer-transaction.ps1",
  "./tests/compatibility-contract.ps1",
  "./tests/provenance-contract.ps1"
)

foreach ($command in $requiredCommands) {
  Assert-ContainsOnce -Text $workflow -Needle $command -Label "Required CI command '$command'"
}

$runStepPattern = '(?ms)^\s*- name:\s*(?<name>[^\r\n]+)\r?\n(?<body>.*?)(?=^\s*- name:|^\s*- uses:|\z)'
$runSteps = [regex]::Matches($workflow, $runStepPattern)
$runStepCount = 0

foreach ($match in $runSteps) {
  $body = [string]$match.Groups["body"].Value
  if ($body -notmatch "(?m)^\s*run:\s*") {
    continue
  }

  $runStepCount++
  if ($body -notmatch "(?m)^\s*shell:\s*pwsh\s*$") {
    throw "Run step '$($match.Groups["name"].Value.Trim())' must use shell: pwsh"
  }
}

if ($runStepCount -lt 20) {
  throw "Expected at least 20 PowerShell run steps in the current full validation workflow; observed $runStepCount"
}

if ($workflow -match '(?m)^\s*run:\s*\.\\') {
  throw "CI script invocation must use cross-platform ./ paths, not Windows-only .\ paths"
}

Write-Output "[PASS] CI matrix is exactly Windows + Ubuntu with fail-fast disabled"
Write-Output "[PASS] validation steps cannot silently continue or conditionally skip"
Write-Output "[PASS] every required current suite command is present exactly once"
Write-Output "[PASS] every run step uses PowerShell Core shell semantics"
Write-Output "[PASS] CI script paths use cross-platform ./ form"
Write-Output ("CI_CONTRACT RUN_STEPS={0} FAIL=0" -f $runStepCount)

exit 0

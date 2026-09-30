param(
  [string]$MatrixPath = "$PSScriptRoot\..\evidence\compatibility\2026-09-30.json",
  [string]$CompatibilityPath = "$PSScriptRoot\..\COMPATIBILITY.md",
  [string]$WorkflowPath = "$PSScriptRoot\..\.github\workflows\validate.yml"
)

$ErrorActionPreference = "Stop"
$matrix = Get-Content $MatrixPath -Raw | ConvertFrom-Json
$doc = Get-Content $CompatibilityPath -Raw
$workflow = Get-Content $WorkflowPath -Raw
$errors = New-Object System.Collections.Generic.List[string]

if ($matrix.schema_version -ne 1) {
  $errors.Add("Unsupported compatibility schema_version: $($matrix.schema_version)")
}

$byId = @{}
foreach ($envItem in $matrix.environments) {
  $id = [string]$envItem.id
  if ([string]::IsNullOrWhiteSpace($id)) {
    $errors.Add("Compatibility environment has empty id")
    continue
  }
  if ($byId.ContainsKey($id)) {
    $errors.Add("Duplicate compatibility environment id: $id")
    continue
  }
  if ([string]::IsNullOrWhiteSpace([string]$envItem.evidence)) {
    $errors.Add("${id}: evidence text is required")
  }
  $byId[$id] = $envItem
}

$expected = @{
  "windows-pwsh-filesystem-skills" = "TESTED"
  "ubuntu-pwsh-filesystem-skills" = "TESTED"
  "macos-pwsh-filesystem-skills" = "NOT_RUN"
  "other-filesystem-agent-same-convention" = "NOT_RUN"
  "agent-different-skill-convention" = "NOT_APPLICABLE"
}

foreach ($id in $expected.Keys) {
  if (-not $byId.ContainsKey($id)) {
    $errors.Add("Missing compatibility environment: $id")
    continue
  }
  if ([string]$byId[$id].tested_execution -ne [string]$expected[$id]) {
    $errors.Add("${id}: tested_execution must be '$($expected[$id])'")
  }
}

if ($byId.ContainsKey("agent-different-skill-convention") -and
    [string]$byId["agent-different-skill-convention"].format -ne "ADAPTATION_REQUIRED") {
  $errors.Add("Different-convention agent must remain ADAPTATION_REQUIRED")
}

foreach ($marker in @(
  "Format",
  "Architecture",
  "Tested execution",
  "Windows + PowerShell",
  "Ubuntu Linux + PowerShell",
  "macOS + PowerShell",
  "NOT RUN",
  "ADAPTATION_REQUIRED",
  "36667646038"
)) {
  if (-not $doc.Contains($marker)) {
    $errors.Add("COMPATIBILITY.md missing marker: $marker")
  }
}

foreach ($runner in @("windows-latest","ubuntu-latest")) {
  if (-not $workflow.Contains($runner)) {
    $errors.Add("Workflow no longer contains tested runner: $runner")
  }
}
if ($workflow.Contains("macos-latest")) {
  $errors.Add("macOS runner exists but compatibility matrix still marks macOS NOT_RUN; update evidence deliberately")
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] compatibility claims match evidence and CI matrix"
}
Write-Output ("COMPAT ENVIRONMENTS={0} FAIL={1}" -f $byId.Count,$errors.Count)

if ($errors.Count -gt 0) { exit 1 }
exit 0

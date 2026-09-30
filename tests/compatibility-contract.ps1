param(
  [string]$MatrixPath = "$PSScriptRoot\..\evidence\compatibility\2026-09-30.json",
  [string]$CompatibilityPath = "$PSScriptRoot\..\COMPATIBILITY.md",
  [string]$WorkflowPath = "$PSScriptRoot\..\.github\workflows\validate.yml"
)

$ErrorActionPreference = "Stop"

function Get-StringArray {
  param([object]$Value)
  if ($null -eq $Value) { return @() }
  return @($Value | ForEach-Object { [string]$_ })
}

function Assert-Environment {
  param(
    [Parameter(Mandatory = $true)][hashtable]$ById,
    [Parameter(Mandatory = $true)][string]$Id,
    [Parameter(Mandatory = $true)][string]$Format,
    [Parameter(Mandatory = $true)][string]$Architecture,
    [Parameter(Mandatory = $true)][string]$TestedExecution,
    [Parameter(Mandatory = $true)][string]$RuntimeLoading,
    [Parameter(Mandatory = $true)][System.Collections.Generic.List[string]]$Errors
  )

  if (-not $ById.ContainsKey($Id)) {
    $Errors.Add("Missing compatibility environment: $Id")
    return
  }

  $item = $ById[$Id]
  $expected = @{
    format = $Format
    architecture = $Architecture
    tested_execution = $TestedExecution
    runtime_loading = $RuntimeLoading
  }

  foreach ($field in $expected.Keys) {
    if ([string]$item.$field -ne [string]$expected[$field]) {
      $Errors.Add("${Id}: $field must be '$($expected[$field])'")
    }
  }

  if ([string]::IsNullOrWhiteSpace([string]$item.evidence)) {
    $Errors.Add("${Id}: evidence text is required")
  }
  if ([string]::IsNullOrWhiteSpace([string]$item.claim_limit)) {
    $Errors.Add("${Id}: claim_limit is required")
  }
}

foreach ($path in @($MatrixPath,$CompatibilityPath,$WorkflowPath)) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing compatibility input: $path"
  }
}

$matrix = Get-Content -LiteralPath $MatrixPath -Raw | ConvertFrom-Json
$doc = Get-Content -LiteralPath $CompatibilityPath -Raw
$workflow = Get-Content -LiteralPath $WorkflowPath -Raw
$errors = New-Object System.Collections.Generic.List[string]

if ([int]$matrix.schema_version -ne 2) {
  $errors.Add("Unsupported compatibility schema_version '$($matrix.schema_version)'; expected 2")
}

if ([string]$matrix.verified_on -ne "2026-09-30") {
  $errors.Add("Compatibility verified_on must remain 2026-09-30 for this evidence snapshot")
}

$basis = $matrix.evidence_basis
if ([string]$basis.repository_commit -ne "7a361791aa310fc3cf0e54e9a5a5a499abb9b3d8") {
  $errors.Add("Compatibility evidence repository_commit must reference the Phase 11 re-audit merge")
}
if ([int]$basis.pull_request -ne 26) {
  $errors.Add("Compatibility evidence pull_request must be 26")
}
if ([int64]$basis.pull_request_ci_run -ne 36686190812) {
  $errors.Add("Compatibility evidence pull_request_ci_run must be 36686190812")
}
if ([string]$basis.scope -ne "repository_tooling") {
  $errors.Add("Compatibility evidence scope must be repository_tooling")
}
if ([string]::IsNullOrWhiteSpace([string]$basis.note)) {
  $errors.Add("Compatibility evidence note is required")
}

$requiredNonClaims = @(
  "automatic SKILL.md discovery or loading by a third-party agent runtime",
  "macOS executable support",
  "support for arbitrary Linux distributions or self-hosted runners",
  "identical behavior for runtimes with different frontmatter, packaging, routing, or discovery conventions"
)
$actualNonClaims = Get-StringArray $basis.does_not_prove
foreach ($claim in $requiredNonClaims) {
  if ($actualNonClaims -notcontains $claim) {
    $errors.Add("Compatibility evidence does_not_prove missing: $claim")
  }
}

foreach ($runnerKey in @("windows","ubuntu")) {
  $runner = $basis.runners.$runnerKey
  if ($null -eq $runner) {
    $errors.Add("Compatibility evidence missing runner snapshot: $runnerKey")
    continue
  }

  $expectedRunner = if ($runnerKey -eq "windows") { "windows-latest" } else { "ubuntu-latest" }
  $expectedOs = if ($runnerKey -eq "windows") { "Windows" } else { "Linux" }

  if ([string]$runner.matrix_runner -ne $expectedRunner) {
    $errors.Add("${runnerKey}: matrix_runner must be '$expectedRunner'")
  }
  if ([string]$runner.runner_os -ne $expectedOs) {
    $errors.Add("${runnerKey}: runner_os must be '$expectedOs'")
  }
  if ([string]$runner.powershell_edition -ne "Core") {
    $errors.Add("${runnerKey}: powershell_edition must be Core")
  }
  if ([string]$runner.observed_powershell_version -ne "7.6.6") {
    $errors.Add("${runnerKey}: observed_powershell_version must preserve the recorded 7.6.6 evidence")
  }
  if ([string]$runner.job_conclusion -ne "success") {
    $errors.Add("${runnerKey}: job_conclusion must be success")
  }
}

foreach ($dimension in @("format","architecture","tested_execution","runtime_loading")) {
  if ($null -eq $matrix.dimensions.PSObject.Properties[$dimension] -or
      [string]::IsNullOrWhiteSpace([string]$matrix.dimensions.$dimension)) {
    $errors.Add("Compatibility dimension '$dimension' is missing or empty")
  }
}

$byId = @{}
foreach ($envItem in @($matrix.environments)) {
  $id = [string]$envItem.id
  if ([string]::IsNullOrWhiteSpace($id)) {
    $errors.Add("Compatibility environment has empty id")
    continue
  }
  if ($byId.ContainsKey($id)) {
    $errors.Add("Duplicate compatibility environment id: $id")
    continue
  }
  $byId[$id] = $envItem
}

if ($byId.Count -ne 5) {
  $errors.Add("Compatibility matrix must contain exactly 5 environment rows; observed $($byId.Count)")
}

Assert-Environment -ById $byId -Id "windows-github-hosted-pwsh-tooling" -Format "COMPATIBLE_BY_FORMAT" -Architecture "COMPATIBLE_BY_DESIGN" -TestedExecution "TESTED" -RuntimeLoading "NOT_RUN" -Errors $errors
Assert-Environment -ById $byId -Id "ubuntu-github-hosted-pwsh-tooling" -Format "COMPATIBLE_BY_FORMAT" -Architecture "COMPATIBLE_BY_DESIGN" -TestedExecution "TESTED" -RuntimeLoading "NOT_RUN" -Errors $errors
Assert-Environment -ById $byId -Id "macos-pwsh-filesystem-skills" -Format "COMPATIBLE_BY_FORMAT" -Architecture "COMPATIBLE_BY_DESIGN" -TestedExecution "NOT_RUN" -RuntimeLoading "NOT_RUN" -Errors $errors
Assert-Environment -ById $byId -Id "other-filesystem-agent-same-convention" -Format "LIKELY_COMPATIBLE" -Architecture "COMPATIBLE_BY_DESIGN" -TestedExecution "NOT_RUN" -RuntimeLoading "NOT_RUN" -Errors $errors
Assert-Environment -ById $byId -Id "agent-different-skill-convention" -Format "ADAPTATION_REQUIRED" -Architecture "ADAPTABLE" -TestedExecution "NOT_APPLICABLE" -RuntimeLoading "NOT_APPLICABLE" -Errors $errors

foreach ($id in @("windows-github-hosted-pwsh-tooling","ubuntu-github-hosted-pwsh-tooling")) {
  if ($byId.ContainsKey($id)) {
    if ([string]$byId[$id].runtime_loading -eq "TESTED") {
      $errors.Add("${id}: repository tooling CI must not be relabeled as runtime-loading evidence")
    }
    if ([string]$byId[$id].evidence -notmatch "36686190812") {
      $errors.Add("${id}: evidence must reference current Phase 11 CI run 36686190812")
    }
    if ([string]$byId[$id].evidence -notmatch "PowerShell=7\.6\.6") {
      $errors.Add("${id}: evidence must preserve observed PowerShell 7.6.6 runtime")
    }
  }
}

if ($workflow -notmatch "(?m)^\s*os:\s*\[windows-latest,\s*ubuntu-latest\]\s*$") {
  $errors.Add("Workflow no longer has the exact Windows + Ubuntu tested-execution matrix")
}
if ($workflow -match "macos-latest") {
  $errors.Add("macOS runner exists while compatibility evidence still marks macOS tested execution NOT_RUN")
}
if ($workflow -notmatch 'CI requires PowerShell Core \(pwsh\)') {
  $errors.Add("Workflow no longer asserts PowerShell Core runtime")
}
if ($workflow -notmatch 'CI requires PowerShell 7\+') {
  $errors.Add("Workflow no longer asserts PowerShell 7+")
}
if ($workflow -notmatch 'CI_RUNTIME OS=') {
  $errors.Add("Workflow no longer emits runtime evidence")
}

$tick = [char]0x60
$docMarkers = @(
  "Format",
  "Architecture",
  "Tested execution",
  "Runtime loading",
  "GitHub-hosted Windows + PowerShell Core repository tooling",
  "GitHub-hosted Ubuntu + PowerShell Core repository tooling",
  "macOS tested execution: NOT RUN",
  "macOS runtime loading: NOT RUN",
  "36686190812",
  "7a361791aa310fc3cf0e54e9a5a5a499abb9b3d8",
  ("PowerShell " + $tick + "7.6.6" + $tick),
  "PowerShell Core 7+",
  "does not launch a Codex runtime",
  "not a blanket claim",
  "NOT_APPLICABLE"
)
foreach ($marker in $docMarkers) {
  if (-not $doc.Contains($marker)) {
    $errors.Add("COMPATIBILITY.md missing marker: $marker")
  }
}

$expectedRows = @(
  "| GitHub-hosted Windows + PowerShell Core repository tooling | COMPATIBLE_BY_FORMAT | COMPATIBLE_BY_DESIGN | **TESTED** | **NOT RUN** |",
  "| GitHub-hosted Ubuntu + PowerShell Core repository tooling | COMPATIBLE_BY_FORMAT | COMPATIBLE_BY_DESIGN | **TESTED** | **NOT RUN** |",
  ("| macOS + PowerShell + filesystem " + $tick + "SKILL.md" + $tick + " convention | COMPATIBLE_BY_FORMAT | COMPATIBLE_BY_DESIGN | **NOT RUN** | **NOT RUN** |"),
  "| Other agent using a compatible filesystem skill convention | LIKELY_COMPATIBLE | COMPATIBLE_BY_DESIGN | **NOT RUN** | **NOT RUN** |",
  "| Agent requiring different frontmatter/index/packaging/discovery/routing conventions | ADAPTATION_REQUIRED | ADAPTABLE | NOT_APPLICABLE | NOT_APPLICABLE |"
)
foreach ($row in $expectedRows) {
  if (-not $doc.Contains($row)) {
    $errors.Add("COMPATIBILITY.md matrix row drifted: $row")
  }
}

$staleMarkers = @(
  "36667646038",
  "PR #12 run",
  ("Windows + PowerShell + filesystem " + $tick + "SKILL.md" + $tick + " loading"),
  ("Ubuntu Linux + PowerShell + filesystem " + $tick + "SKILL.md" + $tick + " loading")
)
foreach ($staleMarker in $staleMarkers) {
  if ($doc.Contains($staleMarker)) {
    $errors.Add("COMPATIBILITY.md contains stale/ambiguous compatibility marker: $staleMarker")
  }
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] compatibility dimensions, evidence snapshot, workflow, and documentation are aligned"
}
Write-Output ("COMPATIBILITY_CONTRACT ENVIRONMENTS={0} FAIL={1} EVIDENCE_RUN={2}" -f $byId.Count,$errors.Count,[int64]$basis.pull_request_ci_run)

if ($errors.Count -gt 0) { exit 1 }
exit 0

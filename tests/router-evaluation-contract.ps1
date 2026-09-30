$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$evaluator = Join-Path $repoRoot "tests/router-evaluation.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-router-contract-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  New-Item -ItemType Directory -Path $root -Force | Out-Null

  $registryPath = Join-Path $root "REGISTRY.json"
  $casesPath = Join-Path $root "router-cases.json"
  $resultsPath = Join-Path $root "router-results.json"

  [ordered]@{
    schema_version = 2
    suite = "router-contract"
    version = "0"
    skills = @(
      [ordered]@{ name = "skill-a"; kind = "generic"; path = "skills/skill-a"; status = "stable"; evidence_tier = "none"; evidence_refs = @(); tags = @() },
      [ordered]@{ name = "skill-b"; kind = "generic"; path = "skills/skill-b"; status = "stable"; evidence_tier = "none"; evidence_refs = @(); tags = @() },
      [ordered]@{ name = "project-router"; kind = "project"; path = "skills/project-router"; status = "project"; evidence_tier = "none"; evidence_refs = @(); tags = @() }
    )
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $registryPath -Encoding utf8NoBOM

  Write-Cases -Path $casesPath -Cases @(
    (New-Case)
  )
  Write-Selections -Path $resultsPath -Selections @(
    (New-Selection)
  )

  return @{
    Root = $root
    RegistryPath = $registryPath
    CasesPath = $casesPath
    ResultsPath = $resultsPath
  }
}

function New-Case {
  param(
    [string]$Id = "case-a",
    [string]$Scope = "generic",
    [string[]]$Required = @("skill-a"),
    [string[]]$Allowed = @("skill-a"),
    [string[]]$Forbidden = @("project-router"),
    [int]$MaxSelected = 1
  )

  return [ordered]@{
    id = $Id
    task = "Bounded router contract fixture."
    scope = $Scope
    selection_mode = "exact_required"
    required = @($Required)
    allowed = @($Allowed)
    forbidden = @($Forbidden)
    max_selected = $MaxSelected
  }
}

function New-Selection {
  param(
    [string]$CaseId = "case-a",
    [string[]]$Selected = @("skill-a")
  )

  return [ordered]@{
    case_id = $CaseId
    selected = @($Selected)
  }
}

function Write-Cases {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Cases,
    [int]$SchemaVersion = 2
  )

  [ordered]@{
    schema_version = $SchemaVersion
    cases = @($Cases)
  } | ConvertTo-Json -Depth 15 | Set-Content -Path $Path -Encoding utf8NoBOM
}

function Write-Selections {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Selections,
    [int]$SchemaVersion = 2,
    [string]$EvaluationType = "documented_router_contract",
    [string]$RuntimeObedience = "NOT_RUN",
    [switch]$AddRuntimeField
  )

  $doc = [ordered]@{
    schema_version = $SchemaVersion
    evaluation_type = $EvaluationType
    runtime_obedience = $RuntimeObedience
    claim_limit = "Static fixture only; no runtime obedience claim."
    selections = @($Selections)
  }

  if ($AddRuntimeField) {
    $doc["model"] = "fake-runtime-model"
  }

  $doc | ConvertTo-Json -Depth 15 | Set-Content -Path $Path -Encoding utf8NoBOM
}

function Invoke-Evaluator {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)

  $output = & pwsh -NoProfile -File $evaluator `
    -CasesPath $Sandbox.CasesPath `
    -ResultsPath $Sandbox.ResultsPath `
    -RegistryPath $Sandbox.RegistryPath `
    -MinimumCases 1 2>&1

  return @{
    ExitCode = $LASTEXITCODE
    Text = (($output | ForEach-Object { [string]$_ }) -join "`n")
  }
}

function Assert-Passes {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )

  $result = Invoke-Evaluator -Sandbox $Sandbox
  if ($result.ExitCode -ne 0) {
    throw "Expected router evaluator to pass. Output: $($result.Text)"
  }
  if ($result.Text -notmatch [regex]::Escape($ExpectedText)) {
    throw "Router evaluator passed without '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] $ExpectedText"
}

function Assert-Rejected {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )

  $result = Invoke-Evaluator -Sandbox $Sandbox
  if ($result.ExitCode -eq 0) {
    throw "Expected router evaluator rejection containing '$ExpectedText'. Output: $($result.Text)"
  }
  if ($result.Text -notmatch [regex]::Escape($ExpectedText)) {
    throw "Router evaluator rejected for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $validGeneric = New-Sandbox -Name "valid-generic"
  Assert-Passes -Sandbox $validGeneric -ExpectedText "[PASS] case-a [generic] -> skill-a"

  $validUnrelated = New-Sandbox -Name "valid-unrelated"
  Write-Cases -Path $validUnrelated.CasesPath -Cases @(
    (New-Case -Scope "unrelated" -Required @() -Allowed @() -Forbidden @("skill-a","skill-b","project-router") -MaxSelected 0)
  )
  Write-Selections -Path $validUnrelated.ResultsPath -Selections @(
    (New-Selection -Selected @())
  )
  Assert-Passes -Sandbox $validUnrelated -ExpectedText "[PASS] case-a [unrelated] -> <none>"

  $validProject = New-Sandbox -Name "valid-project"
  Write-Cases -Path $validProject.CasesPath -Cases @(
    (New-Case -Scope "project" -Required @("project-router","skill-a") -Allowed @("project-router","skill-a") -Forbidden @("skill-b") -MaxSelected 2)
  )
  Write-Selections -Path $validProject.ResultsPath -Selections @(
    (New-Selection -Selected @("project-router","skill-a"))
  )
  Assert-Passes -Sandbox $validProject -ExpectedText "[PASS] case-a [project] ->"

  $missingProjectForbid = New-Sandbox -Name "missing-project-forbid"
  Write-Cases -Path $missingProjectForbid.CasesPath -Cases @(
    (New-Case -Forbidden @())
  )
  Assert-Rejected -Sandbox $missingProjectForbid -ExpectedText "generic case must explicitly forbid project skill 'project-router'"

  $requiredNotAllowed = New-Sandbox -Name "required-not-allowed"
  Write-Cases -Path $requiredNotAllowed.CasesPath -Cases @(
    (New-Case -Required @("skill-a") -Allowed @("skill-b"))
  )
  Assert-Rejected -Sandbox $requiredNotAllowed -ExpectedText "required skill is not allowed -> skill-a"

  $overlap = New-Sandbox -Name "allowed-forbidden-overlap"
  Write-Cases -Path $overlap.CasesPath -Cases @(
    (New-Case -Allowed @("skill-a","skill-b") -Forbidden @("skill-b","project-router"))
  )
  Assert-Rejected -Sandbox $overlap -ExpectedText "allowed skill is also forbidden -> skill-b"

  $unknownSkill = New-Sandbox -Name "unknown-skill"
  Write-Cases -Path $unknownSkill.CasesPath -Cases @(
    (New-Case -Required @("missing-skill") -Allowed @("missing-skill") -Forbidden @("project-router"))
  )
  Assert-Rejected -Sandbox $unknownSkill -ExpectedText "required references unregistered skill 'missing-skill'"

  $ambiguousAllowed = New-Sandbox -Name "ambiguous-allowed"
  Write-Cases -Path $ambiguousAllowed.CasesPath -Cases @(
    (New-Case -Required @("skill-a") -Allowed @("skill-a","skill-b") -Forbidden @("project-router") -MaxSelected 1)
  )
  Assert-Rejected -Sandbox $ambiguousAllowed -ExpectedText "exact_required allowed set must exactly match required skills"

  $nonMinimal = New-Sandbox -Name "non-minimal-selection"
  Write-Selections -Path $nonMinimal.ResultsPath -Selections @(
    (New-Selection -Selected @("skill-b"))
  )
  Assert-Rejected -Sandbox $nonMinimal -ExpectedText "exact_required selection must exactly match required skills"

  $unrelatedIncomplete = New-Sandbox -Name "unrelated-incomplete-forbid"
  Write-Cases -Path $unrelatedIncomplete.CasesPath -Cases @(
    (New-Case -Scope "unrelated" -Required @() -Allowed @() -Forbidden @("project-router") -MaxSelected 0)
  )
  Write-Selections -Path $unrelatedIncomplete.ResultsPath -Selections @(
    (New-Selection -Selected @())
  )
  Assert-Rejected -Sandbox $unrelatedIncomplete -ExpectedText "unrelated case must forbid every registered skill"

  $runtimeClaim = New-Sandbox -Name "runtime-claim"
  Write-Selections -Path $runtimeClaim.ResultsPath -Selections @(
    (New-Selection)
  ) -RuntimeObedience "COMPLETED"
  Assert-Rejected -Sandbox $runtimeClaim -ExpectedText "runtime_obedience must remain NOT_RUN"

  $runtimeField = New-Sandbox -Name "runtime-field"
  Write-Selections -Path $runtimeField.ResultsPath -Selections @(
    (New-Selection)
  ) -AddRuntimeField
  Assert-Rejected -Sandbox $runtimeField -ExpectedText "must not contain runtime field 'model'"

  $duplicateSelection = New-Sandbox -Name "duplicate-selection"
  Write-Selections -Path $duplicateSelection.ResultsPath -Selections @(
    (New-Selection),
    (New-Selection)
  )
  Assert-Rejected -Sandbox $duplicateSelection -ExpectedText "Duplicate router selection case_id: case-a"

  $missingSelection = New-Sandbox -Name "missing-selection"
  Write-Selections -Path $missingSelection.ResultsPath -Selections @()
  Assert-Rejected -Sandbox $missingSelection -ExpectedText "Missing router selection for case: case-a"

  $oldSchema = New-Sandbox -Name "old-schema"
  Write-Cases -Path $oldSchema.CasesPath -Cases @(
    (New-Case)
  ) -SchemaVersion 1
  Assert-Rejected -Sandbox $oldSchema -ExpectedText "Unsupported router case schema_version '1'; expected 2"

  Write-Output "[PASS] router selection contract is regression-covered"
} finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

exit 0

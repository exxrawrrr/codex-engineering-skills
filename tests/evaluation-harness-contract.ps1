$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$harness = Join-Path $repoRoot "tests/evaluation-harness.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-eval-contract-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  $resultsRoot = Join-Path $root "results"
  New-Item -ItemType Directory -Path $resultsRoot -Force | Out-Null

  $registryPath = Join-Path $root "REGISTRY.json"
  $casesPath = Join-Path $root "cases.json"
  $fixturesPath = Join-Path $root "fixtures.json"

  [ordered]@{
    schema_version = 2
    suite = "eval-contract"
    version = "0"
    skills = @(
      [ordered]@{
        name = "skill-a"
        kind = "generic"
        path = "skills/skill-a"
        tags = @("fixture")
        status = "stable"
        evidence_tier = "none"
        evidence_refs = @()
      },
      [ordered]@{
        name = "skill-b"
        kind = "generic"
        path = "skills/skill-b"
        tags = @("fixture")
        status = "stable"
        evidence_tier = "none"
        evidence_refs = @()
      }
    )
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $registryPath -Encoding utf8NoBOM

  [ordered]@{
    schema_version = 2
    cases = @(
      [ordered]@{
        id = "case-1"
        task = "Perform the bounded fixture task."
        fixture_id = "fixture-1"
        allowed_variants = @("no_skills","selected_skills","all_generic_skills")
        recommended_skills = @("skill-a")
        acceptance_criteria = @(
          [ordered]@{ id = "criterion-a"; description = "Criterion A is checked." },
          [ordered]@{ id = "criterion-b"; description = "Criterion B is checked." }
        )
      }
    )
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $casesPath -Encoding utf8NoBOM

  [ordered]@{
    schema_version = 1
    fixtures = @(
      [ordered]@{
        id = "fixture-1"
        case_id = "case-1"
        description = "Bounded deterministic fixture."
        initial_state = [ordered]@{ input = "fixed" }
        constraints = @("Keep the fixture bounded.")
      }
    )
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $fixturesPath -Encoding utf8NoBOM

  return @{
    Root = $root
    ResultsRoot = $resultsRoot
    RegistryPath = $registryPath
    CasesPath = $casesPath
    FixturesPath = $fixturesPath
  }
}

function Write-Results {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][object[]]$Results,
    [int]$SchemaVersion = 2
  )

  [ordered]@{
    schema_version = $SchemaVersion
    results = @($Results)
  } | ConvertTo-Json -Depth 15 | Set-Content -Path $Path -Encoding utf8NoBOM
}

function New-NotRunResult {
  return [ordered]@{
    case_id = "case-1"
    variant = "selected_skills"
    execution_status = "NOT_RUN"
    skills_loaded = @()
    criteria = [ordered]@{}
    evidence = [ordered]@{}
    notes = "Deliberately not executed."
  }
}

function New-CompletedResult {
  param(
    [string]$Variant = "selected_skills",
    [string[]]$SkillsLoaded = @("skill-a"),
    [bool]$CriterionA = $true,
    [bool]$CriterionB = $true,
    [switch]$OmitExecution,
    [switch]$AddExtraCriterion
  )

  $criteria = [ordered]@{
    "criterion-a" = $CriterionA
    "criterion-b" = $CriterionB
  }
  $evidence = [ordered]@{
    "criterion-a" = "artifact:a"
    "criterion-b" = "artifact:b"
  }
  if ($AddExtraCriterion) {
    $criteria["stale-extra"] = $true
    $evidence["stale-extra"] = "artifact:stale"
  }

  $result = [ordered]@{
    case_id = "case-1"
    variant = $Variant
    execution_status = "COMPLETED"
    skills_loaded = @($SkillsLoaded)
    criteria = $criteria
    evidence = $evidence
    notes = "Completed fixture execution."
  }
  if (-not $OmitExecution) {
    $result["execution"] = [ordered]@{
      run_id = "run-1"
      executed_at = "2026-09-30T12:00:00+07:00"
      runtime = "fixture-runtime"
      model = "fixture-model"
      repository = "fixture/repo"
      repository_ref = "deadbeef"
    }
  }
  return $result
}

function Invoke-Harness {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)

  $output = & pwsh -NoProfile -File $harness `
    -CasesPath $Sandbox.CasesPath `
    -FixturesPath $Sandbox.FixturesPath `
    -ResultsRoot $Sandbox.ResultsRoot `
    -RegistryPath $Sandbox.RegistryPath 2>&1

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

  $result = Invoke-Harness -Sandbox $Sandbox
  if ($result.ExitCode -ne 0) {
    throw "Expected harness to pass. Output: $($result.Text)"
  }
  if ($result.Text -notmatch [regex]::Escape($ExpectedText)) {
    throw "Harness passed without expected output '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] $ExpectedText"
}

function Assert-Rejected {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )

  $result = Invoke-Harness -Sandbox $Sandbox
  if ($result.ExitCode -eq 0) {
    throw "Expected harness rejection containing '$ExpectedText'. Output: $($result.Text)"
  }
  if ($result.Text -notmatch [regex]::Escape($ExpectedText)) {
    throw "Harness rejected for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $validNotRun = New-Sandbox -Name "valid-not-run"
  Write-Results -Path (Join-Path $validNotRun.ResultsRoot "result.json") -Results @((New-NotRunResult))
  Assert-Passes -Sandbox $validNotRun -ExpectedText "[NOT RUN] case-1 / selected_skills"

  $notRunEvidence = New-Sandbox -Name "not-run-evidence"
  $notRunWithEvidence = New-NotRunResult
  $notRunWithEvidence.evidence = [ordered]@{ "criterion-a" = "fake evidence" }
  Write-Results -Path (Join-Path $notRunEvidence.ResultsRoot "result.json") -Results @($notRunWithEvidence)
  Assert-Rejected -Sandbox $notRunEvidence -ExpectedText "must have empty evidence"

  $validCompleted = New-Sandbox -Name "valid-completed"
  Write-Results -Path (Join-Path $validCompleted.ResultsRoot "result.json") -Results @((New-CompletedResult))
  Assert-Passes -Sandbox $validCompleted -ExpectedText "[PASS] case-1 / selected_skills"

  $validNoSkills = New-Sandbox -Name "valid-no-skills"
  Write-Results -Path (Join-Path $validNoSkills.ResultsRoot "result.json") -Results @(
    (New-CompletedResult -Variant "no_skills" -SkillsLoaded @())
  )
  Assert-Passes -Sandbox $validNoSkills -ExpectedText "[PASS] case-1 / no_skills"

  $failedOutcome = New-Sandbox -Name "failed-outcome"
  Write-Results -Path (Join-Path $failedOutcome.ResultsRoot "result.json") -Results @(
    (New-CompletedResult -CriterionB $false)
  )
  Assert-Passes -Sandbox $failedOutcome -ExpectedText "[FAIL] case-1 / selected_skills"

  $wrongTreatment = New-Sandbox -Name "wrong-treatment"
  Write-Results -Path (Join-Path $wrongTreatment.ResultsRoot "result.json") -Results @(
    (New-CompletedResult -SkillsLoaded @("skill-b"))
  )
  Assert-Rejected -Sandbox $wrongTreatment -ExpectedText "skills_loaded does not match 'selected_skills' treatment"

  $missingExecution = New-Sandbox -Name "missing-execution"
  Write-Results -Path (Join-Path $missingExecution.ResultsRoot "result.json") -Results @(
    (New-CompletedResult -OmitExecution)
  )
  Assert-Rejected -Sandbox $missingExecution -ExpectedText "requires execution provenance object"

  $extraCriterion = New-Sandbox -Name "extra-criterion"
  Write-Results -Path (Join-Path $extraCriterion.ResultsRoot "result.json") -Results @(
    (New-CompletedResult -AddExtraCriterion)
  )
  Assert-Rejected -Sandbox $extraCriterion -ExpectedText "criteria keys must exactly match case criteria"

  $duplicateResults = New-Sandbox -Name "duplicate-results"
  Write-Results -Path (Join-Path $duplicateResults.ResultsRoot "a.json") -Results @((New-NotRunResult))
  Write-Results -Path (Join-Path $duplicateResults.ResultsRoot "b.json") -Results @((New-NotRunResult))
  Assert-Rejected -Sandbox $duplicateResults -ExpectedText "duplicate result for 'case-1/selected_skills'"

  $oldResultSchema = New-Sandbox -Name "old-result-schema"
  Write-Results -Path (Join-Path $oldResultSchema.ResultsRoot "result.json") -Results @((New-NotRunResult)) -SchemaVersion 1
  Assert-Rejected -Sandbox $oldResultSchema -ExpectedText "unsupported result schema_version '1'; expected 2"

  $unknownRecommendedSkill = New-Sandbox -Name "unknown-recommended"
  $caseDoc = Get-Content $unknownRecommendedSkill.CasesPath -Raw | ConvertFrom-Json
  $caseDoc.cases[0].recommended_skills = @("missing-skill")
  $caseDoc | ConvertTo-Json -Depth 15 | Set-Content -Path $unknownRecommendedSkill.CasesPath -Encoding utf8NoBOM
  Write-Results -Path (Join-Path $unknownRecommendedSkill.ResultsRoot "result.json") -Results @((New-NotRunResult))
  Assert-Rejected -Sandbox $unknownRecommendedSkill -ExpectedText "unknown recommended skill 'missing-skill'"

  $duplicateCriterion = New-Sandbox -Name "duplicate-criterion"
  $duplicateCaseDoc = Get-Content $duplicateCriterion.CasesPath -Raw | ConvertFrom-Json
  $duplicateCaseDoc.cases[0].acceptance_criteria = @(
    [ordered]@{ id = "criterion-a"; description = "First." },
    [ordered]@{ id = "criterion-a"; description = "Duplicate." }
  )
  $duplicateCaseDoc | ConvertTo-Json -Depth 15 | Set-Content -Path $duplicateCriterion.CasesPath -Encoding utf8NoBOM
  Write-Results -Path (Join-Path $duplicateCriterion.ResultsRoot "result.json") -Results @((New-NotRunResult))
  Assert-Rejected -Sandbox $duplicateCriterion -ExpectedText "duplicate criterion id 'criterion-a'"

  $fixtureMismatch = New-Sandbox -Name "fixture-mismatch"
  $fixtureDoc = Get-Content $fixtureMismatch.FixturesPath -Raw | ConvertFrom-Json
  $fixtureDoc.fixtures[0].case_id = "some-other-case"
  $fixtureDoc | ConvertTo-Json -Depth 15 | Set-Content -Path $fixtureMismatch.FixturesPath -Encoding utf8NoBOM
  Write-Results -Path (Join-Path $fixtureMismatch.ResultsRoot "result.json") -Results @((New-NotRunResult))
  Assert-Rejected -Sandbox $fixtureMismatch -ExpectedText "belongs to case 'some-other-case', not 'case-1'"

  $emptyCorpus = New-Sandbox -Name "empty-corpus"
  Write-Results -Path (Join-Path $emptyCorpus.ResultsRoot "result.json") -Results @()
  Assert-Rejected -Sandbox $emptyCorpus -ExpectedText "Evaluation corpus contains no result records"

  $missingSkillsLoaded = New-Sandbox -Name "missing-skills-loaded"
  $missingSkillsResult = New-NotRunResult
  $missingSkillsResult.Remove("skills_loaded")
  Write-Results -Path (Join-Path $missingSkillsLoaded.ResultsRoot "result.json") -Results @($missingSkillsResult)
  Assert-Rejected -Sandbox $missingSkillsLoaded -ExpectedText "skills_loaded is required"

  Write-Output "[PASS] behavioral evaluation harness contract is regression-covered"
} finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

exit 0

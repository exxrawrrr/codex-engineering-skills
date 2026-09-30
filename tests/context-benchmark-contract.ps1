$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$benchmark = Join-Path $repoRoot "tests/context-benchmark.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-context-contract-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  $skillsRoot = Join-Path $root "skills"
  New-Item -ItemType Directory -Path $skillsRoot -Force | Out-Null

  foreach ($skill in @(
    @{ name = "skill-a"; kind = "generic"; body = "alpha" },
    @{ name = "skill-b"; kind = "generic"; body = "bravo-charlie" },
    @{ name = "project-router"; kind = "project"; body = "project-only-content" }
  )) {
    $dir = Join-Path $skillsRoot $skill.name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $dir "SKILL.md"), [string]$skill.body, [System.Text.UTF8Encoding]::new($false))
  }

  $registryPath = Join-Path $root "REGISTRY.json"
  [ordered]@{
    schema_version = 2
    suite = "context-contract"
    version = "0"
    skills = @(
      [ordered]@{ name = "skill-a"; kind = "generic"; path = "skills/skill-a"; status = "stable"; evidence_tier = "none"; evidence_refs = @(); tags = @() },
      [ordered]@{ name = "skill-b"; kind = "generic"; path = "skills/skill-b"; status = "stable"; evidence_tier = "none"; evidence_refs = @(); tags = @() },
      [ordered]@{ name = "project-router"; kind = "project"; path = "skills/project-router"; status = "project"; evidence_tier = "none"; evidence_refs = @(); tags = @() }
    )
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $registryPath -Encoding utf8NoBOM

  $casesPath = Join-Path $root "cases.json"
  [ordered]@{
    schema_version = 2
    cases = @(
      [ordered]@{
        id = "case-a"
        task = "fixture"
        fixture_id = "fixture-a"
        allowed_variants = @("no_skills","selected_skills","all_generic_skills")
        recommended_skills = @("skill-a")
        acceptance_criteria = @([ordered]@{ id = "criterion"; description = "fixture" })
      }
    )
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $casesPath -Encoding utf8NoBOM

  $expectedPath = Join-Path $root "context-current.json"
  [ordered]@{
    schema_version = 2
    evaluation_type = "context_cost"
    measurement = "UTF-8 byte size of SKILL.md entrypoints only; references are excluded because they are conditionally loaded."
    treatment_contract = [ordered]@{
      no_skills = "none"
      selected_skills = "selected"
      all_generic_skills = "generic only"
    }
    all_generic_skill_names = @("skill-a","skill-b")
    all_generic_entrypoint_bytes = 18
    comparisons = @(
      [ordered]@{
        case_id = "case-a"
        no_skills_bytes = 0
        selected_skills_bytes = 5
        all_generic_skills_bytes = 18
        selected_skills = @("skill-a")
        selected_skill_count = 1
        generic_skill_count = 2
      }
    )
    runtime_metrics = [ordered]@{
      input_tokens = "NOT_AVAILABLE"
      tool_calls = "NOT_RUN"
      elapsed_ms = "NOT_RUN"
    }
    behavioral_quality = "NOT_RUN"
    claim_limit = "Fixture claim limit."
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $expectedPath -Encoding utf8NoBOM

  return @{
    Root = $root
    SkillsRoot = $skillsRoot
    RegistryPath = $registryPath
    CasesPath = $casesPath
    ExpectedPath = $expectedPath
  }
}

function Invoke-Benchmark {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)

  $output = & pwsh -NoProfile -File $benchmark `
    -RegistryPath $Sandbox.RegistryPath `
    -CasesPath $Sandbox.CasesPath `
    -SkillsRoot $Sandbox.SkillsRoot `
    -ExpectedPath $Sandbox.ExpectedPath 2>&1

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

  $result = Invoke-Benchmark -Sandbox $Sandbox
  if ($result.ExitCode -ne 0) {
    throw "Expected context benchmark to pass. Output: $($result.Text)"
  }
  if ($result.Text -notmatch [regex]::Escape($ExpectedText)) {
    throw "Context benchmark passed without '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] $ExpectedText"
}

function Assert-Rejected {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )

  $result = Invoke-Benchmark -Sandbox $Sandbox
  if ($result.ExitCode -eq 0) {
    throw "Expected context benchmark rejection containing '$ExpectedText'. Output: $($result.Text)"
  }
  if ($result.Text -notmatch [regex]::Escape($ExpectedText)) {
    throw "Context benchmark rejected for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $valid = New-Sandbox -Name "valid"
  Assert-Passes -Sandbox $valid -ExpectedText "GENERIC_SKILLS=2 ALL_GENERIC_BYTES=18"

  $staleBytes = New-Sandbox -Name "stale-bytes"
  $doc = Get-Content $staleBytes.ExpectedPath -Raw | ConvertFrom-Json
  $doc.all_generic_entrypoint_bytes = 999
  $doc | ConvertTo-Json -Depth 12 | Set-Content -Path $staleBytes.ExpectedPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $staleBytes -ExpectedText "all_generic_entrypoint_bytes is stale"

  $projectLeak = New-Sandbox -Name "project-leak"
  $caseDoc = Get-Content $projectLeak.CasesPath -Raw | ConvertFrom-Json
  $caseDoc.cases[0].recommended_skills = @("project-router")
  $caseDoc | ConvertTo-Json -Depth 12 | Set-Content -Path $projectLeak.CasesPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $projectLeak -ExpectedText "recommends project-specific skill 'project-router'"

  $wrongGenericSet = New-Sandbox -Name "wrong-generic-set"
  $genericDoc = Get-Content $wrongGenericSet.ExpectedPath -Raw | ConvertFrom-Json
  $genericDoc.all_generic_skill_names = @("skill-a","skill-b","project-router")
  $genericDoc | ConvertTo-Json -Depth 12 | Set-Content -Path $wrongGenericSet.ExpectedPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $wrongGenericSet -ExpectedText "generic skill set is stale"

  $guessedTokens = New-Sandbox -Name "guessed-tokens"
  $tokenDoc = Get-Content $guessedTokens.ExpectedPath -Raw | ConvertFrom-Json
  $tokenDoc.runtime_metrics.input_tokens = 123
  $tokenDoc | ConvertTo-Json -Depth 12 | Set-Content -Path $guessedTokens.ExpectedPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $guessedTokens -ExpectedText "input_tokens must remain NOT_AVAILABLE"

  $missingTreatment = New-Sandbox -Name "missing-treatment"
  $missingCaseDoc = Get-Content $missingTreatment.CasesPath -Raw | ConvertFrom-Json
  $missingCaseDoc.cases[0].allowed_variants = @("selected_skills","all_generic_skills")
  $missingCaseDoc | ConvertTo-Json -Depth 12 | Set-Content -Path $missingTreatment.CasesPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $missingTreatment -ExpectedText "does not allow required context treatment 'no_skills'"

  Write-Output "[PASS] context efficiency benchmark contract is regression-covered"
} finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

exit 0

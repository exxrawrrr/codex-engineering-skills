param(
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$CasesPath = "$PSScriptRoot\..\evidence\evaluations\cases.json",
  [string]$SkillsRoot = "$PSScriptRoot\..\skills",
  [string]$ExpectedPath = "$PSScriptRoot\..\evidence\evaluations\context-current.json"
)

$ErrorActionPreference = "Stop"

function Test-SameStringSet {
  param(
    [string[]]$Actual,
    [string[]]$Expected
  )

  $actualNormalized = @($Actual | Sort-Object -Unique)
  $expectedNormalized = @($Expected | Sort-Object -Unique)
  if ($actualNormalized.Count -ne $expectedNormalized.Count) { return $false }
  return (($actualNormalized -join [char]0x001F) -eq ($expectedNormalized -join [char]0x001F))
}

function Get-CanonicalUtf8ByteCount {
  param([Parameter(Mandatory = $true)][string]$Path)

  $text = [System.IO.File]::ReadAllText($Path)
  $normalized = $text.Replace("`r`n", "`n").Replace("`r", "`n")
  return [System.Text.UTF8Encoding]::new($false).GetByteCount($normalized)
}

if (-not (Test-Path $RegistryPath)) { throw "Missing registry: $RegistryPath" }
if (-not (Test-Path $CasesPath)) { throw "Missing cases: $CasesPath" }
if (-not (Test-Path $SkillsRoot)) { throw "Missing skills root: $SkillsRoot" }
if (-not (Test-Path $ExpectedPath)) { throw "Missing current context benchmark artifact: $ExpectedPath" }

$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
$casesDoc = Get-Content $CasesPath -Raw | ConvertFrom-Json
$expected = Get-Content $ExpectedPath -Raw | ConvertFrom-Json

if ([int]$expected.schema_version -ne 2) {
  throw "Current context artifact schema_version must be 2"
}
if ([string]$expected.evaluation_type -ne "context_cost") {
  throw "Current context artifact evaluation_type must be 'context_cost'"
}
$expectedMeasurement = "Canonical UTF-8 byte size of SKILL.md entrypoints after CRLF/CR to LF normalization; references are excluded because they are conditionally loaded."
if ([string]$expected.measurement -ne $expectedMeasurement) {
  throw "Current context artifact measurement definition is stale"
}
if ([string]$expected.behavioral_quality -ne "NOT_RUN") {
  throw "Current context artifact behavioral_quality must remain NOT_RUN"
}
if ([string]$expected.runtime_metrics.input_tokens -ne "NOT_AVAILABLE") {
  throw "Current context artifact input_tokens must remain NOT_AVAILABLE unless runtime token measurement is implemented"
}
if ([string]$expected.runtime_metrics.tool_calls -ne "NOT_RUN") {
  throw "Current context artifact tool_calls must remain NOT_RUN unless a runtime execution is added"
}
if ([string]$expected.runtime_metrics.elapsed_ms -ne "NOT_RUN") {
  throw "Current context artifact elapsed_ms must remain NOT_RUN unless a runtime execution is added"
}
if ([string]::IsNullOrWhiteSpace([string]$expected.claim_limit)) {
  throw "Current context artifact requires claim_limit"
}

$bytesBySkill = @{}
$kindBySkill = @{}
$genericSkillNames = New-Object System.Collections.Generic.List[string]

foreach ($entry in @($registry.skills)) {
  $name = [string]$entry.name
  $kind = [string]$entry.kind

  if ([string]::IsNullOrWhiteSpace($name)) {
    throw "Registry contains empty skill name"
  }

  $skillPath = Join-Path (Join-Path $SkillsRoot $name) "SKILL.md"
  if (-not (Test-Path $skillPath)) {
    throw "Missing SKILL.md for context measurement: $name"
  }

  $bytesBySkill[$name] = Get-CanonicalUtf8ByteCount -Path $skillPath
  $kindBySkill[$name] = $kind

  if ($kind -eq "generic") {
    $genericSkillNames.Add($name)
  }
}

if ($genericSkillNames.Count -eq 0) {
  throw "Context benchmark requires at least one generic skill"
}

$allGenericBytes = 0
foreach ($name in $genericSkillNames) {
  $allGenericBytes += [int]$bytesBySkill[$name]
}

if (-not (Test-SameStringSet -Actual @($expected.all_generic_skill_names | ForEach-Object { [string]$_ }) -Expected @($genericSkillNames))) {
  throw "Current context artifact generic skill set is stale"
}
if ([int]$expected.all_generic_entrypoint_bytes -ne $allGenericBytes) {
  throw "Current context artifact all_generic_entrypoint_bytes is stale: expected $allGenericBytes, found $($expected.all_generic_entrypoint_bytes)"
}

$caseIds = New-Object System.Collections.Generic.HashSet[string]
$computedByCase = @{}

foreach ($case in @($casesDoc.cases)) {
  $caseId = [string]$case.id
  if ([string]::IsNullOrWhiteSpace($caseId)) {
    throw "Context benchmark case has empty id"
  }
  if (-not $caseIds.Add($caseId)) {
    throw "Duplicate context benchmark case id: $caseId"
  }

  $allowedVariants = @($case.allowed_variants | ForEach-Object { [string]$_ })
  foreach ($requiredVariant in @("no_skills","selected_skills","all_generic_skills")) {
    if ($requiredVariant -notin $allowedVariants) {
      throw "Case '$caseId' does not allow required context treatment '$requiredVariant'"
    }
  }

  $selectedSkills = @($case.recommended_skills | ForEach-Object { [string]$_ })
  if ($selectedSkills.Count -eq 0) {
    throw "Case '$caseId' has no recommended skills"
  }
  if (($selectedSkills | Sort-Object -Unique).Count -ne $selectedSkills.Count) {
    throw "Case '$caseId' has duplicate recommended skills"
  }

  $selectedBytes = 0
  foreach ($name in $selectedSkills) {
    if (-not $bytesBySkill.ContainsKey($name)) {
      throw "Case '$caseId' references unknown skill '$name'"
    }
    if ([string]$kindBySkill[$name] -ne "generic") {
      throw "Case '$caseId' recommends project-specific skill '$name'; generic-only denominator would not be comparable"
    }
    $selectedBytes += [int]$bytesBySkill[$name]
  }

  if ($selectedBytes -ge $allGenericBytes) {
    throw "Case '$caseId' selected treatment is not smaller than all_generic_skills"
  }

  $computedByCase[$caseId] = [ordered]@{
    case_id = $caseId
    no_skills_bytes = 0
    selected_skills_bytes = $selectedBytes
    all_generic_skills_bytes = $allGenericBytes
    selected_skills = @($selectedSkills)
    selected_skill_count = $selectedSkills.Count
    generic_skill_count = $genericSkillNames.Count
  }
}

$expectedComparisons = @($expected.comparisons)
if ($expectedComparisons.Count -ne $computedByCase.Count) {
  throw "Current context artifact comparison count is stale: expected $($computedByCase.Count), found $($expectedComparisons.Count)"
}

$seenExpectedCases = New-Object System.Collections.Generic.HashSet[string]
foreach ($comparison in $expectedComparisons) {
  $caseId = [string]$comparison.case_id
  if (-not $computedByCase.ContainsKey($caseId)) {
    throw "Current context artifact contains unknown case '$caseId'"
  }
  if (-not $seenExpectedCases.Add($caseId)) {
    throw "Current context artifact contains duplicate case '$caseId'"
  }

  $computed = $computedByCase[$caseId]

  if ([int]$comparison.no_skills_bytes -ne [int]$computed.no_skills_bytes) {
    throw "Case '$caseId' no_skills_bytes is stale"
  }
  if ([int]$comparison.selected_skills_bytes -ne [int]$computed.selected_skills_bytes) {
    throw "Case '$caseId' selected_skills_bytes is stale: expected $($computed.selected_skills_bytes), found $($comparison.selected_skills_bytes)"
  }
  if ([int]$comparison.all_generic_skills_bytes -ne [int]$computed.all_generic_skills_bytes) {
    throw "Case '$caseId' all_generic_skills_bytes is stale: expected $($computed.all_generic_skills_bytes), found $($comparison.all_generic_skills_bytes)"
  }
  if ([int]$comparison.selected_skill_count -ne [int]$computed.selected_skill_count) {
    throw "Case '$caseId' selected_skill_count is stale"
  }
  if ([int]$comparison.generic_skill_count -ne [int]$computed.generic_skill_count) {
    throw "Case '$caseId' generic_skill_count is stale"
  }
  if (-not (Test-SameStringSet -Actual @($comparison.selected_skills | ForEach-Object { [string]$_ }) -Expected @($computed.selected_skills))) {
    throw "Case '$caseId' selected skill set is stale"
  }
}

foreach ($caseId in $computedByCase.Keys) {
  if (-not $seenExpectedCases.Contains($caseId)) {
    throw "Current context artifact is missing case '$caseId'"
  }
}

Write-Output "=== Context Efficiency Benchmark ==="
Write-Output ("GENERIC_SKILLS={0} ALL_GENERIC_BYTES={1}" -f $genericSkillNames.Count,$allGenericBytes)
foreach ($caseId in @($computedByCase.Keys | Sort-Object)) {
  $row = $computedByCase[$caseId]
  Write-Output ("[PASS] {0}: no={1} selected={2} all_generic={3} selected_count={4}" -f $caseId,$row.no_skills_bytes,$row.selected_skills_bytes,$row.all_generic_skills_bytes,$row.selected_skill_count)
}
Write-Output "[PASS] current context artifact matches recomputed generic-only entrypoint bytes"
Write-Output "[PASS] runtime/token/tool/behavioral metrics remain explicitly unmeasured"

exit 0

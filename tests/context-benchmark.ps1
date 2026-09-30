param(
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$CasesPath = "$PSScriptRoot\..\evidence\evaluations\cases.json",
  [string]$SkillsRoot = "$PSScriptRoot\..\skills"
)

$ErrorActionPreference = "Stop"

$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
$casesDoc = Get-Content $CasesPath -Raw | ConvertFrom-Json
$bytesBySkill = @{}

foreach ($entry in $registry.skills) {
  $name = [string]$entry.name
  $skillPath = Join-Path $SkillsRoot ($name + "\SKILL.md")
  if (-not (Test-Path $skillPath)) { throw "Missing SKILL.md for context measurement: $name" }
  $bytesBySkill[$name] = [System.IO.File]::ReadAllBytes($skillPath).Length
}

$allBytes = 0
foreach ($value in $bytesBySkill.Values) { $allBytes += [int]$value }

$comparisons = @()
foreach ($case in $casesDoc.cases) {
  $selectedBytes = 0
  foreach ($skillName in $case.recommended_skills) {
    $name = [string]$skillName
    if (-not $bytesBySkill.ContainsKey($name)) {
      throw "Case '$($case.id)' references unknown skill '$name'"
    }
    $selectedBytes += [int]$bytesBySkill[$name]
  }

  $comparisons += [pscustomobject]@{
    case_id = [string]$case.id
    no_skill_bytes = 0
    selected_skill_bytes = $selectedBytes
    all_skills_bytes = $allBytes
    selected_skill_count = @($case.recommended_skills).Count
    registered_skill_count = @($registry.skills).Count
  }
}

$result = [pscustomobject]@{
  measurement = "SKILL.md UTF-8 bytes"
  all_skill_entrypoint_bytes = $allBytes
  comparisons = $comparisons
}

$result | ConvertTo-Json -Depth 5
exit 0

param(
  [string]$ProvenancePath = "$PSScriptRoot\..\PROVENANCE.json",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$SourcesPath = "$PSScriptRoot\..\SOURCES.md",
  [string]$AttributionPath = "$PSScriptRoot\..\ATTRIBUTION.md",
  [string]$DuplicateProjectPath = "$PSScriptRoot\..\skills\growthops-engineering\references\source-provenance.md"
)

$ErrorActionPreference = "Stop"
$provenance = Get-Content $ProvenancePath -Raw | ConvertFrom-Json
$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
$sourcesText = Get-Content $SourcesPath -Raw
$attributionText = Get-Content $AttributionPath -Raw
$errors = New-Object System.Collections.Generic.List[string]

if ($provenance.schema_version -ne 1) {
  $errors.Add("Unsupported provenance schema_version: $($provenance.schema_version)")
}

foreach ($path in @($provenance.canonical_human_sources)) {
  $resolved = Join-Path (Split-Path $ProvenancePath -Parent) ([string]$path)
  if (-not (Test-Path $resolved)) {
    $errors.Add("Missing canonical human provenance file: $path")
  }
}

$registeredSkills = @($registry.skills | ForEach-Object { [string]$_.name })
$genericSkills = @($registry.skills | Where-Object { $_.kind -eq "generic" } | ForEach-Object { [string]$_.name })
$sourceIds = New-Object System.Collections.Generic.HashSet[string]
$mappedSkills = New-Object System.Collections.Generic.HashSet[string]
$allUrls = New-Object System.Collections.Generic.HashSet[string]

foreach ($source in $provenance.sources) {
  $id = [string]$source.id
  if ([string]::IsNullOrWhiteSpace($id)) {
    $errors.Add("Provenance source has empty id")
    continue
  }
  if (-not $sourceIds.Add($id)) {
    $errors.Add("Duplicate provenance source id: $id")
  }

  $urls = @($source.urls)
  if ($urls.Count -eq 0) {
    $errors.Add("${id}: at least one URL is required")
  }
  foreach ($url in $urls) {
    $urlText = [string]$url
    if ($urlText -notmatch "^https://") {
      $errors.Add("${id}: URL must use https -> $urlText")
    }
    [void]$allUrls.Add($urlText.TrimEnd("/"))
  }

  if ([string]::IsNullOrWhiteSpace([string]$source.license_status)) {
    $errors.Add("${id}: license_status is required")
  }

  $skills = @($source.informs_skills)
  if ($skills.Count -eq 0) {
    $errors.Add("${id}: informs_skills is empty")
  }
  foreach ($skill in $skills) {
    $skillName = [string]$skill
    if ($registeredSkills -notcontains $skillName) {
      $errors.Add("${id}: unknown skill mapping -> $skillName")
    } else {
      [void]$mappedSkills.Add($skillName)
    }
  }
}

foreach ($skill in $genericSkills) {
  if (-not $mappedSkills.Contains($skill)) {
    $errors.Add("Generic skill has no provenance mapping: $skill")
  }
}
if (-not $mappedSkills.Contains("growthops-engineering")) {
  $errors.Add("GrowthOps project skill has no project-source mapping")
}

$trail = @($provenance.sources | Where-Object { $_.id -eq "repo-trailofbits-claude-code-config" })
if ($trail.Count -ne 1) {
  $errors.Add("Trail of Bits source mapping missing or duplicated")
} elseif ([string]$trail[0].license_status -ne "UNVERIFIED_NO_REDISTRIBUTION_CLAIM") {
  $errors.Add("Trail of Bits license uncertainty must remain explicit until independently re-verified")
}

$attributionRepoUrls = [regex]::Matches($attributionText, "https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+") |
  ForEach-Object { $_.Value.TrimEnd("/") } |
  Sort-Object -Unique
foreach ($url in $attributionRepoUrls) {
  if (-not $allUrls.Contains([string]$url)) {
    $errors.Add("ATTRIBUTION.md public repository URL missing from PROVENANCE.json: $url")
  }
}

foreach ($docPair in @(
  @{ Name = "SOURCES.md"; Text = $sourcesText },
  @{ Name = "ATTRIBUTION.md"; Text = $attributionText }
)) {
  if (-not $docPair.Text.Contains("PROVENANCE.json")) {
    $errors.Add("$($docPair.Name) does not link PROVENANCE.json")
  }
}

if (Test-Path $DuplicateProjectPath) {
  $errors.Add("Duplicate GrowthOps source-provenance.md still exists")
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] provenance mappings are unique, registered, and deduplicated"
}
Write-Output ("PROVENANCE SOURCES={0} MAPPED_SKILLS={1} FAIL={2}" -f $sourceIds.Count,$mappedSkills.Count,$errors.Count)

if ($errors.Count -gt 0) { exit 1 }
exit 0

param(
  [string]$CasePath = "$PSScriptRoot\..\evidence\cases\growthops-m01-m04.json",
  [string]$IndexPath = "$PSScriptRoot\..\evidence\INDEX.json",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$CaseStudyPath = "$PSScriptRoot\..\docs\case-study-growthops-m01-m04.md"
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

function Get-StringArray {
  param([object]$Value)
  if ($null -eq $Value) { return @() }
  return @($Value | ForEach-Object { [string]$_ })
}

function Get-MilestoneSection {
  param(
    [Parameter(Mandatory = $true)][string]$Markdown,
    [Parameter(Mandatory = $true)][string]$Heading
  )

  $pattern = "(?ms)^" + [regex]::Escape($Heading) + "\r?\n(?<body>.*?)(?=^## |\z)"
  $match = [regex]::Match($Markdown, $pattern)
  if (-not $match.Success) { return $null }
  return $match.Value
}

function Test-ObservationMapsEqual {
  param(
    [object]$Actual,
    [object]$Expected
  )

  if ($Actual -isnot [System.Management.Automation.PSCustomObject]) { return $false }
  if ($Expected -isnot [System.Management.Automation.PSCustomObject]) { return $false }

  $actualNames = @($Actual.PSObject.Properties.Name)
  $expectedNames = @($Expected.PSObject.Properties.Name)
  if (-not (Test-SameStringSet -Actual $actualNames -Expected $expectedNames)) { return $false }

  foreach ($name in $expectedNames) {
    if ([string]$Actual.PSObject.Properties[$name].Value -ne [string]$Expected.PSObject.Properties[$name].Value) { return $false }
  }
  return $true
}

foreach ($path in @($CasePath,$IndexPath,$RegistryPath,$CaseStudyPath)) {
  if (-not (Test-Path $path)) { throw "Missing GrowthOps evidence input: $path" }
}

$case = Get-Content $CasePath -Raw | ConvertFrom-Json
$index = Get-Content $IndexPath -Raw | ConvertFrom-Json
$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
$doc = Get-Content $CaseStudyPath -Raw
$errors = New-Object System.Collections.Generic.List[string]

if ([int]$case.schema_version -ne 2) {
  $errors.Add("GrowthOps case schema_version must be 2")
}
if ([string]$case.evidence_type -ne "observational_case_study") {
  $errors.Add("GrowthOps case evidence_type must be 'observational_case_study'")
}
if ([string]$case.claim_state -ne "PARTIALLY_VERIFIED") {
  $errors.Add("GrowthOps case claim_state must remain PARTIALLY_VERIFIED")
}
if ([string]::IsNullOrWhiteSpace([string]$case.claim)) {
  $errors.Add("GrowthOps case claim is required")
}
if ([string]::IsNullOrWhiteSpace([string]$case.does_not_claim)) {
  $errors.Add("GrowthOps case must state what it does not claim")
}

$requiredPrivacyExclusions = @(
  "private Codex transcripts",
  "secrets or credentials",
  "local-only session logs",
  "M05-and-later work"
)
$privacyExclusions = Get-StringArray $case.privacy_exclusions
if (-not (Test-SameStringSet -Actual $privacyExclusions -Expected $requiredPrivacyExclusions)) {
  $errors.Add("GrowthOps case privacy_exclusions must explicitly cover transcripts, secrets, local logs, and M05-and-later work")
}
foreach ($marker in @("Private Codex transcripts","M05-and-later work")) {
  if ([string]$case.privacy -notmatch [regex]::Escape($marker)) {
    $errors.Add("GrowthOps case privacy text missing marker: $marker")
  }
}

$expectedMilestones = @("M01","M02","M03","M04")
$sourceMilestones = Get-StringArray $case.source_scope.included_milestones
if (-not (Test-SameStringSet -Actual $sourceMilestones -Expected $expectedMilestones)) {
  $errors.Add("GrowthOps source_scope must include exactly M01-M04")
}
$sourceExcluded = Get-StringArray $case.source_scope.excluded
foreach ($marker in @("M05-and-later work","private Codex transcripts","local-only session logs","secrets or credentials")) {
  if ($sourceExcluded -notcontains $marker) {
    $errors.Add("GrowthOps source_scope exclusion missing: $marker")
  }
}

if ([string]$case.public_source_resolution.repository -ne [string]$case.repository) {
  $errors.Add("Public-source resolution repository must match case repository")
}
if ([string]$case.public_source_resolution.checked_on -ne [string]$case.verified_on) {
  $errors.Add("Public-source resolution checked_on must match case verified_on")
}
if ($case.public_source_resolution.all_listed_commits_resolved -ne $true) {
  $errors.Add("Public-source resolution must record all listed commits as resolved")
}
$expectedSourcePaths = @(
  "docs/implementation/M01_CHECKPOINT.md",
  "docs/implementation/M02_CHECKPOINT.md",
  "docs/implementation/M03_CHECKPOINT.md",
  "docs/implementation/M04_CHECKPOINT.md",
  "docs/implementation/M04_PROGRESS.md"
)
if (-not (Test-SameStringSet -Actual (Get-StringArray $case.public_source_resolution.checkpoint_paths_reviewed) -Expected $expectedSourcePaths)) {
  $errors.Add("Public-source resolution checkpoint path set is incomplete or stale")
}

$records = @($index.records | Where-Object { [string]$_.id -eq [string]$case.evidence_record_id })
if ($records.Count -ne 1) {
  $errors.Add("Case evidence_record_id must resolve to exactly one INDEX record")
  $record = $null
} else {
  $record = $records[0]
  if ([string]$record.type -ne "observational") {
    $errors.Add("GrowthOps INDEX record type must remain observational")
  }
  if ([string]$record.claim_state -ne "PARTIALLY_VERIFIED") {
    $errors.Add("GrowthOps INDEX record claim_state must remain PARTIALLY_VERIFIED")
  }
  if ([string]$record.public_repository -ne [string]$case.repository) {
    $errors.Add("Case repository does not match INDEX record")
  }
  if ([string]$record.claim -ne [string]$case.claim) {
    $errors.Add("Case claim must exactly match INDEX record claim")
  }
  if ([string]$record.does_not_claim -ne [string]$case.does_not_claim) {
    $errors.Add("Case does_not_claim must exactly match INDEX record")
  }
  if ([string]$record.case_data_path -ne "evidence/cases/growthops-m01-m04.json") {
    $errors.Add("GrowthOps INDEX case_data_path is stale")
  }
  if ([string]$record.case_study_path -ne "docs/case-study-growthops-m01-m04.md") {
    $errors.Add("GrowthOps INDEX case_study_path is stale")
  }
  if (-not (Test-ObservationMapsEqual -Actual $case.skill_observations -Expected $record.skill_observations)) {
    $errors.Add("Case skill_observations must exactly match INDEX record")
  }
}

$registeredByName = @{}
foreach ($entry in @($registry.skills)) {
  $name = [string]$entry.name
  if (-not [string]::IsNullOrWhiteSpace($name)) {
    $registeredByName[$name] = $entry
  }
}

if ($case.skill_observations -isnot [System.Management.Automation.PSCustomObject]) {
  $errors.Add("GrowthOps case skill_observations must be an object")
} else {
  foreach ($property in $case.skill_observations.PSObject.Properties) {
    $skill = [string]$property.Name
    if (-not $registeredByName.ContainsKey($skill)) {
      $errors.Add("GrowthOps case skill_observations references unregistered skill '$skill'")
      continue
    }
    $skillEvidenceRefs = @($registeredByName[$skill].evidence_refs | ForEach-Object { [string]$_ })
    if ($skillEvidenceRefs -notcontains [string]$case.evidence_record_id) {
      $errors.Add("Registry skill '$skill' does not reference the GrowthOps evidence record")
    }
  }
}

$milestones = @($case.milestones)
$milestoneIds = @($milestones | ForEach-Object { [string]$_.id })
if (-not (Test-SameStringSet -Actual $milestoneIds -Expected $expectedMilestones) -or $milestones.Count -ne 4) {
  $errors.Add("GrowthOps case must contain exactly M01-M04")
}
if (@($milestoneIds | Sort-Object -Unique).Count -ne $milestoneIds.Count) {
  $errors.Add("Duplicate milestone id in GrowthOps case")
}

$expectedCheckpointByMilestone = @{
  M01 = "docs/implementation/M01_CHECKPOINT.md"
  M02 = "docs/implementation/M02_CHECKPOINT.md"
  M03 = "docs/implementation/M03_CHECKPOINT.md"
  M04 = "docs/implementation/M04_CHECKPOINT.md"
}
$allCaseCommits = New-Object System.Collections.Generic.List[string]
$seenCaseCommits = New-Object System.Collections.Generic.HashSet[string]

foreach ($milestone in $milestones) {
  $id = [string]$milestone.id
  if ([string]$milestone.claim_state -ne "VERIFIED") {
    $errors.Add("${id}: milestone claim_state must be VERIFIED")
  }
  if ([string]::IsNullOrWhiteSpace([string]$milestone.name)) {
    $errors.Add("${id}: milestone name missing")
  }

  $expectedCheckpoint = [string]$expectedCheckpointByMilestone[$id]
  if ([string]$milestone.checkpoint_path -ne $expectedCheckpoint) {
    $errors.Add("${id}: checkpoint_path must be '$expectedCheckpoint'")
  }

  $commits = Get-StringArray $milestone.implementation_commits
  if ($commits.Count -eq 0) {
    $errors.Add("${id}: implementation_commits is empty")
  }
  if (@($commits | Sort-Object -Unique).Count -ne $commits.Count) {
    $errors.Add("${id}: implementation_commits contains duplicates")
  }
  foreach ($sha in $commits) {
    if ($sha -notmatch "^[0-9a-f]{40}$") {
      $errors.Add("${id}: implementation commit is not a full lowercase SHA -> $sha")
      continue
    }
    if (-not $seenCaseCommits.Add($sha)) {
      $errors.Add("${id}: implementation commit is duplicated across milestones -> $sha")
    }
    $allCaseCommits.Add($sha)
  }

  $skills = Get-StringArray $milestone.repository_skills_recorded
  if ($skills.Count -eq 0) {
    $errors.Add("${id}: repository_skills_recorded is empty")
  }
  if (@($skills | Sort-Object -Unique).Count -ne $skills.Count) {
    $errors.Add("${id}: repository_skills_recorded contains duplicates")
  }
  foreach ($skill in $skills) {
    if (-not $registeredByName.ContainsKey($skill)) {
      $errors.Add("${id}: unknown repository skill -> $skill")
    }
    if ($case.skill_observations -is [System.Management.Automation.PSCustomObject] -and
        $null -eq $case.skill_observations.PSObject.Properties[$skill]) {
      $errors.Add("${id}: skill '$skill' missing from case skill_observations")
    }
  }

  $verification = Get-StringArray $milestone.observed_verification
  if ($verification.Count -eq 0) {
    $errors.Add("${id}: observed_verification is empty")
  }
  if (@($verification | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
    $errors.Add("${id}: observed_verification contains empty text")
  }
  if (@($verification | Sort-Object -Unique).Count -ne $verification.Count) {
    $errors.Add("${id}: observed_verification contains duplicates")
  }
  if ([string]::IsNullOrWhiteSpace([string]$milestone.notes)) {
    $errors.Add("${id}: notes are required")
  }

  if ($id -eq "M04") {
    if ([string]$milestone.supporting_progress_path -ne "docs/implementation/M04_PROGRESS.md") {
      $errors.Add("M04: supporting_progress_path must point to M04_PROGRESS.md")
    }
    if ([string]$milestone.notes -notmatch "growthops-engineering was unavailable") {
      $errors.Add("M04: notes must preserve the M04-A2 router-unavailable nuance")
    }
  }
}

if ($null -ne $record) {
  $indexCommits = Get-StringArray $record.public_commits
  if (@($indexCommits | Sort-Object -Unique).Count -ne $indexCommits.Count) {
    $errors.Add("GrowthOps INDEX public_commits contains duplicates")
  }
  foreach ($sha in $indexCommits) {
    if ($sha -notmatch "^[0-9a-f]{40}$") {
      $errors.Add("GrowthOps INDEX public commit is not a full lowercase SHA -> $sha")
    }
  }
  if (-not (Test-SameStringSet -Actual @($allCaseCommits) -Expected $indexCommits)) {
    $errors.Add("GrowthOps case implementation commit set must exactly match INDEX public_commits")
  }
}

$backtick = [char]0x60
$docMarkers = @(
  "Evidence state: **PARTIALLY VERIFIED**",
  ("Source repository: " + $backtick + [string]$case.repository + $backtick),
  "Evidence window: M01 through M04, committed public records only",
  "No controlled skill-on versus skill-off experiment is claimed here.",
  "M05 and later work are outside this case study",
  "**VERIFIED**",
  "**PARTIALLY VERIFIED**",
  "**UNPROVEN**"
)
foreach ($marker in $docMarkers) {
  if (-not $doc.Contains($marker)) {
    $errors.Add("Case-study document missing boundary marker: $marker")
  }
}

foreach ($milestone in $milestones) {
  $id = [string]$milestone.id
  $heading = "## $id — $([string]$milestone.name)"
  $section = Get-MilestoneSection -Markdown $doc -Heading $heading
  if ($null -eq $section) {
    $errors.Add("${id}: case-study document missing milestone heading")
    continue
  }
  $checkpointMarker = $backtick + [string]$milestone.checkpoint_path + $backtick
  if (-not $section.Contains($checkpointMarker)) {
    $errors.Add("${id}: case-study document missing checkpoint path")
  }
  foreach ($sha in Get-StringArray $milestone.implementation_commits) {
    if (-not $section.Contains($sha)) {
      $errors.Add("${id}: case-study document missing commit $sha")
    }
  }
  foreach ($skill in Get-StringArray $milestone.repository_skills_recorded) {
    $skillMarker = $backtick + $skill + $backtick
    if (-not $section.Contains($skillMarker)) {
      $errors.Add("${id}: case-study document missing recorded skill '$skill'")
    }
  }
}
$m04ProgressMarker = $backtick + "docs/implementation/M04_PROGRESS.md" + $backtick
if (-not $doc.Contains($m04ProgressMarker)) {
  $errors.Add("Case-study document missing M04 supporting progress path")
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] GrowthOps M01-M04 observational case study contract"
}
Write-Output ("GROWTHOPS_CASE MILESTONES={0} COMMITS={1} FAIL={2} STATE={3}" -f $milestones.Count,$allCaseCommits.Count,$errors.Count,[string]$case.claim_state)

if ($errors.Count -gt 0) { exit 1 }
exit 0

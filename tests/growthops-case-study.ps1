param(
  [string]$CasePath = "$PSScriptRoot\..\evidence\cases\growthops-m01-m04.json",
  [string]$IndexPath = "$PSScriptRoot\..\evidence\INDEX.json",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$CaseStudyPath = "$PSScriptRoot\..\docs\case-study-growthops-m01-m04.md"
)

$ErrorActionPreference = "Stop"

$case = Get-Content $CasePath -Raw | ConvertFrom-Json
$index = Get-Content $IndexPath -Raw | ConvertFrom-Json
$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
$errors = New-Object System.Collections.Generic.List[string]

if ($case.claim_state -notin @("VERIFIED","PARTIALLY_VERIFIED","INFERRED","UNPROVEN")) {
  $errors.Add("Invalid case claim_state: $($case.claim_state)")
}
if ([string]::IsNullOrWhiteSpace([string]$case.does_not_claim)) {
  $errors.Add("Case must state what it does not claim")
}
if ([string]::IsNullOrWhiteSpace([string]$case.privacy) -or
    [string]$case.privacy -notmatch "Private Codex transcripts") {
  $errors.Add("Case must explicitly exclude private Codex transcripts")
}

$record = @($index.records | Where-Object { $_.id -eq $case.evidence_record_id })
if ($record.Count -ne 1) {
  $errors.Add("Case evidence_record_id must resolve to exactly one INDEX record")
} elseif ($record[0].public_repository -ne $case.repository) {
  $errors.Add("Case repository does not match INDEX record")
}

$registeredSkills = @($registry.skills | ForEach-Object { [string]$_.name })
$milestones = @($case.milestones)
$milestoneIds = @($milestones | ForEach-Object { [string]$_.id })
$expectedMilestones = @("M01","M02","M03","M04")

if (@($milestoneIds | Sort-Object -Unique).Count -ne $milestoneIds.Count) {
  $errors.Add("Duplicate milestone id in GrowthOps case")
}
foreach ($id in $expectedMilestones) {
  if ($milestoneIds -notcontains $id) { $errors.Add("Missing milestone: $id") }
}
foreach ($id in $milestoneIds) {
  if ($expectedMilestones -notcontains $id) { $errors.Add("Unexpected milestone: $id") }
}

foreach ($milestone in $milestones) {
  $id = [string]$milestone.id
  if ($milestone.claim_state -ne "VERIFIED") {
    $errors.Add("${id}: milestone claim_state must be VERIFIED")
  }
  if ([string]::IsNullOrWhiteSpace([string]$milestone.checkpoint_path)) {
    $errors.Add("${id}: checkpoint_path missing")
  }
  foreach ($sha in @($milestone.implementation_commits)) {
    if ([string]$sha -notmatch "^[0-9a-f]{40}$") {
      $errors.Add("${id}: implementation commit is not a full lowercase SHA -> $sha")
    }
  }
  foreach ($skill in @($milestone.repository_skills_recorded)) {
    if ($registeredSkills -notcontains [string]$skill) {
      $errors.Add("${id}: unknown repository skill -> $skill")
    }
  }
  if (@($milestone.observed_verification).Count -eq 0) {
    $errors.Add("${id}: observed_verification is empty")
  }
}

if (-not (Test-Path $CaseStudyPath)) {
  $errors.Add("Missing case-study document")
} else {
  $doc = Get-Content $CaseStudyPath -Raw
  foreach ($marker in @("PARTIALLY VERIFIED","VERIFIED","UNPROVEN","private Codex transcripts","unfinished M05 work")) {
    if (-not $doc.Contains($marker)) {
      $errors.Add("Case-study document missing boundary marker: $marker")
    }
  }
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] GrowthOps M01-M04 observational case study contract"
}
Write-Output ("GROWTHOPS_CASE MILESTONES={0} FAIL={1}" -f $milestones.Count,$errors.Count)

if ($errors.Count -gt 0) { exit 1 }
exit 0

param(
  [string]$ReviewPath = "$PSScriptRoot\..\evidence\lifecycle\phase16-review-2026-10-01.json",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$SkillRoot = "$PSScriptRoot\..\skills",
  [string]$IncubationRoot = "$PSScriptRoot\..\evidence\incubation",
  [string]$RootValidatorPath = "$PSScriptRoot\..\validate.ps1"
)

$ErrorActionPreference = "Stop"
$errors = [System.Collections.Generic.List[string]]::new()

function Assert-ExactSet {
  param([string[]]$Actual,[string[]]$Expected,[string]$Label)
  $a = @($Actual | Sort-Object -Unique -CaseSensitive)
  $e = @($Expected | Sort-Object -Unique -CaseSensitive)
  if ($a.Count -ne $e.Count -or (($a -join [char]0x001F) -cne ($e -join [char]0x001F))) {
    $errors.Add("$Label mismatch. Expected [$($e -join ', ')], observed [$($a -join ', ')]")
  }
}

foreach ($path in @($ReviewPath,$RegistryPath,$SkillRoot,$IncubationRoot,$RootValidatorPath)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Missing Phase 16 input: $path" }
}

$review = Get-Content -LiteralPath $ReviewPath -Raw | ConvertFrom-Json
$registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json

if ([int]$review.schema_version -ne 1) { $errors.Add("Phase 16 review schema_version must be 1") }
if ([string]$review.phase -ne "16") { $errors.Add("Phase 16 review must identify phase 16") }
if ([string]$review.reviewed_on -ne "2026-10-01") { $errors.Add("Phase 16 reviewed_on must be 2026-10-01") }

$state = [string]$review.completion_state
if ($state -notin @("DECISIONS_LOCKED_CLEANUP_PENDING_16B","COMPLETE")) {
  $errors.Add("Unsupported Phase 16 completion_state '$state'")
}
$expectedSplit = if ($state -eq "COMPLETE") { "16B" } else { "16A" }
if ([string]$review.split -ne $expectedSplit) {
  $errors.Add("Phase 16 split must be '$expectedSplit' for completion_state '$state'")
}

$registryByName = @{}
foreach ($entry in @($registry.skills)) { $registryByName[[string]$entry.name] = $entry }
$rows = @($review.lifecycle_decisions)
Assert-ExactSet -Actual @($rows | ForEach-Object { [string]$_.skill }) -Expected @($registry.skills | ForEach-Object { [string]$_.name }) -Label "lifecycle skill set"

foreach ($row in $rows) {
  $name = [string]$row.skill
  if (-not $registryByName.ContainsKey($name)) { continue }
  $entry = $registryByName[$name]
  $status = [string]$entry.status
  $tier = [string]$entry.evidence_tier

  if ([string]$row.status -ne $status) { $errors.Add("${name}: review status does not match registry") }
  if ([string]$row.evidence_tier -ne $tier) { $errors.Add("${name}: review evidence_tier does not match registry") }
  if ([string]::IsNullOrWhiteSpace([string]$row.basis)) { $errors.Add("${name}: lifecycle decision requires basis") }

  if ($status -eq "stable") {
    if ([string]$row.decision -ne "KEEP_STABLE") { $errors.Add("${name}: stable skill must remain KEEP_STABLE in 16A") }
    if ([string]$row.evidence_state -ne "PARTIALLY_VERIFIED") { $errors.Add("${name}: observational stable evidence must remain PARTIALLY_VERIFIED") }
  } elseif ($status -eq "project") {
    if ([string]$row.decision -ne "KEEP_PROJECT") { $errors.Add("${name}: project skill must remain KEEP_PROJECT") }
    if ([string]$row.evidence_state -ne "PARTIALLY_VERIFIED") { $errors.Add("${name}: project observational evidence must remain PARTIALLY_VERIFIED") }
  } elseif ($status -eq "incubating") {
    if ([string]$row.decision -ne "KEEP_INCUBATING") { $errors.Add("${name}: incubating skill must remain KEEP_INCUBATING in Phase 16") }
    if ($tier -ne "none" -or @($entry.evidence_refs).Count -ne 0) { $errors.Add("${name}: incubating skill must remain evidence_tier none with no refs") }
    if ([string]$row.evidence_state -ne "UNPROVEN") { $errors.Add("${name}: incubating skill must remain UNPROVEN") }

    $recordPath = Join-Path $IncubationRoot ($name + ".json")
    if ($name -eq "agent-skill-authoring") {
      if (Test-Path -LiteralPath $recordPath) {
        $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
        if ([string]$record.evidence_state -ne "UNPROVEN") { $errors.Add("${name}: optional incubation record must remain UNPROVEN") }
      }
    } else {
      if (-not (Test-Path -LiteralPath $recordPath)) {
        $errors.Add("${name}: expected incubation record is missing")
      } else {
        $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
        if ([string]$record.lifecycle_status -ne "incubating" -or [string]$record.evidence_state -ne "UNPROVEN" -or [string]$record.evidence_tier -ne "none") {
          $errors.Add("${name}: incubation record lifecycle/evidence fields are inconsistent")
        }
        if ([string]$record.representative_case_plan.execution_status -ne "NOT_RUN") {
          $errors.Add("${name}: post-creation representative case must remain NOT_RUN")
        }
      }
    }
  } else {
    $errors.Add("${name}: unsupported lifecycle status '$status'")
  }
}

if (@($review.promotions).Count -ne 0) { $errors.Add("Phase 16A must not contain lifecycle promotions") }
if (@($review.demotions).Count -ne 0) { $errors.Add("Phase 16A must not contain lifecycle demotions") }

$expectedDeferred = @("observability-diagnostics","dependency-upgrade-engineering","release-rollback-engineering")
Assert-ExactSet -Actual @($review.deferred_candidates | ForEach-Object { [string]$_.candidate }) -Expected $expectedDeferred -Label "deferred candidates"
foreach ($candidate in $expectedDeferred) {
  if ($registryByName.ContainsKey($candidate)) { $errors.Add("${candidate}: deferred candidate must remain absent from REGISTRY.json") }
  if (Test-Path -LiteralPath (Join-Path (Join-Path $SkillRoot $candidate) "SKILL.md")) { $errors.Add("${candidate}: deferred candidate must remain absent from skills/") }
}

$cleanupPath = "skills/growthops-engineering/scripts/validate-suite.ps1"
$cleanup = @($review.consolidation_decisions | Where-Object { [string]$_.path -eq $cleanupPath })
if ($cleanup.Count -ne 1 -or [string]$cleanup[0].decision -ne "REMOVE_IN_16B") {
  $errors.Add("Phase 16 must lock validate-suite.ps1 as REMOVE_IN_16B")
}
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$cleanupFullPath = Join-Path $repoRoot $cleanupPath
if ($state -eq "DECISIONS_LOCKED_CLEANUP_PENDING_16B" -and -not (Test-Path -LiteralPath $cleanupFullPath)) {
  $errors.Add("16A pending cleanup asset must still exist before 16B")
}
if ($state -eq "COMPLETE" -and (Test-Path -LiteralPath $cleanupFullPath)) {
  $errors.Add("COMPLETE state requires redundant validate-suite.ps1 to be removed")
}

$manifestDecision = @($review.consolidation_decisions | Where-Object { [string]$_.path -eq "skills/growthops-engineering/suite-manifest.json" })
if ($manifestDecision.Count -ne 1 -or [string]$manifestDecision[0].decision -ne "KEEP") {
  $errors.Add("suite-manifest.json must remain KEEP")
}
$rootValidator = Get-Content -LiteralPath $RootValidatorPath -Raw
if ($rootValidator -notmatch "suite-manifest\.json") {
  $errors.Add("Root validator must retain suite-manifest validation")
}

if ([string]::IsNullOrWhiteSpace([string]$review.lock_claim) -or [string]$review.lock_claim -notmatch "does not promote skill effectiveness") {
  $errors.Add("Phase 16A requires an explicit non-promotion lock claim")
}

if ($state -eq "COMPLETE") {
  if ([string]$review.locked_on -ne "2026-10-01") { $errors.Add("COMPLETE state requires locked_on=2026-10-01") }
}

foreach ($e in $errors) { Write-Output "[FAIL] $e" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] Phase 16 lifecycle evidence, defer discipline, and consolidation decisions are aligned"
}
Write-Output ("PHASE16_CONTRACT STATE={0} SKILLS={1} DEFERRED={2} CLEANUP_PENDING={3} FAIL={4}" -f $state,$rows.Count,$expectedDeferred.Count,@($review.removals_pending_16B).Count,$errors.Count)
if ($errors.Count -gt 0) { exit 1 }
exit 0

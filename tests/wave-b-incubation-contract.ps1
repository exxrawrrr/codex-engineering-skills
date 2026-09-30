param(
  [string]$DecisionPath = "$PSScriptRoot\..\evidence\incubation\wave-b-decisions-2026-09-30.json",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$SkillRoot = "$PSScriptRoot\..\skills",
  [string]$IncubationRoot = "$PSScriptRoot\..\evidence\incubation"
)

$ErrorActionPreference = "Stop"

function Assert-ExactSet {
  param(
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Actual,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Expected,
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors
  )

  $a = @($Actual | Sort-Object -Unique -CaseSensitive)
  $e = @($Expected | Sort-Object -Unique -CaseSensitive)
  if ($a.Count -ne $e.Count -or (($a -join [char]0x001F) -cne ($e -join [char]0x001F))) {
    $Errors.Add("$Label mismatch. Expected [$($e -join ', ')], observed [$($a -join ', ')]")
  }
}

foreach ($path in @($DecisionPath,$RegistryPath,$SkillRoot,$IncubationRoot)) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing Wave B input: $path"
  }
}

$ledger = Get-Content -LiteralPath $DecisionPath -Raw | ConvertFrom-Json
$registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()

if ([int]$ledger.schema_version -ne 1) {
  $errors.Add("Wave B decisions schema_version must be 1")
}
if ([string]$ledger.phase -ne "15") {
  $errors.Add("Wave B ledger must identify phase 15")
}
if ([string]$ledger.reviewed_on -ne "2026-09-30") {
  $errors.Add("Wave B reviewed_on must preserve 2026-09-30")
}

$state = [string]$ledger.completion_state
$stateContract = @{
  "DECISIONS_LOCKED_IMPLEMENTATION_PENDING_15B" = @{
    split = "15A"
    created = @()
    pending = @("runtime-compatibility-engineering","software-supply-chain-integrity")
    deferred = @("observability-diagnostics","dependency-upgrade-engineering","release-rollback-engineering")
  }
  "IMPLEMENTATION_IN_PROGRESS_15B" = @{
    split = "15B"
    created = @("runtime-compatibility-engineering")
    pending = @("software-supply-chain-integrity")
    deferred = @("observability-diagnostics","dependency-upgrade-engineering","release-rollback-engineering")
  }
  "IMPLEMENTATION_COMPLETE_PENDING_LOCK" = @{
    split = "15B"
    created = @("runtime-compatibility-engineering","software-supply-chain-integrity")
    pending = @()
    deferred = @("observability-diagnostics","dependency-upgrade-engineering","release-rollback-engineering")
  }
  "COMPLETE" = @{
    split = "15B"
    created = @("runtime-compatibility-engineering","software-supply-chain-integrity")
    pending = @()
    deferred = @("observability-diagnostics","dependency-upgrade-engineering","release-rollback-engineering")
  }
}

if (-not $stateContract.ContainsKey($state)) {
  $errors.Add("Unsupported Wave B completion_state '$state'")
  $expectedState = $null
} else {
  $expectedState = $stateContract[$state]
  if ([string]$ledger.split -ne [string]$expectedState.split) {
    $errors.Add("Wave B split must be '$($expectedState.split)' for completion_state '$state'")
  }
}

$expectedCandidates = @(
  "observability-diagnostics",
  "dependency-upgrade-engineering",
  "compatibility-engineering",
  "release-rollback-engineering",
  "supply-chain-security"
)
$requiredCandidates = @($ledger.required_candidates | ForEach-Object { [string]$_ })
Assert-ExactSet -Actual $requiredCandidates -Expected $expectedCandidates -Label "required_candidates" -Errors $errors

$rows = @($ledger.decisions)
$names = @($rows | ForEach-Object { [string]$_.candidate })
Assert-ExactSet -Actual $names -Expected $expectedCandidates -Label "decision candidates" -Errors $errors
if (@($names | Sort-Object -Unique -CaseSensitive).Count -ne $names.Count) {
  $errors.Add("Wave B decision candidates must be unique")
}

$registryByName = @{}
foreach ($entry in @($registry.skills)) {
  $registryByName[[string]$entry.name] = $entry
}

$expectedDecision = @{
  "observability-diagnostics" = "DEFER"
  "dependency-upgrade-engineering" = "DEFER"
  "compatibility-engineering" = "MODIFY"
  "release-rollback-engineering" = "DEFER"
  "supply-chain-security" = "MODIFY"
}
$expectedTarget = @{
  "compatibility-engineering" = "runtime-compatibility-engineering"
  "supply-chain-security" = "software-supply-chain-integrity"
}

$createdObserved = [System.Collections.Generic.List[string]]::new()
$pendingObserved = [System.Collections.Generic.List[string]]::new()
$deferredObserved = [System.Collections.Generic.List[string]]::new()

foreach ($row in $rows) {
  $candidate = [string]$row.candidate
  if (-not $expectedDecision.ContainsKey($candidate)) { continue }

  $decision = [string]$row.decision
  if ($decision -ne [string]$expectedDecision[$candidate]) {
    $errors.Add("$($candidate): decision must be '$($expectedDecision[$candidate])'")
  }

  if ($decision -eq "DEFER") {
    $deferredObserved.Add($candidate)

    if ($null -ne $row.target_skill -and -not [string]::IsNullOrWhiteSpace([string]$row.target_skill)) {
      $errors.Add("$($candidate): DEFER must not define target_skill")
    }
    if ([string]$row.implementation_state -ne "NOT_PLANNED_15B") {
      $errors.Add("$($candidate): DEFER implementation_state must be NOT_PLANNED_15B")
    }
    if ([string]$row.evidence_state -ne "INSUFFICIENT_PROBLEM_EVIDENCE") {
      $errors.Add("$($candidate): DEFER must preserve INSUFFICIENT_PROBLEM_EVIDENCE")
    }
    if ([string]$row.representative_case_status -ne "NOT_AVAILABLE") {
      $errors.Add("$($candidate): DEFER representative_case_status must be NOT_AVAILABLE")
    }
    if (@($row.problem_evidence).Count -eq 0 -or @($row.reconsider_when).Count -eq 0) {
      $errors.Add("$($candidate): DEFER requires problem_evidence and reconsider_when")
    }
    if (@($row.boundary_review.potential_ownership).Count -eq 0 -or @($row.boundary_review.overlap_risk).Count -eq 0) {
      $errors.Add("$($candidate): DEFER requires potential ownership and overlap-risk review")
    }

    if ($registryByName.ContainsKey($candidate)) {
      $errors.Add("$($candidate): deferred candidate must remain absent from REGISTRY.json")
    }
    if (Test-Path -LiteralPath (Join-Path (Join-Path $SkillRoot $candidate) "SKILL.md")) {
      $errors.Add("$($candidate): deferred candidate must remain absent from skills/")
    }
    continue
  }

  $target = [string]$row.target_skill
  if ($target -ne [string]$expectedTarget[$candidate]) {
    $errors.Add("$($candidate): target_skill must be '$($expectedTarget[$candidate])'")
  }
  if ([string]::IsNullOrWhiteSpace([string]$row.rename_reason)) {
    $errors.Add("$($candidate): MODIFY requires rename_reason")
  }
  if ([string]$row.lifecycle_status -ne "incubating") {
    $errors.Add("$($candidate): adopted Wave B target must remain incubating")
  }
  if ([string]$row.evidence_state -ne "UNPROVEN" -or [string]$row.evidence_tier -ne "none") {
    $errors.Add("$($candidate): effectiveness must remain UNPROVEN / evidence_tier none")
  }
  if ([string]$row.effectiveness_evidence -notmatch "^NONE") {
    $errors.Add("$($candidate): must not claim skill-effectiveness evidence")
  }
  if (@($row.boundary.owns).Count -eq 0 -or @($row.boundary.excludes).Count -eq 0) {
    $errors.Add("$($candidate): boundary must include non-empty owns and excludes")
  }
  if (@($row.overlap_review.PSObject.Properties).Count -eq 0) {
    $errors.Add("$($candidate): overlap_review must name neighboring skills/mechanisms")
  }
  if ([string]$row.case_or_unproven.state -ne "UNPROVEN" -or
      [string]::IsNullOrWhiteSpace([string]$row.case_or_unproven.planned_case) -or
      @($row.case_or_unproven.minimum_criteria).Count -eq 0) {
    $errors.Add("$($candidate): adopted target requires UNPROVEN planned representative case with criteria")
  }

  $implementation = [string]$row.implementation_state
  if ($implementation -eq "PENDING_15B") {
    $pendingObserved.Add($target)
    if ($registryByName.ContainsKey($target)) {
      $errors.Add("$($candidate): PENDING_15B target '$target' must not be prematurely registered")
    }
    if (Test-Path -LiteralPath (Join-Path (Join-Path $SkillRoot $target) "SKILL.md")) {
      $errors.Add("$($candidate): PENDING_15B target '$target' must not have SKILL.md")
    }
  } elseif ($implementation -eq "CREATED") {
    $createdObserved.Add($target)
    if (-not $registryByName.ContainsKey($target)) {
      $errors.Add("$($candidate): CREATED target '$target' is missing from REGISTRY.json")
    } else {
      $entry = $registryByName[$target]
      if ([string]$entry.kind -ne "generic" -or [string]$entry.status -ne "incubating") {
        $errors.Add("$($candidate): CREATED target '$target' must be generic/incubating")
      }
      if ([string]$entry.evidence_tier -ne "none" -or @($entry.evidence_refs).Count -ne 0) {
        $errors.Add("$($candidate): CREATED target '$target' must remain evidence_tier none with no refs")
      }
    }

    $skillPath = Join-Path (Join-Path $SkillRoot $target) "SKILL.md"
    $recordPath = Join-Path $IncubationRoot ($target + ".json")
    if (-not (Test-Path -LiteralPath $skillPath)) {
      $errors.Add("$($candidate): CREATED target '$target' is missing SKILL.md")
    } else {
      $skillText = Get-Content -LiteralPath $skillPath -Raw
      foreach ($marker in @("## When not to load","## Limitations")) {
        if (-not $skillText.Contains($marker)) {
          $errors.Add("$($candidate): SKILL.md missing boundary marker: $marker")
        }
      }
    }
    if (-not (Test-Path -LiteralPath $recordPath)) {
      $errors.Add("$($candidate): CREATED target '$target' is missing incubation record")
    } else {
      $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
      if ([int]$record.schema_version -ne 2 -or
          [string]$record.skill -ne $target -or
          [string]$record.implementation_state -ne "CREATED" -or
          [string]$record.lifecycle_status -ne "incubating" -or
          [string]$record.evidence_state -ne "UNPROVEN" -or
          [string]$record.evidence_tier -ne "none") {
        $errors.Add("$($candidate): incubation record identity/lifecycle/evidence fields are inconsistent")
      }
      if ([string]$record.representative_case_plan.execution_status -ne "NOT_RUN") {
        $errors.Add("$($candidate): representative case must remain NOT_RUN")
      }
      if (@($record.limitations).Count -eq 0) {
        $errors.Add("$($candidate): incubation record requires limitations")
      }
    }
  } else {
    $errors.Add("$($candidate): invalid implementation_state '$implementation'")
  }
}

if ($null -ne $expectedState) {
  Assert-ExactSet -Actual @($createdObserved) -Expected @($expectedState.created) -Label "created targets" -Errors $errors
  Assert-ExactSet -Actual @($pendingObserved) -Expected @($expectedState.pending) -Label "pending targets" -Errors $errors
  Assert-ExactSet -Actual @($deferredObserved) -Expected @($expectedState.deferred) -Label "deferred candidates" -Errors $errors
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] Wave B admission decisions, defer discipline, overlap boundaries, and lifecycle state are aligned"
}
Write-Output ("WAVE_B_CONTRACT STATE={0} DECISIONS={1} CREATED={2} PENDING={3} DEFERRED={4} FAIL={5}" -f $state,$rows.Count,$createdObserved.Count,$pendingObserved.Count,$deferredObserved.Count,$errors.Count)

if ($errors.Count -gt 0) { exit 1 }
exit 0

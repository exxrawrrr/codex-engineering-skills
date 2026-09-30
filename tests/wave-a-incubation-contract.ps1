param(
  [string]$DecisionPath = "$PSScriptRoot\..\evidence\incubation\wave-a-decisions-2026-09-30.json",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$ProvenancePath = "$PSScriptRoot\..\PROVENANCE.json",
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

foreach ($path in @($DecisionPath,$RegistryPath,$ProvenancePath,$SkillRoot,$IncubationRoot)) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing Wave A input: $path"
  }
}

$decisions = Get-Content -LiteralPath $DecisionPath -Raw | ConvertFrom-Json
$registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
$provenance = Get-Content -LiteralPath $ProvenancePath -Raw | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()

if ([int]$decisions.schema_version -ne 1) {
  $errors.Add("Wave A decisions schema_version must be 1")
}
if ([string]$decisions.phase -ne "14") {
  $errors.Add("Wave A decision ledger must identify phase 14")
}
if ([string]$decisions.reviewed_on -ne "2026-09-30") {
  $errors.Add("Wave A reviewed_on must preserve 2026-09-30")
}

$state = [string]$decisions.completion_state
$stateContract = @{
  "DECISIONS_LOCKED_IMPLEMENTATION_PENDING_14B" = @{
    split = "14A"
    created = @("agent-skill-evaluation")
    pending = @("api-contract-testing","ci-pipeline-reliability")
  }
  "IMPLEMENTATION_IN_PROGRESS_14B" = @{
    split = "14B"
    created = @("agent-skill-evaluation","api-contract-testing")
    pending = @("ci-pipeline-reliability")
  }
  "IMPLEMENTATION_COMPLETE_PENDING_LOCK" = @{
    split = "14B"
    created = @("agent-skill-evaluation","api-contract-testing","ci-pipeline-reliability")
    pending = @()
  }
  "COMPLETE" = @{
    split = "14B"
    created = @("agent-skill-evaluation","api-contract-testing","ci-pipeline-reliability")
    pending = @()
  }
}
if (-not $stateContract.ContainsKey($state)) {
  $errors.Add("Unsupported Wave A completion_state '$state'")
  $expectedState = $null
} else {
  $expectedState = $stateContract[$state]
  if ([string]$decisions.split -ne [string]$expectedState.split) {
    $errors.Add("Wave A split must be '$($expectedState.split)' for completion_state '$state'")
  }
}

if ($state -eq "COMPLETE") {
  if ([string]$decisions.locked_on -ne "2026-09-30") {
    $errors.Add("COMPLETE state requires locked_on=2026-09-30")
  }
  if ([string]::IsNullOrWhiteSpace([string]$decisions.lock_claim) -or
      [string]$decisions.lock_claim -notmatch "incubating" -or
      [string]$decisions.lock_claim -notmatch "UNPROVEN" -or
      [string]$decisions.lock_claim -notmatch "not an effectiveness promotion") {
    $errors.Add("COMPLETE state requires an explicit incubating/UNPROVEN non-promotion lock claim")
  }
}

$expectedCandidates = @("agent-skill-evaluation","api-contract-testing","ci-cd-reliability")
$requiredCandidates = @($decisions.required_candidates | ForEach-Object { [string]$_ })
Assert-ExactSet -Actual $requiredCandidates -Expected $expectedCandidates -Label "required_candidates" -Errors $errors

$decisionRows = @($decisions.decisions)
$decisionNames = @($decisionRows | ForEach-Object { [string]$_.candidate })
Assert-ExactSet -Actual $decisionNames -Expected $expectedCandidates -Label "decision candidates" -Errors $errors
if (@($decisionNames | Sort-Object -Unique -CaseSensitive).Count -ne $decisionNames.Count) {
  $errors.Add("Wave A decision candidates must be unique")
}

$registryByName = @{}
foreach ($entry in @($registry.skills)) {
  $registryByName[[string]$entry.name] = $entry
}

$provenanceMapped = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($source in @($provenance.sources)) {
  foreach ($skill in @($source.informs_skills)) {
    [void]$provenanceMapped.Add([string]$skill)
  }
}

$expectedTargetByCandidate = @{
  "agent-skill-evaluation" = "agent-skill-evaluation"
  "api-contract-testing" = "api-contract-testing"
  "ci-cd-reliability" = "ci-pipeline-reliability"
}
$expectedDecisionByCandidate = @{
  "agent-skill-evaluation" = "KEEP"
  "api-contract-testing" = "ADOPT"
  "ci-cd-reliability" = "MODIFY"
}

$createdObserved = [System.Collections.Generic.List[string]]::new()
$pendingObserved = [System.Collections.Generic.List[string]]::new()

foreach ($row in $decisionRows) {
  $candidate = [string]$row.candidate
  $decision = [string]$row.decision
  $target = [string]$row.target_skill
  $implementation = [string]$row.implementation_state

  if (-not $expectedTargetByCandidate.ContainsKey($candidate)) {
    continue
  }
  if ($decision -ne [string]$expectedDecisionByCandidate[$candidate]) {
    $errors.Add("$($candidate): decision must be '$($expectedDecisionByCandidate[$candidate])'")
  }
  if ($target -ne [string]$expectedTargetByCandidate[$candidate]) {
    $errors.Add("$($candidate): target_skill must be '$($expectedTargetByCandidate[$candidate])'")
  }

  if ([string]$row.lifecycle_status -ne "incubating") {
    $errors.Add("$($candidate): Wave A candidate must remain incubating")
  }
  if ([string]$row.evidence_state -ne "UNPROVEN" -or [string]$row.evidence_tier -ne "none") {
    $errors.Add("$($candidate): effectiveness must remain UNPROVEN / evidence_tier none")
  }
  if ([string]$row.effectiveness_evidence -notmatch "^NONE") {
    $errors.Add("$($candidate): must not claim skill-effectiveness evidence")
  }

  $owns = @($row.boundary.owns | ForEach-Object { [string]$_ })
  $excludes = @($row.boundary.excludes | ForEach-Object { [string]$_ })
  if ($owns.Count -eq 0 -or $excludes.Count -eq 0) {
    $errors.Add("$($candidate): boundary must include non-empty owns and excludes")
  }
  $overlap = @($row.overlap_review.PSObject.Properties)
  if ($overlap.Count -eq 0) {
    $errors.Add("$($candidate): overlap_review must name at least one neighboring skill/wave")
  }
  if ([string]$row.case_or_unproven.state -ne "UNPROVEN" -or [string]::IsNullOrWhiteSpace([string]$row.case_or_unproven.planned_case)) {
    $errors.Add("$($candidate): must carry explicit UNPROVEN state plus a planned case")
  }

  if ($candidate -eq "ci-cd-reliability" -and [string]::IsNullOrWhiteSpace([string]$row.rename_reason)) {
    $errors.Add("ci-cd-reliability: MODIFY requires rename_reason")
  }

  if ($implementation -eq "CREATED") {
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

    if (-not $provenanceMapped.Contains($target)) {
      $errors.Add("$($candidate): CREATED target '$target' lacks provenance mapping")
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
      foreach ($pair in @(
        @("skill",$target),
        @("implementation_state","CREATED"),
        @("lifecycle_status","incubating"),
        @("evidence_state","UNPROVEN"),
        @("evidence_tier","none")
      )) {
        $field = $pair[0]
        $expected = $pair[1]
        if ([string]$record.$field -ne $expected) {
          $errors.Add("$($candidate): incubation '$field' must be '$expected'")
        }
      }
      if ([int]$record.schema_version -ne 2) {
        $errors.Add("$($candidate): incubation record schema_version must be 2")
      }
      if ([string]$record.representative_case_plan.execution_status -ne "NOT_RUN") {
        $errors.Add("$($candidate): representative case must remain NOT_RUN")
      }
      if (@($record.limitations).Count -eq 0) {
        $errors.Add("$($candidate): incubation record requires limitations")
      }
      if ([string]::IsNullOrWhiteSpace([string]$record.current_evidence) -or [string]$record.current_evidence -notmatch "(?i)no .*post-creation|no controlled post-creation") {
        $errors.Add("$($candidate): current_evidence must preserve missing post-creation effectiveness proof")
      }
    }
  } elseif ($implementation -eq "PENDING_14B") {
    $pendingObserved.Add($target)
    if ($registryByName.ContainsKey($target)) {
      $errors.Add("$($candidate): PENDING_14B target '$target' must not be prematurely registered")
    }
    if (Test-Path -LiteralPath (Join-Path (Join-Path $SkillRoot $target) "SKILL.md")) {
      $errors.Add("$($candidate): PENDING_14B target '$target' must not have a created SKILL.md")
    }
  } else {
    $errors.Add("$($candidate): invalid implementation_state '$implementation'")
  }
}

if ($null -ne $expectedState) {
  Assert-ExactSet -Actual @($createdObserved) -Expected @($expectedState.created) -Label "created targets" -Errors $errors
  Assert-ExactSet -Actual @($pendingObserved) -Expected @($expectedState.pending) -Label "pending targets" -Errors $errors
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] Wave A lifecycle state, created-skill contracts, boundaries, and evidence truthfulness are aligned"
}
Write-Output ("WAVE_A_CONTRACT STATE={0} DECISIONS={1} CREATED={2} PENDING={3} FAIL={4}" -f $state,$decisionRows.Count,$createdObserved.Count,$pendingObserved.Count,$errors.Count)

if ($errors.Count -gt 0) { exit 1 }
exit 0

param(
  [string]$DecisionPath = "$PSScriptRoot\..\evidence\incubation\wave-a-decisions-2026-09-30.json",
  [string]$AgentRecordPath = "$PSScriptRoot\..\evidence\incubation\agent-skill-evaluation.json",
  [string]$AgentSkillPath = "$PSScriptRoot\..\skills\agent-skill-evaluation\SKILL.md",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$ProvenancePath = "$PSScriptRoot\..\PROVENANCE.json"
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

foreach ($path in @($DecisionPath,$AgentRecordPath,$AgentSkillPath,$RegistryPath,$ProvenancePath)) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing Wave A input: $path"
  }
}

$decisions = Get-Content -LiteralPath $DecisionPath -Raw | ConvertFrom-Json
$agentRecord = Get-Content -LiteralPath $AgentRecordPath -Raw | ConvertFrom-Json
$agentSkill = Get-Content -LiteralPath $AgentSkillPath -Raw
$registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
$provenance = Get-Content -LiteralPath $ProvenancePath -Raw | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()

if ([int]$decisions.schema_version -ne 1) {
  $errors.Add("Wave A decisions schema_version must be 1")
}
if ([string]$decisions.phase -ne "14" -or [string]$decisions.split -ne "14A") {
  $errors.Add("Wave A decision ledger must identify phase 14 / split 14A")
}
if ([string]$decisions.reviewed_on -ne "2026-09-30") {
  $errors.Add("Wave A reviewed_on must preserve 2026-09-30")
}
if ([string]$decisions.completion_state -ne "DECISIONS_LOCKED_IMPLEMENTATION_PENDING_14B") {
  $errors.Add("Chat 14A completion_state must remain implementation-pending for 14B")
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

$allowedDecisions = @("KEEP","ADOPT","MODIFY","DEFER","REJECT")
$allowedImplementation = @("CREATED","PENDING_14B","NOT_PLANNED")
$plannedTargets = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

foreach ($row in $decisionRows) {
  $candidate = [string]$row.candidate
  $decision = [string]$row.decision
  $target = [string]$row.target_skill
  $implementation = [string]$row.implementation_state

  if ($allowedDecisions -notcontains $decision) {
    $errors.Add("$($candidate): invalid decision '$decision'")
  }
  if ($allowedImplementation -notcontains $implementation) {
    $errors.Add("$($candidate): invalid implementation_state '$implementation'")
  }
  if ([string]$row.lifecycle_status -eq "stable") {
    $errors.Add("$($candidate): Wave A candidate must not be stable")
  }
  if ([string]$row.lifecycle_status -ne "incubating") {
    $errors.Add("$($candidate): adopted/kept Wave A candidate must remain incubating in 14A")
  }
  if ([string]$row.evidence_state -ne "UNPROVEN" -or [string]$row.evidence_tier -ne "none") {
    $errors.Add("$($candidate): effectiveness must remain UNPROVEN / evidence_tier none in 14A")
  }
  if ([string]$row.effectiveness_evidence -notmatch "^NONE") {
    $errors.Add("$($candidate): 14A must not claim skill-effectiveness evidence")
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
  foreach ($property in $overlap) {
    if ([string]::IsNullOrWhiteSpace([string]$property.Value)) {
      $errors.Add("$($candidate): overlap_review '$($property.Name)' is empty")
    }
  }

  if ([string]$row.case_or_unproven.state -ne "UNPROVEN" -or
      [string]::IsNullOrWhiteSpace([string]$row.case_or_unproven.planned_case)) {
    $errors.Add("$($candidate): must carry explicit UNPROVEN state plus a planned case")
  }

  if ($decision -eq "MODIFY") {
    if ($target -eq $candidate) {
      $errors.Add("$($candidate): MODIFY must change target_skill or scope identity")
    }
    if ([string]::IsNullOrWhiteSpace([string]$row.rename_reason)) {
      $errors.Add("$($candidate): MODIFY requires rename_reason")
    }
  }

  if ($decision -eq "ADOPT" -and $target -ne $candidate) {
    $errors.Add("$($candidate): ADOPT target_skill must preserve the candidate slug")
  }

  if ($implementation -eq "CREATED") {
    if (-not $registryByName.ContainsKey($target)) {
      $errors.Add("$($candidate): CREATED target '$target' is missing from REGISTRY.json")
    } else {
      $entry = $registryByName[$target]
      if ([string]$entry.status -ne "incubating" -or [string]$entry.kind -ne "generic") {
        $errors.Add("$($candidate): CREATED target '$target' must be generic/incubating")
      }
      if ([string]$entry.evidence_tier -ne "none" -or @($entry.evidence_refs).Count -ne 0) {
        $errors.Add("$($candidate): CREATED target '$target' must remain evidence_tier none with no refs")
      }
    }
    if (-not $provenanceMapped.Contains($target)) {
      $errors.Add("$($candidate): CREATED target '$target' lacks provenance mapping")
    }
  }

  if ($implementation -eq "PENDING_14B") {
    if (-not $plannedTargets.Add($target)) {
      $errors.Add("$($candidate): duplicate pending target '$target'")
    }
    if ($registryByName.ContainsKey($target)) {
      $errors.Add("$($candidate): PENDING_14B target '$target' must not be prematurely registered")
    }
  }
}

$agentDecision = @($decisionRows | Where-Object { [string]$_.candidate -eq "agent-skill-evaluation" })
if ($agentDecision.Count -ne 1 -or
    [string]$agentDecision[0].decision -ne "KEEP" -or
    [string]$agentDecision[0].implementation_state -ne "CREATED") {
  $errors.Add("agent-skill-evaluation must have exactly one KEEP/CREATED decision")
}

$apiDecision = @($decisionRows | Where-Object { [string]$_.candidate -eq "api-contract-testing" })
if ($apiDecision.Count -ne 1 -or [string]$apiDecision[0].decision -ne "ADOPT" -or [string]$apiDecision[0].target_skill -ne "api-contract-testing") {
  $errors.Add("api-contract-testing must be ADOPT -> api-contract-testing")
}

$ciDecision = @($decisionRows | Where-Object { [string]$_.candidate -eq "ci-cd-reliability" })
if ($ciDecision.Count -ne 1 -or [string]$ciDecision[0].decision -ne "MODIFY" -or [string]$ciDecision[0].target_skill -ne "ci-pipeline-reliability") {
  $errors.Add("ci-cd-reliability must be MODIFY -> ci-pipeline-reliability")
}

if ([int]$agentRecord.schema_version -ne 2) {
  $errors.Add("agent-skill-evaluation incubation record must use schema_version 2")
}
foreach ($pair in @(
  @("skill","agent-skill-evaluation"),
  @("phase","14A"),
  @("decision","KEEP"),
  @("implementation_state","CREATED"),
  @("lifecycle_status","incubating"),
  @("evidence_state","UNPROVEN"),
  @("evidence_tier","none")
)) {
  $field = $pair[0]
  $expected = $pair[1]
  if ([string]$agentRecord.$field -ne $expected) {
    $errors.Add("agent-skill-evaluation incubation '$field' must be '$expected'")
  }
}
if ([string]$agentRecord.representative_case_plan.execution_status -ne "NOT_RUN") {
  $errors.Add("agent-skill-evaluation representative case must remain NOT_RUN in 14A")
}
if ([string]::IsNullOrWhiteSpace([string]$agentRecord.current_evidence) -or [string]$agentRecord.current_evidence -notmatch "No controlled post-creation execution") {
  $errors.Add("agent-skill-evaluation current_evidence must explicitly preserve the missing post-creation comparison")
}

foreach ($marker in @(
  "## When not to load",
  "## Limitations",
  "object of evaluation is the skill/router/loading strategy itself",
  "does not:",
  "Repository mechanisms that predate this skill are not evidence"
)) {
  if (-not $agentSkill.Contains($marker)) {
    $errors.Add("agent-skill-evaluation SKILL.md missing boundary marker: $marker")
  }
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] Wave A admission decisions, boundaries, evidence truthfulness, and 14A/14B split are aligned"
}
Write-Output ("WAVE_A_CONTRACT DECISIONS={0} CREATED=1 PENDING=2 FAIL={1}" -f $decisionRows.Count,$errors.Count)

if ($errors.Count -gt 0) { exit 1 }
exit 0

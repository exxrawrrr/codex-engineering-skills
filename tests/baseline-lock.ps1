$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$baselinePath = Join-Path $repoRoot "evidence/baseline/2026-09-30-audit-baseline.json"
$evidenceReadmePath = Join-Path $repoRoot "evidence/README.md"
$baselineReadmePath = Join-Path $repoRoot "evidence/baseline/README.md"

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if (-not $Condition) {
    throw $Message
  }
}

function Assert-Equal {
  param(
    [AllowNull()]$Actual,
    [AllowNull()]$Expected,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if ([string]$Actual -ne [string]$Expected) {
    throw "$Message. Expected '$Expected', got '$Actual'"
  }
}

function Assert-FixtureSkill {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][string]$ExpectedMarker
  )

  $path = Join-Path $repoRoot $RelativePath
  Assert-True (Test-Path $path) "Missing installer fixture: $RelativePath"

  $raw = Get-Content $path -Raw
  Assert-True ($raw -match "(?m)^name:\s+fixture-skill\s*$") "$RelativePath lost fixture-skill frontmatter"
  Assert-True ($raw -match "(?m)^version-marker:\s*$([regex]::Escape($ExpectedMarker))\s*$") "$RelativePath lost version marker '$ExpectedMarker'"
}

Assert-True (Test-Path $baselinePath) "Missing Phase 01 baseline snapshot"
$baseline = Get-Content $baselinePath -Raw | ConvertFrom-Json

Assert-Equal $baseline.schema_version 1 "Baseline schema_version drifted"
Assert-Equal $baseline.captured_on "2026-09-30" "Baseline capture date drifted"
Assert-Equal $baseline.repository "exxrawrrr/codex-engineering-skills" "Baseline repository drifted"
Assert-Equal $baseline.baseline_commit "244955ffe24734784d26c36315f4933ec2d34252" "Baseline commit anchor drifted"
Assert-Equal $baseline.audit_source_head "2229aed83f0dd09e2237854da4af855d19992e03" "Audit source anchor drifted"
Assert-Equal $baseline.registry_version "1.1.1" "Historical registry version drifted"

Assert-Equal $baseline.repository_surface.registered_skills 8 "Historical registered skill count drifted"
Assert-Equal $baseline.repository_surface.stable_generic 6 "Historical stable generic count drifted"
Assert-Equal $baseline.repository_surface.incubating_generic 1 "Historical incubating generic count drifted"
Assert-Equal $baseline.repository_surface.project_skills 1 "Historical project skill count drifted"
Assert-Equal $baseline.repository_surface.workflows 1 "Historical workflow count drifted"

Assert-Equal $baseline.ci.workflow ".github/workflows/validate.yml" "Historical CI workflow path drifted"
Assert-Equal $baseline.ci.tested_runner "windows-latest" "Historical CI runner drifted"
Assert-Equal $baseline.ci.prd_validation_run_id 36664649310 "Historical PRD validation run drifted"
Assert-Equal $baseline.ci.prd_validation_conclusion "success" "Historical PRD validation conclusion drifted"

$expectedGaps = [ordered]@{
  "encoding-mojibake" = "VERIFIED"
  "duplicate-growthops-validator" = "VERIFIED"
  "installer-partial-failure" = "VERIFIED"
  "backup-inside-discovery-root" = "INFERRED_RISK"
  "windows-only-ci" = "VERIFIED"
  "behavioral-evaluation" = "VERIFIED_GAP"
}

$seenGaps = New-Object System.Collections.Generic.HashSet[string]
foreach ($gap in @($baseline.known_gaps)) {
  $id = [string]$gap.id
  Assert-True (-not [string]::IsNullOrWhiteSpace($id)) "Baseline contains a gap with an empty id"
  Assert-True ($seenGaps.Add($id)) "Baseline contains duplicate gap id '$id'"
  Assert-True $expectedGaps.Contains($id) "Baseline contains unexpected gap id '$id'"
  Assert-Equal ([string]$gap.state) ([string]$expectedGaps[$id]) "Gap state drifted for '$id'"
}
Assert-Equal $seenGaps.Count $expectedGaps.Count "Baseline gap set size drifted"

Assert-Equal $baseline.growthops_evidence_scope.included "committed M01-M04 evidence" "GrowthOps included evidence scope drifted"
Assert-Equal $baseline.growthops_evidence_scope.excluded "active uncommitted M05 workspace work" "GrowthOps excluded evidence scope drifted"
Assert-Equal $baseline.local_full_growthops_verify "NOT_RUN_RESULT_UNAVAILABLE_REMOTE_TIMEOUT" "Historical local verification result drifted"

$mojibakeFixture = Join-Path $repoRoot "evidence/fixtures/validation/mojibake-sample.txt"
Assert-True (Test-Path $mojibakeFixture) "Missing mojibake regression fixture"
$mojibakeText = Get-Content $mojibakeFixture -Raw
Assert-True ($mojibakeText.Contains("INTENTIONALLY INVALID FIXTURE")) "Mojibake fixture lost invalid-fixture marker"
Assert-True ($mojibakeText.Contains("expected semantic text:")) "Mojibake fixture lost expected-text section"
Assert-True ($mojibakeText.Contains("corrupted forms")) "Mojibake fixture lost corrupted-form section"

$invalidStatusFixture = Join-Path $repoRoot "evidence/fixtures/validation/invalid-status-registry.json"
Assert-True (Test-Path $invalidStatusFixture) "Missing invalid-status registry fixture"
$invalidStatus = Get-Content $invalidStatusFixture -Raw | ConvertFrom-Json
Assert-Equal @($invalidStatus.skills).Count 1 "Invalid-status fixture skill count drifted"
Assert-Equal $invalidStatus.skills[0].name "fixture-skill" "Invalid-status fixture name drifted"
Assert-Equal $invalidStatus.skills[0].status "totally-stable" "Invalid-status fixture no longer encodes the audited defect"

Assert-FixtureSkill -RelativePath "evidence/fixtures/installer/existing-skill/SKILL.md" -ExpectedMarker "existing-v1"
Assert-FixtureSkill -RelativePath "evidence/fixtures/installer/replacement-skill/SKILL.md" -ExpectedMarker "replacement-v2"

Assert-True (Test-Path $baselineReadmePath) "Missing baseline maintenance contract"
$baselineReadme = Get-Content $baselineReadmePath -Raw
Assert-True ($baselineReadme.Contains("historical snapshots")) "Baseline README no longer identifies snapshots as historical"
Assert-True ($baselineReadme.Contains("Do not rewrite a dated baseline")) "Baseline README lost immutability rule"

Assert-True (Test-Path $evidenceReadmePath) "Missing evidence README"
$evidenceReadme = Get-Content $evidenceReadmePath -Raw
Assert-True ($evidenceReadme.Contains("preserved or clearly superseded")) "Evidence preservation rule drifted"

Write-Output "[PASS] Phase 01 baseline anchors remain immutable"
Write-Output "[PASS] Phase 01 regression fixtures retain their audited signatures"
Write-Output "[PASS] Phase 01 evidence preservation rules remain explicit"
exit 0

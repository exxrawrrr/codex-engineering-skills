param(
  [string]$ReportPath = "$PSScriptRoot\..\evidence\releases\v1.2.0-vnext-acceptance-2026-10-01.json",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$Phase16Path = "$PSScriptRoot\..\evidence\lifecycle\phase16-review-2026-10-01.json",
  [string]$ComparativeResultPath = "$PSScriptRoot\..\evidence\evaluations\results\phase17-supply-chain-comparison-2026-10-01.json",
  [string]$CasesPath = "$PSScriptRoot\..\evidence\evaluations\cases.json",
  [string]$ContextPath = "$PSScriptRoot\..\evidence\evaluations\context-current.json",
  [string]$ReadmePath = "$PSScriptRoot\..\README.md",
  [string]$InstallPath = "$PSScriptRoot\..\install.ps1",
  [string]$ReleaseNotesPath = "$PSScriptRoot\..\docs\releases\v1.2.0-vnext.md"
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

foreach ($path in @($ReportPath,$RegistryPath,$Phase16Path,$ComparativeResultPath,$CasesPath,$ContextPath,$ReadmePath,$InstallPath,$ReleaseNotesPath)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Missing Phase 17 input: $path" }
}

$report = Get-Content -LiteralPath $ReportPath -Raw | ConvertFrom-Json
$registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
$phase16 = Get-Content -LiteralPath $Phase16Path -Raw | ConvertFrom-Json
$comparison = Get-Content -LiteralPath $ComparativeResultPath -Raw | ConvertFrom-Json
$cases = Get-Content -LiteralPath $CasesPath -Raw | ConvertFrom-Json
$context = Get-Content -LiteralPath $ContextPath -Raw | ConvertFrom-Json
$readme = Get-Content -LiteralPath $ReadmePath -Raw
$install = Get-Content -LiteralPath $InstallPath -Raw
$releaseNotes = Get-Content -LiteralPath $ReleaseNotesPath -Raw

if ([int]$report.schema_version -ne 1) { $errors.Add("Phase 17 report schema_version must be 1") }
if ([string]$report.phase -ne "17") { $errors.Add("Phase 17 report must identify phase 17") }
if ([string]$report.generated_on -ne "2026-10-01") { $errors.Add("Phase 17 generated_on must be 2026-10-01") }
if ([string]$report.target_version -ne "1.2.0") { $errors.Add("Phase 17 target_version must be 1.2.0") }
if ([string]$report.tag_name -ne "v1.2.0") { $errors.Add("Phase 17 tag_name must be v1.2.0") }
if (-not [bool]$report.release_ready) { $errors.Add("Phase 17 release_ready must be true") }
if ([string]$report.release_state -ne "READY_FOR_FINAL_PR_CI_AND_TAG") { $errors.Add("Phase 17 release_state must be READY_FOR_FINAL_PR_CI_AND_TAG") }
if ([string]$registry.version -ne "1.2.0") { $errors.Add("REGISTRY.version must be 1.2.0 for this release") }

if ([string]$phase16.completion_state -ne "COMPLETE" -or [string]$phase16.split -ne "16B" -or [string]$phase16.locked_on -ne "2026-10-01") {
  $errors.Add("Phase 16 must be COMPLETE/16B and locked on 2026-10-01 before release")
}

$criteria = @($report.criteria)
if ($criteria.Count -ne 20) { $errors.Add("Phase 17 report must contain exactly 20 acceptance criteria") }
$ids = @($criteria | ForEach-Object { [string]$_.id })
Assert-ExactSet -Actual $ids -Expected @(1..20 | ForEach-Object { [string]$_ }) -Label "acceptance criterion ids"
foreach ($criterion in $criteria) {
  $id = [int]$criterion.id
  $status = [string]$criterion.status
  if ($status -notin @("PASS","FAIL","NOT_RUN")) { $errors.Add("criterion ${id}: invalid status '$status'") }
  if ($status -ne "PASS") { $errors.Add("criterion ${id}: release-ready report requires PASS, observed '$status'") }
  if ([string]::IsNullOrWhiteSpace([string]$criterion.criterion)) { $errors.Add("criterion ${id}: criterion text is required") }
  if (@($criterion.evidence).Count -eq 0 -or @($criterion.evidence | Where-Object { [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) {
    $errors.Add("criterion ${id}: non-empty evidence entries are required")
  }
  foreach ($entry in @($criterion.evidence)) {
    if ([string]$entry -match "(?i)\b(TODO|PENDING|TBD)\b") { $errors.Add("criterion ${id}: evidence contains placeholder text") }
  }
}

if ([int]$report.acceptance_summary.pass -ne 20 -or
    [int]$report.acceptance_summary.fail -ne 0 -or
    [int]$report.acceptance_summary.not_run -ne 0 -or
    [int]$report.acceptance_summary.total -ne 20) {
  $errors.Add("acceptance_summary must be 20 PASS / 0 FAIL / 0 NOT_RUN / total 20")
}

if ([string]$report.version_semantics.selected_bump -ne "MINOR") { $errors.Add("v1.2.0 release must record MINOR bump semantics") }
if ([string]$report.version_semantics.tag_policy -notmatch "required CI is green") { $errors.Add("tag policy must require green CI") }

if ([int]$comparison.schema_version -ne 2 -or [string]$comparison.evaluation_type -ne "behavioral_execution") {
  $errors.Add("Phase 17 comparative result must be behavioral_execution schema_version 2")
}
$matched = @($comparison.results | Where-Object { [string]$_.case_id -eq "phase17-supply-chain-comparison" })
if ($matched.Count -ne 2) { $errors.Add("Phase 17 comparison must contain exactly two matched treatment results") }
Assert-ExactSet -Actual @($matched | ForEach-Object { [string]$_.variant }) -Expected @("no_skills","selected_skills") -Label "Phase 17 comparison variants"
foreach ($result in $matched) {
  if ([string]$result.execution_status -ne "COMPLETED") { $errors.Add("Phase 17 matched treatments must both be COMPLETED") }
  if ([string]$result.execution.model -ne "gpt-5.6-sol") { $errors.Add("Phase 17 matched treatments must record model gpt-5.6-sol") }
  if ([string]$result.execution.repository_ref -ne "962461d4af23296d145da7de6d9bf389ec9f8d07") {
    $errors.Add("Phase 17 matched treatments must use the locked Phase 16 baseline ref")
  }
  foreach ($criterionName in @("mutable_input_identified","trust_layers_separated","verification_boundary_defined","scope_limit_preserved")) {
    if ($result.criteria.$criterionName -isnot [bool] -or -not [bool]$result.criteria.$criterionName) {
      $errors.Add("Phase 17 $($result.variant) treatment must pass criterion '$criterionName'")
    }
    if ([string]::IsNullOrWhiteSpace([string]$result.evidence.$criterionName)) {
      $errors.Add("Phase 17 $($result.variant) treatment requires evidence for '$criterionName'")
    }
  }
}
$noSkill = @($matched | Where-Object { $_.variant -eq "no_skills" })
$selected = @($matched | Where-Object { $_.variant -eq "selected_skills" })
if ($noSkill.Count -eq 1 -and @($noSkill[0].skills_loaded).Count -ne 0) { $errors.Add("no_skills treatment must load zero skills") }
if ($selected.Count -eq 1) {
  Assert-ExactSet -Actual @($selected[0].skills_loaded | ForEach-Object { [string]$_ }) -Expected @("software-supply-chain-integrity") -Label "selected treatment skills"
}
if ([string]$comparison.comparison_claim -notmatch "does not show measured criterion uplift") {
  $errors.Add("Phase 17 comparative claim must explicitly avoid an uplift claim")
}
if ([string]$report.comparative_behavior.outcome -ne "NO_MEASURED_CRITERION_UPLIFT") {
  $errors.Add("Release report must preserve no-measured-uplift comparison outcome")
}
if ([string]$report.comparative_behavior.claim_limit -notmatch "remains incubating / UNPROVEN / evidence_tier none") {
  $errors.Add("Release report must preserve comparative non-promotion boundary")
}

$case = @($cases.cases | Where-Object { [string]$_.id -eq "phase17-supply-chain-comparison" })
if ($case.Count -ne 1) { $errors.Add("Phase 17 comparative case must exist exactly once") }
$contextRows = @($context.comparisons | Where-Object { [string]$_.case_id -eq "phase17-supply-chain-comparison" })
if ($contextRows.Count -ne 1) { $errors.Add("Current context benchmark must include the Phase 17 comparative case") }

foreach ($needle in @(
  "Current suite release: **v1.2.0**",
  "PowerShell Core 7+",
  "pwsh -NoProfile -File .\install.ps1",
  "docs/releases/v1.2.0-vnext.md",
  "evidence/releases/v1.2.0-vnext-acceptance-2026-10-01.json"
)) {
  if (-not $readme.Contains($needle)) { $errors.Add("README missing release/runtime statement: $needle") }
}
if ($readme -match "powershell -ExecutionPolicy Bypass -File \.\\install\.ps1") {
  $errors.Add("README must not recommend Windows PowerShell 5.1-style installer invocation")
}

if ($install -notmatch 'PSEdition -ne "Core"' -or
    $install -notmatch 'PSVersion\.Major -lt 7' -or
    $install -notmatch 'requires PowerShell Core 7\+') {
  $errors.Add("install.ps1 must fail fast outside PowerShell Core 7+")
}

if ($releaseNotes -notmatch "v1\.2\.0" -or
    $releaseNotes -notmatch "20 PASS / 0 FAIL / 0 NOT RUN" -or
    $releaseNotes -notmatch "no measured criterion uplift") {
  $errors.Add("v1.2.0 release notes must preserve version, acceptance target, and comparative limitation")
}

if ([string]$report.optional_local_smoke.installer_smoke -ne "NOT_RUN_SUPPORTED_RUNTIME") {
  $errors.Add("Optional local smoke must preserve unsupported-runtime NOT_RUN until a pwsh 7+ local run exists")
}
if ([string]$report.optional_local_smoke.reason -notmatch "does not have pwsh/PowerShell Core 7\+") {
  $errors.Add("Optional local smoke must explain missing local pwsh 7+")
}
if ([string]$report.external_execution_notes.openai_api_comparison_attempt -ne "NOT_RUN") {
  $errors.Add("Failed OpenAI API attempt must remain NOT_RUN")
}

foreach ($e in $errors) { Write-Output "[FAIL] $e" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] Phase 17 release report, version semantics, matched behavioral comparison, runtime truthfulness, and Phase 16 dependency are aligned"
}
Write-Output ("PHASE17_RELEASE VERSION={0} CRITERIA={1} PASS={2} FAIL={3} NOT_RUN={4} RELEASE_READY={5} ERRORS={6}" -f [string]$report.target_version,$criteria.Count,[int]$report.acceptance_summary.pass,[int]$report.acceptance_summary.fail,[int]$report.acceptance_summary.not_run,[bool]$report.release_ready,$errors.Count)
if ($errors.Count -gt 0) { exit 1 }
exit 0

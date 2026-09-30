param(
  [string]$CasesPath = "$PSScriptRoot\..\evidence\evaluations\cases.json",
  [string]$ResultsRoot = "$PSScriptRoot\..\evidence\evaluations\results"
)

$ErrorActionPreference = "Stop"

$casesDoc = Get-Content $CasesPath -Raw | ConvertFrom-Json
$caseById = @{}
foreach ($case in $casesDoc.cases) {
  $id = [string]$case.id
  if ([string]::IsNullOrWhiteSpace($id)) { throw "Evaluation case has empty id" }
  if ($caseById.ContainsKey($id)) { throw "Duplicate evaluation case id: $id" }
  $caseById[$id] = $case
}

$passCount = 0
$failCount = 0
$notRunCount = 0
$schemaErrors = New-Object System.Collections.Generic.List[string]

Get-ChildItem $ResultsRoot -File -Filter "*.json" | Sort-Object Name | ForEach-Object {
  $doc = Get-Content $_.FullName -Raw | ConvertFrom-Json
  foreach ($result in $doc.results) {
    $caseId = [string]$result.case_id
    $variant = [string]$result.variant
    $executionStatus = [string]$result.execution_status

    if (-not $caseById.ContainsKey($caseId)) {
      $schemaErrors.Add("$($_.Name): unknown case_id '$caseId'")
      continue
    }
    if ([string]::IsNullOrWhiteSpace($variant)) {
      $schemaErrors.Add("$($_.Name): empty variant for '$caseId'")
      continue
    }
    if ($executionStatus -eq "NOT_RUN") {
      $notRunCount++
      Write-Output "[NOT RUN] $caseId / $variant"
      continue
    }
    if ($executionStatus -ne "COMPLETED") {
      $schemaErrors.Add("$($_.Name): invalid execution_status '$executionStatus' for '$caseId'")
      continue
    }

    $case = $caseById[$caseId]
    $resultPass = $true
    foreach ($criterion in $case.acceptance_criteria) {
      $criterionId = [string]$criterion.id
      $criterionProperty = $result.criteria.PSObject.Properties[$criterionId]
      $evidenceProperty = $result.evidence.PSObject.Properties[$criterionId]

      if ($null -eq $criterionProperty -or $criterionProperty.Value -isnot [bool]) {
        $schemaErrors.Add("$($_.Name): missing boolean criterion '$criterionId' for '$caseId/$variant'")
        $resultPass = $false
        continue
      }
      if ($null -eq $evidenceProperty -or [string]::IsNullOrWhiteSpace([string]$evidenceProperty.Value)) {
        $schemaErrors.Add("$($_.Name): missing evidence for '$criterionId' in '$caseId/$variant'")
        $resultPass = $false
        continue
      }
      if (-not [bool]$criterionProperty.Value) { $resultPass = $false }
    }

    if ($resultPass) {
      $passCount++
      Write-Output "[PASS] $caseId / $variant"
    } else {
      $failCount++
      Write-Output "[FAIL] $caseId / $variant"
    }
  }
}

foreach ($errorItem in $schemaErrors) { Write-Output "[ERROR] $errorItem" }
Write-Output ("EVAL PASS={0} FAIL={1} NOT_RUN={2} SCHEMA_ERRORS={3}" -f $passCount,$failCount,$notRunCount,$schemaErrors.Count)

if ($schemaErrors.Count -gt 0) { exit 1 }
exit 0

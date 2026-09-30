param(
  [string]$CasesPath = "$PSScriptRoot\..\evidence\evaluations\router-cases.json",
  [string]$ResultsPath = "$PSScriptRoot\..\evidence\evaluations\router-results-current.json"
)

$ErrorActionPreference = "Stop"

$casesDoc = Get-Content $CasesPath -Raw | ConvertFrom-Json
$resultsDoc = Get-Content $ResultsPath -Raw | ConvertFrom-Json

$errors = New-Object System.Collections.Generic.List[string]
$caseById = @{}
$resultById = @{}

if (@($casesDoc.cases).Count -lt 5) {
  $errors.Add("Router evaluation requires at least five cases")
}

foreach ($case in $casesDoc.cases) {
  $id = [string]$case.id
  if ([string]::IsNullOrWhiteSpace($id)) {
    $errors.Add("Router case has empty id")
    continue
  }
  if ($caseById.ContainsKey($id)) {
    $errors.Add("Duplicate router case id: $id")
    continue
  }
  $caseById[$id] = $case
}

foreach ($result in $resultsDoc.results) {
  $id = [string]$result.case_id
  if (-not $caseById.ContainsKey($id)) {
    $errors.Add("Unknown router result case_id: $id")
    continue
  }
  if ($resultById.ContainsKey($id)) {
    $errors.Add("Duplicate router result case_id: $id")
    continue
  }
  $resultById[$id] = $result
}

foreach ($id in $caseById.Keys) {
  if (-not $resultById.ContainsKey($id)) {
    $errors.Add("Missing router result for case: $id")
    continue
  }

  $case = $caseById[$id]
  $result = $resultById[$id]
  $selected = @($result.selected | ForEach-Object { [string]$_ })
  $required = @($case.required | ForEach-Object { [string]$_ })
  $allowed = @($case.allowed | ForEach-Object { [string]$_ })
  $forbidden = @($case.forbidden | ForEach-Object { [string]$_ })

  if (@($selected | Sort-Object -Unique).Count -ne $selected.Count) {
    $errors.Add("$id: selected skills contain duplicates")
  }

  foreach ($skill in $required) {
    if ($selected -notcontains $skill) {
      $errors.Add("$id: required skill missing -> $skill")
    }
  }

  foreach ($skill in $selected) {
    if ($allowed -notcontains $skill) {
      $errors.Add("$id: selected skill outside allowed set -> $skill")
    }
  }

  foreach ($skill in $forbidden) {
    if ($selected -contains $skill) {
      $errors.Add("$id: forbidden skill selected -> $skill")
    }
  }

  if ($selected.Count -gt [int]$case.max_selected) {
    $errors.Add("$id: selected $($selected.Count) skills; max_selected is $($case.max_selected)")
  }

  if (($id.StartsWith("generic-") -or $id -eq "unrelated-readme-edit") -and
      $selected -contains "growthops-engineering") {
    $errors.Add("$id: GrowthOps project router leaked into a generic/unrelated case")
  }

  if (-not $errors.Where({ $_ -like "$id:*" })) {
    Write-Output "[PASS] $id -> $($selected -join ', ')"
  }
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
Write-Output ("ROUTER CASES={0} RESULTS={1} FAIL={2}" -f $caseById.Count,$resultById.Count,$errors.Count)

if ($errors.Count -gt 0) { exit 1 }
exit 0

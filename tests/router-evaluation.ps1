param(
  [string]$CasesPath = "$PSScriptRoot\..\evidence\evaluations\router-cases.json",
  [string]$ResultsPath = "$PSScriptRoot\..\evidence\evaluations\router-results-current.json",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [int]$MinimumCases = 5
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

if (-not (Test-Path $CasesPath)) { throw "Missing router cases: $CasesPath" }
if (-not (Test-Path $ResultsPath)) { throw "Missing router selections: $ResultsPath" }
if (-not (Test-Path $RegistryPath)) { throw "Missing registry: $RegistryPath" }
if ($MinimumCases -lt 1) { throw "MinimumCases must be at least 1" }

$casesDoc = Get-Content $CasesPath -Raw | ConvertFrom-Json
$resultsDoc = Get-Content $ResultsPath -Raw | ConvertFrom-Json
$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json

$errors = New-Object System.Collections.Generic.List[string]
$caseById = @{}
$selectionById = @{}
$kindBySkill = @{}
$registeredSkills = New-Object System.Collections.Generic.HashSet[string]
$projectSkills = New-Object System.Collections.Generic.List[string]

foreach ($entry in @($registry.skills)) {
  $name = [string]$entry.name
  $kind = [string]$entry.kind

  if ([string]::IsNullOrWhiteSpace($name)) {
    $errors.Add("Registry contains empty skill name")
    continue
  }
  if (-not $registeredSkills.Add($name)) {
    $errors.Add("Duplicate registry skill name: $name")
    continue
  }
  if ($kind -notin @("generic","project")) {
    $errors.Add("Registry skill '$name' has unsupported kind '$kind'")
    continue
  }

  $kindBySkill[$name] = $kind
  if ($kind -eq "project") {
    $projectSkills.Add($name)
  }
}

if ([int]$casesDoc.schema_version -ne 2) {
  $errors.Add("Unsupported router case schema_version '$($casesDoc.schema_version)'; expected 2")
}
if ($null -eq $casesDoc.cases) {
  $errors.Add("Router cases collection is required")
} elseif (@($casesDoc.cases).Count -lt $MinimumCases) {
  $errors.Add("Router evaluation requires at least $MinimumCases cases")
}

if ([int]$resultsDoc.schema_version -ne 2) {
  $errors.Add("Unsupported router selection schema_version '$($resultsDoc.schema_version)'; expected 2")
}
if ([string]$resultsDoc.evaluation_type -ne "documented_router_contract") {
  $errors.Add("Router selection evaluation_type must be 'documented_router_contract'")
}
if ([string]$resultsDoc.runtime_obedience -ne "NOT_RUN") {
  $errors.Add("Router runtime_obedience must remain NOT_RUN for this static contract artifact")
}
if ([string]::IsNullOrWhiteSpace([string]$resultsDoc.claim_limit)) {
  $errors.Add("Router selection artifact requires non-empty claim_limit")
}
foreach ($runtimeField in @("execution","runtime","model","executed_at","run_id")) {
  if ($null -ne $resultsDoc.PSObject.Properties[$runtimeField]) {
    $errors.Add("Router static contract artifact must not contain runtime field '$runtimeField'")
  }
}
if ($null -eq $resultsDoc.selections) {
  $errors.Add("Router selections collection is required")
}

foreach ($case in @($casesDoc.cases)) {
  $id = [string]$case.id
  if ([string]::IsNullOrWhiteSpace($id)) {
    $errors.Add("Router case has empty id")
    continue
  }
  if ($caseById.ContainsKey($id)) {
    $errors.Add("Duplicate router case id: $id")
    continue
  }

  if ([string]::IsNullOrWhiteSpace([string]$case.task)) {
    $errors.Add("${id}: task is required")
  }

  $scope = [string]$case.scope
  if ($scope -notin @("generic","unrelated","project")) {
    $errors.Add("${id}: invalid scope '$scope'")
  }

  $selectionMode = [string]$case.selection_mode
  if ($selectionMode -ne "exact_required") {
    $errors.Add("${id}: selection_mode must be 'exact_required'")
  }

  foreach ($field in @("required","allowed","forbidden")) {
    if ($null -eq $case.PSObject.Properties[$field]) {
      $errors.Add("${id}: $field collection is required")
    }
  }

  $required = Get-StringArray $case.required
  $allowed = Get-StringArray $case.allowed
  $forbidden = Get-StringArray $case.forbidden

  foreach ($pair in @(
    @{ label = "required"; values = $required },
    @{ label = "allowed"; values = $allowed },
    @{ label = "forbidden"; values = $forbidden }
  )) {
    if (@($pair.values | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
      $errors.Add("${id}: $($pair.label) contains an empty skill name")
    }
    if (@($pair.values | Sort-Object -Unique).Count -ne $pair.values.Count) {
      $errors.Add("${id}: $($pair.label) contains duplicates")
    }
    foreach ($skill in $pair.values) {
      if (-not $registeredSkills.Contains($skill)) {
        $errors.Add("${id}: $($pair.label) references unregistered skill '$skill'")
      }
    }
  }

  foreach ($skill in $required) {
    if ($allowed -notcontains $skill) {
      $errors.Add("${id}: required skill is not allowed -> $skill")
    }
    if ($forbidden -contains $skill) {
      $errors.Add("${id}: required skill is also forbidden -> $skill")
    }
  }
  foreach ($skill in $allowed) {
    if ($forbidden -contains $skill) {
      $errors.Add("${id}: allowed skill is also forbidden -> $skill")
    }
  }

  if ($null -eq $case.PSObject.Properties["max_selected"]) {
    $errors.Add("${id}: max_selected is required")
    $maxSelected = -1
  } else {
    $maxSelected = [int]$case.max_selected
    if ($maxSelected -lt 0) {
      $errors.Add("${id}: max_selected must be non-negative")
    }
  }

  if ($selectionMode -eq "exact_required" -and $maxSelected -ne $required.Count) {
    $errors.Add("${id}: exact_required max_selected must equal required skill count")
  }

  if ($scope -eq "generic") {
    foreach ($skill in @($required + $allowed)) {
      if ($kindBySkill.ContainsKey($skill) -and [string]$kindBySkill[$skill] -eq "project") {
        $errors.Add("${id}: generic case cannot require/allow project skill '$skill'")
      }
    }
    foreach ($projectSkill in $projectSkills) {
      if ($forbidden -notcontains $projectSkill) {
        $errors.Add("${id}: generic case must explicitly forbid project skill '$projectSkill'")
      }
    }
  }

  if ($scope -eq "unrelated") {
    if ($required.Count -ne 0 -or $allowed.Count -ne 0 -or $maxSelected -ne 0) {
      $errors.Add("${id}: unrelated case must require/allow zero skills with max_selected 0")
    }
    if (-not (Test-SameStringSet -Actual $forbidden -Expected @($registeredSkills | ForEach-Object { [string]$_ }))) {
      $errors.Add("${id}: unrelated case must forbid every registered skill")
    }
  }

  if ($scope -eq "project") {
    $requiredProjectSkills = @($required | Where-Object {
      $kindBySkill.ContainsKey($_) -and [string]$kindBySkill[$_] -eq "project"
    })
    if ($requiredProjectSkills.Count -eq 0) {
      $errors.Add("${id}: project case must require at least one project skill")
    }
  }

  $caseById[$id] = $case
}

foreach ($selection in @($resultsDoc.selections)) {
  $id = [string]$selection.case_id
  if ([string]::IsNullOrWhiteSpace($id)) {
    $errors.Add("Router selection has empty case_id")
    continue
  }
  if (-not $caseById.ContainsKey($id)) {
    $errors.Add("Unknown router selection case_id: $id")
    continue
  }
  if ($selectionById.ContainsKey($id)) {
    $errors.Add("Duplicate router selection case_id: $id")
    continue
  }
  if ($null -eq $selection.PSObject.Properties["selected"]) {
    $errors.Add("${id}: selected collection is required")
    continue
  }

  $selected = Get-StringArray $selection.selected
  if (@($selected | Sort-Object -Unique).Count -ne $selected.Count) {
    $errors.Add("${id}: selected skills contain duplicates")
  }
  foreach ($skill in $selected) {
    if (-not $registeredSkills.Contains($skill)) {
      $errors.Add("${id}: selected unregistered skill -> $skill")
    }
  }

  $selectionById[$id] = $selection
}

foreach ($id in $caseById.Keys) {
  if (-not $selectionById.ContainsKey($id)) {
    $errors.Add("Missing router selection for case: $id")
    continue
  }

  $case = $caseById[$id]
  $selection = $selectionById[$id]
  $selected = Get-StringArray $selection.selected
  $required = Get-StringArray $case.required
  $allowed = Get-StringArray $case.allowed
  $forbidden = Get-StringArray $case.forbidden
  $scope = [string]$case.scope

  foreach ($skill in $required) {
    if ($selected -notcontains $skill) {
      $errors.Add("${id}: required skill missing -> $skill")
    }
  }
  foreach ($skill in $selected) {
    if ($allowed -notcontains $skill) {
      $errors.Add("${id}: selected skill outside allowed set -> $skill")
    }
  }
  foreach ($skill in $forbidden) {
    if ($selected -contains $skill) {
      $errors.Add("${id}: forbidden skill selected -> $skill")
    }
  }

  if ($selected.Count -gt [int]$case.max_selected) {
    $errors.Add("${id}: selected $($selected.Count) skills; max_selected is $($case.max_selected)")
  }

  if ([string]$case.selection_mode -eq "exact_required" -and -not (Test-SameStringSet -Actual $selected -Expected $required)) {
    $errors.Add("${id}: exact_required selection must exactly match required skills")
  }

  if ($scope -in @("generic","unrelated")) {
    foreach ($skill in $selected) {
      if ($kindBySkill.ContainsKey($skill) -and [string]$kindBySkill[$skill] -eq "project") {
        $errors.Add("${id}: project-specific skill leaked into $scope case -> $skill")
      }
    }
  }

  if (-not $errors.Where({ $_ -like "${id}:*" })) {
    $display = if ($selected.Count -eq 0) { "<none>" } else { $selected -join ", " }
    Write-Output "[PASS] $id [$scope] -> $display"
  }
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
Write-Output ("ROUTER CASES={0} SELECTIONS={1} FAIL={2} RUNTIME_OBEDIENCE={3}" -f $caseById.Count,$selectionById.Count,$errors.Count,[string]$resultsDoc.runtime_obedience)

if ($errors.Count -gt 0) { exit 1 }
exit 0

param(
  [string]$CasesPath = "$PSScriptRoot\..\evidence\evaluations\cases.json",
  [string]$FixturesPath = "$PSScriptRoot\..\evidence\evaluations\fixtures.json",
  [string]$ResultsRoot = "$PSScriptRoot\..\evidence\evaluations\results",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json"
)

$ErrorActionPreference = "Stop"

function Get-PropertyNames {
  param([object]$Object)
  if ($null -eq $Object) { return @() }
  return @($Object.PSObject.Properties.Name)
}

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

function Test-IsoTimestamp {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
  $parsed = [DateTimeOffset]::MinValue
  return [DateTimeOffset]::TryParse($Value, [ref]$parsed)
}

$schemaErrors = New-Object System.Collections.Generic.List[string]
$passCount = 0
$failCount = 0
$notRunCount = 0

if (-not (Test-Path $CasesPath)) { throw "Missing evaluation cases: $CasesPath" }
if (-not (Test-Path $FixturesPath)) { throw "Missing evaluation fixtures: $FixturesPath" }
if (-not (Test-Path $ResultsRoot)) { throw "Missing evaluation results root: $ResultsRoot" }
if (-not (Test-Path $RegistryPath)) { throw "Missing registry: $RegistryPath" }

$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
$registeredSkills = New-Object System.Collections.Generic.HashSet[string]
$genericSkills = New-Object System.Collections.Generic.List[string]
foreach ($entry in @($registry.skills)) {
  $skillName = [string]$entry.name
  if (-not [string]::IsNullOrWhiteSpace($skillName)) {
    [void]$registeredSkills.Add($skillName)
    if ([string]$entry.kind -eq "generic") {
      $genericSkills.Add($skillName)
    }
  }
}

$fixturesDoc = Get-Content $FixturesPath -Raw | ConvertFrom-Json
if ([int]$fixturesDoc.schema_version -ne 1) {
  $schemaErrors.Add("Unsupported evaluation fixture schema_version '$($fixturesDoc.schema_version)'; expected 1")
}

$fixtureById = @{}
foreach ($fixture in @($fixturesDoc.fixtures)) {
  $fixtureId = [string]$fixture.id
  $fixtureCaseId = [string]$fixture.case_id

  if ([string]::IsNullOrWhiteSpace($fixtureId)) {
    $schemaErrors.Add("Evaluation fixture has empty id")
    continue
  }
  if ($fixtureById.ContainsKey($fixtureId)) {
    $schemaErrors.Add("Duplicate evaluation fixture id: $fixtureId")
    continue
  }
  if ([string]::IsNullOrWhiteSpace($fixtureCaseId)) {
    $schemaErrors.Add("Evaluation fixture '$fixtureId' has empty case_id")
  }
  if ([string]::IsNullOrWhiteSpace([string]$fixture.description)) {
    $schemaErrors.Add("Evaluation fixture '$fixtureId' has empty description")
  }
  if ($fixture.initial_state -isnot [System.Management.Automation.PSCustomObject] -or (Get-PropertyNames $fixture.initial_state).Count -eq 0) {
    $schemaErrors.Add("Evaluation fixture '$fixtureId' requires non-empty initial_state object")
  }
  $constraints = @($fixture.constraints | ForEach-Object { [string]$_ })
  if ($constraints.Count -eq 0 -or @($constraints | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
    $schemaErrors.Add("Evaluation fixture '$fixtureId' requires non-empty constraints")
  }

  $fixtureById[$fixtureId] = $fixture
}

$casesDoc = Get-Content $CasesPath -Raw | ConvertFrom-Json
if ([int]$casesDoc.schema_version -ne 2) {
  $schemaErrors.Add("Unsupported evaluation case schema_version '$($casesDoc.schema_version)'; expected 2")
}

$caseById = @{}
$usedFixtureIds = New-Object System.Collections.Generic.HashSet[string]
$allowedVariantVocabulary = @("no_skills","selected_skills","all_generic_skills")

foreach ($case in @($casesDoc.cases)) {
  $id = [string]$case.id
  if ([string]::IsNullOrWhiteSpace($id)) {
    $schemaErrors.Add("Evaluation case has empty id")
    continue
  }
  if ($caseById.ContainsKey($id)) {
    $schemaErrors.Add("Duplicate evaluation case id: $id")
    continue
  }

  if ([string]::IsNullOrWhiteSpace([string]$case.task)) {
    $schemaErrors.Add("Evaluation case '$id' has empty task")
  }

  $fixtureId = [string]$case.fixture_id
  if ([string]::IsNullOrWhiteSpace($fixtureId) -or -not $fixtureById.ContainsKey($fixtureId)) {
    $schemaErrors.Add("Evaluation case '$id' references unknown fixture_id '$fixtureId'")
  } else {
    [void]$usedFixtureIds.Add($fixtureId)
    if ([string]$fixtureById[$fixtureId].case_id -ne $id) {
      $schemaErrors.Add("Evaluation fixture '$fixtureId' belongs to case '$($fixtureById[$fixtureId].case_id)', not '$id'")
    }
  }

  $variants = @($case.allowed_variants | ForEach-Object { [string]$_ })
  if ($variants.Count -eq 0) {
    $schemaErrors.Add("Evaluation case '$id' requires at least one allowed_variant")
  }
  if (($variants | Sort-Object -Unique).Count -ne $variants.Count) {
    $schemaErrors.Add("Evaluation case '$id' has duplicate allowed_variants")
  }
  foreach ($variant in $variants) {
    if ($variant -notin $allowedVariantVocabulary) {
      $schemaErrors.Add("Evaluation case '$id' has invalid variant '$variant'")
    }
  }

  $recommendedSkills = @($case.recommended_skills | ForEach-Object { [string]$_ })
  if ($recommendedSkills.Count -eq 0) {
    $schemaErrors.Add("Evaluation case '$id' requires at least one recommended_skill")
  }
  if (($recommendedSkills | Sort-Object -Unique).Count -ne $recommendedSkills.Count) {
    $schemaErrors.Add("Evaluation case '$id' has duplicate recommended_skills")
  }
  foreach ($skillName in $recommendedSkills) {
    if (-not $registeredSkills.Contains($skillName)) {
      $schemaErrors.Add("Evaluation case '$id' references unknown recommended skill '$skillName'")
    }
  }

  $criteria = @($case.acceptance_criteria)
  if ($criteria.Count -eq 0) {
    $schemaErrors.Add("Evaluation case '$id' requires acceptance_criteria")
  }
  $criterionIds = New-Object System.Collections.Generic.HashSet[string]
  foreach ($criterion in $criteria) {
    $criterionId = [string]$criterion.id
    if ([string]::IsNullOrWhiteSpace($criterionId)) {
      $schemaErrors.Add("Evaluation case '$id' has empty criterion id")
      continue
    }
    if (-not $criterionIds.Add($criterionId)) {
      $schemaErrors.Add("Evaluation case '$id' has duplicate criterion id '$criterionId'")
    }
    if ([string]::IsNullOrWhiteSpace([string]$criterion.description)) {
      $schemaErrors.Add("Evaluation case '$id' criterion '$criterionId' has empty description")
    }
  }

  $caseById[$id] = $case
}

foreach ($fixtureId in $fixtureById.Keys) {
  if (-not $usedFixtureIds.Contains($fixtureId)) {
    $schemaErrors.Add("Orphan evaluation fixture '$fixtureId' is not referenced by a case")
  }
}

$resultKeys = New-Object System.Collections.Generic.HashSet[string]
$resultCaseIds = New-Object System.Collections.Generic.HashSet[string]
$resultRecordCount = 0
$resultFiles = @(Get-ChildItem $ResultsRoot -File -Filter "*.json" | Sort-Object Name)
if ($resultFiles.Count -eq 0) {
  $schemaErrors.Add("Evaluation results root contains no JSON result files")
}

foreach ($resultFile in $resultFiles) {
  $doc = Get-Content $resultFile.FullName -Raw | ConvertFrom-Json
  if ([int]$doc.schema_version -ne 2) {
    $schemaErrors.Add("$($resultFile.Name): unsupported result schema_version '$($doc.schema_version)'; expected 2")
    continue
  }
  if ($null -eq $doc.results) {
    $schemaErrors.Add("$($resultFile.Name): results collection is required")
    continue
  }

  foreach ($result in @($doc.results)) {
    $caseId = [string]$result.case_id
    $variant = [string]$result.variant
    $executionStatus = [string]$result.execution_status

    if (-not $caseById.ContainsKey($caseId)) {
      $schemaErrors.Add("$($resultFile.Name): unknown case_id '$caseId'")
      continue
    }

    $case = $caseById[$caseId]
    $resultRecordCount++
    [void]$resultCaseIds.Add($caseId)

    $allowedVariants = @($case.allowed_variants | ForEach-Object { [string]$_ })
    if ([string]::IsNullOrWhiteSpace($variant) -or $variant -notin $allowedVariants) {
      $schemaErrors.Add("$($resultFile.Name): invalid variant '$variant' for '$caseId'")
      continue
    }

    $resultKey = "$caseId|$variant"
    if (-not $resultKeys.Add($resultKey)) {
      $schemaErrors.Add("$($resultFile.Name): duplicate result for '$caseId/$variant'")
      continue
    }

    if ($executionStatus -notin @("COMPLETED","NOT_RUN")) {
      $schemaErrors.Add("$($resultFile.Name): invalid execution_status '$executionStatus' for '$caseId/$variant'")
      continue
    }

    if ($null -eq $result.PSObject.Properties["skills_loaded"]) {
      $schemaErrors.Add("$($resultFile.Name): skills_loaded is required for '$caseId/$variant'")
    }
    $skillsLoaded = @($result.skills_loaded | ForEach-Object { [string]$_ })
    if (($skillsLoaded | Sort-Object -Unique).Count -ne $skillsLoaded.Count) {
      $schemaErrors.Add("$($resultFile.Name): duplicate skills_loaded for '$caseId/$variant'")
    }
    foreach ($skillName in $skillsLoaded) {
      if (-not $registeredSkills.Contains($skillName)) {
        $schemaErrors.Add("$($resultFile.Name): unknown loaded skill '$skillName' for '$caseId/$variant'")
      }
    }

    $criteriaObject = $result.criteria
    $evidenceObject = $result.evidence
    if ($criteriaObject -isnot [System.Management.Automation.PSCustomObject]) {
      $schemaErrors.Add("$($resultFile.Name): criteria must be an object for '$caseId/$variant'")
      continue
    }
    if ($evidenceObject -isnot [System.Management.Automation.PSCustomObject]) {
      $schemaErrors.Add("$($resultFile.Name): evidence must be an object for '$caseId/$variant'")
      continue
    }

    if ($executionStatus -eq "NOT_RUN") {
      if ($skillsLoaded.Count -ne 0) {
        $schemaErrors.Add("$($resultFile.Name): NOT_RUN '$caseId/$variant' must have empty skills_loaded")
      }
      if ((Get-PropertyNames $criteriaObject).Count -ne 0) {
        $schemaErrors.Add("$($resultFile.Name): NOT_RUN '$caseId/$variant' must have empty criteria")
      }
      if ((Get-PropertyNames $evidenceObject).Count -ne 0) {
        $schemaErrors.Add("$($resultFile.Name): NOT_RUN '$caseId/$variant' must have empty evidence")
      }
      $executionProperty = $result.PSObject.Properties["execution"]
      if ($null -ne $executionProperty -and $null -ne $executionProperty.Value) {
        $schemaErrors.Add("$($resultFile.Name): NOT_RUN '$caseId/$variant' must not contain execution provenance")
      }
      if ([string]::IsNullOrWhiteSpace([string]$result.notes)) {
        $schemaErrors.Add("$($resultFile.Name): NOT_RUN '$caseId/$variant' requires explanatory notes")
      }

      $notRunCount++
      Write-Output "[NOT RUN] $caseId / $variant"
      continue
    }

    if ($result.execution -isnot [System.Management.Automation.PSCustomObject]) {
      $schemaErrors.Add("$($resultFile.Name): COMPLETED '$caseId/$variant' requires execution provenance object")
      continue
    }

    foreach ($field in @("run_id","executed_at","runtime","model","repository","repository_ref")) {
      if ([string]::IsNullOrWhiteSpace([string]$result.execution.$field)) {
        $schemaErrors.Add("$($resultFile.Name): COMPLETED '$caseId/$variant' missing execution.$field")
      }
    }
    if (-not (Test-IsoTimestamp -Value ([string]$result.execution.executed_at))) {
      $schemaErrors.Add("$($resultFile.Name): COMPLETED '$caseId/$variant' execution.executed_at must be parseable ISO-8601")
    }

    $expectedSkills = @()
    switch ($variant) {
      "no_skills" {
        $expectedSkills = @()
      }
      "selected_skills" {
        $expectedSkills = @($case.recommended_skills | ForEach-Object { [string]$_ })
      }
      "all_generic_skills" {
        $expectedSkills = @($genericSkills)
      }
    }
    if (-not (Test-SameStringSet -Actual $skillsLoaded -Expected $expectedSkills)) {
      $schemaErrors.Add("$($resultFile.Name): skills_loaded does not match '$variant' treatment for '$caseId'")
    }

    $requiredCriterionIds = @($case.acceptance_criteria | ForEach-Object { [string]$_.id })
    $criteriaKeys = @(Get-PropertyNames $criteriaObject)
    $evidenceKeys = @(Get-PropertyNames $evidenceObject)

    if (-not (Test-SameStringSet -Actual $criteriaKeys -Expected $requiredCriterionIds)) {
      $schemaErrors.Add("$($resultFile.Name): criteria keys must exactly match case criteria for '$caseId/$variant'")
    }
    if (-not (Test-SameStringSet -Actual $evidenceKeys -Expected $requiredCriterionIds)) {
      $schemaErrors.Add("$($resultFile.Name): evidence keys must exactly match case criteria for '$caseId/$variant'")
    }

    $resultPass = $true
    foreach ($criterionId in $requiredCriterionIds) {
      $criterionProperty = $criteriaObject.PSObject.Properties[$criterionId]
      $evidenceProperty = $evidenceObject.PSObject.Properties[$criterionId]

      if ($null -eq $criterionProperty -or $criterionProperty.Value -isnot [bool]) {
        $schemaErrors.Add("$($resultFile.Name): missing boolean criterion '$criterionId' for '$caseId/$variant'")
        $resultPass = $false
        continue
      }
      if ($null -eq $evidenceProperty -or [string]::IsNullOrWhiteSpace([string]$evidenceProperty.Value)) {
        $schemaErrors.Add("$($resultFile.Name): missing evidence for '$criterionId' in '$caseId/$variant'")
        $resultPass = $false
        continue
      }
      if (-not [bool]$criterionProperty.Value) {
        $resultPass = $false
      }
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

if ($resultRecordCount -eq 0) {
  $schemaErrors.Add("Evaluation corpus contains no result records")
}
foreach ($caseId in $caseById.Keys) {
  if (-not $resultCaseIds.Contains($caseId)) {
    $schemaErrors.Add("Evaluation case '$caseId' has no result record")
  }
}

foreach ($errorItem in $schemaErrors) { Write-Output "[ERROR] $errorItem" }
Write-Output ("EVAL PASS={0} FAIL={1} NOT_RUN={2} SCHEMA_ERRORS={3}" -f $passCount,$failCount,$notRunCount,$schemaErrors.Count)

if ($schemaErrors.Count -gt 0) { exit 1 }
exit 0

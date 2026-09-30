param(
  [string]$SkillsRoot = "$PSScriptRoot\skills",
  [string]$RegistryPath = "$PSScriptRoot\REGISTRY.json",
  [string]$EvidenceIndexPath = "$PSScriptRoot\evidence\INDEX.json",
  [string]$ExpectTextHygieneFailurePath
)

$ErrorActionPreference = "Stop"

function Get-EvidenceTierRank {
  param([Parameter(Mandatory = $true)][string]$Tier)

  switch ($Tier) {
    "none" { return 0 }
    "observed" { return 1 }
    "repeated" { return 2 }
    "benchmarked" { return 3 }
    default { return -1 }
  }
}

function Get-TextHygieneIssues {
  param([Parameter(Mandatory = $true)][string]$Path)

  $issues = New-Object System.Collections.Generic.List[string]
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $issues.Add("UTF-8 BOM")
  }

  $text = [System.IO.File]::ReadAllText($Path)
  if ($text.Contains([char]0xFFFD)) {
    $issues.Add("Unicode replacement character U+FFFD")
  }

  # Build markers from code points so PowerShell never parses mojibake punctuation as source delimiters.
  # These are narrow signatures of common UTF-8 bytes decoded as Windows-1252/Latin-1 text.
  $mojibakeMarkers = @(
    ([string]([char]0x00E2) + [string]([char]0x2020)), # corrupted arrow-family prefix
    ([string]([char]0x00E2) + [string]([char]0x201D)), # corrupted box-drawing prefix
    ([string]([char]0x00E2) + [string]([char]0x20AC)), # corrupted quote/dash prefix
    ([string]([char]0x00C2) + [string]([char]0x00A0)), # corrupted NBSP sequence
    ([string]([char]0x00EF) + [string]([char]0x00BB) + [string]([char]0x00BF)), # BOM bytes decoded as text
    ([string]([char]0x00C3) + [string]([char]0x00A9)), # common corrupted accented-letter sequence
    ([string]([char]0x00C3) + [string]([char]0x00B1)), # common corrupted accented-letter sequence
    ([string]([char]0x00C3) + [string]([char]0x00BC)), # common corrupted accented-letter sequence
    ([string]([char]0x00F0) + [string]([char]0x0178))  # common corrupted emoji prefix
  )
  foreach ($marker in $mojibakeMarkers) {
    if ($text.Contains($marker)) {
      $issues.Add("common mojibake marker '$marker'")
      break
    }
  }

  return @($issues)
}

if (-not [string]::IsNullOrWhiteSpace($ExpectTextHygieneFailurePath)) {
  if (-not (Test-Path $ExpectTextHygieneFailurePath)) {
    throw "Missing text-hygiene fixture: $ExpectTextHygieneFailurePath"
  }
  $fixtureIssues = @(Get-TextHygieneIssues -Path $ExpectTextHygieneFailurePath)
  if ($fixtureIssues.Count -eq 0) {
    Write-Output "[FAIL] Expected text-hygiene fixture to be rejected"
    exit 1
  }
  Write-Output ("[PASS] Text-hygiene negative fixture rejected: {0}" -f ($fixtureIssues -join ", "))
  exit 0
}
$fail = New-Object System.Collections.Generic.List[string]
$warn = New-Object System.Collections.Generic.List[string]
$pass = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path $RegistryPath)) {
  $fail.Add("Missing registry: $RegistryPath")
} else {
  try {
    $registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
  } catch {
    $fail.Add("REGISTRY.json is not valid JSON: $($_.Exception.Message)")
  }
}

$evidenceRecordIds = New-Object System.Collections.Generic.HashSet[string]
$evidenceRecordsById = @{}
if (-not (Test-Path $EvidenceIndexPath)) {
  $fail.Add("Missing evidence index: $EvidenceIndexPath")
} else {
  try {
    $evidenceIndex = Get-Content $EvidenceIndexPath -Raw | ConvertFrom-Json

    if ([int]$evidenceIndex.schema_version -ne 1) {
      $fail.Add("Unsupported evidence index schema_version '$($evidenceIndex.schema_version)'; validator supports schema_version 1")
    }

    if ($null -eq $evidenceIndex.records) {
      $fail.Add("Evidence index: records is required")
    }

    $expectedEvidenceTiers = @("none","observed","repeated","benchmarked")
    if ($null -eq $evidenceIndex.evidence_tiers) {
      $fail.Add("Evidence index: evidence_tiers is required")
    } else {
      $declaredEvidenceTiers = @($evidenceIndex.evidence_tiers.PSObject.Properties.Name)
      if (
        @($declaredEvidenceTiers | Sort-Object).Count -ne $expectedEvidenceTiers.Count -or
        (Compare-Object ($declaredEvidenceTiers | Sort-Object) ($expectedEvidenceTiers | Sort-Object))
      ) {
        $fail.Add("Evidence index: evidence_tiers must declare exactly none, observed, repeated, benchmarked")
      }
      foreach ($tierName in $expectedEvidenceTiers) {
        if ([string]::IsNullOrWhiteSpace([string]$evidenceIndex.evidence_tiers.$tierName)) {
          $fail.Add("Evidence index: evidence_tiers.$tierName description is required")
        }
      }
    }

    foreach ($record in @($evidenceIndex.records)) {
      $recordId = [string]$record.id
      $recordType = [string]$record.type
      $claimState = [string]$record.claim_state

      if ([string]::IsNullOrWhiteSpace($recordId)) {
        $fail.Add("Evidence record has empty id")
        continue
      }
      if (-not $evidenceRecordIds.Add($recordId)) {
        $fail.Add("Duplicate evidence record id: $recordId")
        continue
      }

      $evidenceRecordsById[$recordId] = $record

      if ($recordType -notin @("observational","comparative")) {
        $fail.Add("Evidence record '$recordId': invalid type '$recordType'")
      }
      if ($claimState -notin @("VERIFIED","PARTIALLY_VERIFIED","UNPROVEN")) {
        $fail.Add("Evidence record '$recordId': invalid claim_state '$claimState'")
      }
      if ([string]::IsNullOrWhiteSpace([string]$record.claim)) {
        $fail.Add("Evidence record '$recordId': claim is required")
      }
      if ([string]::IsNullOrWhiteSpace([string]$record.does_not_claim)) {
        $fail.Add("Evidence record '$recordId': does_not_claim is required")
      }
      if ($null -eq $record.skill_observations) {
        $fail.Add("Evidence record '$recordId': skill_observations is required")
        continue
      }
      if ($record.skill_observations -isnot [System.Management.Automation.PSCustomObject]) {
        $fail.Add("Evidence record '$recordId': skill_observations must be an object mapping skill names to tiers")
        continue
      }

      foreach ($observation in $record.skill_observations.PSObject.Properties) {
        $observationTier = [string]$observation.Value
        if ($observationTier -notin @("observed","repeated","benchmarked")) {
          $fail.Add("Evidence record '$recordId': skill '$($observation.Name)' has invalid observation tier '$observationTier'")
        }
        if ($recordType -eq "observational" -and $observationTier -eq "benchmarked") {
          $fail.Add("Evidence record '$recordId': observational records cannot support benchmarked tier")
        }
      }
    }
  } catch {
    $fail.Add("Evidence index is not valid JSON: $($_.Exception.Message)")
  }
}

if ($fail.Count -eq 0) {
  if ([int]$registry.schema_version -lt 2) {
    $fail.Add("Registry schema_version must be at least 2 for evidence metadata")
  }

  $names = New-Object System.Collections.Generic.HashSet[string]
  $registryByName = @{}

  foreach ($entry in $registry.skills) {
    $name = [string]$entry.name
    $kind = [string]$entry.kind
    $status = [string]$entry.status
    $relativePath = [string]$entry.path

    if ([string]::IsNullOrWhiteSpace($name)) {
      $fail.Add("Registry entry has empty name")
      continue
    }

    if (-not $names.Add($name)) {
      $fail.Add("Duplicate registry skill name: $name")
    } else {
      $registryByName[$name] = $entry
    }

    if ($kind -notin @("generic","project")) {
      $fail.Add("$($name): invalid kind '$kind'")
    }

    if ($status -notin @("stable","incubating","reference","project")) {
      $fail.Add("$($name): invalid status '$status'")
    }

    if ($kind -eq "project" -and $status -ne "project") {
      $fail.Add("$($name): kind/status mismatch; project skills must use status 'project'")
    }
    if ($kind -eq "generic" -and $status -eq "project") {
      $fail.Add("$($name): kind/status mismatch; generic skills cannot use status 'project'")
    }

    $evidenceTier = [string]$entry.evidence_tier
    $evidenceRefs = @($entry.evidence_refs | ForEach-Object { [string]$_ })
    if ($evidenceTier -notin @("none","observed","repeated","benchmarked")) {
      $fail.Add("$($name): invalid evidence_tier '$evidenceTier'")
    }
    if (($evidenceRefs | Sort-Object -Unique).Count -ne $evidenceRefs.Count) {
      $fail.Add("$($name): duplicate evidence_refs are not allowed")
    }
    if ($evidenceTier -eq "none" -and $evidenceRefs.Count -gt 0) {
      $fail.Add("$($name): evidence_tier 'none' cannot have evidence_refs")
    }
    if ($evidenceTier -ne "none" -and $evidenceRefs.Count -eq 0) {
      $fail.Add("$($name): evidence_tier '$evidenceTier' requires at least one evidence_ref")
    }

    $supportedEvidenceTier = "none"
    foreach ($evidenceRef in $evidenceRefs) {
      if (-not $evidenceRecordIds.Contains($evidenceRef)) {
        $fail.Add("$($name): unknown evidence_ref '$evidenceRef'")
        continue
      }

      $record = $evidenceRecordsById[$evidenceRef]
      $observationProperty = $record.skill_observations.PSObject.Properties[$name]
      if ($null -eq $observationProperty) {
        continue
      }

      $observationTier = [string]$observationProperty.Value
      if ((Get-EvidenceTierRank -Tier $observationTier) -gt (Get-EvidenceTierRank -Tier $supportedEvidenceTier)) {
        $supportedEvidenceTier = $observationTier
      }
    }

    if (
      $evidenceTier -in @("observed","repeated","benchmarked") -and
      (Get-EvidenceTierRank -Tier $supportedEvidenceTier) -lt (Get-EvidenceTierRank -Tier $evidenceTier)
    ) {
      $fail.Add("$($name): evidence_tier '$evidenceTier' is not supported by referenced evidence (max supported: '$supportedEvidenceTier')")
    }

    $expectedRegistryPath = "skills/$name"
    if ($relativePath -ne $expectedRegistryPath) {
      $fail.Add("$($name): non-canonical registered path '$relativePath'; expected '$expectedRegistryPath'")
    }

    $dir = Join-Path $SkillsRoot $name
    if (-not (Test-Path $dir)) {
      $fail.Add("$($name): registered path missing -> $relativePath")
      continue
    }

    $skill = Join-Path $dir "SKILL.md"
    if (-not (Test-Path $skill)) {
      $fail.Add("$($name): missing SKILL.md")
      continue
    }

    $raw = Get-Content $skill -Raw
    $lines = Get-Content $skill

    $frontmatterMatch = [regex]::Match(
      $raw,
      '\A---\r?\n(?<frontmatter>[\s\S]*?)\r?\n---(?:\r?\n|$)'
    )

    if (-not $frontmatterMatch.Success) {
      $fail.Add("$($name): invalid YAML frontmatter block; expected opening and closing '---' delimiters")
    } else {
      $frontmatter = $frontmatterMatch.Groups["frontmatter"].Value
      if ($frontmatter -notmatch "(?m)^name:\s+$([regex]::Escape($name))\s*$") {
        $fail.Add("$($name): frontmatter name does not match registry/directory")
      }
      if ($frontmatter -notmatch "(?m)^description:\s+.+$") {
        $fail.Add("$($name): missing description in frontmatter")
      }
    }
    if ($lines.Count -gt 500) {
      $warn.Add("$($name): SKILL.md exceeds 500 lines ($($lines.Count))")
    } else {
      $pass.Add("$($name): SKILL.md size OK ($($lines.Count) lines)")
    }

    $refs = [regex]::Matches($raw, 'references/[A-Za-z0-9._/-]+\.md') |
      ForEach-Object { $_.Value } | Sort-Object -Unique

    foreach ($ref in $refs) {
      $refPath = Join-Path $dir ($ref -replace '/', '\')
      if (-not (Test-Path $refPath)) {
        $fail.Add("$($name): broken reference -> $ref")
      }
    }

    Get-ChildItem $dir -Recurse -File | ForEach-Object {
      $fileRaw = Get-Content $_.FullName -Raw
      $textIssues = @(Get-TextHygieneIssues -Path $_.FullName)
      foreach ($issue in $textIssues) {
        $fail.Add("$($name): $issue in $($_.FullName)")
      }
      if ($fileRaw -match "(?m)^\[Reading .+\]$" -or $fileRaw -match "(?m)^\[executed on device: .+\]$") {
        $fail.Add("$($name): tool-output contamination in $($_.FullName)")
      }
    }

    if ($kind -eq "generic") {
      $hits = Get-ChildItem $dir -Recurse -File |
        Select-String -Pattern "GrowthOps" -SimpleMatch -ErrorAction SilentlyContinue
      if ($hits) {
        $warn.Add("$($name): generic skill contains GrowthOps-specific text")
      }
    }
  }

  Get-ChildItem $SkillsRoot -Recurse -File -Filter "suite-manifest.json" -ErrorAction SilentlyContinue | ForEach-Object {
    $manifestPath = $_.FullName
    try {
      $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    } catch {
      $fail.Add("Invalid suite manifest JSON: $manifestPath")
      return
    }

    $manifestSkills = @($manifest.skills | ForEach-Object { [string]$_ })
    $genericSkills = @($manifest.generic | ForEach-Object { [string]$_ })
    $projectSkills = @($manifest.project_specific | ForEach-Object { [string]$_ })
    $partition = @($genericSkills + $projectSkills)

    if (($manifestSkills | Sort-Object -Unique).Count -ne $manifestSkills.Count) {
      $fail.Add("Suite manifest has duplicate skills: $manifestPath")
    }

    foreach ($skillName in $manifestSkills) {
      if (-not $registryByName.ContainsKey($skillName)) {
        $fail.Add("Suite manifest references unregistered skill '$skillName': $manifestPath")
      }
      if (@($partition | Where-Object { $_ -eq $skillName }).Count -ne 1) {
        $fail.Add("Suite manifest skill '$skillName' must appear exactly once in generic/project_specific: $manifestPath")
      }
    }

    foreach ($skillName in $partition) {
      if ($manifestSkills -notcontains $skillName) {
        $fail.Add("Suite manifest partition contains skill not present in skills list '$skillName': $manifestPath")
        continue
      }
      if (-not $registryByName.ContainsKey($skillName)) {
        continue
      }
      $expectedKind = if ($genericSkills -contains $skillName) { "generic" } else { "project" }
      if ([string]$registryByName[$skillName].kind -ne $expectedKind) {
        $fail.Add("Suite manifest kind mismatch for '$skillName': expected $expectedKind")
      }
    }
  }

  $registeredDirs = @($registry.skills | ForEach-Object { Split-Path ([string]$_.path) -Leaf })
  Get-ChildItem $SkillsRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    if ($registeredDirs -notcontains $_.Name) {
      $warn.Add("Unregistered skill directory: $($_.Name)")
    }
  }
}

Write-Output "=== Codex Engineering Skills Validation ==="
foreach ($item in $pass) { Write-Output "[PASS] $item" }
foreach ($item in $warn) { Write-Output "[WARN] $item" }
foreach ($item in $fail) { Write-Output "[FAIL] $item" }
Write-Output ("PASS={0} WARN={1} FAIL={2}" -f $pass.Count,$warn.Count,$fail.Count)

if ($fail.Count -gt 0) { exit 1 }
exit 0

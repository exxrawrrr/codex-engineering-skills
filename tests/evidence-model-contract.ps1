$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "validate.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-evidence-model-" + [guid]::NewGuid().ToString("N"))

function New-EvidenceCase {
  param([Parameter(Mandatory = $true)][string]$Name)

  $caseRoot = Join-Path $tempRoot $Name
  $skillsRoot = Join-Path $caseRoot "skills"
  $skillRoot = Join-Path $skillsRoot "example"
  $registryPath = Join-Path $caseRoot "REGISTRY.json"
  $evidencePath = Join-Path $caseRoot "evidence-index.json"

  New-Item -ItemType Directory -Path $skillRoot -Force | Out-Null

  @'
---
name: example
description: "Evidence model fixture."
---

# Example
'@ | Set-Content -Path (Join-Path $skillRoot "SKILL.md") -Encoding utf8NoBOM

  return @{
    Root = $caseRoot
    SkillsRoot = $skillsRoot
    RegistryPath = $registryPath
    EvidencePath = $evidencePath
  }
}

function Write-Registry {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Tier = "none",
    [string[]]$Refs = @()
  )

  [ordered]@{
    schema_version = 2
    suite = "evidence-model-fixture"
    version = "0.0.0"
    skills = @(
      [ordered]@{
        name = "example"
        kind = "generic"
        path = "skills/example"
        tags = @("fixture")
        status = "stable"
        evidence_tier = $Tier
        evidence_refs = @($Refs)
      }
    )
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $Path -Encoding utf8NoBOM
}

function New-EvidenceRecord {
  param(
    [string]$Id = "record-1",
    [string]$Type = "observational",
    [string]$ClaimState = "PARTIALLY_VERIFIED",
    [string]$SkillTier = "observed",
    [switch]$OmitSkill,
    [string]$Claim = "Fixture evidence claim.",
    [string]$DoesNotClaim = "No broader causal claim."
  )

  $observations = [ordered]@{}
  if (-not $OmitSkill) {
    $observations["example"] = $SkillTier
  }

  return [ordered]@{
    id = $Id
    type = $Type
    claim_state = $ClaimState
    claim = $Claim
    does_not_claim = $DoesNotClaim
    skill_observations = $observations
  }
}

function Write-EvidenceIndex {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [object[]]$Records = @(),
    [int]$SchemaVersion = 1
  )

  [ordered]@{
    schema_version = $SchemaVersion
    evidence_tiers = [ordered]@{
      none = "none"
      observed = "observed"
      repeated = "repeated"
      benchmarked = "benchmarked"
    }
    records = @($Records)
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $Path -Encoding utf8NoBOM
}

function Invoke-EvidenceValidator {
  param([Parameter(Mandatory = $true)][hashtable]$Case)

  $output = & pwsh -NoProfile -File $validator `
    -SkillsRoot $Case.SkillsRoot `
    -RegistryPath $Case.RegistryPath `
    -EvidenceIndexPath $Case.EvidencePath 2>&1

  return @{
    ExitCode = $LASTEXITCODE
    Text = (($output | ForEach-Object { [string]$_ }) -join "`n")
  }
}

function Assert-Accepted {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Case,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $result = Invoke-EvidenceValidator -Case $Case
  if ($result.ExitCode -ne 0) {
    throw "Expected '$Label' to pass. Output: $($result.Text)"
  }
  Write-Output "[PASS] $Label"
}

function Assert-Rejected {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Case,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )

  $result = Invoke-EvidenceValidator -Case $Case
  if ($result.ExitCode -eq 0) {
    throw "Expected evidence model case to fail with '$ExpectedText'"
  }
  if ($result.Text -notmatch [regex]::Escape($ExpectedText)) {
    throw "Evidence model case failed for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $none = New-EvidenceCase -Name "none"
  Write-Registry -Path $none.RegistryPath
  Write-EvidenceIndex -Path $none.EvidencePath
  Assert-Accepted -Case $none -Label "none tier without refs"

  $observed = New-EvidenceCase -Name "observed"
  Write-Registry -Path $observed.RegistryPath -Tier "observed" -Refs @("record-1")
  Write-EvidenceIndex -Path $observed.EvidencePath -Records @(
    (New-EvidenceRecord -SkillTier "observed")
  )
  Assert-Accepted -Case $observed -Label "observed tier backed by observational evidence"

  $repeated = New-EvidenceCase -Name "repeated"
  Write-Registry -Path $repeated.RegistryPath -Tier "repeated" -Refs @("record-1")
  Write-EvidenceIndex -Path $repeated.EvidencePath -Records @(
    (New-EvidenceRecord -SkillTier "repeated")
  )
  Assert-Accepted -Case $repeated -Label "repeated tier backed by repeated observation"

  $benchmarked = New-EvidenceCase -Name "benchmarked"
  Write-Registry -Path $benchmarked.RegistryPath -Tier "benchmarked" -Refs @("record-1")
  Write-EvidenceIndex -Path $benchmarked.EvidencePath -Records @(
    (New-EvidenceRecord -Type "comparative" -ClaimState "VERIFIED" -SkillTier "benchmarked")
  )
  Assert-Accepted -Case $benchmarked -Label "benchmarked tier backed by comparative evidence"

  $inflated = New-EvidenceCase -Name "inflated"
  Write-Registry -Path $inflated.RegistryPath -Tier "benchmarked" -Refs @("record-1")
  Write-EvidenceIndex -Path $inflated.EvidencePath -Records @(
    (New-EvidenceRecord -SkillTier "observed")
  )
  Assert-Rejected -Case $inflated -ExpectedText "evidence_tier 'benchmarked' is not supported by referenced evidence"

  $missingSkill = New-EvidenceCase -Name "missing-skill"
  Write-Registry -Path $missingSkill.RegistryPath -Tier "observed" -Refs @("record-1")
  Write-EvidenceIndex -Path $missingSkill.EvidencePath -Records @(
    (New-EvidenceRecord -OmitSkill)
  )
  Assert-Rejected -Case $missingSkill -ExpectedText "max supported: 'none'"

  $duplicateRefs = New-EvidenceCase -Name "duplicate-refs"
  Write-Registry -Path $duplicateRefs.RegistryPath -Tier "observed" -Refs @("record-1", "record-1")
  Write-EvidenceIndex -Path $duplicateRefs.EvidencePath -Records @(
    (New-EvidenceRecord -SkillTier "observed")
  )
  Assert-Rejected -Case $duplicateRefs -ExpectedText "duplicate evidence_refs are not allowed"

  $observationalBenchmark = New-EvidenceCase -Name "observational-benchmark"
  Write-Registry -Path $observationalBenchmark.RegistryPath -Tier "benchmarked" -Refs @("record-1")
  Write-EvidenceIndex -Path $observationalBenchmark.EvidencePath -Records @(
    (New-EvidenceRecord -Type "observational" -SkillTier "benchmarked")
  )
  Assert-Rejected -Case $observationalBenchmark -ExpectedText "observational records cannot support benchmarked tier"

  $invalidRecordType = New-EvidenceCase -Name "invalid-record-type"
  Write-Registry -Path $invalidRecordType.RegistryPath -Tier "observed" -Refs @("record-1")
  Write-EvidenceIndex -Path $invalidRecordType.EvidencePath -Records @(
    (New-EvidenceRecord -Type "marketing-story" -SkillTier "observed")
  )
  Assert-Rejected -Case $invalidRecordType -ExpectedText "invalid type 'marketing-story'"

  $invalidClaimState = New-EvidenceCase -Name "invalid-claim-state"
  Write-Registry -Path $invalidClaimState.RegistryPath -Tier "observed" -Refs @("record-1")
  Write-EvidenceIndex -Path $invalidClaimState.EvidencePath -Records @(
    (New-EvidenceRecord -ClaimState "PROVEN_FOREVER" -SkillTier "observed")
  )
  Assert-Rejected -Case $invalidClaimState -ExpectedText "invalid claim_state 'PROVEN_FOREVER'"

  $missingLimitation = New-EvidenceCase -Name "missing-limitation"
  Write-Registry -Path $missingLimitation.RegistryPath -Tier "observed" -Refs @("record-1")
  Write-EvidenceIndex -Path $missingLimitation.EvidencePath -Records @(
    (New-EvidenceRecord -SkillTier "observed" -DoesNotClaim "")
  )
  Assert-Rejected -Case $missingLimitation -ExpectedText "does_not_claim is required"

  $unsupportedSchema = New-EvidenceCase -Name "unsupported-schema"
  Write-Registry -Path $unsupportedSchema.RegistryPath
  Write-EvidenceIndex -Path $unsupportedSchema.EvidencePath -SchemaVersion 2
  Assert-Rejected -Case $unsupportedSchema -ExpectedText "Unsupported evidence index schema_version"

  $tierVocabularyDrift = New-EvidenceCase -Name "tier-vocabulary-drift"
  Write-Registry -Path $tierVocabularyDrift.RegistryPath
  [ordered]@{
    schema_version = 1
    evidence_tiers = [ordered]@{
      none = "none"
      observed = "observed"
      repeated = "repeated"
      proven = "invented tier"
    }
    records = @()
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $tierVocabularyDrift.EvidencePath -Encoding utf8NoBOM
  Assert-Rejected -Case $tierVocabularyDrift -ExpectedText "evidence_tiers must declare exactly none, observed, repeated, benchmarked"

  $nonObjectObservations = New-EvidenceCase -Name "non-object-observations"
  Write-Registry -Path $nonObjectObservations.RegistryPath -Tier "observed" -Refs @("record-1")
  [ordered]@{
    schema_version = 1
    evidence_tiers = [ordered]@{
      none = "none"
      observed = "observed"
      repeated = "repeated"
      benchmarked = "benchmarked"
    }
    records = @(
      [ordered]@{
        id = "record-1"
        type = "observational"
        claim_state = "PARTIALLY_VERIFIED"
        claim = "Fixture evidence claim."
        does_not_claim = "No broader causal claim."
        skill_observations = @("example", "observed")
      }
    )
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $nonObjectObservations.EvidencePath -Encoding utf8NoBOM
  Assert-Rejected -Case $nonObjectObservations -ExpectedText "skill_observations must be an object mapping skill names to tiers"

  Write-Output "[PASS] evidence tier and claim contracts are regression-covered"
} finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

exit 0

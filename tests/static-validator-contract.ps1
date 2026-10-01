$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "validate.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-static-validator-" + [guid]::NewGuid().ToString("N"))

function New-Case {
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
description: "Static validator contract fixture."
---

# Example

fixture-body
'@ | Set-Content -Path (Join-Path $skillRoot "SKILL.md") -Encoding utf8NoBOM

  [ordered]@{
    schema_version = 1
    evidence_tiers = [ordered]@{
      none = "none"
      observed = "observed"
      repeated = "repeated"
      benchmarked = "benchmarked"
    }
    records = @()
  } | ConvertTo-Json -Depth 10 | Set-Content -Path $evidencePath -Encoding utf8NoBOM

  Write-Registry -Path $registryPath

  return @{
    Root = $caseRoot
    SkillsRoot = $skillsRoot
    SkillRoot = $skillRoot
    RegistryPath = $registryPath
    EvidencePath = $evidencePath
  }
}

function New-RegistryEntry {
  param(
    [string]$Name = "example",
    [string]$Kind = "generic",
    [string]$Path = "skills/example",
    [string]$Status = "stable"
  )

  return [ordered]@{
    name = $Name
    kind = $Kind
    path = $Path
    tags = @("fixture")
    status = $Status
    evidence_tier = "none"
    evidence_refs = @()
  }
}

function Write-Registry {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [object[]]$Entries = @((New-RegistryEntry))
  )

  [ordered]@{
    schema_version = 2
    suite = "static-validator-fixture"
    version = "0.0.0"
    skills = $Entries
  } | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8NoBOM
}

function Invoke-CaseValidator {
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
  param([Parameter(Mandatory = $true)][hashtable]$Case)

  $result = Invoke-CaseValidator -Case $Case
  if ($result.ExitCode -ne 0) {
    throw "Expected validator case '$($Case.Root)' to pass. Output: $($result.Text)"
  }

  Write-Output "[PASS] accepted valid static contract"
}

function Assert-Rejected {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Case,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )

  $result = Invoke-CaseValidator -Case $Case
  if ($result.ExitCode -eq 0) {
    throw "Expected validator case '$($Case.Root)' to fail with '$ExpectedText'"
  }
  if ($result.Text -notmatch [regex]::Escape($ExpectedText)) {
    throw "Validator failed for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)"
  }

  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $valid = New-Case -Name "valid"
  Assert-Accepted -Case $valid

  $invalidVersion = New-Case -Name "invalid-registry-version"
  $registryDoc = Get-Content -LiteralPath $invalidVersion.RegistryPath -Raw | ConvertFrom-Json
  $registryDoc.version = "banana"
  $registryDoc | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $invalidVersion.RegistryPath -Encoding utf8NoBOM
  Assert-Rejected -Case $invalidVersion -ExpectedText "Registry version must use SemVer X.Y.Z"

  $unknownObservation = New-Case -Name "unknown-evidence-skill"
  $evidenceDoc = Get-Content -LiteralPath $unknownObservation.EvidencePath -Raw | ConvertFrom-Json
  $evidenceDoc.records = @(
    [ordered]@{
      id = "ghost-evidence"
      type = "observational"
      claim_state = "PARTIALLY_VERIFIED"
      claim = "Fixture observation."
      does_not_claim = "Causal improvement."
      skill_observations = [ordered]@{
        "ghost-skill" = "observed"
      }
    }
  )
  $evidenceDoc | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $unknownObservation.EvidencePath -Encoding utf8NoBOM
  Assert-Rejected -Case $unknownObservation -ExpectedText "Evidence record 'ghost-evidence': unknown skill_observation 'ghost-skill'"

  $escapedReference = New-Case -Name "escaped-reference"
  New-Item -ItemType Directory -Path (Join-Path $escapedReference.SkillRoot "references") -Force | Out-Null
  Set-Content -LiteralPath (Join-Path $escapedReference.SkillsRoot "outside.md") -Value "outside" -Encoding utf8NoBOM
  Add-Content -LiteralPath (Join-Path $escapedReference.SkillRoot "SKILL.md") -Value @'

Read `references/../../outside.md`.
'@ -Encoding utf8NoBOM
  Assert-Rejected -Case $escapedReference -ExpectedText "reference escapes skill directory"

  $invalidKind = New-Case -Name "invalid-kind"
  Write-Registry -Path $invalidKind.RegistryPath -Entries @(
    (New-RegistryEntry -Kind "mystery")
  )
  Assert-Rejected -Case $invalidKind -ExpectedText "invalid kind"

  $duplicate = New-Case -Name "duplicate-name"
  Write-Registry -Path $duplicate.RegistryPath -Entries @(
    (New-RegistryEntry),
    (New-RegistryEntry)
  )
  Assert-Rejected -Case $duplicate -ExpectedText "Duplicate registry skill name"

  $nonCanonical = New-Case -Name "non-canonical-path"
  Write-Registry -Path $nonCanonical.RegistryPath -Entries @(
    (New-RegistryEntry -Path "skills/../skills/example")
  )
  Assert-Rejected -Case $nonCanonical -ExpectedText "non-canonical registered path"

  $genericProject = New-Case -Name "generic-project-status"
  Write-Registry -Path $genericProject.RegistryPath -Entries @(
    (New-RegistryEntry -Kind "generic" -Status "project")
  )
  Assert-Rejected -Case $genericProject -ExpectedText "kind/status mismatch"

  $projectStable = New-Case -Name "project-stable-status"
  Write-Registry -Path $projectStable.RegistryPath -Entries @(
    (New-RegistryEntry -Kind "project" -Status "stable")
  )
  Assert-Rejected -Case $projectStable -ExpectedText "kind/status mismatch"

  $frontmatter = New-Case -Name "frontmatter-not-closed"
  @'
---
name: example
description: "Looks valid but never closes."

# Body

name: example
description: "Body text must not rescue malformed frontmatter."
'@ | Set-Content -Path (Join-Path $frontmatter.SkillRoot "SKILL.md") -Encoding utf8NoBOM
  Assert-Rejected -Case $frontmatter -ExpectedText "invalid YAML frontmatter block"

  $manifestUnknown = New-Case -Name "manifest-unknown-skill"
  [ordered]@{
    suite = "fixture"
    version = "0"
    skills = @("example", "ghost")
    generic = @("example", "ghost")
    project_specific = @()
  } | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $manifestUnknown.SkillRoot "suite-manifest.json") -Encoding utf8NoBOM
  Assert-Rejected -Case $manifestUnknown -ExpectedText "unregistered skill 'ghost'"

  $manifestPartition = New-Case -Name "manifest-partition"
  [ordered]@{
    suite = "fixture"
    version = "0"
    skills = @("example")
    generic = @()
    project_specific = @()
  } | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $manifestPartition.SkillRoot "suite-manifest.json") -Encoding utf8NoBOM
  Assert-Rejected -Case $manifestPartition -ExpectedText "must appear exactly once in generic/project_specific"

  $manifestKind = New-Case -Name "manifest-kind"
  [ordered]@{
    suite = "fixture"
    version = "0"
    skills = @("example")
    generic = @()
    project_specific = @("example")
  } | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $manifestKind.SkillRoot "suite-manifest.json") -Encoding utf8NoBOM
  Assert-Rejected -Case $manifestKind -ExpectedText "Suite manifest kind mismatch"

  $manifestJson = New-Case -Name "manifest-invalid-json"
  "{ definitely-not-json" | Set-Content -Path (Join-Path $manifestJson.SkillRoot "suite-manifest.json") -Encoding utf8NoBOM
  Assert-Rejected -Case $manifestJson -ExpectedText "Invalid suite manifest JSON"

  Write-Output "[PASS] static validator registry/frontmatter/manifest contract is regression-covered"
} finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

exit 0

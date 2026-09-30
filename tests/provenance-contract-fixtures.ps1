$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "tests/provenance-contract.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-provenance-contract-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  New-Item -ItemType Directory -Path $root -Force | Out-Null

  foreach ($file in @("PROVENANCE.json","REGISTRY.json","SOURCES.md","ATTRIBUTION.md","NOTICE")) {
    Copy-Item -LiteralPath (Join-Path $repoRoot $file) -Destination (Join-Path $root $file)
  }

  return @{
    Root = $root
    ProvenancePath = Join-Path $root "PROVENANCE.json"
    RegistryPath = Join-Path $root "REGISTRY.json"
    SourcesPath = Join-Path $root "SOURCES.md"
    AttributionPath = Join-Path $root "ATTRIBUTION.md"
    NoticePath = Join-Path $root "NOTICE"
    DuplicateProjectPath = Join-Path $root "skills/growthops-engineering/references/source-provenance.md"
  }
}

function Save-Provenance {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][object]$Value
  )
  $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Sandbox.ProvenancePath -Encoding utf8NoBOM
}

function Invoke-Validator {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)

  $output = & pwsh -NoProfile -File $validator -ProvenancePath $Sandbox.ProvenancePath -RegistryPath $Sandbox.RegistryPath -SourcesPath $Sandbox.SourcesPath -AttributionPath $Sandbox.AttributionPath -NoticePath $Sandbox.NoticePath -RepoRoot $Sandbox.Root -DuplicateProjectPath $Sandbox.DuplicateProjectPath 2>&1

  return @{
    ExitCode = $LASTEXITCODE
    Text = (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
  }
}

function Assert-Passes {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )
  $result = Invoke-Validator -Sandbox $Sandbox
  if ($result.ExitCode -ne 0) {
    throw "Expected provenance validator to pass. Output: $($result.Text)"
  }
  if (-not $result.Text.Contains($ExpectedText)) {
    throw "Provenance validator passed without '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] $ExpectedText"
}

function Assert-Rejected {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )
  $result = Invoke-Validator -Sandbox $Sandbox
  if ($result.ExitCode -eq 0) {
    throw "Expected provenance validator rejection containing '$ExpectedText'. Output: $($result.Text)"
  }
  if (-not $result.Text.Contains($ExpectedText)) {
    throw "Provenance validator rejected for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $valid = New-Sandbox -Name "valid"
  Assert-Passes -Sandbox $valid -ExpectedText "PROVENANCE_CONTRACT SOURCES=19 MAPPED_SKILLS=10 RETIRED_URLS=1 FAIL=0"

  $oldSchema = New-Sandbox -Name "old-schema"
  $p = Get-Content -LiteralPath $oldSchema.ProvenancePath -Raw | ConvertFrom-Json
  $p.schema_version = 1
  Save-Provenance -Sandbox $oldSchema -Value $p
  Assert-Rejected -Sandbox $oldSchema -ExpectedText "Unsupported provenance schema_version '1'; expected 2"

  $duplicateId = New-Sandbox -Name "duplicate-id"
  $p = Get-Content -LiteralPath $duplicateId.ProvenancePath -Raw | ConvertFrom-Json
  $p.sources[1].id = $p.sources[0].id
  Save-Provenance -Sandbox $duplicateId -Value $p
  Assert-Rejected -Sandbox $duplicateId -ExpectedText "Duplicate provenance source id"

  $duplicateUrl = New-Sandbox -Name "duplicate-url"
  $p = Get-Content -LiteralPath $duplicateUrl.ProvenancePath -Raw | ConvertFrom-Json
  $p.sources[1].urls[0] = $p.sources[0].urls[0]
  Save-Provenance -Sandbox $duplicateUrl -Value $p
  Assert-Rejected -Sandbox $duplicateUrl -ExpectedText "Duplicate active provenance URL across sources"

  $badType = New-Sandbox -Name "bad-type"
  $p = Get-Content -LiteralPath $badType.ProvenancePath -Raw | ConvertFrom-Json
  $p.sources[0].type = "marketing_reference"
  Save-Provenance -Sandbox $badType -Value $p
  Assert-Rejected -Sandbox $badType -ExpectedText "invalid source type 'marketing_reference'"

  $unmapped = New-Sandbox -Name "unmapped-skill"
  $p = Get-Content -LiteralPath $unmapped.ProvenancePath -Raw | ConvertFrom-Json
  $internal = @($p.sources | Where-Object { $_.id -eq "internal-agent-skill-evaluation-framework" })[0]
  $internal.informs_skills = @("agent-skill-authoring")
  Save-Provenance -Sandbox $unmapped -Value $p
  Assert-Rejected -Sandbox $unmapped -ExpectedText "Registered skill has no provenance mapping: agent-skill-evaluation"

  $retired = New-Sandbox -Name "retired-url"
  $p = Get-Content -LiteralPath $retired.ProvenancePath -Raw | ConvertFrom-Json
  $wstg = @($p.sources | Where-Object { $_.id -eq "official-owasp-wstg-path-traversal" })[0]
  $wstg.urls = @("https://cheatsheetseries.owasp.org/cheatsheets/Path_Traversal_Cheat_Sheet.html")
  Save-Provenance -Sandbox $retired -Value $p
  Assert-Rejected -Sandbox $retired -ExpectedText "Active source URL is retired"

  $missingLicenseEvidence = New-Sandbox -Name "missing-license-evidence"
  $p = Get-Content -LiteralPath $missingLicenseEvidence.ProvenancePath -Raw | ConvertFrom-Json
  $repoSource = @($p.sources | Where-Object { $_.id -eq "repo-timothy-nishimura-crawl" })[0]
  $repoSource.license_evidence = $null
  Save-Provenance -Sandbox $missingLicenseEvidence -Value $p
  Assert-Rejected -Sandbox $missingLicenseEvidence -ExpectedText "verified license requires dated LICENSE blob evidence"

  $trailOverclaim = New-Sandbox -Name "trail-overclaim"
  $p = Get-Content -LiteralPath $trailOverclaim.ProvenancePath -Raw | ConvertFrom-Json
  $trail = @($p.sources | Where-Object { $_.id -eq "repo-trailofbits-claude-code-config" })[0]
  $trail.license_status = "VERIFIED_MIT"
  Save-Provenance -Sandbox $trailOverclaim -Value $p
  Assert-Rejected -Sandbox $trailOverclaim -ExpectedText "Trail of Bits license uncertainty must remain UNVERIFIED_NO_REDISTRIBUTION_CLAIM"

  $sourceDrift = New-Sandbox -Name "sources-drift"
  $textValue = Get-Content -LiteralPath $sourceDrift.SourcesPath -Raw
  $textValue = $textValue.Replace("- https://pnpm.io/workspaces" + [Environment]::NewLine,"")
  Set-Content -LiteralPath $sourceDrift.SourcesPath -Value $textValue -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $sourceDrift -ExpectedText "SOURCES.md source URL set must exactly match active PROVENANCE URLs"

  $attributionDrift = New-Sandbox -Name "attribution-drift"
  $textValue = Get-Content -LiteralPath $attributionDrift.AttributionPath -Raw
  $textValue = $textValue.Replace("- https://github.com/alfa546/Crawler" + [Environment]::NewLine,"")
  Set-Content -LiteralPath $attributionDrift.AttributionPath -Value $textValue -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $attributionDrift -ExpectedText "ATTRIBUTION.md public repository URLs must exactly match"

  $noticeDrift = New-Sandbox -Name "notice-drift"
  $textValue = Get-Content -LiteralPath $noticeDrift.NoticePath -Raw
  $textValue = $textValue.Replace("@timothy-nishimura — crawl (MIT)","@timothy-nishimura — crawl (Apache-2.0)")
  Set-Content -LiteralPath $noticeDrift.NoticePath -Value $textValue -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $noticeDrift -ExpectedText "NOTICE license marker must be '(MIT)'"

  $canonicalDrift = New-Sandbox -Name "canonical-human-sources"
  $p = Get-Content -LiteralPath $canonicalDrift.ProvenancePath -Raw | ConvertFrom-Json
  $p.canonical_human_sources = @("SOURCES.md","ATTRIBUTION.md")
  Save-Provenance -Sandbox $canonicalDrift -Value $p
  Assert-Rejected -Sandbox $canonicalDrift -ExpectedText "canonical_human_sources must contain exactly"

  $exactDuplicate = New-Sandbox -Name "exact-duplicate"
  $copyDir = Join-Path $exactDuplicate.Root "docs"
  New-Item -ItemType Directory -Path $copyDir -Force | Out-Null
  Copy-Item -LiteralPath $exactDuplicate.SourcesPath -Destination (Join-Path $copyDir "source-copy.md")
  Assert-Rejected -Sandbox $exactDuplicate -ExpectedText "Exact duplicate provenance Markdown matches SOURCES.md"

  Write-Output "[PASS] provenance drift, overclaim, retired-link, mapping, and duplication fixtures are regression-covered"
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

exit 0

param(
  [string]$ProvenancePath = "$PSScriptRoot\..\PROVENANCE.json",
  [string]$RegistryPath = "$PSScriptRoot\..\REGISTRY.json",
  [string]$SourcesPath = "$PSScriptRoot\..\SOURCES.md",
  [string]$AttributionPath = "$PSScriptRoot\..\ATTRIBUTION.md",
  [string]$NoticePath = "$PSScriptRoot\..\NOTICE",
  [string]$RepoRoot = "$PSScriptRoot\..",
  [string]$DuplicateProjectPath = "$PSScriptRoot\..\skills\growthops-engineering\references\source-provenance.md"
)

$ErrorActionPreference = "Stop"
$reviewDate = "2026-09-30"

function Normalize-Url {
  param([Parameter(Mandatory = $true)][string]$Url)
  return $Url.Trim().TrimEnd("/")
}

function Test-ExactStringSet {
  param(
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Actual,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Expected
  )
  $a = @($Actual | Sort-Object -Unique -CaseSensitive)
  $e = @($Expected | Sort-Object -Unique -CaseSensitive)
  return ($a.Count -eq $e.Count -and (($a -join [char]0x001F) -ceq ($e -join [char]0x001F)))
}

foreach ($path in @($ProvenancePath,$RegistryPath,$SourcesPath,$AttributionPath,$NoticePath)) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing provenance input: $path"
  }
}

$provenance = Get-Content -LiteralPath $ProvenancePath -Raw | ConvertFrom-Json
$registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
$sourcesText = Get-Content -LiteralPath $SourcesPath -Raw
$attributionText = Get-Content -LiteralPath $AttributionPath -Raw
$noticeText = Get-Content -LiteralPath $NoticePath -Raw
$errors = New-Object System.Collections.Generic.List[string]

if ([int]$provenance.schema_version -ne 2) {
  $errors.Add("Unsupported provenance schema_version '$($provenance.schema_version)'; expected 2")
}
if ([string]$provenance.reviewed_on -ne $reviewDate) {
  $errors.Add("Provenance reviewed_on must preserve the $reviewDate review snapshot")
}
if ([string]::IsNullOrWhiteSpace([string]$provenance.policy)) {
  $errors.Add("Provenance policy is required")
}
if ([string]$provenance.maintenance.network_checks -ne "MANUAL_SNAPSHOT_NOT_CI") {
  $errors.Add("Provenance network_checks must remain MANUAL_SNAPSHOT_NOT_CI")
}
if ([string]::IsNullOrWhiteSpace([string]$provenance.maintenance.deterministic_ci_checks)) {
  $errors.Add("Provenance deterministic_ci_checks description is required")
}

$expectedHumanSources = @("SOURCES.md","ATTRIBUTION.md","NOTICE")
$humanSources = @($provenance.canonical_human_sources | ForEach-Object { [string]$_ })
if (-not (Test-ExactStringSet -Actual $humanSources -Expected $expectedHumanSources)) {
  $errors.Add("canonical_human_sources must contain exactly SOURCES.md, ATTRIBUTION.md, NOTICE")
}
if (@($humanSources | Sort-Object -Unique -CaseSensitive).Count -ne $humanSources.Count) {
  $errors.Add("canonical_human_sources contains duplicates")
}
foreach ($path in $humanSources) {
  if ([System.IO.Path]::IsPathRooted($path) -or $path.Contains("..") -or (Split-Path $path -Leaf) -cne $path) {
    $errors.Add("canonical_human_sources entry must be a root filename: $path")
    continue
  }
  $resolved = Join-Path (Split-Path $ProvenancePath -Parent) $path
  if (-not (Test-Path -LiteralPath $resolved)) {
    $errors.Add("Missing canonical human provenance file: $path")
  }
}

$registeredSkills = @($registry.skills | ForEach-Object { [string]$_.name })
$registryKind = @{}
foreach ($entry in @($registry.skills)) {
  $registryKind[[string]$entry.name] = [string]$entry.kind
}

$allowedTypes = @(
  "official_documentation",
  "public_repository_reference",
  "project_specific_source",
  "repository_original_synthesis"
)
$prefixByType = @{
  official_documentation = "official-"
  public_repository_reference = "repo-"
  project_specific_source = "project-"
  repository_original_synthesis = "internal-"
}
$allowedLicenseByType = @{
  official_documentation = @("NOT_APPLICABLE_DOCUMENTATION_REFERENCE")
  public_repository_reference = @("VERIFIED_MIT","VERIFIED_APACHE_2_0","UNVERIFIED_NO_REDISTRIBUTION_CLAIM")
  project_specific_source = @("PROJECT_SOURCE")
  repository_original_synthesis = @("PROJECT_SOURCE")
}

$sourceIds = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::Ordinal)
$activeUrls = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::Ordinal)
$mappedSkills = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::Ordinal)
$projectMappedSkills = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::Ordinal)
$publicRepoUrls = New-Object System.Collections.Generic.List[string]

$retiredByUrl = @{}
foreach ($retired in @($provenance.retired_urls)) {
  $retiredUrl = Normalize-Url ([string]$retired.url)
  if ([string]::IsNullOrWhiteSpace($retiredUrl)) {
    $errors.Add("retired_urls contains an empty URL")
    continue
  }
  if ($retiredByUrl.ContainsKey($retiredUrl)) {
    $errors.Add("Duplicate retired provenance URL: $retiredUrl")
    continue
  }
  if ([string]$retired.retired_on -ne $reviewDate) {
    $errors.Add("Retired URL must preserve retired_on=$reviewDate -> $retiredUrl")
  }
  if ([string]::IsNullOrWhiteSpace([string]$retired.reason)) {
    $errors.Add("Retired URL requires reason -> $retiredUrl")
  }
  if ([string]::IsNullOrWhiteSpace([string]$retired.replacement)) {
    $errors.Add("Retired URL requires replacement -> $retiredUrl")
  }
  $retiredByUrl[$retiredUrl] = Normalize-Url ([string]$retired.replacement)
}

foreach ($source in @($provenance.sources)) {
  $id = [string]$source.id
  if ($id -notmatch "^[a-z0-9]+(?:-[a-z0-9]+)*$") {
    $errors.Add("Invalid provenance source id: $id")
  }
  if (-not $sourceIds.Add($id)) {
    $errors.Add("Duplicate provenance source id: $id")
  }

  $type = [string]$source.type
  if ($allowedTypes -notcontains $type) {
    $errors.Add("${id}: invalid source type '$type'")
  } elseif (-not $id.StartsWith([string]$prefixByType[$type],[System.StringComparison]::Ordinal)) {
    $errors.Add("${id}: source id prefix does not match type '$type'")
  }

  $urls = @($source.urls | ForEach-Object { [string]$_ })
  if ($urls.Count -eq 0) {
    $errors.Add("${id}: at least one URL is required")
  }
  $localUrls = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::Ordinal)
  foreach ($urlTextRaw in $urls) {
    $urlText = $urlTextRaw.Trim()
    $uri = $null
    if (-not [System.Uri]::TryCreate($urlText,[System.UriKind]::Absolute,[ref]$uri) -or
        $uri.Scheme -cne "https" -or
        [string]::IsNullOrWhiteSpace($uri.Host) -or
        -not [string]::IsNullOrWhiteSpace($uri.UserInfo) -or
        -not [string]::IsNullOrWhiteSpace($uri.Fragment)) {
      $errors.Add("${id}: URL must be an absolute HTTPS URL without credentials/fragment -> $urlText")
      continue
    }

    $normalized = Normalize-Url $urlText
    if (-not $localUrls.Add($normalized)) {
      $errors.Add("${id}: duplicate URL within source -> $normalized")
    }
    if (-not $activeUrls.Add($normalized)) {
      $errors.Add("Duplicate active provenance URL across sources: $normalized")
    }
    if ($retiredByUrl.ContainsKey($normalized)) {
      $errors.Add("Active source URL is retired: $normalized")
    }
  }

  if ([string]$source.url_review.reviewed_on -ne $reviewDate) {
    $errors.Add("${id}: url_review.reviewed_on must be $reviewDate")
  }
  if ([string]$source.url_review.status -ne "RESOLVED") {
    $errors.Add("${id}: url_review.status must be RESOLVED")
  }
  if (@("manual_network_review","repository_access") -notcontains [string]$source.url_review.method) {
    $errors.Add("${id}: unsupported url_review.method '$([string]$source.url_review.method)'")
  }

  $licenseStatus = [string]$source.license_status
  if ($allowedLicenseByType.ContainsKey($type) -and
      $allowedLicenseByType[$type] -notcontains $licenseStatus) {
    $errors.Add("${id}: license_status '$licenseStatus' is invalid for source type '$type'")
  }

  if ($type -eq "official_documentation") {
    if ($null -ne $source.license_evidence) {
      $errors.Add("${id}: official documentation must not carry repository license_evidence")
    }
  } elseif ($type -eq "public_repository_reference") {
    if ($urls.Count -ne 1 -or $urls[0] -notmatch "^https://github\.com/[^/]+/[^/]+/?$") {
      $errors.Add("${id}: public repository source must have exactly one GitHub repository-root URL")
    } else {
      $publicRepoUrls.Add((Normalize-Url $urls[0]))
    }

    $evidence = $source.license_evidence
    if ($licenseStatus -eq "VERIFIED_MIT" -or $licenseStatus -eq "VERIFIED_APACHE_2_0") {
      $expectedObserved = if ($licenseStatus -eq "VERIFIED_MIT") { "MIT" } else { "Apache-2.0" }
      if ([string]$evidence.kind -ne "repository_file" -or
          [string]$evidence.reviewed_on -ne $reviewDate -or
          [string]$evidence.path -ne "LICENSE" -or
          [string]$evidence.blob_sha -notmatch "^[0-9a-f]{40}$" -or
          [string]$evidence.observed_license -ne $expectedObserved) {
        $errors.Add("${id}: verified license requires dated LICENSE blob evidence matching '$expectedObserved'")
      }
    } elseif ($licenseStatus -eq "UNVERIFIED_NO_REDISTRIBUTION_CLAIM") {
      $expectedChecked = @("LICENSE","LICENSE.md","LICENSE.txt","COPYING","COPYING.md")
      $actualChecked = @($evidence.checked_paths | ForEach-Object { [string]$_ })
      if ([string]$evidence.kind -ne "manual_root_check" -or
          [string]$evidence.reviewed_on -ne $reviewDate -or
          [string]$evidence.result -ne "NOT_FOUND" -or
          -not (Test-ExactStringSet -Actual $actualChecked -Expected $expectedChecked)) {
        $errors.Add("${id}: unverified license must preserve the dated root-license NOT_FOUND review")
      }
    }
  } else {
    if ([string]$source.license_evidence.kind -ne "repository_owned_source" -or
        [string]$source.license_evidence.reviewed_on -ne $reviewDate) {
      $errors.Add("${id}: project/internal source must carry repository_owned_source evidence")
    }
  }

  $skills = @($source.informs_skills | ForEach-Object { [string]$_ })
  if ($skills.Count -eq 0) {
    $errors.Add("${id}: informs_skills is empty")
  }
  if (@($skills | Sort-Object -Unique -CaseSensitive).Count -ne $skills.Count) {
    $errors.Add("${id}: duplicate informs_skills entries are not allowed")
  }

  foreach ($skillName in $skills) {
    if ($registeredSkills -cnotcontains $skillName) {
      $errors.Add("${id}: unknown skill mapping -> $skillName")
      continue
    }
    [void]$mappedSkills.Add($skillName)

    if ($type -eq "project_specific_source") {
      if ([string]$registryKind[$skillName] -ne "project") {
        $errors.Add("${id}: project_specific_source maps non-project skill '$skillName'")
      } else {
        [void]$projectMappedSkills.Add($skillName)
      }
    }
    if ($type -eq "repository_original_synthesis" -and [string]$registryKind[$skillName] -eq "project") {
      $errors.Add("${id}: repository_original_synthesis must not replace project-specific provenance for '$skillName'")
    }
  }
}

foreach ($skill in $registeredSkills) {
  if (-not $mappedSkills.Contains($skill)) {
    $errors.Add("Registered skill has no provenance mapping: $skill")
  }
  if ([string]$registryKind[$skill] -eq "project" -and -not $projectMappedSkills.Contains($skill)) {
    $errors.Add("Project skill has no project_specific_source mapping: $skill")
  }
}

foreach ($retiredUrl in $retiredByUrl.Keys) {
  if ($activeUrls.Contains($retiredUrl)) {
    $errors.Add("Retired URL is still active: $retiredUrl")
  }
  $replacement = [string]$retiredByUrl[$retiredUrl]
  if (-not $activeUrls.Contains($replacement)) {
    $errors.Add("Retired URL replacement is not an active provenance URL: $replacement")
  }
  if ($sourcesText.Contains($retiredUrl)) {
    $errors.Add("SOURCES.md still contains retired URL: $retiredUrl")
  }
}

foreach ($url in $activeUrls) {
  $count = ([regex]::Matches($sourcesText,[regex]::Escape($url))).Count
  if ($count -ne 1) {
    $errors.Add("SOURCES.md must contain active provenance URL exactly once ($count observed): $url")
  }
}

$attributionRepoUrls = @(
  [regex]::Matches($attributionText, "https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+") |
    ForEach-Object { Normalize-Url $_.Value } |
    Sort-Object -Unique -CaseSensitive
)
if (-not (Test-ExactStringSet -Actual $attributionRepoUrls -Expected @($publicRepoUrls))) {
  $errors.Add("ATTRIBUTION.md public repository URLs must exactly match PROVENANCE public_repository_reference URLs")
}

foreach ($url in @($publicRepoUrls)) {
  if (([regex]::Matches($sourcesText,[regex]::Escape($url))).Count -ne 1) {
    $errors.Add("Public repository URL must appear exactly once in SOURCES.md: $url")
  }
}

foreach ($source in @($provenance.sources | Where-Object { [string]$_.type -eq "public_repository_reference" })) {
  $url = [uri]([string]$source.urls[0])
  $parts = $url.AbsolutePath.Trim("/").Split("/")
  $owner = $parts[0]
  $repoName = $parts[1]
  $noticeLines = @($noticeText -split "\r?\n" | Where-Object { $_ -match [regex]::Escape("@$owner") -and $_ -match [regex]::Escape($repoName) })
  if ($noticeLines.Count -ne 1) {
    $errors.Add("$([string]$source.id): NOTICE must contain exactly one owner/repository line")
    continue
  }
  $line = [string]$noticeLines[0]
  $expectedMarker = switch ([string]$source.license_status) {
    "VERIFIED_MIT" { "(MIT)" }
    "VERIFIED_APACHE_2_0" { "(Apache-2.0)" }
    "UNVERIFIED_NO_REDISTRIBUTION_CLAIM" { "(public reference)" }
  }
  if (-not $line.Contains($expectedMarker)) {
    $errors.Add("$([string]$source.id): NOTICE license marker must be '$expectedMarker'")
  }
}

foreach ($docPair in @(
  @{ Name = "SOURCES.md"; Text = $sourcesText },
  @{ Name = "ATTRIBUTION.md"; Text = $attributionText },
  @{ Name = "NOTICE"; Text = $noticeText }
)) {
  if (-not $docPair.Text.Contains("PROVENANCE.json")) {
    $errors.Add("$($docPair.Name) does not reference PROVENANCE.json")
  }
}

$trail = @($provenance.sources | Where-Object { [string]$_.id -eq "repo-trailofbits-claude-code-config" })
if ($trail.Count -ne 1 -or [string]$trail[0].license_status -ne "UNVERIFIED_NO_REDISTRIBUTION_CLAIM") {
  $errors.Add("Trail of Bits license uncertainty must remain UNVERIFIED_NO_REDISTRIBUTION_CLAIM")
}

if (Test-Path -LiteralPath $DuplicateProjectPath) {
  $errors.Add("Duplicate GrowthOps source-provenance.md still exists")
}

$sourcesHash = (Get-FileHash -LiteralPath $SourcesPath -Algorithm SHA256).Hash
$sourcesFull = (Resolve-Path -LiteralPath $SourcesPath).Path
$duplicateMarkdown = @(
  Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Filter "*.md" -ErrorAction Stop |
    Where-Object { $_.FullName -ne $sourcesFull } |
    Where-Object { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash -eq $sourcesHash }
)
foreach ($duplicate in $duplicateMarkdown) {
  $errors.Add("Exact duplicate provenance Markdown matches SOURCES.md: $($duplicate.FullName)")
}

foreach ($errorItem in $errors) { Write-Output "[FAIL] $errorItem" }
if ($errors.Count -eq 0) {
  Write-Output "[PASS] provenance source, license, mapping, human-doc, retired-link, and deduplication contracts are aligned"
}
Write-Output ("PROVENANCE_CONTRACT SOURCES={0} MAPPED_SKILLS={1} RETIRED_URLS={2} FAIL={3}" -f $sourceIds.Count,$mappedSkills.Count,$retiredByUrl.Count,$errors.Count)

if ($errors.Count -gt 0) { exit 1 }
exit 0

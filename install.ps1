param(
  [switch]$DryRun,
  [switch]$GenericOnly,
  [string[]]$SkillName,
  [string]$TargetRoot = "$env:USERPROFILE\.codex\skills",
  [string]$BackupRoot
)

$ErrorActionPreference = "Stop"
$sourceRoot = Join-Path $PSScriptRoot "skills"
$registryPath = Join-Path $PSScriptRoot "REGISTRY.json"

function Get-PathComparison {
  if ([System.OperatingSystem]::IsWindows()) {
    return [System.StringComparison]::OrdinalIgnoreCase
  }
  return [System.StringComparison]::Ordinal
}

function Get-NormalizedFullPath {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Label
  )

  if ([string]::IsNullOrWhiteSpace($Path)) {
    throw "$Label must not be empty"
  }

  $full = [System.IO.Path]::GetFullPath($Path)
  $root = [System.IO.Path]::GetPathRoot($full)
  if ([string]::IsNullOrWhiteSpace($root)) {
    throw "$Label must resolve to an absolute filesystem path"
  }

  if ($full -eq $root) { return $full }
  return $full.TrimEnd([char[]]@(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
  ))
}

function Test-SameOrChildPath {
  param(
    [Parameter(Mandatory = $true)][string]$Candidate,
    [Parameter(Mandatory = $true)][string]$Root
  )

  $comparison = Get-PathComparison
  if ($Candidate.Equals($Root, $comparison)) { return $true }

  $prefix = $Root
  if (-not $prefix.EndsWith([string][System.IO.Path]::DirectorySeparatorChar) -and
      -not $prefix.EndsWith([string][System.IO.Path]::AltDirectorySeparatorChar)) {
    $prefix += [System.IO.Path]::DirectorySeparatorChar
  }

  return $Candidate.StartsWith($prefix, $comparison)
}

function Test-LinkOrReparsePoint {
  param([Parameter(Mandatory = $true)][System.IO.FileSystemInfo]$Item)

  $linkType = $Item.PSObject.Properties["LinkType"]
  if ($null -ne $linkType -and -not [string]::IsNullOrWhiteSpace([string]$linkType.Value)) {
    return $true
  }

  return (($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Assert-NoPathAlias {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $cursor = Get-NormalizedFullPath -Path $Path -Label $Label
  while ($true) {
    if (Test-Path -LiteralPath $cursor) {
      $item = Get-Item -LiteralPath $cursor -Force
      if (Test-LinkOrReparsePoint -Item $item) {
        throw "$Label must not traverse a symlink, junction, or reparse-point alias: $cursor"
      }
    }

    $parent = [System.IO.Directory]::GetParent($cursor)
    if ($null -eq $parent) { break }
    if ($parent.FullName -eq $cursor) { break }
    $cursor = $parent.FullName
  }
}

function Assert-NoLinksInTree {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Label
  )

  if (-not (Test-Path -LiteralPath $Path)) { return }

  $items = @((Get-Item -LiteralPath $Path -Force))
  $items += @(Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction Stop)

  foreach ($item in $items) {
    if (Test-LinkOrReparsePoint -Item $item) {
      throw "$Label must not contain symlinks, junctions, or reparse points: $($item.FullName)"
    }
  }
}

function Assert-SkillBundle {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$ExpectedName
  )

  $skillPath = Join-Path $Path "SKILL.md"
  if (-not (Test-Path -LiteralPath $skillPath)) {
    throw "Invalid skill bundle '$ExpectedName': missing SKILL.md"
  }

  $raw = Get-Content -LiteralPath $skillPath -Raw
  if (-not $raw.StartsWith("---")) {
    throw "Invalid skill bundle '$ExpectedName': missing YAML frontmatter opener"
  }
  if ($raw -notmatch "(?m)^name:\s+$([regex]::Escape($ExpectedName))\s*$") {
    throw "Invalid skill bundle '$ExpectedName': frontmatter name mismatch"
  }
}

function Get-DirectoryFingerprint {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) { return $null }

  $root = (Resolve-Path -LiteralPath $Path).Path
  $rows = Get-ChildItem -LiteralPath $root -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
      $relative = [System.IO.Path]::GetRelativePath($root, $_.FullName).Replace("\", "/")
      $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
      "$relative|$hash"
    }

  return ($rows -join "`n")
}

if (-not (Test-Path -LiteralPath $registryPath)) {
  throw "Missing REGISTRY.json"
}

$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$entries = @($registry.skills)

$hasExplicitSelection = $PSBoundParameters.ContainsKey("SkillName")
$requestedNames = @()
if ($hasExplicitSelection) {
  foreach ($rawName in @($SkillName)) {
    foreach ($part in ([string]$rawName -split ",")) {
      $name = $part.Trim()
      if (-not [string]::IsNullOrWhiteSpace($name)) {
        $requestedNames += $name
      }
    }
  }

  $requestedNames = @($requestedNames | Sort-Object -Unique)
  if ($requestedNames.Count -eq 0) {
    throw "SkillName was provided but no skill names were supplied"
  }
}

if ($GenericOnly -and $hasExplicitSelection) {
  throw "Use either -GenericOnly or -SkillName, not both"
}

if ($GenericOnly) {
  $entries = @($entries | Where-Object { [string]$_.kind -eq "generic" })
}

if ($hasExplicitSelection) {
  $knownNames = @($registry.skills | ForEach-Object { [string]$_.name })
  $unknownNames = @($requestedNames | Where-Object { $knownNames -notcontains $_ })
  if ($unknownNames.Count -gt 0) {
    throw "Unknown skill name(s): $($unknownNames -join ', ')"
  }
  $entries = @($entries | Where-Object { $requestedNames -contains [string]$_.name })
}

$sourceFull = Get-NormalizedFullPath -Path $sourceRoot -Label "Source skill root"
Assert-NoPathAlias -Path $sourceFull -Label "Source skill root"

$sourcePathByName = @{}
foreach ($entry in $entries) {
  $name = [string]$entry.name
  $src = Get-NormalizedFullPath -Path (Join-Path $PSScriptRoot ([string]$entry.path)) -Label "Source skill '$name'"

  if (-not (Test-SameOrChildPath -Candidate $src -Root $sourceFull)) {
    throw "Registered source path for '$name' escapes the source skill root"
  }

  Assert-NoLinksInTree -Path $src -Label "Source skill '$name'"
  Assert-SkillBundle -Path $src -ExpectedName $name
  $sourcePathByName[$name] = $src
}

$targetFull = Get-NormalizedFullPath -Path $TargetRoot -Label "TargetRoot"
$targetParent = Split-Path $targetFull -Parent
$targetLeaf = Split-Path $targetFull -Leaf
if ([string]::IsNullOrWhiteSpace($targetParent) -or [string]::IsNullOrWhiteSpace($targetLeaf)) {
  throw "TargetRoot must have a parent directory"
}

Assert-NoPathAlias -Path $targetFull -Label "TargetRoot"
if (Test-Path -LiteralPath $targetFull) {
  if (-not (Test-Path -LiteralPath $targetFull -PathType Container)) {
    throw "TargetRoot must be a directory"
  }
}

if ((Test-SameOrChildPath -Candidate $targetFull -Root $sourceFull) -or
    (Test-SameOrChildPath -Candidate $sourceFull -Root $targetFull)) {
  throw "TargetRoot must not overlap the repository source skill root"
}

if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
  $BackupRoot = Join-Path $targetParent ($targetLeaf + "-backups")
}

$backupFull = Get-NormalizedFullPath -Path $BackupRoot -Label "BackupRoot"
$backupRootLeaf = Split-Path $backupFull -Leaf
if ([string]::IsNullOrWhiteSpace($backupRootLeaf)) {
  throw "BackupRoot must not be a filesystem root"
}

Assert-NoPathAlias -Path $backupFull -Label "BackupRoot"
if (Test-Path -LiteralPath $backupFull) {
  if (-not (Test-Path -LiteralPath $backupFull -PathType Container)) {
    throw "BackupRoot must be a directory"
  }
}

if (Test-SameOrChildPath -Candidate $backupFull -Root $targetFull) {
  throw "BackupRoot must be outside TargetRoot so backups are not discoverable as active skills"
}

if ((Test-SameOrChildPath -Candidate $backupFull -Root $sourceFull) -or
    (Test-SameOrChildPath -Candidate $sourceFull -Root $backupFull)) {
  throw "BackupRoot must not overlap the repository source skill root"
}

$TargetRoot = $targetFull
$BackupRoot = $backupFull

if (-not (Test-Path -LiteralPath $TargetRoot)) {
  if ($DryRun) {
    Write-Output "[DRY RUN] Would create $TargetRoot"
  } else {
    New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
  }
}

$backupRunId = (Get-Date -Format "yyyyMMdd-HHmmss-fff") + "-" + [guid]::NewGuid().ToString("N")
$backupRunRoot = Join-Path $BackupRoot $backupRunId
$stagingRoot = Join-Path $targetParent (".skill-install-staging-" + [guid]::NewGuid().ToString("N"))

try {
  if (-not $DryRun) {
    New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
  }

  foreach ($entry in $entries) {
    $name = [string]$entry.name
    $src = [string]$sourcePathByName[$name]
    $dst = Join-Path $TargetRoot $name

    if (Test-Path -LiteralPath $dst) {
      Assert-NoLinksInTree -Path $dst -Label "Installed skill destination '$name'"
    }

    $sourceFingerprint = Get-DirectoryFingerprint -Path $src
    $destinationFingerprint = Get-DirectoryFingerprint -Path $dst

    if ($null -ne $destinationFingerprint -and $destinationFingerprint -eq $sourceFingerprint) {
      Write-Output $(if ($DryRun) { "[DRY RUN] Unchanged $name" } else { "[UNCHANGED] $name" })
      continue
    }

    if ($DryRun) {
      if (Test-Path -LiteralPath $dst) {
        Write-Output "[DRY RUN] Would back up $dst -> $backupRunRoot"
      }
      Write-Output "[DRY RUN] Would stage and install $name -> $dst"
      continue
    }

    $stagePath = Join-Path $stagingRoot $name
    if (Test-Path -LiteralPath $stagePath) { Remove-Item -LiteralPath $stagePath -Recurse -Force }
    Copy-Item -LiteralPath $src -Destination $stagePath -Recurse -Force

    Assert-SkillBundle -Path $stagePath -ExpectedName $name
    if ((Get-DirectoryFingerprint -Path $stagePath) -ne $sourceFingerprint) {
      throw "Staging verification failed for $name"
    }

    $backupPath = $null
    if (Test-Path -LiteralPath $dst) {
      New-Item -ItemType Directory -Path $backupRunRoot -Force | Out-Null
      $backupPath = Join-Path $backupRunRoot $name
      Copy-Item -LiteralPath $dst -Destination $backupPath -Recurse -Force

      if ((Get-DirectoryFingerprint -Path $backupPath) -ne $destinationFingerprint) {
        throw "Backup verification failed for $name"
      }
    }

    try {
      if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
      Move-Item -LiteralPath $stagePath -Destination $dst

      Assert-SkillBundle -Path $dst -ExpectedName $name
      if ((Get-DirectoryFingerprint -Path $dst) -ne $sourceFingerprint) {
        throw "Installed verification failed for $name"
      }

      Write-Output "[INSTALLED] $name"
    } catch {
      $installError = $_

      try {
        if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }

        if ($null -ne $backupPath -and (Test-Path -LiteralPath $backupPath)) {
          Copy-Item -LiteralPath $backupPath -Destination $dst -Recurse -Force
          if ((Get-DirectoryFingerprint -Path $dst) -ne $destinationFingerprint) {
            throw "Restored content verification failed for $name"
          }
          Write-Output "[RESTORED] $name"
        }
      } catch {
        throw "Install failed for '$name' and automatic restore also failed. Original error: $($installError.Exception.Message). Restore error: $($_.Exception.Message)"
      }

      throw $installError
    } finally {
      if (Test-Path -LiteralPath $stagePath) { Remove-Item -LiteralPath $stagePath -Recurse -Force }
    }
  }
} finally {
  if (-not $DryRun -and (Test-Path -LiteralPath $stagingRoot)) {
    Remove-Item -LiteralPath $stagingRoot -Recurse -Force
  }
}

Write-Output "Done."

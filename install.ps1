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

function Assert-SkillBundle {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$ExpectedName
  )

  $skillPath = Join-Path $Path "SKILL.md"
  if (-not (Test-Path $skillPath)) {
    throw "Invalid skill bundle '$ExpectedName': missing SKILL.md"
  }

  $raw = Get-Content $skillPath -Raw
  if (-not $raw.StartsWith("---")) {
    throw "Invalid skill bundle '$ExpectedName': missing YAML frontmatter opener"
  }
  if ($raw -notmatch "(?m)^name:\s+$([regex]::Escape($ExpectedName))\s*$") {
    throw "Invalid skill bundle '$ExpectedName': frontmatter name mismatch"
  }
}

function Get-DirectoryFingerprint {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (-not (Test-Path $Path)) { return $null }

  $root = (Resolve-Path $Path).Path
  $rows = Get-ChildItem $root -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
      $relative = [System.IO.Path]::GetRelativePath($root, $_.FullName).Replace("\", "/")
      $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
      "$relative|$hash"
    }

  return ($rows -join "`n")
}

if (-not (Test-Path $registryPath)) {
  throw "Missing REGISTRY.json"
}

$registry = Get-Content $registryPath -Raw | ConvertFrom-Json
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
  $entries = @($entries | Where-Object { $_.kind -eq "generic" })
}

if ($hasExplicitSelection) {
  $knownNames = @($registry.skills | ForEach-Object { [string]$_.name })
  $unknownNames = @($requestedNames | Where-Object { $knownNames -notcontains $_ })
  if ($unknownNames.Count -gt 0) {
    throw "Unknown skill name(s): $($unknownNames -join ', ')"
  }
  $entries = @($entries | Where-Object { $requestedNames -contains [string]$_.name })
}

$targetFull = [System.IO.Path]::GetFullPath($TargetRoot)
$targetParent = Split-Path $targetFull -Parent
$targetLeaf = Split-Path $targetFull -Leaf
if ([string]::IsNullOrWhiteSpace($targetParent) -or [string]::IsNullOrWhiteSpace($targetLeaf)) {
  throw "TargetRoot must have a parent directory"
}

if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
  $BackupRoot = Join-Path $targetParent ($targetLeaf + "-backups")
}

$backupFull = [System.IO.Path]::GetFullPath($BackupRoot)
$separator = [System.IO.Path]::DirectorySeparatorChar
$targetPrefix = $targetFull.TrimEnd([char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)) + $separator
if ($backupFull -eq $targetFull -or $backupFull.StartsWith($targetPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "BackupRoot must be outside TargetRoot so backups are not discoverable as active skills"
}

if (-not (Test-Path $TargetRoot)) {
  if ($DryRun) {
    Write-Output "[DRY RUN] Would create $TargetRoot"
  } else {
    New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
  }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
$backupRunRoot = Join-Path $BackupRoot $stamp
$stagingRoot = Join-Path $targetParent (".skill-install-staging-" + [guid]::NewGuid().ToString("N"))

try {
  if (-not $DryRun) {
    New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
  }

  foreach ($entry in $entries) {
    $name = [string]$entry.name
    $src = Join-Path $PSScriptRoot ([string]$entry.path)
    $dst = Join-Path $TargetRoot $name

    Assert-SkillBundle -Path $src -ExpectedName $name

    $sourceFingerprint = Get-DirectoryFingerprint -Path $src
    $destinationFingerprint = Get-DirectoryFingerprint -Path $dst

    if ($null -ne $destinationFingerprint -and $destinationFingerprint -eq $sourceFingerprint) {
      Write-Output $(if ($DryRun) { "[DRY RUN] Unchanged $name" } else { "[UNCHANGED] $name" })
      continue
    }

    if ($DryRun) {
      if (Test-Path $dst) {
        Write-Output "[DRY RUN] Would back up $dst -> $backupRunRoot"
      }
      Write-Output "[DRY RUN] Would stage and install $name -> $dst"
      continue
    }

    $stagePath = Join-Path $stagingRoot $name
    if (Test-Path $stagePath) { Remove-Item $stagePath -Recurse -Force }
    Copy-Item $src $stagePath -Recurse -Force

    Assert-SkillBundle -Path $stagePath -ExpectedName $name
    if ((Get-DirectoryFingerprint -Path $stagePath) -ne $sourceFingerprint) {
      throw "Staging verification failed for $name"
    }

    $backupPath = $null
    if (Test-Path $dst) {
      New-Item -ItemType Directory -Path $backupRunRoot -Force | Out-Null
      $backupPath = Join-Path $backupRunRoot $name
      Copy-Item $dst $backupPath -Recurse -Force

      if ((Get-DirectoryFingerprint -Path $backupPath) -ne $destinationFingerprint) {
        throw "Backup verification failed for $name"
      }
    }

    try {
      if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
      Move-Item $stagePath $dst

      Assert-SkillBundle -Path $dst -ExpectedName $name
      if ((Get-DirectoryFingerprint -Path $dst) -ne $sourceFingerprint) {
        throw "Installed verification failed for $name"
      }

      Write-Output "[INSTALLED] $name"
    } catch {
      $installError = $_

      try {
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }

        if ($null -ne $backupPath -and (Test-Path $backupPath)) {
          Copy-Item $backupPath $dst -Recurse -Force
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
      if (Test-Path $stagePath) { Remove-Item $stagePath -Recurse -Force }
    }
  }
} finally {
  if (-not $DryRun -and (Test-Path $stagingRoot)) {
    Remove-Item $stagingRoot -Recurse -Force
  }
}

Write-Output "Done."

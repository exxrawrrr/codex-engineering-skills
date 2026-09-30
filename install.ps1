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
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
  $targetParent = Split-Path $targetFull -Parent
  $targetLeaf = Split-Path $targetFull -Leaf
  if ([string]::IsNullOrWhiteSpace($targetParent) -or [string]::IsNullOrWhiteSpace($targetLeaf)) {
    throw "TargetRoot must have a parent directory so backups can live outside the skill discovery root"
  }
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

foreach ($entry in $entries) {
  $name = [string]$entry.name
  $src = Join-Path $PSScriptRoot ([string]$entry.path)
  $dst = Join-Path $TargetRoot $name

  if (-not (Test-Path (Join-Path $src "SKILL.md"))) {
    throw "Invalid registry entry or bundle: $name"
  }

  if (Test-Path $dst) {
    if ($DryRun) {
      Write-Output "[DRY RUN] Would back up $dst -> $backupRunRoot"
    } else {
      New-Item -ItemType Directory -Path $backupRunRoot -Force | Out-Null
      Copy-Item $dst (Join-Path $backupRunRoot $name) -Recurse -Force
    }
  }

  if ($DryRun) {
    Write-Output "[DRY RUN] Would install $name -> $dst"
  } else {
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $src $dst -Recurse -Force
    Write-Output "[INSTALLED] $name"
  }
}

Write-Output "Done."

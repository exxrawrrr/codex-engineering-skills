param(
  [string]$SkillsRoot = "$PSScriptRoot\skills",
  [string]$RegistryPath = "$PSScriptRoot\REGISTRY.json"
)

$ErrorActionPreference = "Stop"
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

if ($fail.Count -eq 0) {
  $names = New-Object System.Collections.Generic.HashSet[string]

  foreach ($entry in $registry.skills) {
    $name = [string]$entry.name
    $kind = [string]$entry.kind
    $relativePath = [string]$entry.path

    if ([string]::IsNullOrWhiteSpace($name)) {
      $fail.Add("Registry entry has empty name")
      continue
    }

    if (-not $names.Add($name)) {
      $fail.Add("Duplicate registry skill name: $name")
    }

    if ($kind -notin @("generic","project")) {
      $fail.Add("$($name): invalid kind '$kind'")
    }

    $dir = Join-Path $PSScriptRoot $relativePath
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

    if (-not $raw.StartsWith("---")) {
      $fail.Add("$($name): missing YAML frontmatter opener")
    }
    if ($raw -notmatch "(?m)^name:\s+$([regex]::Escape($name))\s*$") {
      $fail.Add("$($name): frontmatter name does not match registry/directory")
    }
    if ($raw -notmatch "(?m)^description:\s+.+$") {
      $fail.Add("$($name): missing description")
    }
    if ($raw.Contains([char]0xFFFD)) {
      $fail.Add("$($name): contains Unicode replacement character U+FFFD")
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
      if ($fileRaw.Contains([char]0xFFFD)) {
        $fail.Add("$($name): replacement character in $($_.FullName)")
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

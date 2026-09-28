param(
  [string]$SkillsRoot = "$env:USERPROFILE\.codex\skills"
)

$ErrorActionPreference = "Stop"

$required = @(
  "typescript-node-architecture",
  "monorepo-typescript",
  "sqlite-data-modeling",
  "resilient-crawler-engineering",
  "application-security-local-first",
  "testing-typescript-systems",
  "growthops-engineering"
)

$generic = @(
  "typescript-node-architecture",
  "monorepo-typescript",
  "sqlite-data-modeling",
  "resilient-crawler-engineering",
  "application-security-local-first",
  "testing-typescript-systems"
)

$recommended = @(
  "systematic-debugging",
  "verification-loop",
  "requesting-code-review",
  "codebase-onboarding",
  "playwright-cli",
  "vercel-react-best-practices",
  "web-design-guidelines"
)

$fail = New-Object System.Collections.Generic.List[string]
$warn = New-Object System.Collections.Generic.List[string]
$pass = New-Object System.Collections.Generic.List[string]

foreach ($name in $required) {
  $dir = Join-Path $SkillsRoot $name
  $skill = Join-Path $dir "SKILL.md"

  if (-not (Test-Path $skill)) {
    $fail.Add("Missing required skill: $name")
    continue
  }

  $raw = Get-Content $skill -Raw
  $lines = Get-Content $skill

  if (-not $raw.StartsWith("---")) {
    $fail.Add("$($name): missing YAML frontmatter opener")
  }

  if ($raw -notmatch "(?m)^name:\s+$([regex]::Escape($name))\s*$") {
    $fail.Add("$($name): frontmatter name does not match directory")
  }

  if ($raw -notmatch "(?m)^description:\s+.+$") {
    $fail.Add("$($name): missing description")
  }

  if ($raw.Contains([char]0xFFFD)) {
    $fail.Add("$($name): contains Unicode replacement character U+FFFD")
  }

  if ($lines.Count -gt 500) {
    $warn.Add("$($name): SKILL.md exceeds 500 lines ($($lines.Count)); consider progressive disclosure")
  } else {
    $pass.Add("$($name): SKILL.md size OK ($($lines.Count) lines)")
  }

  $refs = [regex]::Matches($raw, 'references/[A-Za-z0-9._/-]+\.md') |
    ForEach-Object { $_.Value } |
    Sort-Object -Unique

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

  if ($generic -contains $name) {
    $growthopsMentions = Get-ChildItem $dir -Recurse -File |
      Select-String -Pattern "GrowthOps" -SimpleMatch -ErrorAction SilentlyContinue
    if ($growthopsMentions) {
      $warn.Add("$($name): generic skill still contains project-specific GrowthOps text")
    }
  }
}

foreach ($name in $recommended) {
  if (Test-Path (Join-Path $SkillsRoot $name)) {
    $pass.Add("Supporting skill present: $name")
  } else {
    $warn.Add("Supporting skill missing: $name")
  }
}

$router = Join-Path $SkillsRoot "growthops-engineering"
foreach ($requiredFile in @(
  "suite-manifest.json",
  "references\source-provenance.md",
  "references\public-adaptation-guide.md",
  "scripts\validate-suite.ps1"
)) {
  if (Test-Path (Join-Path $router $requiredFile)) {
    $pass.Add("Suite maintenance asset present: $requiredFile")
  } else {
    $fail.Add("Suite maintenance asset missing: $requiredFile")
  }
}

Write-Output "=== GrowthOps Skill Suite Validation ==="
Write-Output "Skills root: $SkillsRoot"
Write-Output ""

foreach ($item in $pass) { Write-Output "[PASS] $item" }
foreach ($item in $warn) { Write-Output "[WARN] $item" }
foreach ($item in $fail) { Write-Output "[FAIL] $item" }

Write-Output ""
Write-Output ("PASS={0} WARN={1} FAIL={2}" -f $pass.Count,$warn.Count,$fail.Count)

if ($fail.Count -gt 0) { exit 1 }
exit 0

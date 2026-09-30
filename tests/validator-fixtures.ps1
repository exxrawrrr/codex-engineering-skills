$ErrorActionPreference = "Stop"

$root = Split-Path $PSScriptRoot -Parent
$validator = Join-Path $root "validate.ps1"
$fixtureRoot = Join-Path $root "evidence\fixtures\validation"
$tempSkills = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-skill-validator-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempSkills -Force | Out-Null

function Assert-RejectedRegistry {
  param(
    [Parameter(Mandatory = $true)][string]$FixtureName,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )

  $fixture = Join-Path $fixtureRoot $FixtureName
  $output = & pwsh -NoProfile -File $validator -SkillsRoot $tempSkills -RegistryPath $fixture 2>&1
  $exitCode = $LASTEXITCODE
  $text = ($output | ForEach-Object { [string]$_ }) -join "`n"

  if ($exitCode -eq 0) {
    throw "Expected validator to reject $FixtureName"
  }
  if ($text -notmatch [regex]::Escape($ExpectedText)) {
    throw "Validator rejected $FixtureName for the wrong reason. Expected '$ExpectedText'. Output: $text"
  }

  Write-Output "[PASS] $FixtureName rejected with '$ExpectedText'"
}

try {
  Assert-RejectedRegistry -FixtureName "invalid-status-registry.json" -ExpectedText "invalid status"
  Assert-RejectedRegistry -FixtureName "broken-path-registry.json" -ExpectedText "registered path missing"
} finally {
  Remove-Item $tempSkills -Recurse -Force -ErrorAction SilentlyContinue
}

exit 0

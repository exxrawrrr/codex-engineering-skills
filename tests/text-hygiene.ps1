$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "validate.ps1"
$fixtureRoot = Join-Path $repoRoot "evidence/fixtures/validation"

function Assert-HygieneFixture {
  param(
    [Parameter(Mandatory = $true)][string]$FixtureName,
    [Parameter(Mandatory = $true)][string]$ExpectedReason
  )

  $fixture = Join-Path $fixtureRoot $FixtureName
  if (-not (Test-Path $fixture)) {
    throw "Missing text-hygiene fixture: $FixtureName"
  }

  $output = & pwsh -NoProfile -File $validator -ExpectTextHygieneFailurePath $fixture 2>&1
  $exitCode = $LASTEXITCODE
  $text = ($output | ForEach-Object { [string]$_ }) -join "`n"

  if ($exitCode -ne 0) {
    throw "Validator failed to recognize $FixtureName as an expected invalid fixture. Output: $text"
  }
  if ($text -notmatch [regex]::Escape($ExpectedReason)) {
    throw "Validator rejected $FixtureName for the wrong reason. Expected '$ExpectedReason'. Output: $text"
  }

  Write-Output "[PASS] $FixtureName -> $ExpectedReason"
}

Assert-HygieneFixture -FixtureName "mojibake-sample.txt" -ExpectedReason "common mojibake marker"
Assert-HygieneFixture -FixtureName "mojibake-extended-sample.txt" -ExpectedReason "common mojibake marker"
Assert-HygieneFixture -FixtureName "bom-sample.txt" -ExpectedReason "UTF-8 BOM"
Assert-HygieneFixture -FixtureName "replacement-character-sample.txt" -ExpectedReason "Unicode replacement character U+FFFD"

Write-Output "[PASS] text-hygiene claim coverage matches documented BOM/U+FFFD/mojibake checks"
exit 0

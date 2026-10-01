$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "tests/phase17-release-contract.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-phase17-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  foreach ($dir in @(
    "evidence/releases",
    "evidence/lifecycle",
    "evidence/evaluations/results",
    "evidence/evaluations",
    "docs/releases"
  )) {
    New-Item -ItemType Directory -Path (Join-Path $root $dir) -Force | Out-Null
  }

  $copies = @{
    "REGISTRY.json" = "REGISTRY.json"
    "README.md" = "README.md"
    "install.ps1" = "install.ps1"
    "evidence/releases/v1.2.0-vnext-acceptance-2026-10-01.json" = "evidence/releases/v1.2.0-vnext-acceptance-2026-10-01.json"
    "evidence/lifecycle/phase16-review-2026-10-01.json" = "evidence/lifecycle/phase16-review-2026-10-01.json"
    "evidence/evaluations/results/phase17-supply-chain-comparison-2026-10-01.json" = "evidence/evaluations/results/phase17-supply-chain-comparison-2026-10-01.json"
    "evidence/evaluations/cases.json" = "evidence/evaluations/cases.json"
    "evidence/evaluations/context-current.json" = "evidence/evaluations/context-current.json"
    "docs/releases/v1.2.0-vnext.md" = "docs/releases/v1.2.0-vnext.md"
  }
  foreach ($source in $copies.Keys) {
    $dest = Join-Path $root $copies[$source]
    Copy-Item -LiteralPath (Join-Path $repoRoot $source) -Destination $dest
  }

  return @{
    Root = $root
    ReportPath = Join-Path $root "evidence/releases/v1.2.0-vnext-acceptance-2026-10-01.json"
    RegistryPath = Join-Path $root "REGISTRY.json"
    Phase16Path = Join-Path $root "evidence/lifecycle/phase16-review-2026-10-01.json"
    ComparativeResultPath = Join-Path $root "evidence/evaluations/results/phase17-supply-chain-comparison-2026-10-01.json"
    CasesPath = Join-Path $root "evidence/evaluations/cases.json"
    ContextPath = Join-Path $root "evidence/evaluations/context-current.json"
    ReadmePath = Join-Path $root "README.md"
    InstallPath = Join-Path $root "install.ps1"
    ReleaseNotesPath = Join-Path $root "docs/releases/v1.2.0-vnext.md"
  }
}

function Save-Json {
  param([string]$Path,[object]$Value)
  $Value | ConvertTo-Json -Depth 80 | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

function Invoke-Contract {
  param([hashtable]$Sandbox)
  $output = & pwsh -NoProfile -File $validator `
    -ReportPath $Sandbox.ReportPath `
    -RegistryPath $Sandbox.RegistryPath `
    -Phase16Path $Sandbox.Phase16Path `
    -ComparativeResultPath $Sandbox.ComparativeResultPath `
    -CasesPath $Sandbox.CasesPath `
    -ContextPath $Sandbox.ContextPath `
    -ReadmePath $Sandbox.ReadmePath `
    -InstallPath $Sandbox.InstallPath `
    -ReleaseNotesPath $Sandbox.ReleaseNotesPath 2>&1
  return @{ ExitCode = $LASTEXITCODE; Text = (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine) }
}

function Assert-Passes {
  param([hashtable]$Sandbox)
  $r = Invoke-Contract -Sandbox $Sandbox
  if ($r.ExitCode -ne 0) { throw "Expected Phase 17 release contract to pass. Output: $($r.Text)" }
  if (-not $r.Text.Contains("PHASE17_RELEASE VERSION=1.2.0 CRITERIA=20 PASS=20 FAIL=0 NOT_RUN=0 RELEASE_READY=True ERRORS=0")) {
    throw "Phase 17 contract passed without expected summary. Output: $($r.Text)"
  }
  Write-Output "[PASS] valid v1.2.0 release-readiness report"
}

function Assert-Rejected {
  param([hashtable]$Sandbox,[string]$ExpectedText)
  $r = Invoke-Contract -Sandbox $Sandbox
  if ($r.ExitCode -eq 0) { throw "Expected Phase 17 rejection containing '$ExpectedText'. Output: $($r.Text)" }
  if (-not $r.Text.Contains($ExpectedText)) { throw "Phase 17 rejected for wrong reason. Expected '$ExpectedText'. Output: $($r.Text)" }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $valid = New-Sandbox -Name "valid"
  Assert-Passes -Sandbox $valid

  $futurePatch = New-Sandbox -Name "future-patch-version"
  $r = Get-Content -LiteralPath $futurePatch.RegistryPath -Raw | ConvertFrom-Json
  $r.version = "1.2.1"
  Save-Json -Path $futurePatch.RegistryPath -Value $r
  $text = Get-Content -LiteralPath $futurePatch.ReadmePath -Raw
  $text = $text.Replace("Current suite release: **v1.2.0**","Current suite release: **v1.2.1**")
  Set-Content -LiteralPath $futurePatch.ReadmePath -Value $text -Encoding utf8NoBOM
  Assert-Passes -Sandbox $futurePatch

  $versionDrift = New-Sandbox -Name "version-drift"
  $r = Get-Content -LiteralPath $versionDrift.RegistryPath -Raw | ConvertFrom-Json
  $r.version = "1.1.1"
  Save-Json -Path $versionDrift.RegistryPath -Value $r
  Assert-Rejected -Sandbox $versionDrift -ExpectedText "REGISTRY.version must be 1.2.0 for this release"

  $notRun = New-Sandbox -Name "criterion-not-run"
  $r = Get-Content -LiteralPath $notRun.ReportPath -Raw | ConvertFrom-Json
  (@($r.criteria | Where-Object { [int]$_.id -eq 8 })[0]).status = "NOT_RUN"
  Save-Json -Path $notRun.ReportPath -Value $r
  Assert-Rejected -Sandbox $notRun -ExpectedText "criterion 8: release-ready report requires PASS, observed 'NOT_RUN'"

  $phase16Open = New-Sandbox -Name "phase16-open"
  $r = Get-Content -LiteralPath $phase16Open.Phase16Path -Raw | ConvertFrom-Json
  $r.completion_state = "DECISIONS_LOCKED_CLEANUP_PENDING_16B"
  Save-Json -Path $phase16Open.Phase16Path -Value $r
  Assert-Rejected -Sandbox $phase16Open -ExpectedText "Phase 16 must be COMPLETE/16B and locked on 2026-10-01 before release"

  $comparisonDrift = New-Sandbox -Name "comparison-uplift-overclaim"
  $r = Get-Content -LiteralPath $comparisonDrift.ComparativeResultPath -Raw | ConvertFrom-Json
  $r.comparison_claim = "Selected skill improved the result."
  Save-Json -Path $comparisonDrift.ComparativeResultPath -Value $r
  Assert-Rejected -Sandbox $comparisonDrift -ExpectedText "Phase 17 comparative claim must explicitly avoid an uplift claim"

  $missingSelected = New-Sandbox -Name "missing-selected-treatment"
  $r = Get-Content -LiteralPath $missingSelected.ComparativeResultPath -Raw | ConvertFrom-Json
  $r.results = @($r.results | Where-Object { $_.variant -ne "selected_skills" })
  Save-Json -Path $missingSelected.ComparativeResultPath -Value $r
  Assert-Rejected -Sandbox $missingSelected -ExpectedText "Phase 17 comparison must contain exactly two matched treatment results"

  $runtimeGuard = New-Sandbox -Name "missing-runtime-guard"
  $text = Get-Content -LiteralPath $runtimeGuard.InstallPath -Raw
  $text = $text -replace '(?ms)if \(\$PSVersionTable\.PSEdition -ne "Core".*?^\}\r?\n\r?\n', ''
  Set-Content -LiteralPath $runtimeGuard.InstallPath -Value $text -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $runtimeGuard -ExpectedText "install.ps1 must fail fast outside PowerShell Core 7+"

  $legacyReadme = New-Sandbox -Name "legacy-readme"
  $text = Get-Content -LiteralPath $legacyReadme.ReadmePath -Raw
  $text = $text.Replace("pwsh -NoProfile -File .\install.ps1","powershell -ExecutionPolicy Bypass -File .\install.ps1")
  Set-Content -LiteralPath $legacyReadme.ReadmePath -Value $text -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $legacyReadme -ExpectedText "README must not recommend Windows PowerShell 5.1-style installer invocation"

  Write-Output "[PASS] Phase 17 version, acceptance, comparison, dependency, runtime, and documentation regressions are covered"
} finally {
  if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

exit 0

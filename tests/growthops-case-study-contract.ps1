$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$validator = Join-Path $repoRoot "tests/growthops-case-study.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-growthops-case-contract-" + [guid]::NewGuid().ToString("N"))

function New-Sandbox {
  param([Parameter(Mandatory = $true)][string]$Name)

  $root = Join-Path $tempRoot $Name
  New-Item -ItemType Directory -Path $root -Force | Out-Null

  $casePath = Join-Path $root "case.json"
  $indexPath = Join-Path $root "index.json"
  $registryPath = Join-Path $root "registry.json"
  $docPath = Join-Path $root "case-study.md"

  Copy-Item (Join-Path $repoRoot "evidence/cases/growthops-m01-m04.json") $casePath
  Copy-Item (Join-Path $repoRoot "evidence/INDEX.json") $indexPath
  Copy-Item (Join-Path $repoRoot "REGISTRY.json") $registryPath
  Copy-Item (Join-Path $repoRoot "docs/case-study-growthops-m01-m04.md") $docPath

  return @{
    Root = $root
    CasePath = $casePath
    IndexPath = $indexPath
    RegistryPath = $registryPath
    DocPath = $docPath
  }
}

function Invoke-Validator {
  param([Parameter(Mandatory = $true)][hashtable]$Sandbox)

  $output = & pwsh -NoProfile -File $validator `
    -CasePath $Sandbox.CasePath `
    -IndexPath $Sandbox.IndexPath `
    -RegistryPath $Sandbox.RegistryPath `
    -CaseStudyPath $Sandbox.DocPath 2>&1

  return @{
    ExitCode = $LASTEXITCODE
    Text = (($output | ForEach-Object { [string]$_ }) -join "`n")
  }
}

function Assert-Passes {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Sandbox,
    [Parameter(Mandatory = $true)][string]$ExpectedText
  )

  $result = Invoke-Validator -Sandbox $Sandbox
  if ($result.ExitCode -ne 0) {
    throw "Expected GrowthOps case validator to pass. Output: $($result.Text)"
  }
  if ($result.Text -notmatch [regex]::Escape($ExpectedText)) {
    throw "GrowthOps case validator passed without '$ExpectedText'. Output: $($result.Text)"
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
    throw "Expected GrowthOps case validator rejection containing '$ExpectedText'. Output: $($result.Text)"
  }
  if ($result.Text -notmatch [regex]::Escape($ExpectedText)) {
    throw "GrowthOps case validator rejected for the wrong reason. Expected '$ExpectedText'. Output: $($result.Text)"
  }
  Write-Output "[PASS] rejected with '$ExpectedText'"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

  $valid = New-Sandbox -Name "valid"
  Assert-Passes -Sandbox $valid -ExpectedText "GROWTHOPS_CASE MILESTONES=4 COMMITS=6 FAIL=0 STATE=PARTIALLY_VERIFIED"

  $badState = New-Sandbox -Name "bad-state"
  $case = Get-Content $badState.CasePath -Raw | ConvertFrom-Json
  $case.claim_state = "INFERRED"
  $case | ConvertTo-Json -Depth 20 | Set-Content $badState.CasePath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $badState -ExpectedText "claim_state must remain PARTIALLY_VERIFIED"

  $commitDrift = New-Sandbox -Name "commit-drift"
  $index = Get-Content $commitDrift.IndexPath -Raw | ConvertFrom-Json
  $record = @($index.records | Where-Object { $_.id -eq "growthops-m01-m04-observational-2026-09-30" })[0]
  $record.public_commits = @($record.public_commits | Where-Object { $_ -ne "b1bee1c9b80ad85d533fbd3fc3d102e489f49801" })
  $index | ConvertTo-Json -Depth 20 | Set-Content $commitDrift.IndexPath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $commitDrift -ExpectedText "implementation commit set must exactly match INDEX public_commits"

  $skillDrift = New-Sandbox -Name "skill-observation-drift"
  $case = Get-Content $skillDrift.CasePath -Raw | ConvertFrom-Json
  $case.skill_observations."monorepo-typescript" = "repeated"
  $case | ConvertTo-Json -Depth 20 | Set-Content $skillDrift.CasePath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $skillDrift -ExpectedText "skill_observations must exactly match INDEX record"

  $m05Leak = New-Sandbox -Name "m05-leak"
  $case = Get-Content $m05Leak.CasePath -Raw | ConvertFrom-Json
  $case.source_scope.included_milestones = @("M01","M02","M03","M04","M05")
  $case | ConvertTo-Json -Depth 20 | Set-Content $m05Leak.CasePath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $m05Leak -ExpectedText "source_scope must include exactly M01-M04"

  $privacyLeak = New-Sandbox -Name "privacy-leak"
  $case = Get-Content $privacyLeak.CasePath -Raw | ConvertFrom-Json
  $case.privacy_exclusions = @("private Codex transcripts","secrets or credentials","local-only session logs")
  $case | ConvertTo-Json -Depth 20 | Set-Content $privacyLeak.CasePath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $privacyLeak -ExpectedText "privacy_exclusions must explicitly cover transcripts, secrets, local logs, and M05-and-later work"

  $badSha = New-Sandbox -Name "bad-sha"
  $case = Get-Content $badSha.CasePath -Raw | ConvertFrom-Json
  $case.milestones[0].implementation_commits[0] = "164680e"
  $case | ConvertTo-Json -Depth 20 | Set-Content $badSha.CasePath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $badSha -ExpectedText "implementation commit is not a full lowercase SHA"

  $badCheckpoint = New-Sandbox -Name "bad-checkpoint"
  $case = Get-Content $badCheckpoint.CasePath -Raw | ConvertFrom-Json
  $case.milestones[1].checkpoint_path = "docs/implementation/M99_CHECKPOINT.md"
  $case | ConvertTo-Json -Depth 20 | Set-Content $badCheckpoint.CasePath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $badCheckpoint -ExpectedText "M02: checkpoint_path must be 'docs/implementation/M02_CHECKPOINT.md'"

  $lostNuance = New-Sandbox -Name "lost-m04-nuance"
  $case = Get-Content $lostNuance.CasePath -Raw | ConvertFrom-Json
  $case.milestones[3].notes = "All routing guidance was available in every M04 slice."
  $case | ConvertTo-Json -Depth 20 | Set-Content $lostNuance.CasePath -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $lostNuance -ExpectedText "M04: notes must preserve the M04-A2 router-unavailable nuance"

  $docCommitDrift = New-Sandbox -Name "doc-commit-drift"
  $doc = Get-Content $docCommitDrift.DocPath -Raw
  $doc = $doc.Replace("b1bee1c9b80ad85d533fbd3fc3d102e489f49801","MISSING_M04_MERGE_SHA")
  Set-Content $docCommitDrift.DocPath -Value $doc -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $docCommitDrift -ExpectedText "case-study document missing commit b1bee1c9b80ad85d533fbd3fc3d102e489f49801"

  $docScopeDrift = New-Sandbox -Name "doc-scope-drift"
  $doc = Get-Content $docScopeDrift.DocPath -Raw
  $doc = $doc.Replace("M05 and later work are outside this case study","Future work is omitted")
  Set-Content $docScopeDrift.DocPath -Value $doc -Encoding utf8NoBOM
  Assert-Rejected -Sandbox $docScopeDrift -ExpectedText "Case-study document missing boundary marker: M05 and later work are outside this case study"

  Write-Output "[PASS] GrowthOps evidence case-study negative contract is regression-covered"
} finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

exit 0

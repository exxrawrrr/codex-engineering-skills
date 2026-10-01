# Repository Safety Audit & Hardening Implementation Plan

**Implementation lock status:** Tasks 1–7 COMPLETE. Release `v1.2.1` was published from protected-main release commit `4b4238da8d97b41568a191711e3e6ae23161088c` after green PR and post-merge CI.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Audit and harden codex-engineering-skills so public users can install/update it with safer defaults, deterministic failure behavior, trustworthy CI, and truthful maintenance documentation.

**Architecture:** Keep the existing small PowerShell-first design. Harden the installer at its current boundaries instead of introducing a package manager or release automation framework. Treat v1.2.0 evidence as immutable historical evidence while making future releases possible.

**Tech Stack:** PowerShell Core 7+, GitHub Actions, JSON/Markdown evidence contracts, GitHub branch protection.

**Spec:** User request in this conversation: audit everything for cleanliness, quality, function, errors/bugs, and make installation/use safe and smooth.

## Global Constraints

- Preserve `SKILL.md` content unless a concrete behavioral defect is demonstrated; stylistic skill improvements are audit findings, not automatic edits.
- Production bug fixes follow RED → GREEN.
- Do not change the current default full-registry selection silently; preserve compatibility but warn when project-specific skills are included.
- General-user documentation should recommend `-GenericOnly` or explicit `-SkillName`.
- Keep backups outside the active discovery root.
- Keep PowerShell Core 7+ as the executable tooling floor.
- Keep v1.2.0 evidence/release files historical and immutable.
- Do not claim runtime-loading support that was not executed.

## Review Focus

- Default install path on non-Windows hosts must resolve to the real user home, not a Windows-only environment variable.
- Concurrent installers targeting the same skill root must not mutate the target simultaneously.
- A malformed or path-escaping skill reference must be rejected before installation/validation.
- Historical v1.2.0 release tests must not prevent a future registry version.
- CI must not execute a mutable third-party action ref for checkout.

---

### Task 1: Installer default-path and concurrency safety

**Files:**
- Modify: `tests/installer-selection.ps1`
- Modify: `install.ps1`

**Interfaces:**
- Consumes: current `-TargetRoot`, `-BackupRoot`, `-GenericOnly`, `-SkillName` installer interface.
- Produces: cross-platform default target resolution and a per-target exclusive installation lock.

- [x] **Step 1: Write failing tests**
  - Default target derives from the runtime user home on Windows/Linux instead of direct `$env:USERPROFILE` concatenation.
  - A held sibling lock file rejects a second mutating install before target content changes.
  - Dry-run remains non-mutating and does not require an install lock.

- [x] **Step 2: Run focused installer-selection test and verify RED**
  - Expected: default-target/lock assertions fail against current installer.

- [x] **Step 3: Implement minimal installer fix**
  - Resolve default target after startup using the runtime user profile/home.
  - Acquire an exclusive `<TargetRoot>.install.lock` FileStream for non-dry-run invocations.
  - Hold the handle through transaction cleanup and release it in `finally`.
  - Emit a clear error when another installer owns the target lock.

- [x] **Step 4: Run installer selection + transaction tests and verify GREEN**

- [x] **Step 5: Commit focused installer-safety change**

---

### Task 2: Installer bundle validation and safe public default guidance

**Files:**
- Modify: `tests/installer-selection.ps1`
- Modify: `install.ps1`
- Modify: `README.md`

**Interfaces:**
- Consumes: selected source skill bundles from Task 1.
- Produces: stricter pre-mutation bundle checks and explicit full-registry/project-skill warning.

- [x] **Step 1: Write failing tests**
  - Missing frontmatter closer is rejected.
  - Missing frontmatter description is rejected.
  - A `references/../...` escape is rejected.
  - Full-registry install output warns when project-specific skills are included.

- [x] **Step 2: Run focused test and verify RED**

- [x] **Step 3: Implement minimal validation/warning behavior**
  - Strengthen `Assert-SkillBundle`.
  - Canonicalize referenced Markdown paths and require containment under the skill directory.
  - Preserve full-registry default for compatibility, but warn and recommend `-GenericOnly` / `-SkillName`.

- [x] **Step 4: Update README installation flow**
  - Make `-GenericOnly` the recommended general-user command.
  - Label no-selection install as advanced/full registry including project-specific entries.
  - Document lock behavior and cross-platform default home resolution.

- [x] **Step 5: Run installer tests and validator**

---

### Task 3: Static validator correctness hardening

**Files:**
- Modify: `tests/static-validator-contract.ps1`
- Modify: `validate.ps1`

**Interfaces:**
- Consumes: registry, evidence index, skill tree.
- Produces: stronger rejection of invalid evidence and escaped references.

- [x] **Step 1: Write failing static-validator fixtures**
  - Evidence `skill_observations` naming an unregistered skill fails.
  - Registry version not matching SemVer `X.Y.Z` fails.
  - A reference path escaping a skill directory fails.

- [x] **Step 2: Run static-validator contract and verify RED**

- [x] **Step 3: Implement minimal validator checks**

- [x] **Step 4: Run validator fixture suite and root validator**

---

### Task 4: CI supply-chain and bounded-runtime hardening

**Files:**
- Modify: `.github/workflows/validate.yml`
- Modify: `tests/ci-workflow-contract.ps1`

**Interfaces:**
- Consumes: existing Windows/Ubuntu matrix.
- Produces: immutable checkout pin + bounded workflow runtime.

- [x] **Step 1: Write failing CI contract assertions**
  - checkout must use exact commit `3d3c42e5aac5ba805825da76410c181273ba90b1` with version comment `v7.0.1`.
  - validate job must have a finite `timeout-minutes`.

- [x] **Step 2: Run CI contract and verify RED**

- [x] **Step 3: Pin checkout action and add timeout**

- [x] **Step 4: Run CI contract and root validation**

---

### Task 5: Future-release blocker removal

**Files:**
- Modify: `tests/phase17-release-contract.ps1`
- Modify: `tests/phase17-release-contract-fixtures.ps1`

**Interfaces:**
- Consumes: immutable v1.2.0 acceptance report/release notes.
- Produces: historical v1.2.0 validation that no longer freezes the current suite version or README current-release string.

- [x] **Step 1: Write fixture proving registry version `1.2.1` and a future README current-version can coexist with valid historical v1.2.0 evidence**
- [x] **Step 2: Run fixture and verify RED**
- [x] **Step 3: Remove only current-state coupling from historical Phase 17 contract**
- [x] **Step 4: Run Phase 17 contract + fixtures and verify GREEN**

---

### Task 6: Documentation and audit record

**Files:**
- Modify: `CONTRIBUTING.md`
- Modify: `COMPATIBILITY.md`
- Create: `docs/audits/2026-10-01-repository-safety-audit.md`

**Interfaces:**
- Consumes: verified findings from Tasks 1–5 plus current skill inventory.
- Produces: factual current maintenance guidance and skill-by-skill audit matrix.

- [x] **Step 1: Correct stale contributor language (`six reusable skills` → current generic/project contract without fragile hard-coded count)**
- [x] **Step 2: Label the 2026-09-30 compatibility run clearly as a historical snapshot and point readers to newer CI for current repository health without rewriting old evidence**
- [x] **Step 3: Record audit matrix for all 13 skills: routing clarity, scope, completion guidance, evidence tier, overlap risk, and deferred improvement notes**
- [x] **Step 4: Record repo hygiene findings: no secret-pattern hits, no symlinks, no >200 KB files, no broken relative Markdown links, index LF / Windows checkout CRLF normalization**
- [x] **Step 5: Record unresolved evidence limits (macOS/runtime-loading/router obedience/incubating effectiveness)**

---

### Task 7: Real smoke, full CI, repository governance, and patch release

**Files / settings:**
- Modify: `REGISTRY.json` only if patch release is justified after fixes.
- Create: `docs/releases/v1.2.1-safety-hardening.md` if releasing.
- GitHub setting: protect `main` with required Windows + Ubuntu validation checks and PR-only changes, without requiring an unavailable second human reviewer.

**Interfaces:**
- Consumes: all hardened behavior.
- Produces: verified public state.

- [x] **Step 1: Run real temporary-clone smoke on Remote GROWTH Stable; never touch the user's live Codex skill directory**
- [x] **Step 2: Run complete GitHub PR CI on Windows + Ubuntu**
- [x] **Step 3: Perform whole-branch review against this plan; fix Critical/Important findings with RED→GREEN**
- [x] **Step 4: Merge only after full green verification**
- [x] **Step 5: Verify post-merge main CI**
- [x] **Step 6: Enable `main` branch protection requiring PR + validation checks if GitHub plan/permissions support it**
- [x] **Step 7: If code changes are merged, publish patch `v1.2.1` after green main CI; do not rewrite v1.2.0 historical evidence**

## Self-review

- Spec coverage: covers skill quality, repo hygiene, installer user safety, CI integrity, release maintainability, and governance.
- Shared interfaces: Tasks 1–2 both touch installer; Task 5 is prerequisite to Task 7 version bump; Task 4 determines branch-protection check names.
- Review focus tests are assigned to Tasks 1–5.
- No skill content edits are planned without behavioral evidence; skill-specific wording improvements are audit findings only.

# Repository Safety Audit — 2026-10-01

Repository: `exxrawrrr/codex-engineering-skills`  
Audit baseline: `38625ccb5258260a7d24a41c28fd98362347b90a`  
Audit branch: `audit/installation-safety-2026-10-01`  
Scope: repository hygiene, skill quality, installer/update safety, validator correctness, CI integrity, release maintainability, and public-user installation experience.

## Executive summary

The repository is structurally small and understandable: 13 registered skills, one project-specific router, one PowerShell installer, one root validator, and a Windows + Ubuntu validation matrix.

The audit found no secret-pattern hits, tracked symlinks, large tracked binaries, broken relative Markdown links, or trailing-whitespace findings in the baseline scan. The strongest defects were not visual clutter; they were edge cases around installation and future maintenance.

The audit hardening branch addresses:

1. cross-platform default target resolution;
2. concurrent installer mutation of the same target;
3. malformed source bundles being accepted by the installer;
4. skill-reference path escapes;
5. evidence records naming unregistered skills;
6. missing registry SemVer validation;
7. mutable GitHub Actions checkout input;
8. unbounded CI job runtime;
9. a historical v1.2.0 test that accidentally froze the repository's future current version;
10. stale contributor/compatibility wording.

Skill content itself was not mass-edited. No concrete skill-content defect justified rewriting the 13 instruction packages during this audit, and the repository's own evidence discipline says skill edits should be evaluated behaviorally rather than treated as prose cleanup.

## Severity and disposition

| Finding | Severity | Disposition |
| --- | --- | --- |
| Non-Windows default installer path relied directly on `USERPROFILE` | High | Fixed + regression-covered |
| Concurrent mutating installs could operate on the same target | High | Fixed with per-target exclusive lock + regression-covered |
| Installer accepted unclosed YAML frontmatter | High | Fixed + regression-covered |
| Installer accepted missing skill description metadata | Medium | Fixed + regression-covered |
| Installer did not reject escaping/missing referenced Markdown | High | Fixed + regression-covered |
| Full-registry default silently included project-specific GrowthOps router | Medium | Compatibility preserved; explicit warning added; general-user docs now recommend selective/generic install |
| Root validator did not require simple `X.Y.Z` registry version | Medium | Fixed + regression-covered |
| Evidence `skill_observations` could name an unregistered skill | Medium | Fixed + regression-covered |
| Root validator reference check did not enforce skill-directory containment | High | Fixed + regression-covered |
| CI used mutable `actions/checkout@v7.0.1` tag | Medium | Pinned to exact commit `3d3c42e5aac5ba805825da76410c181273ba90b1` with version comment |
| CI validate job had no finite timeout | Medium | Fixed at 20 minutes |
| Phase 17 historical contract required current `REGISTRY.version == 1.2.0` | High maintenance risk | Decoupled; historical v1.2.0 evidence remains immutable |
| Phase 17 historical contract required README current suite string to remain v1.2.0 | High maintenance risk | Decoupled |
| `CONTRIBUTING.md` hard-coded “six reusable skills” | Low | Fixed |
| `COMPATIBILITY.md` described a dated Phase 11 snapshot as current evidence | Low | Clarified as historical snapshot |
| `main` branch protection was disabled at audit start | Important governance gap | Pending final Task 7 repository setting |
| macOS executable testing | Evidence gap | Still NOT RUN |
| Named third-party agent runtime loading | Evidence gap | Still NOT RUN |
| Runtime proof that agents obey router selection | Evidence gap | Still NOT RUN |
| Six incubating generic skills | Evidence gap | Remain incubating / UNPROVEN / evidence tier `none` |

## Baseline repository hygiene

A temporary Windows clone of baseline `38625ccb...` was scanned without modifying the repository.

Observed:

- tracked files: **137**;
- registered skills: **13**;
- PowerShell test scripts under `tests/`: **28**;
- tracked symlinks: **none**;
- likely live-secret pattern hits: **none**;
- tracked files larger than 200 KB: **none**;
- broken relative Markdown links found by the audit scan: **none**;
- trailing whitespace in Markdown/PowerShell/JSON/YAML scan: **none**;
- suspicious backup/temp file names: no meaningful finding;
- the only TODO-like match was validator logic that intentionally searches for placeholder words;
- Git index content was LF while the Windows clone checked many text files out as CRLF. This is working-tree normalization behavior, not evidence of repository-content corruption.

No `.gitattributes` mechanism was added solely for cosmetic EOL normalization because current index content is canonical and the shared suite executes on both Windows and Ubuntu. Add one later only if line-ending churn becomes an actual review/merge problem.

## Installer safety after hardening

### Selection

For normal public reuse, the recommended command is:

```powershell
pwsh -NoProfile -File .\install.ps1 -GenericOnly
```

Explicit skill selection remains available with `-SkillName`.

No selection flag still preserves the existing full-registry behavior for compatibility, but it now warns that project-specific entries such as `growthops-engineering` are included and recommends `-GenericOnly` or `-SkillName`.

### Default path

The installer no longer constructs its default from a Windows-only environment variable.

It resolves the current user home by host:

- Windows: `USERPROFILE`;
- non-Windows: `HOME`;
- fallback: runtime user-profile special folder;
- if no home can be resolved: fail closed and require explicit `-TargetRoot`.

### Concurrent mutation

A non-dry-run install acquires an exclusive sibling lock for the normalized target.

A second mutating installer targeting the same root fails before target mutation instead of racing backup/remove/swap operations.

Dry-run remains lock-free and non-mutating.

### Bundle validation

Before target mutation, selected source bundles must have:

- `SKILL.md`;
- a closed YAML frontmatter block;
- matching `name`;
- non-empty `description`;
- referenced Markdown paths that remain inside the skill directory;
- referenced Markdown files that actually exist.

Source and target symlink/junction/reparse-point boundaries continue to fail closed.

### Transaction behavior retained

The existing transaction model remains:

```text
stage all changed skills
  -> verify staged copies
    -> create and verify every required backup
      -> apply swaps
        -> verify installed copies
          -> rollback all attempted destinations on failure
```

Identical reinstalls remain idempotent and do not create unnecessary backups.

## Validator safety after hardening

The root validator now additionally rejects:

- registry versions outside simple SemVer `X.Y.Z`;
- evidence observations naming skills absent from the registry;
- `references/...md` paths that normalize outside the owning skill directory.

Existing checks remain for:

- registry schema/kind/status;
- canonical skill paths;
- evidence tiers and evidence references;
- frontmatter;
- broken references;
- text hygiene / mojibake / U+FFFD / UTF-8 BOM;
- tool-output contamination;
- project/generic boundaries;
- suite-manifest consistency.

## CI hardening

The workflow remains read-only with the exact Windows + Ubuntu matrix.

Changes:

- checkout is pinned to immutable commit `3d3c42e5aac5ba805825da76410c181273ba90b1`, annotated as `v7.0.1`;
- the validation job has `timeout-minutes: 20`;
- the CI self-contract now rejects mutable checkout version tags and removal of the timeout.

This aligns the repository's own CI with the supply-chain rules taught by `software-supply-chain-integrity`.

## Release-maintenance hardening

The Phase 17 acceptance report and v1.2.0 release notes are historical artifacts.

The historical contract still requires the original v1.2.0 facts:

- report target version `1.2.0`;
- tag `v1.2.0`;
- 20/20 acceptance;
- Phase 16 dependency;
- matched comparison evidence and its no-uplift limitation;
- release-note version/acceptance/limitation markers.

It no longer requires the **current** repository registry or README to remain at v1.2.0. A fixture now proves that a later suite version can coexist with valid v1.2.0 historical evidence.

## Skill-by-skill audit

| Skill | Lifecycle / evidence | Routing & scope | Audit result |
| --- | --- | --- | --- |
| `typescript-node-architecture` | stable / repeated observational | Narrow TypeScript/Node architecture boundary; compact entrypoint | Good reusable core. No functional edit required. Explicit non-goals could be added only with behavioral justification. |
| `monorepo-typescript` | stable / observed | Focused pnpm/TypeScript workspace ownership and dependency direction | Clean and compact. Completion criteria are more implicit than newer incubating skills, but no observed functional defect. |
| `sqlite-data-modeling` | stable / repeated observational | Durable SQLite schema/migration/transaction/job-state guidance | Strong durability focus. No audit defect found. |
| `resilient-crawler-engineering` | stable / repeated observational | Clear crawler lifecycle, bounded transport, retries, resume and browser fallback | Strong boundaries and explicit completion rule. No audit defect found. |
| `application-security-local-first` | stable / repeated observational | Broad security surface split into selective references | Broad, but reference decomposition keeps entrypoint bounded. No functional edit made. |
| `testing-typescript-systems` | stable / repeated observational | Unit/integration/fault/restart/E2E testing for TypeScript systems | Useful operational rules and failure-first guidance. No audit defect found. |
| `agent-skill-authoring` | incubating / none | Skill creation/refactor/package workflow | Routing and success condition are clear. Keep incubating until post-creation behavioral evidence exists. |
| `agent-skill-evaluation` | incubating / none | Explicitly scoped to evaluating skills/routers rather than ordinary app testing | Excellent boundary/limitations structure. Still UNPROVEN as a created skill. |
| `api-contract-testing` | incubating / none | Clear provider/consumer compatibility ownership and exclusions | Well-bounded and test-oriented. Keep incubating pending real-use evidence. |
| `ci-pipeline-reliability` | incubating / none | CI signal integrity, matrices, flakiness, artifacts | Clear neighboring-skill boundaries. Repository CI hardening in this audit is consistent with its rules but is not treated as causal effectiveness evidence. |
| `runtime-compatibility-engineering` | incubating / none | Distinguishes format/design/execution/runtime-loading claims | Strong anti-overclaim boundary. Keep incubating pending post-creation evidence. |
| `software-supply-chain-integrity` | incubating / none | Inputs, immutable refs, integrity/provenance/attestation | Broad but well-partitioned. Phase 17 comparison showed no measured criterion uplift in one run, so no promotion is justified. |
| `growthops-engineering` | project / repeated observational | Explicit project contract/router | Correctly project-specific and must not be presented as generic. No project leakage into generic skills found by root validation. |

### Skill quality conclusion

The collection is not uniformly formatted because older stable skills are intentionally shorter and some newer incubating skills have more explicit `When not to load`, `Neighboring skills`, `Limitations`, and `Completion rule` sections.

That is a consistency opportunity, not enough evidence for a mass rewrite.

A future skill-content cleanup should be done one skill at a time with the repository's behavioral-evaluation discipline, not by normalizing headings for appearance.

## Evidence limits intentionally preserved

This audit does **not** change these truthful limits:

- macOS repository tooling: NOT RUN;
- third-party runtime discovery/loading: NOT RUN;
- runtime router obedience: NOT RUN;
- broad cross-model/multi-user effectiveness: not established;
- six incubating generic skills: UNPROVEN / evidence tier `none`;
- shorter context entrypoints do not automatically prove token/latency/output-quality gains;
- stable lifecycle status does not mean causal effectiveness is benchmarked.

## Operational notes from audit execution

A remote supported-runtime smoke attempt used only temporary paths and did not intentionally target the live Codex skill directory.

The portable PowerShell download/extract attempt timed out through the remote connector and left two temporary audit directories under the Windows TEMP directory. They are audit leftovers, not repository content. Final cleanup/smoke handling belongs to the final verification task.

A read-only inspection showed the most recently modified live Codex files at that moment were under `~/.codex/skills/.system/`; the audit did not establish the cause of those system-file timestamps and therefore does not attribute them to this repository.

## Task 6 implementation lock

Tasks 1–6 are complete on the audit branch.

Verified implementation head:

`7af4e70651d935fb883aaaf379eebc278879d707`

Verification evidence:

- GitHub Actions PR run **#131** / run id `36841830126`;
- `validate (ubuntu-latest)`: **PASS**;
- `validate (windows-latest)`: **PASS**;
- no failed steps in either job.

This lock covers audit implementation and documentation only. It does **not** merge the branch, mutate the live user skill directory, enable branch protection, bump the suite version, or publish a release. Those remain exclusively in Task 7.

The lock commit itself is documentation-only and must also pass the same Windows + Ubuntu CI before Task 6 is considered closed.

## Remaining final gates

Before this audit is considered shipped:

1. run the final temporary-target installer smoke without touching live skills;
2. run full PR CI Windows + Ubuntu at the final branch head;
3. review the full branch diff;
4. merge only after green;
5. verify post-merge `main` CI;
6. enable practical `main` branch protection if the repository plan permits it;
7. if releasing the fixes, publish a SemVer patch without rewriting v1.2.0 historical evidence.


# PRD vNext — Evidence-Backed Engineering Skill System

Status: Draft for implementation  
Audit date: 2026-09-30  
Repository: exxrawrrr/codex-engineering-skills  
Audited main HEAD: 2229aed83f0dd09e2237854da4af855d19992e03  
Current registry version observed: 1.1.1

## 1. Product thesis

Codex Engineering Skills should be a small, selective, maintainable engineering skill system for agent workflows.

The product is not the quantity of Markdown, the number of abstractions, or the amount of validation machinery. Its value is whether a skill or router measurably improves engineering outcomes at an acceptable context, latency, token, and maintenance cost.

The vNext thesis is:

> Preserve the strong authoring and static-quality foundation, then add the smallest credible evidence system needed to distinguish well-written guidance from guidance that actually improves agent behavior.

Primary principle:

**Evidence > vibes.**

Secondary principle:

**Lifecycle status and effectiveness evidence are different dimensions.**

A skill can be stable as a maintained reusable artifact while still having limited effectiveness evidence. vNext should make that distinction explicit instead of pretending that one label answers both questions.

## 2. Audit scope and current state

The audit covered the complete current repository tree and all eight registered skills.

Observed repository surface:

- 81 total tree paths.
- 58 files.
- 8 registered skills.
- 6 generic stable skills.
- 1 generic incubating skill.
- 1 project-specific skill.
- 1 GitHub Actions workflow.
- PowerShell installer and validator.
- Registry, collection policy, authoring standard, compatibility guide, provenance documents, project-router template, routing examples, and supporting references.

All current SKILL.md entrypoints and all 32 reference Markdown files were inspected.

Current registered skills:

| Skill | Kind | Lifecycle status |
| --- | --- | --- |
| typescript-node-architecture | generic | stable |
| monorepo-typescript | generic | stable |
| sqlite-data-modeling | generic | stable |
| resilient-crawler-engineering | generic | stable |
| application-security-local-first | generic | stable |
| testing-typescript-systems | generic | stable |
| agent-skill-authoring | generic | incubating |
| growthops-engineering | project | project |

## 3. Evidence classification

This PRD uses the following claim states:

- **VERIFIED** — directly observed in repository source, GitHub history/CI, or local GrowthOps evidence.
- **PARTIALLY VERIFIED** — evidence supports part of the claim but not the full causal/effectiveness claim.
- **INFERRED** — reasonable conclusion from observed structure, but not directly measured.
- **UNPROVEN** — claim exists or is plausible but evidence is insufficient.
- **NOT RUN** — validation was intentionally not completed or its result was unavailable.

## 4. Current evidence

### 4.1 Static repository quality

**VERIFIED**

The repository already has meaningful static discipline:

- registry-backed skill discovery;
- required frontmatter checks;
- exact name/path consistency checks;
- required description checks;
- broken reference detection;
- unregistered skill-directory warnings;
- basic encoding corruption check for U+FFFD;
- tool-output contamination checks;
- generic/project leakage warning for GrowthOps text;
- SKILL.md line-count warning;
- Windows GitHub Actions validation.

The latest main workflow run observed for HEAD 2229aed completed successfully.

This is valuable. vNext should extend it, not replace it.

### 4.2 Behavioral effectiveness

**UNPROVEN at repository-system level**

The repository does not currently contain a behavioral evaluation harness, benchmark corpus, skill-on/skill-off comparison, router selection benchmark, token/context benchmark, or regression suite for agent outcomes.

The repository can currently prove that skill files are structurally consistent. It cannot yet prove, in a controlled and repeatable way, that loading a skill improves an agent result.

### 4.3 GrowthOps real-world usage

**VERIFIED for usage, PARTIALLY VERIFIED for causal effectiveness**

The local machine contains the GrowthOps Codex workspace at:

D:\RAFDI_DATA\02_WORKSPACES\Codex\GrowthOps

The relevant skill entrypoints are installed in the local Codex skill catalog.

Committed GrowthOps milestone records explicitly document skill usage alongside implementation scope, commits, test commands, and observed results.

Observed examples:

- M01 records use of growthops-engineering, monorepo-typescript, testing-typescript-systems and supporting skills.
- M02 records use of growthops-engineering, sqlite-data-modeling, typescript-node-architecture, testing-typescript-systems and verification-loop.
- M03 records typescript-node-architecture, sqlite-data-modeling, testing-typescript-systems and debugging/verification support while implementing durable job behavior.
- M04 records growthops-engineering, resilient-crawler-engineering, application-security-local-first and other relevant specialist skills across safe HTTP, crawl frontier, and bounded execution slices.

GitHub commits independently confirm the corresponding implementation exists:

- M01 foundation commit 164680e…
- M02 SQLite foundation commit 599d502…
- M03 merged persistent job engine dae287f…
- M04 safe HTTP commit 80b255b…
- M04 bounded crawl execution commit da5b8d9…

The milestone records include regression evidence such as expected failing tests before fixes followed by passing targeted suites and broader repository gates.

This is substantially stronger than a README claim.

However, it does not prove a counterfactual:

> The same agent, task, model, and repository state would have produced a worse result without the skill.

Therefore GrowthOps is strong observational evidence, not yet a controlled effectiveness benchmark.

### 4.4 Current GrowthOps workspace state

The local GrowthOps workspace is actively being modified on branch feat/m05-static-parsing-observations by another running process/session.

During this audit, uncommitted M05 files appeared and a formatter process was active.

Decision:

- exclude M05 WIP from effectiveness evidence;
- do not mutate, reset, clean, or inspect unstable WIP as if it were finalized evidence;
- use committed M01–M04 evidence only.

A full local npm run verify was attempted but the remote command channel timed out before a final result was available.

Classification: **NOT RUN / result unavailable** for this audit attempt.

No claim of current full local verification is made.

## 5. Audit decisions

### 5.1 Behavioral validation

Decision: **ADOPT**

Evidence state: **VERIFIED gap**

Add a small evaluation harness that can compare selected tasks with and without selected skills.

Do not build a generalized model-evaluation platform.

The first harness should answer narrow questions:

- Did the skill improve requirement adherence?
- Did it reduce architectural or security mistakes?
- Did it reduce rework?
- Did it improve verification behavior?
- What context cost did it add?

### 5.2 Stable status must have evidence

Decision: **MODIFY**

Evidence state: **VERIFIED gap**

Do not redefine stable to mean “scientifically benchmarked.”

Keep lifecycle status as an author/maintenance signal.

Add a separate evidence dimension, for example:

- none
- observed
- repeated
- benchmarked

Evidence must point to auditable records, not manually inflated counters.

Avoid fields such as repeated_uses: 17 unless the number is derived from committed evidence records.

### 5.3 Runtime portability

Decision: **MODIFY**

Evidence state:

- portable by format: **VERIFIED**
- portable by architecture: **PARTIALLY VERIFIED**
- portable by tested execution: **UNPROVEN beyond Windows-oriented workflow**

The Markdown layout is simple and largely model-agnostic.

The installer/validator and CI are PowerShell/Windows-first.

vNext should first test the existing PowerShell tooling on Windows and Ubuntu with pwsh.

Do not rewrite the suite into Python/Node solely to claim portability.

macOS CI is **DEFER** until a concrete need appears.

### 5.4 Context efficiency

Decision: **ADOPT**

Evidence state: **UNPROVEN**

The repository correctly promotes progressive disclosure and selective loading, but there is no measurement.

Create a small benchmark with variants such as:

- no skill;
- router + selected specialists;
- all available specialists.

Measure whatever the runtime exposes reliably:

- prompt/context bytes;
- token count when available;
- tool calls;
- iterations;
- elapsed time when meaningful;
- correctness rubric;
- acceptance-criteria pass rate;
- rework count.

### 5.5 Project router effectiveness

Decision: **NEEDS EVIDENCE**

The GrowthOps router is well-scoped and has real usage records.

What remains unproven is whether routing itself improves task selection/context efficiency versus direct specialist loading or indiscriminate loading.

Do not rewrite the router before measuring it.

### 5.6 Installer reliability

Decision: **MODIFY**

Evidence state: **VERIFIED**

Current behavior:

backup existing destination
→ remove destination
→ copy replacement

This is safer than blind overwrite but not rollback-friendly if copy fails after deletion.

Recommended smallest improvement:

stage selected skill
→ validate staged content
→ backup old version outside discovery root
→ swap
→ verify installed entrypoint
→ restore backup on failure

Do not build a package manager.

Also add explicit skill selection so users do not need to install the whole garage.

Do not change default install semantics until context/discovery behavior is measured.

### 5.7 Cross-platform validation

Decision: **MODIFY**

Add Ubuntu pwsh CI beside Windows.

Do not add macOS initially.

The objective is to test current portability claims, not maximize CI matrix size.

### 5.8 Provenance

Decision: **ALREADY SOLVED for baseline, MODIFY for maintainability**

The repository already has strong ATTRIBUTION.md, SOURCES.md, NOTICE, Apache-2.0 licensing, and explicit statements about source influence.

The baseline provenance concern is not confirmed.

Maintenance issues remain:

- source-to-skill mapping is human-maintained;
- growthops-engineering/references/source-provenance.md duplicates root SOURCES.md content;
- one referenced upstream license is intentionally not claimed because it was not reliably verified;
- no validator checks that provenance mappings remain coherent as the suite grows.

vNext should reduce duplication and validate references, not add a provenance database.

### 5.9 Complexity budget

Decision: **ADOPT as review discipline, REJECT as new subsystem**

Use this review sequence for major changes:

problem
→ mechanism
→ demonstrated value
→ evidence
→ maintenance cost

Do not create a “complexity engine,” scoring service, or policy DSL.

### 5.10 Skill quality vs skill effectiveness

Decision: **ADOPT distinction**

Current quality: strong.

Current effectiveness evidence: uneven.

The repository should publish both dimensions honestly.

### 5.11 “Knowledge dumping” concern

Decision: **REJECT as a repository-wide diagnosis; MODIFY isolated duplication**

The inspected skill entrypoints are reasonably bounded and references are split by meaningful subproblem.

The collection does not currently look like indiscriminate knowledge dumping.

Confirmed cleanup candidates exist, especially duplicated provenance content and the copied project-suite validator.

### 5.12 Stable labels are “false”

Decision: **REJECT**

There is not enough evidence to call the stable labels false.

Several stable skills have repeated observational GrowthOps use.

The actual issue is that lifecycle and evidence are conflated.

Fix the model, not the label.

### 5.13 Static validator stronger than behavioral evaluation

Decision: **ADOPT**

This concern is **VERIFIED**.

Static validation is currently much stronger than effectiveness evaluation.

### 5.14 Router looks sophisticated but is unproven

Decision: **NEEDS EVIDENCE**

Real use exists.

Controlled router-benefit evidence does not.

### 5.15 Skill adds context/token without measured benefit

Decision: **ADOPT benchmark**

Concern is **VERIFIED as unmeasured**, not verified as harmful.

### 5.16 Installer transactional/rollback concern

Decision: **MODIFY**

Confirmed by source inspection.

Implement staging and recovery without global transaction machinery.

### 5.17 Portability claim exceeds tested CI

Decision: **MODIFY**

The compatibility document already honestly says PowerShell-first and Windows-oriented.

Therefore “portable by tested execution” is not currently claimed strongly enough to call it misleading.

Add Linux pwsh validation to increase evidence.

### 5.18 Provenance becomes hard to maintain

Decision: **MODIFY**

Current provenance is good.

The duplicate project copy of source provenance creates unnecessary drift risk.

### 5.19 Project-specific knowledge leaks into generic skills

Decision: **ALREADY SOLVED for current inspected corpus**

All generic SKILL.md files and their references were inspected.

No GrowthOps-specific product policy was found in the generic corpus.

The validator also warns on GrowthOps text in generic skill directories.

Keep the check.

### 5.20 Skills are too long/redundant

Decision: **REJECT as a broad claim**

All current entrypoints are below the existing 500-line warning threshold and are structurally concise.

Some conceptual overlap is intentional because reliability, testing, and persistence share invariants.

Only remove duplication when ownership is clearly wrong.

### 5.21 External mature tooling already solves some needs

Decision: **ADOPT as candidate filter**

Do not create local duplicates of supporting skills already used successfully, especially:

- systematic-debugging;
- verification-loop;
- requesting-code-review;
- codebase-onboarding;
- Playwright-specific operation.

New skill proposals must solve a gap not already covered adequately.

### 5.22 GrowthOps evidence is underused

Decision: **ADOPT**

This concern is **VERIFIED**.

The repository has meaningful observational evidence but does not currently represent it as an evidence asset, case study, evaluation fixture, or lifecycle input.

### 5.23 Repository focuses on machinery over demonstrated value

Decision: **PARTIALLY VERIFIED**

The repository is still small and the machinery is not excessive.

However, the next major investment should be evidence, not more metadata or routing abstraction.

### 5.24 Encoding integrity

Decision: **ADOPT immediate fix**

Evidence state: **VERIFIED**

The current GrowthOps project skill and references contain visible mojibake sequences such as malformed arrows/box characters.

The validator checks U+FFFD but does not catch common UTF-8-as-Windows-1252 mojibake patterns.

Fix the files and extend validation narrowly.

### 5.25 Duplicate GrowthOps validator

Decision: **MODIFY / likely REMOVE**

Evidence state: **VERIFIED**

skills/growthops-engineering/scripts/validate-suite.ps1 has the same Git blob SHA as root validate.ps1.

As installed inside the skill folder, its default relative paths do not point to the repository root registry/skills tree.

It does not provide GrowthOps behavioral validation.

Prefer removing it from the installed project skill unless a real project-local purpose is defined.

### 5.26 Validator/documentation mismatch

Decision: **MODIFY**

README says the validator checks “suite maintenance assets.”

The current validator does not validate the GrowthOps suite manifest or a broader maintenance-asset contract.

Either implement the specific check or narrow the README claim.

Prefer the smallest truthful behavior.

### 5.27 Release/version model

Decision: **DEFER release automation; ADOPT simple semantics**

REGISTRY.json exposes version 1.1.1.

No release workflow or changelog file exists in the current tree.

The audit did not establish a published tag/release contract tied to that field.

Do not add Changesets or release automation yet.

First document what increments the suite version and when a Git tag is required.

## 6. Skill evidence assessment

| Skill | Observed GrowthOps evidence | Evidence strength | Current lifecycle recommendation |
| --- | --- | --- | --- |
| growthops-engineering | Explicitly recorded across M01–M04; project routing and milestone discipline reflected in checkpoints | Strong observational | Keep project |
| typescript-node-architecture | Used in M02–M04; commit structure shows explicit boundaries, strict TypeScript, failure ownership | Strong observational | Keep stable; evidence=repeated |
| monorepo-typescript | M01 explicitly records use; monorepo/workspace boundaries and acyclic graph checks implemented | Medium-to-strong observational | Keep stable; evidence=observed |
| sqlite-data-modeling | M02/M03/M04 durable schemas, migrations, transactions, recovery semantics | Strong observational | Keep stable; evidence=repeated |
| resilient-crawler-engineering | M04 safe transport/frontier/execution, retry/bounds/resume behavior and regression tests | Strong observational | Keep stable; evidence=repeated |
| application-security-local-first | M01 secret/path controls and M04 SSRF/DNS/redirect boundary tests | Strong observational | Keep stable; evidence=repeated |
| testing-typescript-systems | Used repeatedly; failure-first regression evidence, focused + broader gates, CI evidence | Strong observational | Keep stable; evidence=repeated |
| agent-skill-authoring | No concrete GrowthOps execution evidence found | Weak / none for GrowthOps | Keep incubating |

Important limitation:

**None of these have controlled skill-on versus skill-off effectiveness evidence yet.**

## 7. Goals

vNext should:

1. preserve simple SKILL.md packaging;
2. make evidence auditable;
3. measure at least a small sample of skill effectiveness;
4. measure context/router cost;
5. harden installer recovery without creating a package manager;
6. test current tooling on Windows and Linux pwsh;
7. convert GrowthOps history into privacy-safe evidence;
8. fix confirmed hygiene defects;
9. keep generic/project boundaries clean;
10. prevent new skills from bypassing evidence/lifecycle discipline.

## 8. Non-goals

vNext will not:

- build a hosted evaluation service;
- add a database;
- add a web dashboard;
- add an MCP server;
- require telemetry;
- require proprietary model APIs;
- make every skill cross-runtime executable;
- rewrite PowerShell tooling into another language without evidence;
- add macOS CI before demand;
- automatically promote new skills to stable;
- create all ten candidate skills immediately;
- add Changesets/Turborepo/Nx or package-release machinery;
- duplicate mature supporting skills already available externally;
- publish private GrowthOps source or sensitive local logs.

## 9. Architecture direction

Keep the repository architecture intentionally boring:

~~~text
REGISTRY.json
skills/
  <skill>/
    SKILL.md
    references/
    optional deterministic scripts/assets
evidence/
  cases/
  results/
templates/
examples/
tools / validator / installer
~~~

New evidence records should be append-oriented and reviewable.

Recommended model:

- registry lifecycle status remains stable/incubating/reference/project;
- evidence tier is separate;
- evidence records point to concrete case IDs and results;
- benchmark results are committed as compact summaries, not giant raw transcripts;
- private project evidence is represented through sanitized case metadata and reproducible public fixtures.

Do not embed growing validation counters directly into SKILL.md frontmatter.

## 10. Skill lifecycle

Proposed lifecycle vocabulary:

~~~text
experimental
→ incubating
→ validated
→ stable
→ deprecated
~~~

Project routers remain kind=project and can use an evidence tier without pretending to be generic reusable skills.

Lifecycle meaning:

### experimental

Idea or draft with no obligation of compatibility.

### incubating

Usable enough for real trials, but routing/scope may still change.

### validated

Has at least one reproducible behavioral case that demonstrates intended guidance without major regressions.

### stable

Maintained reusable skill with:

- clear trigger boundaries;
- static validation passing;
- no project leakage;
- known limitations;
- repeated real use or multiple reproducible cases;
- no unresolved high-severity correctness issue.

Stable does not require a universal benchmark win.

### deprecated

Retained for migration/history but no longer recommended.

### Evidence tier

Separate field or derived record:

- none
- observed
- repeated
- benchmarked

This prevents lifecycle labels from becoming fake metrics.

## 11. Skill effectiveness evaluation

Initial evaluation harness should be deliberately small.

### First case classes

1. TypeScript package-boundary change.
2. SQLite migration/durable-state change.
3. Crawler retry/URL-lifecycle change.
4. SSRF/redirect security change.
5. Test-strategy/regression change.
6. Project-router selection task.

### Variants

For each applicable case:

A. no repository skill  
B. recommended skill(s)  
C. intentionally over-loaded skill set when safe/useful for context comparison

### Scoring

Prefer deterministic or reviewable scoring:

- acceptance criteria passed;
- tests passing;
- forbidden behavior introduced;
- security invariant violated;
- architecture boundary violated;
- rework iterations;
- unnecessary files/dependencies added;
- tool calls;
- context bytes/tokens when available.

Do not score writing style.

### Reproducibility

A case must record:

- task fixture/version;
- model/runtime identifier when available;
- skill set loaded;
- expected acceptance criteria;
- result summary;
- validation commands;
- evidence state.

The harness may initially be semi-manual.

Automation is optional until the cases prove useful.

## 12. Context/token efficiency

Measure context cost directly where possible.

At minimum record:

- SKILL.md bytes;
- selected reference bytes;
- number of loaded skills;
- number of loaded references.

When runtime metrics are available, also record:

- input tokens;
- output tokens;
- tool calls;
- elapsed time.

Key question:

> Does router + selective loading preserve or improve correctness with less context than loading every relevant skill?

Do not claim token savings before measurement.

## 13. Router evaluation

Create a small routing corpus.

Each task declares the expected minimum specialist set.

Examples:

- monorepo package split;
- SQLite migration;
- crawler retry bug;
- parser-only task;
- report XSS task;
- unrelated documentation task.

Measure:

- required skill selected;
- irrelevant skill avoided;
- forbidden project skill avoided;
- reference loading stayed conditional;
- downstream result passed task acceptance criteria.

The GrowthOps router should not be rewritten unless routing failures are demonstrated.

## 14. Installer and distribution

### Near-term installer changes

1. Add explicit skill selection.
2. Keep dry-run.
3. Stage before destructive replacement.
4. Validate staged content.
5. Back up old versions outside the active discovery root.
6. Swap only after validation.
7. Verify installed SKILL.md exists.
8. Restore backup on failure.
9. Add temp-target installer tests.
10. Preserve current default behavior until discovery/context impact is measured.

### Distribution stance

The repository is a skill collection, not a package ecosystem.

No package registry is required for vNext.

Git clone/download + explicit installer remains sufficient.

## 15. Runtime compatibility

Compatibility should distinguish three levels:

| Runtime | Format | Architecture | Tested execution |
| --- | --- | --- | --- |
| Codex on Windows | Yes | Yes | Yes for validator/install workflow orientation |
| Codex/agent with filesystem skills on Linux + pwsh | Likely | Likely | To be added |
| macOS filesystem-based agents | Likely | Likely | Deferred |
| Agents requiring different frontmatter/index format | Partial | Adaptable | Not tested |

The compatibility document must state tested facts separately from theoretical portability.

## 16. Provenance

Keep the existing human-readable provenance files.

Add only lightweight maintainability controls:

- each generic skill maps to relevant source sections;
- validator checks mapped files/source IDs exist;
- remove exact duplicate provenance copies;
- source license uncertainty remains explicit;
- copied/adapted text requires stronger attribution than inspiration.

Do not auto-scrape or auto-license-classify upstream repositories in CI.

## 17. Ten new skill candidates

These are candidates, not an instruction to create ten folders immediately.

### 17.1 agent-skill-evaluation

**Decision:** ADOPT first  
**Purpose:** Design reproducible evaluations for SKILL.md guidance and routers.  
**Problem solved:** Current repository validates structure but not agent outcome effectiveness.  
**Why it belongs:** It directly serves the product thesis.  
**Likely triggers:** New skill promotion, disputed routing value, regression in agent behavior.  
**Dependencies:** Existing authoring standard; optional runtime-specific adapters.  
**Overlap:** Complements agent-skill-authoring; should not duplicate authoring rules.  
**Expected value:** Very high.  
**Maintenance burden:** Medium.  
**Maturity:** experimental → incubating.

### 17.2 api-contract-testing

**Decision:** ADOPT  
**Purpose:** Contract-first testing for local APIs, package APIs, schemas, compatibility, and failure responses.  
**Problem solved:** Existing testing guidance is broad; API compatibility has no dedicated workflow.  
**Why it belongs:** Common reusable engineering-agent task and relevant to GrowthOps local API evolution.  
**Likely triggers:** Endpoint/schema change, package public API change, backward-compatibility work.  
**Dependencies:** testing-typescript-systems; typescript-node-architecture.  
**Overlap:** Moderate with testing-typescript-systems; must stay contract-specific.  
**Expected value:** High.  
**Maintenance burden:** Medium.  
**Maturity:** incubating candidate.

### 17.3 observability-diagnostics

**Decision:** ADOPT  
**Purpose:** Structured logs, safe diagnostics, correlation, error taxonomy, and debuggability boundaries.  
**Problem solved:** Error handling exists across skills, but operational observability is fragmented.  
**Why it belongs:** Durable/agent-built systems need evidence for failures without leaking secrets.  
**Likely triggers:** New long-running jobs, service boundaries, hard-to-debug failures, supportability work.  
**Dependencies:** application-security-local-first; typescript-node-architecture.  
**Overlap:** Avoid duplicating systematic-debugging; this skill is instrumentation/design, not debugging procedure.  
**Expected value:** High.  
**Maintenance burden:** Medium.  
**Maturity:** incubating candidate.

### 17.4 ci-cd-reliability

**Decision:** ADOPT  
**Purpose:** CI matrices, deterministic gates, artifact evidence, retry/flakiness policy, and safe workflow changes.  
**Problem solved:** Repository and GrowthOps rely on CI, but no specialist skill owns CI correctness.  
**Why it belongs:** Cross-platform and behavioral validation will depend on trustworthy CI.  
**Likely triggers:** Workflow changes, flaky checks, platform matrix changes, release gates.  
**Dependencies:** testing-typescript-systems.  
**Overlap:** Low.  
**Expected value:** High.  
**Maintenance burden:** Medium.  
**Maturity:** incubating candidate.

### 17.5 dependency-upgrade-engineering

**Decision:** ADOPT  
**Purpose:** Safe dependency upgrades, changelog/API review, lockfile discipline, staged rollout, and regression gates.  
**Problem solved:** Current skills mention dependency hygiene but do not define upgrade workflow.  
**Why it belongs:** Common engineering-agent failure mode is broad upgrades without impact analysis.  
**Likely triggers:** Runtime/framework/library upgrades and security patching.  
**Dependencies:** testing-typescript-systems; relevant stack skill.  
**Overlap:** Small with TypeScript runtime guidance.  
**Expected value:** Medium-high.  
**Maintenance burden:** Medium-high because ecosystems change.  
**Maturity:** incubating candidate.

### 17.6 supply-chain-security

**Decision:** MODIFY / candidate after scope proof  
**Purpose:** Dependency provenance, install scripts, lockfiles, advisories, artifact trust, CI dependency exposure.  
**Problem solved:** Application security currently focuses mainly on runtime/input boundaries.  
**Why it belongs:** Supply-chain threats are materially different from SSRF/XSS/path safety.  
**Likely triggers:** New dependency, package-manager policy, release artifact, CI action adoption.  
**Dependencies:** application-security-local-first.  
**Overlap:** Some dependency hygiene already exists.  
**Expected value:** High when scoped narrowly.  
**Maintenance burden:** High.  
**Maturity:** experimental; do not build until scope is constrained.

### 17.7 release-rollback-engineering

**Decision:** ADOPT after installer work  
**Purpose:** Release gates, rollback plans, compatibility, reversible deployment/distribution changes.  
**Problem solved:** Existing release guidance is project-specific; generic rollback design is missing.  
**Why it belongs:** Useful across installers, local apps, services, and agent-generated release changes.  
**Likely triggers:** Release preparation, installer updates, schema/API rollout, deployment change.  
**Dependencies:** testing-typescript-systems; ci-cd-reliability.  
**Overlap:** Do not duplicate GrowthOps-specific release gates.  
**Expected value:** Medium-high.  
**Maintenance burden:** Medium.  
**Maturity:** incubating candidate.

### 17.8 compatibility-engineering

**Decision:** ADOPT  
**Purpose:** Platform/runtime compatibility matrices, capability detection, graceful degradation, and compatibility testing.  
**Problem solved:** Current portability language is mostly descriptive and not backed by a systematic compatibility workflow.  
**Why it belongs:** Directly supports multi-runtime skill goals without promising universal portability.  
**Likely triggers:** New OS/runtime support, toolchain portability, API/runtime upgrade.  
**Dependencies:** testing-typescript-systems; ci-cd-reliability.  
**Overlap:** Moderate with runtime-specific references; keep it cross-cutting.  
**Expected value:** High.  
**Maintenance burden:** Medium.  
**Maturity:** incubating candidate.

### 17.9 performance-profiling-node

**Decision:** DEFER  
**Purpose:** CPU, memory, event-loop, I/O, query, and crawler throughput profiling.  
**Problem solved:** Prevents optimization by intuition.  
**Why it may belong:** Performance work is common and evidence-oriented.  
**Likely triggers:** Measured latency/memory/throughput problem.  
**Dependencies:** Node runtime/tooling.  
**Overlap:** Low.  
**Expected value:** Medium, but only when performance pressure exists.  
**Maintenance burden:** Medium-high.  
**Maturity:** reference/experimental candidate only after a real case.

### 17.10 schema-evolution-safety

**Decision:** DEFER as standalone skill; likely extend existing SQLite/API guidance instead  
**Purpose:** Backward-compatible schema and data-contract evolution.  
**Problem solved:** Cross-version compatibility for durable and serialized data.  
**Why it might belong:** Valuable beyond SQLite.  
**Likely triggers:** Versioned persistence/API/event schema changes.  
**Dependencies:** sqlite-data-modeling; api-contract-testing.  
**Overlap:** High with existing migrations and proposed API contract skill.  
**Expected value:** Medium.  
**Maintenance burden:** Medium.  
**Maturity:** do not create until repeated non-SQLite cases prove the boundary.

### Explicitly rejected new-skill directions

Do not create separate skills now for:

- generic systematic debugging — mature supporting skill already used;
- verification loop — mature supporting skill already used;
- requesting code review — mature supporting skill already used;
- generic test strategy — existing testing-typescript-systems already owns it;
- documentation architecture — lower priority than demonstrated behavioral gaps.

## 18. GrowthOps evidence publication

Create a privacy-safe case study derived only from committed/publicly safe facts.

Allowed evidence:

- milestone IDs;
- public commit IDs;
- classes of changes;
- test counts/results already public in repository records;
- mapping from skill to task class;
- anonymized/fixture-based reproductions.

Do not publish:

- private Codex session transcripts;
- secrets;
- local user paths except generic sanitized examples;
- private prompt history;
- unrelated local workspace content.

GrowthOps should become:

1. an observational case study;
2. a source of reproducible public fixtures where possible;
3. not the sole benchmark corpus.

## 19. Risks

### Technical risks

- Evaluation results can be noisy across model versions.
- Token metrics may not be available consistently.
- Cross-platform PowerShell behavior may differ.
- Installer swap semantics differ across filesystems.
- Evidence metadata can become stale if manually maintained.

### Maintenance risks

- Too many candidate skills create collection sprawl.
- Evaluation harness itself can become more complex than the skill set.
- Provenance automation can produce false certainty.
- Compatibility matrix can become a promise the project cannot maintain.

### Ecosystem risks

- Runtime-specific conventions may change.
- Agent skill loading semantics may change.
- External supporting skills may disappear or change contracts.

### Adoption risks

- Users may misread benchmark results as universal guarantees.
- Users may install everything despite selective-loading guidance.

Mitigation:

- small cases;
- explicit evidence classifications;
- no universal quality scores;
- versioned fixtures;
- clear tested-runtime language.

## 20. Acceptance criteria for vNext

vNext is acceptable when all of the following are true:

1. Current mojibake in project skill files is removed.
2. Validator catches the known encoding failure pattern or equivalent regression fixture.
3. Validator checks registry status values.
4. README validator claims match actual checks.
5. Duplicate/nonfunctional GrowthOps suite validator is removed or given a real tested purpose.
6. Evidence model separates lifecycle from evidence tier.
7. At least three reproducible behavioral cases exist.
8. At least one case compares no-skill versus selected-skill behavior.
9. At least one case measures context size for selected versus over-loaded routing.
10. Router corpus has at least five task-selection cases.
11. GrowthOps public case study maps committed milestones to skills without exposing private logs.
12. Installer has explicit skill selection.
13. Installer staging/rollback is tested against a temporary target.
14. Installer backup is not placed inside an active skill discovery root.
15. Validator runs successfully on Windows and Ubuntu pwsh in CI.
16. Compatibility document distinguishes format/architecture/tested execution.
17. Provenance duplication is removed and source mappings are validated.
18. No new candidate skill is promoted directly to stable.
19. At least one candidate skill is rejected/deferred based on overlap or insufficient evidence.
20. Final vNext audit reports PASS/FAIL/NOT RUN for every acceptance criterion.

## 21. Seventeen-phase execution plan

The audit and this PRD are pre-implementation work. The phases below start after this PRD branch is accepted as the execution contract.

### Phase 01 — Baseline lock and regression fixtures

**Objective:** Freeze the current repository baseline and encode confirmed audit defects as failing/regression fixtures before broad changes.  
**Files affected:** evidence/baseline/*, test/validation fixture locations to be chosen, docs audit note.  
**Expected outcome:** Reproducible baseline for encoding, registry, validator, installer, and current CI behavior.  
**Acceptance criteria:** Current HEAD recorded; confirmed defects have minimal fixtures; no production behavior changed.  
**Validation:** Existing validate.ps1 plus fixture-specific checks.  
**GitHub deliverable:** One branch/PR with baseline evidence only.  
**Rollback/recovery:** Delete additive fixtures/notes; no existing behavior touched.  
**Dependencies:** PRD accepted.

### Phase 02 — Encoding and truthfulness repairs

**Objective:** Fix mojibake/BOM issues and align README claims with actual validator behavior.  
**Files affected:** growthops-engineering SKILL/references with corruption, README.md, validate.ps1 as narrowly required.  
**Expected outcome:** Clean UTF-8 text and no documentation overclaim.  
**Acceptance criteria:** Known malformed sequences absent; regression fixture catches recurrence; validator/docs agree.  
**Validation:** validate.ps1; targeted encoding fixture.  
**GitHub deliverable:** Small hygiene PR.  
**Rollback/recovery:** Revert text-only commit.  
**Dependencies:** Phase 01.

### Phase 03 — Static validator contract hardening

**Objective:** Add only high-value missing static checks.  
**Files affected:** validate.ps1, REGISTRY.json schema conventions/docs, validation fixtures.  
**Expected outcome:** Status validation, suite-manifest consistency where retained, better encoding detection, explicit warnings/errors.  
**Acceptance criteria:** Invalid status fails; broken registered path fails; known encoding fixture fails; valid corpus passes.  
**Validation:** Windows local/CI validator tests.  
**GitHub deliverable:** Validator PR with negative fixtures.  
**Rollback/recovery:** Revert validator changes; fixtures remain diagnostic.  
**Dependencies:** Phases 01–02.

### Phase 04 — Evidence model

**Objective:** Separate lifecycle status from effectiveness evidence.  
**Files affected:** REGISTRY.json, COLLECTION_POLICY.md, AUTHORING_STANDARD.md, evidence schema/docs.  
**Expected outcome:** Evidence tiers and auditable case references without manual vanity counters.  
**Acceptance criteria:** Every registered skill has either explicit evidence tier or derived default; evidence links resolve.  
**Validation:** Validator evidence-reference checks.  
**GitHub deliverable:** Evidence-model PR.  
**Rollback/recovery:** Evidence fields/files are additive and can be removed without changing skill content.  
**Dependencies:** Phase 03.

### Phase 05 — Minimal behavioral evaluation harness

**Objective:** Prove that the repository can evaluate outcomes, not only files.  
**Files affected:** evidence/cases, evaluation scripts/docs, small public fixtures.  
**Expected outcome:** Three or more reproducible cases with deterministic acceptance criteria.  
**Acceptance criteria:** Case runner/report format produces PASS/FAIL/NOT RUN; results are reviewable.  
**Validation:** Run cases using documented procedure.  
**GitHub deliverable:** Evaluation-harness PR.  
**Rollback/recovery:** Remove additive harness; skills remain untouched.  
**Dependencies:** Phase 04.

### Phase 06 — Context efficiency benchmark

**Objective:** Measure selective-loading cost.  
**Files affected:** evidence/cases/context-*, results summaries, possibly helper script.  
**Expected outcome:** No-skill/selected/all comparison for representative tasks.  
**Acceptance criteria:** At least three comparisons record context bytes and available runtime metrics.  
**Validation:** Re-run benchmark and compare schema-consistent results.  
**GitHub deliverable:** Context benchmark PR/results.  
**Rollback/recovery:** Results are append-only evidence; bad runs can be superseded, not rewritten.  
**Dependencies:** Phase 05.

### Phase 07 — Router selection evaluation

**Objective:** Test whether router guidance selects minimal relevant skills.  
**Files affected:** router case corpus, project-router template/examples only if failures justify edits.  
**Expected outcome:** Five or more routing cases with expected skill sets.  
**Acceptance criteria:** Required skills selected, irrelevant skills avoided, project-specific skill not leaked.  
**Validation:** Routing case run/review.  
**GitHub deliverable:** Router-evaluation PR.  
**Rollback/recovery:** Do not modify router unless a failing case demonstrates need.  
**Dependencies:** Phases 05–06.

### Phase 08 — GrowthOps evidence case study

**Objective:** Convert committed M01–M04 evidence into a public, privacy-safe evidence asset.  
**Files affected:** evidence/cases/growthops-*, docs/case-study-growthops.md.  
**Expected outcome:** Skill-to-milestone mapping with public commit/test references.  
**Acceptance criteria:** No private session text; claims use VERIFIED/PARTIALLY VERIFIED labels; public commits resolve.  
**Validation:** Manual privacy review plus link/file validation.  
**GitHub deliverable:** Case-study PR.  
**Rollback/recovery:** Additive documentation/evidence only.  
**Dependencies:** Phase 04.

### Phase 09 — Installer selection and backup-root hardening

**Objective:** Make selective installation practical and prevent backups from living under active discovery roots.  
**Files affected:** install.ps1, README install docs, installer tests.  
**Expected outcome:** Explicit skill selection and safer backup placement.  
**Acceptance criteria:** Dry-run shows exact selected skills; unselected skills untouched; backup root outside target discovery tree.  
**Validation:** Temporary-target tests.  
**GitHub deliverable:** Installer-selection PR.  
**Rollback/recovery:** Preserve current default semantics; flags are additive.  
**Dependencies:** Phase 03.

### Phase 10 — Installer staging, rollback, and idempotency

**Objective:** Survive partial install failure safely.  
**Files affected:** install.ps1, installer fixtures/tests.  
**Expected outcome:** Stage → validate → backup → swap → verify → restore-on-failure.  
**Acceptance criteria:** Injected copy/validation failure restores previous skill; second identical install is safe.  
**Validation:** Fault-injection tests on temporary directories.  
**GitHub deliverable:** Installer reliability PR.  
**Rollback/recovery:** Old implementation remains recoverable from Git; backup behavior verified before merge.  
**Dependencies:** Phase 09.

### Phase 11 — Windows + Linux PowerShell CI

**Objective:** Test current tooling portability without rewriting it.  
**Files affected:** .github/workflows/validate.yml, compatibility docs if needed.  
**Expected outcome:** Validator and installer temp-target tests run on windows-latest and ubuntu-latest with pwsh.  
**Acceptance criteria:** Both matrix legs green.  
**Validation:** GitHub Actions.  
**GitHub deliverable:** Cross-platform CI PR.  
**Rollback/recovery:** Remove Linux matrix leg if an upstream runner defect blocks progress; document NOT RUN rather than weakening checks.  
**Dependencies:** Phases 03, 09–10.

### Phase 12 — Compatibility contract

**Objective:** Make portability claims precise and evidence-backed.  
**Files affected:** COMPATIBILITY.md, evidence compatibility matrix.  
**Expected outcome:** Format, architecture, and tested-execution support are separately documented.  
**Acceptance criteria:** Every supported row names evidence or explicitly says untested/deferred.  
**Validation:** Documentation review + CI references.  
**GitHub deliverable:** Compatibility PR.  
**Rollback/recovery:** Documentation-only.  
**Dependencies:** Phase 11.

### Phase 13 — Provenance deduplication and maintenance checks

**Objective:** Preserve current strong provenance while reducing drift.  
**Files affected:** SOURCES.md, ATTRIBUTION.md, duplicated project provenance file, validator mappings.  
**Expected outcome:** One canonical source record with skill mappings; duplicate copy removed/pointered.  
**Acceptance criteria:** No exact duplicate provenance file; mapped source IDs/paths validate.  
**Validation:** Validator + manual license/source review.  
**GitHub deliverable:** Provenance PR.  
**Rollback/recovery:** Text mapping changes are reversible; no license claims expanded without evidence.  
**Dependencies:** Phase 03.

### Phase 14 — New skill incubation wave A

**Objective:** Add only highest-value evidence-driven candidates.  
**Files affected:** candidate folders for agent-skill-evaluation, api-contract-testing, ci-cd-reliability as justified by completed cases.  
**Expected outcome:** New skills start experimental/incubating, each with scope, triggers, examples, limitations, and evidence plan.  
**Acceptance criteria:** No candidate marked stable; overlap review completed; validator passes; at least one real case per created skill or explicit UNPROVEN state.  
**Validation:** Static validator + relevant behavioral case.  
**GitHub deliverable:** Separate PR per skill or tightly related pair.  
**Rollback/recovery:** Each skill independently removable.  
**Dependencies:** Phases 05–07.

### Phase 15 — New skill incubation wave B

**Objective:** Evaluate observability, dependency upgrades, compatibility, release/rollback, and supply-chain candidates.  
**Files affected:** only candidates that pass scope review.  
**Expected outcome:** Create only skills with demonstrated trigger boundaries; defer the rest.  
**Acceptance criteria:** Every candidate receives ADOPT/MODIFY/DEFER/REJECT decision with evidence.  
**Validation:** Overlap review + at least one representative case for adopted skills.  
**GitHub deliverable:** Candidate decision PRs.  
**Rollback/recovery:** No bundled ten-skill mega-commit.  
**Dependencies:** Phase 14 plus real use cases.

### Phase 16 — Complexity and lifecycle review

**Objective:** Remove or consolidate mechanisms whose value is not demonstrated and review promotion eligibility.  
**Files affected:** REGISTRY.json, collection policy, duplicated/redundant files, evidence summaries.  
**Expected outcome:** Honest lifecycle/evidence labels and lower maintenance surface.  
**Acceptance criteria:** Every stable/incubating skill has evidence state; deferred candidates remain absent; duplicate/nonfunctional assets removed.  
**Validation:** Full validator + evaluation summary review.  
**GitHub deliverable:** Consolidation PR.  
**Rollback/recovery:** Prefer deletion-only changes that are easy to revert; archive evidence before removing behavior.  
**Dependencies:** Phases 04–15.

### Phase 17 — vNext release readiness

**Objective:** Prove the resulting system is more useful and truthful without unnecessary machinery.  
**Files affected:** README.md, CHANGELOG or release note only if version semantics require it, REGISTRY.json version, final evidence report.  
**Expected outcome:** Final measurable acceptance report and documented release semantics.  
**Acceptance criteria:** All vNext acceptance criteria explicitly PASS/FAIL/NOT RUN; no silent gaps; CI green on required platforms.  
**Validation:** Full static validation, installer tests, behavioral cases, context/router benchmarks, provenance checks.  
**GitHub deliverable:** Final release-readiness PR and optional tag only if versioning contract says so.  
**Rollback/recovery:** Release changes isolated from prior functional PRs; tag only after green evidence.  
**Dependencies:** Phases 01–16.

## 22. Implementation discipline

For every phase:

1. inspect current state;
2. make only changes required by that phase;
3. run focused validation first;
4. run broader validation appropriate to the change;
5. inspect diff;
6. commit;
7. push/create PR according to repository workflow;
8. record exact PASS/FAIL/NOT RUN results;
9. stop at the phase boundary.

Do not continue automatically into the next phase.

## 23. Final decision

The repository does not need to become more “enterprise.”

It needs to become more falsifiable.

Keep:

- concise specialist skills;
- project/generic separation;
- progressive disclosure;
- provenance;
- boring PowerShell tooling where it works;
- GrowthOps as a real-world example.

Add:

- lightweight behavioral evidence;
- context/router measurement;
- safer installer recovery;
- Linux pwsh validation;
- explicit lifecycle/evidence separation.

Reject:

- broad rewrites;
- giant metadata schemas;
- dashboards/databases/services;
- automatic creation of ten new skills;
- duplicated mature supporting workflows.

The target state is:

> **a small engineering skill garage whose claims are backed by inspectable evidence, whose limitations are explicit, and whose machinery stays cheaper than the problems it solves.**

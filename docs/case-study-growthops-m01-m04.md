# GrowthOps M01–M04: observational skill evidence

Evidence state: **PARTIALLY VERIFIED**  
Source repository: `exxrawrrr/GrowthOps`  
Evidence window: M01 through M04, committed public records only  
Public-source re-audit: 2026-09-30

This case study documents how the Codex Engineering Skills suite appeared in real GrowthOps engineering work.

It is evidence of **usage + aligned implementation/verification**.

It is **not** evidence that the same tasks would have been worse without the skills. No controlled skill-on versus skill-off experiment is claimed here.

## Privacy boundary

Included:

- public GrowthOps commit IDs;
- public checkpoint/progress records;
- named skills recorded in those documents;
- public test and CI outcomes already documented by GrowthOps.

Excluded:

- private Codex transcripts;
- local session logs;
- secrets or credentials;
- unrelated local workspace content;
- M05-and-later work, regardless of current repository state.

Machine-readable source: [`evidence/cases/growthops-m01-m04.json`](../evidence/cases/growthops-m01-m04.json)

## Public-source verification

During the Phase 08 re-audit, every implementation/merge commit listed by the machine-readable case was resolved in the public `exxrawrrr/GrowthOps` repository, and the M01-M04 checkpoint/progress records were re-read against the claims below.

The machine-readable case and `evidence/INDEX.json` are required to carry the same public commit set and the same skill-observation mapping. CI enforces that parity.

This remains a historical M01-M04 evidence window. M05 and later work are outside this case study even if the GrowthOps repository continues to evolve.

## M01 — Repository Foundation

GrowthOps M01 records `growthops-engineering`, `monorepo-typescript`, and `testing-typescript-systems` among the repository skills used.

Implementation source:

- `164680ef9532e4812baa3b68e51b0a7bfb53e296`

Observed evidence includes:

- `npm run verify` PASS;
- 17 tests passed, 1 platform-specific skip, 0 failed;
- smoke test PASS;
- high-severity npm audit PASS with 0 vulnerabilities;
- later CI PASS on both Ubuntu and Windows.

A useful counterexample to “skill as absolute authority” also appears here: the checkpoint says GrowthOps' canonical npm workspace requirements took precedence over the monorepo skill's pnpm preference.

That is desirable behavior. Repository source-of-truth won.

## M02 — Domain + SQLite Foundation

Recorded repository skills:

- `growthops-engineering`;
- `sqlite-data-modeling`;
- `typescript-node-architecture`;
- `testing-typescript-systems`.

Implementation source:

- `599d50228ae5160e3d4509380d07c28c5c43edb0`

Observed evidence includes:

- `npm run verify` PASS;
- 29 tests passed, 1 platform-specific skip, 0 failed;
- source/security graph check PASS;
- npm audit PASS with 0 vulnerabilities.

The implementation used explicit SQL and a small migration mechanism. It did not add an ORM merely because the task involved persistence.

## M03 — Persistent Job Engine

Recorded repository skills:

- `growthops-engineering`;
- `typescript-node-architecture`;
- `sqlite-data-modeling`;
- `testing-typescript-systems`.

Merged implementation:

- `dae287f456a7d3d36d3d134d3957dce87c918c67`

The strongest evidence in this milestone is failure-first verification:

1. focused regression tests initially produced 2 failures;
2. the defects were corrected;
3. focused job-engine tests passed 10/10;
4. persistence + worker tests passed 17/17;
5. full verification passed with 47 tests passed, 1 skipped, 0 failed;
6. PR #13 passed CI on Ubuntu and Windows.

That does not prove a skill caused the fix. It does show the documented workflow and resulting implementation were consistent with the suite's durability and testing guidance.

## M04 — Safe Crawler Network + Discovery

Recorded repository skills across the M04 evidence:

- `growthops-engineering`;
- `resilient-crawler-engineering`;
- `application-security-local-first`;
- `typescript-node-architecture`;
- `sqlite-data-modeling`;
- `testing-typescript-systems`.

Key public commits:

- `80b255b3b051b848cadd023f3aa612bb4600cc9b` — safe HTTP transport boundary;
- `da5b8d9373a409b1cdd51b1b34501ec3b9601774` — bounded crawl execution orchestration;
- `b1bee1c9b80ad85d533fbd3fc3d102e489f49801` — M04 integration merge.

Observed evidence includes:

- an initial safe-HTTP regression proof with 8 failures before classifier repair;
- focused M04 proof PASS with 137 tests;
- full repository tests PASS with 169 passed, 1 platform-conditional skip, 0 failed;
- typecheck, lint, formatting, source check, build, smoke, and npm audit PASS;
- PR #14 CI PASS on Ubuntu and Windows.

### Important nuance

M04 does **not** support the claim that every slice always loaded the GrowthOps project router.

The M04-A2 progress record explicitly says `growthops-engineering` was unavailable in that Codex skill catalog, so the project operating guide plus named specialist skills were used directly.

That makes the evidence more useful, not less: it separates the project contract from specialist skill availability instead of rewriting history into a cleaner story.

## What this case study supports

**VERIFIED**

- these skill names appear in public GrowthOps milestone records;
- the corresponding public implementation commits exist;
- the checkpoints record concrete verification outcomes;
- skills were used across multiple distinct engineering milestones.

**PARTIALLY VERIFIED**

- the resulting engineering behavior aligns with the skill guidance.

**UNPROVEN**

- causal improvement versus an otherwise identical no-skill run;
- token or latency savings caused by the skills;
- universal usefulness outside GrowthOps.

## Why this matters for the suite

GrowthOps gives this repository something better than a polished README: repeated real-project evidence with failures, corrections, tests, and milestone boundaries.

The next level of evidence is comparative evaluation.

Until that exists, this case study should remain observational and should not be promoted into a benchmark claim.

---
name: agent-skill-evaluation
description: "Design, review, and interpret evidence-backed evaluations for SKILL.md-style agent skills and routers. Use when testing whether a skill changes task outcomes, comparing no-skill/selected/over-loaded variants, measuring routing or context cost, reviewing evidence tiers, or deciding whether a skill should be promoted, revised, or rejected. Do not use as a substitute for ordinary application test strategy."
---

# Agent Skill Evaluation

Use this skill when the object being evaluated is an **agent skill, router, or skill-loading strategy**.

Do not use it merely because an engineering task has tests.

## Load references selectively

- Designing bounded cases and acceptance criteria: `references/case-design.md`
- Comparative executions and confound control: `references/comparative-execution.md`
- Evidence records, claims, and lifecycle interpretation: `references/evidence-reporting.md`

## Neighboring skills

Use `agent-skill-authoring` to create or restructure a skill.

Use `testing-typescript-systems` to test application/system behavior.

This skill owns the question:

> Did loading this skill/router materially improve the agent outcome, and what evidence supports that claim?

## Core rules

1. Define the claim before choosing metrics.
2. Evaluate bounded tasks with explicit acceptance criteria.
3. Prefer observable correctness/safety outcomes over style judgments.
4. Keep comparison variants as similar as practical except for the skill-loading treatment.
5. Include a no-skill baseline when a causal-improvement claim is being tested.
6. Add selected-skill and over-loaded variants when routing/context cost is part of the question.
7. Treat `NOT_RUN` as a valid result; never manufacture evidence to fill a matrix.
8. A completed result requires criterion-level evidence, not a summary adjective.
9. Record runtime/model/repository state when available because agent behavior can drift.
10. Measure context bytes/tokens/tool calls/elapsed time only when the runtime exposes them reliably.
11. Never infer token or latency savings from shorter Markdown alone.
12. Distinguish observational evidence from comparative evidence.
13. Do not upgrade an evidence tier merely because a skill is stable, popular, or well written.
14. Prefer a few high-signal cases over a large synthetic benchmark with weak scoring.
15. Preserve privacy: raw private transcripts are not required when compact sanitized evidence is sufficient.

## Evaluation variants

Common variants:

```text
A. no repository skill
B. recommended skill(s)
C. deliberately over-loaded skill set
```

Not every case needs all three.

Use only the variants required by the claim.

## Scoring preference

Good criteria:

- acceptance criterion passed;
- forbidden behavior avoided;
- regression tests pass;
- security invariant preserved;
- architecture boundary preserved;
- unnecessary dependency/file added;
- rework iteration required;
- exact verification command/result.

Weak criteria:

- "looks professional";
- "seems smarter";
- "better reasoning";
- prose length;
- stylistic preference.

## Workflow

Before execution:

1. state the claim;
2. define the task fixture/state;
3. define acceptance criteria;
4. choose variants;
5. identify controlled variables and known confounds;
6. choose available cost metrics;
7. define evidence format.

After execution:

1. score criteria from evidence;
2. mark missing executions `NOT_RUN`;
3. compare outcomes without hiding regressions;
4. state limitations;
5. update evidence records only to the level justified;
6. do not promote lifecycle/evidence status automatically.

## Completion rule

An evaluation is complete only when a reviewer can answer:

1. What exact claim was tested?
2. Which variants actually ran?
3. What evidence proves each criterion?
4. What changed between variants?
5. What remains unproven?

## Red flags

Stop if:

- the task changes between variants;
- the model/runtime changes but the result is presented as a clean skill comparison;
- success is scored from prose style;
- a no-skill run is omitted while making a causal improvement claim;
- token counts are guessed;
- private transcripts are published unnecessarily;
- a single lucky run is reported as universal effectiveness;
- benchmark machinery becomes larger than the skill problem being evaluated.

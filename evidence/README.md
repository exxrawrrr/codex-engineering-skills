# Evidence assets

This directory contains small, reviewable evidence records and fixtures used to test claims made by this repository.

## Rules

- Evidence records describe what was actually observed.
- Dated baseline snapshots are historical records; do not silently rewrite them to match current repository state.
- Fixtures may be intentionally invalid; they are not installed skills.
- Raw private agent transcripts, secrets, and unrelated local-workspace data do not belong here.
- A failing or superseded result should be preserved or clearly superseded, not rewritten into a success.

The Phase 01 fixtures were intentionally inert when first captured. Later phases now consume them as validator and installer regression tests. The original dated baseline remains a frozen record of the pre-vNext state; see `baseline/README.md`.


## Evidence index contract

`evidence/INDEX.json` is the machine-readable source for reusable evidence claims.

Current schema version: `1`.

The `evidence_tiers` vocabulary is part of that schema and must declare exactly: `none`, `observed`, `repeated`, and `benchmarked`. The validator does not auto-aggregate several lower-tier records into a higher tier; a referenced record must explicitly support the skill at the claimed tier.

Each evidence record must have:

- a unique non-empty `id`;
- `type: observational` or `type: comparative`;
- `claim_state: VERIFIED | PARTIALLY_VERIFIED | UNPROVEN`;
- a non-empty `claim`;
- a non-empty `does_not_claim` limitation;
- `skill_observations` mapping named skills to `observed`, `repeated`, or `benchmarked`.

An observational record may support `observed` or `repeated`. It cannot support `benchmarked`.

A registry skill may claim only the highest tier directly supported for that skill by one of its referenced evidence records. Merely pointing at an existing evidence record is not enough.

`benchmarked` requires comparative evidence that explicitly marks that skill as `benchmarked`. Do not infer it from passing tests, repeated use, or an observational case study.

## Incubation records

Files under `evidence/incubation/` are admission/lifecycle decision records, not reusable effectiveness evidence by themselves.

They may document:
- why a candidate exists;
- ADOPT/MODIFY/DEFER/REJECT decisions;
- overlap boundaries;
- planned representative cases;
- explicit `UNPROVEN` state;
- promotion or rejection conditions.

They do **not** raise a registry `evidence_tier` unless a separate auditable record is added to `evidence/INDEX.json` and explicitly supports that skill. A pre-creation problem case can justify incubation without proving that the new skill is effective.


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

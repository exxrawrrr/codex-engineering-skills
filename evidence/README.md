# Evidence assets

This directory contains small, reviewable evidence records and fixtures used to test claims made by this repository.

## Rules

- Evidence records describe what was actually observed.
- Dated baseline snapshots are historical records; do not silently rewrite them to match current repository state.
- Fixtures may be intentionally invalid; they are not installed skills.
- Raw private agent transcripts, secrets, and unrelated local-workspace data do not belong here.
- A failing or superseded result should be preserved or clearly superseded, not rewritten into a success.

The Phase 01 fixtures were intentionally inert when first captured. Later phases now consume them as validator and installer regression tests. The original dated baseline remains a frozen record of the pre-vNext state; see `baseline/README.md`.

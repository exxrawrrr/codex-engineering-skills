# Baseline snapshots

Files in this directory are **historical snapshots**, not live status documents.

The Phase 01 snapshot `2026-09-30-audit-baseline.json` records the repository state that existed before the vNext implementation sequence began. Its old registry version, skill counts, CI shape, and known gaps are intentional evidence of that moment.

## Maintenance rules

- Do not rewrite a dated baseline so that it matches the current repository.
- Preserve the original commit anchors and observed claim states.
- If a factual mistake is discovered, document the correction explicitly instead of silently modernizing the snapshot.
- If a new baseline is needed, add a new dated snapshot.
- Regression fixtures referenced by the snapshot may later become active tests; that does not change what the original baseline recorded.

`tests/baseline-lock.ps1` protects the Phase 01 anchors and fixture signatures so accidental drift is detected on both CI platforms.

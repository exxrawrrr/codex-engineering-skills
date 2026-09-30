# Milestone protocol

## Canonical sequence

Default implementation order:

```
Architecture proposal
↓
Repository skeleton
↓
Domain + SQLite
↓
Job engine
↓
Crawler
↓
Parser
↓
Check engine
↓
Evidence engine
↓
Finding engine
↓
Action system
↓
Verification
↓
Reporting
↓
Web UI
↓
Browser verifier
↓
Optional AI
↓
Hardening
↓
Packaging
```

Canonical docs may refine milestone numbering/names, but do not reorder casually.

## One milestone at a time

Never accept an instruction equivalent to:

```
build GrowthOps
```

Translate work into a bounded milestone with explicit acceptance criteria.

Implementation loop:

```
implement
↓
test
↓
demonstrate
↓
checkpoint
↓
STOP
```

Do not silently continue into the next milestone.

## Before implementation

For the current milestone state:

1. objective;
2. in-scope behavior;
3. explicitly out-of-scope future work;
4. source-of-truth docs;
5. affected packages/files;
6. invariants;
7. acceptance criteria;
8. tests required;
9. demonstration artifact/output;
10. checkpoint condition.

If acceptance criteria are missing and cannot be derived from locked docs, do not invent product behavior.

## Change discipline

Prefer:
- additive/reversible changes;
- narrow package boundaries;
- small commits/checkpoints;
- regression tests with every bug;
- explicit migrations for persistent schema changes.

Avoid:
- "while I'm here" rewrites;
- future-milestone scaffolding with real behavior;
- broad refactors unrelated to acceptance criteria;
- hidden compatibility breaks.

## Architecture proposals

Architecture proposal is a decision milestone, not permission to implement the whole repository.

It should distinguish:
- locked product requirements;
- proposed technical choices;
- open questions;
- rejected alternatives and rationale when useful.

Do not present a proposed stack as canonical until approved/recorded.

## Checkpoint

A milestone checkpoint should record enough information that another Codex session/model can resume without relying on chat memory.

At minimum:
- milestone status;
- implemented behavior;
- test evidence;
- known limitations;
- open issues;
- next approved milestone;
- relevant commit/branch when available.

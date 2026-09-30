# Collection Policy

This repository is both an engineering skill suite and a personal/public **skill garage**.

Its purpose is to collect skills that are useful, promising, experimental, educational, or project-specific without pretending that every skill must be installed or used.

## Status values

### stable

A reusable skill that is considered useful enough for normal use and is expected to be maintained.

### incubating

A new or experimental skill. It may change substantially as it is tested in real projects.

### reference

A skill or pattern retained primarily as a knowledge/reference asset. It may be useful for study or selective reuse without being part of a normal install path.

### project

A project-specific router or contract. It intentionally contains product-specific scope, vocabulary, milestones, or release gates.

## Presence is not endorsement

A skill being in this repository means it was worth collecting or developing.

It does not mean:
- every project needs it;
- every agent should load it;
- it is the best solution for every stack;
- it will remain unchanged forever.

## Installation philosophy

Use the smallest set of skills required for the current task.

Do not install or load the entire collection just because it exists.

## Promotion

An incubating skill may become stable after:
- repeated real-world use;
- clear routing boundaries;
- no accidental project leakage;
- useful references/provenance;
- validation passes;
- feedback shows the skill improves outcomes.

## Retirement

Skills may be deprecated, archived, or moved to reference status when they become redundant, outdated, or too narrow.

History and attribution should remain visible.

## Project-specific material

Project routers such as `growthops-engineering` are intentionally preserved as examples of real-world composition.

They should be adapted, not blindly reused.


## Lifecycle status vs evidence tier

Lifecycle status answers how the repository maintains and recommends an artifact. It does **not** by itself prove behavioral effectiveness.

Evidence is tracked separately in `REGISTRY.json`:

- `none` — no auditable real-use or behavioral evidence is recorded;
- `observed` — at least one auditable real-use observation exists;
- `repeated` — observations exist across multiple milestones/tasks;
- `benchmarked` — at least one reproducible comparative behavioral evaluation exists.

Evidence refs must resolve to records in `evidence/INDEX.json`.

Do not promote an evidence tier because a skill is long, well-written, popular, or marked stable. A tier must be supported by the referenced record.

Observational evidence can justify `observed` or `repeated`, but it must not be described as causal skill improvement unless a comparative evaluation supports that claim.

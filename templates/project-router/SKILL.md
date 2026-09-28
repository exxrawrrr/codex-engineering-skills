---
name: your-project-engineering
description: "Project-level engineering contract and skill router for Your Project. Use for any implementation, architecture, refactor, test, review, milestone, or repository-structure task in this project."
---

# Your Project Engineering

Use this skill FIRST for engineering work in this project.

## Source of truth

List the repository documents that define product and architecture decisions.

Repository-approved documentation wins over chat memory and generic skill defaults.

## Project principles

Define a short set of stable principles.

Example:

1. Deterministic-first.
2. Human-controlled.
3. Restart-safe.
4. Evidence-backed.
5. No silent failure.

## Scope

State what the current product/release includes and explicitly excludes.

Do not allow agents to implement future roadmap items silently.

## Specialist routing

For each major task class, name only the skills that should usually be loaded.

Example:

```
database task:
- your-project-engineering
- sqlite-data-modeling
- testing-typescript-systems
- verification-loop
```

## Milestone protocol

Use one bounded milestone at a time:

```
implement -> test -> demonstrate -> checkpoint -> stop
```

## Definition of Done

Define observable completion requirements.

## Release gates

Define blocking release conditions.

## Prohibitions

- Do not invent product direction.
- Do not add future-scope features.
- Do not replace deterministic logic with AI without approval.
- Do not introduce infrastructure without a demonstrated need.

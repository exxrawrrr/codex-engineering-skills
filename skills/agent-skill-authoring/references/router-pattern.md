# Project router pattern

A project router is a project-specific contract skill.

It should encode:
- source-of-truth precedence;
- immutable product/engineering principles;
- vocabulary;
- scope boundaries;
- milestone sequencing;
- Definition of Done;
- release gates;
- routing to generic specialist skills.

It should not duplicate:
- full TypeScript rules;
- full database guidance;
- complete security manuals;
- framework docs.

## Typical composition

```
project-engineering
  -> typescript-node-architecture
  -> sqlite-data-modeling
  -> testing-typescript-systems
  -> verification-loop
```

The exact specialist set changes by task.

## Router safety

A router must explicitly prevent:
- speculative future-scope implementation;
- silent stack decisions;
- loading all skills for every task;
- optional subsystem failures becoming core failures;
- product direction being invented by the coding agent.

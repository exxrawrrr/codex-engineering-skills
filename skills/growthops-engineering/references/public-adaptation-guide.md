# Public Adaptation Guide

The suite contains six broadly reusable engineering skills plus one GrowthOps-specific router.

## Reusable skills

- typescript-node-architecture
- monorepo-typescript
- sqlite-data-modeling
- resilient-crawler-engineering
- application-security-local-first
- testing-typescript-systems

These are written to be project-agnostic. Project examples should remain generic.

## Project-specific skill

- growthops-engineering

Do not reuse this skill unchanged for another product. Replace:
- product identity;
- domain vocabulary;
- scope boundaries;
- milestone order;
- release gates;
- specialist routing.

## Recommended adaptation pattern

Create a project router skill with:

1. immutable product principles;
2. source-of-truth document precedence;
3. domain vocabulary;
4. scope boundaries;
5. milestone protocol;
6. Definition of Done;
7. release gates;
8. selective routing to generic specialist skills.

Keep implementation detail out of the router when it belongs in specialist skills.

## Context-efficiency rule

Do not merge all specialist references into one giant skill.

Use:

project router
-> one to four relevant specialist skills
-> verification skill

Load reference files only when the current task needs them.

## Publishing

Before public distribution:
- choose and add an explicit license;
- preserve upstream attribution where content is substantially derived;
- run the suite validator;
- remove project secrets, private paths, and organization-specific credentials;
- document supported agent/skill-directory conventions.

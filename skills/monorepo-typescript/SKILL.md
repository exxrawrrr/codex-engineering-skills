---
name: monorepo-typescript
description: "Structure and maintain TypeScript monorepos with pnpm workspaces, explicit package ownership, stable exports, shared configuration, acyclic dependencies, and efficient build/test orchestration. Use when changing workspace layout, adding apps/packages, changing internal dependencies, or defining monorepo conventions."
---

# TypeScript Monorepo

Use this skill only for real multi-package workspaces.

## Progressive disclosure

Read only the reference relevant to the task:

- Workspace/package boundaries: `references/workspace-boundaries.md`
- pnpm/config/build/test orchestration: `references/pnpm-orchestration.md`

## Core rules

1. Every package owns one coherent responsibility.
2. Apps compose packages; packages never depend on apps.
3. Internal dependencies are declared explicitly in package manifests.
4. Consume public package exports, never another package's private `src/`.
5. Keep the dependency graph acyclic.
6. Shared configuration removes duplication but must not hide behavior.
7. Prefer plain pnpm workspace capabilities first.
8. Do not add Turborepo/Nx/Changesets unless a demonstrated problem requires them.
9. Do not create empty roadmap packages.
10. Prefer fewer, stronger packages over tiny fragmented packages.

## Baseline shape

```
apps/
packages/
fixtures/
tests/
scripts/
docs/
package.json
pnpm-workspace.yaml
tsconfig.base.json
```

Before creating a package, define its responsibility in one sentence.

Good:
- `@app/core`: domain models and core rules.
- `@app/db`: SQLite persistence and migrations.
- `@app/crawler`: crawl scheduling/retrieval behavior.

Bad:
- `@app/common`
- `@app/helpers`
- `@app/misc`

## Change workflow

Before structural changes:
1. Read root manifest/workspace/tsconfig and repository instructions.
2. Map the current dependency direction.
3. Identify the minimum structural change.
4. Preserve existing public entry points unless the spec permits breaking changes.

When adding a package:
1. state ownership;
2. create manifest/config;
3. define public exports;
4. add only required dependencies;
5. add relevant tests;
6. wire consumers through public API;
7. verify no cycle/deep import was introduced.

## Red flags

Stop if:
- TypeScript aliases bypass undeclared package dependencies;
- root package.json becomes a dumping ground for app/package dependencies;
- packages deep-import each other's source;
- a package depends on an app;
- a new package exists only because a roadmap mentions future work;
- orchestration tooling is added before plain pnpm commands become inadequate.

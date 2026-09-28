# pnpm workspace and orchestration

## Internal dependencies

Use workspace protocol when appropriate:

```json
{
  "dependencies": {
    "@app/core": "workspace:*"
  }
}
```

Runtime deps belong in the package that imports them.
Do not hoist dependencies to root merely to make resolution succeed.

## TypeScript config

Use a small root base config.
Package configs extend it and own package-specific options.

Do not use TS path aliases to fake package boundaries.

## Commands

Package scripts should remain directly runnable.

Root orchestration may use:

```
pnpm -r build
pnpm -r test
pnpm -r typecheck
```

For focused work, prefer filters:

```
pnpm --filter @app/crawler test
```

Do not rebuild/test the entire monorepo when a smaller correct target exists.

## Orchestration escalation

Start with pnpm workspaces.
Introduce a task graph/cache tool only when evidence shows a real bottleneck or coordination requirement.

Framework-specific monorepo rules belong in separate skills/references, not this generic skill.

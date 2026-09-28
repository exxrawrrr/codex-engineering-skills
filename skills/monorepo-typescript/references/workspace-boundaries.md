# Workspace boundaries

This reference adapts strong patterns from public monorepo agent guidance while remaining framework-neutral.

## Apps vs packages

`apps/*` are runnable entry points.
`packages/*` are reusable domain/infrastructure modules.

Apps may depend on packages.
Packages must not depend on apps.

## Public APIs

Expose narrow package entry points via `package.json` exports or a documented root entry.

Prefer:

```ts
import { createCrawler } from "@app/crawler";
```

Avoid:

```ts
import { normalizeUrl } from "@app/crawler/src/internal/url/normalize";
```

Do not export every internal file from a barrel.

## Package creation test

Create a package only if at least one is true:
- it owns a distinct domain/infrastructure responsibility;
- multiple apps/packages need the same stable contract;
- independent testing/reasoning becomes materially clearer;
- dependency direction becomes safer.

Otherwise keep the code near its current owner.

## Shared code

Do not centralize two similar helpers prematurely.
A shared package creates coupling and compatibility obligations.

If ownership cannot be stated in one sentence, do not split yet.

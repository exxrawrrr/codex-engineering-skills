# Source Provenance

This suite is a curated synthesis. It is not a verbatim copy of any single upstream skill.

Machine-readable source-to-skill maintenance map: [`PROVENANCE.json`](PROVENANCE.json).

`PROVENANCE.json` supports validation and drift control. It does not replace this human-readable source record, `ATTRIBUTION.md`, `NOTICE`, or upstream license review.

## Primary official references

### TypeScript
- https://www.typescriptlang.org/tsconfig/
- https://www.typescriptlang.org/tsconfig/exactOptionalPropertyTypes.html
- https://www.typescriptlang.org/tsconfig/noUncheckedIndexedAccess.html

Used for strict compiler guidance and type-safety defaults.

### pnpm
- https://pnpm.io/
- https://pnpm.io/workspaces
- https://pnpm.io/package-sources
- https://pnpm.io/cli/audit

Used for workspace protocol, filtered workspace execution, dependency hygiene, and supply-chain considerations.

### SQLite
- https://www.sqlite.org/wal.html
- https://www.sqlite.org/pragma.html
- https://www.sqlite.org/foreignkeys.html
- https://www.sqlite.org/lang_transaction.html

Used for WAL behavior, foreign-key enforcement, busy handling, transactions, and durability notes.

### Vitest
- https://vitest.dev/guide/
- https://vitest.dev/guide/mocking.html
- https://vitest.dev/guide/mocking/timers

Used for focused unit/integration testing, mocks, and fake-timer guidance.

### Mock Service Worker
- https://mswjs.io/

Used for network-level request mocking guidance instead of business-function monkey-patching.

### Playwright
- https://playwright.dev/docs/intro
- https://playwright.dev/docs/test-assertions

Used for targeted browser/E2E verification guidance.

### OWASP
- https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Path_Traversal_Cheat_Sheet.html

Used for SSRF, redirect/network boundaries, XSS/output safety, prompt-injection isolation, and path containment.

## Public repositories benchmarked

These were used as design references, not copied wholesale.

- https://github.com/brendonboshell/supercrawler
  - durable queue concepts, robots/sitemap discovery, concurrency/rate limiting, retry scheduling.
- https://github.com/timothy-nishimura/crawl
  - TypeScript crawler architecture, hard crawl limits, SSRF-aware transport boundaries.
- https://github.com/alfa546/Crawler
  - local-first crawler patterns, adaptive 429/503 handling, pause/resume concepts.
- https://github.com/Jean-W-FE/nextjs-monorepo-agent-skill
  - progressive-disclosure layout and reference separation for monorepo skills.
- https://github.com/ersinkoc/project-bootstrap
  - skill generation structure and keeping SKILL.md bounded with references.
- https://github.com/trailofbits/claude-code-config
  - strict TypeScript/compiler and supply-chain review inspiration.
- https://github.com/jezweb/claude-skills
  - testing skill patterns, Vitest/integration-test decomposition.

## Repository-original evaluation framework

`agent-skill-evaluation` is an original synthesis built from this repository's own evidence model, behavioral case contract, context benchmark, and router-evaluation work.

Its provenance mapping points back to this repository rather than implying an external benchmark framework was copied.

## Project-specific source

GrowthOps product rules come from the canonical GrowthOps blueprint authored for this project.

The project-specific skill must not be treated as a generic product-management template. Its scope, vocabulary, milestone order, and release gates belong to GrowthOps unless explicitly adapted.

## Maintenance rule

When an upstream tool/framework changes materially:
1. verify current official documentation;
2. update only the affected reference;
3. preserve project invariants unless canonical GrowthOps docs change;
4. record the update in the audit report/changelog.

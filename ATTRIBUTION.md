# Attribution & Provenance

This repository is a **curated synthesis and re-authoring**, not a wholesale copy of the projects below.

The referenced projects and official docs were studied to compare engineering patterns. The resulting skills were rewritten, combined, narrowed, extended, and organized around progressive disclosure and agent-oriented usage.

For the canonical machine-readable source-to-skill mapping used by repository validation, including the dated 2026-09-30 source/license review evidence, see [`PROVENANCE.json`](PROVENANCE.json). Human-readable attribution and license caveats remain authoritative here.

## Public repository references

### @brendonboshell / supercrawler
- https://github.com/brendonboshell/supercrawler
- Verified license: Apache-2.0
- Referenced for durable URL queues, robots.txt/sitemap handling, concurrency/rate limiting, and retry scheduling.
- Mainly informed `resilient-crawler-engineering`.

### @timothy-nishimura / crawl
- https://github.com/timothy-nishimura/crawl
- Verified license: MIT
- Referenced for modular TypeScript crawler architecture, hard crawl limits, SSRF-aware transport boundaries, and static-first crawling.
- Mainly informed `resilient-crawler-engineering` and `application-security-local-first`.

### @alfa546 / Crawler
- https://github.com/alfa546/Crawler
- Verified license: MIT
- Referenced for local-first crawling, adaptive 429/503 handling, pause/resume concepts, and SEO-oriented resilience.
- Mainly informed `resilient-crawler-engineering`.

### @Jean-W-FE / nextjs-monorepo-agent-skill
- https://github.com/Jean-W-FE/nextjs-monorepo-agent-skill
- Verified license: MIT
- Referenced for skill packaging and progressive disclosure through smaller reference files.

### @ersinkoc / project-bootstrap
- https://github.com/ersinkoc/project-bootstrap
- Verified license: MIT
- Referenced for compact skill entrypoints, supporting references, and agent-oriented bootstrap structure.

### @trailofbits / claude-code-config
- https://github.com/trailofbits/claude-code-config
- Referenced as public engineering guidance for strict TypeScript/compiler settings and dependency/supply-chain thinking.
- Its license was not reliably retrieved during this preparation pass, so this repository does not make a license claim for it and does not claim to redistribute that project.

### @jezweb / claude-skills
- https://github.com/jezweb/claude-skills
- Verified license: MIT
- Referenced for Vitest/integration-test decomposition and testing-skill patterns.
- Mainly informed `testing-typescript-systems`.

## Official documentation

- TypeScript: https://www.typescriptlang.org/tsconfig/
- pnpm: https://pnpm.io/
- SQLite: https://www.sqlite.org/
- Vitest: https://vitest.dev/
- MSW: https://mswjs.io/
- Playwright: https://playwright.dev/
- OWASP Cheat Sheet Series: https://cheatsheetseries.owasp.org/

OWASP guidance materially informed SSRF, XSS/output encoding, path containment, and prompt-injection boundaries.

## What this repository adds

This suite adds its own cross-skill routing model, project-router pattern, restart-safety rules, partial-failure behavior, local-first security posture, source provenance, validator, backup-before-overwrite installer, generic/project-specific separation, and the GrowthOps project contract/milestone system.

Third-party names and copyrights belong to their respective owners. Attribution does not imply endorsement, affiliation, or co-authorship.

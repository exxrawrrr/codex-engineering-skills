# Codex Engineering Skills

Reusable engineering skills for Codex and other agent workflows that understand `SKILL.md`-style instructions.

The suite focuses on **boring, testable, recoverable engineering**: strict TypeScript architecture, monorepo boundaries, SQLite durability, resilient crawlers, local-first application security, system testing, and project-level skill routing.

## Included

| Skill | Purpose |
| --- | --- |
| `typescript-node-architecture` | Strict TypeScript/Node boundaries, contracts, async lifecycle, error design |
| `monorepo-typescript` | pnpm workspaces, package ownership, exports, dependency direction |
| `sqlite-data-modeling` | Schema design, migrations, transactions, locking, restart-safe state |
| `resilient-crawler-engineering` | Durable frontier, retries/backoff, robots/sitemaps, checkpoint/resume |
| `application-security-local-first` | SSRF/DNS rebinding, XSS, path safety, secrets, prompt-injection boundaries |
| `testing-typescript-systems` | Vitest, MSW, fixtures, durability/fault/restart tests, targeted E2E |
| `growthops-engineering` | Example of a real project-specific router/contract skill |

The first six are reusable. `growthops-engineering` is intentionally project-specific and should be adapted rather than copied unchanged.

## Design

```text
project router
  -> relevant specialist skill(s)
    -> selected references
      -> verification
```

This keeps context smaller than loading one giant instruction corpus for every task.

## Install

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Generic skills only:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -GenericOnly
```

Default target is `%USERPROFILE%\.codex\skills`. Existing matching folders are backed up before replacement.

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File .\validate.ps1
```

The validator checks frontmatter, names, references, encoding corruption, tool-output contamination, context size, generic/project leakage, and suite maintenance assets.

## Provenance

These skills are **newly authored as a curated synthesis**. This repository is not a wholesale fork or copy of one upstream project.

Public repositories and official documentation were studied, patterns were compared, then the skills were rewritten, narrowed, extended, and organized for agent use.

See [ATTRIBUTION.md](ATTRIBUTION.md), [NOTICE](NOTICE), and [SOURCES.md](SOURCES.md).

Key public references:

- [@brendonboshell](https://github.com/brendonboshell) — [supercrawler](https://github.com/brendonboshell/supercrawler)
- [@timothy-nishimura](https://github.com/timothy-nishimura) — [crawl](https://github.com/timothy-nishimura/crawl)
- [@alfa546](https://github.com/alfa546) — [Crawler](https://github.com/alfa546/Crawler)
- [@Jean-W-FE](https://github.com/Jean-W-FE) — [nextjs-monorepo-agent-skill](https://github.com/Jean-W-FE/nextjs-monorepo-agent-skill)
- [@ersinkoc](https://github.com/ersinkoc) — [project-bootstrap](https://github.com/ersinkoc/project-bootstrap)
- [@trailofbits](https://github.com/trailofbits) — [claude-code-config](https://github.com/trailofbits/claude-code-config)
- [@jezweb](https://github.com/jezweb) — [claude-skills](https://github.com/jezweb/claude-skills)

Official references include TypeScript, pnpm, SQLite, Vitest, MSW, Playwright, and OWASP guidance.

## License

Apache-2.0. Third-party projects retain their own copyrights and licenses. See [ATTRIBUTION.md](ATTRIBUTION.md).

## Contributing

Contributions that improve correctness, safety, portability, context efficiency, testability, or source attribution are welcome.

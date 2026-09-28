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
| `agent-skill-authoring` | Meta-skill for creating, reviewing, packaging, and publishing agent skills |
| `growthops-engineering` | Example of a real project-specific router/contract skill |

The reusable skills are designed to work across projects. `growthops-engineering` is intentionally project-specific and should be adapted rather than copied unchanged.

## Skill garage / collection philosophy

This repository is also a **personal/public skill garage**: a place to collect engineering skills, patterns, experiments, and project routers that may be useful now or later.

A skill being present here does **not** mean everyone should load it, install it, or use it on every project.

Registry status helps communicate intent:

- `stable` — actively useful and expected to be maintained;
- `incubating` — experimental/new, useful for testing and refinement;
- `reference` — kept mainly as a pattern or knowledge asset;
- `project` — intentionally tied to a specific project.

The goal is to curate useful skills without pretending every collected skill is universally necessary.

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
## Build your own skills

This repository now includes `agent-skill-authoring`, an original meta-skill for designing and reviewing maintainable agent skills.

Start from:

- [AUTHORING_STANDARD.md](AUTHORING_STANDARD.md)
- [templates/project-router/SKILL.md](templates/project-router/SKILL.md)
- [examples/ROUTING_EXAMPLES.md](examples/ROUTING_EXAMPLES.md)
- [REGISTRY.json](REGISTRY.json)

The validator and installer are registry-driven, so adding a new skill means adding its folder plus one registry entry.

See [COLLECTION_POLICY.md](COLLECTION_POLICY.md) for how stable, experimental, reference, and project-specific skills are handled.

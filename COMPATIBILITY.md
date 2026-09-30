# Compatibility

Compatibility in this repository is described across three separate dimensions:

- **Format** — can the runtime consume the Markdown / `SKILL.md` folder representation?
- **Architecture** — can the runtime represent selective loading, project routers, specialist skills, and references?
- **Tested execution** — has this repository's executable validator/installer/test workflow actually passed in that environment?

Do not collapse those into one vague "portable" claim.

## Repository format

The canonical layout is intentionally simple:

```text
skills/<skill-name>/SKILL.md
skills/<skill-name>/references/*.md
skills/<skill-name>/scripts/*
```

The skill content is predominantly Markdown. Executable repository maintenance tooling is PowerShell-first.

## Tested environments

| Environment | Format | Architecture | Tested execution |
| --- | --- | --- | --- |
| Windows + PowerShell + filesystem `SKILL.md` loading | COMPATIBLE | COMPATIBLE | **TESTED** |
| Ubuntu Linux + PowerShell + filesystem `SKILL.md` loading | COMPATIBLE | COMPATIBLE | **TESTED** |
| macOS + PowerShell + filesystem `SKILL.md` loading | COMPATIBLE_BY_FORMAT | COMPATIBLE_BY_DESIGN | **NOT RUN** |
| Other agent using a compatible filesystem skill convention | LIKELY_COMPATIBLE | COMPATIBLE_BY_DESIGN | **NOT RUN** |
| Agent requiring different frontmatter/index/packaging conventions | ADAPTATION_REQUIRED | ADAPTABLE | NOT_APPLICABLE |

Machine-readable matrix: [`evidence/compatibility/2026-09-30.json`](evidence/compatibility/2026-09-30.json).

### What "TESTED" means here

For Windows and Ubuntu, GitHub Actions PR #12 run `36667646038` executed the complete repository suite, including:

- static skill validation;
- negative encoding/registry fixtures;
- behavioral-evaluation record validation;
- context-footprint benchmark;
- router-selection contract validation;
- GrowthOps evidence case validation;
- installer selection/backup-root tests;
- installer staging, idempotency, rollback, and fault-injection tests.

Both `windows-latest` and `ubuntu-latest` completed successfully.

This proves the repository maintenance/install workflow on those CI environments. It does **not** prove that every third-party agent runtime loads skills identically.

## Codex

The primary local installation target remains:

```text
%USERPROFILE%\.codex\skills
```

The included PowerShell installer supports filesystem skill roots directly and accepts a custom `-TargetRoot`.

The Windows Codex layout is therefore a primary supported use case, not the only possible representation of the Markdown content.

## Linux

The PowerShell validator, evidence checks, router checks, and installer tests now have successful Ubuntu CI execution.

That is a tested repository-tooling claim.

It is not a claim that every Linux-hosted agent automatically discovers `SKILL.md` folders in the same location or with the same semantics.

## macOS

The Markdown format is not OS-specific, and the current PowerShell tooling is designed without an intentional Windows-only implementation dependency.

However:

**macOS execution is NOT RUN.**

vNext explicitly defers a macOS CI runner until there is a concrete need. Do not report macOS installer/validator support as tested.

## Other agents

Other systems may require:

- a different skills directory;
- different frontmatter fields;
- a generated wrapper/index;
- different routing metadata;
- manual or runtime-specific skill selection.

When those differences exist, adapt the packaging layer rather than rewriting the engineering guidance unnecessarily.

Use `-TargetRoot` only when the target runtime actually supports a compatible filesystem-based skill directory.

## Supporting skills

Some routing examples reference external/supporting skills such as:

- verification-loop;
- systematic-debugging;
- requesting-code-review;
- codebase-onboarding;
- playwright-cli.

These are recommended integrations, not bundled dependencies.

Their availability is separate from this repository's OS/runtime compatibility.

## Claim discipline

Use these terms deliberately:

- **TESTED** — an executable repository workflow passed in that environment.
- **NOT RUN** — plausible or designed support exists, but no successful execution is claimed.
- **ADAPTATION_REQUIRED** — the runtime convention differs and needs a wrapper/index/frontmatter or packaging adaptation.
- **COMPATIBLE_BY_FORMAT / COMPATIBLE_BY_DESIGN** — structural compatibility only, not execution evidence.

If an environment is absent from the tested matrix, do not upgrade it to "supported" from intuition alone.

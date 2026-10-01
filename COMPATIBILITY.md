# Compatibility

Compatibility in this repository is deliberately split into four different questions:

- **Format** — is the Markdown / `SKILL.md` folder representation structurally compatible?
- **Architecture** — can the target convention represent selective loading, project routers, specialist skills, and references?
- **Tested execution** — has this repository's executable validator/installer/test workflow passed in the named host environment?
- **Runtime loading** — has a named agent/runtime actually discovered and loaded these `SKILL.md` folders with the intended semantics?

Do not collapse those into one vague "portable" or "supported" claim.

## Repository format

The canonical repository layout is intentionally simple:

```text
skills/<skill-name>/SKILL.md
skills/<skill-name>/references/*.md
skills/<skill-name>/scripts/*
```

The skill content is predominantly Markdown. Repository maintenance and installation tooling is PowerShell-first.

Structural simplicity is useful portability evidence, but it is not execution evidence by itself.

## Compatibility matrix

| Environment | Format | Architecture | Tested execution | Runtime loading |
| --- | --- | --- | --- | --- |
| GitHub-hosted Windows + PowerShell Core repository tooling | COMPATIBLE_BY_FORMAT | COMPATIBLE_BY_DESIGN | **TESTED** | **NOT RUN** |
| GitHub-hosted Ubuntu + PowerShell Core repository tooling | COMPATIBLE_BY_FORMAT | COMPATIBLE_BY_DESIGN | **TESTED** | **NOT RUN** |
| macOS + PowerShell + filesystem `SKILL.md` convention | COMPATIBLE_BY_FORMAT | COMPATIBLE_BY_DESIGN | **NOT RUN** | **NOT RUN** |
| Other agent using a compatible filesystem skill convention | LIKELY_COMPATIBLE | COMPATIBLE_BY_DESIGN | **NOT RUN** | **NOT RUN** |
| Agent requiring different frontmatter/index/packaging/discovery/routing conventions | ADAPTATION_REQUIRED | ADAPTABLE | NOT_APPLICABLE | NOT_APPLICABLE |

Machine-readable source: [`evidence/compatibility/2026-09-30.json`](evidence/compatibility/2026-09-30.json).

## Historical tested-execution snapshot (2026-09-30)

The machine-readable compatibility record under `evidence/compatibility/2026-09-30.json` is a dated historical snapshot. It is intentionally not rewritten every time later CI succeeds. For current repository health, inspect the latest GitHub Actions run for the relevant commit or pull request; a later green run does not by itself change the runtime-loading or macOS claims below.

The dated compatibility evidence snapshot is based on:

- repository commit: `7a361791aa310fc3cf0e54e9a5a5a499abb9b3d8`;
- PR: **#26 — Phase 11 cross-platform PowerShell CI re-audit**;
- GitHub Actions run: `36686190812`;
- matrix runners: `windows-latest` and `ubuntu-latest`;
- both jobs: **success**;
- observed runtime on both jobs: `PSEdition=Core`, PowerShell `7.6.6`.

That run executed the current shared repository suite, including:

- static skill validation;
- baseline, encoding, registry, and static-validator contracts;
- evidence-model checks;
- behavioral-evaluation validation and negative contracts;
- context benchmark and drift contracts;
- router-selection contracts;
- GrowthOps observational case-study contracts;
- installer selection/path-safety tests;
- invocation-wide staging/backup/rollback/idempotency fault injection;
- compatibility contract checks;
- provenance checks.

This is strong evidence for **repository tooling execution on those two GitHub-hosted OS environments**.

It does **not** prove:

- automatic `SKILL.md` discovery/loading by Codex or any other agent runtime;
- macOS executable support;
- support for arbitrary Linux distributions or self-hosted runners;
- identical behavior in systems with different frontmatter, packaging, discovery, or routing conventions.

The observed PowerShell `7.6.6` values are evidence from that run, not a promise that future hosted runners must use that exact patch release. The workflow contract requires PowerShell Core 7+.

## Windows

The current repository validator, evidence checks, installer selection/path tests, and installer transaction tests passed on GitHub-hosted `windows-latest` with PowerShell Core 7.6.6 in run `36686190812`.

The primary local Codex installation example remains:

```text
%USERPROFILE%\.codex\skills
```

The included installer accepts a custom `-TargetRoot` for compatible filesystem destinations.

This supports a **repository tooling** claim for the tested Windows runner. It does not independently prove that every Windows-hosted agent discovers that directory or interprets the skill format identically.

## Ubuntu Linux

The same shared suite passed on GitHub-hosted `ubuntu-latest` with PowerShell Core 7.6.6 in run `36686190812`.

This is a tested repository-tooling claim for that hosted Ubuntu environment.

It is not a blanket claim for:

- every Linux distribution;
- every PowerShell build;
- every filesystem or shell configuration;
- automatic skill discovery by arbitrary Linux-hosted agents.

## macOS

The Markdown representation is not intrinsically Windows-specific, and the current tooling is designed around PowerShell Core conventions rather than Windows PowerShell-only APIs.

However:

**macOS tested execution: NOT RUN.**

**macOS runtime loading: NOT RUN.**

There is no macOS CI runner in the current validation workflow. Do not report macOS installer/validator execution as tested until a real macOS run exists.

## Codex and other agent runtimes

This repository's CI validates files, contracts, and installer behavior. It does not launch a Codex runtime or another agent runtime and prove skill discovery/loading semantics.

For Codex, the Windows filesystem layout above is the primary local target used by this repository's installer examples. Treat that as an installation convention, not as a universal runtime-loading proof.

Other systems may require:

- a different skills directory;
- different frontmatter fields;
- a generated wrapper or index;
- different routing metadata;
- runtime-specific discovery/registration;
- manual selection.

If the runtime convention differs, adapt the packaging layer rather than silently calling the repository drop-in compatible.

Use `-TargetRoot` only when the target runtime actually supports a compatible filesystem skill convention.

## Supporting skills

Some routing examples reference external/supporting skills such as:

- verification-loop;
- systematic-debugging;
- requesting-code-review;
- codebase-onboarding;
- playwright-cli.

These are recommended integrations, not bundled dependencies.

Their availability is independent of this repository's host-OS tooling compatibility.

## Claim vocabulary

Use these terms deliberately:

- **TESTED** — the executable repository workflow passed in the named host environment.
- **NOT RUN** — no successful execution/loading evidence is recorded for that dimension.
- **COMPATIBLE_BY_FORMAT** — the representation is structurally compatible; no execution claim follows.
- **COMPATIBLE_BY_DESIGN** — the architecture appears representable by the convention; no execution claim follows.
- **LIKELY_COMPATIBLE** — structural similarity exists, but the named/unspecified runtime has not been executed.
- **ADAPTATION_REQUIRED** — the runtime convention differs and needs a wrapper/index/frontmatter/packaging adaptation.
- **ADAPTABLE** — the architecture can plausibly be mapped after adaptation; this is not drop-in support.
- **NOT_APPLICABLE** — the dimension is not meaningful until the required adaptation exists.

If evidence is absent for a dimension, do not upgrade that dimension to "supported" from intuition alone.

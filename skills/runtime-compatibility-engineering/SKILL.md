---
name: runtime-compatibility-engineering
description: "Design, review, or repair host/runtime/toolchain compatibility claims and evidence: OS/runtime support matrices, minimum-version boundaries, format-vs-execution distinctions, adaptation requirements, and cross-platform regression checks. Use when deciding what environments are actually supported or when a compatibility claim exceeds the tested evidence. Do not use for HTTP/API contract compatibility, dependency upgrade sequencing, database migrations, production rollout/rollback, or general application testing."
---

# Runtime Compatibility Engineering

Use this skill when the question is:

> What host/runtime/toolchain environments are actually supported, and what evidence justifies that claim?

This skill is about **support claims**, not generic portability optimism.

## Load references selectively

- Compatibility claim vocabulary and evidence boundaries:
  `references/support-claims.md`
- Building and maintaining environment/version matrices:
  `references/environment-matrices.md`

## Neighboring skills

Use `api-contract-testing` for provider/consumer API compatibility.

Use `ci-pipeline-reliability` to ensure compatibility checks actually execute and fail visibly.

Use `testing-typescript-systems` to design the tests that exercise behavior.

This skill owns **the meaning and evidence boundary of host/runtime/toolchain compatibility claims**.

## When to load

Load this skill when one or more are true:

- an OS/runtime/toolchain support matrix is being created or changed;
- a repository claims support for an environment that CI has not executed;
- minimum runtime or platform versions need to be defined;
- a format may be structurally portable but executable support is uncertain;
- a third-party runtime uses different discovery/frontmatter/packaging conventions;
- a `latest` hosted image or moving toolchain changes what was actually tested;
- support claims must be narrowed after a platform/runtime regression.

## When not to load

Do not load this skill for:

- HTTP/API provider-consumer compatibility;
- dependency upgrade sequencing;
- database/schema migrations;
- application feature tests;
- production deployment rollout or rollback;
- generic CI failures that do not change compatibility claims.

## Core rules

1. Separate **format compatibility**, **design compatibility**, **tested execution**, and **runtime loading/integration**.
2. A passing test on one OS/runtime does not prove another OS/runtime.
3. A moving alias such as `latest` is evidence about the resolved environment that actually ran, not every future image behind the alias.
4. Record the environment identity that matters: OS, architecture, runtime/toolchain versions, and runner/image when available.
5. Distinguish vendor-supported from merely observed-working.
6. Distinguish repository-tooling execution from third-party runtime discovery/loading.
7. Never upgrade `NOT_RUN` to supported from intuition.
8. Prefer narrow support statements over blanket portability claims.
9. Minimum-version claims require a tested lower boundary or authoritative runtime/platform requirement.
10. If an environment needs wrappers, generated indexes, different frontmatter, or packaging changes, call it `ADAPTATION_REQUIRED` rather than drop-in compatible.
11. Test the compatibility dimension that the claim actually names.
12. Keep historical evidence dated; support lifecycles and hosted images move.
13. A current vendor support statement does not prove this repository has executed there.
14. A repository CI pass does not prove every downstream agent/runtime integration.
15. If evidence is missing, state `NOT_RUN`, `NOT_AVAILABLE`, or an equivalent bounded status.

## Compatibility dimensions

Use separate dimensions when useful:

- **format** — can the files/data be represented structurally?
- **architecture** — can the target convention represent the required design?
- **tested execution** — did the repository/tooling actually run successfully?
- **runtime loading/integration** — did the named runtime discover/load/integrate it?
- **vendor support** — does the platform/runtime vendor currently support that environment?
- **adaptation** — is translation/wrapping required before direct use?

Do not collapse these into one "supported" boolean unless all relevant dimensions are intentionally equivalent.

## Environment matrix workflow

Before claiming compatibility:

1. name the environment rows;
2. name the compatibility dimensions;
3. define allowed status vocabulary;
4. identify evidence for each non-NOT_RUN cell;
5. record exact runtime/OS/tool versions where material;
6. separate static/design evidence from executed evidence;
7. record exclusions and adaptation boundaries;
8. add a regression check for high-value claim rows.

After execution:

- update only rows justified by the run;
- preserve NOT_RUN elsewhere;
- date the evidence;
- retain the command/run identifier when available;
- state what the run does **not** prove.

## Version boundaries

For minimum-version claims:

- identify the first supported/tested version;
- test at or near the lower bound when feasible;
- separately test a current version;
- do not infer the lower bound from a higher-version pass;
- account for vendor end-of-support where relevant.

For moving hosted images:

- record the observed runtime/tool versions;
- treat the alias as a selection mechanism, not a permanent environment identity.

## Failure classification

Compatibility failures can come from:

- unsupported API/runtime feature;
- OS/filesystem/path semantics;
- shell differences;
- case sensitivity;
- line endings/encoding;
- architecture-specific behavior;
- missing runtime integration/discovery convention;
- packaging/frontmatter/index format mismatch;
- test harness or runner configuration.

Classify the failure before changing support claims.

## Evidence preference

Strong evidence:
- exact CI/manual run identifier;
- environment/runtime versions;
- deterministic compatibility fixture;
- explicit unsupported/adaptation fixture;
- vendor lifecycle/support documentation;
- exact command and result;
- matrix row with claim limits.

Weak evidence:
- "Markdown is portable";
- "it should work on Linux/macOS";
- one successful run on a different runtime;
- a vendor supports the runtime but this repository never executed there;
- a `latest` label with no observed version.

## Completion rule

A compatibility task is complete only when a reviewer can answer:

1. Which environment and compatibility dimension are being claimed?
2. What exact evidence supports that cell?
3. What versions/runner identity were observed?
4. Which environments remain NOT_RUN?
5. Which environments require adaptation?
6. What could invalidate the claim later?

## Limitations

This skill does not prove:

- API/provider-consumer compatibility;
- safe dependency upgrades;
- application correctness beyond executed compatibility checks;
- production deployment or rollback safety;
- future compatibility with moving hosted images;
- support for unknown third-party runtime conventions.

Compatibility evidence is time- and environment-bounded.

## Red flags

Stop and reconsider if:

- "works on my machine" becomes a support statement;
- format compatibility is used as execution evidence;
- Windows + Ubuntu CI is reported as macOS support;
- a vendor-supported runtime is called repository-tested without execution;
- `latest` is treated as a fixed OS/runtime version;
- a runtime-loading claim is made without launching that runtime;
- adaptation requirements are hidden behind vague "portable" language.

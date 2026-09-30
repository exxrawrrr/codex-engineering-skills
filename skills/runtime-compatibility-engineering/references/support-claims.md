# Compatibility support claims

Use claim terms that reveal what was actually proven.

## Suggested vocabulary

- `TESTED` — the named executable workflow passed in the named environment.
- `NOT_RUN` — no execution evidence is recorded.
- `COMPATIBLE_BY_FORMAT` — the representation is structurally compatible.
- `COMPATIBLE_BY_DESIGN` — the architecture can be represented conceptually.
- `LIKELY_COMPATIBLE` — structural similarity exists, but execution is missing.
- `ADAPTATION_REQUIRED` — packaging/frontmatter/index/runtime convention differs.
- `NOT_APPLICABLE` — the dimension is not meaningful for this environment.
- `VENDOR_SUPPORTED` — authoritative vendor support exists; repository execution is a separate question.

Avoid a single `SUPPORTED` label when multiple dimensions matter.

## Evidence hierarchy

For executable support:

1. successful execution in the exact environment;
2. successful execution in a materially equivalent environment with limitations stated;
3. authoritative vendor/platform requirements;
4. design/format reasoning;
5. intuition.

Only the first layers justify a tested-execution claim.

## Support claim template

```text
environment:
  <os/runtime/toolchain/architecture>

dimension:
  <format | design | tested_execution | runtime_loading | vendor_support>

status:
  <bounded vocabulary>

evidence:
  <run id, command, vendor doc, fixture>

observed versions:
  <runtime/tool/runner versions>

claim limit:
  <what this does not prove>

reviewed_on:
  <date>
```

## Vendor support vs repository support

A vendor may support:
- an OS version;
- an architecture;
- a runtime version.

That does not prove your code works there.

Likewise, your code may work on an environment the vendor no longer supports. That is observation, not a safe long-term support policy.

Record both dimensions separately when lifecycle matters.

## Negative evidence

A failed run can justify narrowing a claim when:
- the failure is reproducible;
- the environment is correctly identified;
- the failure is compatibility-related rather than harness-related.

Do not drop support after a single ambiguous runner outage.

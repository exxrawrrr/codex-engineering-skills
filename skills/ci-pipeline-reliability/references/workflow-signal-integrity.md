# Workflow signal integrity

CI reliability starts with reachability and failure semantics, not with YAML formatting.

## Trigger reachability

Review:
- events;
- branch/tag filters;
- path filters;
- manual/reusable workflow inputs;
- fork/trust behavior.

For every required validation, identify at least one event path that must exercise it.

A required check that never triggers is not "passing".

## Permissions

Treat workflow/job permissions as an explicit contract.

Prefer the minimum required token access.

Review especially:
- write scopes;
- pull-request/fork events;
- OIDC/id-token permissions;
- deployments/packages/pages permissions;
- whether a reusable workflow receives inherited secrets.

Permission failure and application-test failure are different outcomes. Preserve that distinction in diagnostics.

## Matrix expansion

Write the expected legs down before changing matrix YAML.

Review:
- base dimensions;
- `include`;
- `exclude`;
- experimental/allowed-failure dimensions;
- max-parallel/cost limits;
- runner labels.

Do not trust a visual glance at nested include/exclude rules. Compare the intended set with the generated set when correctness matters.

## fail-fast vs continue-on-error

`fail-fast` controls cancellation of other matrix jobs.

`continue-on-error` controls whether a failing job/step is allowed to remain non-fatal.

They solve different problems.

If independent evidence from all required OS/runtime legs matters, fail-fast cancellation may be undesirable.

A required validation leg should not use continue-on-error unless the contract explicitly classifies it as non-blocking.

## Conditional execution

Review `if:` on:
- jobs;
- required validation steps;
- artifact upload;
- cleanup/diagnostics.

A condition can convert "failed" into "never executed".

If a required gate may skip, define:
- why;
- how the skip is surfaced;
- whether the overall validation should still be considered complete.

## Shell/runtime assumptions

Record when material:
- runner image/OS;
- shell;
- language/runtime version;
- package manager;
- architecture;
- service/container versions.

Use explicit setup when the repository requires a narrower runtime contract than the hosted image default.

## External actions

Third-party actions are executable dependencies.

Follow repository policy for version pinning/review and keep permissions bounded.

This skill does not own supply-chain policy, but it should surface when an unreviewed action version makes CI behavior non-reproducible.

# Comparative execution

Skill evaluation is vulnerable to false attribution.

## Treatment discipline

For a clean comparison, keep these stable when practical:

- model/runtime configuration;
- repository/fixture state;
- task wording;
- available tools;
- acceptance criteria;
- execution budget.

Change only the skill/router treatment being evaluated.

If a material variable changes, record it as a limitation rather than pretending the runs are directly comparable.

## Variant patterns

### No-skill baseline

Use when testing a causal claim that skill guidance improves outcomes.

### Selected skill set

Use the minimum skill set recommended by the routing contract.

### Over-loaded set

Use when measuring context/routing cost or interference.

Do not deliberately sabotage an over-loaded run with contradictory instructions merely to manufacture a win.

## Non-determinism

One agent run is evidence of one run.

When variance matters:
- repeat bounded cases;
- preserve individual results;
- report the sample size;
- avoid false statistical precision from tiny samples.

Do not average away a safety regression.

## Execution failures

Distinguish:
- task failure;
- infrastructure/runtime failure;
- evaluation harness failure;
- NOT_RUN.

A broken runner does not mean a skill failed.

## Cost metrics

Record only metrics you can actually observe:

- loaded entrypoint/reference bytes;
- input/output tokens;
- tool calls;
- elapsed time;
- iteration count.

If a metric is unavailable, use `NOT_AVAILABLE`.

Never estimate an unavailable metric and store it as measured evidence.

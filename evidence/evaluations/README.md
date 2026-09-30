# Behavioral evaluation harness

This harness separates **case contracts**, **fixed fixtures**, and **agent executions**.

It is intentionally small. It validates whether evaluation records are internally reviewable; it does not invoke a model and it does not turn a passing task into an effectiveness claim by itself.

## Case contract

`cases.json` schema version `2` defines:

- a bounded task;
- a stable `fixture_id`;
- allowed treatment variants;
- recommended repository skills;
- named deterministic acceptance criteria.

Each case must reference one fixture in `fixtures.json`.

Recommended skills must exist in the repository registry, case IDs and criterion IDs must be unique, and empty/unknown fixture references are rejected.

## Fixture contract

`fixtures.json` schema version `1` freezes the bounded input state for each case:

- fixture ID and owning case;
- short description;
- non-empty `initial_state`;
- explicit constraints.

The fixture is a compact scenario contract, not a hidden private transcript. If the scenario changes materially, create a new fixture/version rather than silently changing what an old result means.

## Treatment variants

Behavioral result files use only these treatment names:

- `no_skills` — no repository skills loaded;
- `selected_skills` — exactly the case's `recommended_skills`;
- `all_generic_skills` — exactly all registry entries whose `kind` is `generic`.

For `COMPLETED` results, `skills_loaded` must match the treatment exactly. This prevents a result from being labeled as one treatment while actually running another.

Cases may allow only the subset of variants relevant to the claim.

## Result contract

Result files use schema version `2`.

Every result contains:

- `case_id`;
- `variant`;
- `execution_status`: `COMPLETED` or `NOT_RUN`;
- `skills_loaded`;
- `criteria`;
- `evidence`;
- optional notes.

A `case_id + variant` pair may appear only once across the result directory.

### NOT_RUN

`NOT_RUN` is a first-class state and makes **no behavioral or effectiveness claim**.

A `NOT_RUN` result must have:

- empty `skills_loaded`;
- empty `criteria`;
- empty `evidence`;
- no execution provenance object;
- non-empty explanatory `notes`.

This prevents placeholder records from carrying evidence-looking data.

### COMPLETED

A completed result requires an `execution` object with:

- `run_id`;
- parseable ISO-8601 `executed_at`;
- `runtime`;
- `model`;
- `repository`;
- `repository_ref`.

When a runtime does not expose a field such as the exact model name, record an explicit value such as `NOT_AVAILABLE`; do not guess.

For each required acceptance criterion:

- `criteria.<id>` must be a boolean;
- `evidence.<id>` must be a non-empty reviewable evidence string;
- criteria/evidence keys must match the case criteria exactly.

The scorer prints:

- `PASS` when every required criterion is true and evidenced;
- `FAIL` when at least one required criterion is false;
- `NOT RUN` when the execution did not occur.

A criterion failure is an evaluation outcome, **not a schema failure**. Missing/malformed evidence is a schema failure.

## Claim boundary

A `PASS` means only:

> this execution satisfied this case's acceptance criteria.

It does **not** mean:

- the loaded skill caused the result;
- the selected variant beat a baseline;
- the skill is universally effective;
- the skill deserves `benchmarked` evidence tier.

Causal or comparative claims require matched comparative executions and must obey the repository evidence model. In particular, a registry `benchmarked` tier requires comparative evidence explicitly supporting that skill.

## Run

~~~powershell
./tests/evaluation-harness.ps1
./tests/evaluation-harness-contract.ps1
~~~

Phase 05 keeps the three seed executions as `NOT_RUN`. The harness proves the format and scorer contract without fabricating an agent run.

Raw private agent transcripts are not required. Prefer compact evidence such as public commit references, exact validation commands/results, or sanitized artifacts. The harness validates structure and treatment identity; a human reviewer still decides whether a supplied evidence string is substantively credible.

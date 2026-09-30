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

Files under `evidence/evaluations/results/` must declare an `evaluation_type`.

- `behavioral_execution` — processed by the Phase 05 behavioral harness and uses result schema version `2`;
- `context_cost` — a non-behavioral measurement artifact owned by the context benchmark and intentionally skipped by the behavioral scorer.

Unknown or missing result document types fail closed. This keeps different evidence families in one reviewable directory without letting one masquerade as another.

Behavioral result files use schema version `2`.

Every result contains:

- `case_id`;
- `variant`;
- `execution_status`: `COMPLETED` or `NOT_RUN`;
- `skills_loaded`;
- `criteria`;
- `evidence`;
- optional notes.

A `case_id + variant` pair may appear only once across the result directory. Every defined case must have at least one result record, even when that result is `NOT_RUN`; deleting a case's evidence row must not silently shrink evaluation coverage.

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


## Context efficiency benchmark

The current deterministic context-cost artifact is `context-current.json`.

It compares the same three treatment names used by the behavioral harness:

- `no_skills`: zero repository skill entrypoint bytes;
- `selected_skills`: exactly the case `recommended_skills`;
- `all_generic_skills`: every registry skill whose `kind` is `generic`.

Project-specific routers such as `growthops-engineering` are intentionally excluded from the `all_generic_skills` denominator. This makes the denominator match the treatment name and prevents a project router from inflating generic context cost.

The measurement is deliberately narrow: canonical UTF-8 bytes of `SKILL.md` entrypoints only, after CRLF/CR line endings are normalized to LF. This avoids Windows-versus-Linux checkout differences changing the benchmark. Conditionally loaded references are excluded. Byte counts are recomputed from the repository on every CI run and compared with `context-current.json`; stale stored numbers fail CI.

The original `context-baseline-2026-09-30.json` and `results/phase06-context-variants.json` are preserved as historical Phase 06 evidence. Their original `all skills` treatment included every registered skill at that time, including the project-specific GrowthOps router, so they are **not** the current generic-only contract and must not be used as the current denominator. The current artifact supersedes that treatment definition without rewriting the historical measurements.

Runtime metrics remain intentionally explicit:

- `input_tokens: NOT_AVAILABLE`;
- `tool_calls: NOT_RUN`;
- `elapsed_ms: NOT_RUN`;
- `behavioral_quality: NOT_RUN`.

Do not infer token, latency, tool-call, or behavioral savings from byte-size differences.

Run:

~~~powershell
./tests/context-benchmark.ps1
./tests/context-benchmark-contract.ps1
~~~


## Router selection evaluation

The router corpus is a **static contract evaluation**, not a runtime-agent execution.

`router-cases.json` schema version `2` defines each routing case with:

- a bounded task description;
- explicit `scope: generic | unrelated | project`;
- `selection_mode: exact_required`;
- registered `required`, `allowed`, and `forbidden` skill sets;
- `max_selected`.

For the current corpus, `exact_required` means the documented selection must equal the required skill set exactly. Merely staying inside an allowed superset is not enough. This makes “minimal relevant skills” machine-checkable rather than subjective.

Scope rules are explicit:

- generic cases may require/allow only generic repository skills and must explicitly forbid every registered project skill;
- unrelated cases require and allow zero skills and forbid every registered skill;
- project cases must require at least one project skill.

`router-results-current.json` schema version `2` stores **documented selections**, not observed agent runs. It therefore requires:

- `evaluation_type: documented_router_contract`;
- `runtime_obedience: NOT_RUN`;
- a non-empty `claim_limit`;
- no runtime/model/execution provenance fields.

A passing router contract proves only that repository routing expectations are internally consistent with the case corpus. It does not prove that a model or runtime will obey those instructions.

Run:

~~~powershell
./tests/router-evaluation.ps1
./tests/router-evaluation-contract.ps1
~~~

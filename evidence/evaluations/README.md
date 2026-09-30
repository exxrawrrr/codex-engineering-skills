# Behavioral evaluation harness

This harness separates **case contracts** from **agent executions**.

## Case contract

`cases.json` defines:

- a bounded task;
- recommended repository skills;
- named acceptance criteria.

The case file does not score prose style or architectural elegance.

## Result contract

A result record contains:

- `case_id`;
- `variant`;
- `execution_status`: `COMPLETED` or `NOT_RUN`;
- `skills_loaded`;
- one boolean per required criterion;
- one non-empty evidence string per required criterion.

The scorer computes PASS/FAIL from the criteria. A completed result cannot pass without criterion-level evidence.

`NOT_RUN` is a first-class state and makes no effectiveness claim.

## Run

~~~powershell
.\tests\evaluation-harness.ps1
~~~

Phase 05 validates the format and three initial case contracts. Comparative no-skill/selected/all-skills executions are added in later phases.

Raw private agent transcripts are not required. Prefer compact evidence such as public commit references, validation commands/results, or sanitized artifacts.

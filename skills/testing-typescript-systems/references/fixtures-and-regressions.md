# Fixtures and regression corpus

## Fixture principle

A fixture represents a known world the system must handle.

For website/crawler systems, keep small deterministic fixture sites such as:

```
healthy-site
broken-links-site
redirect-loop-site
missing-metadata-site
canonical-errors-site
robots-blocked-site
schema-errors-site
huge-site
slow-site
malicious-site
js-heavy-site
```

Serve them locally in tests rather than relying on internet availability.

## Fixture design

Each fixture should have:
- one clear purpose;
- minimal files needed to reproduce behavior;
- documented expected outcomes;
- stable URLs/content;
- no real credentials or private data.

Do not create one giant "everything broken" site as the only fixture.

## Regression rule

Every meaningful production bug should result in one of:
- a new fixture;
- a new test case against an existing fixture;
- a new migration/state fixture;
- a new failure-injection scenario.

Name the test around the bug behavior, not ticket folklore.

## Golden outputs

Golden/snapshot files are acceptable for stable artifacts such as:
- report schemas;
- normalized export structures;
- migration result manifests.

Keep them small and reviewable.

Avoid giant HTML snapshots where a few semantic assertions would be clearer.

## Versioning

Treat fixtures as source code:
- commit them;
- review changes;
- avoid hidden generated state;
- document why a fixture exists.

If a fixture changes expected behavior, update the related contract/test deliberately.

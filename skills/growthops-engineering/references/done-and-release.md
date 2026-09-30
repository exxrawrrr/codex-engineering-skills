# Definition of Done and release gates

## Feature Definition of Done

A feature is not complete because UI exists.

Where applicable, Done means:

- implementation exists;
- unit tests exist;
- integration tests exist;
- edge/error cases are covered;
- evidence behavior is correct;
- finding behavior is correct;
- report behavior is correct;
- UI behavior is correct;
- error handling exists;
- documentation is updated;
- verification evidence has been produced.

Apply only relevant rows, but do not silently omit a relevant layer.

## Bug Definition of Done

A bug fix should include:
- reproducible root cause;
- regression test or fixture;
- minimal fix;
- affected tests pass;
- broader regression verification when warranted.

Use systematic-debugging for investigation.

## Fixture corpus

Expected V0.1 fixture categories include:

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

Every meaningful bug should strengthen this corpus.

## V0.1 release gates

Do not call V0.1 releasable until critical gates pass:

1. clean install succeeds;
2. project creation succeeds;
3. public website scan succeeds;
4. scan pause/fail/restart does not lose completed data;
5. broken URLs do not destroy the scan;
6. findings have evidence;
7. reports open successfully;
8. action + verification work;
9. AI failure does not break core;
10. browser failure does not break core;
11. malicious HTML cannot execute script in reports/UI;
12. secrets do not appear in logs;
13. fixture suite passes;
14. onboarding E2E passes;
15. fresh-machine test passes.

If a critical gate fails, release status is NOT READY.

## Test reporting

Use explicit statuses:

```
PASS
FAIL
NOT CONFIGURED
NOT RUN
```

Do not infer success from absence of observed errors.

# E2E and release gates

## E2E purpose

E2E tests prove critical user workflows across assembled components.

They are not the place to exhaustively test every parser edge case.

## Core local-audit product flow

A minimal E2E suite for a local audit product may prove:

1. clean startup;
2. create/open project;
3. scan local fixture website;
4. progress reaches terminal state;
5. findings link to evidence;
6. report opens/exports;
7. action can be created;
8. targeted verification updates result/history.

## Failure-path E2E

Add targeted scenarios for release-critical invariants:

- app restart during scan then resume;
- broken URLs do not crash scan;
- browser subsystem unavailable;
- AI subsystem unavailable;
- malicious fixture cannot execute report script;
- no secrets appear in generated logs/artifacts.

## Playwright

Use Playwright for actual browser/UI behavior:
- navigation;
- forms;
- progress display;
- finding detail;
- report download/open flow.

Do not use Playwright as the crawler's general integration-test engine when HTTP/server fixtures can prove behavior faster.

## Release gates

Translate product release requirements into executable checks where possible.

A gate should have:
- exact command;
- expected result;
- blocking/non-blocking status;
- evidence/artifact when useful.

Do not mark a gate passed because a developer manually "looked at it once."

## Fresh-machine test

Fresh-machine/install tests are distinct from unit tests.

They should verify:
- documented prerequisites;
- dependency install;
- build/start;
- database initialization;
- basic workflow.

Automate as much as practical in CI or disposable environments, but do not introduce heavy container infrastructure solely for appearance.

## Test status reporting

For completion/release reports, state each relevant category as:

```
PASS
FAIL
NOT CONFIGURED
NOT RUN
```

Never imply tests ran if they did not.

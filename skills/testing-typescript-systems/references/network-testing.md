# Network testing

Public internet calls make core tests slow and flaky.

Use deterministic request interception/server fixtures.

## MSW or equivalent

For TypeScript/Node HTTP clients, MSW is a strong option for request-level tests because it models actual HTTP request/response behavior without monkey-patching business functions.

Use the project's approved tool if different.

Mock:
- remote server responses;
- delays/timeouts;
- connection failures;
- redirects;
- headers such as Retry-After;
- malformed responses.

Do not mock:
- URL normalization under test;
- retry classifier under test;
- persistence behavior when testing crawler integration.

## Important crawler scenarios

Test:
- 200 success;
- redirects;
- redirect loop;
- 404 non-retryable behavior;
- 408/429/502/503/504 retry policy as specified;
- valid Retry-After;
- timeout;
- truncated/oversized body;
- wrong content type;
- robots.txt responses;
- sitemap index + nested sitemap;
- malformed HTML/XML;
- connection reset.

## Timing

Use fake timers or injected clock/scheduler abstractions for backoff.

A test should not wait real seconds/minutes merely to prove retry scheduling.

Assert scheduled next-attempt timestamps/delays.

## Request evidence

Where required, assert:
- attempt count;
- final status;
- redirect chain;
- timeout/error category;
- next retry time;
- persisted evidence.

## Optional live smoke tests

Live-network tests may exist separately for compatibility checks, but:
- mark them non-deterministic;
- do not make core CI correctness depend on third-party availability;
- use explicit opt-in/environment flag.

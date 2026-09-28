---
name: resilient-crawler-engineering
description: "Design, implement, or review resilient website crawlers for local-first TypeScript applications: crawl frontier, URL lifecycle, bounded concurrency, rate limiting, retries/backoff, robots/sitemaps, normalization/deduplication, per-URL state, partial failure, checkpoints, resume, and browser fallback. Use for crawler, scan engine, URL queue, fetch policy, or crawl reliability work."
---

# Resilient Crawler Engineering

Use this skill for crawler/scan-engine work where reliability matters more than raw throughput.

## Load references selectively

Read only what the task needs:

- URL lifecycle, queue/frontier, normalization, deduplication:
  `references/frontier-and-url-lifecycle.md`
- Fetch limits, concurrency, rate limiting, retries, 429 behavior:
  `references/fetch-reliability.md`
- robots.txt, sitemap discovery, browser fallback:
  `references/discovery-and-rendering.md`
- checkpoint/resume, partial failure, progress accounting:
  `references/resume-and-recovery.md`

For SSRF/private-network protection, also use the security skill if installed.

## Core principles

1. Crawl state is durable product state, not an in-memory loop.
2. Every URL has an explicit lifecycle.
3. One URL failure must not fail the entire scan.
4. Concurrency is always bounded.
5. Rate limits and server signals must be respected.
6. Retries are bounded, classified, and delayed.
7. URL normalization happens before deduplication.
8. robots.txt is respected by default.
9. Static HTTP fetch is the default; browser rendering is targeted fallback.
10. Completed evidence is persisted incrementally so a restart does not erase progress.
11. Coverage and failures are reported honestly.
12. The crawler must have hard limits for pages, depth, redirects, time, and body size.

## Canonical URL lifecycle

Prefer explicit states such as:

```
discovered
normalized
queued
fetching
completed
failed
skipped
robots_blocked
```

A persisted implementation may use more detailed states, but transitions must stay observable and recoverable.

## Default architecture

```
seed/discovery
    ↓
normalize + scope filter
    ↓
deduplicate
    ↓
durable frontier / queue
    ↓
bounded scheduler
    ↓
fetch
    ↓
classify response/failure
    ↓
persist evidence + discovered links
    ↓
complete / retry / fail / skip
```

Keep crawling, parsing, rule evaluation, and reporting as separate concerns.

## Required crawl controls

A production-oriented crawl configuration should explicitly support:

- max pages;
- max depth;
- request timeout;
- max redirects;
- max response/body size;
- content-type allow/deny behavior;
- concurrency limit;
- per-host/request delay;
- bounded retry count;
- robots policy;
- same-origin/subdomain policy;
- query-parameter policy;
- optional sitemap seeding;
- clear user agent.

Do not use unlimited defaults silently.

## Browser rule

Do not send every URL through Playwright.

Default:

```
HTTP fetch
→ HTML parse
→ deterministic checks
```

Use browser rendering only for:
- explicitly selected URLs;
- representative samples;
- JS-dependent/problem pages;
- targeted verification.

A browser subsystem failure must not invalidate a successful static crawl.

## Completion rule

A scan may complete with failed URLs.

Report separately:
- discovered;
- completed;
- failed;
- skipped;
- robots-blocked;
- remaining/queued;
- coverage percentage where meaningful.

Do not claim 100% coverage when some URLs were unavailable.

## Workflow

Before coding:
1. Read crawl/product/security specs.
2. Identify durable URL/job state.
3. Define normalization and scope rules.
4. Define retryable vs non-retryable failures.
5. Define hard crawl limits.
6. Define recovery behavior after process termination.

After coding:
1. test URL normalization/deduplication;
2. test timeout/retry/backoff;
3. test 429/Retry-After behavior;
4. test redirect loops and size limits;
5. test robots/sitemap handling;
6. test partial failure;
7. test restart/resume from persisted state;
8. run verification loop.

## Red flags

Stop and reconsider if:
- crawl is implemented as one `for ... fetch()` loop with no durable state;
- a single rejected promise aborts the scan;
- `Promise.all` is used over an unbounded URL set;
- retries happen immediately;
- all 4xx/5xx responses are retried blindly;
- 429 ignores `Retry-After`;
- normalization happens after dedupe;
- browser rendering is the default for every page;
- completed pages exist only in memory until the very end;
- queue state cannot be reconstructed after restart;
- page/depth/body/redirect limits are missing.

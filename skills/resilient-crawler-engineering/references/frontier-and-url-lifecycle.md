# Frontier and URL lifecycle

This reference adapts proven crawler patterns from queue-based crawlers and production SEO crawlers.

## Frontier ownership

The frontier/queue is responsible for:
- which URL should run next;
- whether a URL has already been seen;
- URL state;
- retry scheduling;
- priority/order if supported.

Do not make the fetcher secretly own queue policy.

For resumable crawls, the durable frontier/database is the source of truth.

## Normalize before dedupe

Normalize discovered URLs before checking uniqueness.

Typical normalization policy may include:
- resolve relative URLs against the source page;
- remove fragments;
- normalize hostname casing;
- normalize default ports;
- apply trailing-slash policy consistently;
- reject unsupported schemes;
- classify/remove known tracking/session parameters only when approved by product policy;
- preserve original observed URL separately when evidence requires it.

Do not over-normalize query parameters that may identify real pages.

## Scope

Scope rules must be explicit:
- exact origin by default;
- optional subdomain crawling;
- include/exclude patterns;
- maximum depth;
- same-origin redirects policy.

A discovered URL outside scope should become `skipped`, not silently disappear.

## Deduplication

Use the normalized crawl key for URL dedupe.

Content-level duplicate detection is separate from URL dedupe.

If body/content hashes are used, they must not replace URL identity because distinct URLs can legitimately serve identical content.

## Queue insertion

Prefer an idempotent "insert if unseen" operation.

Concurrent discovery must not create duplicate queue rows.

Persist:
- normalized URL;
- original/discovered URL where useful;
- source/referrer;
- depth;
- state;
- discovery timestamp;
- retry/attempt metadata when applicable.

## State transitions

Example:

```
discovered
  ↓
normalized
  ↓
queued
  ↓
fetching
  ├─→ completed
  ├─→ failed
  ├─→ skipped
  └─→ robots_blocked
```

If retry is scheduled:

```
fetching → queued(next_attempt_at)
```

Do not mark a URL complete before its required evidence is durably written.

# Fetch reliability

## Concurrency

Use a bounded worker pool or queue.

Have separate concepts for:
- global concurrency;
- per-host politeness/rate policy when multiple hosts are allowed.

Never create one promise per discovered page without a bound.

## Timeouts

Every request has a timeout.

Timeout is a classified failure, not a hung worker.

Cancellation should propagate through request handling so shutdown/pause does not wait indefinitely.

## Redirects

Follow redirects only up to a hard maximum.

Track the redirect chain when useful for evidence.

Revalidate scope and security policy on every redirect target.

Detect redirect loops explicitly.

## Body limits

Enforce maximum response bytes.

Reject/stop oversized responses before loading unlimited content into memory.

Validate content type before expensive parsing/rendering.

## Retry classification

Retry only failures that may reasonably be transient.

Common retry candidates:
- network timeout/reset;
- temporary DNS/network errors where policy permits;
- HTTP 408;
- HTTP 429;
- HTTP 502/503/504.

Usually do not retry indefinitely:
- most 4xx client errors;
- robots-blocked URLs;
- invalid/unsupported URLs;
- deterministic parse/input validation errors.

Project rules may refine this classification.

## Backoff

Use bounded exponential backoff with jitter.

Example conceptual schedule:

```
baseDelay * 2^attempt + jitter
```

Always cap:
- retry count;
- maximum delay.

Do not create synchronized retry storms.

## 429 and Retry-After

For HTTP 429:
1. read `Retry-After` if valid;
2. slow or pause the affected host;
3. reschedule rather than hot-loop;
4. keep other independent work running if safe.

Repeated 429/503 is evidence that current crawl pressure is too high.

Adaptive slowdown is preferable to "fight the server."

## Response accounting

Persist response outcome even when parsing fails.

Useful evidence:
- status code;
- final URL;
- redirect chain;
- duration;
- response bytes;
- content type;
- safe error classification;
- attempt count.

Network/request errors are evidence too.

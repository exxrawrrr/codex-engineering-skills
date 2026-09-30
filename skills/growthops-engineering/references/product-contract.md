# Product contract

## V0.1 included

V0.1 Website Intelligence Core may include:

- local project create/open/delete;
- internal-page crawl/discovery;
- HTTP status/redirect/error analysis;
- metadata;
- headings;
- canonical validation;
- internal/external/broken links;
- image alt/basic validation;
- robots.txt;
- sitemap discovery/validation;
- structured-data detection/basic validation;
- indexability checks;
- deterministic findings;
- evidence linked to findings;
- deterministic priority;
- manual action tracking;
- targeted verification;
- JSON/Markdown/HTML reports;
- local web UI;
- minimal CLI.

Optional experimental AI explanation is non-blocking and should come only after deterministic core stability.

## Explicitly out of V0.1

Do not add:

- GA4;
- Google Search Console;
- Google Ads;
- Meta Ads;
- WordPress write;
- automatic content generation;
- social scheduling;
- n8n;
- MCP server;
- multi-agent;
- plugin marketplace;
- team accounts;
- cloud sync;
- billing;
- CRM;
- keyword/backlink database;
- full Lighthouse replacement;
- desktop executable packaging as a release blocker.

## Product shape

Human-facing shape:

```
GrowthOps
├── Web App
├── CLI
└── Local API
```

The local API is an internal/integration boundary, not permission to build remote/cloud platform behavior.

## Reliability contract

- per-URL state is explicit;
- completed work persists incrementally;
- scans are resumable;
- one URL failure does not destroy a scan;
- failures become visible evidence;
- hard crawl limits exist;
- browser rendering is targeted fallback;
- reports remain usable without GrowthOps running.

## Deterministic-first

If a fact can be parsed, calculated, validated, or compared deterministically, do that first.

AI may explain structured evidence later, but AI must not become the authoritative source for deterministic findings.

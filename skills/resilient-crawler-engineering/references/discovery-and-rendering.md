# Discovery, robots, sitemaps, and rendering

## robots.txt

Respect robots.txt by default.

Cache robots rules per host for an appropriate duration during a scan.

Evaluate rules using the crawler's actual user agent/policy.

Record robots denial explicitly as a crawl outcome.

A robots fetch failure must have an explicit policy; do not silently interpret every failure as allow or deny without specification.

## Sitemap discovery

Use sitemap URLs from:
- `Sitemap:` directives in robots.txt;
- conventional sitemap locations when product policy allows;
- sitemap indexes and nested sitemaps.

Feed discovered sitemap URLs through the same normalization, scope, and dedupe pipeline as link-discovered URLs.

Sitemap presence does not guarantee indexability or successful fetch.

## Link discovery

Extract links only from supported content types.

Resolve relative links against the final/base URL correctly.

Do not enqueue:
- fragments;
- unsupported protocols such as mailto/tel/javascript;
- out-of-scope URLs unless explicitly configured.

## Static-first rendering

HTTP + parser is the primary crawler path.

Browser rendering is expensive:
- more CPU/memory;
- additional requests;
- different cache/load behavior;
- larger failure surface.

Use Playwright/browser rendering as a verifier/fallback.

## Browser trigger examples

Browser rendering may be justified when:
- raw HTML lacks meaningful content but rendered DOM has it;
- user explicitly requests deep browser verification;
- a page is known to require client-side rendering;
- checking console/resource/render behavior.

Persist static and rendered observations separately when comparing them.

Do not let rendered DOM overwrite raw-source evidence.

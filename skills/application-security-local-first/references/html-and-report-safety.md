# HTML and report safety

Primary reference model: OWASP XSS Prevention guidance.

## Treat fetched HTML as hostile

Never execute scripts from crawled HTML as part of report generation.

Parsing a document does not make its strings safe to render.

Dangerous values include:
- page title;
- meta description;
- headings;
- URLs;
- anchor text;
- JSON-LD strings;
- error messages copied from remote content.

## Prefer escaped text

Use framework/template output escaping by default.

In client-side DOM code prefer safe text sinks such as `textContent`.

Do not use:
- `innerHTML`;
- `outerHTML`;
- `document.write`;
- framework raw-HTML escape hatches

for crawler-derived values unless a reviewed sanitization requirement exists.

## Context-aware encoding

Encoding depends on output context.

HTML body, HTML attribute, URL parameter, JavaScript, and CSS contexts are not interchangeable.

Do not solve all XSS with one generic `escape()` helper.

Avoid placing untrusted values directly into executable JavaScript or CSS contexts.

## HTML sanitization

If the product intentionally displays a subset of untrusted HTML:
- use a maintained sanitizer such as DOMPurify or an equivalent appropriate to the runtime;
- use an explicit allowlist policy;
- sanitize as close as possible to final rendering;
- do not mutate the sanitized result afterward in ways that can reintroduce unsafe markup;
- keep the sanitizer updated.

Prefer rendering extracted plain text/structured data over rendering remote HTML.

## URLs in reports

Validate URL schemes before placing crawler-derived links into clickable `href`/`src`.

Do not permit `javascript:` or other executable schemes.

Apply URL validation plus the output encoding appropriate for the HTML attribute context.

## Offline reports

An HTML report opened from disk is still an HTML execution environment.

Offline does not mean safe.

Generated reports should avoid:
- inline executable remote content;
- raw copied script/style blocks;
- untrusted event handler attributes;
- unsafe external-resource injection.

Consider a restrictive CSP as defense in depth, not a replacement for encoding/sanitization.

## Tests

Test report output with payload-like data in:
- title;
- description;
- heading;
- URL;
- anchor text;
- JSON-LD value;
- error message.

Verify it renders as inert data rather than executable markup.

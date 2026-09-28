---
name: application-security-local-first
description: "Design, implement, or review security boundaries for local-first TypeScript applications that process untrusted websites/files: SSRF and DNS rebinding defenses, redirect validation, private-network controls, malicious HTML/report XSS prevention, path/file safety, secret handling, least privilege, and prompt-injection isolation. Use for crawler/network code, reports, local file writes, AI analysis of fetched content, connectors, or security reviews."
---

# Application Security for Local-First Systems

Use this skill when local-first software processes untrusted network, HTML, file, or model input.

## Load references selectively

- Outbound requests, SSRF, DNS resolution, redirects, private network:
  `references/ssrf-and-network.md`
- HTML/report rendering and XSS:
  `references/html-and-report-safety.md`
- Filesystem paths, filenames, local storage boundaries:
  `references/path-and-file-safety.md`
- Secrets/logging and least privilege:
  `references/secrets-and-privilege.md`
- AI analysis of fetched content and prompt injection:
  `references/untrusted-ai-content.md`

## Core rules

1. Treat every fetched website as attacker-controlled input.
2. Treat every URL as unsafe until parsed, resolved, and policy-checked.
3. Public-web crawling must not become a localhost/private-network proxy.
4. Re-check security policy after every redirect.
5. Raw HTML is data, never trusted executable content.
6. Report generation must encode/sanitize untrusted values according to output context.
7. User-controlled names never become raw filesystem paths.
8. Logs must not contain secrets, credentials, auth headers, or sensitive raw payloads.
9. Optional AI sees external content as data, never as instructions.
10. Privileged or destructive actions require explicit authorization and narrow capability.
11. Security checks fail closed for privileged operations.
12. Never weaken security controls merely to make a failing test or difficult website work.

## Threat boundary

For a local website-audit application, assume hostile input can arrive through:

```
URL
DNS
redirects
HTTP headers
HTML
JavaScript
JSON-LD
XML/sitemap
filenames
report values
AI-selected page excerpts
connector responses
```

Each boundary must validate according to its own grammar and context.

## Default network posture

Public-site scanning should default to:
- http/https only;
- block loopback, link-local, private, multicast, unspecified, and other non-public destinations;
- inspect both IPv4 and IPv6;
- resolve hostnames and validate every resulting address;
- revalidate every redirect destination;
- explicit opt-in before local/private network scanning.

Do not implement network safety as a string check such as `hostname !== "localhost"`.

## Output safety

Prefer structured rendering where frameworks escape text automatically.

Avoid raw HTML sinks. If product requirements genuinely need untrusted HTML rendering, use a maintained sanitizer with a strict policy and keep sanitization as the final transformation before rendering.

Never insert crawler-derived values into:
- scripts;
- event handlers;
- raw CSS;
- unsafe URL schemes;
- `innerHTML` / equivalent unsafe sinks without sanitization.

## Filesystem safety

All writes must be contained under an approved application-owned directory.

Generate internal filenames/IDs rather than trusting remote filenames.

Resolve and verify final paths remain inside the intended root before writing.

Do not let:
- URL path;
- Content-Disposition filename;
- page title;
- project name;
- model-generated filename

directly determine filesystem location.

## AI boundary

If AI analyzes crawled content:

```
website content = untrusted data
system/developer/user instructions = trusted control plane
```

Do not concatenate raw HTML into privileged instructions.

Prefer structured findings/evidence subsets over entire HTML documents.

AI-generated recommendations are not authorization to execute changes.

## Workflow

Before implementing:
1. identify untrusted inputs;
2. identify privileged effects;
3. define trust boundaries;
4. define allow/deny policy;
5. define failure behavior;
6. add security tests for bypass classes.

After implementing:
1. test IPv4 + IPv6 private/loopback blocking;
2. test hostname resolving to private IP;
3. test redirect from public to private destination;
4. test oversized/malicious HTML;
5. test report XSS payloads;
6. test path traversal and malicious filenames;
7. scan changed files/logging for secret leakage;
8. test prompt-injection content cannot trigger privileged actions;
9. run verification loop.

## Red flags

Stop and reconsider if:
- URL security relies on regex alone;
- hostname validation occurs once but redirects are auto-followed;
- DNS is resolved for validation, then the HTTP client independently resolves again without protection;
- local-network crawling is enabled by default;
- fetched HTML is rendered with raw HTML APIs;
- report values are interpolated directly into HTML/JS;
- remote filenames are used directly for local writes;
- errors log Authorization headers, cookies, tokens, or API keys;
- crawled text can instruct an AI to call tools or mutate the project;
- a security exception is added just to support one problematic site.

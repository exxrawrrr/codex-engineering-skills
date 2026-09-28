# Secrets, logs, and privilege

## Secrets

Never persist secrets in:
- logs;
- crawl evidence;
- reports;
- URLs;
- exception strings;
- analytics events;
- fixtures committed to source control.

Examples:
- API keys;
- OAuth tokens;
- cookies;
- Authorization headers;
- passwords;
- session IDs;
- signed URLs when sensitive.

Development `.env` files may be acceptable for local development but are not the ideal final production secret design.

For future connectors, prefer OS credential/keychain storage or an encrypted secret store appropriate to the platform.

## Logging

Log identifiers and safe metadata, not secret values.

Good:

```
AI provider request failed: auth_error
credential_present=true
```

Bad:

```
Authorization: Bearer sk-...
```

Redact sensitive headers before debug serialization.

Remote response bodies can contain secrets or personal data. Do not dump entire bodies by default.

## Least privilege

Give each subsystem only the capabilities it needs.

Examples:
- crawler: network fetch + crawl-state persistence;
- report renderer: read audit data + write approved report directory;
- AI explanation: read selected structured evidence;
- future WordPress writer: separate explicit action capability.

Do not give an AI analysis component filesystem/network mutation authority merely because it can generate recommendations.

## Approval boundaries

High-risk actions require explicit human approval when introduced later.

Keep read/analyze and mutate/publish capabilities separate.

An error, prompt injection, or compromised remote page should not be able to cross that boundary.

## Failure behavior

When secret storage/provider auth fails:
- report the subsystem as unavailable;
- keep deterministic core functionality running when possible;
- never fall back to plaintext persistence silently.

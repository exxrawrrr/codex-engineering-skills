# API compatibility rules

Compatibility is directional. A change can be safe for one side and breaking for the other.

## Start with the message direction

For an HTTP interaction, reason about:

- **request**: consumer sends, provider accepts;
- **response**: provider sends, consumer accepts.

Then ask whether the change makes the sender produce something the receiver may no longer accept, or makes the receiver require something the sender did not previously provide.

## High-signal breaking-change candidates

Request-side candidates:
- adding a new required request field;
- narrowing an accepted type/range/pattern;
- removing an accepted enum value;
- making an optional header/query/path/body value required;
- removing or renaming an operation/path/method.

Response-side candidates:
- removing a response field that a known consumer requires;
- changing a field type incompatibly;
- removing an enum value a consumer handles or changing its meaning;
- removing a documented success status/media type;
- changing nullable/optional behavior in a way a consumer cannot parse.

These are review triggers, not universal verdicts. Compatibility depends on the contract semantics, serialization rules, and known consumers.

## Additive changes need context

"Added field" is not automatically safe.

It is often compatible for tolerant consumers, but can break:
- strict decoders;
- closed-schema validators;
- exhaustive enum/switch handling;
- signature/canonicalization logic;
- generated clients with restrictive settings.

If unknown-field tolerance is part of the compatibility claim, prove it for the relevant consumer/toolchain.

## Schema validity is not compatibility

A contract may be valid according to its schema and still be incompatible with the previous version.

Conversely, a version-to-version diff tool may flag a change that is acceptable for the actual consumer population.

Treat:
- syntax/schema validation;
- version diff;
- provider conformance;
- consumer-driven verification

as different evidence layers.

## OpenAPI-specific discipline

Record:
- OpenAPI Specification version understood by the tooling;
- contract document version/ref;
- diff/validation tool version;
- whether extensions or implementation-defined behavior matter.

The OpenAPI specification text is authoritative over convenience schemas when they disagree. Do not assume every tool interprets optional/nullable/composition semantics identically.

## Compatibility result

Prefer a result shaped like:

```text
contract: api/openapi.yaml @ <ref>
baseline: <previous ref/version>
provider: <ref/version>
known consumers: <names/versions or "not enumerated">

schema validation: PASS | FAIL | NOT_RUN
version diff: PASS | FAIL | NOT_RUN
provider verification: PASS | FAIL | NOT_RUN
consumer verification: PASS | FAIL | NOT_RUN

claim:
  <narrow compatibility statement>

limitations:
  <unknown consumers, semantic behavior, auth, deployment, etc.>
```

Do not collapse multiple NOT_RUN layers into one "compatible" adjective.

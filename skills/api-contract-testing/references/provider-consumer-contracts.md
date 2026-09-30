# Provider and consumer contract verification

A provider contract and a consumer-driven contract answer related but different questions.

## Provider conformance

Use provider conformance when a provider claims to implement a published machine-readable API description.

Evidence should identify:
- provider build/ref;
- contract ref;
- deterministic provider state/fixture;
- verification command;
- exact failed interaction/schema location when it fails.

This proves conformance only to the checked contract surface.

## Consumer-driven contracts

Consumer-driven contracts capture the subset of interactions a consumer relies on.

A useful workflow is:

1. consumer test records an expected request and minimum acceptable response;
2. the contract artifact is versioned/published;
3. provider verification replays the interaction against a controlled provider;
4. verification result is associated with provider and consumer versions;
5. deployment decisions, if any, use verified compatibility evidence rather than contract existence alone.

Keep interactions independent. Use explicit provider states instead of ordering one interaction after another.

## What to stub

During provider verification, stub dependencies **below** the boundary being verified.

Do not stub away:
- request parsing;
- validation;
- routing;
- response serialization;
- contract-relevant provider behavior.

Otherwise the verifier can pass without exercising the behavior the contract is meant to protect.

## Version identity

A contract result without version identity ages badly.

Capture when available:
- consumer name/version/ref;
- provider name/version/ref;
- contract digest/version;
- verification run ID;
- executed_at/runtime/tool version.

If version identity is unavailable, state that limitation rather than claiming deploy compatibility.

## Contract broker / registry

A broker or registry can coordinate:
- contract versions;
- provider verification results;
- consumer/provider relationships.

It is infrastructure, not proof by itself. The useful evidence is the verification result for the versions being compared.

## Failure interpretation

Distinguish:
- invalid contract artifact;
- incompatible version diff;
- provider verification mismatch;
- consumer test failure;
- environment/harness failure.

Do not treat an unavailable verifier as an API incompatibility, and do not treat a green schema parser as consumer compatibility.

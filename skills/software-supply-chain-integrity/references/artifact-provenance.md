# Artifact provenance and attestation verification

Provenance answers where/how an artifact was produced. Integrity answers whether the consumed bytes match the expected artifact identity.

## Subject-first verification

Start with the consumed artifact:
- compute/read its digest;
- identify the expected subject;
- verify evidence refers to that exact subject.

Do not begin from a provenance document and assume it belongs to the file you downloaded.

## Build provenance

Useful build provenance can include:
- source repository/revision;
- builder/workflow identity;
- invocation/build type;
- external parameters;
- dependency/material identities;
- timestamps/run identity;
- output subject digest.

The exact schema varies. Preserve the schema/version and verifier semantics.

## Attestations

An attestation is useful only when verified.

Verification normally needs:
- signed statement;
- trusted issuer/signer identity;
- subject digest match;
- expected source/repository;
- expected builder/workflow;
- expected policy constraints.

If any required dimension is unavailable, report it explicitly.

## GitHub artifact attestations

When using hosted artifact attestations, verify:
- repository/organization identity;
- workflow/builder identity;
- commit/ref/event as required;
- artifact digest.

Generating an attestation and verifying an attestation are distinct operations.

## SLSA-style provenance

Treat provenance as verifiable information about how an artifact/source revision came to exist.

Do not claim a SLSA level merely because a provenance file exists. A level/track claim has additional requirements.

## SBOM vs provenance

SBOM:
- inventory of components/materials.

Provenance:
- evidence about origin/build process.

Integrity:
- evidence about byte identity.

They complement each other and should not be used as synonyms.

## Verification record

A useful compact record:

```text
artifact:
  name: <name>
  digest: <algorithm:value>

source:
  repository: <repo>
  revision: <commit>

builder:
  identity: <workflow/builder>

attestation:
  format/version: <type>
  signer/issuer: <identity>
  verification: PASS | FAIL | NOT_RUN

policy:
  expected repository: <value>
  expected builder: <value>
  allowed event/environment: <value>

claim limit:
  <what this verification does not prove>
```

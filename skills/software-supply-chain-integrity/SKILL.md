---
name: software-supply-chain-integrity
description: "Design, review, or repair technical trust for software inputs and outputs: dependency/action/source provenance, immutable references, lockfile integrity, artifact digests, signed attestations, build provenance, and verification gates. Use when CI/build/release inputs may be mutable or unverified. Do not use for application authorization/SSRF/XSS, generic CI reliability, deployment rollout/rollback, vendor-risk governance, or legal/license advice."
---

# Software Supply Chain Integrity

Use this skill when the question is:

> Can we verify what software input or artifact this is, where it came from, and that the bytes/identity satisfy our trust policy?

This skill owns **technical integrity and provenance of software supply-chain inputs/outputs**.

## Load references selectively

- Dependency/action/source identity, pinning, lockfiles, and trust:
  `references/input-trust.md`
- Digests, attestations, build provenance, and artifact verification:
  `references/artifact-provenance.md`

## Neighboring skills

Use `application-security-local-first` for runtime/application security boundaries such as SSRF, XSS, filesystem safety, secrets, and prompt injection.

Use `ci-pipeline-reliability` to ensure supply-chain gates actually execute and fail visibly.

Use `runtime-compatibility-engineering` for host/runtime support claims.

This skill owns **what build/dependency/artifact identity must be trusted and how that trust is verified**.

## When to load

Load this skill when one or more are true:

- a CI workflow executes a third-party action/plugin by mutable tag/branch;
- dependencies are added from registries, git refs, tarballs, or custom sources;
- lockfile/resolution/integrity metadata changes;
- a build downloads external tools or artifacts;
- checksums/digests are used as integrity evidence;
- artifacts are signed or accompanied by attestations/provenance;
- build outputs must be traced to source/workflow/commit;
- an SBOM/provenance/attestation claim is being reviewed;
- CI needs a technical supply-chain verification gate.

## When not to load

Do not load this skill for:

- application authorization, SSRF, XSS, or user-input security;
- ordinary CI matrix/trigger/flaky-test reliability;
- production rollout, canary, promotion, or rollback;
- generic dependency version migration sequencing;
- vendor procurement/risk governance;
- license interpretation or legal advice;
- vulnerability remediation unless the task is specifically about provenance/integrity of the affected dependency or artifact.

## Core rules

1. Separate **identity**, **version selection**, **integrity**, **provenance**, and **policy approval**.
2. A human-friendly tag/version is not necessarily immutable.
3. Prefer immutable identifiers for critical executable build inputs when the ecosystem supports them.
4. Verify that an immutable identifier belongs to the intended upstream source, not merely that it exists.
5. A checksum verifies bytes only relative to the trusted checksum value.
6. A checksum downloaded from the same compromised mutable channel as the artifact may add little trust.
7. Lockfiles improve reproducibility/visibility; they do not automatically establish publisher trust or vulnerability safety.
8. Preserve lockfile integrity/resolution metadata and review unexpected source changes.
9. Generated SBOMs are inventories, not proof that artifacts were built from the declared inputs.
10. Provenance/attestations are claims; verify signatures/identity/policy before relying on them.
11. Record the subject digest when an attestation is used to authorize an artifact.
12. Build provenance should connect output artifact identity to source/ref, builder/workflow identity, and relevant invocation parameters.
13. Do not confuse source attribution/license provenance with cryptographic artifact integrity.
14. Pinning a dependency/action does not prove the pinned thing is safe; it controls mutability.
15. A signature without trusted signer identity/policy is incomplete evidence.
16. Verification keys/identity roots are part of the trust boundary.
17. Never replace a verification failure with "accept anyway" in a required gate without an explicit policy decision.
18. Preserve exact verification command/result and tool version where material.
19. Keep supply-chain verification deterministic and fail closed for required artifacts.
20. Do not claim application security, absence of vulnerabilities, or safe deployment from supply-chain integrity alone.

## Trust layers

For a critical input, answer these separately:

### Identity
What is it?
- package/repository/action/artifact name;
- source registry/repository;
- publisher/owner/build system identity.

### Selection
Which version/ref?
- semantic version;
- lockfile-resolved version;
- git commit;
- immutable artifact digest.

### Integrity
Are these the expected bytes?
- registry integrity metadata;
- checksum/digest;
- signature over content;
- verified artifact digest.

### Provenance
Where/how was it produced?
- source revision;
- builder/workflow identity;
- build parameters;
- triggering event;
- attestation/provenance statement.

### Policy
Do we accept it?
- allowed source/publisher;
- required pinning level;
- required attestation/signature;
- review/approval rules.

Do not collapse these layers into one "trusted" boolean without documenting what passed.

## Third-party CI actions/plugins

For executable third-party build inputs:

- determine whether the reference is mutable;
- prefer immutable pinning when required by policy;
- verify the immutable ref belongs to the expected upstream;
- use dependency-update tooling/processes to keep immutable pins maintainable;
- scope workflow permissions separately from action provenance.

A full commit pin controls ref mutability. It does not prove the upstream code is benign.

## Dependency and lockfile discipline

Review changes to:
- resolved source/registry;
- package version;
- integrity digest;
- git commit;
- install scripts;
- transitive tree.

A lockfile can make installs reproducible and expose integrity/resolution changes. It does not replace:
- source trust policy;
- vulnerability review;
- signature/provenance checks where required;
- regression testing.

## Artifact verification workflow

Before accepting an artifact:

1. identify expected artifact and source;
2. obtain expected digest/provenance through an independently trusted mechanism;
3. verify digest/signature/attestation;
4. verify signer/builder/workflow identity;
5. verify source/ref/commit and relevant build parameters;
6. enforce policy;
7. record subject digest + verification result.

If the artifact is transformed, repackaged, or mirrored, verify the identity chain through that transformation.

## Attestation workflow

When an attestation exists:

1. identify the artifact digest (subject);
2. verify attestation signature/issuer;
3. verify repository/source identity;
4. verify builder/workflow identity;
5. verify source commit/ref;
6. verify expected event/environment/policy constraints;
7. verify the attested digest matches the consumed artifact.

An attestation stored next to an artifact is not useful if no verification occurs.

## Failure classification

Supply-chain verification can fail because of:

- mutable/unapproved source;
- digest mismatch;
- signature verification failure;
- unexpected signer/issuer;
- unexpected repository/commit;
- missing provenance;
- unsupported attestation format;
- lockfile/source drift;
- unavailable trust root/verifier;
- policy mismatch.

Do not classify verifier infrastructure failure as "artifact malicious"; report the verification state accurately.

## Evidence preference

Strong evidence:
- immutable source/ref;
- resolved dependency identity;
- trusted integrity value;
- subject digest;
- successful signature/attestation verification;
- expected builder/repository/source identity;
- exact verification command and result;
- negative fixture proving mutable/unverified input is rejected.

Weak evidence:
- a tag/version name alone;
- "downloaded over HTTPS";
- checksum fetched from the exact same mutable location with no independent trust;
- an SBOM with no artifact identity verification;
- presence of an attestation file without verification;
- green CI where the integrity gate was skipped.

## Completion rule

A supply-chain integrity task is complete only when a reviewer can answer:

1. What input/artifact identity is trusted?
2. How is the version/ref selected?
3. What proves byte integrity?
4. What provenance/signature/attestation was verified?
5. Which signer/builder/source identities were required?
6. What policy made the result acceptable?
7. What remains outside the claim?

## Limitations

This skill does not prove:

- absence of vulnerabilities or malicious logic;
- application authorization/security correctness;
- legal/license compliance;
- vendor organizational trustworthiness;
- production rollout/rollback safety;
- that a trusted upstream will remain trustworthy forever.

Integrity/provenance evidence is only as strong as the identities, trust roots, verification policy, and artifact linkage that were actually checked.

## Red flags

Stop and reconsider if:

- a mutable branch/tag is treated as immutable;
- a checksum and artifact come from the same mutable/untrusted source and that is called independent verification;
- an attestation exists but is never verified;
- the verified attestation subject does not match the consumed artifact digest;
- a lockfile is called a security guarantee by itself;
- an SBOM is called provenance or integrity proof;
- a signature is accepted without verifying signer identity/policy;
- supply-chain checks are used to claim application or deployment safety.

# Input trust: dependencies, actions, and source refs

Supply-chain integrity starts before the build runs.

## Identity and mutability

For each executable input record:
- source/registry/repository;
- owner/publisher;
- selected ref/version;
- resolved immutable identity when available;
- integrity metadata;
- whether selection is mutable.

Examples of mutable selectors:
- branches;
- moving tags;
- floating version ranges;
- unversioned URLs.

Examples of stronger immutable identities:
- git commit identifiers;
- content digests;
- registry artifacts bound to integrity metadata.

Immutability controls mutation. It does not establish that the selected code is trustworthy.

## CI actions/plugins

Third-party actions/plugins execute inside the build trust boundary.

Review:
- source repository;
- ref form;
- immutable resolved commit where required;
- upstream identity;
- workflow permissions;
- update process.

Keep permission review separate: a perfectly pinned malicious action is still dangerous with broad permissions.

## Lockfiles

A lockfile can:
- preserve a resolved dependency tree;
- make source/integrity drift visible;
- improve reproducibility.

Review lockfile diffs for:
- registry/source changes;
- git commit changes;
- integrity digest changes;
- unexpected transitive additions;
- install-script-bearing packages.

Do not regenerate a lockfile blindly to make a diff disappear.

## Checksums

A checksum proves that bytes match an expected checksum.

Ask where the expected checksum came from.

Stronger:
- expected digest embedded in a trusted lockfile;
- digest from a signed/verified provenance statement;
- digest distributed through an independently trusted channel.

Weaker:
- artifact and checksum fetched from the same mutable location controlled by the same compromise path.

## Dependency updates

Supply-chain integrity does not own the semantic migration strategy.

For an upgrade:
- this skill verifies identity/source/integrity/provenance;
- dependency-upgrade engineering, if later justified, would own migration sequencing;
- testing verifies behavior after the change.

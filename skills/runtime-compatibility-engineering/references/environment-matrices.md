# Environment and version matrices

A useful compatibility matrix is small enough to maintain and precise enough to falsify.

## Row design

Prefer rows that represent materially distinct environments:

- Windows + PowerShell Core;
- Ubuntu + PowerShell Core;
- macOS + PowerShell Core;
- named third-party runtime integration;
- runtime requiring adaptation.

Do not create rows for every theoretical combination if the repository has no policy or tests for them.

## Column design

Typical columns:

- format;
- architecture/design;
- tested execution;
- runtime loading/integration;
- vendor support;
- evidence reference;
- claim limit.

Use only the dimensions that matter.

## Moving environments

Hosted aliases such as `windows-latest` or `ubuntu-latest` move over time.

For each important run record:
- the alias;
- runner OS;
- observed runtime versions;
- workflow/run ID;
- date.

Do not treat the alias itself as immutable version evidence.

## Lower-bound testing

If the repository claims runtime >= X:

- test X or the nearest supported X release;
- test a current release;
- keep feature usage compatible with X;
- fail visibly if the runtime is below X.

A pass on X+2 does not prove X.

## Adaptation matrix

For a runtime with different conventions, record what must change:

```text
runtime: <name>
format: ADAPTATION_REQUIRED
required adaptation:
  - frontmatter mapping
  - generated index
  - target directory
  - routing metadata
runtime_loading: NOT_RUN
```

Do not call it drop-in compatible before adaptation + execution.

## Review triggers

Re-review compatibility when:
- hosted runner images roll;
- runtime LTS/support windows change;
- minimum runtime version changes;
- shell/filesystem assumptions change;
- packaging/frontmatter format changes;
- a new runtime integration is added;
- a compatibility fixture regresses.

# Codex Engineering Skills

A small, curated collection of engineering instructions for **Codex and other agent workflows that can consume `SKILL.md`-style guidance**.

The repository packages recurring engineering concerns into task-specific skills: architecture boundaries, monorepo structure, SQLite durability, crawler reliability, local-first application security, testing, API contracts, CI reliability, runtime compatibility, software supply-chain integrity, and one project-specific GrowthOps router.

The intended workflow is simple:

```text
task
  -> select the smallest relevant skill set
    -> load only the references needed
      -> implement
        -> verify
```

This is **not** presented as a novel engineering framework, a universal benchmark, or proof that loading a skill automatically improves model quality. It is a maintained working collection built from practical project experience, public repositories, and official documentation, with explicit provenance and evidence limits.

> **Current suite version:** `1.2.1`  
> **Historical vNext release:** `v1.2.0`  
> **Registry:** 13 skills  
> **License:** Apache-2.0  
> **Tooling runtime:** PowerShell Core 7+ (`pwsh`)  
> **Primary tested hosts:** GitHub-hosted Windows and Ubuntu

---

## What these skills are for

A skill in this repository is a bounded instruction package for a recurring engineering problem.

Instead of asking an agent to rely only on a broad prompt such as:

> "Build a TypeScript monorepo."

a relevant skill can add constraints such as:

- which package owns which responsibility;
- where public API boundaries belong;
- which dependency directions are allowed;
- what durability or security invariant must survive;
- what verification is required before the task is considered complete.

The goal is not to make every prompt longer. The goal is to provide **specific engineering context when that context is actually relevant**.

Typical uses include:

- giving Codex a reusable engineering contract for a focused task;
- keeping project-specific rules separate from generic engineering guidance;
- reducing repeated explanation across similar tasks;
- making important failure boundaries and verification steps explicit;
- testing whether a skill is useful enough to keep, revise, or remove.

---

## What this repository is not

This repository does **not** claim that:

- every available skill should be loaded for every task;
- the current skill set is complete;
- every skill is already proven effective;
- the repository replaces project-specific engineering judgment;
- passing static validation proves an agent will behave correctly;
- context-byte reduction automatically means lower token cost or better output;
- one successful evaluation proves causal improvement;
- material adapted from public work originated here.

Some skills are intentionally still experimental.

---

## Current status

Current registry version: **1.2.0**.

| Category | Count | Meaning |
| --- | ---: | --- |
| Stable generic skills | 6 | Maintained for normal reuse, with observational evidence attached |
| Incubating generic skills | 6 | Useful enough to keep testing, but still `UNPROVEN` / evidence tier `none` |
| Project-specific skills | 1 | Deliberately tied to a named project and not treated as generic guidance |
| Total | **13** | Current registry entries |

### What is already in place

- UTF-8 / mojibake regression checks;
- registry lifecycle and evidence contracts;
- a behavioral evaluation harness with versioned cases and fixtures;
- one matched `no_skills` vs `selected_skills` behavioral comparison;
- a context-size benchmark for selective vs overloaded skill loading;
- a 10-case static router-selection corpus;
- a public, sanitized GrowthOps evidence case study;
- explicit installer selection with `-GenericOnly` and `-SkillName`;
- staged install, backup, rollback, and idempotency checks;
- Windows + Ubuntu CI using PowerShell Core 7+;
- compatibility claims separated into format, design, tested execution, and runtime loading;
- canonical provenance mapping and source validation;
- candidate incubation / defer decisions;
- Phase 16 lifecycle cleanup and removal of a redundant GrowthOps validator;
- a vNext acceptance report covering all 20 release criteria.

### What is **not** demonstrated yet

- macOS repository-tooling execution is **NOT RUN**;
- runtime loading/discovery in arbitrary third-party agents is **NOT RUN**;
- router **runtime obedience** is **NOT RUN** — the current router corpus validates the documented routing contract, not real agent compliance;
- the current context benchmark measures canonical `SKILL.md` entrypoint bytes, **not** token savings, latency savings, tool-call savings, or output quality;
- the six incubating skills remain **UNPROVEN** until their own post-creation evidence requirements are satisfied;
- the Phase 17 matched behavioral comparison produced **no measured criterion uplift** in that single run: both the baseline and selected-skill treatment passed 4/4 criteria;
- there is no broad multi-model or multi-user benchmark demonstrating universal effectiveness.

That distinction is intentional. The evidence system is meant to make unknowns visible rather than convert them into marketing claims.

Machine-readable vNext acceptance:

[`evidence/releases/v1.2.0-vnext-acceptance-2026-10-01.json`](evidence/releases/v1.2.0-vnext-acceptance-2026-10-01.json)

Release notes:

[`docs/releases/v1.2.0-vnext.md`](docs/releases/v1.2.0-vnext.md)

---

## Skills

| Skill | Lifecycle | Purpose |
| --- | --- | --- |
| `typescript-node-architecture` | stable | TypeScript/Node boundaries, contracts, lifecycle, async flow, and error design |
| `monorepo-typescript` | stable | pnpm workspaces, package ownership, exports, and dependency direction |
| `sqlite-data-modeling` | stable | Schema design, migrations, transactions, locking, and restart-safe persistence |
| `resilient-crawler-engineering` | stable | Durable crawling, retries, robots/sitemaps, bounded transport, checkpoint/resume |
| `application-security-local-first` | stable | SSRF/DNS rebinding, XSS, filesystem/path safety, secrets, and prompt boundaries |
| `testing-typescript-systems` | stable | Vitest/MSW, fixtures, regression strategy, fault injection, durability and restart testing |
| `agent-skill-authoring` | incubating | Creating, reviewing, packaging, and maintaining agent skills |
| `agent-skill-evaluation` | incubating | Evaluation cases, baselines, evidence discipline, routing, and context-cost analysis |
| `api-contract-testing` | incubating | API compatibility, provider conformance, consumer/provider contracts, breaking-change gates |
| `ci-pipeline-reliability` | incubating | CI triggers, matrices, failure propagation, runtime assumptions, caches/artifacts, flaky-test boundaries |
| `runtime-compatibility-engineering` | incubating | Host/runtime/toolchain support evidence, version boundaries, adaptation, and compatibility claim limits |
| `software-supply-chain-integrity` | incubating | Dependency/action/source trust, immutable refs, lockfiles, digests, attestations, build provenance |
| `growthops-engineering` | project | Project router and engineering contract specifically for GrowthOps |

Canonical metadata lives in [`REGISTRY.json`](REGISTRY.json).

---

## Lifecycle and evidence are separate

A lifecycle label answers:

> How is this skill intended to be maintained and used?

An evidence tier answers:

> What evidence currently supports its usefulness?

Those are deliberately different questions.

### Lifecycle

- **stable** — maintained for normal reuse;
- **incubating** — experimental and expected to change;
- **reference** — retained mainly as a pattern/knowledge asset;
- **project** — intentionally scoped to a specific project.

### Evidence

The repository records evidence separately so `stable` does not silently mean "scientifically benchmarked" and `incubating` does not silently mean "bad".

See:

- [`COLLECTION_POLICY.md`](COLLECTION_POLICY.md)
- [`evidence/README.md`](evidence/README.md)
- [`evidence/evaluations/README.md`](evidence/evaluations/README.md)

---

## Routing model

The default assumption is selective loading.

```text
PROJECT / TASK CONTEXT
        |
        v
optional project router
        |
        v
relevant specialist skill(s)
        |
        v
selected references only
        |
        v
implementation
        |
        v
verification
```

The repository intentionally does **not** treat "more skills loaded" as automatically better.

The current context benchmark compares:

- `no_skills`;
- `selected_skills`;
- `all_generic_skills`.

It measures canonical UTF-8 byte size of skill entrypoints. References are excluded because they are conditionally loaded.

See [`evidence/evaluations/context-current.json`](evidence/evaluations/context-current.json).

---

## Installation

### Requirements

Use **PowerShell Core 7+**:

```powershell
pwsh --version
```

Windows PowerShell 5.1 is not a supported installer runtime. The installer rejects it explicitly rather than continuing with uncertain behavior.

### Recommended for most users: generic skills only

Preview first:

```powershell
pwsh -NoProfile -File .\install.ps1 -DryRun -GenericOnly
```

Install the reusable generic skills:

```powershell
pwsh -NoProfile -File .\install.ps1 -GenericOnly
```

This avoids installing project-specific routers such as `growthops-engineering` into a general Codex skill directory.

### Install selected skills only

```powershell
pwsh -NoProfile -File .\install.ps1 -SkillName "sqlite-data-modeling,testing-typescript-systems"
```

### Advanced: install the full current registry

```powershell
pwsh -NoProfile -File .\install.ps1 -DryRun
pwsh -NoProfile -File .\install.ps1
```

No selection flag intentionally preserves the historical full-registry behavior, including project-specific entries. The installer prints a warning when project skills are included. Use this only when that is what you want.

Selection behavior:

- no selection flag installs the full current registry and warns when project-specific skills are included;
- `-GenericOnly` installs exactly entries whose registry `kind` is `generic`;
- `-SkillName` installs exactly the requested registered skills;
- `-GenericOnly` and `-SkillName` are mutually exclusive;
- invalid or mixed valid/unknown selections fail before target mutation;
- skills outside the selected set are left untouched.

Default Codex target is resolved from the current operating-system user home:

```text
Windows: %USERPROFILE%\.codex\skills
Linux/macOS convention: $HOME/.codex/skills
```

A mutating install takes an exclusive sibling lock for that target (for example `skills.install.lock`). A second installer targeting the same directory fails before changing active skill content. Dry-run remains lock-free and non-mutating.

Default backup root is the sibling `skills-backups` directory under the same user-home location. Backups are intentionally outside the active skill-discovery root.

For changed bundles, the installer uses a staged transaction:

```text
stage
  -> verify
    -> backup existing destination
      -> verify backup
        -> swap
          -> verify installed bundle
            -> rollback attempted destinations on failure
```

Identical reinstalls report `UNCHANGED` rather than generating unnecessary backups.

---

## Validation

Run:

```powershell
pwsh -NoProfile -File .\validate.ps1
```

The root validator currently checks, among other repository contracts:

- `SKILL.md` frontmatter structure;
- registered skill names and canonical paths;
- references;
- UTF-8 BOM / U+FFFD / known mojibake patterns;
- generated-output contamination;
- `SKILL.md` length guardrails;
- generic/project boundary leakage;
- registry kind, lifecycle status, evidence tier, and evidence references;
- retained project `suite-manifest.json` consistency.

Additional regression contracts under [`tests/`](tests/) cover the evidence model, evaluation harness, context benchmark, router selection, installer transactions, compatibility claims, provenance, incubation decisions, lifecycle cleanup, and vNext release readiness.

CI currently runs the shared PowerShell suite on:

- `windows-latest`;
- `ubuntu-latest`.

---

## Evidence and evaluation

The repository distinguishes static validity from behavioral evidence.

A valid skill can still be unhelpful.

A passing behavioral case can still fail to establish causality.

The current Phase 17 matched comparison is intentionally reported as:

```text
no_skills       -> PASS 4/4
selected_skills -> PASS 4/4

measured criterion uplift -> none in this single run
```

That result is retained because "no observed uplift" is still useful evidence. It is not rewritten into a stronger claim.

Relevant files:

- [`evidence/evaluations/cases.json`](evidence/evaluations/cases.json)
- [`evidence/evaluations/fixtures.json`](evidence/evaluations/fixtures.json)
- [`evidence/evaluations/results/`](evidence/evaluations/results/)
- [`evidence/evaluations/router-cases.json`](evidence/evaluations/router-cases.json)
- [`evidence/evaluations/context-current.json`](evidence/evaluations/context-current.json)

---

## Provenance and attribution

This repository was **not** produced in isolation.

Public repositories, public engineering patterns, and official documentation were inspected and compared while these skills were being written. Material was then rewritten, narrowed, reorganized, or adapted for this repository's agent-oriented workflow.

The repository should therefore be read as a **curated synthesis and working engineering collection**, not as a claim that every underlying idea originated here.

Source and license records are kept in:

- [`SOURCES.md`](SOURCES.md)
- [`ATTRIBUTION.md`](ATTRIBUTION.md)
- [`NOTICE`](NOTICE)
- [`PROVENANCE.json`](PROVENANCE.json)

`PROVENANCE.json` is the canonical machine-readable source-to-skill mapping validated by repository tests.

---

## GrowthOps project example

`growthops-engineering` is deliberately project-specific.

It exists because this repository also needed one non-toy example of composition:

```text
project vocabulary
+ project milestones
+ project constraints
+ generic specialist skills
= project router
```

It should **not** be copied to an unrelated project by simply renaming "GrowthOps".

The public case study is sanitized and based on committed project evidence:

[`docs/case-study-growthops-m01-m04.md`](docs/case-study-growthops-m01-m04.md)

---

## Repository layout

```text
skills/                  skill packages
templates/               reusable authoring/router templates
examples/                routing and usage examples
evidence/                evaluation, lifecycle, compatibility, release evidence
tests/                   PowerShell contract and regression tests
docs/                    PRD, compatibility/release notes, case-study documentation
REGISTRY.json            canonical skill registry + suite version
install.ps1              selective transactional installer
validate.ps1             root static validator
PROVENANCE.json          canonical machine-readable source mapping
```

---

## Creating or adapting a skill

Start with:

- [`AUTHORING_STANDARD.md`](AUTHORING_STANDARD.md)
- [`templates/project-router/SKILL.md`](templates/project-router/SKILL.md)
- [`examples/ROUTING_EXAMPLES.md`](examples/ROUTING_EXAMPLES.md)
- [`REGISTRY.json`](REGISTRY.json)

A new skill should have a narrow trigger, clear non-goals, useful completion criteria, and an explicit evidence plan.

Adding a skill directly as `stable` just because the topic sounds important is intentionally discouraged.

---

## Version and release semantics

Current suite version: **`1.2.1`**.

Patch notes: [`docs/releases/v1.2.1-safety-hardening.md`](docs/releases/v1.2.1-safety-hardening.md).

Historical vNext release evidence remains under `v1.2.0` and is not rewritten by this patch.

The suite uses simple SemVer-style versioning:

- **MAJOR** — breaking registry/installer contract changes, incompatible default behavior, or removal/renaming of maintained stable interfaces;
- **MINOR** — backward-compatible skills or new installer/evidence/validation capabilities;
- **PATCH** — backward-compatible fixes, documentation/provenance corrections, and test hardening.

A release tag is created only after the release commit is on `main` and required CI is green.

> The README on `main` may receive documentation-only updates after the latest published tag. The release evidence under `evidence/releases/` remains historical evidence for the tagged release and is not rewritten to pretend later documentation existed at release time.

---

## License

Apache-2.0.

Third-party projects retain their own copyrights and licenses as recorded in the attribution files.

---

# Owner's Notes — catatan buat gue sendiri

> Bagian atas buat orang yang pengen tahu repo ini **sebenarnya apa**.  
> Bagian bawah ini buat gue sendiri biar enam bulan lagi nggak sok lupa terus bikin kekacauan yang sama.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/merge-conflict.jpg" width="315" alt="merge conflict meme" />
</p>

## Ngene loh, Raf.

Awalnya cuma pengen bikin beberapa instruction biar Codex kalau ngerjain engineering nggak ngawur-ngawur amat.

Terus mulai:

```text
butuh monorepo rules
-> bikin skill

butuh SQLite durability
-> bikin skill

butuh crawler nggak amnesia
-> bikin skill

butuh security
-> bikin skill

butuh testing
-> bikin skill

butuh router
-> bikin lagi
```

Lama-lama:

> **lah jancuk, kok dadi bengkel.**

Ya wis. Bengkel ya bengkel.

Tapi inget: **bengkel bukan museum perkakas**.

Jangan semua obeng, kunci ring, bor, gerinda, dongkrak, kompresor, sama palu dimasukin tas cuma karena semuanya tersedia.

---

## Aturan nomor siji: OJO LOAD KABEH

Kalau nanti jumlah skill tambah banyak terus lo mikir:

> "sekalian load semua ben pinter."

**DAMPUT. OJO.**

Skema gobloknya sudah jelas:

```text
skill tambah akeh
-> load kabeh
-> context dadi gudang
-> instruction tabrakan
-> model muter-muter
-> token kobong
-> terus lo ngomel:
   "kok Codex lemot sih?"
```

Yo salahmu dewe, diancuk.

Pakai **skill paling sedikit yang cukup**.

Presence is not endorsement.

Ada di repo bukan berarti harus disuntikkan ke setiap kerjaan.

---

## Repo ini juga dudu wahyu engineering

Jangan suatu hari nulis README:

> "revolutionary autonomous engineering intelligence framework™"

Jancuk tenan nek nganti ngono.

Banyak bagian repo ini lahir dari:

- baca dokumentasi;
- lihat repo orang;
- cek pattern orang;
- bandingkan cara orang;
- kena bug sendiri;
- betulin;
- terus tulis ulang biar cocok dipakai agent.

Dan itu **nggak masalah**.

Yang penting jangan nyolong diam-diam, jangan ngaku dapat wahyu dari langit, attribution jelas, license jelas, terus hasil adaptasinya memang ada gunanya.

Repo ini biasa aja.

Cuma diusahakan **rapi, bisa dicek, dan nggak terlalu ngibul**.

Itu sudah cukup.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/stackoverflow-copypaste.jpg" width="290" alt="stackoverflow copy paste meme" />
</p>

---

## v1.2.0 — sing wis mari

Yang sudah beres dan jangan dibongkar cuma karena gabut:

- validator dasar sudah jauh lebih waras;
- mojibake punya regression fixture;
- lifecycle dipisah dari evidence;
- behavioral harness sudah ada;
- context benchmark sudah ada;
- router corpus sudah ada;
- GrowthOps public case study sudah ada;
- installer bisa pilih skill;
- staging / backup / rollback / idempotency sudah dites;
- Windows + Ubuntu CI sudah hijau;
- compatibility claim sudah dibatesin;
- provenance sudah dirapikan;
- Wave A dan Wave B sudah punya keputusan;
- Phase 16 cleanup selesai;
- vNext acceptance **20/20**;
- tag dan release **v1.2.0** sudah terbit.

Iki **selesai untuk scope vNext**, bukan berarti repo sakti mandraguna.

---

## Sing durung — utang nyata, bukan utang khayalan

Masih ada yang belum terbukti:

- macOS belum dites;
- runtime loading di agent lain belum dibuktikan;
- router belum diuji apakah agent beneran nurut saat runtime;
- context byte lebih kecil belum berarti token pasti lebih hemat;
- enam incubating skill masih **UNPROVEN**;
- benchmark behavior masih tipis;
- comparison Phase 17 malah hasilnya baseline PASS, selected PASS — **ora ono uplift sing kebukten nang run iku**;
- belum ada bukti lintas banyak model / banyak user / banyak project bahwa collection ini secara umum lebih bagus.

Kalau nanti mau lanjut:

**bayar utang yang nyata ini.**

Jangan malah bikin:

```text
observability-super-agent-skill-v2-final-final
multi-orchestrator-meta-router
agentic-agent-skill-manager-manager
```

padahal evidence yang lama belum dibayar.

Jancuk.

---

## Delete test

Setiap mau nambah mekanisme baru, tanya:

> Kalau benda ini gue hapus, apa ada sesuatu yang benar-benar hilang?

Kalau jawabannya:

> "hmmm... sebenernya nggak."

**hapus wae.**

Jangan miara complexity karena sayang sama commit sendiri.

Commit nggak punya perasaan.

---

## Stable iku dudu gelar profesor

`stable` artinya dipelihara buat pemakaian normal.

Bukan:

> "skill ini secara ilmiah meningkatkan AI sebesar 37.4%."

Ora ono bukti ngono.

Dan `incubating` juga bukan berarti sampah.

Artinya:

> "iki durung cukup bukti. ojo kemaki."

Simple.

---

## Tentang GrowthOps

`growthops-engineering` ada karena butuh contoh project router yang beneran punya project context.

Bukan template generik berkumis.

Kalau nanti bikin project baru:

**adaptasi pola composition-nya.**

Jangan:

```text
Ctrl+C
Ctrl+V
GrowthOps -> ProjectBaru
commit
"architecture complete"
```

Diancuk.

---

## Kalau suatu hari repo ini punya 100 skill

STOP.

Buka README iki.

Terus cek:

```text
apakah 100 skill itu benar-benar 100 kemampuan berbeda?

atau

gue cuma hobi koleksi folder?
```

Kalau jawabannya yang kedua:

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/99-bugs.jpg" width="300" alt="99 bugs meme" />
</p>

**PRUNING.**

Ora usah sentimental.

---

## Reminder terakhir

Yang dicari dari repo ini bukan biar orang buka terus ngomong:

> "WOOOOOW AGENTIC ENGINEERING SUPER SYSTEM."

Ra perlu.

Kalau orang buka terus ngerti:

- ini collection buat apa;
- skill mana yang relevan;
- mana yang stable;
- mana yang masih percobaan;
- evidence-nya di mana;
- batas klaimnya apa;
- cara install dan validasinya gimana;

**wes apik.**

Kalau kerjaan agent jadi sedikit lebih konsisten karena boundary-nya jelas:

bonus.

Kalau suatu skill ternyata nggak membantu:

buang atau revisi.

Kalau gue sendiri suatu hari mulai overclaim:

> **Rafdi, ojok kemaki. Woco evidence-mu dewe, jancuk.**

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/rubber-duck.jpg" width="285" alt="rubber duck debugging meme" />
</p>

---

**Small context. Clear boundaries. Boring reliability.**

Terus kerja. Ojo nggawe framework anyar mung mergo deadline liyane durung kelar.

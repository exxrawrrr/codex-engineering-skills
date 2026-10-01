# Codex Engineering Skills

> **A curated engineering skill collection for Codex and other agent workflows that can consume `SKILL.md`-style guidance.**

This repository packages recurring software-engineering concerns into focused, reusable instruction bundles: architecture boundaries, monorepo design, SQLite durability, crawler reliability, local-first application security, testing, API contracts, CI reliability, runtime compatibility, software supply-chain integrity, and project-specific routing.

The goal is simple:

```text
task
  ↓
select the smallest relevant skill set
  ↓
load only the references that matter
  ↓
implement
  ↓
verify
```

It is **not** a universal agent framework, a magic prompt collection, or proof that adding more context automatically produces better engineering.

---

## Current release

| Item | Current state |
| --- | --- |
| Suite / registry version | **1.2.1** |
| Published release | **v1.2.1 — Installation Safety Hardening** |
| Total registered skills | **13** |
| Stable generic skills | **6** |
| Incubating generic skills | **6** |
| Project-specific skills | **1** |
| Installer runtime | **PowerShell Core 7+** |
| Primary tested hosts | **GitHub-hosted Windows + Ubuntu** |
| License | **Apache-2.0** |

Release notes: [v1.2.1 safety hardening](docs/releases/v1.2.1-safety-hardening.md)

Historical v1.2.0 release evidence remains preserved rather than rewritten to pretend later hardening existed at that time.

---

## Why this exists

Agentic coding works better when important engineering constraints are explicit.

A generic request like:

> “Build a TypeScript monorepo.”

does not automatically tell an agent:

- which package owns which responsibility;
- which dependency directions are allowed;
- what belongs in the public API;
- how migrations must behave;
- what durability invariant must survive restart;
- what security boundary cannot be weakened;
- what evidence is required before calling the task complete.

A skill is a bounded instruction package for one of those recurring problems.

This repository tries to keep that guidance:

- **narrow enough to be useful**;
- **small enough to load selectively**;
- **explicit about non-goals**;
- **versioned and testable**;
- **honest about the evidence supporting it**.

---

## Skill catalog

| Skill | Lifecycle | Purpose |
| --- | --- | --- |
| `typescript-node-architecture` | stable | TypeScript/Node boundaries, contracts, lifecycle, async flow, and error design |
| `monorepo-typescript` | stable | workspace ownership, exports, package boundaries, and dependency direction |
| `sqlite-data-modeling` | stable | schema design, migrations, transactions, locking, and restart-safe persistence |
| `resilient-crawler-engineering` | stable | durable crawling, retries, robots/sitemaps, bounded transport, checkpoint/resume |
| `application-security-local-first` | stable | SSRF/DNS rebinding, XSS, filesystem/path safety, secrets, and prompt boundaries |
| `testing-typescript-systems` | stable | Vitest/MSW, fixtures, regression strategy, fault injection, durability and restart testing |
| `agent-skill-authoring` | incubating | creating, reviewing, packaging, and maintaining agent skills |
| `agent-skill-evaluation` | incubating | evaluation cases, baselines, evidence discipline, routing, and context-cost analysis |
| `api-contract-testing` | incubating | API compatibility, provider conformance, consumer/provider contracts, breaking-change gates |
| `ci-pipeline-reliability` | incubating | CI triggers, matrices, failure propagation, caches/artifacts, and flaky-test boundaries |
| `runtime-compatibility-engineering` | incubating | host/runtime/toolchain support evidence, version boundaries, adaptation, and compatibility claims |
| `software-supply-chain-integrity` | incubating | dependency/action/source trust, immutable refs, lockfiles, digests, attestations, provenance |
| `growthops-engineering` | project | project-specific router and engineering contract for GrowthOps |

Canonical metadata lives in [REGISTRY.json](REGISTRY.json).

---

## Lifecycle and evidence are separate

A lifecycle label answers:

> **How should this skill be maintained and used?**

An evidence tier answers:

> **What evidence currently supports its usefulness?**

Those are intentionally different questions.

A skill can be stable without claiming universal behavioral superiority. An incubating skill can be useful without pretending it is proven.

The repository keeps these concepts separate so labels do not quietly become marketing claims.

See:

- [COLLECTION_POLICY.md](COLLECTION_POLICY.md)
- [evidence/README.md](evidence/README.md)
- [evidence/evaluations/README.md](evidence/evaluations/README.md)

---

## Routing model

The default rule is **selective loading**, not “load everything.”

```text
PROJECT / TASK CONTEXT
        ↓
optional project router
        ↓
relevant specialist skill(s)
        ↓
selected references only
        ↓
implementation
        ↓
verification
```

The repository includes a static routing corpus and context-size measurements, but it does not claim that measured entrypoint-byte reduction automatically equals token savings, latency savings, or better model output.

---

## Installation

### Requirements

Use **PowerShell Core 7+**:

```powershell
pwsh --version
```

Windows PowerShell 5.1 is intentionally not a supported installer runtime.

### Recommended for most users: generic skills only

Preview first:

```powershell
pwsh -NoProfile -File .\install.ps1 -DryRun -GenericOnly
```

Install:

```powershell
pwsh -NoProfile -File .\install.ps1 -GenericOnly
```

### Install selected skills only

```powershell
pwsh -NoProfile -File .\install.ps1 -SkillName "sqlite-data-modeling,testing-typescript-systems"
```

### Install the full registry

```powershell
pwsh -NoProfile -File .\install.ps1 -DryRun
pwsh -NoProfile -File .\install.ps1
```

The full-registry path includes project-specific entries such as `growthops-engineering`. Use `-GenericOnly` when you want the reusable generic collection without project-specific routing.

---

## Installer safety

The installer is intentionally more defensive than a simple recursive copy.

For changed bundles, the flow is:

```text
stage
  ↓
verify
  ↓
backup existing destination
  ↓
verify backup
  ↓
swap
  ↓
verify installed bundle
  ↓
rollback attempted destinations on failure
```

Important behavior includes:

- preview / dry-run support;
- explicit `-GenericOnly` and `-SkillName` selection;
- invalid mixed/unknown selections fail before target mutation;
- unchanged bundles stay `UNCHANGED`;
- backups live outside the active skill-discovery root;
- mutating installs use an exclusive sibling lock;
- path containment and destination validation are tested;
- rollback behavior is tested;
- repository verification never needs to mutate a user's live skill directory.

The default Codex target follows the current user's home:

```text
Windows: %USERPROFILE%\.codex\skills
Linux/macOS convention: $HOME/.codex/skills
```

---

## Validation and CI

Run the repository validator:

```powershell
pwsh -NoProfile -File .\validate.ps1
```

The validator and regression suite cover, among other things:

- `SKILL.md` frontmatter;
- registered names and canonical paths;
- references;
- UTF-8 / mojibake regressions;
- generated-output contamination;
- generic/project boundary leakage;
- lifecycle and evidence metadata;
- installer transaction behavior;
- compatibility claims;
- provenance;
- routing contracts;
- release-readiness evidence.

CI currently runs the shared PowerShell suite on:

- `windows-latest`;
- `ubuntu-latest`.

The v1.2.1 hardening release was published after green PR verification, green post-merge `main` verification, and branch-protection hardening.

---

## Evidence model

This repository deliberately distinguishes:

```text
static validity
≠
behavioral usefulness
≠
causal improvement
≠
universal runtime compatibility
```

Current evidence includes:

- a behavioral evaluation harness with versioned cases and fixtures;
- matched `no_skills` vs `selected_skills` comparison;
- context-size measurement;
- static router-selection corpus;
- a public sanitized GrowthOps case study;
- Windows + Ubuntu installer/validator execution;
- release acceptance evidence;
- provenance/source validation.

One matched Phase 17 behavioral comparison produced:

```text
no_skills       → PASS 4/4
selected_skills → PASS 4/4

measured criterion uplift → none in that single run
```

That result remains in the repository because “no measured uplift” is still valid evidence. It is not rewritten into a stronger claim.

---

## What is not demonstrated

The repository intentionally keeps these gaps visible:

- macOS repository-tooling execution: **NOT RUN**;
- arbitrary third-party agent runtime loading/discovery: **NOT RUN**;
- router runtime obedience: **NOT RUN**;
- broad multi-model or multi-user proof: **NOT ESTABLISHED**;
- token, latency, tool-call, or output-quality savings from the context benchmark: **NOT ESTABLISHED**;
- the six incubating skills remain **UNPROVEN** until their own evidence requirements are satisfied.

Passing the repository validator does not prove that every model will follow every instruction perfectly.

---

## Provenance and attribution

This collection was not created in isolation.

Public engineering repositories, patterns, and official documentation were inspected while the skill set evolved. Material was rewritten, narrowed, reorganized, or adapted for this repository's agent-oriented workflow.

The repository should therefore be understood as a **curated engineering collection**, not as a claim that every underlying idea originated here.

Canonical source records:

- [SOURCES.md](SOURCES.md)
- [ATTRIBUTION.md](ATTRIBUTION.md)
- [NOTICE](NOTICE)
- [PROVENANCE.json](PROVENANCE.json)

---

## Repository layout

```text
skills/                  skill packages
templates/               reusable authoring/router templates
examples/                routing and usage examples
evidence/                evaluations, lifecycle, compatibility, release evidence
tests/                   PowerShell contract and regression tests
docs/                    PRD, compatibility, release notes, case studies, audits
REGISTRY.json            canonical registry + suite version
install.ps1              selective transactional installer
validate.ps1             root validator
PROVENANCE.json          machine-readable source mapping
```

---

## Creating or adapting a skill

Start with:

- [AUTHORING_STANDARD.md](AUTHORING_STANDARD.md)
- [templates/project-router/SKILL.md](templates/project-router/SKILL.md)
- [examples/ROUTING_EXAMPLES.md](examples/ROUTING_EXAMPLES.md)
- [REGISTRY.json](REGISTRY.json)

A useful new skill should have:

- a narrow trigger;
- explicit non-goals;
- clear completion criteria;
- references only when necessary;
- an evidence plan;
- a lifecycle state that matches reality.

A new topic does not become “stable” merely because it sounds important.

---

## Versioning

Current suite version: **1.2.1**

Current published release: **v1.2.1**

Simple SemVer-style interpretation:

- **MAJOR** — breaking registry/installer contracts, incompatible default behavior, removal/rename of maintained stable interfaces;
- **MINOR** — backward-compatible skills or new installer/evidence/validation capabilities;
- **PATCH** — backward-compatible fixes, documentation/provenance corrections, safety and regression hardening.

Historical evidence remains historical. Later README improvements do not rewrite what earlier releases actually contained.

---

## Contributing

Focused contributions are welcome.

Read:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [AUTHORING_STANDARD.md](AUTHORING_STANDARD.md)
- [SECURITY.md](SECURITY.md)

Please keep claims proportional to evidence and avoid turning project-specific assumptions into generic rules without justification.

---

## License

Apache-2.0. See [LICENSE](LICENSE).

Third-party projects retain their respective copyrights and licenses as recorded in the attribution and provenance files.

---

# Owner's Notes — catatan buat gue sendiri

> Kalau lu cuma mau pakai skill-nya, bagian atas sudah cukup.
>
> Bagian ini sengaja lebih personal. Biar beberapa bulan lagi gue masih inget kenapa repo ini berubah dari “beberapa instruksi buat Codex” menjadi bengkel engineering kecil.

## Awalnya cuma: “bikin beberapa skill biar Codex nggak ngawur”

Kurang lebih begini:

```text
butuh aturan TypeScript
→ bikin skill

butuh aturan monorepo
→ bikin skill

butuh SQLite nggak korup
→ bikin skill

butuh crawler nggak ngawur
→ bikin skill

butuh security
→ bikin skill

butuh testing
→ bikin skill
```

Terus gue lihat foldernya.

Kok nambah terus.

<p align="center">
  <img src="docs/assets/readme-notes/document-you.jpg" width="350" alt="I will document you meme" />
</p>

Ternyata penyakit utama repo ini bukan kekurangan dokumentasi.

Justru dokumentasinya bisa berkembang biak sendiri kalau tidak dikasih pagar.

## Dari “kumpulan prompt” jadi harus punya registry

Begitu jumlah skill bertambah, masalah baru muncul:

- skill mana generic?
- mana project-specific?
- mana stabil?
- mana masih eksperimen?
- sumbernya dari mana?
- siapa yang memastikan path/reference-nya valid?
- installer kalau gagal setengah jalan gimana?

Akhirnya lahir registry, lifecycle, provenance, validator, installer transaction, backup, rollback, tests, CI.

Ya. Dari file Markdown.

<p align="center">
  <img src="docs/assets/readme-notes/review-maybe.jpg" width="350" alt="review maybe meme" />
</p>

Setiap kali mikir “ini kayaknya sudah aman”, jawabannya biasanya:

> **review dulu.**

## Terus gue sempat mikir makin banyak skill = makin pintar

Ternyata belum tentu.

Kalau semua skill dimasukin ke context:

```text
lebih banyak instruksi
≠
lebih banyak kepintaran
```

Kadang yang terjadi cuma konteks makin gemuk, routing makin tidak jelas, dan agent harus membaca separuh perpustakaan sebelum menyentuh satu file.

Dari situ aturan yang justru paling penting jadi:

> **load the smallest relevant skill set.**

<p align="center">
  <img src="docs/assets/readme-notes/workflow.png" width="360" alt="workflow meme" />
</p>

Repo ini akhirnya lebih banyak mengatur **pemilihan konteks** daripada sekadar menambah konteks.

## Evidence bikin hidup sedikit lebih ribet, tapi jauh lebih jujur

Bagian yang gue suka dari repo ini justru ketika hasil evaluasi tidak sesuai harapan.

Phase 17:

```text
baseline 4/4
selected skills 4/4
uplift: none
```

Dulu mungkin gampang tergoda nulis:

> “skill meningkatkan kualitas engineering.”

Tapi datanya nggak bilang begitu.

Jadi ya jangan bilang begitu.

Lebih baik punya repo yang kadang jawab **“belum terbukti”** daripada README yang kedengarannya keren tapi tidak bisa dibela.

## Installer akhirnya ikut jadi proyek sendiri

Awalnya:

```text
copy folder → ~/.codex/skills
```

Terus pertanyaan berdatangan:

- target salah?
- install kedua bentrok?
- setengah file sudah diganti lalu gagal?
- backup valid?
- rollback berhasil?
- project skill ikut terpasang padahal user cuma butuh generic?
- PowerShell versi lama?

Akhirnya installer punya staging, verification, backup, lock, swap, rollback, idempotency, selection flags, dan regression tests.

Sedikit berlebihan untuk “copy Markdown”.

Tapi setelah lihat jenis kegagalan yang mungkin terjadi: ternyata nggak juga.

## v1.2.1: akhirnya release dengan safety hardening

Yang gue pengen dari release ini bukan klaim bombastis.

Cukup:

- installer lebih aman;
- CI Windows + Ubuntu hijau;
- branch protection aktif;
- evidence historis tidak dimanipulasi;
- registry dan README konsisten;
- limitation tetap ditulis.

<p align="center">
  <img src="docs/assets/readme-notes/all-tests-passed.jpg" width="360" alt="all tests passed meme" />
</p>

Itu sudah jauh lebih berguna daripada badge 47 biji tapi installernya bisa niban folder orang.

## Kalau nanti repo ini makin besar

Inget:

```text
small relevant context > everything loaded
evidence > marketing
specific skill > vague mega-skill
rollback > hope
provenance > "kayaknya dari sini"
tests > vibes
delete useless complexity
```

Dan jangan bikin skill baru cuma karena nama topiknya kedengaran keren.

Kalau prosedurnya belum jelas, trigger-nya kabur, atau tidak punya cara buat dinilai:

> mungkin itu belum skill. Mungkin itu cuma file Markdown yang sedang percaya diri.

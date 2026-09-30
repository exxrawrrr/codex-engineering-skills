# Codex Engineering Skills

> **Catatan buat gue sendiri dulu.**
>
> Repo ini bukan "install semua biar AI makin sakti".
>
> Justru kebalikannya.
>
> Kalau nanti gue mulai masukin 48 skill ke satu agent terus heran kenapa context-nya sesak:
>
> **woco README iki meneh.**

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/merge-conflict.jpg" width="315" alt="merge conflict meme" />
</p>

## Ngene loh, cak.

Awalnya gue cuma butuh beberapa instruction yang bikin agent engineering **nggak ngawur**.

Bukan cuma:

> "buat monorepo."

Tapi:

> "buat monorepo, ngerti ownership package-nya, dependency direction-nya, export boundary-nya, terus jangan bikin semua package saling gandengan kayak rombongan kondangan."

Terus berkembang.

Butuh SQLite? bikin skill.

Butuh crawler yang nggak amnesia habis restart? bikin skill.

Butuh security local-first? bikin skill.

Butuh testing yang nggak cuma tiga assertion terus merasa aman? bikin skill.

Butuh router khusus GrowthOps? yo bikin lagi.

Lama-lama:

> **lah kok dadi bengkel.**

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/99-bugs.jpg" width="300" alt="99 bugs meme" />
</p>

Dan akhirnya gue sadar:

**ya sudah. Memang ini bengkel.**

---

## Ini skill garage, bukan buffet all-you-can-eat

Kesalahan paling gampang waktu punya koleksi skill:

```text
"wah ada 8"
↓
"load semua"
↓
context gede
↓
instruction tabrakan
↓
agent mikir kelamaan
↓
token kobong
↓
gue:
"kok ngene?"
```

Ora usah.

Prinsip repo ini sederhana:

> **pakai skill paling sedikit yang cukup buat kerjaan saat ini.**

Bukan semua skill harus aktif.

Bukan semua skill harus stable.

Bukan semua skill harus relevan ke semua project.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/printf-debugging.jpg" width="290" alt="printf debugging meme" />
</p>

Presence is not endorsement.

Kalau satu skill ada di sini, artinya:

> **pernah cukup berguna, menarik, atau penting untuk dikoleksi.**

Bukan berarti harus disuntikkan ke setiap chat sampai model megap-megap.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/heisenbug.jpg" width="305" alt="heisenbug meme" />
</p>

---

## Yang gue kejar dari skill beginian

Gue nggak terlalu peduli skill-nya terdengar keren.

Gue lebih peduli apakah setelah skill dipakai:

- agent ngerti boundary;
- keputusan teknis lebih konsisten;
- context lebih kecil;
- testing lebih masuk akal;
- error lebih recoverable;
- source dan provenance jelas;
- project-specific rule nggak bocor ke project lain;
- dan hasil akhirnya bisa diverifikasi.

Kalau skill cuma bikin agent ngomong makin panjang tapi implementasinya sama:

**ngapain.**

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/stackoverflow-copypaste.jpg" width="290" alt="stackoverflow copy paste meme" />
</p>

---

## Cara gue mikir routing-nya

Kurang lebih:

```text
PROJECT CONTEXT
      ↓
PROJECT ROUTER
      ↓
pilih specialist skill yang relevan
      ↓
ambil references seperlunya
      ↓
implement
      ↓
verify
```

Bukan:

```text
PROJECT
  ↓
LOAD EVERYTHING
  ↓
SEMOGA ALLAH MEMBERKATI CONTEXT WINDOW
```

Nah.

---

## Status itu penting

Gue sengaja bedain skill jadi beberapa jenis.

### `stable`

Sudah cukup berguna buat pemakaian normal dan memang diniatkan untuk dirawat.

### `incubating`

Masih diuji.

Bisa berubah.

Bisa dipotong.

Bisa ternyata idenya bagus tapi implementasinya perlu ditampar ulang.

### `reference`

Disimpan sebagai knowledge/pattern.

Nggak harus masuk install normal.

### `project`

Sengaja spesifik ke satu project.

Contohnya `growthops-engineering`.

Kalau lu copy mentah skill project-specific ke project lain terus ternyata aneh:

ya karena memang **ora digawe kanggo kono**.

---

## Skill yang sekarang ada

| Skill | Status | Buat apa |
| --- | --- | --- |
| `typescript-node-architecture` | stable | strict TypeScript/Node boundaries, contracts, lifecycle, error design |
| `monorepo-typescript` | stable | pnpm workspaces, package ownership, exports, dependency direction |
| `sqlite-data-modeling` | stable | schema, migration, transactions, locking, restart-safe persistence |
| `resilient-crawler-engineering` | stable | durable crawling, retries, robots/sitemaps, checkpoint/resume |
| `application-security-local-first` | stable | SSRF, DNS rebinding, XSS, path safety, secrets, prompt boundaries |
| `testing-typescript-systems` | stable | Vitest, MSW, fixtures, durability/fault/restart testing |
| `agent-skill-authoring` | incubating | bikin, review, package, dan maintain agent skill |
| `agent-skill-evaluation` | incubating | evaluasi skill/router dengan case, baseline, evidence, dan context-cost discipline |
| `api-contract-testing` | incubating | compatibility API, schema/provider conformance, consumer-driven contract, dan breaking-change gate |
| `ci-pipeline-reliability` | incubating | trigger/matrix/runtime/failure-signal CI, cache-artifact boundary, dan flaky-test discipline |
| `runtime-compatibility-engineering` | incubating | bukti support OS/runtime/toolchain, version boundary, adaptation, dan anti-overclaim compatibility |
| `growthops-engineering` | project | router + engineering contract khusus GrowthOps |

Canonical registry: [REGISTRY.json](REGISTRY.json)

---

## Kenapa ada `growthops-engineering` di repo generic?

Karena gue pengen ada satu contoh **beneran dipakai di project nyata**.

Bukan contoh:

```text
my-awesome-project
todo: implement later
```

Tapi router yang memang punya vocabulary, milestone, contract, dan boundary dari project asli.

Fungsinya buat belajar composition.

Bukan buat dicopy terus nama GrowthOps diganti `ProjectX`.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/git-commit-fixed-stuff.jpg" width="300" alt="git commit fixed stuff meme" />
</p>

**Adapt. Ojo mung Ctrl+C Ctrl+V.**

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/xkcd-git.png" width="300" alt="xkcd git meme" />
</p>

---

## Gue juga nggak mau skill ini jadi kitab suci

Engineering berubah.

Library berubah.

Agent behavior berubah.

Model berubah.

Best practice juga kadang cuma best practice sampai ketemu production.

Jadi skill harus bisa:

```text
dipakai
→ diuji
→ dikritik
→ direvisi
→ dipromosikan
→ diturunkan statusnya
→ dipensiunkan kalau perlu
```

Makanya ada [COLLECTION_POLICY.md](COLLECTION_POLICY.md).

Kalau sebuah skill sudah redundant atau ternyata lebih banyak bikin ribet daripada membantu:

**ya wes, jangan dipelihara karena gengsi.**

---

## Provenance jangan disembunyikan

Repo ini bukan hasil gue bangun dari ruang hampa terus mendadak mendapat wahyu engineering.

Public repositories dan official docs dipelajari.

Pattern dibandingkan.

Lalu instruction ditulis ulang, disempitkan, dikembangkan, dan disusun buat workflow agent.

Detailnya ada di:

- [ATTRIBUTION.md](ATTRIBUTION.md)
- [NOTICE](NOTICE)
- [SOURCES.md](SOURCES.md)
- [PROVENANCE.json](PROVENANCE.json) — mapping source → skill yang divalidasi CI

Kalau ada ide bagus datang dari orang lain, ya sebut.

Simple.

---

## Install

Dry run dulu kalau pengen lihat apa yang bakal berubah:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -DryRun
```

Install:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Generic skills only:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -GenericOnly
```

Install only selected skills:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -SkillName "sqlite-data-modeling,testing-typescript-systems"
```

`-GenericOnly` and `-SkillName` are intentionally mutually exclusive so selection behavior stays unambiguous.

Selection contract:

- no selection flag = install the full current registry, preserving the original default behavior;
- `-GenericOnly` = install exactly entries whose registry `kind` is `generic`;
- `-SkillName` = install exactly the requested registry entries; matching is case-insensitive and output/install paths use the canonical registry name;
- unknown, blank, mixed-valid/unknown, or ambiguous selections fail before target mutation;
- skills outside the selected set are left untouched.

Default target:

```text
%USERPROFILE%\.codex\skills
```

Changed skills are handled as one invocation-level transaction: every changed bundle is staged and verified first, then every required existing bundle is backed up and verified before the first swap. Only after those preparation gates pass does replacement begin.

If any swap or post-install verification fails, every destination already attempted in that invocation is rolled back: existing bundles are restored from their verified backups, while failed fresh installs are removed. If restore verification itself fails, the unverified active destination is removed and the verified backup path is preserved in the error for manual recovery. Identical reinstalls report `UNCHANGED` and do not create redundant backups.

The installer cleans the staging directory created by the current invocation, but does not sweep unrelated `.skill-install-staging-*` directories because they may belong to another live or interrupted process.

By default backups live in the sibling directory:

```text
%USERPROFILE%\.codex\skills-backups
```

—not inside the active skill-discovery root. Each backup run uses a timestamp plus GUID suffix so concurrent/rapid runs do not share one backup directory.

A custom `-BackupRoot` must stay outside `-TargetRoot` and outside the repository source-skill tree. Existing target/backup path chains and installed skill destinations must not traverse symlink, junction, or reparse-point aliases; the installer rejects those instead of guessing which physical tree is authoritative. Path containment is case-insensitive on Windows and case-sensitive on Unix-like systems.

Karena installer yang merasa paling tahu lalu nimpa file tanpa backup itu bukan automation.

Itu villain origin story.

---

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File .\validate.ps1
```

Validator ngecek hal-hal seperti:

- frontmatter block structure;
- skill names dan canonical registered paths;
- references;
- UTF-8 BOM, replacement-character, dan common mojibake corruption;
- tool-output contamination;
- guardrail panjang `SKILL.md` (>500 baris menghasilkan warning);
- generic/project leakage;
- registry kind/lifecycle-status dan evidence-reference contract;
- project suite-manifest consistency;

Kalau validator merah:

jangan dibujuk.

Benerin.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/xkcd-compiling.png" width="295" alt="xkcd compiling meme" />
</p>

---

## Build your own skills

Kalau mau bikin skill sendiri, mulai dari:

- [AUTHORING_STANDARD.md](AUTHORING_STANDARD.md)
- [templates/project-router/SKILL.md](templates/project-router/SKILL.md)
- [examples/ROUTING_EXAMPLES.md](examples/ROUTING_EXAMPLES.md)
- [REGISTRY.json](REGISTRY.json)

`agent-skill-authoring` juga sengaja ada sebagai meta-skill untuk bantu proses itu.

Tapi tetap:

> skill yang bagus bukan skill yang paling panjang.

Skill yang bagus adalah instruction yang bikin agent **lebih tepat**, tanpa bikin context berubah jadi gudang kardus.

---

## Pesan buat gue nanti

Kalau collection ini suatu hari isinya 100 skill:

cek lagi.

Jangan-jangan yang gue bangun bukan skill system.

Jangan-jangan cuma folder hoarding dengan YAML.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/rubber-duck.jpg" width="285" alt="rubber duck debugging meme" />
</p>

Yang dicari tetap sama:

> **small context, strong boundaries, boring reliability.**

Kalau skill nggak membantu salah satu dari itu, minimal harus punya alasan bagus kenapa dia masih tinggal di sini.

---

<br/>

# For everyone else

> If you came here for the reusable engineering suite rather than the owner's notes, this section is the cleaner overview.

## Codex Engineering Skills

**Codex Engineering Skills is a curated collection of reusable engineering skills for Codex and other agent workflows that understand `SKILL.md`-style instructions.**

The suite focuses on reliable engineering patterns rather than maximum instruction volume.

Its main goals are:

- smaller task-specific context;
- explicit engineering boundaries;
- reusable specialist guidance;
- clear separation between generic and project-specific instructions;
- validation and provenance;
- testable, recoverable system design.

## Included skills

| Skill | Purpose |
| --- | --- |
| `typescript-node-architecture` | Strict TypeScript/Node boundaries, contracts, async lifecycle, error design |
| `monorepo-typescript` | pnpm workspaces, package ownership, exports, dependency direction |
| `sqlite-data-modeling` | Schema design, migrations, transactions, locking, restart-safe state |
| `resilient-crawler-engineering` | Durable frontier, retries/backoff, robots/sitemaps, checkpoint/resume |
| `application-security-local-first` | SSRF/DNS rebinding, XSS, path safety, secrets, prompt-injection boundaries |
| `testing-typescript-systems` | Vitest, MSW, fixtures, durability/fault/restart tests, targeted E2E |
| `agent-skill-authoring` | Meta-skill for creating, reviewing, packaging, and publishing agent skills |
| `agent-skill-evaluation` | Evidence-backed evaluation of skill/router effectiveness, routing, and context cost |
| `api-contract-testing` | Machine-readable API compatibility, provider conformance, and consumer/provider contract verification |
| `ci-pipeline-reliability` | Trustworthy CI triggers, matrices, failure propagation, runtime assumptions, caches/artifacts, and flaky-test handling |
| `runtime-compatibility-engineering` | Host/runtime/toolchain support matrices, evidence boundaries, minimum versions, and adaptation requirements |
| `growthops-engineering` | Real project-specific router and engineering contract example |

## Routing model

```text
project router
  -> relevant specialist skill(s)
    -> selected references
      -> implementation
        -> verification
```

The collection intentionally avoids the assumption that every available skill should be loaded for every task.

## Collection model

Registry status communicates intended use:

**stable** — reusable and maintained for normal use.

**incubating** — experimental and expected to evolve.

**reference** — retained primarily as a knowledge or pattern asset.

**project** — intentionally tied to one project's scope and vocabulary.

See [COLLECTION_POLICY.md](COLLECTION_POLICY.md) and [REGISTRY.json](REGISTRY.json).

## Installation

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Generic skills only:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -GenericOnly
```

Selected skills only:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -SkillName "sqlite-data-modeling,testing-typescript-systems"
```

`-SkillName` matching remains case-insensitive for compatibility, while installed/output names use the canonical registry spelling. No selection flag preserves the original full-registry install; `-GenericOnly` selects exactly registry `kind=generic`; `-SkillName` selects only the named entries and leaves other installed skills untouched. Invalid or mixed-valid/unknown selections fail before mutation.

Backups default to the sibling `skills-backups` directory, use collision-resistant per-run IDs, and are rejected if the backup path is inside the active target tree or overlaps the repository source-skill tree. Existing symlink/junction/reparse-point aliases in installer-controlled target/backup paths are rejected rather than followed.

Changed skills are transaction-scoped per installer invocation: all changed bundles are staged/verified and all required backups are verified before the first replacement. A later swap or installed-verification failure rolls back every destination already attempted in that invocation. Fresh installs are removed on rollback; existing installs are restored from verified backups. An incomplete restore removes the unverified active destination and reports the retained verified backup path.

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File .\validate.ps1
```

The validator checks frontmatter structure, skill metadata and canonical registered paths, references, `SKILL.md` length guardrails, generic/project leakage, BOM/U+FFFD/common-mojibake text hygiene, generated-output contamination, registry kind/lifecycle/evidence contracts, and project suite-manifest consistency.

## Provenance

These skills are newly authored as a curated synthesis rather than a wholesale fork of one upstream project.

Public repositories and official documentation were studied and compared, then the material was rewritten and organized for agent workflows.

See:

- [ATTRIBUTION.md](ATTRIBUTION.md)
- [NOTICE](NOTICE)
- [SOURCES.md](SOURCES.md)
- [PROVENANCE.json](PROVENANCE.json) — canonical machine-readable source → skill mapping

## Authoring

To create or adapt skills, start with:

- [AUTHORING_STANDARD.md](AUTHORING_STANDARD.md)
- [templates/project-router/SKILL.md](templates/project-router/SKILL.md)
- [examples/ROUTING_EXAMPLES.md](examples/ROUTING_EXAMPLES.md)

## License

Apache-2.0.

Third-party projects retain their own copyrights and licenses as documented in the attribution files.

---

**Use the smallest skill set that can do the job well. Context is a resource too.**

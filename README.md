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

Default target:

```text
%USERPROFILE%\.codex\skills
```

Existing matching folders are staged, validated, backed up, swapped, and verified before the install is considered successful. If a swap or post-install verification fails, the previous skill is restored automatically. Identical reinstalls report `UNCHANGED` and do not create redundant backups. By default backups live in the sibling directory:

```text
%USERPROFILE%\.codex\skills-backups
```

—not inside the active skill-discovery root. A custom `-BackupRoot` is allowed only when it is outside `-TargetRoot`.

Karena installer yang merasa paling tahu lalu nimpa file tanpa backup itu bukan automation.

Itu villain origin story.

---

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File .\validate.ps1
```

Validator ngecek hal-hal seperti:

- frontmatter;
- skill names;
- references;
- UTF-8 BOM, replacement-character, and common mojibake corruption;
- tool-output contamination;
- context size;
- generic/project leakage;
- registry lifecycle-status values;
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

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File .\validate.ps1
```

The validator checks skill metadata, references, context size, project leakage, encoding issues, generated-output contamination, and repository maintenance rules.

## Provenance

These skills are newly authored as a curated synthesis rather than a wholesale fork of one upstream project.

Public repositories and official documentation were studied and compared, then the material was rewritten and organized for agent workflows.

See:

- [ATTRIBUTION.md](ATTRIBUTION.md)
- [NOTICE](NOTICE)
- [SOURCES.md](SOURCES.md)

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

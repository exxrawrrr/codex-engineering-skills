# Skill Authoring Standard

This repository uses a small set of conventions to keep skills useful to both humans and agents.

## 1. Skill classes

**Generic skill** — reusable across projects.

**Project skill/router** — contains project-specific product rules, vocabulary, scope, milestones, or release gates.

Generic skills must stay free of project-specific policy.

## 2. Required files

Every skill requires:

```
skills/<name>/SKILL.md
```

The registry path is canonical and must resolve to that same directory:

```json
"path": "skills/<name>"
```

Do not use path aliases such as `..` segments to reach an equivalent directory.

Optional:

```
references/
scripts/
assets/
```

## 3. Frontmatter

```yaml
---
name: exact-directory-name
description: "Specific problem class + trigger conditions."
---
```

Both `---` delimiters are required, and `name` / `description` must be inside the frontmatter block. Body text does not satisfy missing frontmatter metadata.

Registry class/status consistency is enforced:

- `kind: generic` may use `stable`, `incubating`, or `reference`;
- `kind: project` uses `status: project`.

## 4. Progressive disclosure

Keep high-frequency rules in `SKILL.md`.
Move conditional depth into references.

Never instruct agents to read all references unconditionally.

## 5. Context discipline

Prefer fewer high-signal rules over encyclopedic prose.

A skill is not better because it is longer.

## 6. Composition

Project routers should compose generic skills instead of copying them.

Generic skills should not depend on project routers.

## 7. Provenance

When external work materially shapes a skill:
- add it to attribution/provenance;
- state what it informed;
- do not imply endorsement.

## 8. Validation

Every change should pass:

```powershell
./validate.ps1
```

## 9. Security

Never place real secrets, private tokens, passwords, or sensitive user data in skills, fixtures, examples, or logs.

## 10. Review test

A reviewer should be able to tell:
- when the skill loads;
- what it requires;
- what it forbids;
- which references are conditional;
- how completion is verified.


## Evidence claims

Skill quality and skill effectiveness are different review questions.

When a skill is added or changed:

- state behavioral claims only to the level supported by evidence;
- link reusable evidence through `REGISTRY.json.evidence_refs`;
- use `none`, `observed`, `repeated`, or `benchmarked` according to `COLLECTION_POLICY.md`;
- never convert a lifecycle label into a performance claim;
- preserve explicit limitations when evidence is observational or runtime-specific.

A benchmark result is not a permanent universal truth. Record the task/case, runtime/model when available, validation method, and limitations.

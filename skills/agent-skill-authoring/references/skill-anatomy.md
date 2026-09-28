# Skill anatomy

## Frontmatter

Minimum:

```yaml
---
name: example-skill
description: "What this skill does and when to use it."
---
```

The directory name and `name` should match.

The description should include:
- problem class;
- important boundaries;
- trigger situations.

Avoid vague descriptions such as "helps with coding."

## Entrypoint sections

A strong `SKILL.md` usually contains:

- identity/purpose;
- selective reference routing;
- core rules;
- workflow;
- red flags;
- completion/verification behavior.

Not every skill needs every heading, but the entrypoint should be operational.

## References

Use references for:
- framework-specific detail;
- deep implementation patterns;
- long checklists;
- examples;
- security subtopics;
- migration playbooks.

A reference file should have a clear reason to exist and should be named by topic, not `notes2.md`.

## Scripts/assets

Add scripts only when they provide repeatable deterministic value such as validation, migration, linting, or generation.

Do not add executable helpers merely to make a skill look advanced.

# Progressive disclosure

Agent context is a limited resource.

Use a layered model:

```
metadata/description
  -> SKILL.md
    -> selected reference
      -> optional script/tool
```

## Entry-point budget

Keep the entrypoint concise enough that loading it does not crowd out the actual task.

Split when:
- a section is needed only for one subdomain;
- examples dominate the rules;
- framework-specific material appears in a framework-neutral skill;
- the same large appendix is rarely needed.

## Do not over-split

A five-line reference file usually creates more navigation cost than value.

Split by meaningful subproblem.

## Routing language

Prefer:

```
Read references/retries.md when modifying retry policy.
```

Avoid:

```
Read all files in references before doing anything.
```

Selective loading is part of the skill design.

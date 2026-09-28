---
name: agent-skill-authoring
description: "Design, review, refactor, and package maintainable SKILL.md-style agent skills with precise triggers, progressive disclosure, bounded context, provenance, testable rules, project-vs-generic separation, and automated validation. Use when creating a new agent skill, cleaning up an existing skill, splitting references, designing a project router, or preparing skills for public reuse."
---

# Agent Skill Authoring

Use this skill when the artifact being designed is an agent skill itself.

## Load references selectively

- Skill anatomy and frontmatter: `references/skill-anatomy.md`
- Progressive disclosure and context budget: `references/progressive-disclosure.md`
- Project routers and composition: `references/router-pattern.md`
- Provenance and public reuse: `references/provenance-and-reuse.md`

## Core rules

1. A skill should solve one coherent class of problems.
2. The description is a router contract, not marketing copy.
3. `SKILL.md` should contain the minimum high-value rules needed for routing and execution.
4. Deep guidance belongs in `references/`.
5. Do not duplicate the same rules across multiple skills unless the invariant truly belongs in both.
6. Generic skills must not silently contain project-specific names, paths, credentials, or product policy.
7. Project routers coordinate specialist skills; they should not re-implement specialist content.
8. Prefer explicit "use when" and "do not use when" boundaries.
9. Rules should be testable or behaviorally observable where practical.
10. Public skills must document provenance honestly.

## Authoring workflow

Before writing:
1. identify the problem class;
2. identify neighboring skills and overlap;
3. define trigger conditions;
4. define exclusions;
5. identify what belongs in the entrypoint vs references;
6. identify external sources that materially inform the skill.

During writing:
- keep terminology stable;
- use imperative, operational rules;
- separate invariants from examples;
- avoid unnecessary framework lock-in;
- avoid future-speculative instructions.

After writing:
- validate frontmatter;
- verify every referenced file exists;
- inspect for accidental project leakage;
- inspect encoding;
- run suite validator;
- review context size;
- document provenance when appropriate.

## Red flags

Stop if:
- the skill is just a long checklist with no routing boundary;
- the description matches every coding task;
- `SKILL.md` exceeds a reasonable context size while references could split it;
- a generic skill contains one project's product rules;
- the same paragraph exists in several skills;
- source attribution is hidden or overstated;
- the skill instructs an agent to load every other skill by default.

## Success condition

A good skill lets an agent answer four questions quickly:

1. Should I load this skill?
2. What rules are mandatory?
3. Which reference file do I need now?
4. How do I know the task is done?

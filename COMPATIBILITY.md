# Compatibility

## Designed for

This repository targets agent environments that can consume Markdown instruction files and can selectively load `SKILL.md`-style folders.

The layout is intentionally simple:

```
skills/<skill-name>/SKILL.md
skills/<skill-name>/references/*.md
skills/<skill-name>/scripts/*
```

## Codex

Primary local installation target:

```
%USERPROFILE%\.codex\skills
```

The included PowerShell installer supports this layout directly.

## Other agents

The content is mostly model-agnostic Markdown.

Other systems may need:
- a different skills directory;
- different frontmatter fields;
- a wrapper/index;
- manual routing.

Use `-TargetRoot` with the installer when a compatible filesystem-based skill directory is available.

## Supporting skills

Some routing examples reference external/supporting skills such as:
- verification-loop;
- systematic-debugging;
- requesting-code-review;
- codebase-onboarding;
- playwright-cli.

These are recommended, not bundled dependencies.

The validator reports them as warnings when absent.

## OS support

The supplied installer/validator are PowerShell-first and tested for Windows-oriented Codex workflows.

The Markdown skills themselves are portable.

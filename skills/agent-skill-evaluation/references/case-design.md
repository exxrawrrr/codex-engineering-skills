# Evaluation case design

A useful skill evaluation case is small enough to reproduce and specific enough to score.

## Start from a claim

Examples:

- the architecture skill reduces deep-import/package-boundary violations;
- the SQLite skill improves migration failure handling;
- the crawler/security skills prevent unsafe redirect connections;
- a project router selects fewer irrelevant skills than loading the whole collection.

A case should not start from:

> prove this skill is good

## Task fixture

Freeze as much as practical:

- repository/fixture version;
- input task;
- starting files/state;
- allowed tools;
- acceptance criteria;
- verification commands.

Do not silently repair the fixture between comparison variants.

## Acceptance criteria

Prefer binary or directly reviewable criteria.

Good:

- no package imports another package's private `src/`;
- failed migration does not advance schema version;
- public-to-private redirect produces zero blocked-destination connections;
- selected skill count stays below the declared maximum.

Avoid criteria such as:

- elegant architecture;
- expert-level output;
- more thoughtful answer.

## Case size

One case should test one coherent behavior class.

Split cases when:
- scoring depends on unrelated subsystems;
- different specialist skills own different failure modes;
- one giant fixture makes failures hard to attribute.

## Regression value

A good case remains useful after the first evaluation.

Version the fixture/criteria when the contract changes rather than editing historical results into compliance.

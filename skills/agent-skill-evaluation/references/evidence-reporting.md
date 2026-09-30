# Evidence reporting

The report should make it harder to overclaim than to stay uncertain.

## Result states

Use explicit states such as:

```text
PASS
FAIL
NOT_RUN
NOT_AVAILABLE
```

Do not infer a pass from missing errors or an empty result.

## Criterion evidence

Each scored criterion should point to compact evidence such as:

- test command and result;
- public commit/file reference;
- deterministic artifact;
- sanitized diff;
- bounded structured output.

A summary such as "worked well" is not criterion evidence.

## Claim levels

### Observational

The skill was used and the resulting work had certain properties.

This does not prove the skill caused those properties.

### Comparative

Controlled variants were executed and compared.

This can support a bounded causal claim about that case/runtime when confounds are documented.

### Generalized

Requires repeated evidence across tasks/runtimes.

Do not jump from one comparative case to a universal claim.

## Evidence tiers

Repository evidence tiers may be:

- `none`;
- `observed`;
- `repeated`;
- `benchmarked`.

Promotion must point to auditable records.

A lifecycle label such as `stable` is not effectiveness evidence.

## Privacy

Prefer compact evidence over raw conversation dumps.

Never publish:
- secrets;
- credentials;
- private user data;
- unrelated local workspace content.

Private transcripts should remain private unless they are genuinely necessary and explicitly safe to publish.

## Negative results

Keep useful failures.

A result showing that a skill adds context without improving the case, or causes a regression, is valuable evidence for revision, deprecation, or rejection.

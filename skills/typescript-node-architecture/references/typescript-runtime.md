# TypeScript runtime and strictness

This reference is informed by current production-oriented TypeScript guidance, including Trail of Bits' public TypeScript rules. Adapt to the repository instead of forcing tools that are not already approved.

## Runtime

- Use a currently supported Node.js release appropriate to the repository.
- Prefer ESM for greenfield code when the selected stack supports it cleanly.
- Pin runtime/tooling intentionally in project configuration; do not rely on developer-machine defaults.

## Compiler baseline

For greenfield strict TypeScript, strongly consider:

```jsonc
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true
  }
}
```

Enable flags deliberately and fix resulting type errors rather than disabling them reflexively.

## Type rules

- Avoid `any`; use `unknown` + validation at untrusted boundaries.
- Model finite states with discriminated unions.
- Do not conflate transport DTOs with durable domain models when lifecycles differ.
- Prefer named option objects over ambiguous boolean parameters.
- Export the smallest useful type surface.

## Dependency hygiene

- Keep a lockfile committed.
- Prefer exact or intentionally controlled versions according to project policy.
- Audit newly introduced dependencies before adoption.
- Do not add dependencies solely to avoid writing a small, well-tested local helper.
- Treat install scripts and supply-chain behavior as security-relevant.

Do not blindly copy another repository's lint/format toolchain; align with the project's approved stack.

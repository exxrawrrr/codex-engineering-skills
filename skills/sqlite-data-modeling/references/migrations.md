# SQLite migration discipline

## Versioning

Use one authoritative schema version mechanism for the selected stack. SQLite `PRAGMA user_version` is a viable lightweight option when the migration runner owns it; an ORM migration table is also valid.

Do not maintain two competing authorities.

## Rules

1. Applied/released migrations are immutable.
2. Fix mistakes with a new migration.
3. Advance schema version only after migration success.
4. Migration code must preserve existing data unless an approved destructive change says otherwise.
5. Test both fresh initialization and upgrade from representative old versions.
6. Reopening an already-current database must be idempotent.

## Risky transformation

Prefer staged changes:

1. create new structure;
2. copy/transform;
3. validate counts/invariants;
4. switch readers/writers;
5. remove old structure only when safe.

For destructive migrations, provide backup/recovery behavior appropriate to the product.

## Verification

Tests should cover:
- fresh DB creation;
- previous-version upgrade;
- data preservation;
- repeated open after migration;
- failure does not falsely advance schema version.

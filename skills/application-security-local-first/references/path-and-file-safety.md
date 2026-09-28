# Path and file safety

## Root containment

Define an application-owned root for generated artifacts.

For every write:
1. generate or sanitize a safe relative name;
2. resolve against approved root;
3. canonicalize/normalize as appropriate;
4. verify resulting path remains inside the root;
5. write using APIs that do not invoke a shell.

Do not rely on replacing `../` alone.

## Filenames

Prefer generated IDs/slugs over remote filenames.

If retaining a remote/user-visible name:
- store the original name as metadata;
- generate a separate safe storage name;
- restrict length;
- remove/replace path separators;
- reject control characters;
- account for Windows reserved names and trailing dot/space behavior;
- avoid leading-dot hidden-file surprises where relevant.

Do not let `Content-Disposition` choose the local path.

## Path traversal inputs

Treat as untrusted:
- URL paths;
- query parameters;
- hostnames;
- page titles;
- report names;
- project names;
- model-generated artifact names;
- archive entry names.

Reject absolute paths and traversal outside the approved root.

## Symlinks / junctions

When writes may occur in user-modifiable directories, account for symlink/junction escape where relevant.

Checking a textual prefix alone may be insufficient after filesystem indirection.

Prefer application-controlled directories with restricted mutation.

## Archive extraction

If archive support is ever added:
- reject absolute entries;
- reject traversal entries;
- validate each final extraction path;
- do not trust archive filenames.

## Tests

Include:
- `../` and nested traversal;
- absolute Windows/Unix paths;
- mixed separators;
- encoded traversal where decoding occurs;
- reserved names;
- very long filenames;
- leading/trailing dot/space;
- symlink/junction escape if supported environment makes it relevant.

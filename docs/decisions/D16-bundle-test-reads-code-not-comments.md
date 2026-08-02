# D16. Bundle discipline test reads code, not comments

Kind: implementation

`tests/bundle.test.ts` strips comments before scanning for engine imports.

The first run failed on `src/core/babylon.ts` itself, because that file's doc
comment quotes the barrel import it exists to prevent. A rule that cannot be
explained in prose beside the code it governs is a bad rule, so the scanner
learned to read code instead of the documentation learning to avoid words.

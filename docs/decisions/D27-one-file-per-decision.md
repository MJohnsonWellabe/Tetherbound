# D27. One file per decision, and no checked-in index

Kind: implementation

`DECISIONS.md` was a single file that every session appended to at the top. It
is the most-churned file in the repo, six commits deep after two sessions, and
every one of those commits rewrote the same region. That is fine while one
session runs at a time and guarantees a conflict the moment two do.

Split into `docs/decisions/DNN-slug.md`, one entry per file, content unchanged.
Two sessions adding decisions now add different files, and git has nothing to
reconcile.

`DECISIONS.md` survives as the explainer for the format. It deliberately holds
no index: a list of every decision is a single line that each session appends
to, which is the original conflict wearing a different name. `npm run decisions`
generates the list from the directory instead, and exits non-zero when two files
claim the same number, which is the quiet way concurrent work corrupts the log.
Cross-references like "per D15" are unaffected because the numbers did not move.

Numbers are allocated by range when sessions run in parallel, not by
`--next`, because `--next` reads the working tree and cannot see a branch it is
not on. Two sessions would both be told D27.

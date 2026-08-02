# D52. An asset is stale when its job or its source is newer than its output

Kind: implementation

`npm run assets` rebuilds a job when the output file is missing, when
`--force` is passed, when the output is older than any source it reads, or when
the output is older than `scripts/asset-jobs.mjs`.

The original check was `existsSync(out) && !force`, which means an asset was
considered fresh forever once built. Retargeting a job at a different source
model, or changing its simplify ratio, left the old file sitting in `public/`
and the pipeline cheerfully reported `fresh` for it. The edit looked applied,
the manifest looked right, and nothing changed.

That is not a hypothetical. Two ground-cover jobs carried `simplify` ratios of
0.28 and 0.35, and the shipped models were byte-for-byte the unsimplified
sources at 224 and 276 triangles. The ratios had never once been applied. A
previous session added them specifically to bring the triangle budget down,
verified the budget came down (density changes in the same commit did that),
and recorded the simplify pass as the fix. The pass did nothing.

The lesson is worth more than the fix: a cache whose invalidation ignores the
thing you edit will convert an edit into a no-op and report success. When a
tuning change produces no measurable effect, check that the tool ran before
concluding the tuning was wrong.

Timestamps rather than content hashes, because the raw kits are large, the
comparison runs on every invocation, and a spurious rebuild costs seconds while
a missed rebuild costs a debugging session.

Separately, and for the same reason, `simplify()` needs its `error` bound
raised to matter. At the default 0.01 (one percent of mesh extent) collapsing
any edge of a multi-blade grass tuft blows the bound immediately, so the
simplifier returns the mesh untouched whatever ratio it is given. Ground cover
is read at 40m and beyond, where 0.5 costs nothing visible.

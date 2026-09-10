# CI audit — PR117 commit `9fc53908fe59c2d1ee055ab6f6e49bf11824ee60`

Workflow run `34454848997` (run number `4664`, PR117, repository
`MJohnsonWellabe/Tetherbound`) completed **success**. The run has 29 jobs: 26
executed jobs succeeded and three jobs were intentionally skipped by workflow
conditions: `verify-gate-b-full-known-red`, `verify-continuous-core-known-red`,
and `export`. No job was rerun and no green result is based on a retry.

All raw executed-job logs are preserved under:

```text
.artifacts/broad-visual-0910/ci-9fc/
```

## Executed jobs

The 26 successful jobs were `changes`, `verify-scatter-rules`,
`verify-veg-corridor`, `verify-scatter-bake-freshness`, `verify-unit-tests (1)`
through `(4)`, `verify-terrain-bake-freshness`, `verify-regions-shard`,
`verify-harvest`, `discover-net-smokes`, `verify-gate-a-ui-build-shard`,
`verify-core-verb-shard`, `verify-gate-evidence-shard`, `verify-gate-b-core`,
`verify-combat-shard`, `verify-owner-regressions-shard`,
`verify-multiplayer-shard (1)` through `(7)`, and `verify-solo-regression`.

The unit shards ran actual test suites rather than documentation-only checks:

| Job | Result |
|---|---:|
| `verify-unit-tests (1)` | 688 tests / 62,814 assertions / 0 failed |
| `verify-unit-tests (2)` | 932 tests / 376,320 assertions / 0 failed |
| `verify-unit-tests (3)` | 766 tests / 33,889 assertions / 0 failed |
| `verify-unit-tests (4)` | 817 tests / 17,785 assertions / 0 failed |
| **Unit total** | **3,203 tests / 490,808 assertions / 0 failed** |

Other explicit suite receipts include 38 scatter-rule tests / 1,019,854
assertions, 9 corridor tests / 1,537,510 assertions, 30 harvest tests /
799,078 assertions, and one assertion each for scatter and terrain bake
freshness. The regions, Gate A, Gate B, combat, owner-regression and all seven
multiplayer jobs report successful production or contract checks. The solo job
is a successful dependency fence and prints the depended-on jobs; it does not
run an additional test suite.

## Log findings and caveats

The logs contain no failed job, script parse error, or import failure that
changed a job conclusion. They do contain expected negative-control output and
diagnostic runtime noise that should remain visible in the audit:

- `verify-multiplayer-shard (3)` deliberately kills a peer. Its coordinator
  prints `ERROR: peer exited` and `FAIL`, then records the expected negative
  control as `PASS`; the surrounding smoke and job finish successfully. This is
  not a product regression.
- Several unit/fixture paths print off-tree Godot errors such as
  `Can't use get_node() with absolute paths from outside the active scene tree`,
  `Parameter "data.tree" is null`, malformed-input refusals, and unknown
  species/conversation refusals. The corresponding tests pass. These are
  exercised refusal or fixture paths, not an unhandled CI failure.
- `verify-harvest` prints repeated off-tree `get_node()`/null-tree errors while
  constructing isolated visual fixtures, plus scatter placement warnings; its
  receipt is 30 tests / 799,078 assertions / 0 failed.
- `verify-unit-tests (1)` and `(2)` finish with renderer/resource and ObjectDB
  leak diagnostics, while still reporting 0 failed tests. These are material
  cleanup caveats for future CI hygiene, not a red job in this run.
- Scatter jobs report authored-anchor placement warnings for some sparse or
  intentionally constrained anchors, but the scatter suites finish with zero
  failed assertions.
- The standard GitHub Actions Node 20 deprecation, npm `punycode`/`url.parse`
  deprecation, cache notices, and Godot dummy-renderer material warnings recur
  in the raw logs. They did not fail a job.

The `changes` job confirms the run was code-relevant; it did not take the
documentation-only skip path. This CI proves the tested commit's actual unit,
regression, contract, multiplayer, freshness and production-smoke suites. It
does not cover later uncommitted work or native visual acceptance, and the two
known-red jobs were intentionally excluded by their workflow conditions.

# CI audit — PR117 commit `d6cb7f0cbd86124a531e152f2e1dc0be788fda49`

Workflow run `34460216688` (CI run number `4665`, PR117,
`MJohnsonWellabe/Tetherbound`) completed **success**. It has 29 jobs: 26
executed jobs succeeded and three jobs were intentionally skipped by workflow
conditions: `verify-continuous-core-known-red`, `verify-gate-b-full-known-red`,
and `export`. No job was rerun and the green conclusion is not retry-derived.

All 26 executed raw logs are preserved under:

```text
.artifacts/broad-visual-0910/ci-d6c/
```

## Executed validation

The executed jobs were `changes`, the two bake-freshness jobs,
`verify-owner-regressions-shard`, `verify-combat-shard`, `verify-harvest`,
`verify-gate-b-core`, `verify-scatter-rules`, `verify-core-verb-shard`, four
unit shards, `verify-regions-shard`, `verify-veg-corridor`,
`discover-net-smokes`, `verify-gate-evidence-shard`, `verify-gate-a-ui-build-shard`,
seven multiplayer shards, and `verify-solo-regression`.

The unit shards ran code tests, not documentation-only checks:

| Job | Result |
|---|---:|
| `verify-unit-tests (1)` | 688 tests / 62,814 assertions / 0 failed |
| `verify-unit-tests (2)` | 932 tests / 376,320 assertions / 0 failed |
| `verify-unit-tests (3)` | 766 tests / 33,889 assertions / 0 failed |
| `verify-unit-tests (4)` | 817 tests / 17,785 assertions / 0 failed |
| **Unit total** | **3,203 tests / 490,808 assertions / 0 failed** |

Other explicit receipts include 38 scatter-rule tests / 1,019,854 assertions,
9 vegetation-corridor tests / 1,537,510 assertions, 30 harvest tests / 799,078
assertions, and one assertion each for scatter and terrain bake freshness. The
regions, Gate A/B core and evidence, combat, owner, core-verb, and all seven
multiplayer shards completed success. `verify-solo-regression` completed its
dependency-fence job successfully; it is not an additional test suite.

`changes` detected code-relevant changes. `discover-net-smokes` found 38
two-peer smoke files, including the required split-realm and current Water
coverage. The multiplayer jobs executed their selected production smokes and
uploaded run artifacts; they were not docs skips.

## Log findings and caveats

No executed job contains an unhandled `SCRIPT ERROR`, GDScript `Parse Error`,
or import failure that changed its conclusion. The raw logs do contain the
following material output:

- `verify-multiplayer-shard (3)` deliberately kills peer 1 in
  `smoke_net_peer_death.gd`; its coordinator prints `FAIL: ERROR: peer exited`,
  then records that condition as a passing negative control. The job continues
  and succeeds.
- Unit and fixture suites intentionally exercise malformed JSON, unknown
  conversation/species data, off-tree fixture access, and refusal paths. These
  print messages such as `Parse JSON failed`, `Can't use get_node() with
  absolute paths from outside the active scene tree`, `Parameter "data.tree"
  is null`, and `Parameter "material" is null`; their final receipts report
  zero failed assertions.
- `verify-unit-tests (1)` and `(2)` print Godot resource/ObjectDB cleanup
  diagnostics (`resources still in use at exit`). This is CI hygiene debt, not
  a red assertion in this run.
- Scatter and harvest/corridor jobs print authored-anchor placement warnings
  for constrained anchors. Their measured suites still finish with zero failed
  assertions.
- Gate/fixture output includes expected `EARNED ... FAIL` and `CLOUDREACH
  CONTINUOUS ... FAIL` messages from unavailable or deliberately negative
  harness paths; the surrounding jobs finish success. These strings must not
  be treated as an unhandled job failure without their receipt context.
- Smoke wrappers show configured per-test attempt budgets, but the preserved
  logs show no second workflow attempt and no workflow rerun. A gate evidence
  physical-launch check and a multiplayer catch path perform their own stated
  in-test retries and still pass.
- GitHub Action Node 20 deprecation notices, npm `punycode`/`url.parse`
  deprecations, cache notices, and dummy-renderer material warnings recur in
  raw logs. They did not fail a job.

This CI proves the tested commit's unit, regression, freshness, multiplayer,
and production-smoke suites. It does not cover later uncommitted work or native
visual acceptance; the three conditional skips above remain outside this green
result.

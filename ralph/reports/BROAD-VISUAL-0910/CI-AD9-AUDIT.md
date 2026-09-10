# CI audit — PR117 commit `ad9ed5378ae13934bbef28af3b43ff68b8ab5ce7`

Workflow run `34464224986` (CI run number `4666`, PR117,
`MJohnsonWellabe/Tetherbound`) completed **success**. It has 29 jobs: 26
executed jobs succeeded and three jobs were intentionally skipped by workflow
conditions: `verify-gate-b-full-known-red`, `verify-continuous-core-known-red`,
and `export`. No job was rerun.

All 26 executed raw logs are preserved under:

```text
.artifacts/broad-visual-0910/ci-ad9/
```

## Executed validation

The executed jobs were `changes`, both bake-freshness jobs, harvest,
scatter-rules, vegetation-corridor, four unit shards, combat, net-smoke
discovery, Gate A/B/core/evidence, owner regressions, regions, core verbs,
seven multiplayer shards, and solo regression.

The unit shards ran code tests rather than documentation-only checks:

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
regions, Gate A/B, combat, owner, core-verb, and all seven multiplayer shards
completed success. `verify-solo-regression` completed its dependency-fence job;
it is not an additional test suite. `changes` detected code-relevant changes,
and `discover-net-smokes` found the required 38 two-peer smoke files.

## Material log caveat

The workflow conclusion is green, but the raw logs contain **three uncaught
GDScript errors** in two executed jobs:

- `verify-gate-a-ui-build-shard` (`job-102829378974`) at 10:11:02 and 10:13:17
  UTC.
- `verify-core-verb-shard` (`job-102829379117`) at 10:10:48 UTC.

Each has the same backtrace:

```text
SCRIPT ERROR: Trying to assign invalid previously freed instance.
_prompt_belongs_to_combat (res://scripts/ui/playground_hud.gd:3603)
_recall_prompt_is_already_present (res://scripts/ui/playground_hud.gd:3724)
_update_exploration_legend (res://scripts/ui/playground_hud.gd:3694)
```

The affected smoke sequences continued and their jobs reported success, so
these errors are not represented by the job conclusion or assertion totals.
They are material runtime defects in the tested commit and should be fixed or
explicitly dispositioned before treating this CI as error-clean.

Other observed output was expected or non-blocking:

- `verify-multiplayer-shard (3)` deliberately kills a peer; its `ERROR: peer
  exited` / `FAIL` is recorded as a passing negative control.
- Unit and fixture tests intentionally print malformed-JSON/refusal errors,
  off-tree access errors, null-tree/material diagnostics, and other negative
  control messages while ending with zero failed assertions.
- Unit, combat, regions, and UI logs report Godot resources still in use at
  exit; scatter, harvest, and corridor jobs report constrained-anchor placement
  warnings.
- GitHub Actions Node 20, npm `punycode`/`url.parse`, cache, and dummy-renderer
  notices recur. They did not change job conclusions.
- Smoke wrappers show configured per-test attempt budgets, but no second
  workflow attempt or workflow rerun was observed. In-test negative controls
  and stated physical-launch retries are reported in their own receipts.

This CI covers the pushed commit's unit, regression, freshness, multiplayer,
and production-smoke suites. It does not cover later uncommitted work or native
visual acceptance. The three conditional skips remain outside this result, and
the three freed-instance script errors mean the green workflow is not a clean
runtime-error result.

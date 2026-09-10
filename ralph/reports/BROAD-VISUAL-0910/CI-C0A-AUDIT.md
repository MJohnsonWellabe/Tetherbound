# CI audit — PR117 / c0a4d243b0437adc73bd47ecf21fde749e92b692

Repository: MJohnsonWellabe/Tetherbound
Workflow run: 34447522002 (run attempt 1, completed, success)
Run number: 4663
Raw logs: .artifacts/broad-visual-0910/ci-c0a/ (26 executed-job logs)

## Verdict

This replacement run is a real code-validation run and passed at the workflow level. Twenty-six jobs executed successfully; three conditional jobs were skipped. The four unit shards report 3,202 tests and 490,800 assertions with zero failures. Terrain and scatter bake freshness checks passed.

## Executed jobs

All 26 executed jobs concluded completed/success:

- changes
- verify-harvest — 30 tests, 799,078 assertions, 0 failed
- verify-terrain-bake-freshness — 1 test, 1 assertion, 0 failed
- verify-veg-corridor — 9 tests, 1,537,510 assertions, 0 failed
- verify-scatter-rules — 38 tests, 1,019,854 assertions, 0 failed
- verify-scatter-bake-freshness — 1 test, 1 assertion, 0 failed
- verify-unit-tests (4) — 817 tests, 17,785 assertions, 0 failed
- verify-combat-shard — combat checks passed; scaling reports 66 assertions, 0 failures
- verify-unit-tests (2) — 932 tests, 376,320 assertions, 0 failed
- verify-gate-a-ui-build-shard
- verify-gate-evidence-shard
- verify-unit-tests (3) — 766 tests, 33,889 assertions, 0 failed
- discover-net-smokes
- verify-core-verb-shard
- verify-owner-regressions-shard
- verify-gate-b-core
- verify-regions-shard
- verify-unit-tests (1) — 687 tests, 62,806 assertions, 0 failed
- verify-multiplayer-shard (1), (2), (3), (4), (5), (6), (7)
- verify-solo-regression

All listed steps in these jobs completed successfully.

## Skipped jobs

- verify-continuous-core-known-red
- verify-gate-b-full-known-red
- export

The known-red jobs provide no validation in this run, and export packaging was not checked.

## Error, retry, and negative-control audit

No smoke wrapper recorded a second attempt or an emitted failed-on-attempt line. Import checks ran without an actual SCRIPT ERROR, parse failure, failed-load, or ERROR: Cannot open result.

Raw logs contain expected fixture diagnostics: malformed JSON, unscoped flags, missing scene-tree context, and the intentional multiplayer peer-death negative control. Successful gameplay smokes continue to emit null-material diagnostics, combat adopt_starter is not a swap diagnostics, and repeated Godot shutdown resource/RID leak messages. The regions shard reports the expected smoke_relay_gate unscoped-flag diagnostic. Node action deprecation and cache setup/cleanup warnings are infrastructure caveats. None changed a job conclusion or produced a failed assertion.

This run validates the retained Water state/current payoff head at the CI level. Local uncommitted Cloudreach geology/labels/helper/new-texture changes were not part of this run.

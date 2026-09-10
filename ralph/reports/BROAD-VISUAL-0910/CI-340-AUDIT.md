# CI audit — PR117 / 340d7287c7b49cef722bb68a8de8ff4c354af361

Repository: MJohnsonWellabe/Tetherbound
Workflow run: 34442439915 (run attempt 1, completed, success)
Run number: 4662
Raw logs: .artifacts/broad-visual-0910/ci-340/ (26 executed-job logs)

## Verdict

This replacement run is a real code-validation run and passed at the workflow level. Twenty-six jobs executed successfully; three conditional jobs were skipped. The four unit shards report 3,198 tests and 490,749 assertions with zero failures. Terrain and scatter bake freshness checks also passed.

## Executed jobs

All 26 executed jobs concluded completed/success:

- changes
- verify-scatter-rules — 38 tests, 1,019,854 assertions, 0 failed
- verify-terrain-bake-freshness — 1 test, 1 assertion, 0 failed
- verify-scatter-bake-freshness — 1 test, 1 assertion, 0 failed
- verify-harvest — 30 tests, 799,078 assertions, 0 failed
- verify-veg-corridor — 9 tests, 1,537,510 assertions, 0 failed
- verify-unit-tests (1) — 683 tests, 62,755 assertions, 0 failed
- verify-combat-shard — combat checks passed; scaling reports 66 assertions, 0 failures
- verify-unit-tests (4) — 817 tests, 17,785 assertions, 0 failed
- verify-unit-tests (2) — 932 tests, 376,320 assertions, 0 failed
- verify-gate-evidence-shard
- verify-unit-tests (3) — 766 tests, 33,889 assertions, 0 failed
- verify-gate-a-ui-build-shard
- verify-gate-b-core
- verify-owner-regressions-shard
- verify-regions-shard
- verify-core-verb-shard
- discover-net-smokes
- verify-multiplayer-shard (1), (2), (3), (4), (5), (6), (7)
- verify-solo-regression

## Skipped jobs

- verify-continuous-core-known-red
- verify-gate-b-full-known-red
- export

The known-red jobs provide no validation in this run, and export packaging was not checked.

## Error, retry, and negative-control audit

No smoke wrapper recorded a second attempt or an emitted failed-on-attempt line. Import checks ran without an actual SCRIPT ERROR, parse failure, failed-load, or ERROR: Cannot open result.

Raw logs do contain expected fixture diagnostics: malformed JSON, unscoped flags, missing scene-tree context, and the intentional multiplayer peer-death negative control. Successful gameplay smokes continue to emit null-material diagnostics, the combat adopt_starter is not a swap diagnostic, and repeated Godot shutdown resource/RID leak messages. The regions shard reports the expected smoke_relay_gate unscoped-flag diagnostic. Parallel cache setup/cleanup warnings and Node action deprecation warnings are infrastructure caveats. None changed a job conclusion or produced a failed assertion.

This run is a clean replacement for the prior road-visibility failure at the workflow/test level.

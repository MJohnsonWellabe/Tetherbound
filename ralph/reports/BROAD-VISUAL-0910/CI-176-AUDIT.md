# CI audit — PR117 / 176b17638c81d61fe0664a81e1b3f44d5b533e52

Repository: MJohnsonWellabe/Tetherbound
Workflow run: 34435358237 (run attempt 1, completed, failure)
Run number: 4660
Raw logs: .artifacts/broad-visual-0910/ci-176/ (26 files, one per executed job)

## Verdict

This was a real code-validation run. Twenty-six jobs executed; twenty-five concluded success and one failed. Three conditional jobs were skipped. The material blocker is two Stormwood authored-anchor unit-test failures in verify-unit-tests (2), job 102739521309.

The suspected Stormwood settlement bake fingerprint mismatch was not observed: verify-terrain-bake-freshness and verify-scatter-bake-freshness both passed, including their freshness checks. The failure is authored NPC/trainer anchor grounding.

## Failed job

verify-unit-tests (2), Run tests:

    865 tests, 365192 assertions, 2 failed
    FAIL test_stormwood_npcs_data.gd :: test_every_npc_has_an_actual_surface_contact_and_key_anchors_hold
      trader_oswin expected 46.611389 +/- 0.010000, got 45.830000
      elder_maud expected 57.585462 +/- 0.010000, got 57.572500
    FAIL test_stormwood_trainers_data.gd :: test_anchors_are_unique_grounded_and_near_authored_routes
      traveller_ivo_lantern_pools expected 33.981319 +/- 0.010000, got 34.140000
      rodfolk_guard_bram expected 57.470444 +/- 0.010000, got 57.489400

The step exited with code 1. No retry or workflow rerun was performed.

## Passing executed jobs

These jobs concluded completed/success and their validation steps ran:

- changes
- verify-scatter-rules — 38 tests, 1,019,854 assertions, 0 failed
- verify-scatter-bake-freshness — passed
- verify-veg-corridor — 9 tests, 1,537,510 assertions, 0 failed
- discover-net-smokes
- verify-gate-a-ui-build-shard
- verify-harvest — 30 tests, 799,078 assertions, 0 failed
- verify-core-verb-shard
- verify-combat-shard — combat smokes passed; 66 scaling assertions, 0 failures
- verify-gate-evidence-shard
- verify-regions-shard — all listed region/streaming/art steps passed
- verify-terrain-bake-freshness — passed, including terrain bake freshness and initialized mipmaps
- verify-gate-b-core
- verify-unit-tests (3) — 811 tests, 24,829 assertions, 0 failed
- verify-unit-tests (4) — 770 tests, 42,477 assertions, 0 failed
- verify-unit-tests (1) — 741 tests, 58,183 assertions, 0 failed
- verify-owner-regressions-shard
- verify-multiplayer-shard (1) through (7) — all net-smoke steps passed and artifacts uploaded
- verify-solo-regression

The three passing unit shards total 2,322 tests and 125,489 assertions with zero failures. Including the failed shard, the unit suite ran 3,187 tests and 490,681 assertions with two failures.

## Skipped jobs

- verify-gate-b-full-known-red
- verify-continuous-core-known-red
- export

The known-red jobs provide no validation in this run, and export packaging was not checked.

## Error, retry, and negative-control audit

No smoke wrapper emitted a real failed-on-attempt line or ran a second attempt. Observed wrappers were first attempts only; RETRIES values are allowances.

No actual SCRIPT ERROR, parse failure, or failed-load import diagnostic was emitted by the import checks. Logs contain expected test-fixture diagnostics, including deliberate earned-segment FAIL messages, invalid JSON/flags, and missing live-tree context, while the relevant tests complete as intended. Godot teardown logs continue to report resource/RID leaks; successful gameplay smokes still emit occasional null-material and similar diagnostics. The regions lifecycle probe intentionally exercises failure/rollback paths. Multiplayer shard (3) includes the intentional peer-death negative control. Parallel cleanup also reports cache-key reservation contention. These are follow-up caveats; the authored-anchor failures above are the CI blockers for this head.

## Fix prepared after this audit

The four authored Y values were updated to the exact canonical terrain-grounded values reported by the failing tests, with X/Z and all other NPC/trainer fields unchanged:

- trader_oswin: 45.830000 -> 46.611389
- elder_maud: 57.572500 -> 57.585462
- traveller_ivo_lantern_pools: 34.140000 -> 33.981319
- rodfolk_guard_bram: 57.489400 -> 57.470444

This is a source-data correction only. The settlement bake/fingerprint checks had already passed, and these NPC/trainer files are not scatter sources. Root then ran `stormwood-authored-anchor-correction-first` at 04:29:25–04:29:28 UTC: both affected suites passed, five tests and 665 assertions, exit 0 without engine errors. Replacement complete CI is still required.

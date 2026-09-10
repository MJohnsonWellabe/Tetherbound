# CI audit — PR117 / 4d3a69b7f13097f078d97cd07394fda5ec24767c

Repository: MJohnsonWellabe/Tetherbound
Workflow run: 34439181372 (run attempt 1, completed, failure)
Run number: 4661
Raw logs: .artifacts/broad-visual-0910/ci-4d3/ (26 executed-job logs, 9.28 MB)

## Verdict

This was a real code-validation run. Twenty-six jobs executed: twenty-five passed and one failed. Three conditional jobs were skipped. The first/material blocker is verify-unit-tests (2), job 102750776184.

The failed shard ran 896 tests and 367,744 assertions. One test failed with three reported route checks:

    FAIL test_road_creature_visibility.gd :: test_every_critical_route_has_two_forward_visible_creatures_at_every_sample
    expected 0, got 2 (stormwood/deepwood_road has failing 10m samples)
    2 samples were empty over the 20m run

This is a real code/data validation failure, unrelated to the prior authored NPC/trainer Y correction. No retry or workflow rerun was performed.

## Passing executed jobs

- changes
- verify-veg-corridor
- verify-unit-tests (3) — 826 tests, 25,317 assertions, 0 failed
- verify-scatter-rules — 38 tests, 1,019,854 assertions, 0 failed
- verify-terrain-bake-freshness — passed
- verify-gate-evidence-shard
- verify-harvest — 30 tests, 799,078 assertions, 0 failed
- verify-combat-shard — combat smokes passed; scaling reports 66 assertions, 0 failures
- verify-unit-tests (4) — 730 tests, 24,109 assertions, 0 failed
- verify-unit-tests (1) — 740 tests, 73,543 assertions, 0 failed
- verify-gate-b-core
- verify-scatter-bake-freshness — passed
- verify-gate-a-ui-build-shard
- discover-net-smokes
- verify-owner-regressions-shard
- verify-regions-shard
- verify-multiplayer-shard (1), (2), (3), (4), (5), (6), (7)
- verify-solo-regression (final job 102753983013)

All listed steps in these jobs completed successfully. The three passing unit shards total 2,296 tests and 122,969 assertions with zero failures. Including the failed shard, the unit suite ran 3,192 tests and 490,713 assertions with one failed test.

## Skipped jobs

- verify-gate-b-full-known-red
- verify-continuous-core-known-red
- export

The known-red jobs provide no validation in this run, and export packaging was not checked.

## Error, retry, and negative-control audit

No smoke wrapper recorded a second attempt or an emitted failed-on-attempt line. Import checks ran and did not emit SCRIPT ERROR, parse failure, failed-load, or ERROR: Cannot open diagnostics.

The logs contain expected fixture diagnostics: malformed JSON/unscoped flags, missing scene-tree context, deliberate earned-segment FAIL messages, and the intentional multiplayer peer-death negative control. Successful gameplay smokes still emit recurring null-material diagnostics and Godot shutdown resource/RID leaks. Parallel jobs report cache-key reservation contention. These are follow-up caveats; the route creature visibility failure is the material blocker for this commit.

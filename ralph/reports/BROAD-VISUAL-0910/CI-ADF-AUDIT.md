# CI audit — PR117 / adf8e4d97eb5a1bf1fd8f2bd4af34f851e95b210

Repository: MJohnsonWellabe/Tetherbound
Workflow run: 34432804989 (run attempt 1, completed, failure)
PR: 117, branch codex/broad-visual-pass-0910
Raw logs: .artifacts/broad-visual-0910/ci-adf/ (one file per executed job)

## Verdict

This was a real code-validation run. Twenty-six jobs executed; twenty-five concluded success and one failed. Three conditional jobs were skipped. The failure is actionable and comes from a unit test, not a documentation-only or infrastructure-only result.

Failed job: verify-unit-tests (3), job 102731975906. Its Run tests step exited 1:

    799 tests, 32470 assertions, 1 failed
    FAIL test_texture_import_policy.gd :: test_every_runtime_3d_texture_uses_vram_compression
    expected true, got false
    assets/creatures/tetherbound/voltarach/models/voltarach_extracted_base_color_alpha.png.import

The log says the runtime 3D texture must be fully reimported with VRAM Compressed (mode 2), and suggests tools/art_pipeline/texture_import_policy.py --apply. No retry or workflow rerun was performed.

## Passing executed jobs

The following 25 jobs concluded completed/success and show their validation steps and final success markers:

- changes
- verify-harvest — 30 tests, 799,078 assertions, 0 failed
- verify-terrain-bake-freshness — 1 test, 1 assertion, 0 failed
- verify-veg-corridor — 9 tests, 1,537,510 assertions, 0 failed
- verify-scatter-bake-freshness — 1 test, 1 assertion, 0 failed
- verify-unit-tests (4) — 796 tests, 33,697 assertions, 0 failed
- verify-scatter-rules — 38 tests, 1,019,854 assertions, 0 failed
- verify-unit-tests (2) — 915 tests, 357,741 assertions, 0 failed
- verify-gate-a-ui-build-shard — all listed smoke steps completed successfully with OK/PASS markers
- verify-combat-shard — all listed combat smokes completed; explicit OK/PASS markers and 66 scaling assertions with 0 failures
- verify-unit-tests (1) — 672 tests, 64,917 assertions, 0 failed
- verify-core-verb-shard — all listed verb smokes completed with OK/PASS markers
- verify-gate-b-core — continuous gate path completed with OK marker
- verify-gate-evidence-shard — all listed evidence smokes completed with OK/PASS markers
- discover-net-smokes — discovery completed successfully
- verify-owner-regressions-shard — all listed owner regressions completed with OK/PASS markers
- verify-regions-shard — all 34 listed region/streaming/art steps completed successfully
- verify-multiplayer-shard (1), (2), (3), (4), (5), (6), (7) — all net-smoke steps and artifact uploads completed successfully
- verify-solo-regression — solo regression fence completed successfully

## Skipped jobs

- verify-gate-b-full-known-red
- verify-continuous-core-known-red
- export

The skipped known-red jobs do not provide their validation, and export packaging was not checked.

## Error, retry, and negative-control audit

No smoke wrapper emitted a real failed-on-attempt line or ran a second attempt. All observed smoke groups were attempt 1/1 or attempt 1/N. RETRIES values are allowances only.

No import check emitted an actual SCRIPT ERROR, parse failure, failed load, or ERROR: Cannot open. Raw logs do contain the shell grep source lines for those checks.

Expected test-fixture diagnostics appear in unit logs (malformed JSON, unscoped flags, missing scene-tree context), and their assertions pass. Godot shutdown logs repeatedly report resources/RID/page leaks. Several successful gameplay smokes emit null material diagnostics; combat also emits adopt_starter is not a swap. The regions lifecycle probe intentionally exercises Water realm timeout/rollback and records its checks as passed. Multiplayer shard (3) intentionally kills a peer; process-not-found errors are part of the expected negative control. Cache-save contention messages also appear during parallel cleanup. These are caveats to follow up, while the texture import policy failure is the material CI blocker for this commit.

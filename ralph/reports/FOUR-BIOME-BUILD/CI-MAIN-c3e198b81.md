# Main c3e CI — failed reconnect watchdog transition

[Run34401138071](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34401138071)
finished failure on attempt1, 2026-09-09 20:27:23–21:13:25 UTC including queue
time. All29 jobs were inspected:26 passed, multiplayer shard4 failed, and two
known-red full-route jobs were skipped. The sole failed step was Run net smokes
in shard4. All27 executed-job raw logs,10,302,170 bytes, are preserved in
`.artifacts/main-c3e198b81-ci/`, with complete diagnostic comparisons.

The four unit shards passed3148 tests/488076 assertions. All38 network smokes
were invoked once;37 passed and reconnect_keeps_character failed. There was no
retry.310 known native diagnostic lines and zero SCRIPT ERROR lines remain;
error-class comparison against PR108 shows shutdown-count variation. The
reconnect FAIL receipts are a separate real failure and are not erased by this
native-error comparison.

Export passed its native packaged-ground check: terrain present, ground0.90,
player2.90, props383004. This does not make the overall run green.

The reconnect artifact shows a successful production rejoin followed7ms later
by a false silence verdict against the stale pre-build heartbeat. Diagnosis,
artifact receipts and the focused correction are recorded in
`MAIN-C3E-RECONNECT-WATCHDOG-0909.md`. PR111 proposes that correction; neither
its focused regression nor earlier PR passes supersede this failed run.

# Main 5d564d175 CI — passed on attempt 1

[Run34390274327](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34390274327) verified PR103's main landing `5d564d175e81f2091fcd655514853b393020c489`, 2026-09-09 18:38:46–19:04:05 UTC. All27 executed jobs and their steps succeeded; two explicitly known-red full-route jobs were skipped. All27 complete raw logs (10,640,936 bytes), metadata and comparisons are retained in `.artifacts/main-5d564d175-ci/`.

Four unit shards: 3,146 tests, 488,022 assertions, zero failures. All38 network smokes ran once with attempt1/1. The equipment controller flow passed26 checks. Export found terrain, ground0.90, player2.90 and383,004 props.

Full-log comparison against the reviewed PR103 run retains existing native diagnostic classes and varying shutdown resource counts, including3/4/5 resources at exit. No new non-shutdown error class appeared. This is not an error-free-log claim. Main production contents match the reviewed PR103 tree plus PR105 documentation, verified at landing.

The superseding d3cdb57 main has its own CI34390358648 in progress. The intermediate 5d release was superseded/cancelled; the final d3 release is separately verified. No campaign or Beta acceptance follows from these regression jobs.

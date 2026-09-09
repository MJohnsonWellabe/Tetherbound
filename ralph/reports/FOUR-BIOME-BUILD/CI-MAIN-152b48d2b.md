# Reconnect main CI — passed on attempt 1

[Run 34396402668](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34396402668) verified main `152b48d2bf66e3e5efb6066cbeea68f09bb4a6a3`, 2026-09-09 19:39:52–20:07:03 UTC. All27 executed jobs and steps succeeded; two explicitly known-red full-route jobs were skipped. All27 full raw logs (10,631,275 bytes), metadata and comparison are retained under `.artifacts/main-152b48d2b-ci/`.

The four unit shards passed3148 tests and488076 assertions. All38 network smokes ran on invocation1/1, with no failed invocation/retry. Full-log comparison against PR106 retained known native diagnostic classes and varying shutdown-resource counts. There were no SCRIPT ERROR lines or new non-shutdown error classes;307 native error lines remain, so this is not an error-free-log claim. Export passed.

The source tree matches the reviewed reconnect PR exactly. Release/publication of this same main is separately verified in `RELEASE-MAIN-152b48d2b.md`. The superseding terrain main e231897f4 has separate CI34397173524 pending; no campaign or Beta acceptance follows from these regression jobs.

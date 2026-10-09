The regional-body candidate does not satisfy the performance criterion. Both matched Tidewake AFTER repeats miss 60 mean fps and P99 <=33ms. Variability between repeats precludes a causal speedup claim. All five executed cases pass native measurement, raw-error, route-completion and PNG structure checks; ROOT independently verified them. Three unchanged Meadows repeats were cancelled after the second candidate performance failure. The intended eight-case matrix is incomplete.

Actual BEFORE package source is 785e6f612e28a77075dd66684047628c2affbb13, with runtime/data/assets/export settings verified equivalent to main 6add9d5f9b9f490bf8a77783d3afa21474cdb50d. Actual AFTER source is 9d513c981830e9760e5fccc20dd4755e7003eab2: main plus only six D files. Both packages use the same engine, extension and canonical QUIET measurement shim, Forward+ Medium, 1920x1080, uncapped with vsync disabled, fresh paired userdata, >=15s warmup and >=60s timed samples. Nearest-rank percentiles use wall_ms; process/physics/render/setup/GPU means overlap and must not be added.

The failed candidate changed regional_collision_enabled from absent/default false to true and introduced build_budget_ms=8.0. This commit restores all six candidate source/config/test paths to current main. Earlier candidate commits, packages, functional proofs, failed attempts and native images remain preserved. The branch now has no production or config difference from the cited main. There is no READY, mainlanding, performance acceptance or visual verdict.

Raw route samples, launch metadata and all three logs for each executed case are committed here. Native image paths and hashes remain in the receipts; the images are benchmark evidence and have not been submitted as visual acceptance. The native lease was explicitly handed to E after all D engines exited. A later D lease is needed for the separately described GPU-pass/native-actor attribution problems.
| Case | Mean fps | P95 wall ms | P99 wall ms | Process ms | Physics ms | Render CPU ms | Setup CPU ms | GPU ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| BEFORE water r1 | 33.91 | 50.036 | 74.255 | 24.814 | 15.882 | 1.388 | 0.241 | 21.992 |
| BEFORE water r2 | 24.82 | 84.855 | 131.703 | 24.909 | 14.987 | 1.380 | 0.235 | 22.093 |
| BEFORE meadows r1 | 42.80 | 32.274 | 39.202 | 27.878 | 8.200 | 2.398 | 0.677 | 22.298 |
| AFTER water r1 | 27.56 | 63.161 | 106.870 | 19.646 | 14.268 | 1.373 | 0.240 | 22.042 |
| AFTER water r2 | 35.82 | 39.180 | 72.307 | 18.656 | 16.459 | 1.384 | 0.239 | 22.138 |

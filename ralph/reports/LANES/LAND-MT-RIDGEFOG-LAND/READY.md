# READY: tb/land-mt-ridgefog-land

STATUS: land. Correctness fix, no flag, no score claimed.

**What.** The Meadows ridge backdrop copied the scene fog on a 0.5 s poll (`horizon_ranges.gd`). After a time jump the ridge kept the previous hour's haze for up to half a second. The route capture tool pins the hour and shoots about 0.2 s later on a GPU, so a day frame taken right after a golden-hour frame could show the mountains as a flat tan sheet (G-things-redleaf, stronghold route_day: 7.73 on the clean boot, 5.14 on the tan one). The fog is now compared every frame and copied the frame it changes.

**Files.** `scripts/world/horizon_ranges.gd`, `tests/test_meadows_ridge_vl.gd` (new pin test `test_ridge_fog_follows_the_environment_without_delay`).

**Tests run.** `tests/run_tests.gd --only=test_meadows_ridge_vl.gd`: 4 tests, 20 assertions, 0 failed (headless, CPU container).

**Not shown.** The tan state itself was not reproduced here: CPU frames take longer than the old poll, so it only appears on a GPU. A High re-shoot of stronghold route_day after a golden-hour frame confirms it.

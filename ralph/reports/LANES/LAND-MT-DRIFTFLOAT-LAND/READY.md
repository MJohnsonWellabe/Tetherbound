# READY: tb/land-mt-driftfloat-land

STATUS: land. Correctness fix with a test; no score claimed.

**What.** Current-lane drift floaters (`scripts/world/water_current_drift_markers.gd`) travel a straight line between a lane's end points, with a lateral spread, always at sea level plus 0.05 m. They never checked the ground. Where a lane's band crosses a beach, a log either sinks into the sand or hovers over wet sand beside the dune.

That is the "mossy log floating in the sky" the judges named 3/3 on the Venn fight t-000 frames. GPU lane frame: `tb/gpu-frames-1113` 11b4d9f0e, `G-venn-floating-log`, camera A. The model in the crop is the Meshy driftwood these floaters use, and the nearest floaters sit about 20 m from camera A.

**Change.** A floater shows only where the water under it is at least `min_depth_m` deep (0.4 by default; optional key `current_flow.drift_markers.min_depth_m`). Elsewhere it is hidden and keeps travelling, so a lane's spacing is unchanged. Presentation only: no collision, physics, save or network state.

**Tests.**
- `tests/run_tests.gd --only=test_drift_markers_afloat.gd`: 3 tests, 6 assertions, 0 failed.
- `--only=test_water_restored_sea.gd` (the other drift-marker test): 2 tests, 11 assertions, 0 failed.

**By-eye for the GPU lane.** Venn t-000 at camera A: no log at the top left.

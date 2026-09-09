# Aim readiness fix — 2026-09-08

Branch `codex/four-biome-audit-resume-0908`. This is a test-driver repair only.
No production aim, camera or combat file changed.

## Result

The opening driver no longer treats one instantaneous camera angle as launch
readiness. When the camera angle or current production verdict becomes a candidate,
the helper releases the physical right stick, waits for the camera's real process
callbacks, then waits for the throw system's physics callbacks and physics-owned
verdict. It uses zero-duration SceneTree timers because the bare `process_frame` and
`physics_frame` signals fire before node callbacks. A failed transient
sample resumes ordinary right-stick steering inside the original 12s/8s deadline.
No retry, timeout, angular window, launch budget or tolerance increased.

The fresh helper extends that readiness check with all existing launch conditions:
`launch_assist_diagnostics().eligible`, an active aiming state, a nonempty refreshed
preview and `trajectory_blocked == false`. It reads them again synchronously at the
actual physical Interact dispatch boundary. The terminal check remains strict and
reports failure before an orb can be spent.

The earned helper now prints read-only `AIM READINESS` receipts at the angular
candidate (`convergence`), after the camera/physics callbacks (`post-settle`) and
at the synchronous physical input boundary (`input-commit`). Each includes camera
position/forward, player and live-target positions, current launch diagnostics and
the preview. Repeated identical samples are suppressed; changed facts are retained.

## Focused native evidence

Command (with isolated APPDATA and Godot 4.7):

`$env:APPDATA='C:\Projects\Tetherbound\.artifacts\aim-readiness-appdata'; & 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tools/aim_readiness_regression.gd`

Final receipt: `.artifacts/aim-readiness-regression-post-callback.log`, exit 0,
24 checks, zero failures and no engine errors. The tiny fixture has no Terrain3D
or save. Its instrumented production-aim subclass also verifies `_tick_aiming`
completed after look release before readiness returned in every positive case.

- Pre-settle follow: moved the player 6m while the previously centred camera still
  occupied its old follow pose. Released-look convergence resumed, the final current
  verdict was eligible, preview clear, and the actual Interact commit logged
  `eligible=true`, `reticle=1.016/1.360`; release retained `assist=true`.
- Stationary control: actual Interact commit logged `eligible=true`,
  `reticle=0.000/1.360`; release retained `assist=true`.
- Moving target: a real `_process` target moved at 0.35m/s while the production rig
  was steered through physical pad events. Actual Interact commit logged
`eligible=true`, `reticle=0.046/1.360`; release retained `assist=true`.
- Blocked line: a real physics blocker crossed the launch path. The helper refused
  readiness through the bounded one-second convergence, the refreshed production
  preview reported obstruction, and the spend counter remained zero.

The first run is preserved in `.artifacts/aim-readiness-regression.log`: seven
failures. All readiness cases passed, but the fixture inspected spend before the
production 0.18s release windup completed, and its blocker sat below the measured
arc. The repair changed only the fixture observation wait and blocker placement.
It did not tune the driver. The corrected intermediate run is
`.artifacts/aim-readiness-regression-v2.log` (18 checks, zero failures).

The same final regression has a `--legacy-readiness` mode that substitutes the
former immediate angular-success return while leaving the production rig, aim,
input and assertions unchanged. `.artifacts/aim-readiness-regression-legacy.log`
exits 1 as required: readiness returned without a post-release physics refresh,
then the actual Interact commit logged `eligible=false`, `reticle=5.209/1.360`,
`reason=reticle_outside_body`; release logged `assist=false`. The two named
assertion failures are the missing refresh and eligibility failing at actual commit.

## Named checks

- `tests/run_tests.gd -- --only=test_fresh_opening_target.gd`:
  `.artifacts/aim-readiness-fresh-target-tests.log`, exit 0, 5 tests, 21 assertions,
  zero failed.
- `tests/run_tests.gd -- --only=test_camera_aim_response.gd`:
  `.artifacts/aim-readiness-camera-tests.log`, exit 0, 10 tests, 35 assertions,
  zero failed. Its existing three ObjectDB leak warning remains; no test failed.
- `tools/aim_readiness_regression.gd`: exit 0, 24 checks, zero failures.
- `tools/aim_readiness_regression.gd -- --legacy-readiness`: exit 1, 7 checks,
  two expected named readiness-race failures.

`smoke_throw_preview_occlusion.gd` was not required because no production preview
integration changed. The new regression itself inherits its production physics
fixture and adds actual helper input/commit coverage.

## Scope and remaining evidence

No HP, item or progression state was injected; no save was copied; no launch or
camera transform is directly changed in an earned path. The native fixture creates
poses only to isolate the timing race. It does not prove a campaign or gameplay gate.

The one changed genuine fresh-campaign attempt required by the implementation brief
is pending root review and the full-world RAM lease. A request was sent after all
focused checks passed. No full world was launched without that grant.

Prepared command source is the existing
`.artifacts/run-wave6-fresh-final-verdict.ps1`, with a new never-before-used isolated
APPDATA/output stem for the approved attempt. It invokes
`tests/smoke_four_biome_continuous.gd` directly and fingerprints owner saves before
and after. The old profile/output stem will not be reused.

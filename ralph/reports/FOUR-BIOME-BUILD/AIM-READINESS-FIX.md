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

Root reviewed the regression and granted exactly one changed genuine fresh-campaign
attempt after the Meadows process released the exclusive 8GB-machine RAM lease. The
run used the new `wave7-aim-readiness-fresh-profile`, invoked the unchanged default
`tests/smoke_four_biome_continuous.gd` directly, and fingerprinted owner saves before
and after. Exact Godot command:

`Godot_v4.7-stable_win64_console.exe --headless --path C:\Projects\Tetherbound --log-file C:\Projects\Tetherbound\.artifacts\wave7-aim-readiness-fresh-engine.log --script tests/smoke_four_biome_continuous.gd`

The single run did not reach aim. `.artifacts/wave7-aim-readiness-fresh.log` records:

- `+0.09s` title interactive;
- `+0.12s` character choice answered;
- `+4.53s` new game world entered;
- then `Parameter "mem" is null`, `mem_new is null`, and signal 11 at
  `map_baker.gd:192`, through `bake_cached`,
  `playground_hud._ensure_minimap_baked`, `_run_frame`, `_process`.

The native process remained after its crash handler, so the exact crashed PIDs were
stopped to finish collection. Wrapper terminal exit was -1. No Godot process remained
and the before/after owner-save fingerprints were byte-identical. At the post-crash
observation the console wrapper held about 0.14MB and the crashed child about 20.3MB;
that is not a useful peak-memory measurement. This is a different full-world failure
class and supplies no fresh aim or campaign acceptance evidence. Per the one-attempt
grant, it was preserved and not rerun.

## Allocation preflight follow-up

`ALLOCATION-DIAGNOSIS.md` correlates that crash with Windows system commit at
99.56% and 1,357 processes; its isolated production-size map bake passes. A later
live census found 846 concurrent Git no-index/diff processes enumerating the large
untracked `.artifacts` tree. Root installed a local exclude and the process count
recovered. The durable narrow prevention adds anchored `/.artifacts/` to
`.gitignore`; it does not ignore reports or source and removes no evidence payload.

Pre-world census after recovery: 2 Git processes using 2.2MB private total,
252 total processes, 10.31/22.67GB system commit, 2696MB available physical memory,
and no Godot process. `git check-ignore -v` identifies `/.artifacts/` for a local
artifact, while the tracked report and regression source remain unignored.

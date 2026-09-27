# F10#3 strike motion capture: context for the lane lead (do not give to the judge)

## Builds
- Primary build (origin/main): `4316362e26ed78589551ccf61de9c66974bc91c6`.
- Rendered SHA (tb/vis = main + the VIS tool only): `07695fc114cb5d42015a9e4b28e56e08f9b7e73e`
  (`git merge-base --is-ancestor 4316362e… 07695fc1…` is true). The only new file is
  `tools/vis_capture_strike_motion.gd`. No game code, config or other tool changed.
- render.yml was dispatched on `main`. The workflow runs record main head `4316362e` (seqA) and
  `4ee9f415766df881cbcf9756415efc713becca65` (seqB/seqC; main moved during the session). That is
  only the version of render.yml; the checked-out code is `07695fc1` in all three.

## Runs (render.yml, mode=render, xvfb + opengl3 software GL, 1920x1080, all exit 0)
| Seq | Run ID | Artifact | Args |
|---|---|---|---|
| A | 36310845684 | render-vis-f10-3-seqA-36310845684 | `--motion=normal --hours=12 --out=res://shots/vis_f10_3_motion/seqA --label=seqA --only=quick` |
| B | 36312800214 | render-vis-f10-3-seqB-36312800214 | `--motion=normal --hours=0 --out=res://shots/vis_f10_3_motion/seqB --label=seqB --only=quick` |
| C | 36312802264 | render-vis-f10-3-seqC-36312802264 | `--motion=reduced --hours=0 --out=res://shots/vis_f10_3_motion/seqC --label=seqC --only=quick` |

Script: `tools/vis_capture_strike_motion.gd`. It extends `tools/capture_stormwood_reduced_motion.gd`
(so `--motion` sets `motion_prefs.set_reduced_motion` before any staging), which extends
`tools/capture_stormwood_surge_phases.gd` (world mount, stand, HUD hiding, surge pin). Each run took
about 71 min; the sequence itself is ~8.5 s of wall time per frame.

Per-frame staging records (ticks, ring progress, bolt/light/flash levels, camera and player positions):
`scratchpad/frames_seq{A,B,C}.json`; logs: `scratchpad/run_seq{A,B,C}.log`
(scratchpad = `/tmp/claude-0/-home-user-Tetherbound/17284e0f-c457-5bb8-96a5-6e50038613d5/scratchpad`).

## Staging and shortcuts (all disclosed)
- **Exact timing via a child process.** The script relaunches itself once as a child Godot with
  `--fixed-fps 60` (same executable, project, opengl3, window size and X display). Every rendered frame
  is then exactly 1/60 s of game time for both process and physics. Without that, software GL makes
  tweens advance by wall time. Recorded ring `progress` confirms the timing: 0.014 at t=0, 0.514 at
  0.6 s and 0.931 at 1.1 s, identical in A/B/C. Frame t=N is exactly N×60 ticks after the warning call.
- **Forced strike.** One warning+impact pair goes through `StormwoodLightning._receive` (the client
  path, the same event dicts the host publishes). It aims at the trainer's own position, which is
  where the host aims, with `ground_height_near + 0.08`. The impact comes exactly 72 ticks (1.2 s)
  after the warning, with `hits: {}`, so there is no damage. Combat and the host schedule are untouched.
- **Natural strikes suppressed.** `StormwoodLightning._next = 1e9` and `_pending` are cleared, so no
  random host strike lands in the window.
- **Decorative sky normalised.** `StormwoodSurge._flash_next = 60` pushes the distant telegraph-less
  scene flash out of the window, and `_flash_echo = -1`. `_sky_rng` and `_flash_rng` are seeded
  20260927 with `_sky_next = 0.4`, so decorative in-cloud/bolt events are the same across sequences
  except where reduced motion itself changes them. Decorative sky bolts are also held during the
  warning by the game's own `hold_sky_bolts`. So the only scene-wide flash in the window is the
  strike's own.
- Stand: base tool's Surge strip stand, Cinder Verge `verge_glass_01` (-604, 772), camera toward the
  Verge Rod Station, pitch 2 deg. One `Game.debug_teleport_to` plus a Player transform; the production
  CameraRig settles on its own. Camera to trainer is 5.43 m. The trainer character is `trainer`.
- Surge clock is pinned into **Break** (`realm_environment.stormwood.elapsed` = Break start + 2 s,
  then `settle_presentation()`), with 60 ticks of settle before the warning.
- World clock is set to the exact hour and frozen (`WorldLook._elapsed_seconds`). The base run first
  pins "day" via `apply_time`.
- HUD CanvasLayers are hidden (world + surge).

## Measured presentation state (from the JSON, for the lead)
- Impact frame t=1.2: A/B flash_level 0.95, strike light 7.63; C flash_level 0.10, light 1.14.
  Bolt mesh present at 1.2/1.25/1.3 s in all three.
- A and B flash sequences are identical (0.95 → 0.81 → 0.67 → 0.38 → 0.10 → 0).

## Limitations
- **Night looks like day by design.** `stormwood_surge.json storm_base.pin_time_of_day = true`
  (owner direction WO-F10-08) presents every hour with the day reference look. B and A differ only
  where the clock still matters (e.g. rain night tint). B is therefore "clock at 00:00", not a dark
  night; the judge's "does the telegraph merge into the night" question can only test that.
- **Sequence (d) not produced.** The PR #365 strike head `4a38a1faf44e8a7d8b1753eaf19659c759c1b5bd`
  does not contain `tools/vis_capture_strike_motion.gd`. render.yml runs the script from the
  checked-out ref, and a comparison would need a scratch branch or a push to another lane's PR
  branch, both of which are forbidden. It can be produced if #365 is merged into main/tb/vis, or if the
  lead authorises putting the tool on that branch.
- 1920x1080 PNGs straight from the viewport, with no resize. Contact sheets are downscaled
  (480 px tiles).
- Software GL (Mesa llvmpipe) on a GitHub runner with the Compatibility renderer, not the ROG Ally.
- Harmless `ERROR: Condition "status < 0" ... ERR_CANT_OPEN` lines appear at boot in each log
  (pre-existing, before the launcher); no SCRIPT ERRORs.
- Staged strike, not a naturally scheduled one; the trainer stands still and idle.
- A GPU backup request (sha/script/args) was sent to the lane lead per their instruction. These
  render.yml frames landed first.

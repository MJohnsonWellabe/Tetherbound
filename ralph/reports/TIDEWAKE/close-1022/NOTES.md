# Tidewake close-1022 (owner 22 Oct: fix the yardstick, then raise scores)

## TO COORDINATOR

- 2026-10-22 07:40 CT READY: tb/tidewake-land 5b1179976 (P2-109 saddle fade; Aquaryn camera pass-through). Found by coordinator 08:35 CT.
- 2026-10-22 11:55 CT INFO: tb/tidewake-land 905a0c938 passed re-review (PR #710). Merge main back in after it lands. Look candidate (OFF) since: harbour-boom dock barriers, kitbashed landmarks at Deep Watch, Salt Crown shrine/bell, Drowned Garden, Lantern Cove arch in view, tide-race restyle (wisp spray, wandering waterline, no crest ring). First calibrated batch (control vs candidate, 8 destinations) capturing now.
- 2026-10-22 10:20 CT READY: tb/tidewake-land 905a0c938 (second re-review: real-path tests). smoke_water_alpha_runtime adds 4 checks through the real engage/fight/exit: passes before engage, solid from engage, solid through phases ["active","resolving"] (passed in none), passes after exit; 31 checks, 2 failures = the same two baseline failures (Authored Alpha level; saddle row). smoke_net_water_alpha: guest passes before engage, solid on its engage verdict, new water_alpha_flee step (production try_flee) solid until local exit and passing after, then re-engage so the mid-fight leave check is unchanged: ALL CHECKS PASSED.
- 2026-10-22 09:35 CT READY: tb/tidewake-land 6f469c400 (re-review). Review defect fixed in 7ae45f75c: the pass-through now uses `water_alpha.camera_passes_through()` = not `_local_fight` (enrolment to local exit, so catching/resolving count; a guest sets it too) and not any other local fight. smoke_camera_pass_through adds catching, resolving, other-local-fight and a guest body driven through its real physics tick. Fade bounds are re-measured until meshes exist. Flake: the test body fell (no floor) out of a camera placed once; the lens now follows it, 12/12 saddle-fade and 4/4 pass-through. uid committed. Unit tests: 71, 0 failed.
- 2026-10-22 08:40 CT INFO: candidate day recapture (24 destinations, CPU Low) running; first calibrated batch follows.

Worklist: the GPU findings in `ralph/reports/GPU-PASS/F39-0/VERDICT.md` (branch tb/gpu-pass).

## Coordinator handoff (send_message refused: "elevated_session_untrusted_device")

This lane cannot message session_01CfKRDSan7LUFmNAx6VWNUy. The server needs a trusted device. This file is the handoff.

**Ready to land: `tb/tidewake-land` at 5b1179976** (origin/main plus two functional commits, no look candidates):

1. **P2-109, floating saddle after dismount.** The follower's camera fade dithered only the model. `RideSaddle` hangs off the body, so it stayed opaque at screen centre. It now fades with the mount. `tests/smoke_follower_saddle_fade.gd` fails before the fix ("0 of 1 saddle surfaces faded") and passes after.
2. **Camera inside the trainer's hair at Aquaryn basin.** The camera arm stopped on Aquaryn's flank. `camera_rig.gd` gains `PASS_THROUGH_GROUP`, which it re-applies every physics tick and adds to its clear-orbit sweep. Aquaryn's world body joins the group only while no fight is active. While in the group it fades when the lens is inside it; that fade moved from `follower_creature.gd` into `creature_body.gd` as opt-in `fades_when_camera_inside`. `tests/smoke_camera_pass_through.gd` covers:
   - the control: an ungrouped body stops the arm at 1.73 m;
   - a grouped body leaves the full 6 m;
   - the group and fade toggle with fight state;
   - all model surfaces dither with the lens inside.

**Checks.** Both new smokes pass, as do `smoke_camera_probe` and 62 related unit tests (companion presence, ally occlusion fade, water alpha state, riding saddle).

**Failing on the baseline too** (unchanged by this work, so not caused by it):
- `smoke_water_alpha_runtime`: "Authored Alpha level" and "Earned Stone and completed Iona lesson expose the real saddle row".
- `smoke_combat_camera`: bramblebun frame-crop failures.
- `smoke_riding_saddle`: "the party would not take a veridian (it holds 5)".

**Yardstick.** The new yardstick (`tools/visual_judge/`) is on origin/main. Because no message can reach this lane, its presence on main is taken as the landing signal.

## Findings worked

| GPU finding | Cause | State |
|---|---|---|
| Night creatures as flat white ghosts | Shared night `creature_emission_floor` 0.22 adds each plain-PBR creature's albedo as emission. Every Tidewake species is plain PBR, and Aquaryn's albedo is near white. Reproduced on CPU at aquaryn_tidal_basin 23:00. | Candidate (OFF): Tidewake night floor 0.08 (Cloudreach's measured value), d38f2d778. On CPU, Aquaryn keeps its blue colour and shading. Unjudged. |
| Aquaryn saddle floats after dismount | See 1 above | Fixed, on tb/tidewake-land |
| Camera inside trainer's hair at Aquaryn basin | See 2 above. Not reproduced on CPU at the same stand; Aquaryn's settled position differs between runs. | Fixed, on tb/tidewake-land |

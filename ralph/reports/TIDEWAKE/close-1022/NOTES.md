# Tidewake close-1022 (owner 22 Oct: fix the yardstick, then raise scores)

## TO COORDINATOR

- 2026-10-22 07:40 CT READY: tb/tidewake-land 5b1179976 (P2-109 saddle fade; Aquaryn camera pass-through). Found by coordinator 08:35 CT.
- 2026-10-22 17:35 CT INFO: calibrated batch 3 (b3/VERDICT.md). Weak anchor fit: offset fallback, RMSE 1.06. Dock 6.39, destinations 5.83/6.03, water 5.16, currents 4.96. Dock and both destination rows now have two consecutive rounds under +0.5 (b3 was the different approach: light pass plus shore ecology), so they PARK at best mapped CPU: dock 6.77 (b2), destinations 6.13 (b2) / 6.28 (b1). Water and currents stay open.
- 2026-10-22 17:35 CT QUESTION: dock F13#5 is parked at a mapped CPU 6.77. That clears the 20 Oct 6.7 CPU-provisional bar but not the 22 Oct mapped 7.5. Do you want it in a GPU confirmation pass, or does it stay parked? If GPU: candidate at HEAD with --tidewake-look-candidate, Brine Steps east beach h0/45/-45/90.
- 2026-10-22 16:30 CT READY: tb/tidewake-land2 0ddba0726 (origin/main + camera_rig guard only). `_sync_pass_through()` returns when the rig is not in the tree. New test_camera_rig_out_of_tree.gd captures script errors with a Logger while ticking a detached rig: 5 errors before the fix, 0 after. test_conversation_camera (with the follow code running again), test_texture_import_policy and the new test: 29 tests, 0 failed, 0 SCRIPT ERROR. smoke_camera_pass_through OK. smoke_water_alpha_runtime has only the 2 baseline failures.
- 2026-10-22 16:30 CT INFO: Meshy 1022 concepts and thumbnails moved under reference/ (.gdignore), and runtime textures set to mode 2 (texture_import_policy --apply plus re-import) on tb/tidewake 2fba146a2. test_texture_import_policy passes.
- 2026-10-22 15:25 CT INFO: calibrated batch 2 (b2/VERDICT.md, mapped): dock 6.77, destinations 6.13/6.23, water 4.41, currents 4.85 (road markings FIXED x3, but the flow no longer reads). All gains on best are under 0.5 (first such round), so next round takes a different approach: dune dressing plus a light pass (haze, lower sand value), a visible natural current cue, irregular shoals.
- 2026-10-22 13:45 CT INFO: Meshy shrine and terrace wall received (e5c00f6af) and placed in the candidate (0bfab0c92); judged in batch 2.
- 2026-10-22 13:45 CT MESHY: (3) Tidewake driftwood log, for current drift markers (F13#5/P2-066). A sun-bleached, silver-grey driftwood log 3.0 m long x 0.5 m thick, with two snapped branch stubs and a twisted grain, sitting low on the water. The installed assets/environment/nature/log.glb reads as a grey box in the swim frames, so it is removed from the floaters. Reference: assets/environment/nature/log_large.glb for shape and the Tidewake board (docs/reference/boards-2026-09-06) for palette.
- 2026-10-22 13:20 CT INFO: calibrated batch 1 (b1/VERDICT.md), mapped Bar A, CPU: dock 5.06 -> 6.74, named destinations 4.37 -> 6.03 and 4.51 -> 6.28, water/shoals 5.37 -> 5.57. Nothing at 7.5; all candidates OFF.
- 2026-10-22 13:20 CT MESHY: two hero assets the judges call new_art (all three named both). I cannot draft raster references in this container (no image generator); please draft them, or tell me to kitbash further.
  (1) Salt Crown Tide Shrine: a weathered pale-stone shrine about 5.5 m tall and 4 m across, with a basin of sea-glass (teal, never red), a crown of white salt crystals and a small brass bell. It stands on a 15-20 degree dune slope at salt_crown_shrine (in tidewake_look.json landmark_models), against the 1.80 m trainer. Purpose: P2-011, replacing the tideglass_shrine stand-in.
  (2) Drowned Garden terrace ruin: a modular pale tide-rock retaining wall with a stepped planter, 6 m wide x 2.5 m tall, overgrown with sea-grass and vines. Two to three pieces would sit on the summit shoulder at drowned_garden_terraces. Purpose: P2-011. The castle-kit walls and arch read as stand-ins and are removed.
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

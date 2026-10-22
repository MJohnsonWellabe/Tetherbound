# Tidewake close-1022 (owner 22 Oct: fix the yardstick, then raise scores)

## TO COORDINATOR

- 2026-10-22 19:10 CT TO COORDINATOR: FINAL READY tb/tidewake-final 5f937c78 This is origin/main a4f8a6b7 plus tb/tidewake plus tb/tidewake-land2.
  - **ON by coordinator decision for the 22 Oct wind-down** (`tidewake_look.json` `enabled:true`, exactly the state judged in calibrated batch 2; mapped CPU Bar A vs shipping, all below the bar):
    - F13#5 dock 6.77 (control 3.97); b1 6.74 vs 5.06.
    - P2-011 named destinations 6.13 / 6.23 (control 3.03 / 2.88); best 6.28 (b1).
    - P2-026/P2-009 water 4.41 (control 4.36); b1 5.57 vs 5.37.
    - The ON sections are the Meshy landmarks (Salt Crown shrine, Drowned Garden terrace walls, hall/porch/huts, Veilfall gate, drift arch), the harbour-boom dock barrier, the dock village/dressing/equipment, the tide-race restyle, the water/offshore surfaces, b2 lighting and camp-bed sailcloth. Nothing is at 7.5, and a GPU pass is owed.
  - **OFF but shipped** (`sections_off`, dropped by settings() in play; `--tidewake-look-candidate` restores them):
    - current_flow and current_flow_visual: b4 foam ribbons, unjudged (b3 ribbons 4.96 vs control 4.86).
    - night_creature_floor: the white-ghost fix, 0.08, never judged at night.
  - **Left out:** the unbaked rest-shoal reshape (418ca24ed; `water_world.json` stays main's, since it is gameplay terrain), and the b3 light pass, shore ecology and paver removal (judged above control but below b2; they stay on tb/tidewake 2e8aabbeb). The coordinator's shoal-reshape note said to keep it OFF; it is excluded rather than flagged because the heightfield has no gate for it.
  - **Cleanup:**
    - Unreferenced Meshy preview/raw PNGs were removed. Every included GLB is referenced by an ON section or an OFF section.
    - Evidence is the verdict/notes .md, key/mapping .json and one _sheet per round.
  - **Code from tb/tidewake:**
    - saddle fade, Aquaryn camera pass-through and camera_rig out-of-tree guard (land2);
    - landmark placer (.obj and per-surface materials);
    - dock rope boom, tide-race presentation overlay, shore-ecology switch, buoys-without-floaters;
    - fight_victory_receipt party-order fix (earlier lane, with its test);
    - tidewake_look_profile `sections_off` and the night_creature_floor section.
  - **Tests changed to follow ON** (same strength):
    - test_tidewake_look_profile now checks that the look ships ON with the unjudged sections off.
    - test_water_camp_bed_presentation asserts the configured sailcloth; it had been dereferencing a null map, an uncounted SCRIPT ERROR.
  - **Checks:**
    - water/tidewake/texture_import_policy/camera/receipt/companion/occlusion/saddle unit set: 629 tests, 0 failed, 0 SCRIPT ERROR.
    - smoke_camera_pass_through OK and smoke_follower_saddle_fade OK.
    - smoke_water_alpha_runtime builds the water scene with the look ON and shows only the 2 baseline failures. 0 SCRIPT ERROR across the smokes.
  - Lane stopped.
- 2026-10-22 07:40 CT READY: tb/tidewake-land 5b1179976 (P2-109 saddle fade; Aquaryn camera pass-through). Found by coordinator 08:35 CT.
- 2026-10-22 17:05 CT READY: tb/tidewake-land2 0ddba0726 (camera_rig is_inside_tree guard, test_conversation_camera re-run with the follow code running: 0 failed, 0 SCRIPT ERROR) and the Meshy reference/ move (2fba146a2, plus re-imported sidecars). Lane stopping per coordinator (usage cut); see RESUME below.
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

## RESUME (lane stopped 22 Oct ~17:05 CT, coordinator usage cut)

**Landed or ready.**
- tb/tidewake-land 905a0c938 (#710): saddle fade, Aquaryn camera pass-through.
- tb/tidewake-land2 0ddba0726: READY, the out-of-tree guard.

**Candidates.** All are OFF: `data/config/tidewake_look.json` has `enabled:false`. Turn them on per process with `--tidewake-look-candidate`. The candidate state is tb/tidewake at the commit carrying this section. tb/tidewake has NOT merged origin/main since 807adae56. Before the next judged batch:
- merge origin/main and tb/owner-creature-style e188bc862 (corrected JUDGE_PROMPT.md, used verbatim);
- re-import;
- capture a FRESH control, because the batch 1-3 control frames predate that merge.

**Best mapped CPU scores** (b1-b3 VERDICT.md files in this folder):

| Row | Best | State |
|---|---|---|
| F13#5 dock | 6.77 (b2) | PARKED (gain rule). QUESTION open: GPU pass? |
| P2-011 named destinations, heading 0 | 6.13 (b2) | PARKED |
| P2-011 named destinations, other headings | 6.28 (b1) | PARKED |
| P2-026/P2-009 water and shoals | 5.57 (b1) | OPEN, no gain in 3 rounds |
| P2-066/F13#5 currents | 4.96 (b3) | OPEN |
| F39#3 night/rain matrix | unmeasured since the white-ghost floor fix | OPEN |

**What the candidate holds now.**
- **Landmarks** (`landmark_models`, installed kits plus Meshy; the placer takes `.obj` meshes and per-surface materials):
  - Reedhaven: hall, porch, huts.
  - Deep Watch: castle watchtower, wood plus slate, in the gully about 15 m ahead.
  - Salt Crown shrine: Meshy `salt_crown_tide_shrine`, 5.5 m. Judges: it sits behind the dune crest and reads as "crystal on a pole". Next: move it forward onto lower ground or give it a plinth.
  - Salt Crown bell: Meshy dock shelter.
  - Lantern Cove: drift arch moved into view. Judges: washed out beside the smoke column.
  - Drowned Garden: Meshy terrace walls on the summit shoulder. Judges: "white boxes" at that range. Next: closer, larger, or more pieces.
  - Veilfall: Meshy gate.
- **Docks:** harbour-boom barrier (FIXED x3), paver discs off.
- **Water:** shallow `depth_falloff` 5, offshore start 2.5 m, full 26 m. Judges still see hard navy bands and blotches; the next try should be the opposite direction or real bathymetry.
- **Tide race** (`seal_race`): wisp spray, wandering inner edge, no crest ring; presentation keys only.
- **Currents (b4, unjudged):** ungrouped foam ribbons at full opacity and density, faint tint, no comets, chevrons or rims, no floaters, buoys only. The drift-marker script now keeps the buoys when there are no floaters.
- **Light:** day/dawn/golden ambient 2.0/1.7/1.15, sky share 0.15, haze 0.0006-0.0007, sand #b9a17b, shore-ecology colonies on. Night `creature_emission_floor` 0.08 fixes the white ghost: verified on CPU at Aquaryn basin, not yet judged.

**Next steps, in value order.**
1. **Currents:** judge b4 (the capture at HEAD was interrupted). If the lane still doesn't read, ask MESHY for a proper channel buoy plus the driftwood log (MESHY line 3 above).
2. **Night matrix (F39#3):** capture day/night/rain on welcome_beacon, woven_hall, veilfall_cascade, brine_steps_east and aquaryn_tidal_basin, candidate vs fresh control, and judge.
3. **Shoals (P2-026):**
   - The shoals are r=20 circles plus up to 8 m of extension (`water_heightfield._rest_shore_radius`). Variety needs per-shoal `shore_radius_m` changes plus a rebake.
   - That touches seal radii, swim-route spacing and safe landings, so it needs the water route/swim/heightfield tests (191 last time, see 418ca24ed).
   - The 418ca24ed shapes are still unbaked on this branch.
4. **Parked rows** reopen only with clearly new art: Salt Crown placement or plinth, terrace pieces, dune groves.
5. **Not started:** P2-002 map black canvas, P2-030 shiny magenta, the fight HUD rows (other lanes' surfaces), and P2-067 restored-current look.

**Known baseline test failures** (unchanged by this lane): smoke_water_alpha_runtime ("Authored Alpha level", saddle row), smoke_combat_camera (bramblebun crop), smoke_riding_saddle (veridian, party holds 5).

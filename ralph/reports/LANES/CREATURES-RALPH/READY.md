# CREATURES-RALPH: running status

Branch `tb/creatures-ralph`. Capture and judging run in this container on CPU (coordinator, 2 Nov): import works with a partial import set (untracked temporary `.gdignore` files), and `capture_f36_poses.gd` renders on llvmpipe. Disk is about 300 MB free, so each set is imported, captured and dropped in turn.

## BLOCKED: needs the coordinator (2 Nov, ~03:00 UTC)

- **The r9 Meshy models (Aquaryn, Duskhush, Mangrove Monitor) cannot be rigged in this container.**
  - The rig recipes (`prepare_remake_quadruped.py`, `rig_bird.py`) need Blender.
  - Blender is not installed, and only about 270 MB of disk is free, too little for Blender or a `bpy` wheel.
  - Please rig them where Blender exists (quadruped recipe for Aquaryn and Mangrove Monitor at the installed heights, `rig_bird` for Duskhush) and push the rigged GLBs to `candidate_r9/models/`. Or give this lane a session with more disk.
  - Once the rigged GLBs are on this branch, I run `arc_emission`, the weight relax and the CPU judge against the shipped remakes, then point the flag in the same commit.
- My cross-session messages to the coordinator are refused (`elevated_session_untrusted_device`), so this file is the channel.
- **Wake-ups.** I did not arm `send_later` wake-ups on a peer session's request alone. The user has to ask for those.

## r9 Meshy models (2 Nov ~10:00 UTC): all three wired to r9, waiting for the GPU (see QUEUE.md)

- **Duskhush** (r12): 4.61 → 6.30.
- **Aquaryn** (r13): 4.44 → 6.54.
- **Mangrove Monitor** (r13): 5.02 → 5.69.
- **What I changed on the r9 rigs:**
  - hit: neck, head and tail eased;
  - faint: grounded side-lie (about 77°, the root lifted per key), not belly-up;
  - the Monitor's hit hop scaled down;
  - Duskhush's wings eased ×0.5 in attack and fly_grip;
  - weights relaxed on all three.

## GPU-confirmed: cr1102 (2 Nov ~12:10 UTC; three code-blind judges, anchors, calibrated; tree 29518c111 vs main1102b)

| Species | main | lane | Δ |
|---|---|---|---|
| Sirenseal | 5.93 | **7.10** | +1.17 |
| Skyrill | 6.05 | 6.87 | +0.82 |
| Staticub | 6.46 | **7.16** | +0.70 |
| Thundertunnel | 5.59 | 6.28 | +0.69 |
| Aquaryn | 6.26 | 6.64 | +0.38 |
| Duskhush | 6.44 | 6.77 | +0.33 |
| Mangrove Monitor | 6.13 | 6.44 | +0.31 |

All seven are GPU-confirmed gains, and Sirenseal and Staticub cross 7.0. **Nothing on this branch must be held back from landing.** Every OFF flag (the grounded-hit roster flag and the unkept coat flags) changes nothing while off.

## Coordinator order of 2 Nov ~11:30 UTC: status

1. **Sirenseal hit and faint (r18): KEPT.** CPU 5.82 → 7.30 mapped on the r10 model. The hit hop is ×0.3; the left flippers fold and the faint settles, so the flipper prop is FIXED for all three judges. The GLB is in the queued GPU job.
2. **Bramblebun and Ripplet fight-camera bias (option 2):** already its own commit ("Fight camera: lean the pair midpoint toward the ally for longer remakes; Bramblebun and Ripplet ON"). Ready to land; CI's `smoke_combat` decides.
3. **Torrentoad blue speckled toad:** `creatures_ralph_torrentoad_toad` is ON. It scored r10 CPU 4.64 → 5.55, which clears the new target 4.73 (GPU roster 5.53 − 0.8). It is registered in `JUDGED_ON`. The gaunt biped silhouette still needs new art.
4. **Tuskroot and Ashtusk value lift:** already ON since r10 (Tuskroot 5.55 → 7.42, Ashtusk 5.71 → 7.07, CPU). The roster baseline (main dd2d01342) does not contain this branch, so its Tuskroot 6.85 and Ashtusk 7.16 are pre-fix. Please add both to the next GPU job.
5. **The 6.8–7.0 band.** Shared-lift probe (2 Nov ~12:30 UTC):
   - **Hit grounding (`creatures_ralph_grounded_hit_roster`).** 28 live remakes lift their hit react 0.15–0.68 m because the dog3 hit clip hops the root. One clip flag plants all 28 (position ×0.3).
     - The CPU stage A/B (tuskroot, mosshock, cliffspike) changes the hit frames by only 0.7–1.4 of 255 grey levels, because the hop is small at the stage camera.
     - Not judged; it stays OFF.
   - **Faints are uniform across the roster** (the 90° dog3 side-lie). No faint lever there either.
   - **Without the ROSTER-1102 per-species judge notes, the band has no evidenced shared defect.** Please push the notes. The judges' recurring note is rim light and value on the dark stage, which is lighting, not this lane's rig or coat work.

## r10 Meshy models wired (r16, 2 Nov ~11:00 UTC): Staticub, Sirenseal and Skyrill ON, queued for GPU with r9

- **Scores (mapped):**
  - Staticub 5.34 → **8.55**: "naturalistic bear, Stormursa bar".
  - Sirenseal 4.35 → **6.95**: "believable sea lion".
  - Skyrill 4.79 → **7.34**: "believable sail-back quadruped".
- **One GPU job** for the six r9 and r10 models is in QUEUE.md. Evidence is in `r16/`.
- **Sirenseal follow-up:** the hit lifts off the floor, and the faint end props on a flipper.
- **Thundertunnel (r17): KEPT, ON.** A velvet coat plus hit and faint fixes on the current remake: 2.93 → 5.36 mapped (target 3.92). The judges still want a clearer face and anatomy, which is the r10 remodel once Meshy credits return.
- **Test fix in `tests/test_remake_owner1101_finish.gd` (please review).** The r9 and r10 models carry glow masks, so `test_glow_pass_covers_every_remake_with_a_glow_mask` failed from r12 on. They are now in `remake_owner1101_glow_read`, which stays OFF, with maps from `remake_owner1101_finish.py`; that tool now reads the live remake model.
  - `test_enabled_coat_flags_apply_every_key` assumed every remake albedo lives under `candidate_owner1101/`. It now also accepts the exact live albedo of a remake's current model, which is stricter than a path pattern.
  - Locally, every check on the seven species I touched passes. The remaining failures are only species not imported in this container's partial import set; CI imports everything.

## Work list from 2 Nov ~09:20 UTC: the coordinator's GPU roster baseline (main dd2d01342)

16 of 70 creatures are at 7.0 or above. The full table lands as `ralph/reports/CLOUD-JUDGE/ROSTER-1102/`. Order of work:

1. **The 6.8–7.0 band** (aeriex 6.92, mosshell 6.92, galewisp 6.96, paddlenewt 6.98, trailpup 6.99, tuskroot 6.85, cindercub 6.85, stormbrush 6.82, nightburrow 6.80, water_mosshell 6.95): look first for a shared lift (faints, value against the dark stage, rim). Started: a CPU baseline of mosshell, galewisp and aeriex.
2. **Water variants:** do they inherit the base model's look fixes, and are their swim and ride clips missing?
   - **Band audit (2 Nov ~09:50 UTC).**
     - Faint end-roll: every live dog3 remake ends its faint on a 90° root side-lie (the bird recipe at 70°; fulgocobra and skyrill at 0°). There is no roster-wide over-roll to fix in one place.
     - CPU baseline of mosshell, galewisp and aeriex:
       - mosshell (an installed model, not a remake) flips fully belly-up in its own faint;
       - galewisp and aeriex read cleanly, with grounded side-lies.
     - Nothing shared stands out at the stage camera. **Needed from the coordinator: the ROSTER-1102 per-species judge notes** (defects per frame) for the band and the water_* rows. Without them every band arm is a guess. The water_* rows are separate species with their own clips and pose overrides (`creature_clip_flags.json`, `f36_pose_candidates.json`), so they do not inherit the base model's look fixes.
3. **The bottom, worst first.**
   - Thundertunnel, Sirenseal, Skyrill and Staticub get coordinator r10 Meshy models.
   - Sparkit, Ribbonray, Tempestwing and Ripplet are already tried (r14, r15) and need new art.

## GPU batch 6 (Sparkit, Tempestwing, Ribbonray), r14 (2 Nov): no keeps, shipped remakes unchanged

- **Sparkit:** shipped 5.86 vs regional fennec coat with the faint grounded 5.89 (mapped, three judges). A tie, so not kept. All three judges name "spindly stick legs"; that is mesh, so it needs a re-mesh or new Meshy art.
- **Tempestwing:** shipped 6.20 vs pale gold coat with the faint grounded 5.71. Not kept. The judges prefer the shipped dark body under bright white wings for the value split; the shipped faint already rests on its body (only the wingtips cross the floor).
- **Ribbonray:** shipped 5.53 vs value and saturation lift with the hit eased and the faint grounded 5.39. Not kept. All three judges call the magenta body "toy-like, no readable face". **It needs new Meshy art (a natural hue and a face). Parked.**
- The coat flags (`creatures_ralph_sparkit_fennec`, `_tempestwing_gold`, `_ribbonray_lift`) stay OFF with their scores. Evidence is in `r14/`.
- **Ripplet look (r15):** a natural otter regrade (sky-teal, deeper back, cream belly, matte, the grey dome texels recoloured) scored 5.29 against the shipped 5.42, so it is not kept. The judges want new art: fur or scale breakup, a back-to-belly gradient, natural plates in place of the domes, and glowing aqua markings and eyes. **Parked for Meshy.**
- **Requests for the coordinator's Meshy queue:**
  - Ribbonray: a natural-hued ray or serpent with a readable face;
  - Sparkit: the fennec with sturdier legs;
  - Ripplet: the otter with fur, natural plates and glowing aqua markings.

## GPU main1102 regressions (coordinator, 2 Nov ~08:30 UTC): status

- **Tuskroot and Ashtusk** (r10): KEEP and ON.
  - Tuskroot 5.55 → 7.42.
  - Ashtusk 5.71 → 7.07.
  - Both are in `JUDGED_ON`.
- **Torrentoad** (r10, r11): two approaches failed the 6.26 target (+0.91, +0.55).
  - **Coordinator: please generate the new Meshy blue toad.**
  - r10's coat stays committed with its flag OFF, as an optional interim (+0.91).
- **Terrapup** (r11): the faint change gave no gain, so it is dropped. The judges' issue is the plate grid, which the owner's look keeps. See `r11/VERDICT.md`.

## Paddlenewt remake ON (2 Nov ~06:55 UTC, coordinator GPU batch 5: installed 6.50 → remake 7.16)

- **Contract.** The HELD reason was "aspect variant Riftfrill uses textures painted for the old model". That is met: r5 shows Riftfrill's repaint resolving on the remake mesh.
- **Change.** The flag is ON and removed from HELD.
- **Caveat for the GPU.** On CPU r5, Riftfrill on the remake scored 5.70 against 6.49 installed. The judges called it "galaxy noise", the hunched stance came from the Paddlenewt mesh, and the GPU rates Paddlenewt higher. Riftfrill has not been GPU-judged on the remake yet, so please include it in the next GPU batch.
- **CI.** `test_dual_type` and `test_creature_model_flags` run in CI only.

## Queue additions (coordinator, GPU batch 5)

- **Meadowhart remake (live)** (r8, r9): the hit-react stoop fix is shipped in the GLB. Attempt-1 coat: 6.12 → 6.80 mapped (+0.68), 0.10 short of the 6.9 target, so `creatures_ralph_meadowhart_warm` is OFF. **Coordinator: please decide whether to turn it ON.** It is strictly better than the live remake. Attempt 2 gained nothing. See `r8/VERDICT.md`.
- **Mosshock remake (live): 6.55 → 6.45 on GPU.** A mild regression, at the end of Task 1.

## Bramblebun + Ripplet ON with the long-body fight-camera bias (coordinator option 2, 2 Nov ~08:40 UTC)

- **Commit.** "Fight camera: lean the pair midpoint toward the ally for longer remakes; Bramblebun and Ripplet ON". This commit stands alone. If CI's `smoke_combat` is red, drop only the failing species.
- **Code.** `fight_camera.gd::midpoint_bias_for(config, ally_ratio, foe_ratio)` returns `midpoint_bias` unchanged unless `camera.json fight.long_body_bias.enabled` is on and a fighter declares `framing_length_ratio` > 1. In that case it returns `midpoint_bias − slope·(ratio − 1)`, floored at `min_bias` (0.3). `combat_manager.gd` feeds it each fighter's declared ratio. No other fight changes.
- **Declared ratios** in `creature_model_flags.json`:
  - Bramblebun 1.18 (3.53 m rendered against the installed 2.99 m);
  - Ripplet 1.09 (hit-pose 6.22 m against the installed 5.73 m).
- **Test.** `tests/test_fight_camera_long_body_bias.gd` passes here: 4 tests, 79 assertions. It checks:
  - the bias is 0.5 within installed footprints, and shorter bodies never move it;
  - a longer remake leans the midpoint toward the ally;
  - with the flag OFF, nothing changes;
  - only declared remakes carry a ratio.
- **Not run here:** `smoke_combat` needs the Meadows world. If 1.18 or 1.09 is not enough lean, raise `slope` in `camera.json`; that touches only these two.

### Earlier analysis: smoke_combat camera anchor (2 Nov ~03:25 UTC)

Analysis only. `smoke_combat` needs the Meadows world imported, which does not fit this container's disk, so I could not run it.

- **The check.** `smoke_combat.gd::_check_the_fight_opened` takes the rig position minus height and shoulder, and fails when that is nearer the trainer than the ally.
- **What sets that position.**
  - `combat_manager.gd` calls `set_framing_pivot_offset(solution.pivot − ally)` and then `apply_fight_camera_pose`.
  - `fight_camera.gd::pivot()` lerps between the ally's and foe's **rendered** AABB centres (`camera.json midpoint_bias` 0.5). Those centres are `RENDER_BOUNDS.measure(model)`.
  - The arena spacing also grows with the **rendered** footprint (`_fighter_render_footprint` → `_admission_render_radius`, the xz reach of the render box corners).
- **Measured with CPU skinning, rest/idle pose.**
  - Both remakes are centred on their origins, the same as the installed models. Nothing is offset.
  - Bramblebun is longer: remake 1.59 × 3.00 × 3.53 m against installed 1.44 × 3.00 × 2.99 m. Its admission radius is 1.94 m against 1.66 m (hit pose: 2.30 m).
  - The extra length is in both ends: the head reaches +1.77 m and the leafy tail −1.77 m. Rotating the tail (±25–40°) does not shorten it, because the head end is just as long.
  - Ripplet: remake 1.94 × 3.60 × 5.87 m against installed 2.86 × 3.60 × 5.73 m (hit pose 6.22 m long).
- **What this means.**
  - The longer rendered bodies widen the formation and move the framing midpoint away from the ally, so the anchor ends up as near the trainer (2.6 m) as the creature (2.8 m).
  - Without shrinking, nothing in the remake mesh or rig moves it back. There is no stray island or offset to remove; the identity-defining head and leafy tail set the length.
- **Options (need a decision; I have not made any of these changes).**
  1. **Re-proportion the remake to the installed footprint.** This is how CAUSE-REMAKES fixed Terrapup (x 0.83, z 1.05, height kept, `terrapup/candidate_owner1101/source/fit_installed_footprint.py`). For Bramblebun that means z 0.85. It shortens the body, so it conflicts with "never shrink" unless the owner rule allows a height-kept re-proportion. **Owner/coordinator call.**
  2. **Bias the fight-camera midpoint toward the ally** for these pair classes (`camera.json` `midpoint_bias` below 0.5, or per `size_matrix` profile). This is a config change in the camera system, so it affects every fight's framing; CI and a GPU look would decide.
  3. **Leave both HELD** until one of the above is chosen.

## Done (CPU-provisional; batch these into the GPU confirmation pass)

- **Cliffspike** r1: 5.53 → 6.49 mapped (+0.96; target ≥ 5.80). GLB weight relax plus the coat flag `creatures_ralph_cliffspike_bands`. Ships as is.
- **Ashtusk** r1: 5.94 → 6.71 mapped (+0.77; target ≥ 6.60). Remake aspect textures plus rigid tusks in the Tuskroot GLB.
- **Tuskroot remake ON** r4 (takes Ashtusk live). Installed → remake mapped: Tuskroot 6.85 → 7.06; Ashtusk 5.36 → 7.27. The Tuskroot GLB weights are relaxed. Commit "r4".
- **Craghorn** r2: 5.75 → 6.45 mapped (+0.70; target ≥ 6.12). Weight relax in the GLB (horn stretch 1.38 m → 0.17 m). Ships as is.
- **Cannonback** r6: 5.33 → 6.22 mapped (+0.89; target ≥ 5.88). Coat flag `creatures_ralph_cannonback_moss` (ON).
- **Cragclaw** r7: 5.39 → 6.34 mapped (+0.95; target ≥ 5.90). Coat flag `creatures_ralph_cragclaw_body_mid` plus scale flag `creatures_ralph_cragclaw_presence` (×1.2). Landing needs the scale gameplay checks (arena containment) in CI.
- GPU form: `capture_f36_poses.gd -- --species=cliffspike,ashtusk,craghorn,cannonback,tuskroot,cragclaw --whole-body --context` with `remake_owner1101_tuskroot` enabled for Ashtusk; Forward+ 1920x1080, High first.

## Task 2 unholds that need CI (separate commit, "Task 2: turn ON ... CI to verify")

- Torrentoad, Meadowhart, Terrapup, Riptusk and Bramblebun are ON and removed from HELD. The CAUSE-REMAKES lane fixed each contract ("fixed, not run", `ralph/reports/LANES/CAUSE-REMAKES/READY.md`).
- Their contracts are gameplay smokes that need a full world import, and this container cannot run them. If CI fails any one, drop that species' two lines (flag `enabled` back to false, HELD line restored) and land the rest. That commit is independent of r1–r4.
- Still HELD:
  - Ripplet (parked by CAUSE-REMAKES: the combat camera anchor);
  - Burrowback, Trailpup and Paddlenewt (variant aspect textures not yet repainted for the remakes);
  - Mudsnout (Warrens seat);
  - Frostclaw (pose library).

## Parked / needs the coordinator

- **Aquaryn and Duskhush:** two approaches each with no gain (r1, r3). The judges ask for new models, which means Meshy, and the key is not in this container.
- **Mangrove Monitor:** two failed approaches (r2, r6). It needs new art via Meshy.
- **Burrowback and Trailpup remakes:** two approaches each (r5, r7) and still below their installed models. They stay HELD and are parked; they need new art or a re-rig (Blender).
- **Paddlenewt remake:** the hunched bipedal mesh needs new art (r5).

## Next

- **Task 3 (started 2 Nov, ~03:40 UTC).** The batch-4 creature table is not in the repo, so I used the last board scores on the coordinator dashboard (pre-1 Nov remakes). I baselined the shipped remakes of Sparkit, Mosshock, Pebbik and Shadelet on CPU.
  - **Shadelet:** the tail and leg geometry stands up about 2.7 m in the faint frames. It is skinned to the pelvis, head and rear_lower_r, not the tail chain. The rig joints sit off-centre and asymmetric across a mesh 3.4 m wide. It needs a Blender re-rig.
  - **Pebbik:** the faint end reads belly-up, but the shipped clip already keeps the feet lowest, so a root or pelvis roll does not help. It needs an authored faint (Blender).
  - **Mosshock:** the faint is a moss lump. Its worst clip stretch is 0.46 m (the weight relax brings it to 0.27 m), but r2 showed a relax alone does not move scores unless the artefact is visible.
  - **Sparkit:** reads cleanly; no defect obvious at the stage camera.
  - Without the current GPU table, Blender, or the rigged r9 models, further Task 3 rounds are guesswork. **Please push the batch-4 creature table (or the current board scores) to this branch.** I will then work up from the lowest score where grading or weights can help.

## Local checks

Not run yet. The required suite needs every remake imported, which does not fit this container's disk. Until I can run a scoped set, CI decides.

## Tools added (all without Blender)

- `tools/art_pipeline/relax_stretched_weights.py`: CPU skinning over gameplay clips, then a harmonic weight solve where triangles stretch.
- `tools/art_pipeline/rigid_bind_region.py`: binds a box region rigidly to one joint.
- `tools/art_pipeline/amplify_clip.py`: exaggerates a clip's rotations.
- `tools/art_pipeline/grade_regions.py` with `data/creatures/remake_grades.json`: regional coat grade by anatomy map.
- `tools/art_pipeline/grade_quill_bands.py`: banded quills.

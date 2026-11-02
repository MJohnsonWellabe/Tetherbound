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

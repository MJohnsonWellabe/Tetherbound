# POSE-1 handoff to the creatures lane (GPU lane, 31 Oct 2026)

The owner moved POSE-1 to the CPU creatures lane ("this machine judges"). This is the GPU lane's local work on `tb/pose-ground`, as a patch series on main d4d5b262f. Apply it with `git am ralph/reports/GPU-PASS/Q31/POSE-1-handoff/*.patch` on a branch from d4d5b262f.

It is here and not pushed to `tb/pose-ground`, because the GPU lane pushes only to `tb/gpu-pass` without the owner's explicit OK for another branch.

**Status: never rendered or judged.** The GPU queue took priority, so v1 had no render pass.

1. **0001, the flag-off hook:**
   - `data/config/pose_ground_candidate.json` (`enabled: false`) can replace named roles of named F36 pose profiles in `creature_pose_candidates.gd::install()`.
   - Candidate roles, including a new `rest`, are grounded on the posed skin and get their own contact-cache scope.
   - A profile that gains `rest` makes `CreatureBody.play_rest()` hold that clip, instead of the legacy whole-body rest roll that leaves Riptusk belly-up (P2-029).
   - Off renders exactly as main.
   - Note: `tb/co-f36-2-on` (e8da58fe1) adds a separate `candidate_role_flags` hook in the same function. They should combine, but one of the two should be kept.
2. **0002, Riptusk v1:**
   - **Faint:** `bramblebun_quadruped_anatomical`'s faint verbatim. Its rig contract is identical to Riptusk's (rig-diff 0.0 on the measured rest matrices). It ends lying on its side, pivot [0,0,90], legs slack. This replaces the upright, head-raised crouch (P2-028; ROSTER-1 water_riptusk upright faint PARTIAL 3/3).
   - **Rest:** `stormursa_native_adult`'s rest (rig-diff 0.2), a settled half-lean with pivot roll −52, legs folded and head lowered. It is retimed to settle by phase 0.4 and hold, because `phase2_capture_creatures.gd` samples a recipe rest at 45%. Riptusk's own profile has no `rest` role.
   - It is deliberately distinct from the side-lying faint, so the faint and rest do not read the same (the Terrapup P2-015 complaint).

**Notes for whoever continues:**
- **Capture behaviour:** `phase2_capture_creatures.gd` photographs a recipe faint at 90% of its clip and a recipe rest at 45%. Authored rests wait for completion.
- **Veridian and Terrapup** (P2-015) do not match their recipe models: the installed nat1024 and dog3 models are not the recipe models. Their faints are baked native clips, so they need a re-bake like Mosshell's 3899595e9.
- **Aquaryn mounted swim** (P2-108): `data/config/water_mounts.json` `surface_origin_offset_m` (−1.048) sets the depth. Not touched.
- **Flying landing** (P2-069): not investigated.

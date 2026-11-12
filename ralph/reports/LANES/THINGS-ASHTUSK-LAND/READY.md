STATUS: land

# THINGS-ASHTUSK landing (aspect motes face the lens for Ashtusk and Stormtrail; Ashtusk hit recoil)

Branch `tb/things-ashtusk-land`, cut from main c73dcc80.

Verdict: `ralph/reports/GPU-PASS/1108/G-things-creature-closeout.md` on tb/item-scout-1108 adfe7e1b (GPU High, confirming batch). Ships under the owner's 12 Nov no-threshold rule.

| Row | Before | After | Judges |
|---|---|---|---|
| F36#33 Ashtusk (motes + hit recoil) | 7.02 | 7.32 | 3/3; floating line FIXED 3/3; tusk PARTIAL |
| F36#75 Stormtrail (motes only) | 7.40 | 7.49 | 2/3 |
| Riftfrill (motes) | | -0.04 | left out |
| Nightburrow (motes) | | -0.05 | left out |

Neither row closes. Pose-stage Medium was not separate evidence (the stage ignored the preset; fixed in `tb/things-posepreset-land`).

Change:
- `scripts/creatures/vfx/aspect_vfx.gd`: the mote discs take their billboard axes in the effect node's own space, for the variants listed in `vfx.json aspect_billboard_local_1112.species` (ON: ashtusk, stormtrail). Riftfrill and Nightburrow draw exactly as before.
- `creature_pose_settle.json things_hit_scope` ON (ashtusk): new `hit.per_species` rows and `recoil.force` in `creature_pose_settle.gd`; Ashtusk rears 12 degrees through the hit and is planted; its faint sections are switched off so its faint is the game's clip.

Tests: new `test_aspect_billboard_local_1112.gd` (2) and `test_things_hit_per_species.gd` (4). Older pin updated: `test_cause_poses_settle.gd` listed the live settle species (Ashtusk added). Ran with test_things_faint_ground, test_combat_vfx, test_camfx_candidates: 38 tests, 0 failed.

Pixel check (CPU, pose stage, hit 000, this branch against earlier captures): Riftfrill matches main and differs from the all-species arm; Ashtusk and Stormtrail match the arm. No script errors. Nightburrow was not captured; the unit test covers its exclusion.

Still open per judges: the tusk tip meets the shadow line; dark plates with no rim; 1/3 reads the amber motes as a floating effect. For Riftfrill and Nightburrow the judges want both the orbs and the streaks removed.

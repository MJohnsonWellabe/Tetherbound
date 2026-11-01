# CAUSE-POSES lane (creature hurt and faint poses, roster-wide) — READY

## Summary (rolling; updated 1 Nov 2026, ~23:00 UTC)

- **Branch:** `tb/cause-poses`, from `origin/tb/land-vis-2`. The flag ships OFF. `MANIFEST.json` lists every entry.
- **GPU arm (one flip):** `data/config/creature_pose_settle.json:enabled`. Each section inside it keeps its own switch (ON inside the arm), so an arm can drop one section.
- **Criteria closed: zero.** This is a game change waiting on GPU verdicts. No CPU scores are claimed.

| Group | Items | Flag |
|---|---|---|
| 1 | F36 (1) rows, one per species (70: 48 recipe species with `--candidate`, 22 own-clip species without it), P2-015, P2-016, P2-020, P2-028, P2-063 | `creature_pose_settle.json:enabled` |

## What the fix does (`scripts/creatures/creature_pose_settle.gd`)

**One clip-level pass for every rig.** The F36 recipe roster and every own-clip species share one bone convention (root, pelvis, spine, neck, head, limbs). That includes the Meadows roster and all 49 `remake_owner1101_*` candidates. Once per body, the pass rewrites the resolved `faint` and `hit` clips in a per-body copy of their library, under the clip's own name, so the F36 stage (which plays clips by name) shows what the game shows.

The pass samples a bounded subset of skinned vertices (2,400) under the clip and pivot, using the same skinning maths as the F36 contact grounding. That costs one bake per body spawn: no per-frame cost, no material, mesh or collision change.

| Section | Judges' theme it answers | What it does |
|---|---|---|
| `faint.grounded` | "faint mid floats above its detached shadow" | Dense pivot keys (11 or more) plant every faint sample on the standing ground line, sunk 1.5% of the body's height into the ground, and re-centre the posed body over its contact shadow. |
| `faint.side_lie` | "faint same as standing", "hunched upright", legs-up and belly-up faints | Rolls about the body's own forward axis until the legs, measured from the trunk to the lower-limb bones, lie out to the side (78° from straight down). This covers standing and crouched faints (legs down) and legs-up faints (Veridian's own clip). A faint already on its side is left alone (roll under 10°). The roll composes with `roster_pose_r1` instead of doubling it. **Upright species** (`cragclaw`, `cannonback`, `mosshell`, `voltarach`, `burrowback`) target legs-down instead: they collapse flat on their own legs, which also rights Mosshell's belly-up own faint. |
| `faint.head_lift` | "a rug or pelt with no head or face" | The `neck` bone lifts a head that ends below about 10° of elevation, by up to 35°, ramped in over the second half of the clip. |
| `faint.face_camera` | "faint end collapses into a front-facing blob", belly blotches | At `play_faint` (the game path, not the stage), the collapse turns about its standing centre, ramped in, so the body lies across the camera's view with its back toward the camera. The belly, where generated textures are weakest, faces away. The turn is recomputed from the baked keys on every faint. |
| `hit.recoil` | "hurt keeps the idle silhouette" | A hit whose posed vertices move less than 4% of the body's height from its first frame gains a pivot recoil: nose up 7°, lean 6°, and a shove back of 8% of height. It is held from 22% to 60% of the clip, so the phase2 "hurt" still (taken at 45%) and fight frames catch it. |
| `hit.grounded` | "hit react goes airborne" | Every hit sample is planted on the ground line. |

- **Game wiring:**
  - `creature_body.gd::_build_animator` makes the call.
  - Settled clips are listed in `clips.pivot_clips`. `creature_animator.gd` restores the model pivot when leaving them, the same way it does for recipe clips.
  - The combat flinch moves the art child, not the keyed pivot.
  - Bed rests keep finishing the unsettled installed faint (`pose_settle_original/faint`).
- **Composes with:**
  - `f36_pose_candidates.json` flags, including `roster_pose_r1` and the lane role flags;
  - `creature_clip_flags.json`;
  - remake flags. The pass reads whatever clip those leave.

## CPU checks (llvmpipe, Compatibility; sanity only, not scored)

- **F36 stage with the flag ON:**
  - **Own-clip species** (Veridian, Terrapup, Pipwing, Mosshell, Bramblebun, Stormtrail): faint end grounded on its side, head up; the hit shows a visible recoil.
  - **Recipe species** (Frostclaw, Cloudfang, Cragclaw, Sirenseal, Glimmermoth, Staticub): Frostclaw and Cloudfang end flat on their side, and Cragclaw stays flat on its legs.
  - **Fixed during the work:** Veridian first stood on its antlers, legs up, under the first rule (a posed-height test). The second rule uses limb direction.
- **Game path (scratch probe, `play_faint` with the body facing the camera at 0° and 45°):** Terrapup, Veridian, Frostclaw and Pipwing end lying across the view instead of end-on.
- **Tests:**
  - `test_cause_poses_settle`: the arm ships OFF; OFF changes nothing on a body; ON re-keys faint and hit for Frostclaw (recipe) and Veridian (own clips). ON checks: grounded, over the shadow, side-lying, faint mid not floating, hit planted and visibly moving, bed rest unchanged; Mosshell upright.
  - Also passing: `test_f36_pose_candidates`, `test_uiposes_roster_pose_r1`, `test_creature_hit_impact_window` and `test_creature_attack_telegraph_animation`.

## Not covered or open

- **Many-legged and shelled bodies** (Cragclaw, Cannonback, Voltarach, Burrowback): grounded and righted, but no leg splay, so the faint can still read close to standing.
- **Glimmermoth** (moth) folds small and upright. The wing-only rig has no lower limbs, so the height fallback is used.
- **Material blotches in the faint:**
  - Nothing in the pose path changes materials; the only faint-time visual change is the aspect-flame hide.
  - The likely cause is the belly texture of generated meshes showing in belly-up or legs-toward-camera faints. `face_camera`, plus the back-toward-camera roll on the stage (`roll_sign` +1), keeps the belly away.
  - If the GPU judges still name blotches with the flag ON, it needs a frame.
- **phase2 creature and fight captures** were not run on CPU here: the Meadows world needs the large prop folders this disk cannot hold. Their manifest entries rely on the `play_faint` probe above.

# CAUSE-POSES lane (creature hurt and faint poses, roster-wide) — READY

> **Parked (two attempts):** Fulgocobra's raised hood at faint end. `faint.legless_head_drop` lowers the head through the three joints below it, by up to 90° in total, but the hood still stands part-way (CPU, remakes ON). It needs a different idea, such as re-authoring the snake's faint clip so the whole coil collapses. The partial drop stays in the arm.

## Round 3 (1 Nov 2026, ~23:00 UTC): remakes are the shipping models

**Use MANIFEST group 3.** It supersedes groups 1 and 2: 75 entries, each with a `baseline` field. Every entry is judged with all 49 `remake_owner1101_*` flags ON, as the coordinator directed (1 Nov). Each F36 row's `note` names its stage form:
- remake rigs: no `--candidate` (60 rows, counting water forms);
- recipe species that have no remake: `--candidate`.

The flag is unchanged: `data/config/creature_pose_settle.json:enabled`.

**What the remake checks found and fixed.** Each was checked by CPU capture with all remakes ON, arm OFF vs ON.
- **The remakes' own faints sink below the floor.** The render marker probe was decisive: sampled vertices drawn as spheres sit on the mesh. Abyssal Guardian's own faint goes 1.36 m below the stage floor, which hides the sunk half. With the arm ON its lowest point sits 3 cm into the ground.
- **Ground the trunk, not the lowest vertex** (`faint.grounded.limb_sink_frac` 0.2):
  - The trunk (vertices bound mainly to root, spine, tail, neck or head) rests on the ground.
  - Limbs may sink up to 20% of standing height.
  - Grounding to the lowest vertex had balanced Abyssal Guardian on one fin tip and pushed Mirejaw up onto its legs.
- **`faint.level_trunk`:** a faint that ends sitting or standing up pitches down until pelvis-to-head is at most 25°, before the roll. This answers the "begging seal" and "sits upright" notes. Ribbonray improves from vertical to diagonal but is not fixed.
- **Legless rigs keep their authored fall:**
  - No height-fallback roll: it stood Fulgocobra's coil up on its side.
  - Head lift applies to limbed bodies only.
- **Hit recoil threshold raised from 4% to 7% of height,** so Fulgocobra's 5% hit gains the recoil.
  - The other named remake hits already move 16–34% of height and lift at most 0.11 m off the ground: Voltarach 17%, Bramblebun 16% (lift 0.01 m).
  - So "barely differs" (Voltarach) and "airborne" (Bramblebun) are not a motion-amount problem the arm can fix blind. The long stage shadow makes grounded bodies look lifted.
- **Remakes with the arm ON (CPU):** Terrapup, Bramblebun, Riverdrake, Mirejaw and Tanglevolt (recipe) lie low and grounded on their side. Abyssal Guardian lies low with one fin sunk.
- **Still weak:**
  - Fulgocobra's hood: parked (see the note at the top).
  - Ribbonray is diagonal.
  - Glimmermoth's wings stay up.
  - Galewisp ends as a puffed bird with its tail up.
- **Test:** `test_cause_poses_settle` passes with the committed flags (46 assertions) and with all remakes ON (47). Its expectations follow whether a recipe actually installs, so the remake landing does not break it.

## Lane close-out (1 Nov 2026, ~22:40 UTC)

- **State:** `tb/cause-poses` at its pushed head, with `origin/main` merged in after #792. **One GPU arm:** `data/config/creature_pose_settle.json:enabled`, shipped OFF. Use `MANIFEST.json` **group 2** (83 entries); it supersedes group 1.
  - 70 F36 (1) species rows, run as `capture_f36_poses.gd --whole-body --context`, with `--candidate` for recipe species.
  - P2-015, P2-016, P2-020, P2-028 and P2-063.
  - 8 remake pairings, each with `also_enable` naming its `remake_owner1101_*` flag.
- **What worked:** a single clip-level pass for every rig, using the shared bone names and the posed-vertex sampler:
  - grounded dense keys re-centred over the shadow;
  - a side-lie decided by limb direction, keeping the side the faint fell to;
  - a head lift, and an upright splay for shelled and many-legged bodies;
  - a held recoil when a hit barely moves, and planted hits;
  - a `play_faint` turn so the body lies across the camera with its back toward it.
- **Open candidates, waiting on GPU verdicts:**
  - If the arm loses on a species, add it to `exclude_species`, or to `faint.side_lie.exclude_species` for roll only, rather than turning the arm off.
  - Still weak: Glimmermoth (a wing-only rig, so no leg axis) and Burrowback (small splay).
  - The faint-texture blotches are not reproduced on CPU. If GPU judges still name them with the arm ON, take a frame.
- **Runbook:** TECHNICAL §8.1 CPU setup.
  - This disk needed sparse-checkout to drop `assets/props/meshy-10{20,22,24,31}`, `crossing_hall_hero`, `assets_raw`, `tests/fixtures` and `archive`, plus local `.gdignore` files in `ralph`, `docs` and `site`, to fit the import.
  - F36 stage: `capture_f36_poses.gd -- --species=… --whole-body --context [--candidate] --out=res://.artifacts/…`.
  - Toggle only the master `enabled` line between runs, never mid-run.

## Summary (rolling; updated 1 Nov 2026, round 2)

- **Branch:** `tb/cause-poses`, from `origin/tb/land-vis-2`. The flag ships OFF. `MANIFEST.json` lists every entry.
- **GPU arm (one flip):** `data/config/creature_pose_settle.json:enabled`. Each section inside it keeps its own switch (ON inside the arm), so an arm can drop one section.
- **Criteria closed: zero.** This is a game change waiting on GPU verdicts. No CPU scores are claimed.

| Group | Items | Flag |
|---|---|---|
| 1 | F36 (1) rows, one per species (70: 48 recipe species with `--candidate`, 22 own-clip species without it), P2-015, P2-016, P2-020, P2-028, P2-063 | `creature_pose_settle.json:enabled` |
| 2 | Supersedes group 1: the same 75 entries, rebuilt, plus 8 remake pairings. Each pairing adds `also_enable` with its `remake_owner1101_<species>` flag (terrapup, bramblebun, trailpup, brooktail, pipwing, galewisp, mudsnout, mirejaw) and is judged against the remake flag alone. | `creature_pose_settle.json:enabled` |

## Round 2 changes (from CPU OFF/ON comparisons)

- **Keep the side a faint fell to.** A faint that already lies on a side, or lies legs-up, keeps its own side (`keep_side_deg` 25°). `roll_sign` only orients standing or crouched faints.
  - Round 1's fixed `roll_sign` flipped Mudsnout, Stormursa and Galecrest over, through upright, onto the other side.
  - `face_camera` now uses the baked side, so either side ends with its back to the camera.
- **No large spins.** Rolls above `max_roll_deg` (120°) are kept as authored. Mosshell's own belly-up faint stays belly-up rather than spinning a full turn mid-clip.
- **`exclude_species` (no roll):**
  - Voltarach: its curled faint has no reliable leg axis.
  - Galecrest: its own wing-collapse already lies on its side.
- **`faint.upright_splay`:** for the upright species, the upper limbs swing outward about the forward axis, so the grounded body settles flat onto splayed legs (Cragclaw, Cannonback and Voltarach on CPU). The swing flips for an inverted body, such as the belly-up turtle.
- **Forward axis is +Z,** the combat facing that `model_yaw` guarantees. Round 1's head-to-pelvis axis misread Galecrest's curled neck.
- **Remakes, OFF vs ON (F36 stage):**
  - The remake clips' own faints land belly-up with legs in the air: Terrapup, Bramblebun and Trailpup.
  - With the arm ON they end side-lying, back to the camera, head up.
  - Remake hits are left as authored, because they already move more than 4% of height.
  - Galewisp's remake faint frames rendered black with the arm OFF (an existing capture problem, not this flag).
- **Near-bar species, OFF vs ON (Tanglevolt, Stormcapra, Stormursa, Riverdrake, Nightburrow, Mudsnout):** the faints stay close to their authored poses, re-grounded and seen from the back. No species flips. See `_sheet_cause_poses_cpu_r2.png`.

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

## Cost (CPU container, headless)

- **One bake per species, model, clip set and fit per session,** cached (`creature_pose_settle.gd` `_cache`). Each body gets duplicates, so `play_faint`'s camera turn never touches another body.
- **Spawn time, flag OFF → ON:**
  - first body of a species: 6–15 ms → 39–65 ms;
  - later bodies: 6–15 ms → 6–15 ms (+0–4 ms).
- **Sampling:** a 1,500-vertex subset. There is no per-frame cost.

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

- **Shelled and many-legged bodies:**
  - Burrowback's splay is small, so it still reads close to standing.
  - Mosshell's own faint stays belly-up, splayed and grounded.
- **Glimmermoth** (moth) folds small and upright. The wing-only rig has no lower limbs, so the height fallback is used.
- **Material blotches in the faint:**
  - Nothing in the pose path changes materials; the only faint-time visual change is the aspect-flame hide.
  - The likely cause is the belly texture of generated meshes showing in belly-up or legs-toward-camera faints. `face_camera`, plus the back-toward-camera roll on the stage (`roll_sign` +1), keeps the belly away.
  - If the GPU judges still name blotches with the flag ON, it needs a frame.
- **phase2 creature and fight captures** were not run on CPU here: the Meadows world needs the large prop folders this disk cannot hold. Their manifest entries rely on the `play_faint` probe above.

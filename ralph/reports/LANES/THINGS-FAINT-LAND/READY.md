# THINGS-FAINT-LAND: grounded faints for seven pose rows ship ON, with the pose-stage and dialogue-capture fixes and one camera bug fix

STATUS: land

- **Branch:** `tb/things-faint-land`, cut from `origin/main` 8df122a83 (after PR #910).
- **Verdicts (LANE-SCOUT, `tb/item-scout-1108`, GPU High):**
  - `G-things-faint.md` (58bf5187a), base and arm both on the game's clip, 3/3 unless noted:

    | Row | Base | Arm |
    |---|---|---|
    | cragclaw | 6.84 | **7.51** (Medium 7.30: stays open) |
    | water mirejaw | 6.37 | **7.39** |
    | water cragclaw | 5.43 | **6.51** |
    | abyssal guardian | 5.62 | **6.56** |
    | mangrove monitor | 6.51 | **6.98** |
    | cannonback | 6.74 | **7.07** |
    | mirejaw | 6.70 | **6.98** (2/3) |

    Fulgocobra was level (−0.05; the hood stays raised) and is **not** in the landing. The stage fix alone: water mirejaw 4.77 → 6.37, water abyssal guardian 5.62 → 6.32.
  - `G-newapproach-travel-pose.md` (841b3dbf6): water mosshell 4.65 → 6.67, galewisp 6.35 → 7.44, 3/3 on every set. LANE-NEWAPPROACH's change (tb/newapproach 1833b8a9c), folded in here because it is the same tool file.
- **What ships (game):**
  - `data/config/creature_pose_settle.json`: `things_faint_scope` ON with `_why_on` (mirejaw, abyssal guardian, mangrove monitor, cragclaw, cannonback, and their water forms); `exclude_species` water abyssal guardian and water mangrove monitor; `faint.per_species.water_mirejaw` (tail eases to rest). The roster-wide master stays OFF.
  - `scripts/creatures/creature_pose_settle.gd`: `faint.per_species` deep-merge for one species' bake, `crumple.tail_relax`, `head_joints`. Inert without config.
  - `scripts/player/camera_occlusion.gd` `_ignored`: validity is tested before `is Node`. The dialogue re-capture on main logged seven "Left operand of 'is' is a previously freed instance" errors there. One occlusion check was skipped per frame; nothing visible.
- **What ships (capture tooling):**
  - `tools/art_pipeline/capture_f36_poses.gd`:
    - **Rows play the game's resolved clip by default** (was the species' raw clip). `--raw-clips` restores the old rows; `--game-clips` is still accepted. Made the default at the coordinator's suggestion: the resolved clip is what a fight plays.
    - `--clear-ruler` (opt-in): the ruler stands 0.9 m clear of the posed mesh. Kept opt-in so existing rows keep their ruler position unless asked.
    - The travel-pose change from tb/newapproach: reset between roles, rider seated on a ridden swimmer, trainer hung from the carrier's grip bones.
  - `tools/phase2_capture_dialogue.gd`: a Tidewake character's conversation is opened with the speaker's own name and plate, as play does (Adair showed the base researcher's face; F39#26 "Adair shows Iona"). Applied on top of #910's blend wait.
  - `docs/TECHNICAL.md` §8.1: four bullets.
- **Tests added:**
  - `tests/test_things_faint_ground.gd` (3): the scope ON with its species and no fulgocobra, the exclusions, the per-species row and merge.
  - `tests/test_camera_occlusion_freed_ignore.gd` (1): a freed node in the ignore list is skipped and a live owner after it still counts.
  - `tests/test_cause_poses_settle.gd`: the pinned shipped scope list gains the five species.
- **Tests run on this branch (CPU, headless, per-file lines checked):** `things_faint_ground, camera_occlusion_freed_ignore, cause_poses_settle, f36_pose_candidates, rest_faint_settled, fainting, tutorial_faint_floor, aquaryn_faint_headdown_flag, veridian_faint_headdown_flag, creature_stage_ruler_depth, capture_stand_heading_override, catalogue_capture_stand, dialogue_capture_waits_for_blend, camfx_candidates, storm_cams_candidates` and the eight `uiposes_*` files: 0 failed.
- **Stage check on this branch (CPU):** water mirejaw and cragclaw settle with no switch; galewisp's trainer hangs from the talons; water mosshell is upright with its rider seated.
- **Not included:** fulgocobra's override; the flag-off THINGS-TOYS-UI code (dust, catch card, pickups), which is still being judged.

## Follow-ups (next faint round, not this landing)
- Cragclaw: a faint end with the head out on the ground (Medium 7.30; close-out).
- Water mangrove monitor: belly-up on the game's clip; needs a belly or side slump with limbs folded.
- Water cragclaw's faint end "melts into a heap" (2/3); mirejaw's translucent smear on the tail or jaw in hit frames (3/3).
- The 14 faints named in `G-things-t4-rescore.md`.

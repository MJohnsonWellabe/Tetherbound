STATUS: land
BRANCH: tb/item-eyes  HEAD: the commit that adds this file (origin/main merged in just before)

- Row: Fulgocobra and Mirejaw eye emission / near-black heads (CREATURES-RALPH roster 5.78 / 5.84). Judges: "the hood/head merges with the backdrop and the face is lost"; a whole-body value lift was flat (b25).
- Change (coat flags, face only):
  - `face_read.py` rasterises each species' head triangles into a UV mask from the live remake GLB. Fulgocobra: the top 0.75 m of the 5.2 m body. Mirejaw: the front 0.9 m; its rig's head joint sits behind the snout.
  - Inside the mask: an albedo midtone gamma lift (0.45, hue kept), plus the live emission map ×5 (eyes, aqua spots, hood lines, all in the creature's element). Fulgocobra boosts its ON goldvein map, since later coat flags replace it.
  - The whole coat gets a material rim (0.6, tint 0.5), the fix the judges named.
  - No new floating effect, no red, no size change. Follows the 1 Nov creature rule (glow only in the creature's element).
- Rounds (neutral `capture_f36_poses.gd` stage with `--whole-body`, so both heads are in frame; the default stage crops both; job in `qj_job.json`):
  1. `qj/EYES-939043818257-11072232`: lift γ0.55, emission ×3, no rim. **Flat**, 6.14 -> 6.14.
  2. `qj/EYES-939043818257-11072236`: γ0.45, ×5, rim 0.6. **6.09 -> 6.78 (+0.69)**, r 0.85. All three judges: PRESENT -> PARTIAL.
- Flags ON: `data/config/creature_coat_flags.json:flags.lanekit_face_read_fulgocobra`, `...lanekit_face_read_mirejaw` (`_why_on` names r2).
- Tests: no OFF-asserts existed for these keys. test_creature_coat_flags (6 tests, 0 failed); test_remake_owner1101_finish + test_dark_value_lift_flags (8 tests, 0 failed).
- Files: creature_coat_flags.json; four new textures `*_Image_0_face.png`, `creature_fulgocobra_owner1101_glow_goldvein_face.png`, `creature_mirejaw_owner1101_arc_emission_face.png` (+ .import, compress mode 2 like their live siblings); face_read.py; qj_job.json; verdicts.
- Judges' remaining asks: Fulgocobra's eyes are still not visible at stage distance (its hood still dark); the hit react barely differs from idle on both; Mirejaw's frills do not read at small size; no visible storm trait on Fulgocobra beyond the hood lines.
- Next idea: a small eye-only emission boost on Fulgocobra (an eye mask by brightest emission texels inside the head mask), and a rim tint toward the element colour.

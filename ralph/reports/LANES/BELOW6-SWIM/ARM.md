# BELOW6-SWIM: the swimmer shows a body and a stroke (F39#5, 5.64)

**Flag:** `data/config/human_swim_visual.json surface_crawl_1112` (OFF; overlay turns it on).
**Code:** `scripts/player/trainer_model.gd`: `load_human_swim_visual` merges the flag's `swim_pose` last; `_apply_human_swim_pose` gains `arm_recover_lift` (0 keeps the old stroke). Test: `tests/test_surface_crawl_flag.gd`.

**Cause:** the two stroke candidates that are active on main (`uiposes_stroke_candidates`) set `chest_above_surface_m -0.14`, pitch 84 and `arm_depth 0.3`. The chest is under the surface and the arms reach below the body, so from the swim camera only the hair and the pack break the water: "a floating head with no stroke" (3/3).

**What the arm does (pose keys only):** chest 0.03 m above the surface, pitch 80, arms wider (0.6), arms just under the body plane, and on the recovery half of each cycle the arm arcs up out of the water (`arm_recover_lift 0.75`). Capsule, camera, speed, stamina and the network packet are unchanged; a remote trainer runs the same pose code from the packet it already gets.

**CPU look** (`_sheet_cpu_base_top_arm_bottom.jpg`: entry, surface west, surface mid; base top, arm bottom): shoulders, upper back and pack are above the water, one arm reaches forward out of the water and the other lies out at the surface. Round 1 (chest 0.16, lift 1.0) floated the whole body on top with both arms up; this is round 2. 0 script errors. No CPU judge batch.

**Risks:** in a still the raised arm can read as a wave. Water is opaque on CPU; on GPU more of the body may show through.

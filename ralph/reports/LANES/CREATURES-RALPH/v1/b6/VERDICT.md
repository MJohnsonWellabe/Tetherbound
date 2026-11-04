# Visual lane v1/b6: Tidewake camp bed (F39#12) and workbench (F39#13), Blender r1 (3 Nov 2026, ~15:05 UTC)

**Arms:** `meshy_camp_props.json` `bed.nest_candidate` and `workbench.vl_candidate` (r1 GLBs), both ON vs this branch's shipped Meshy props. Frames: `phase2_capture_tidewake_camps.gd --seed=2042` (bed and crafting views at three camps), CPU llvmpipe, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (craft, f36_0_npc:C9, f36_0_gap:C6; confirming batch), three fresh code-blind judges, `calibrate.py`: linear, slope 0.82, intercept 0.88, r 0.59, anchor RMSE 0.66, no warnings (a weak fit).

| Row | Item | CPU base (mapped) | r1 ON (mapped) | Decision |
|---|---|---|---|---|
| F39#12 | P2-115 camp creature bed | 5.39 | 5.83 (+0.44) | OFF; r2 next |
| F39#13 | P2-116 camp workbench | 5.75 | 5.36 (-0.39) | OFF; r2 next |

**Judges:**
- Bed: the r1 nest "now reads clearly as bedding" (defect PARTIAL 3/3), but it is "near-white on pale sand, almost no value separation" and oversized in view 1. Asked for a mid-value woven or straw rim.
  - Cause: the procedural colours were authored as linear values, which display much lighter in game; the same thing happened with Crown Arch r1.
  - r2 (`nest_bed_r2.glb`): golden straw, warm canvas, deeper teal, dark driftwood.
- Workbench: the r1 bench reads as "an upright pale board like a notice board", because the camp camera sees the back of its tool board, and the trainer still covers it in views 1-2.
  - r2 (`camp_workbench_r2.glb`): the same bench turned 180 deg so the tools face the camera.

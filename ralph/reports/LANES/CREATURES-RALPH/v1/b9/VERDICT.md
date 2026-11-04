# Visual lane v1/b9: Tidewake camp bed (F39#12) and workbench (F39#13), Blender r2 (3 Nov 2026, ~17:00 UTC)

**Arms:** `meshy_camp_props.json` `bed.nest_candidate` and `workbench.vl_candidate` with the r2 GLBs ON, vs this branch's shipped Meshy props. The r2 nest is golden straw with a warm canvas, deeper teal and driftwood. The r2 bench is turned to face the camp camera.

**Frames:** `phase2_capture_tidewake_camps.gd --seed=2042`, CPU llvmpipe, Compatibility. **Caveat:** the baseline is v1/b6's `camp_base` capture (same stands and seed, earlier run), not recaptured in this run.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (f36_0_gap:C2, a named Stormwood fight, craft; confirming batch), three fresh code-blind judges, `calibrate.py`: linear, slope 1.06, intercept 0.26, r 0.79, anchor RMSE 0.74, no warnings.

| Row | Item | CPU base (mapped) | r2 ON (mapped) | Decision |
|---|---|---|---|---|
| F39#12 | P2-115 camp creature bed | 5.86 | **7.02 (+1.16)** | **ON** |
| F39#13 | P2-116 camp workbench | 6.03 | **6.56 (+0.53)** | **ON** |

**Judges, nest:** "a thick straw-coloured cushion with a blue striped blanket, reads as a pet bed in all three frames". Defect FIXED 1, PARTIAL 2. They still note the nest looks oversized in view 1 and the tan sits close to the sand's value.

**Judges, bench:** "now reads as a workstation". Defect PARTIAL 3/3. The cream panel sits close to the sand's value and "looks like a placeholder card", and the trainer still covers part of it in view 1. Next lever: darker weathered wood.

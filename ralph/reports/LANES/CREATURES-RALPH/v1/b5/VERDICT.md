# Visual lane v1/b5: F38#19 comforter retint and F39#23 catch-chance readout (3 Nov 2026, ~14:15 UTC)

**Arms:**
- F38#19: `house_textiles.json` (loft bed comforter retinted from plum-maroon to sea-teal); frame `meadows__exploration_hud` from `phase2_capture_ui.gd --biome=meadows --seed=2042`; base = the v1 UI base run.
- F39#23: `capture_readout_visual.json` `readout_side_enabled` + `contrast_r2` (readout beside the ring and off the subject, caption 26 -> 32 px in primary text, plate 0.85 -> 0.96); frames from `phase2_capture_catch.gd --biome=tidewake --seed=2042`; base = the v1 UI base run.
- CPU llvmpipe, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22; confirming batch), three fresh code-blind judges, `calibrate.py`: linear, slope 1.57, intercept -1.95, r 0.90, anchor RMSE 0.50, no warnings.

| Row | Item | CPU base (mapped) | Arm ON (mapped) | Raw base / ON | Defect call | Decision |
|---|---|---|---|---|---|---|
| F38#19 | P2-004 exploration HUD | 5.23 | **5.92** (+0.69) | 4.5 4.3 4.9 / 4.9 4.8 5.3 | HUD-boxes defect PRESENT on both | `house_textiles` ON |
| F39#23 | P2-114 catch-chance HUD contrast | 6.02 | **6.91** (+0.89) | 5.0 4.9 5.3 / 5.6 5.6 5.7 | PRESENT -> FIXED (3/3) | `readout_side_enabled` + `contrast_r2` ON |

**Judges:**
- F38#19: all three flag the shipped maroon comforter as oxblood on a friendly object, and its teal replacement fits the palette. The HUD's seven dark boxes and the dim interior grade remain. The earlier lean-HUD arm (`hud_lean`, +0.21 in v1/ui1a) and an interior grade lift are the next levers.
- F39#23: "moved beside the target onto a solid dark panel with white caption text, clearly readable"; FIXED 3/3. The side camera now also shows foreground grass blades and a dark rock at the right edge, and the Throw/Cancel prompts are tiny.

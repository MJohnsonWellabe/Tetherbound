# G-closeout-f38-4-map: F38#4 map parchment fog, Medium close call pooled with High (GPU)

## Verdict: F38#4 CLOSES.

| Panel | High | Medium |
|---|---|---|
| G-restoredsea-mapfog (arm, High only) | 7.81 (7.76, 8.03, 7.63) | — |
| **This batch** (High arm frame and Medium on main, side by side) | **7.53** ↑top | **7.53** ↑top |
| **Pooled** | **7.67** | **7.53** |

- **Per judge in this batch:** 7.67, 7.11, 7.81 on both presets. The judges saw the two presets as identical (render difference 2.7).
- **Control:** F38#38 read 8.00 against its closing 8.16/8.30, so this panel is about 0.2 strict.
- **Confirming batch.** Both rows meet the bar only above the top anchor (7.53). The anchors reach 7.47/7.53, so this is the confirming batch.
- **Fit:** r 0.979, RMSE 0.20.
- **Medium is at the bar exactly (7.53).** With the strict control it holds, but with no margin. The row's next lever (below) would add margin.
- **Older score not pooled.** G-closeout-meadows-ui's 6.99 for F38#4 was main before #927 (the grey fog), so it is not part of this pool.

## What the judges say
- **Recorded defect:** PARTIAL 3/3. Roads, tree clumps and the village layout now show inside the surveyed circle. Outside it, "about 70% of the canvas is blank parchment grid", with no relief, water or landmark art.
- **On-direction (3/3):** the header art strip, tab bar and controller hint rows.
- **Minor:** the house, flag and player markers overlap in a tight cluster (1/3); the gold "You are here" line is small (1/3).
- **Next lever** (all 3 top changes): paint faint terrain, roads and landmark silhouettes across the whole canvas, not only the surveyed circle.

## Frames
- **High:** the `G-things-mapfog` arm frame (`tb/things` 31b5e5879 + `overlay_map_parchment.json`), map-area mean 157/146/115.
- **Medium:** `G-closeout-f38-4-map-medium`, main 506b40292 (the #927 merge), `phase2_capture_ui.gd --biome=meadows --seed=2042 --preset=Medium`, map-area mean 157/146/115.
- **Control:** F38#38's closing frames.
- **Sets:** High on one side and Medium on the other, 1280×720. Brief: "one catalogue subject in the meadows biome: map". The recorded defect is the job.json defect.

## Batch `G-mpm`
- Three code-blind judges, standard prompt, two candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.4145, intercept −1.9465, r 0.979, anchor RMSE 0.20.

**Raw Bar A (judges a, b, c; both presets):**

| Row | Raw |
|---|---|
| F38#4 | 6.8, 6.4, 6.9 |
| F38#38 | 7.2, 6.8, 7.1 |

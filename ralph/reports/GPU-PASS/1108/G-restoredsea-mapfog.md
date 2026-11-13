# G-restoredsea-mapfog: restored sea (F39#17, LANE-BELOW6) and map parchment fog (F38#4, LANE-THINGS) (GPU High)

## Verdicts

| Arm | Set | Base | Arm | Gain | Prefer arm | Verdict |
|---|---|---|---|---|---|---|
| restored_sea_1112 | **F39#17 row** (S1/S2 live and restored, t0) | 6.21 | **6.88** | +0.67 | 3/3 | SPLIT. **Do not ship as is:** fails no-loss |
| restored_sea_1112 | F39#17 other stands (S3 waterfall, S4 sunset; restored t0 and t1) | 6.61 | 6.17 | **−0.44** | **0/3** | |
| map_parchment | **F38#4 row** (map) | 7.36 | **7.81** ↑top | +0.45 | 3/3 | **SHIP.** Meets the bar at High (7.76, 8.03, 7.63); needs Medium |

## F39#17 restored sea
- **Row (S1, S2):** the arm makes the restoration read.
  - "Pale concentric current bands sweep around the islands", with curved current arcs in the restored moments (3/3).
  - Base's moments are "nearly identical", so the restoration "barely reads".
  - Recorded defect: PRESENT on base 3/3, PARTIAL on the arm 3/3.
- **Other stands (S3 waterfall, S4 sunset): the arm loses.**
  - All three judges prefer base: "the sunset foreground keeps teal reflections and ripples", while on the arm "the foreground sunset water is near black and loses all form".
  - Base's day shallows also read "more turquoise".
  - This matches the GPU lane's note that S3 and S4 change less on the arm. The change that does happen there darkens the water.
- **Both sides** (3/3):
  - a hard-edged dark-navy wedge or shadow band across the water at the horizon;
  - a blown-out vertical sun-glint pillar at sunset;
  - flat sand-disc islands with sparse, evenly spaced props;
  - no shoreline foam.
- **Next:**
  - keep the restored current bands;
  - scope the deeper water to S1/S2, or put a floor on its darkening at low sun so S3/S4 keep their teal;
  - re-judge with the S3/S4 restored frames as the no-loss set.
  - Shoreline foam and the horizon wedge are the next levers for the row.

## F38#4 map fog
- **The arm wins 3/3.** Its lighter parchment fog "lets the groves and roads read". Base's fog is "dark, mottled grey-brown ... dirty smudges".
- **Recorded defect** (no terrain context): FIXED 1/3, PARTIAL 2/3 on the arm.
  - Terrain shows only inside the surveyed circle, and most of the canvas is still fog at 0% surveyed.
  - The map canvas is small, with dead space below the legend.
- **Close:** 7.81 at High, above the top anchor. This batch's anchors reach 7.47/7.53, so it is the confirming batch.
  - It needs Medium to close. A UI capture with `--preset=Medium` should be close to High.
  - Note: G-closeout-meadows-ui scored the map at 6.99 on main with a stricter panel. This batch's base reads 7.36, so pool the panels before closing.

## Frames
- **F39#17:** `G-below6-restored-sea` (a201a1ef6), High.
  - Capture: `phase2_capture_current_states.gd --seed=2042 --fixed-fps 20`.
  - Build: `tb/below6` f29722b0d on both sides.
    - **base:** no overlay.
    - **arm:** `BELOW6-RESTORED-SEA/overlay.json` (`restored_sea_1112`).
  - 0 script errors. The sky heuristic was bypassed after an eye check, because calm open sea reads as sky.
  - **Row set:** S1_live_t0, S1_restored_t0, S2_live_t0 and S2_restored_t0, in a 2×2 grid.
  - **No-loss set:** S3_restored_t0/t1 and S4_restored_t0/t1.
  - **Render check:** mean difference 5.0 on the row set, 3.4 on the other stands. Live frames are unchanged (GPU lane: 0.01–0.29).
- **F38#4:** `G-things-mapfog` (936c1d705), High, job frame `meadows__menu_map`.
  - Build: `tb/things` 31b5e5879 on both sides.
    - **base:** no overlay.
    - **arm:** `THINGS-MAPFOG/overlay_map_parchment.json`.
  - **Render check:** mean difference 11.8. GPU lane: map-area mean 142/135/108 → 157/146/115.

## Batch `G-rsm`
- Three code-blind judges, standard prompt, three candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.3315, intercept −1.4228, r 0.922, anchor RMSE 0.54.
- **Warning:** F38#4 arm meets the bar only above the top anchor (7.53). This batch is its confirming batch.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F39#17 row | 5.2, 6.2, 5.8 | 5.9, 6.5, 6.3 |
| F39#17 other stands | 5.6, 6.6, 5.9 | 5.2, 6.3, 5.6 |
| F38#4 | 6.5, 6.8, 6.5 | 6.9, 7.1, 6.8 |

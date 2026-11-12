# GPU re-score 1108, section F-cloudreach: Cloudreach catalogue rows (GPU High, mapped)

- **Frames:** `tb/gpu-frames-1108`, manifest-F-cloudreach.json (7416d0d8). It covers 17 rows and 45 entries; 4 frames are missing:
  - F40#3 old_wind_observatory approach;
  - F40#6 terrace 02.0s and 03.0s;
  - F40#11 terrace 02.0s.
  - Rows with missing frames were judged on the frames that exist: F40#3 on 2 of 3, F40#6 on 1 of 3, F40#11 on 2 of 3. Live tree be95950b on an NVIDIA GTX 1060, Forward+ High 1920x1080, JPEG q85.
- **F40#5 (Veyra fight was lost, won=false):**
  - Its frames are nearest-tick matches within 0.55 s (live-2430, live-3510, live-3870).
  - I checked all three before judging. None shows a defeat or loss card: all are mid-fight HUD frames with "staggered", "punish now" and "recovering" banners and TEAM 5/5.
  - So no frame was excluded; all three were judged. The fight's outcome is not visible in any judged frame.
- **Yardstick:** `tools/visual_judge/`.
  - Standard JUDGE_PROMPT, one batch of 17 rows, three fresh code-blind judges.
  - 3 pinned anchor pairs: craft, f10_2_r3_capacitor and f04_6_r22.
  - Scores mapped with a `calibrate.py` linear fit.
- **Fit:** slope 1.090, intercept -0.097, r 0.823, anchor RMSE 0.656. Confirming batch (top anchor 7.35); no warnings.
- **Sets:** one-sided, so each judge's score is the mean of the two sides. All three judges scored both sides of every one-sided set identically.
- **Side images:** each row's frames (up to 4) in a 2x2 grid at 640x360, or a single frame at 1280x720.
- **Score columns:**
  - "Last CPU / board" is from the LANE-SCOUT QUEUE.
  - "Earlier GPU Compat" is the 1060 OpenGL Compatibility item score from `VISUAL/item-scores/cloudreach/VERDICT-gpu.md`.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~02:40 UTC. Judge folders and replies stayed local.

| Row | GPU High mapped | Mapped per judge | Raw per judge | Defect calls (j1, j2, j3) | Last CPU / board score | Earlier GPU Compat | Batch / note |
|---|---|---|---|---|---|---|---|
| F40#6 | **5.10** | 5.25 / 4.92 / 5.14 | 4.9 / 4.6 / 4.8 | PRESENT, PRESENT, PRESENT | 6.10 (board); GPU 4.92. | 4.92 | b1 |
| F40#11 | **5.50** | 5.57 / 5.25 / 5.68 | 5.2 / 4.9 / 5.3 | PRESENT, PRESENT, PRESENT | 6.43 (board); GPU 5.16. | 5.16 | b1 |
| F40#9 | **5.72** | 5.68 / 5.57 / 5.90 | 5.3 / 5.2 / 5.5 | PRESENT, PRESENT, PRESENT | 5.20 (board); GPU 5.50. | 5.50 | b1 |
| F40#8 | **5.85** | 5.85 / 5.68 / 6.01 | 5.5 / 5.3 / 5.6 | PARTIAL, PARTIAL, PARTIAL | 6.32 (board); GPU 5.72. | 5.72 | b1 |
| F40#3 | **5.86** | 5.68 / 5.90 / 6.01 | 5.3 / 5.5 / 5.6 | PRESENT, PARTIAL, PRESENT | 6.46 (board). | 6.14 | b1 |
| F40#1 | **5.90** | 5.90 / 6.01 / 5.79 | 5.5 / 5.6 / 5.4 | PARTIAL, PARTIAL, PRESENT | - | 5.29 | b1 |
| F40#5 | **5.94** | 6.01 / 5.79 / 6.01 | 5.6 / 5.4 / 5.6 | PARTIAL, PARTIAL, PRESENT | 6.39 (board, GPU). | 6.39 | b1 |
| F40#15 | **6.08** | 5.90 / 5.79 / 6.55 | 5.5 / 5.4 / 6.1 | FIXED, PARTIAL, FIXED | 6.36 (board, GPU; 3/3 FIXED). | 6.36 | b1 |
| F40#17 | **6.08** | 5.79 / 6.01 / 6.45 | 5.4 / 5.6 / 6.0 | PARTIAL, FIXED, FIXED | 6.19 (board); GPU 5.90. | 5.90 | b1 |
| F40#4 | **6.12** | 6.01 / 6.12 / 6.23 | 5.6 / 5.7 / 5.8 | PARTIAL, PARTIAL, PARTIAL | 6.27 (board); `ITEM-F40-4/READY.md` parked (strata cliff arms flat). | 5.41 | b1 |
| F40#2 | **6.15** | 6.01 / 6.01 / 6.45 | 5.6 / 5.6 / 6.0 | PARTIAL, PARTIAL, PARTIAL | 6.16 (board, NEAR6-CR CPU); `ITEM-F40-2/READY.md` parked (stone-ground and scattered-stone arms lost or were invisible). | 5.81 | b1 |
| F40#13 | **6.19** | 6.45 / 6.23 / 5.90 | 6.0 / 5.8 / 5.5 | PARTIAL, PARTIAL, PRESENT | - | 6.69 | b1 |
| F40#16 | **6.19** | 6.12 / 6.01 / 6.45 | 5.7 / 5.6 / 6.0 | FIXED, FIXED, FIXED | 6.48 (board, GPU; 3/3 FIXED). | 6.48 | b1 |
| F40#7 | **6.26** | 6.23 / 6.23 / 6.34 | 5.8 / 5.8 / 5.9 | PARTIAL, PARTIAL, PARTIAL | 6.22 (board); GPU 5.87. | 5.87 | b1 |
| F40#10 | **6.74** | 6.88 / 6.45 / 6.88 | 6.4 / 6.0 / 6.4 | PARTIAL, PARTIAL, PARTIAL | - | 5.60 | b1 |
| F40#18 | **7.10** | 6.88 / 6.88 / 7.54 | 6.4 / 6.4 / 7.0 | FIXED, FIXED, FIXED | - | - | b1 |
| F40#12 | **7.17** | 7.10 / 7.10 / 7.32 | 6.6 / 6.6 / 6.8 | FIXED, FIXED, FIXED | - | 5.01 | b1 |

**Rows at 7.5 or above:** none.

**Near the bar (7.0–7.49):** F40#12 dialogue speaker visibility at 7.17 (FIXED 3/3), and F40#18 full-party catch choice at 7.10 (FIXED 3/3; one judge would give 7.54).

## Judges' main findings (all three unless noted)
- **Lowest:**
  - **F40#6 mounted terrace and cloud crossing, 5.10 (PRESENT 3/3):** the deer and rider slide upright down the cliff face, over white puffs and the faceted cloud floor, with nothing holding them up. It was judged on its one existing frame.
  - **F40#11 terrace edge clouds, 5.50 (PRESENT 3/3):** flat white puffs are stacked against the cliff in front of a polygonal cloud floor.
  - **F40#9 NPC posts, 5.72 (PRESENT 3/3):** the NPCs are small and sit behind the trainer or behind trees.
- **F40#5 captain fight camera, 5.94:** in frames 1 and 3 a dust cloud covers the exchange. One judge says Aeriex is cropped at the HUD edge, and the HUD covers about 40% of the frame.
- **F40#15 floating dark strips, 6.08 (2 of 3 FIXED for the Je cameras):** all three judges saw the dark straight strip still crossing the grass in the F40#8 bridge frames, lower left, in all three frames.
- **F40#13 catch feedback, 6.19:** "Pebbik broke free" still shows while "100% CAPTURE CHANCE" is on screen in frame 2. The stale message has moved to the top, but it is not cleared.
- **F40#16 and F40#17 mushrooms:** both FIXED, but all three judges call the caps oversized and toy-saturated against the stylised-realism direction.
- **F40#2 aviary, 6.15:** now a solid domed rotunda with lit night windows, but still a small isolated building on flat grass. The board's cliff, layering and waterfalls are missing; 2 judges list it as new_art.
- **Batch-wide:**
  - Flat grass discs with extruded rims (F40#1, F40#4, F40#7, F40#3).
  - A faceted cloud floor.
  - No height fog or aerial perspective.
- **Top changes named:**
  1. Soft layered or volumetric cloud banks in place of the faceted floor and puffs, with mounts kept on the terrace edge (scene, 3/3).
  2. Stratified terraces and ledges in place of lawn discs (scene from 2 judges, new_art from 1).
  3. A cliff-built aviary sanctuary (new_art, 2/3).
  4. Camera fixes for fights and dialogue (scene).

## F40#5 re-shot with seed 2043 (`manifest-F-veyra-seed2043.json`, 612c1b95)
- The Veyra live fight was captured again with `--seed=2043` on the same tree (be95950b, High, nearest-tick frames live-2430, live-3510 and live-3870).
- **The manifest records `won: false` again, so the fight was lost a second time.** Per the coordinator, a lost re-run is noted, not judged; F40#5 stays at 5.94 from the seed 2042 frames.
- I looked at the three frames. None shows a defeat card; all are mid-fight, with "HEAVY - get clear", "STRONG - you hit a weakness" and "staggered - punish now" banners and TEAM 5/5.
- To judge the fight's result frames, F40#5 needs a seed or input on which the fight is won.

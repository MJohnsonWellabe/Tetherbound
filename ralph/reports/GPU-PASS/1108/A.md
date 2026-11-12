# GPU re-score 1108, section A: live re-baseline (GPU High, mapped)

- Frames: `tb/gpu-frames-1108` manifest-A2.json (8b1c5e39, 23 of 24 frames); live tree be95950b, NVIDIA GTX 1060, Forward+ High 1920x1080, JPEG q85. Fetched with `git fetch --depth 1`.
- Yardstick: `tools/visual_judge/` standard JUDGE_PROMPT, three fresh code-blind judges, 3 anchor pairs pinned (craft, f10_2_r3_capacitor, f04_6_r22), `calibrate.py` linear fit.
- Fit: slope 1.423, intercept -2.0241, r 0.907, anchor RMSE 0.486; top anchor 7.35, so this is a confirming batch. Warnings: ["some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)"].
- Sets are one-sided (the same live image on both sides, as the 28 Oct GPU item scores did); each judge's score is the mean of the two sides, and all three judges scored both sides identically on every one-sided set.
- Side images: each row's frames (up to 4) in a 2x2 grid at 640x360 per tile, or one frame at 1280x720.
- Judged by LANE-SCOUT, 8 Nov 2026 ~23:20 UTC. Judge folders and replies stayed local.

| Row | GPU High mapped | Mapped per judge | Raw per judge | Defect calls (j1, j2, j3) | Last CPU / board score | Note |
|---|---|---|---|---|---|---|
| F38#24 | **3.67** | 4.09 / 3.53 / 3.38 | 4.3 / 3.9 / 3.8 | PRESENT, PRESENT, PRESENT | 3.51 (CPU, #849) |   |
| F38#30 | **4.00** | 4.24 / 3.95 / 3.81 | 4.4 / 4.2 / 4.1 | PRESENT, PRESENT, PRESENT | 3.51 (CPU, #849) | same Warrens frames as F38#24 (walk_02/03)  |
| F41#15 | **5.71** | 5.80 / 5.66 / 5.66 | 5.5 / 5.4 / 5.4 | PARTIAL, PARTIAL, PARTIAL | 5.90 board (GPU 28 Oct 3.19) |   |
| F41#16 | **6.28** | 6.37 / 6.37 / 6.09 | 5.9 / 5.9 / 5.7 | PARTIAL, PARTIAL, PARTIAL | 5.05 (board) | judged on 99-after only: `hollows_alpha-i13` was never packed  |
| F39#20 | **6.37** | 6.09 / 6.51 / 6.51 | 5.7 / 6.0 / 6.0 | PARTIAL, FIXED, FIXED | 6.42 (CPU, #820) | tell-start-001_65 is the 1.12 s nearest-time frame  |
| F39#7 | **6.61** | 6.66 / 6.80 / 6.37 | 6.1 / 6.2 / 5.9 | FIXED, FIXED, PARTIAL | 5.65 (GPU 28 Oct) |   |
| F39#23 | **6.80** | 6.51 / 7.08 / 6.80 | 6.0 / 6.4 / 6.2 | PARTIAL, FIXED, PARTIAL | 5.62 (CPU, #832) |   |
| F39#19 | **6.85** | 6.80 / 6.94 / 6.80 | 6.2 / 6.3 / 6.2 | FIXED, FIXED, FIXED | 5.78 (GPU 28 Oct) | tell-start-000_48 is a nearest-time match  |
| F38#19 | **6.89** | 6.80 / 6.80 / 7.08 | 6.2 / 6.2 / 6.4 | PARTIAL, PARTIAL, PARTIAL | 5.69 (CPU, #846; settled stand 6.58 CPU) |   |
| F40#14 | **6.99** | 7.08 / 6.94 / 6.94 | 6.4 / 6.3 / 6.3 | FIXED, FIXED, FIXED | 5.87 (GPU 28 Oct) |   |

**Rows at 7.5 or above (need a Medium capture):** none.

## Judges' main findings (all three unless noted)
- **F38#24 / F38#30 (Warrens, stronghold route): large flat black slab shapes fill the upper sky in the walk_03 frame, with leaf particles scattered over them.** This is a severe GPU-only artefact; no continuous mountain silhouette appears in any frame, and the hillside is a faceted brown cut face. Both rows stay at the bottom (3.67 / 4.00), and the slabs are the first thing to find (likely a far mesh or card rendering black on Forward+).
- **F41#15:** no creature hides the speaker now, but **Captain Marrow's face and hair blow out to pure white (bloom or material) in both Marrow frames**, and an orange-haired foreground head is cut by the left edge in two frames. GPU 3.19 -> 5.71.
- **F41#16:** a gold-bordered "BATTLE LOST" box now appears and Sparkit shows KO, but its text is tiny, the header still reads TEAM 5/5 with four green bars, and "Sparkit is out of the fight." still sits over the exploration hints (PARTIAL 3/3).
- **F39#7 / F39#19 / F39#20:** stacking, the faded roster and the buried figure are fixed (one judge still sees a small half-sunk figure in F39#20). New asks: the trainer clips Ripplet's back in F39#20 frame 3 and stands inside Cannonback's flank in F39#19 frame 2; a hard black cliff wedge or void in the top-right corner of the Venn frames.
- **F40#14:** the label now wraps (FIXED 3/3), but the map body is blurry fog with one revealed tile.
- **F38#19:** the hint strip and quickbar crowd the lower centre over the trainer (PARTIAL 3/3).
- **F39#23:** the backed odds panel reads (FIXED or PARTIAL); asks are the empty dune and a dark monolith on the ridge.
- Top changes named across the batch: remove the black sky slabs and give the Meadows horizon a continuous mountain backdrop (scene / new art); replace the flat magenta fight telegraphs with grounded effects and keep the Stormwood fight camera out of the canopy (scene; anchor frames); slim the HUD and enlarge result-card text (scene).

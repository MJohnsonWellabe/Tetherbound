# GPU re-score 1108, section F-meadows: Meadows catalogue rows (GPU High, mapped)

- **Frames:** `tb/gpu-frames-1108`, manifest-F-meadows.json (50257949). That is 30 rows and 79 files, with no missing frames.
  - Live tree be95950b on an NVIDIA GTX 1060, Forward+ High 1920x1080, JPEG q85.
  - Fetched with `git fetch --depth 1`.
- **Yardstick:** `tools/visual_judge/`.
  - Standard JUDGE_PROMPT.
  - Two batches of 15 rows, round-robin. Each batch had three fresh code-blind judges, so six in all.
  - Each batch carried 3 pinned anchor pairs: craft, f10_2_r3_capacitor and f04_6_r22.
  - Scores mapped with a `calibrate.py` linear fit per batch.
- **Fit, batch 1:** slope 1.292, intercept -1.4756, r 0.8652, anchor RMSE 0.578. It is a confirming batch (top anchor 7.35). No warnings.
- **Fit, batch 2:** slope 1.585, intercept -2.931, r 0.8938, anchor RMSE 0.517. It is a confirming batch (top anchor 7.35).
  - Warning: "meets the bar only above the top anchor (7.35): F38#18, F38#23, F38#38; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch".
  - Batch 2's judges scored the anchors about 0.2–0.5 lower than batch 1's did, so its steeper slope lifts its top rows.
  - Read F38#18, F38#23 and F38#38 with that margin: they map to 7.6–8.2, but their raw scores are 6.3–7.2.
- **Sets:** all one-sided (the same live image on both sides). Each judge's score is the mean of the two sides, and all six judges scored both sides of every one-sided set identically.
- **Side images:** each row's frames (up to 4) in a 2x2 grid at 640x360 per tile, or a single frame at 1280x720.
- **Column "Last CPU / board":** taken from the LANE-SCOUT QUEUE.
- **Column "Earlier GPU Compat":** the 1060 OpenGL Compatibility item score from `VISUAL/item-scores/meadows/VERDICT-gpu.md` (main b7a6e8bbe; * marks a low-confidence batch).
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~01:00 UTC. Judge folders and replies stayed local.

| Row | GPU High mapped | Mapped per judge | Raw per judge | Defect calls (j1, j2, j3) | Last CPU / board score | Earlier GPU Compat | Batch / note |
|---|---|---|---|---|---|---|---|
| F38#8 | **5.46** | 4.98 / 5.63 / 5.76 | 5.0 / 5.5 / 5.6 | PRESENT, PRESENT, PRESENT | 6.12 (board, GPU). | 6.12* | b1  |
| F38#1 | **5.76** | 5.50 / 5.76 / 6.02 | 5.4 / 5.6 / 5.8 | PARTIAL, PARTIAL, PARTIAL | 6.30 (board); GPU 5.93 (captured before the 4 Nov pose-still fix, TECHNICAL §8.1). | 5.93* | b1  |
| F38#31 | **5.85** | 5.63 / 5.89 / 6.02 | 5.5 / 5.7 / 5.8 | PARTIAL, PARTIAL, PRESENT | - | 5.65 | b1  |
| F38#27 | **5.89** | 6.26 / 5.94 / 5.47 | 5.8 / 5.6 / 5.3 | PRESENT, PRESENT, PRESENT | 6.32 (board, GPU). | 6.32* | b2  |
| F38#28 | **5.97** | 6.02 / 6.28 / 5.63 | 5.8 / 6.0 / 5.5 | PARTIAL, PARTIAL, PRESENT | - | 6.09* | b1  |
| F38#2 | **6.00** | 6.58 / 5.94 / 5.47 | 6.0 / 5.6 / 5.3 | PRESENT, PARTIAL, PRESENT | 6.40 (board); GPU 5.52 (also before the 4 Nov fix). | 5.52 | b2  |
| F38#20 | **6.02** | 5.76 / 6.28 / 6.02 | 5.6 / 6.0 / 5.8 | PARTIAL, PARTIAL, PARTIAL | - | 5.67 | b1  |
| F38#29 | **6.05** | 5.94 / 6.26 / 5.94 | 5.6 / 5.8 / 5.6 | PRESENT, PRESENT, PRESENT | 6.18 (board; NEAR6-MS CPU, `beaten_trainer_stance.immediate_1104` and `silent_victory_shot_1104` ON). | 6.12* | b2  |
| F38#12 | **6.06** | 6.02 / 6.02 / 6.15 | 5.8 / 5.8 / 5.9 | PARTIAL, PARTIAL, PARTIAL | - | 5.47 | b1  |
| F38#14 | **6.06** | 5.76 / 6.15 / 6.28 | 5.6 / 5.9 / 6.0 | PARTIAL, PARTIAL, PARTIAL | 6.23 (board); GPU 6.06. | 6.06 | b1  |
| F38#22 | **6.10** | 6.15 / 6.02 / 6.15 | 5.9 / 5.8 / 5.9 | PARTIAL, PARTIAL, PARTIAL | - | 5.98 | b1  |
| F38#6 | **6.10** | 5.76 / 6.28 / 6.28 | 5.6 / 6.0 / 6.0 | PARTIAL, PARTIAL, PARTIAL | - | 5.52 | b1  |
| F38#25 | **6.23** | 6.15 / 6.28 / 6.28 | 5.9 / 6.0 / 6.0 | PARTIAL, PARTIAL, PARTIAL | 6.21 (board); GPU 6.06. | 6.06 | b1  |
| F38#35 | **6.31** | 6.26 / 6.58 / 6.10 | 5.8 / 6.0 / 5.7 | PRESENT, PRESENT, PRESENT | 5.88 (board, GPU). | 5.88 | b2  |
| F38#3 | **6.49** | 6.28 / 6.53 / 6.66 | 6.0 / 6.2 / 6.3 | PARTIAL, PARTIAL, PARTIAL | 6.26 (board, GPU). | 6.26* | b1  |
| F38#10 | **6.58** | 6.28 / 6.66 / 6.79 | 6.0 / 6.3 / 6.4 | PARTIAL, PARTIAL, PARTIAL | - | 6.40 | b1  |
| F38#16 | **6.75** | 6.92 / 6.66 / 6.66 | 6.5 / 6.3 / 6.3 | FIXED, FIXED, FIXED | - | 6.94 | b1  |
| F38#34 | **6.75** | 6.66 / 6.79 / 6.79 | 6.3 / 6.4 / 6.4 | FIXED, FIXED, FIXED | - | 6.65 | b1  |
| F38#37 | **6.75** | 6.79 / 6.79 / 6.66 | 6.4 / 6.4 / 6.3 | PARTIAL, PARTIAL, PARTIAL | 6.09 (board); GPU 4.64. | 4.64 | b1  |
| F38#15 | **6.84** | 7.21 / 6.58 / 6.74 | 6.4 / 6.0 / 6.1 | PARTIAL, PARTIAL, PARTIAL | - | 5.88 | b2  |
| F38#11 | **6.89** | 7.21 / 7.05 / 6.42 | 6.4 / 6.3 / 5.9 | PARTIAL, PARTIAL, PARTIAL | 6.29 (board); GPU 6.59. | 6.59 | b2  |
| F38#21 | **7.00** | 7.37 / 6.89 / 6.74 | 6.5 / 6.2 / 6.1 | PARTIAL, PARTIAL, PARTIAL | 6.23 (board); GPU 6.06. | 6.06 | b2  |
| F38#13 | **7.16** | 7.53 / 6.89 / 7.05 | 6.6 / 6.2 / 6.3 | PARTIAL, PARTIAL, PARTIAL | - | 5.21 | b2  |
| F38#4 | **7.21** | 7.37 / 7.37 / 6.89 | 6.5 / 6.5 / 6.2 | PARTIAL, PARTIAL, PARTIAL | - | 6.06 | b2  |
| F38#7 | **7.26** | 7.53 / 7.21 / 7.05 | 6.6 / 6.4 / 6.3 | PARTIAL, PARTIAL, PARTIAL | - | 5.82 | b2  |
| F38#33 | **7.32** | 7.53 / 7.21 / 7.21 | 6.6 / 6.4 / 6.4 | PARTIAL, PARTIAL, PARTIAL | - | 5.76 | b2  |
| F38#9 | **7.32** | 7.37 / 7.37 / 7.21 | 6.5 / 6.5 / 6.4 | PARTIAL, PARTIAL, PARTIAL | - | 6.58 | b2  |
| F38#23 | **7.58** | 8.16 / 7.53 / 7.05 | 7.0 / 6.6 / 6.3 | FIXED, FIXED, FIXED | - | 6.59 | b2 **7.5+: needs Medium** |
| F38#18 | **7.95** | 8.16 / 8.16 / 7.53 | 7.0 / 7.0 / 6.6 | PARTIAL, PARTIAL, PARTIAL | - | 7.53 | b2 **7.5+: needs Medium** |
| F38#38 | **8.16** | 8.48 / 8.16 / 7.84 | 7.2 / 7.0 / 6.8 | FIXED, FIXED, FIXED | - | 6.86 | b2 **7.5+: needs Medium** |

**Rows at 7.5 or above (need a Medium capture):** F38#38 craft hint contrast (8.16), F38#18 craft recipe text (7.95) and F38#23 Tether Relay yard (7.58). All three are mapped above the top anchor in a confirming batch. Raw means are 7.0, 6.9 and 6.6, so treat F38#23 as marginal.

**Near the bar (7.0–7.49):** F38#9 menu shell 7.32, F38#33 catch result 7.32, F38#7 catch aim 7.26, F38#4 map 7.21, F38#13 catch camera 7.16 and F38#21 ground cover 7.00. All six are batch-2 rows, so the same slope caveat applies.

## Judges' main findings (all three in the batch unless noted)
- **Craft UI (F38#18, F38#38):**
  - The hint footer is white, with glyph prompts and an orange "Missing" state. FIXED 3/3 on F38#38.
  - The only remaining recipe defect is the cut-off line "Prime Orb 4 Ironwood · 2 Rootstone · 4 F…". PARTIAL 3/3 on F38#18.
- **Relay yard (F38#23):** clean cobble with no overgrowth (FIXED 3/3). Two judges say frame 1's cobbles are overbright and the props are sparse.
- **Up on GPU High against the earlier Compat score:**
  - F38#37 rock obstruction: 4.64 -> 6.75.
  - F38#13 catch camera: 5.21 -> 7.16.
  - F38#7 catch aim: 5.82 -> 7.26, with the backed chance plate reading.
  - F38#33 catch result: 5.76 -> 7.32.
  - F38#15 flight/landing: 5.88 -> 6.84, now with a perch pose.
- **Still lowest:**
  - **F38#8 Fly carrier pose, 5.46 (PRESENT 3/3):** the trainer hangs rigidly with raised straight arms. All three judges list a shoulder-grip pose as new_art.
  - **F38#1 faint pose, 5.76:** Terrapup's frame 3 is a pale, see-through sprawl that reads as floating.
  - **F38#31 alpha read, 5.85:** the alpha coyote is barely larger than its normal form. One judge says it is about trainer height.
  - **F38#27 settings, 5.89 (PRESENT 3/3):** tiny grey rows and literal key labels.
  - **F38#28 Warden rail, 5.97:** a thin teal ring still crosses Terrapup in frames 1–2 per one judge. The creatures carry a ghostly rim glow.
- **Batch-wide asks:**
  - Creatures render with a pale, translucent fresnel rim on GPU High (F38#28, F38#2, F38#7, F38#13, F38#1); all 6 judges mention it, and 2 put it in their top changes.
  - The "TRAIL CAMP" sign's first glyph renders broken in F38#22 frame 3 (3/3 in batch 1).
  - Toy-like candy and potion pickups in F38#6.
  - Flat white smoke puffs bury both fighters in F38#3 and F38#11.
  - NPC role idles and a defeated slump for F38#35 and F38#29 (new_art).
- **Top changes the judges named (scene unless marked):**
  1. Remove the translucent rim from creatures and ground them with contact shadows.
  2. Replace the flat catch orb and the puff impacts with real-object effects.
  3. A Fly shoulder-grip pose, NPC role idles and a defeated pose (new_art).

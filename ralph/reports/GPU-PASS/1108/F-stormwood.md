# GPU re-score 1108, section F-stormwood: Stormwood catalogue rows (GPU High, mapped)

- **Frames:** `tb/gpu-frames-1108`, manifest-F-stormwood.json (7416d0d8), 17 rows.
  - Live tree be95950b on an NVIDIA GTX 1060, Forward+ High 1920x1080, JPEG q85.
- **Not judged: F41#16.** Its only listed frame (`hollows_alpha-i12`) is null. Section A scored it on the 99-after frame alone, at 6.28.
- **Yardstick:** `tools/visual_judge/`.
  - Standard JUDGE_PROMPT, one batch of 16 rows, three fresh code-blind judges.
  - 3 pinned anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22).
  - Scores mapped with a `calibrate.py` linear fit.
- **Fit:** slope 1.169, intercept -0.449, r 0.802, anchor RMSE 0.690. This is a confirming batch (top anchor 7.35), with no warnings. Judge 2 scored about 0.4 above the others on most rows, so the spread is wider than in the other biomes.
- **Sets:** one-sided, so each judge's score is the mean of the two sides. All three judges scored both sides of every one-sided set identically.
- **Side images:** each row's frames (up to 4) in a 2x2 grid at 640x360, or a single frame at 1280x720.
- **Score sources:**
  - "Last CPU / board" comes from the LANE-SCOUT QUEUE.
  - "Earlier GPU Compat" is the 1060 OpenGL Compatibility item score from `VISUAL/item-scores/stormwood/VERDICT-gpu.md`.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~02:45 UTC. Judge folders and replies stayed local.

| Row | GPU High mapped | Mapped per judge | Raw per judge | Defect calls (j1, j2, j3) | Last CPU / board score | Earlier GPU Compat | Batch / note |
|---|---|---|---|---|---|---|---|
| F41#13 | **5.59** | 5.63 / 5.98 / 5.16 | 5.2 / 5.5 / 4.8 | PRESENT, PRESENT, PRESENT | - | 4.54 | b1 |
| F41#1 | **5.78** | 5.86 / 5.75 / 5.75 | 5.4 / 5.3 / 5.3 | PARTIAL, PARTIAL, PARTIAL | 5.24 CPU (`ITEM-F41-1/READY.md`, root vault ON). | 4.41 | b1 |
| F41#21 | **5.78** | 5.75 / 6.21 / 5.39 | 5.3 / 5.7 / 5.0 | PRESENT, PRESENT, PRESENT | - | 4.92 | b1 |
| F41#3 | **5.78** | 5.63 / 6.10 / 5.63 | 5.2 / 5.6 / 5.2 | PRESENT, PARTIAL, PRESENT | 5.98 (board); GPU 5.98. | 5.98 | b1 |
| F41#10 | **6.02** | 6.21 / 6.21 / 5.63 | 5.7 / 5.7 / 5.2 | PARTIAL, PARTIAL, PARTIAL | 5.36 (board); GPU 3.19 (28 Oct). | 3.19 | b1 |
| F41#5 | **6.06** | 5.86 / 6.56 / 5.75 | 5.4 / 6.0 / 5.3 | PARTIAL, PARTIAL, PARTIAL | 5.35 (board); GPU 5.24 (28 Oct). | 5.24 | b1 |
| F41#18 | **6.10** | 5.98 / 6.56 / 5.75 | 5.5 / 6.0 / 5.3 | PARTIAL, PARTIAL, PARTIAL | 5.98 (board); GPU 3.91. | 3.91 | b1 |
| F41#2 | **6.10** | 5.98 / 6.33 / 5.98 | 5.5 / 5.8 / 5.5 | PRESENT, PRESENT, PRESENT | 5.80 (board); GPU 5.69. | 5.69 | b1 |
| F41#4 | **6.37** | 6.21 / 6.80 / 6.10 | 5.7 / 6.2 / 5.6 | PARTIAL, PARTIAL, PARTIAL | 5.92 (board); GPU 4.54. | 4.54 | b1 |
| F41#19 | **6.56** | 6.56 / 7.03 / 6.10 | 6.0 / 6.4 / 5.6 | PARTIAL, FIXED, PARTIAL | - | 5.15 | b1 |
| F41#12 | **6.60** | 6.56 / 6.68 / 6.56 | 6.0 / 6.1 / 6.0 | PARTIAL, PARTIAL, FIXED | 5.63 (board, GPU). | 5.63 | b1 |
| F41#6 | **6.80** | 6.80 / 7.15 / 6.45 | 6.2 / 6.5 / 5.9 | FIXED, FIXED, FIXED | - | 6.76 | b1 |
| F41#20 | **6.99** | 6.80 / 7.62 / 6.56 | 6.2 / 6.9 / 6.0 | FIXED, FIXED, FIXED | 5.64 (board); GPU 6.09 (3/3 FIXED). | 6.09 | b1 |
| F41#17 | **7.03** | 6.91 / 7.26 / 6.91 | 6.3 / 6.6 / 6.3 | PARTIAL, FIXED, PARTIAL | - | 3.97 | b1 |
| F41#7 | **7.23** | 7.03 / 7.62 / 7.03 | 6.4 / 6.9 / 6.4 | FIXED, FIXED, FIXED | - | 6.43 | b1 |
| F41#11 | **7.34** | 7.03 / 7.85 / 7.15 | 6.4 / 7.1 / 6.5 | FIXED, FIXED, FIXED | - | 6.98 | b1 |

**Rows at 7.5 or above:** none.

**Near the bar (7.0–7.49):**

| Row | Subject | Mapped | Defect |
|---|---|---|---|
| F41#11 | Portrait identity | 7.34 | FIXED 3/3 |
| F41#7 | Named trainer dialogue identity | 7.23 | FIXED 3/3 |
| F41#17 | Crown Arch | 7.03 | |

F41#20 dialogue reuse sits just under, at 6.99 (FIXED 3/3).

## Judges' main findings (all three unless noted)
- **F41#7 is held back by Captain Marrow's face**, which blows out to glowing white in frame 3. All 3 judges called it out. This is the F41#15 defect; see `ITEM-F41-15/CAUSE.md`. The fix there (a lower speaker key light) would likely lift F41#7 as well.
- **F41#21 Hollows victory tiles, 5.78 (PRESENT 3/3):** the "x1" tile and the empty binding glyphs still sit in the quickbar band.
  - This is the live tree. Section C's `victory_on` arm scored 7.13 against 5.61 live, and that arm is not in this tree.
- **Lowest:**
  - **F41#13 electric creature finish, 5.59 (PRESENT 3/3):** Fulgocobra and Stormraven are dark navy, with no visible charge glow or eyes at view distance.
  - **F41#1 Stormheart, 5.78:** an interior with walkways, lanterns and banners, but no crown or core in view. The lightning is flat line strokes.
  - **F41#3 actor spacing, 5.78:** Sparkit sits inside Voltarach's legs under a dust trail in every frame.
- **F41#2 Surge phases, 6.10 (PRESENT 3/3):** Calm, Building and Fading differ only in rain density.
- **Up on GPU High against the earlier Compat score:**

  | Row | Subject | Compat | GPU High | What changed |
  |---|---|---|---|---|
  | F41#10 | Glass Sink | 3.19 | 6.02 | Checker void gone; it reads as a crystal ring, not a basin |
  | F41#17 | Crown Arch | 3.97 | 7.03 | A real double arch with a crystal crown |
  | F41#18 | Uniforms | 3.91 | 6.10 | |
  | F41#4 | Destinations | 4.54 | 6.37 | |
- **Batch-wide:**
  - Flat storm light, with no phase grade, shafts or layered fog.
  - The purple fog wall reads flat.
  - Salmon-pink bears scattered evenly across the background (2 judges).
  - Moiré on trunk textures (2 judges).
- **Top changes named:**
  1. A Stormwood storm-light pass: phase key light with white-violet bolts, rim light, charged emissive and layered fog (scene, 3/3).
  2. The fight camera kept out of foliage, with ally/boss spacing and real-object telegraphs (scene, 3/3).
  3. Stormheart crown and core, plus a sunken Glass Sink basin (new_art, 3/3).

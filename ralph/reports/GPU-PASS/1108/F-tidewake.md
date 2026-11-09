# GPU re-score 1108, section F-tidewake: Tidewake catalogue rows (GPU High, mapped)

- **Frames:** `tb/gpu-frames-1108`, read at 7416d0d8.
  - manifest-F-tidewake.json has 22 rows.
  - manifest-F-tidewake-add.json carries F39#21's Venn win and aftermath frames, which are `match: semantic`. The fight was won early, at about 105 s, so these frames replace the null ids in the main manifest.
  - Live tree be95950b on an NVIDIA GTX 1060, Forward+ High 1920x1080, JPEG q85.
- **Not judged: F39#11.** All three of its listed Venn frames (tell-ended 180 s, t 208 s, t 216 s) are null, because the fight stopped at 136 s. No frame of the row exists, so there was nothing to judge. It needs a capture that uses beats inside the fight's real length.
- **Not included: F39#21's Nerissa win frame.** It is null; F39#21 is judged on the two Venn frames only.
- **Yardstick:** `tools/visual_judge/`.
  - Standard JUDGE_PROMPT, with 3 pinned anchor pairs per batch: craft, f10_2_r3_capacitor and f04_6_r22.
  - Three batches, each with three fresh code-blind judges, nine judges in all: b1 and b2 hold 10 rows each, and the add batch holds F39#21 alone.
  - Scores mapped with a `calibrate.py` linear fit per batch. No warnings in any batch.
- **Fits (all confirming, top anchor 7.35):**

  | Batch | Slope | Intercept | r | Anchor RMSE |
  |---|---|---|---|---|
  | b1 | 1.529 | -2.758 | 0.876 | 0.557 |
  | b2 | 1.258 | -0.480 | 0.825 | 0.653 |
  | add | 1.487 | -2.288 | 0.920 | 0.451 |
- **Sets:** one-sided, so each judge's score is the mean of the two sides. All nine judges scored both sides of every one-sided set identically.
- **Side images:** each row's frames (up to 4) in a 2x2 grid at 640x360, or a single frame at 1280x720.
- **Score columns:** "Last CPU / board" comes from the LANE-SCOUT QUEUE. "Earlier GPU Compat" is the 1060 OpenGL Compatibility item score from `VISUAL/item-scores/tidewake/VERDICT-gpu.md`.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~02:30 UTC. Judge folders and replies stayed local.

| Row | GPU High mapped | Mapped per judge | Raw per judge | Defect calls (j1, j2, j3) | Last CPU / board score | Earlier GPU Compat | Batch / note |
|---|---|---|---|---|---|---|---|
| F39#21 | **4.75** | 4.25 / 5.00 / 5.00 | 4.4 / 4.9 / 4.9 | PRESENT, PRESENT, PRESENT | - | - | badd |
| F39#26 | **6.01** | 6.42 / 5.81 / 5.81 | 6.0 / 5.6 / 5.6 | PARTIAL, FIXED, PARTIAL | - | 6.06 | b1 |
| F39#5 | **6.06** | 5.81 / 5.81 / 6.57 | 5.0 / 5.0 / 5.6 | PARTIAL, PARTIAL, PARTIAL | 6.20 (board); GPU 5.20. | 5.20 | b2 |
| F39#18 | **6.16** | 6.57 / 5.81 / 6.11 | 6.1 / 5.6 / 5.8 | PARTIAL, FIXED, FIXED | - | 5.17 | b1 |
| F39#22 | **6.19** | 6.32 / 6.44 / 5.81 | 5.4 / 5.5 / 5.0 | FIXED, FIXED, FIXED | 6.28 (board); GPU 5.62 (3/3 FIXED). | 5.62 | b2 |
| F39#13 | **6.23** | 5.81 / 6.32 / 6.57 | 5.0 / 5.4 / 5.6 | PARTIAL, PARTIAL, PARTIAL | - | 4.71 | b2 |
| F39#15 | **6.27** | 6.19 / 5.94 / 6.69 | 5.3 / 5.1 / 5.7 | PRESENT, PRESENT, PARTIAL | - | 4.85 | b2 |
| F39#17 | **6.27** | 6.32 / 6.06 / 6.44 | 5.4 / 5.2 / 5.5 | PRESENT, PRESENT, PRESENT | - | 5.09 | b2 |
| F39#14 | **6.37** | 6.88 / 5.81 / 6.42 | 6.3 / 5.6 / 6.0 | PARTIAL, PARTIAL, PARTIAL | - | 5.78 | b1 |
| F39#1 | **6.42** | 6.88 / 6.11 / 6.26 | 6.3 / 5.8 / 5.9 | PARTIAL, PARTIAL, PARTIAL | 6.44 (board); GPU 5.56. | 5.56 | b1 |
| F39#2 | **6.48** | 6.57 / 6.06 / 6.82 | 5.6 / 5.2 / 5.8 | PARTIAL, PRESENT, PARTIAL | - | 5.78 | b2 |
| F39#27 | **6.57** | 6.06 / 6.57 / 7.07 | 5.2 / 5.6 / 6.0 | FIXED, FIXED, FIXED | 6.23 (board); GPU 5.48 (3/3 FIXED). | 5.48 | b2 |
| F39#29 | **6.61** | 6.44 / 6.82 / 6.57 | 5.5 / 5.8 / 5.6 | PARTIAL, FIXED, PARTIAL | 6.34 (board); GPU 3.54. | 3.54 | b2 |
| F39#9 | **6.65** | 7.07 / 6.44 / 6.44 | 6.0 / 5.5 / 5.5 | PARTIAL, PRESENT, PRESENT | 5.13 GPU (28 Oct, old nearest-wild capture); CPU 6.54 on the pinned capture (VIS-TIDEWAKE qj/c9, 8 Nov 02:30). | 5.13 | b2 |
| F39#12 | **6.80** | 7.10 / 6.42 / 6.88 | 6.5 / 6.0 / 6.3 | PARTIAL, PARTIAL, PARTIAL | - | 4.59 | b1 |
| F39#16 | **6.88** | 7.33 / 6.11 / 7.18 | 6.6 / 5.8 / 6.5 | FIXED, FIXED, FIXED | - | 4.48 | b1 |
| F39#24 | **7.18** | 7.64 / 6.88 / 7.03 | 6.8 / 6.3 / 6.4 | FIXED, FIXED, FIXED | - | 5.32 | b1 |
| F39#6 | **7.18** | 7.33 / 6.88 / 7.33 | 6.6 / 6.3 / 6.6 | PARTIAL, FIXED, FIXED | 6.24 (board); GPU 5.61. | 5.61 | b1 |
| F39#25 | **7.28** | 7.07 / 7.20 / 7.57 | 6.0 / 6.1 / 6.4 | FIXED, FIXED, FIXED | - | 6.36 | b2 |
| F39#4 | **7.28** | 7.49 / 7.03 / 7.33 | 6.7 / 6.4 / 6.6 | FIXED, FIXED, FIXED | - | 5.90 | b1 |
| F39#28 | **7.33** | 7.33 / 7.18 / 7.49 | 6.6 / 6.5 / 6.7 | FIXED, FIXED, FIXED | 6.02 (board, GPU; 3/3 FIXED). | 6.02 | b1 |

**Rows at 7.5 or above:** none.

**Near the bar (7.0–7.49):**

| Row | Subject | Mapped GPU High |
|---|---|---|
| F39#28 | Boss title overlay | 7.33 |
| F39#4 | Shiny finish | 7.28 |
| F39#25 | Map active region | 7.28 |
| F39#6 | Faint state | 7.18 |
| F39#24 | Rest poses | 7.18 |

Each of these has its recorded defect FIXED by most or all judges. What stands between them and 7.5 is staging and finish, not the defect itself.

## Judges' main findings (all three in the batch unless noted)
- **New on GPU High: named NPCs and speakers render ghost-white and translucent.** All 6 b1/b2 judges named this, and 5 put it in their top changes. It drags down F39#26, F39#18, F39#29, F39#27, F39#13 and F39#22.
  - F39#26 and F39#18: Adair, Iona, Rowan, Daro, Bex and Irva look like see-through ghosts.
  - F39#29: Nerissa and Nalia read washed-out.
  - F39#27, F39#13 and F39#22: the NPC is pale.
  - F39#28 frame 3: the trainer is a white ghost.
  - Likely the same Forward+ rim, emission or fade look as F38's translucent creatures and F41#15's blown-out face; see `ITEM-F41-15/CAUSE.md`. This is an inference, not root-caused. For F39#26 and F39#18, two judges suspect the occlusion fade is hitting the speaker.
- **F39#21 victory hierarchy, 4.75 (PRESENT 3/3):**
  - "Officer Venn defeated" is a small top-right toast over the full exploration HUD: roster, quickbar, hint bar and a "Gather Reef Stone" prompt.
  - There is no focus beat on the defeated officer.
  - It is the lowest Tidewake row and the clearest scene fix: hide the HUD, frame the officer, and centre a gold reward panel.
- **Defect FIXED, but the subject is now hard to see:**
  - F39#16 live currents (6.88): the guide-lane streaks are gone, but the current barely reads.
  - F39#17 current restoration (6.27, PRESENT 3/3): there is no visible payoff, and the sandbars are evenly spaced identical oval discs.
- **Lowest after F39#21:**
  - F39#26 dialogue obstruction, 6.01.
  - F39#5 swimming pose, 6.06: legs hang straight down in frame 1, and one judge saw a polygon seam on the horizon.
  - F39#18 dialogue framing, 6.16: the player's shoulder fills the left third, and the speakers are ghosted.
  - F39#22 Aquaryn dismount, 6.19: FIXED 3/3, but Aquaryn is not in any frame, so the dismount does not read.
- **Other recurring notes:**
  - F39#2: Veilfall is a craggy stack with one fall and no mist, still far from the board. Asked for as new_art by 2 judges.
  - F39#15: the disc chain in the shallows is still visible.
  - F39#14: the swim wake is an oversized, stamped foam smear.
  - F39#13: black square sprites float near the bench, raised by 3 judges.
- **Top changes named:**
  1. Fix the ghost-white NPC and speaker materials (scene).
  2. Dune and shore dressing with clumped grass, wrack lines, foam, falls mist, haze and varied shoals (scene).
  3. Real-object fight telegraphs and a camera kept out of foliage; this is the Stormwood anchor set, so it applies across the batch (scene).
  4. A tiered Veilfall (new_art).

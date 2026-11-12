# GPU re-score 1108, section B: confirm landed CPU gains (GPU High, mapped)

- Frames: `tb/gpu-frames-1108` manifest-B.json (79f5ee34, 34 frames); live tree be95950b, NVIDIA GTX 1060, Forward+ High 1920x1080, JPEG q85. Fetched with `git fetch --depth 1`.
- Yardstick: `tools/visual_judge/` standard JUDGE_PROMPT, three fresh code-blind judges, 3 anchor pairs pinned (craft, f10_2_r3_capacitor, f04_6_r22), `calibrate.py` linear fit.
- Fit: slope 1.483, intercept -2.2005, r 0.8967, anchor RMSE 0.511; top anchor 7.35, so this is a confirming batch. Warnings: ["meets the bar only above the top anchor (7.35): GPU1108 F38#36 live one-sided; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch"].
- Sets are one-sided (the same live image on both sides, as the 28 Oct GPU item scores did); each judge's score is the mean of the two sides, and all three judges scored both sides identically on every one-sided set.
- Side images: each row's frames (up to 4) in a 2x2 grid at 640x360 per tile, or one frame at 1280x720.
- Judged by LANE-SCOUT, 8 Nov 2026 ~23:20 UTC. Judge folders and replies stayed local.

| Row | GPU High mapped | Mapped per judge | Raw per judge | Defect calls (j1, j2, j3) | Last CPU / board score | Note |
|---|---|---|---|---|---|---|
| F41#8 | **5.31** | 5.66 / 5.21 / 5.07 | 5.3 / 5.0 / 4.9 | PARTIAL, PARTIAL, PRESENT | 5.83 (CPU, #855) |   |
| F39#8 | **5.66** | 5.66 / 5.81 / 5.51 | 5.3 / 5.4 / 5.2 | PARTIAL, PARTIAL, PARTIAL | 6.38 (CPU, #855) |   |
| F38#32 | **5.66** | 5.81 / 5.66 / 5.51 | 5.4 / 5.3 / 5.2 | PRESENT, PRESENT, PRESENT | 6.86 (CPU, #861) |   |
| F38#5 | **5.86** | 6.10 / 5.96 / 5.51 | 5.6 / 5.5 / 5.2 | PARTIAL, PARTIAL, PARTIAL | 7.40 (CPU, #858) |   |
| F41#9 | **5.86** | 5.96 / 6.10 / 5.51 | 5.5 / 5.6 / 5.2 | PARTIAL, PARTIAL, PARTIAL | 5.65 (CPU, #856) |   |
| F38#26 | **5.91** | 5.96 / 6.10 / 5.66 | 5.5 / 5.6 / 5.3 | PRESENT, PRESENT, PRESENT | 6.97 (CPU, #855) |   |
| F39#3 | **6.10** | 6.55 / 5.96 / 5.81 | 5.9 / 5.5 / 5.4 | PARTIAL, PARTIAL, PRESENT | 6.84 (CPU, land batch 16) |   |
| F39#10 | **6.30** | 6.70 / 6.25 / 5.96 | 6.0 / 5.7 / 5.5 | PARTIAL, PARTIAL, PARTIAL | 7.25 (CPU, #856) |   |
| F41#14 | **6.35** | 6.55 / 6.40 / 6.10 | 5.9 / 5.8 / 5.6 | FIXED, FIXED, FIXED | 6.04 (CPU, #856) |   |
| F38#41 | **6.65** | 6.70 / 6.70 / 6.55 | 6.0 / 6.0 / 5.9 | PARTIAL, PARTIAL, PARTIAL | 6.96 (CPU, #857) |   |
| F38#17 | **7.34** | 7.44 / 7.29 / 7.29 | 6.5 / 6.4 / 6.4 | FIXED, FIXED, FIXED | 7.32 (CPU, #855) |   |
| F38#36 | **7.74** | 7.88 / 7.74 / 7.59 | 6.8 / 6.7 / 6.6 | FIXED, FIXED, FIXED | 7.89 (CPU, #855) |  **7.5+: needs Medium** |

**Rows at 7.5 or above (need a Medium capture):** F38#36.

## Judges' main findings (all three unless noted)
- **Only F38#36 confirms its CPU score** (7.74 GPU vs 7.89 CPU; mapped above the top anchor in a confirming batch, so it stands): Kell, Corin and Captain Halder framed clearly, no creature intruding. **F38#17** holds (7.34 vs 7.32), just under the bar.
- **Large GPU drops against the landed CPU scores:** F38#5 normal creature scale 7.40 -> 5.86 (the hound, owl and hare read only about the trainer's height, not clearly taller, with feet lost in grass); F38#26 creature ground contact 6.97 -> 5.91 (dense grass hides feet, PRESENT 3/3); F38#32 camp props 6.86 -> 5.66 (props overlap; a large foreground CAMP sign fills the lower left of frame 3; a row of white shapes along the horizon reads as scatter or artefact, PRESENT 3/3); F39#10 water depth 7.25 -> 6.30 (navy/cyan bands are hard-edged; an untextured dark faceted shape in frame 3); F39#3 destinations 6.84 -> 6.10 (small props on bare dunes); F39#8 Aquaryn 6.38 -> 5.66 (mount on a flat white foam disc, no wake or bob).
- **Up on GPU:** F41#14 candy tiers 6.04 -> 6.35 (tiers FIXED 3/3; asks: black-void ground, thick rain streaks); F41#9 harvest identity 5.65 -> 5.86.
- **F41#8:** 5.83 -> 5.31; named roles are small and alike at normal distance.
- **F38#41 Old Quarry:** 6.96 -> 6.65; granite texture is believable but no worked faces or tool marks.
- Possible oxblood flag (one judge): a red banner with a target symbol behind Warder Solene in F38#17, acceptable only if that is a Team Tether site.
- Top changes named across the batch: Stormwood ground (replace the pure-black pool material, halve rain streak thickness); clear grass and add contact shadows under catalogue creatures; atmosphere and grade (height fog, rim light).

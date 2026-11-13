# G-rescore-stale-ext-meadows: 17 rows re-scored on main (GPU High, one-sided)

LANE-PLACES (re-scoring lane), 12 Nov 2026.

**Frames:** `tb/gpu-frames-1108` section `G-rescore-stale-ext-meadows` @ 7d96e3dd3: main c73dcc80f as it is, High, each row's own job.json frames (44 frame slots across 21 rows).

**Batch:** three code-blind judges, the standard prompt, each row as a one-sided sheet of its own frames (640×360 tiles) against its job.json brief and recorded defect. Anchors pinned to craft, f10_2_r3_capacitor and f04_6_r22 (three pairs, six points).

**Fit:** linear, slope 1.4326, intercept -1.4089, r 0.867, anchor RMSE 0.575; confirming batch: True; warnings: ["meets the bar only above the top anchor (7.35): F38#13, F38#14, F38#18, F38#19, F38#3, F38#33, F38#34, F38#38, F38#4, F38#7, F38#9; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch", "some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)"].

**Read the change column as indicative (about ±0.3):** board scores come from other batches and judge pools.


## Results

| Row | Subject | Board | Main now (mapped) | Change | Raw a, b, c | Recorded defect (a / b / c) |
|---|---|---|---|---|---|---|
| F38#3 | fight camera and creature scale | 6.49 | **8.09** | +1.60 | 6.7, 6.9, 6.3 | PARTIAL / FIXED / PARTIAL |
| F38#4 | map | 7.21 | **8.09** | +0.88 | 6.7, 6.5, 6.7 | FIXED / FIXED / FIXED |
| F38#7 | catch aim readability | 7.26 | **7.52** | +0.26 | 6.4, 6.3, 6.0 | PARTIAL / PARTIAL / PARTIAL |
| F38#9 | menu shell | 7.32 | **8.29** | +0.97 | 6.9, 6.8, 6.6 | PARTIAL / PARTIAL / PARTIAL |
| F38#10 | secondary menu panels | 6.58 | **7.38** | +0.80 | 6.3, 6.3, 5.8 | PARTIAL / PARTIAL / PARTIAL |
| F38#11 | shared fight tell and hit effects | 6.89 | **7.47** | +0.58 | 6.4, 6.3, 5.9 | PARTIAL / PARTIAL / PARTIAL |
| F38#13 | catch sequence camera framing | 7.16 | **7.66** | +0.50 | 6.4, 6.4, 6.2 | PARTIAL / PARTIAL / PARTIAL |
| F38#15 | flight and landing pose read | 6.84 | **7.23** | +0.39 | 6.2, 6.2, 5.7 | PARTIAL / PARTIAL / PARTIAL |
| F38#18 | craft recipe text | 7.95 | **8.24** | +0.29 | 7.0, 6.7, 6.5 | PARTIAL / PARTIAL / PARTIAL |
| F38#19 | exploration HUD | 6.89 | **7.62** | +0.73 | 6.6, 6.5, 5.8 | PARTIAL / PARTIAL / PARTIAL |
| F38#21 | ground cover | 7.0 | **6.95** | -0.05 | 6.0, 5.9, 5.6 | PARTIAL / PARTIAL / PARTIAL |
| F38#23 | Tether Relay yard | 7.58 | **6.57** | -1.01 | 5.8, 5.6, 5.3 | FIXED / FIXED / FIXED |
| F38#25 | shiny palette distinction | 6.23 | **7.23** | +1.00 | 6.4, 6.1, 5.6 | PARTIAL / FIXED / PARTIAL |
| F38#33 | catch result hierarchy | 7.32 | **8.14** | +0.82 | 6.8, 6.9, 6.3 | PARTIAL / FIXED / PARTIAL |
| F38#34 | placed wall visual | 6.75 | **7.76** | +1.01 | 6.6, 6.6, 6.0 | FIXED / FIXED / FIXED |
| F38#35 | human post poses | 6.31 | **6.33** | +0.02 | 5.7, 5.3, 5.2 | PRESENT / PRESENT / PRESENT |
| F38#38 | craft action hint contrast | 8.16 | **8.52** | +0.36 | 7.2, 7.0, 6.6 | FIXED / FIXED / FIXED |

## Read this before using the numbers
- **This batch reads about 0.6 higher than G-rescore-stale-tier2 on the same rows.** Five rows were judged in both: F38#13 6.94 → 7.66, F38#14 6.94 → 7.52, F38#21 6.23 → 6.95, F38#22 6.06 → 6.80, F38#20 5.72 → 6.09 (some on different frame subsets). The judges here scored the anchors lower (craft after 6.23 raw against 6.87 in tier2), so the map lifts every row further. Anchor RMSE is 0.58 here and 0.52 there; a between-batch difference of this size is inside what three anchors can resolve.
- **Every mapped score above 7.35 is extrapolated** beyond the top anchor (calibrate.py warns on all eleven). Treat a 7.5-or-above here as "worth a Medium capture and a confirming two-sided judgement", not as a High pass.
- Raw scores (the three judges' own numbers) are in the table; no row was scored above 7.2 raw.

## Flags

- F38#3 8.09: at or above 7.5, needs Medium
- F38#4 8.09: at or above 7.5, needs Medium
- F38#7 7.52: at or above 7.5, needs Medium
- F38#9 8.29: at or above 7.5, needs Medium
- F38#13 7.66: at or above 7.5, needs Medium
- F38#18 8.24: at or above 7.5, needs Medium
- F38#19 7.62: at or above 7.5, needs Medium
- F38#33 8.14: at or above 7.5, needs Medium
- F38#34 7.76: at or above 7.5, needs Medium
- F38#38 8.52: at or above 7.5, needs Medium

## Coverage notes

- F38#8: 1 of 2 job frames (missing meadows__flying__launch)
- F38#14: 2 of 3 job frames (missing meadows__catching__02-orb-in-flight)
- F38#20: 1 of 3 job frames (missing meadows__band5_stronghold_approach__09__stronghold_approach__night__approach, meadows__landmark__stronghold__day__approach)
- F38#22: 1 of 3 job frames (missing meadows__landmark__band1_trail_camp__day__close, meadows__landmark__village__day__close)

## Cross-checks only (partial frame sets in this section; their full sets are in G-rescore-stale-tier2 or another section)
| Row | Subject | Board | This batch (mapped, partial) | Change | Raw a, b, c | Recorded defect |
|---|---|---|---|---|---|---|
| F38#8 | Fly carrier grip pose | 7.14 | **6.23** | -0.91 | 5.4, 5.1, 5.5 | PRESENT / PRESENT / PARTIAL |
| F38#14 | catch effect finish | 6.06 | **7.52** | +1.46 | 6.3, 6.3, 6.1 | PARTIAL / PARTIAL / PARTIAL |
| F38#20 | Team Tether stronghold | 6.02 | **6.09** | +0.07 | 5.4, 5.5, 4.8 | PARTIAL / PARTIAL / PARTIAL |
| F38#22 | mill and settlements | 6.1 | **6.80** | +0.70 | 6.2, 5.7, 5.3 | PARTIAL / PARTIAL / PARTIAL |

## What the judges named (3/3 unless said)
- **Stronghold approach (F38#20):** "a tiny dark castle over an empty flat field"; wants landmark mass, palisade, banners and approach dressing (new art for the hero piece).
- **Tether Relay yard (F38#23):** the recorded defect (weeds through the yard) is FIXED 3/3, but the yard is now "a vast stretched cobble plane" with props at the edges. That is why the row drops.
- **Human post poses (F38#35):** PRESENT 3/3: every NPC holds the same arms-down idle.
- **Fly carrier (F38#8, partial):** the trainer still hangs rigid and upright.
- **Ground cover (F38#21):** flower colour clusters help two frames; the third is a bare dark plain with even scatter.
- **Catch (F38#7, #13, #14):** a bush hides the target in one aim frame; the close shot still crops trainer and companion; the orb is a flat cream disc.
- **UI rows (F38#4, #9, #10, #18, #19, #33, #38):** readable and on palette; remaining notes are heavy orange in the craft panel, one clipped material line, and half-empty Quests and Players panels.

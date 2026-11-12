# G-newapproach-dust: low earth-tone wind-up dust (F38#3, F38#11, F41#3)

Frames: `tb/gpu-frames-1108` a8149eacd, High, every frame published.
- **Live and live2:** main 90886c306, two runs.
- **Arm and arm2:** live plus `LANES/NEWAPPROACH-DUST/overlay_dust.json` at tb/newapproach f088131df (`telegraph.soft_style` dust_size_m 0.42, rise 0.16, alpha 0.6, colour #9c8763, spacing 0.34), two runs.
- **Pairing:** r1 = live vs arm, r2 = live2 vs arm2.
- **F41#6** is a copy of F41#3 and is not judged separately.
- **Frame overlap:** F38#3 (grunt-01/02/03) and F38#11 (grunt-02/03/05) share grunt-02 and grunt-03, so those two rows are not independent of each other.

## Pre-judge render check
- **Dust visible on arm:** a stack image confirms it on the wind-up frames. Live shows near-white body-height clouds; arm shows low earth-tone puffs along the footprint.
- **Meadows:** 20–28% of pixels change and luma moves −7 to +2. Part of this is fight variance.
- **F41#3 r2:** 45–47% of pixels change. arm2 is on the reverse side of the fight, as the GPU lane noted.

## Judged
Batch `G-dustsd`, shared with the F38#3 full-set re-score:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.1189, intercept −0.3093, r 0.810, anchor RMSE 0.677. No warnings.

| Pair | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F38#3 r1 | 6.25 (raw 6.0, 5.8, 5.8) | 6.70 (raw 6.5, 6.1, 6.2) | **+0.45** | 3/3 |
| F38#3 r2 | 6.37 (raw 6.2, 5.9, 5.8) | 6.66 (raw 6.4, 6.1, 6.2) | **+0.29** | 3/3 |
| F38#11 r1 | 6.29 (raw 6.0, 5.9, 5.8) | 6.59 (raw 6.4, 6.1, 6.0) | **+0.30** | 3/3 |
| F38#11 r2 | 6.48 (raw 6.3, 5.9, 6.0) | 6.52 (raw 6.2, 6.1, 6.0) | +0.04 | 1/3 (1 tie) |
| F41#3 r1 (same angle) | 5.84 (raw 5.6, 5.5, 5.4) | 5.81 (raw 5.5, 5.5, 5.4) | −0.03 | 0/3 (2 ties) |
| F41#3 r2 (arm2 reverse side) | 5.77 (raw 5.5, 5.5, 5.3) | 5.96 (raw 5.6, 5.6, 5.6) | +0.19 | 3/3 |

## What the judges saw
- **Live dust:** all three describe it as "puffy white cartoon dust" or "cotton-ball puffs". It swallows the boar's legs and snout, the ally's forequarters and the trainer between them.
- **Arm dust:** they call it a "thin dotted swirl trail" that keeps both creatures readable. They also say it "reads as a particle debug spline, not a real object". The arm wins because it hides less, not because it looks like real dust.
- **No magenta floor marks** appear in the Meadows frames on either side.
- **F41#3:** on the like-for-like pair (r1) the judges called the sides equal, because the dust is mostly hidden under Voltarach. The r2 gain comes from a different camera side, so it is not credited to the dust. Sparkit is still buried under Voltarach's legs on every side.

## Verdict
- **SHIP.** F38#3 clears the ship rule on both runs (+0.45 and +0.29, 3/3 each). F38#11 clears it on r1 and is flat on r2. F41#3 is flat on its like-for-like pair. No row drops.
- **Closes:** none. Best is F38#3 at 6.70.
- **Next swing named by all three judges:** replace the puff or trail with a grounded impact object (clods, stone chips, a short kick of dust at the feet) that never covers faces.

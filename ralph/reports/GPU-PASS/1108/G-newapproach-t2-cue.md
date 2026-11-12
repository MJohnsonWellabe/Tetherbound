# G-newapproach-t2-cue: swimmer "Current" arrow (CARD:T2 currents, F13#5)

Frames: `tb/gpu-frames-1108` 83411a27e, High and Medium, 1920x1080. Three swimmer views from `T2-current.json`: swim-away-day, swim-across-day and swim-away-night.
- **Base:** main 90886c306.
- **Arm:** the same build plus `--tidewake-current-candidate`.
- **Pre-push check:** the badge is visible on 6 of 6 arm frames and on 0 base frames.

## Judged (standard prompt, 7-inch readability brief)
Batch `G-t2`:
- Three code-blind judges.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.2802, intercept −1.0386, r 0.812, anchor RMSE 0.673. No warnings.
- Recorded defect: "The swimming current's direction cannot be read from the swimmer view at a glance on a 7-inch screen".

| Preset | Base | Arm | Gain | Judges preferring arm | Defect on arm |
|---|---|---|---|---|---|
| **High** | 6.26 (raw 5.8, 5.8, 5.5) | **6.86** (raw 6.2, 6.3, 6.0; mapped 6.90, 7.03, 6.64) | **+0.60** | 3/3 | FIXED 1, PARTIAL 2 |
| **Medium** | 6.05 (raw 5.6, 5.6, 5.4) | **6.86** (raw 6.2, 6.3, 6.0; mapped 6.90, 7.03, 6.64) | **+0.81** | 3/3 | FIXED 1, PARTIAL 2 |

On the base side, 5 of the 6 defect calls are PRESENT.

## Blind direction test on the GPU frames
This repeats LANE-NEWAPPROACH's test:
- 12 images (base and arm, High and Medium, 3 views), shuffled and unlabelled.
- Three fresh judges, each asked for direction, confidence and 7-inch readability.
- Truth comes from `NEWAPPROACH-T2/direction_test.json`: across = RIGHT, both away views = TOWARD_CAMERA.
- Per-judge answers and the key are in `yardstick_g_t2/direction_test_gpu.json`.

| Side | Correct | Cannot tell | Mean confidence | Mean readability |
|---|---|---|---|---|
| Base High | 8 of 9 | 0 | 3.8 | 3.3 |
| Base Medium | 8 of 9 | 1 | 2.7 | 2.2 |
| **Arm High** | **9 of 9** | 0 | **9.0** | **8.2** |
| **Arm Medium** | **9 of 9** | 0 | **9.0** | **8.2** |

The arm result matches the lane's CPU test exactly (9 of 9 at confidence 9, readability 8.2).

**About the base results:** base scored better here than in the lane's CPU test (16 of 18 correct against 4 of 9). Every base answer was low-confidence, though (2 to 5), and all three judges called the base cue a guess: "nothing shows the direction for certain", "which way it goes is a guess".

## What the judges flagged
- **Strength still has no cue on either side.** Two judges want long streaks aligned with the flow, scrolling faster where it is stronger, kept alongside the badge.
- **The water disagrees with the badge in swim-across.** One direction-test judge noted that the water streaks point toward the horizon while the badge says RIGHT, so a player who ignores the badge reads the wrong way.
- **Seam in the water colour.** One judge saw a hard diagonal seam splitting the water in swim-across-day on both sides, a defect in the base scene.
- **Small badge problems:**
  - One judge found the down arrow for "toward camera" a little less intuitive.
  - The badge is HUD rather than something in the world, so two judges marked the defect PARTIAL rather than FIXED.

## Verdict
- **SHIP (arrow ON by default, per UX.md).** It passes this judge on both presets: High +0.60 and Medium +0.81, 3 of 3 each, and the blind direction test is 18 of 18 at confidence 9.
- **Does not close.** CARD:T2 currents and F13#5 stay open, with the arm at 6.86 mapped on both High and Medium, below 7.5.
- **The next swing the judges name** is a cue in the water itself: streaks aligned with the flow and showing its strength, matched to the badge in swim-across, with the colour seam fixed.

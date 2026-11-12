# G-t2-arrow-confirm: close-out check, swim-current arrow on plain main (CARD:T2 currents, F13#5)

Frames: `tb/gpu-frames-1108` 83f4816f7, High and Medium, 1920x1080.
- **Build:** plain main 05d86cec8, with the arrow on by default since #883. No candidate flag and no overlay.
- **Views:** swim-away-day, swim-across-day and swim-away-night.
- **Scoring:** one-sided.

## Judged
Batch `G-t2c`:
- Three code-blind judges, the standard prompt and the T2 7-inch brief.
- Recorded defect: "direction cannot be read from the swimmer view at a glance on a 7-inch screen".
- **Anchors:** craft (4.83 / 7.35), f10_2_r3_capacitor, and **f36_0_npc:C1 (7.47 / 7.53)**. This is the only anchor pair that reaches past 7.5, so a score of 7.5 or above would not be extrapolated.
- **Top anchor reference 7.53.** This is a confirming batch.
- Fit: linear, slope 1.6684, intercept −3.3271, r 0.941, anchor RMSE 0.47. No warnings.

| Preset | Mapped | Raw (per judge) | Mapped (per judge) | above_top_anchor |
|---|---|---|---|---|
| **High** | **6.32** | 5.65, 6.05, 5.65 | 6.10, 6.77, 6.10 | false |
| **Medium** | **6.24** | 5.6, 6.0, 5.6 | 6.02, 6.68, 6.02 | false |

**Defect status:** PARTIAL for 3/3 judges at both presets. All three say the HUD arrow carries the direction, but the water itself does not. One-sided raw scores are the mean of the two identical halves of each set; the judges scored the halves within 0.1 of each other.

## Verdict
**DOES NOT CLOSE.** High is 6.32 and Medium 6.24, both below 7.5, and neither is extrapolated.

This settles the 7.66 seen on the base side of `G-newapproach-t2b`. That number came from a steep fit (slope 1.71) and was extrapolated above the top anchor. In three batches, the same arrow-on swimmer views at raw 5.6–6.2 have mapped to between 6.24 and 6.86, and only that one extrapolated reading went over 7.5.

## What holds it below the bar
All three judges agree on what keeps it down:
1. **The water doesn't show the current.** The arcs curve in mixed directions, so neither direction nor strength reads without the badge. The judges want streaks aligned with the flow that scroll at a speed matching the strength, and wakes on floating debris.
2. **The colour seam.** There is a hard diagonal seam in the water in swim-across-day.
3. **The night view** reads as dusk-blue.
4. **Scene finish:** flat water value, logs with no contact foam, and the quest card and minimap crowding the view.

The strength bars (`G-newapproach-t2-bars.md`, +0.57) answer part of point 1. The lane's soft-fleck rework (T2 STREAKS) is the next test for the in-water half.

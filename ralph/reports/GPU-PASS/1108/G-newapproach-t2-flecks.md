# G-newapproach-t2-flecks: soft foam flecks near the swimmer (CARD:T2, F13#5), second in-water attempt

Frames: `tb/gpu-frames-1108` 5ceacf508, High. Views: swim-away-day, swim-across-day and swim-away-night.
- **Base:** main 05d86cec8 (arrow on) plus `water_current_flow.gdshader` and `water_current_cue.gd` at tb/newapproach 7b38eaa74.
- **Arm:** base plus `NEWAPPROACH-T2B/overlay_flecks.json` (near_streak_opacity 0.55, range 18 m, lane 0.9 m, fill 0.42).

## Pre-judge render check
- **Arm in frame:** it changes 3–5% of pixels per view, with luma within 1.3 levels.
- **GPU lane's note:** no lane lines or horizon marks this time. Some flecks have hard straight cut edges, and swim-away-day is sparse.
- **Recorded defects:** F39#16's "guide lanes" catalogue defect was included again, so the judges would check it directly.

## Judged
Batch `G-flk`:
- Three code-blind judges, the standard prompt and the T2 7-inch brief.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.1558, intercept −0.4753, r 0.798, anchor RMSE 0.695. No warnings.

| Side | Mapped | Raw (per judge) |
|---|---|---|
| Base (arrow only) | 6.77 | 6.2, 6.3, 6.3 |
| Arm (arrow + flecks) | 6.50 | 5.9, 5.9, 6.3 |

**Gain −0.27.** No judge preferred the arm (0/3, 1 tie).

Defect calls:

| Defect | Base | Arm |
|---|---|---|
| Guide lanes | FIXED 3/3 | PARTIAL 3/3 |
| Direction | PARTIAL 3/3 | PARTIAL 3/3 |

## What the judges saw
- **Better than the long streaks,** but in the night view and in day view 2 the arm's flecks "become long, bright, roughly parallel white lines" and "start to look like evenly spaced parallel lines again", "more like a lane overlay painted on the water".
- **One judge said the arm gave "a little more sense of flow" near the swimmer.** None said the water now shows direction without the badge.
- **The base's short scattered crescents read as "not lanes"** to all three.
- **Both sides:** the hard-edged diagonal seam in swim-across-day, flat night water, and the HUD at top right.

## Verdict
- **DO NOT SHIP.** −0.27 with 0/3 judges preferring it, and the guide-lane defect returns to PARTIAL on 3/3.
- **Drop the layer.** The lane's own rule (`NEWAPPROACH-T2B/ARM.md`) was that if any line or ladder shows on GPU, the layer is dropped rather than tuned a third time.
- **Park the in-water near-streak approach.** It is the second approach on this item to fail (owner rule, 25 Oct), so it waits until there is a new idea.
- **Where the in-water direction cue could come from instead**, as the judges suggest: wakes behind floating debris and logs, or scrolling flow normals.
- **Better next targets for T2:** the water colour seam and the night grade, which every T2 batch today has flagged.

# G-newapproach-t2b: flow-aligned current streaks plus strength badge (CARD:T2, F13#5, F39#16)

Frames: `tb/gpu-frames-1108` cd277a3d, High, 1920x1080. Views from `T2-current.json`: swim-away-day, swim-across-day and swim-away-night.
- **Base:** main 05d86cec8 (arrow ON since #883) plus `water_current_flow.gdshader` and `water_current_cue.gd` at tb/newapproach 76c85cac4.
- **Arm:** base plus `NEWAPPROACH-T2B/overlay_t2b.json` (near_streak_opacity 0.5, range 38 m, lane 1.3 m, fill 0.4; strength_marks on).

## Pre-judge render check
The arm changes 5–8% of pixels per view with almost no change in luma, so the streaks and strength plate are in frame.

The GPU lane's flag was read before judging: the streaks look like painted lane lines. It is a quality flag, not a hold, so the section was judged. The F39#16 "guide lanes" catalogue defect was added to the recorded defects so the judges would check it directly.

## Judged
Batch `G-t2b`:
- Three code-blind judges, the standard prompt and the T2 7-inch brief.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, **slope 1.713**, intercept −2.7879, r 0.926, anchor RMSE 0.435.
- Calibrate warning: "meets the bar only above the top anchor (7.35): base side; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch."

| Side | Mapped | Raw (per judge) | Mapped (per judge) |
|---|---|---|---|
| Base (arrow, base shader) | **7.66** (above_top_anchor) | 6.4, 6.0, 5.9 | 8.18, 7.49, 7.32 |
| Arm (streaks + strength marks) | 6.12 | 5.5, 5.0, 5.1 | 6.63, 5.78, 5.95 |

**Gain −1.54.** No judge preferred the arm (0/3).

## What the judges saw
- **The streaks look like painted lanes.** All three judges describe the arm's water as "long, bright, evenly spaced parallel white streaks … like painted guide lanes", with "a ladder" or "grid of white dashes in the distance".
  - Arm: F39#16's guide-lane defect is **PRESENT** for 3/3 judges.
  - Base: the same defect is **FIXED** for 2/3 and PARTIAL for 1/3. They read the base's short curved wisps as natural surface flow.
- **The water contradicts the arrow.** One judge noted that in the arm's swim-away-day frame the streaks fan diagonally while the arrow points down.
- **The strength plate** registered with only one judge ("Side A also has a strength meter"). The other two say nothing on either side shows strength.
- **Both sides:** the colour seam in swim-across-day, a night grade that reads too bright, and the HUD at top right.

## Verdict
**DO NOT SHIP.** The arm loses 1.54 with 0/3 judges preferring it. The streak treatment recreates the F39#16 guide-lane defect, matching the GPU lane's own flag. If the strength marks are wanted, re-test them with `near_streak_opacity` at the base value.

## The base result: what it means and what it doesn't
The base side mapped to **7.66, above 7.5**, but this needs care before anyone reads it as a close:
1. **It is extrapolated and the fit is unusually steep.** The slope is 1.71, against 1.08–1.36 in the other batches today. The base's raw mean of 6.1 matches the T2 arrow arm in G-t2 (raw 6.17), which mapped to only 6.86. Same scene, about the same raw score: the difference comes mostly from the fit.
2. **The base is not plain main.** It carries `water_current_flow.gdshader` and `water_current_cue.gd` from tb/newapproach 76c85cac4. Whether those files change anything on screen with their flags at default is not established here.
3. **There are no Medium frames.** A close needs 7.5 or more on both High and Medium.

**Request (owner's High-first judging rule: add Medium only after High scores 7.5 or more):**
1. Capture the same three views at **Medium** on plain main.
2. If the branch shader files differ in effect, also capture High on plain main.
3. Judge both in a fresh confirming batch.

That batch decides whether CARD:T2 currents and F13#5 close. Until then they stay open.

# G-newapproach-t2-cleanup: CARD:T2 / F13#5 water overlay cleanup (GPU High, arrow off both sides)

Frames: `tb/gpu-frames-1108` 8b531c200 (T2 views) and 1ad4d2e18 (regression, `G-newapproach-t2-cleanup-regress`).
Base is `tb/newapproach` 38d55eb2e. The arm is base plus `overlay_cleanup`:
- water opaque past 1.5 m;
- night dim 0.55 / #4a6a98;
- swimmer ring opacity 0.3;
- trail 0.6.

swim-brine-day was not captured on either side (the current misses the stand on this tree), so three T2 views were judged.

Batch `G-t2cl`: three code-blind judges with the standard prompt, the T2 brief per view, and one regression pair (F39-1's three shore frames, 2x2). Anchors were craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. This is a confirming batch, so no score is extrapolated.

## Verdict

The T2 views all gain and are preferred, but the regression frames show a small, unanimous loss. It is caused by the softer swimmer ring. Under the "no regression loss" rule this is **not shipped as-is**.

Recommendation: ship opaque-depth plus night dim, and keep the base swimmer ring (drop `ring opacity 0.3`, and `trail 0.6` with it unless separately tested). Re-judge only the Brine Steps frame. No T2 view maps 7.5 or above, so there is no Medium to queue.

| View | Base (mapped) | Arm (mapped) | Gain | Judges preferring arm |
|---|---|---|---|---|
| swim-away-day | 5.94 (5.76, 5.97, 6.08) | 6.26 (6.08, 6.29, 6.40) | +0.32 | 3/3 |
| swim-across-day | 5.65 (5.55, 5.65, 5.76) | **6.50** (6.29, 6.61, 6.61) | **+0.85** | 3/3 |
| swim-away-night | 5.90 (5.86, 5.65, 6.18) | 6.08 (5.86, 5.86, 6.50) | +0.18 | 2/3 (1 tie) |
| F39 shore regression (3 frames) | 6.36 (6.40, 6.18, 6.50) | 6.22 (6.29, 6.08, 6.29) | **−0.14** | 0/3 (all prefer base) |

Raw Bar A (judges a, b, c):
- away-day: base 5.1, 5.3, 5.4 → arm 5.4, 5.6, 5.7.
- across-day: base 4.9, 5.0, 5.1 → arm 5.6, 5.9, 5.9.
- night: base 5.2, 5.0, 5.5 → arm 5.2, 5.2, 5.8.
- regression: base 5.7, 5.5, 5.8 → arm 5.6, 5.4, 5.6.

Fit: linear, slope 1.0648, intercept 0.3278, r 0.899, anchor RMSE 0.606, 6 anchor points, top_anchor_reference 7.53, confirming_batch true, above_top_anchor false throughout. Calibrate gave no warnings.

Render check (pixels changed by more than 30, then luma):
- away-day: 43.4%, 140.8→138.7.
- across-day: 31.1%, 134.2→136.2.
- night: 43.3%, 89.6→74.0.
- Regression: brine_steps_east_beach 11.3%; welcome_beacon 0.4%; horizon_stones 1.0% (the F39-2 and F39-10 copies are the same frame).

## Why the regression loses
- Only the Brine Steps east-beach frame changes materially. On base, the swimmer has a bright foam ring with a soft wake, and all three judges said base ties the swimmer (which they read as a buoy) and the boat to the water better.
- The arm's ring at 0.3 is fainter. Every other regression detail was called identical.
- The opaque-depth and night-dim parts did not show up in the regression.

## What carried the T2 views
- **across-day:** base has a hard-edged lighter wedge, a seam running from the left shore down the frame, named by all three judges. The arm removes it and reads as one clean, slightly directional surface. This is the biggest gain.
- **away-day:** the arm's water was preferred 3/3. All three judges called the base side the murkier grey-green, with dark smears under the logs and the swimmer, which are the seabed shapes the arm hides.
- **night:** small gain. Judges still find 23:00 too bright: the dunes are over-bright, and the sea reads as royal blue with no moonlight grade.

## Recorded defect and remaining gap to 7.5
- The current-direction defect is PARTIAL on every T2 side from every judge.
  - The white crescent arcs curve in mixed directions.
  - The big near-camera crescents read as hard decal/overlay shapes.
  - There is no single flow line, so direction "needs study".
- Other gaps:
  - a hard pale rectangle at the sand edge (judge b, all views);
  - hard-banded cyan/navy shallows on the shore views;
  - a night grade that is still too bright.
- Judges' top change (scene, 3/3): replace the scattered crescents with continuous, current-aligned foam and flow streaks plus one clear directional cue. Note that crest-shape work in the water was already parked after four failed rounds (see G-newapproach-wave-crests-v3-fixed). This would be a new idea at the decal/flow-line level, not another crest shape.

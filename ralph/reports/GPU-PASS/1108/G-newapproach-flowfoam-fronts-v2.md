# G-newapproach-flowfoam-fronts-v2: advected swell lines (CARD:T2, F13#5), fifth wave-cue attempt

Frames: `tb/gpu-frames-1108` 491b5e04a, High, `--fixed-fps 20`, 10-frame strips (0.1 s per strip frame), arrow off on both sides.
- base = `tb/newapproach` 4b3cfa57a: main with #892's opaque deep water and night dim.
- arm = base + `NEWAPPROACH-FLOWFOAM/overlay_fronts.json`: sums-of-sines swell lines across the current lane, moving downstream, with an fwidth fade in the distance and the crescent caps off.

Render check (frame t0, pixels changed by more than 30): away-day 16.7%, across-day 18.2%, night 23.1%.

## Verdict: DO NOT SHIP

- **Direction gets worse on swim-away-night:** base 3/3, arm 0/3.
- **swim-away-day misses the bar:** the arm reads 0/3, where the bar is at least 2/3 TOWARD_CAMERA at confidence 6+. Base is also 0/3, so it is no worse.
- **Look:** the arm gains on all three views, 3/3 each. On a still frame, judges see the swell lines as a clearer current axis than base.
- **swim-across-day alone passes every gate:** direction is 3/3 on both sides, and look is +0.52 with 3/3. The overlay is one global setting, though, so it cannot ship for one view.
- **No Medium.** Nothing maps 7.5; the best is across-day at 6.86.

## 1. Blind direction test (strips t = 0, 2, 4, 6, 8; labels 0.2 s apart; six shuffled, unlabelled strips; three fresh judges)
Data: `yardstick_g_ff2/direction_test_strips.json`.

| View | Truth | Base | Arm |
|---|---|---|---|
| **swim-away-day** | TOWARD_CAMERA | 0/3 (CANNOT_TELL ×3, confidence 3) | **0/3** (RIGHT 3, CANNOT_TELL 2, CANNOT_TELL 3) |
| **swim-away-night** | TOWARD_CAMERA | 3/3 (TOWARD 3, 4, 3) | **0/3** (CANNOT_TELL, LEFT 4, CANNOT_TELL) |
| swim-across-day | RIGHT | 3/3 (confidence 6, 6, 5) | 3/3 (confidence 6, 6, 5; readability 5, 5, 5 against base 5, 4, 4) |

What the direction judges saw:
- **Arm away-day:** "only faint, near-static ribbons at top right"; "logs move with the camera, no water cue".
- **Arm night:** "wavy bands nearly static"; one judge read the bands as "trailing left from the swimmer like a wake" and answered LEFT.
- **Arm across-day:** "large soft foam bands drift right about 15–20 px per 0.2 s", the clearest strip in the set.
- **Base night:** the crescents slide down-left together, so judges read toward-camera, weakly.

This matches the GPU lane's speed caveat. In swim-away-day the swell lines move about 3 px per strip frame (1.2 px in the far centre) against the near log's 7. With the camera following the swimmer, lines slower than the scenery read as static or backwards. Across-day reads because the lines there cross the screen at 15–20 px.

## 2. Paired look score (each side shows t0, t3, t6, t9, 0.3 s apart)
Batch `G-ff2`:
- three code-blind judges and the standard prompt;
- recorded defect: direction not readable at a glance;
- anchors: craft, f10_2_r3_capacitor, f04_6_r22 (top reference 7.35), so this is a confirming batch.

Fit: linear, slope 0.9678, intercept 0.8922, r 0.731.
Warning (verbatim): `anchor residual RMSE 0.79 > 0.75: these judges do not rank the anchors like the reference judges; report the mapped scores with this caveat`.

| View | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| swim-across-day | 6.34 (6.41, 6.41, 6.22) | **6.86** (6.70, 7.18, 6.70) | **+0.52** | 3/3 |
| swim-away-day | 6.47 (6.51, 6.51, 6.41) | 6.73 (6.80, 6.80, 6.60) | +0.26 | 3/3 |
| swim-away-night | 6.18 (6.22, 6.31, 6.02) | 6.51 (6.51, 6.70, 6.31) | +0.33 | 3/3 |

Raw Bar A (judges a, b, c):
- across: base 5.7, 5.7, 5.5 → arm 6.0, 6.5, 6.0.
- away-day: base 5.8, 5.8, 5.7 → arm 6.1, 6.1, 5.9.
- night: base 5.5, 5.6, 5.3 → arm 5.8, 6.0, 5.6.

The recorded direction defect on the look score:
- base is PRESENT in 8 of 9 judgements (one PARTIAL);
- arm across-day is FIXED/PARTIAL/PARTIAL;
- arm away-day and night are PARTIAL from most judges, with one FIXED on night.

On still frames the lines show the axis. In motion they do not show which way along it the water moves.

Remaining look defects named on the arm:
- **night:** "hard-edged evenly spaced stripes, more like wind lines than foam", and a large milky wash at lower right;
- **away-day:** streaks only in the upper band, plus a milky haze at right;
- **across-day:** soft diagonal bands; called the most natural ("reads clearly"), but also "smeared brush strokes / fog bands rather than lit surface foam".

Every judge still names the flat white foam disc around the swimmer.

## Next step for this technique
This is the first judged round of the sums-of-sines technique (the diag build failed its pre-push check), so it is not parked.
- The one untested variable is speed. Make the lines' screen speed in the away views clearly exceed the near scenery's (log about 7 px per strip frame). That means advection tied to the current's screen-space direction, not world speed alone.
- At night, break up the evenly spaced stripe pattern.
- Across-day already works and should not change.

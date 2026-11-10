# G-newapproach-wave-crests-v3: crests that outrun the drifting swimmer (CARD:T2, F13#5), third attempt

Frames: `tb/gpu-frames-1108` 0b5b57b6f, High, with the current arrow OFF on every side.
- **Sides:** base (shipped arcs); **arm A** (crest_shape 1, crest_margin_m_s 1.6, crests at 2.2 m/s); **arm B** (margin 2.6, crests at 3.2 m/s).
- **Captures:** strips at 0.1 s per step, plus GIFs.
- **GPU lane measurement, swim-away-day:** the log moves about 7 px per strip frame, arm A crests about 29, arm B about 52.
- **Known flaw on both arms (GPU lane):** one crest in swim-away-day (arm A t2–t7, arm B t0–t1) renders as a half-disc with a straight top cut and a grey rectangle. It comes from the crest shader, and the lane will fix it.

## 1. Blind direction test (main question)
Method as in `G-newapproach-wave-crests`:
- nine shuffled, unlabelled strips (3 views × 3 sides; water crop at five moments 0.2 s apart);
- three fresh judges;
- truth: across = RIGHT, both away views = TOWARD_CAMERA;
- data: `yardstick_g_v3/direction_test_strips.json`.

| View | Base | Arm A (2.2 m/s) | Arm B (3.2 m/s) |
|---|---|---|---|
| **swim-away-day** | 0/3 (CANNOT_TELL ×3) | **3/3** TOWARD (confidence 4, 4, 5) | **3/3** TOWARD (confidence 4, 4, 5) |
| swim-away-night | 1/3 (TOWARD, LEFT, LEFT) | 1/3 (LEFT, LEFT, TOWARD) | **2/3** (TOWARD, LEFT, TOWARD; confidence 6) |
| swim-across-day | 3/3 (confidence 6) | 3/3 (confidence 6, 7, 8) | 3/3 (confidence 7, 8, 8) |

**Yes: swim-away-day now reads TOWARD_CAMERA on both arms (3/3), against 0/3 on base.** This is the first time today it has read at all, and it confirms that outrunning the swimmer addresses the camera-follow problem. All three judges noticed independently that "foam blob slides down off screen; streaks move down-left *versus the logs*".

**Confidence is still low** (4–5, readability about 3–4). One judge: toward-camera flow "shows up as marks spreading outward from the centre, which is easy to mistake for leftward flow or camera motion".

**Night is not solved by arm A** (1/3). Arm B reaches 2/3.

## 2. Paired look score (each side shows four moments 0.3 s apart)
Batch `G-v3`:
- three code-blind judges and the standard prompt;
- recorded defect: direction not readable at a glance;
- pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch;
- fit: linear, slope 1.2009, intercept −0.1493, r 0.842, anchor RMSE 0.622; no warnings.

| View | Base | Arm A | Gain A | Prefer A | Arm B | Gain B | Prefer B |
|---|---|---|---|---|---|---|---|
| swim-across-day | 5.65 | **6.34** | **+0.69** | **3/3** | 5.69 | +0.04 | 2/3 |
| swim-away-night | 6.10 | 6.26 | +0.16 | 2/3 | 5.81 | −0.29 | 0/3 |
| swim-away-day | 6.54 | 5.81 | **−0.73** | 0/3 | 6.18 | **−0.36** | 0/3 |

## Does the away-day loss come only from the cut crest? Yes, for both arms.
- **Arm A, swim-away-day:** all three judges name "large hard-edged white half-disc or oval blobs under the log in frames 2 and 3" as a clear artefact. Those are the flawed crest, which appears at arm A t2–t7 (frames 2 and 3 of the 2×2 are t3 and t6).
- **Arm B, swim-away-day:** all three name "a hard-edged white half-disc blob under the near log in frame 1". That is the flawed crest at arm B t0 (frame 1 of the 2×2).
- **No other away-day defect** is named on either arm that base lacks.
- **The flaw does not appear in the other two views,** and there arm A wins: across +0.69 with 3/3, night +0.16 with 2/3.

## Verdict, per arm
- **Arm A (2.2 m/s): WORTH ONE MORE ROUND with the fixed shader.**
  - It fixes swim-away-day direction (0/3 → 3/3).
  - It wins the look score in across (+0.69, 3/3) and night (+0.16, 2/3).
  - It loses away-day (−0.73) **only because of the cut crest.**
  - Re-test arm A with the half-disc fixed on the same direction and look tests. Expect away-day to turn positive if the flaw was the whole cost.
  - Night direction stays at 1/3.
- **Arm B (3.2 m/s): DO NOT PURSUE as is.**
  - It reads direction as well or slightly better (night 2/3).
  - Its look is flat to negative even away from the flaw: across +0.04, night −0.29 with 0/3. The judges describe B's faster crests as "short, uniform dashes in an even scatter that looks generated" and "hook-shaped crescents curling every way".
- **No ship this round.** The away-day frames carry the flawed crest on both arms.

**Remaining water defects, independent of the arms** (named in every T2 batch today, all three judges again):
1. the hard vertical tint or seam band in the water left of the swimmer;
2. the 23:00 views lit like full daylight;
3. the swimmer as a small blob in a flat white foam disc.

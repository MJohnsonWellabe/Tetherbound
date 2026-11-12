# G-newapproach-wave-crests-v3-fixed: v3 arm A with the crest body rebuilt from Gaussians (CARD:T2, F13#5)

Frames: `tb/gpu-frames-1108` 1305175c7, High, base vs arm, with the current arrow OFF on both sides.
- **Arm:** v3 arm A (crest_speed 1.0, margin 1.6) with the crest body rebuilt from Gaussians only.
- **GPU lane pre-check:** the straight-cut half-disc and grey rectangle are gone. In swim-away-day the crests move about 23 px per strip frame against the log's 5–8.

## 1. Blind direction test (strips)
Method as in v3: six shuffled, unlabelled strips and three fresh judges. Data: `yardstick_g_v3f/direction_test_strips.json`.

| View | Base | Arm (fixed) | v3 arm A, for reference |
|---|---|---|---|
| **swim-away-day** | 0/3 (LEFT, CANNOT_TELL ×2) | **1/3** (TOWARD, LEFT, LEFT) | 3/3 |
| swim-away-night | 1/3 (LEFT, LEFT, TOWARD) | **0/3** (LEFT ×3) | 1/3 |
| swim-across-day | 3/3 | 3/3 (confidence 6–7) | 3/3 |

**swim-away-day direction did NOT hold at 3/3.** The rebuilt soft crests now travel diagonally down-left past the logs. Their motion is "20 px left and 12 px down per frame" by one judge's count. Two of three judges read that as LEFT; one read TOWARD_CAMERA.

The v3 crests that read 3/3 had a hard leading edge that made the down-screen travel obvious. The Gaussian body softened the edge, and the direction read went with it.

## 2. Paired look score (each side shows four moments 0.3 s apart)
Batch `G-v3f`:
- three code-blind judges and the standard prompt;
- recorded defect: direction not readable at a glance;
- pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch;
- fit: linear, slope 1.7575, intercept −3.56, r 0.899, anchor RMSE 0.505; no warnings.

**Harness note:** judge a's hand-back left out its JSON. Its scores were taken from the final verdict in its own transcript, and they match the table in its hand-back.

| View | Base | Arm | Gain | Judges preferring arm | Per-view ship? |
|---|---|---|---|---|---|
| swim-across-day | 5.52 | **6.16** | **+0.64** | **3/3** | look yes; direction 3/3 on both sides, so no change |
| swim-away-night | 5.70 | **6.28** | **+0.58** | **3/3** | look yes; **direction 0/3** (base 1/3) |
| swim-away-day | 6.22 | 5.34 | **−0.88** | 0/3 | **no** |

## What the judges saw in swim-away-day
All three still flag artefacts on the arm side:
- "large hard-edged white oval blobs near the bottom and under the log";
- "big white ovals pop in near the bottom edge, which look like flicker";
- "hard, bright white oval blobs … read as rendering artefacts or flicker, not crests".

The straight cut is gone, but at this camera the Gaussian crest still reads as a hard white oval that pops. Elsewhere the arm's crests are softer and more consistently oriented, and the judges prefer them in across and night.

## Verdict
**DO NOT SHIP (overall).** The coordinator's gate fails on both counts:
- swim-away-day direction is 1/3, not 3/3;
- swim-away-day look is −0.88 with 0/3.

| View | Ship? |
|---|---|
| swim-across-day | Passes the look rule (+0.64, 3/3). Direction is no better than base. |
| swim-away-night | Passes the look rule (+0.58, 3/3), but direction gets worse (0/3 against 1/3). |
| swim-away-day | Fails both. |

**No Medium confirm.** Nothing here moves CARD:T2 or F13#5 toward a close. The best arm view maps 6.28, against the earlier T2 arrow close-out at High 6.32 and Medium 6.24. This would land only as a cue change, and as a cue it does not pass.

**Status.** This is the fourth in-water attempt on this item: waves, crests, v3 and v3-fixed. Only v3's hard-edged crests made the toward-camera direction read, and those were the crests that read as artefacts. The judges' consistent suggestion is a different technique: flow-mapped normals and scrolling soft foam that move along the current, instead of discrete crest shapes.

Recommendation: park the crest-shape line under the owner's 25 Oct rule. Keep the shipped arcs and the arrow. Fix the three cheap water defects every judge named again:
1. the vertical seam band;
2. the 23:00 views lit like daylight;
3. the opaque white foam disc around the swimmer.

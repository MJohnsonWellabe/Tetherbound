# G-f40-0-skyroad-arch-recapture: the missing 32 F40#0 frames (broken_skyroad_arch), GPU High

**Frames:** `tb/gpu-frames-1108` cd874ab2c, main 3a514ef5c after #909 (stand on the arch crown), High.
- Capture: `capture_cloudreach_f40_matrix.gd --ground-cover-cache`.
- Coverage: broken_causeways_04 broken_skyroad_arch, 4 views × 4 times × 2 weathers = 32 frames. This completes the F40#0 matrix to 384.
- Blank frames: 0 of 32.

**Method:** 8 one-sided sheets, one per time and weather, each a 2×2 of the stand's four views (approach, gameplay, reverse, detail).
- Every arch frame is judged.
- The brief is the 10 Nov F40#0 biome-look brief (`G-baseline-f40-0-f40-21-cloudreach.md`), reworded for "one place from four views".
- Recorded defect: none.

**Batch `G-arch`:**
- Three code-blind judges, standard prompt.
- The same anchors as the 10 Nov baseline: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. This is a confirming batch.

**Fit:** linear, slope 1.1792, intercept −0.3118, r 0.886, anchor RMSE 0.642. No warnings.

## Results

| Sheet | Raw a, b, c | Mapped |
|---|---|---|
| dawn, clear | 6.1, 5.8, 5.8 | 6.65 |
| day, clear | 6.0, 5.9, 5.7 | 6.61 |
| golden, clear | 6.1, 5.6, 5.8 | 6.57 |
| night, clear | 5.6, 5.4, 5.4 | 6.13 |
| day, rain | 5.3, 5.0, 5.1 | 5.74 |
| golden, rain | 5.3, 4.9, 5.0 | 5.66 |
| dawn, rain | 5.4, 4.8, 4.9 | 5.62 |
| night, rain | 4.9, 4.85, 4.9 | 5.45 |
| **Arch, all 32 frames equally** | | **6.05** (clear 6.49, rain 5.62) |

## New F40#0 row figure over 384 frames: **6.54**
- **How it is computed:** the 10 Nov 352-frame baseline (6.58), weighted 352/384, plus the arch (6.05), weighted 32/384.
- **Alternative weighting:** weighting the arch sheets like the baseline's sheet mix (3 day-clear, 1 each of dawn, golden and night, 1 rain) gives the arch 6.40 and the row **6.57**.
- **Either way the row is essentially unchanged from 6.58, and still below 7.**
- **Caveat:** the arch comes from a different judge pool than the baseline, so the blend is approximate.

## What the judges say (3/3 unless noted)
- **Empty stand:** the stand is "one empty grass disc with one broken arch and a few slabs". It reads as "a generator test pad".
  - There are no props, groves, flowers or creatures.
  - The approach view ends at a smooth cylindrical dirt rim, not a cliff with strata.
- **Missing Cloudreach identity:** there is no cloud sea, no sky islands, no waterfalls and no aviary in view. This repeats the baseline's biggest lift.
- **Rain (all four rain sheets):** the rain is long, opaque, evenly spaced white streaks that read as a screen overlay.
  - Night-rain's sky is bright grey at 23:00, so it reads as day (judges a and b).
  - Golden-rain shows no golden hour at all.
  - This repeats the baseline's worst sheet (rain, 5.74).
- **Dawn and night:** the foreground crushes dark and the trainer sinks into it.
- **Golden clear:** a sepia haze washes out the distant stacks. This repeats the baseline note.
- **What carries it:**
  - the bright day sky with pale layered stacks (day clear);
  - the pink-orange dawn sky against dark stacks.
- **Owner rules:** no oxblood seen.

## Implication for the floor lane
The arch adds nothing new. Its weak points are the baseline's top two causes:
1. the rain grade and streak rendering;
2. the empty plateau without Cloudreach landmarks or a cloud sea.

A rain-grade fix would lift 4 of these 8 sheets, and the 1-in-8 rain share of the full matrix.

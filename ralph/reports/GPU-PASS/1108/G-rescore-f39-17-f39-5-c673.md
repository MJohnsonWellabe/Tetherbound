# G-rescore-f39-17-f39-5-c673: F39#17, F39#16, F39#5, F39#14 on main (GPU High, one-sided)

| Row | Mapped | Per judge (a, b, c) | Raw | Board | Change | Defect (a / b / c) |
|---|---|---|---|---|---|---|
| **F39#17** current restoration | **6.55** | 6.83, 6.23, 6.59 | 6.2, 5.7, 6.0 | 5.50 | **+1.05** | restored looks unchanged: PARTIAL / PRESENT / PARTIAL |
| F39#16 live streaks (same frames) | 6.55 | same set | same | 6.56 | level | guide-lane streaks: FIXED / PARTIAL / PARTIAL |
| **F39#5** swim pose | **6.35** | 6.35, 6.35, 6.35 | 5.8, 5.8, 5.8 | 5.64 | **+0.71** | wading pose: PARTIAL 3/3 |
| F39#14 swimmer water contact (same frames) | 6.35 | same set | same | 6.60 | −0.25 (other batch) | wake/shadow: PARTIAL 3/3 |

- **F39#17 clears 6.**
  - Currents (3/3): the live currents are small scattered chevrons, not parallel lanes.
  - Restored state (2/3): it now changes the water, with shallow rings around the islands.
- **F39#5 clears 6.** The trainer lies flat with arms out.
- **F39#14:** it shares these frames, and its 6.35 here is lower than the board's 6.60 from another batch. The judges mark the wake down; see the asks.

## Frames and batch
- Section: `tb/gpu-frames-1113` 7d1387c8d, tree c673d5285 (= main 4f9ee3967), High, job.json frames.
  - F39-5 and F39-14 are byte-identical; F39-16 is a subset of F39-17.
- Batch: `yardstick_g_rescore_1113/`. Anchors: craft, f36_0_npc:C1, f04_6_r22. Fit r 0.961, RMSE 0.28. Confirming.

## What the judges see
- **Currents:**
  - 3/3: a hard dark navy plane cuts straight across the mid-distance water in every frame ("reads like a cast shadow or a hard depth cutoff").
  - 3/3: in frame 2 the shoal halos around the islands are flat, perfectly concentric rings.
  - Judges b and c: frame 2 still has one long, bright, straight streak.
- **Swim:**
  - 3/3: the boots trail as separate dark blobs below the body.
  - 3/3: the wake is large, blurry, cloud-like foam discs strewn across open water, not a ring around the body.
  - Judge a: frame 3 is a long flat white wake slab.
  - Judge c: the hard shadow is gone.

## Next asks (LANE-LAND-MT)
1. **Replace the hard shallow-to-deep navy edge** with a soft depth gradient. It is in every current frame and is the main thing holding F39#17 and F39#16. Scene.
2. **Make the island shoal rings irregular,** following the sandbar shape. Remove the last long straight streak in S2_live. Scene.
3. **Swim:**
   - Replace the blob foam with a small ring and V-wake that stay at the body.
   - Drop the frame 3 white slab.
   - Hide or submerge the boots in the swim pose.
   
   This covers F39#5 and F39#14 together. Scene and animation.

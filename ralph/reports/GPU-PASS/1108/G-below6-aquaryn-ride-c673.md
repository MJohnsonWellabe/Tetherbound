# G-below6-aquaryn-ride-c673: F39#8 Aquaryn deep swim (GPU High, base vs arm)

## Verdict: SHIP. F39#8 goes 5.97 → 6.32 (+0.35, 3/3 prefer the arm), clearing 6. No loss.

| Set | Base (main) | Arm (deep_swim_1113) | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base → arm) |
|---|---|---|---|---|---|---|
| **F39#8** mounted-swim-03/04/05 | 5.97 | **6.32** | **+0.35** | 3/3 | 5.4→5.7, 5.6→5.9, 5.6→5.9 | PRESENT → PARTIAL 3/3 |

- **Panel strictness:** this batch ran about 0.6 strict (control 7.63 against 8.16/8.30).
- **Confound:** the beach creature differs between runs (base a rock turtle, arm a green lizard or crocodile). All three judges named it and said it is not the subject. The arm's gain is the mount's waterline.

## What the judges see
- **Base (3/3):** "the mount stands tall above the surface with legs and belly visible", which reads as standing on the water, on a flat fixed white foam disc.
- **Arm (3/3):** the mount "sits lower, with its fins spread at the waterline; the white ring is smaller and hugs the body". It reads a bit more as swimming.
- **Both sides (3/3):**
  - Still static across the three frames: no stroke, bob, trailing V-wake, bow wave or spray.
  - The water is one flat, tiled turquoise sheet with no navy depth gradient.
  - Seen from behind, the mount and rider merge into one fin cluster, so the mount's head and face don't read.

## Frames and batch
- Section: `tb/gpu-frames-1113` 5be8ac80d, High, job frames mounted-swim-03/04/05 stacked. Mean pixel difference 11.4–11.5.
- Batch: `yardstick_g_batch5_1113/`. Fit r 0.925, RMSE 0.38. Confirming.

## Next asks (LANE-BEINGS for the mount, LANE-LAND-MT for the water)
1. **Swim cycle on the mount:** a stroke and bob, so the three frames differ. This is the remaining half of F39#8's defect, top ask 3/3. Animation.
2. **Trailing V-wake and bow spray** behind and ahead of the mount, instead of the static foam disc. Scene/VFX.
3. **Camera:** offset the ride camera a little to the side, so the mount's head reads past the rider. Scene.
4. **Water:** a navy depth gradient on Tidewake water. This is shared with F39#17 and F39#16 (the hard depth edge). Scene.

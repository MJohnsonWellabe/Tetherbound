# G-sw-rain-thin: Stormwood rain thinning arm

Frames: `tb/gpu-frames-1108` d1acc5a4e, High. Live is main 4af7d07a9. The arm is live plus `ITEM-SW-RAIN-ARM/overlay_rain_thin.json`:
- near streaks 0.07 → 0.03 m wide;
- length 1.15 → 1.4 m;
- alpha 0.3 → 0.2;
- `near_fade_m` [3.5, 7.0];
- thinner far and curtain layers.

A pixel check (before judging) confirmed the overlay rendered: near streaks are visibly thinner and fainter, for example on Oswin's frame.

`G-sw-foliage-grade` was not judged: its arm hit `Image.adjust_bsc` errors (see `ITEM-SW-FOLIAGE-ARM/ARM.md`).

Batch `G-rain`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so the top anchor is 7.35 and this is a confirming batch.
- Fit: linear, slope 1.5181, intercept −2.3162, r 0.872, anchor RMSE 0.565. No warnings.

| Row | Item | Live | Arm | Gain | Judges preferring arm | Ship |
|---|---|---|---|---|---|---|
| F41#8 | named character silhouettes | 5.68 | 5.68 | 0.00 | 0/3 (3 ties) | no |
| F41#11 | named character portrait identity | 6.94 | 6.94 | 0.00 | 0/3 (3 ties) | no |
| F41#17 | Crown Arch | 6.79 | 6.84 | +0.05 | 1/3 (j3 6.1 → 6.2) | no |
| F41#20 | named character dialogue reuse | 6.44 | 6.49 | +0.05 | 1/3 (j3 5.6 → 5.7) | no |

**Flat, so it does not ship.** All three judges saw the two sides as near-identical. They still describe the rain on both sides as "long white sticks", "opaque white bars" or "rod-like". Judge c alone noted "less rain clutter in the foreground" on the arm side of F41#17.

At these stands the visible streaks that read as rods are mostly mid-distance and far, not the near layer the arm thinned. Cutting the near layer did not change how the rain reads.

**Park the rain arm.** A different idea would have to reach the streaks the judges actually see:
- Shorter streaks with a soft head and tail, across all layers. This is a streak-shader or mesh change, which is code.
- Or far fewer, fainter mid-layer drops.

Rain is a secondary complaint on these rows in any case.

## What the judges rank first for these rows (3/3)
- **F41#20:** Fenn and Oswin share one hooded, bearded model and one portrait. This needs new art or an appearance variant.
- **F41#8:** the NPCs are tiny at the capture distance, with similar chunky bodies.
- **F41#17:**
  - A hard-edged square slab on the black pool.
  - Pale lavender stone that flattens against the purple sky.
  - Salmon-pink background bears (off-palette).
- **Stormwood-wide:**
  - The black pools read as voids or holes.
  - The trunks are flat pink-brown.
  - The bears are salmon-pink.

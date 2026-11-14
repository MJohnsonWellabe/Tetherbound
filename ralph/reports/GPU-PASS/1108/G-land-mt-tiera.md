# G-land-mt-tiera: Veilfall lower cascade tier removed (GPU High, post-#958 base vs arm)

## Verdict: DO NOT SHIP (level, −0.04, 1/3 prefer the arm). F39#31 5.78 → 5.74. Not a judged loss, but no gain.

| Set | Base (main 13a7ab153) | Arm (TIERA) | Gain | Prefer arm | Raw a / b / c (base → arm) |
|---|---|---|---|---|---|
| **F39#31** (veilfall-vista + veilfall-near) | 5.78 | 5.74 | −0.04 | 1/3 | 5.2→5.1, 5.1→5.0, 5.5→5.6 |

- **Scores:** all mapped, from the same batch as G-rescore-f39-31-post958. Fit r 0.909, RMSE 0.58, confirming.
- **Pixel difference:** the arm differs from base by 1.97 in the close frame and 1.11 in the distance frame. The distance frame is no-loss by construction.
- **Ship rule:** fails. The gain is not above 0, and only 1/3 prefer the arm. The −0.04 is within judge noise, so I do not call it a loss.

## What the judges see
- **The removal does not register as an improvement.** No judge names the missing pale rock cluster. All three still report "boulders and shrubs floating in the fall's path" on both sides, because the remaining sapling rock is still in the fall's path.
- **Close frame:** judges a and b see the base sheet as "slightly more spray texture / crisper" and the arm as "softer but blurred and smeared". Judge c prefers the arm's softer edges and "marginally more natural foam falloff".
- **Everything else matches G-rescore-f39-31-post958** (boulder-heap form, no tiers or ledges, no base mist).

## Next asks (LANE-LAND-MT)
1. **Park this approach.** Taking pieces away from the current fall does not move the row. Its ceiling is the landmark's form, which needs the board rebuild (G-rescore-f39-31-post958 ask 1).
2. **If the lane keeps a cleanup arm,** remove the remaining sapling rock from the fall path as well, and ride it with a positive change (mist plume or water material) rather than standing alone.

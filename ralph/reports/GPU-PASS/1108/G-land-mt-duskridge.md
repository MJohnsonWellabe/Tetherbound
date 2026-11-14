# G-land-mt-duskridge: Meadows ridge warm-haze fix at dusk, F38#0 dusk / F38#24 (GPU High, base vs arm)

## Verdict: SHIP. Dusk vistas 6.41 → 7.10 (+0.69, 3/3); F38#24 day frames level (no loss).

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Mountain defect (base → arm) |
|---|---|---|---|---|---|---|
| **Dusk vistas** (warrens and stronghold vista_dusk) | 6.41 | **7.10** | **+0.69** | 3/3 | 5.8→6.3, 5.8→6.3, 5.3→6.1 | PARTIAL → PARTIAL 3/3 |
| F38#24 day (warrens walk_02/03, stronghold route_day), no-loss | 6.56 | 6.56 | 0.00 | ties | 5.9, 6.0, 5.4 | PARTIAL 3/3, both sides |

- **Scoring:** all scores are mapped. Fit: linear, slope 1.154, intercept −0.094, r 0.908, anchor RMSE 0.58. No warnings.
- **Shared batch** with G-land-mt-brokenhill (same base run).

## What the judges see
- **Arm dusk (3/3):** "a cool blue-violet range with snow caps against a warm sky … warm-foreground / cool-distance separation, matching the key art's dusk".
- **Base dusk (3/3):** the range is "washed into a flat peach / orange silhouette that nearly merges with the sky".
- **Remaining on both sides:**
  - The left massif still shows vertical streak facets, so the defect stays PARTIAL.
  - The right-hand slope is one flat wedge (judge b).
  - Frame 1 (warrens vista_dusk) shows the backdrop only as a sliver at the right edge.
- **Day frames, both sides (3/3):**
  - Warrens walk_02 faces the near hill with no backdrop.
  - Walk_03's peaks are "simple smooth blue cones".
  - Floating blue-white shards sit on the hill crest (judges b and c).
- **Flag (judge c):** the stronghold's orange-red window glow in dusk frame 1 sits close to the reserved red. It is acceptable on the enemy stronghold.

## Next asks (LANE-LAND-MT)
1. **A layered mountain backdrop:** two or three depth layers with their own aerial tint, sculpted ridgelines in place of streaky facets and cones. This is the 3/3 top ask for F38#24 day and dusk. new_art.
2. **Re-aim warrens walk_02 and vista_dusk** so the backdrop is in frame. This was already asked in G-rescore-f38-24-after-952.
3. **Remove the floating blue-white shards** on the warrens hill crest. Scene.

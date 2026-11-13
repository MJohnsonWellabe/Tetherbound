# G-rescore-f39-31-post958: F39#31 Veilfall clear day after #958 (GPU High, main 13a7ab153)

## Score: F39#31 = 5.78 mapped. Paired against the pre-#958 frames in the same batch: 5.16 → 5.78 (+0.62, 3/3 prefer post-#958).

| Set | Pre-#958 | Post-#958 | Gain | Prefer post | Raw a / b / c (pre → post) |
|---|---|---|---|---|---|
| **F39#31** (veilfall-vista + veilfall-near) | 5.16 | **5.78** | **+0.62** | 3/3 | 4.7→5.2, 4.6→5.0, 4.9→5.6 |

- **Baseline:** 5.78 replaces the pre-#958 one-sided 5.93 as F39#31's current baseline.
- **Why the score is lower than 5.93 when it improved:** the two numbers come from different panels. This panel is stricter: it scored the same pre-#958 frames 5.16, not 5.93. The same-batch paired read (+0.62, 3/3) is the measure of #958.
- **Fit:** r 0.909, slope 1.15, anchor RMSE 0.58. The batch is confirming, with no warnings. Recorded defect: none.

## What #958 changed (3/3)
- **Pre-#958 close frame:** "a large unlit navy or black faceted wedge" fills the gorge right of the fall, with a hard polygonal sheet edge against it, "the most visible artefact in the batch". **Post-#958:** gone; "the shading is soft and continuous, so the gorge reads as one landform".
- **Pre-#958 distance frame:** the fall texture was blockier and pixel-stepped; post-#958 it is softer.

## What still holds the row near 5.8 (3/3)
- **Distance frame:** the landmark is "a brown low-poly boulder heap" or "faceted rock spire" with one thin white ribbon of water. Against the Veilfall board it has no tiered falls, no moss or tree ledges and no pale stratified stone.
- **Base of the fall:** no mist, spray or plunge pool; the water ends on the sand rim. The mist fix does not read at contact-sheet size.
- **Close frame:**
  - The water is "a white sheet draped over dune-like slopes", reading as cloth or ribbon, not falling water.
  - Small boulders and shrubs float in the fall's path.
  - The slopes carry stretched, striped texture.
- **Islets:** the ring-shaped sandbar islets look generator-placed (judge c).

## Next asks (LANE-LAND-MT)
1. **Rebuild Veilfall from its board (3/3 top ask):** tiered falls, pale stratified stone, moss and tree-lined ledges. This is new art (Meshy hero piece), not a scene tweak.
2. **Make the base mist and spray read at distance,** with a plunge pool and foam where the fall meets the water. Scene/VFX.
3. **Use a streaked falling-water material** instead of the flat white sheet. Scene.
4. **Remove the floating rock and shrub props from the fall path,** and fix the striped slope texture. Scene.

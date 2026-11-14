# G-lcs-wallband-bridge: WALL-BAND no-loss on F40#8, Three Bells bridge day close (GPU High, base vs arm)

## Verdict: LOSS. F40#8 6.29 → 5.86 (−0.43, 0/3 prefer the arm). WALL-BAND's ship verdict (G-below6-wall-band-main) is withdrawn: DO NOT SHIP.

| Set | Base | Arm (wall_top_band) | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base / arm) |
|---|---|---|---|---|---|---|
| **F40#8 bridge** (day close) | 6.29 | **5.86** | **−0.43** | **0/3** | 5.5→5.2, 5.6→5.2, 6.0→5.6 | PARTIAL / PARTIAL 3/3 |

- **Scores:** all mapped. Fit: r 0.901, slope 1.18, anchor RMSE 0.60; the batch is confirming.
- **Frame:** one frame, pixel difference 5.79. Camera, sky and grass are identical. The "axis must be normalized" errors appear on both sides.
- **Position:** the arm sat on side A. Given the side-B lean seen in the SEADEPTH batches, I checked the reasons: all three judges name the same concrete artefact on the arm (below). That is not a position preference, so I count the loss.

## What the judges see (3/3)
- **Arm:** the big cliff right of the bridge becomes "a pale grey mass with sharp faceted brown patches", which reads as "stretched or triplanar texture seams, a camouflage pattern that reads as an artefact rather than strata", "a mis-mapped material" that "clashes with the warm brown sea-stacks around it". Judge a also sees "a floating brown ledge" on that face.
- **Base:** "a coherent warm brown that matches the cliffs on the right … one rock family". Heavier and muddier, but believable.
- **Why the same arm gained on F40#1:** at the Realm Gate the band is a thin rim strip on a disc edge. Here it repaints a whole cliff face with the patchy mask, which exposes it.
- **F40#8's own defect is unchanged (PARTIAL 3/3):** no saturated cyan posts are visible any more, but "a white post with a bright gold cone tip" still stands behind the trainer and competes with the bell gate.

## Next asks (LANE-LAND-CS)
1. **Limit the wall-top band to rim and wall-top geometry** (by height band or by a slope and normal mask), so it never repaints whole cliff faces. Then re-judge on F40#1 plus this F40#8 frame together. +0.32 on F40#1 is waiting.
2. **If pale stone on cliffs is wanted,** use a real stratified pale-stone material with consistent UVs or triplanar blending, not the brown-patch mask.
3. **F40#8:** mute or remove the gold-cone pointer post behind the trainer. This is the last part of the recorded defect.

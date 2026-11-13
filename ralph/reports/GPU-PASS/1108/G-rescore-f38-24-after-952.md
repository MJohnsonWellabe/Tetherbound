# G-rescore-f38-24-after-952: F38#24 distant mountains after #952 (GPU High, one-sided)

## Score: F38#24 = 6.59 mapped (board 6.01, so +0.58). Clears 6.

| | Value |
|---|---|
| Raw a / b / c | 6.3, 5.4, 6.3 |
| Mapped per judge | 6.95, 5.88, 6.95 |
| Recorded defect (faceted mountains, dark slashes) | FIXED for a and c, PARTIAL for b |

#952 does its job: where the backdrop is visible, the ranges are continuous blue silhouettes with snow caps and aerial haze, and no judge sees hard facets or dark slashes. The row now loses its points on framing, not on the mountains.

## Frames
- Section: `tb/gpu-frames-1113` 5868dc16c, main 874835eab game content, High.
- The three job.json frames, stacked:
  - warrens walk_02_day;
  - warrens walk_03_day;
  - stronghold route_day (shot right after the warrens vista_dusk; its mountains keep their day haze).
- Batch: `yardstick_g_rescore_1113/`, the shared re-score batch for this round.
  - Anchors: craft, f36_0_npc:C1, f04_6_r22.
  - Fit: linear, slope 1.195, intercept −0.576, r 0.961, anchor RMSE 0.28. Confirming batch.

## What the judges see
- **Frame 1, warrens walk_02 (3/3):** the camera faces a smeared, low-resolution grass hill, and no backdrop is visible at all.
- **Frame 2, walk_03 (3/3):** a flat green wall or hill partly hides the ranges.
- **Frame 3, stronghold route_day (3/3):** reads as the key art: hazy ranges with snow on the ridge, plus the castle.
- **Mountains (judge a):** they read as flat painted cards with little aerial layering.

## Next asks (LANE-LAND-MT)
1. **Re-aim or re-stand warrens walk_02 and walk_03** so the mountain backdrop is the subject, not the near hillside. Those two frames are what hold the row at 6.6. Scene.
2. **Add a second, hazier range layer** behind the current one so distance reads in depth, not as one card. Scene.
3. **Give the near slopes a tiling detail material** to replace the smeared low-resolution grass that fills frames 1 and 2. Scene.

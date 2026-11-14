# G-rescore-f38-16-c673: F38#16 tournament dialogue on main (GPU High, one-sided)

## Score: F38#16 = 7.31 mapped (board 6.32, so +0.99)

| | Value |
|---|---|
| Raw a / b / c | 6.6, 6.5, 6.7 |
| Mapped per judge | 7.31, 7.19, 7.43 |
| Recorded defect: same grey-haired character at the stand | **FIXED 3/3** |

All three conversations now show a different in-world speaker who matches the portrait: Mira with brown hair, Tam with grey hair, Oskar with dark hair. The row is 0.19 short of the bar at High.

## Frames and batch
- Section: `tb/gpu-frames-1113` ddffe7ea3, tree c673d5285 (= main 4f9ee3967), High.
- The three job.json `__dialogue` frames at camera blend 1.0: quarter_mira, semi_tam, final_oskar.
- Batch: `yardstick_g_rescore_1113/`. Fit r 0.961, RMSE 0.28. Confirming.

## What the judges see
- **3/3:**
  - A pink glowing bush on the left in every frame reads as an odd effect.
  - Faces are flat and mask-like, more mascot than stylised realism.
- **Judge a:** Mira and Tam share the same green-hood body and differ only in hair colour.
- **Judge b:** the foreground ground is smeared.
- **Judge c:** the conversation camera is stiff and front-on.

## Next asks (LANE-BEINGS for the bodies, LANE-SCENE for the stand)
1. **Give Mira and Tam distinct outfits** (colour or garment), so the three tournament opponents differ beyond hair. Scene.
2. **Remove or retint the pink glowing bush** at the left of the tournament stand. Scene.
3. **Add a slight three-quarter angle** to the conversation camera and a detail material on the foreground ground. Scene.

These three are the near-bar route (close-out exception: 7.31).

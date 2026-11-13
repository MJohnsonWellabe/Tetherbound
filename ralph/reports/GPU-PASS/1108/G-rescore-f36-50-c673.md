# G-rescore-f36-50-c673: water mangrove monitor on main (GPU High, one-sided). This scores F36#92, not F36#50.

## Row identity
The section captured `water_mangrove_monitor`. That species is **F36#92 Water Mangrove Monitor**: see G-water-gameclip-rescores and G-things-faint2. **F36#50 Mangrove Monitor** is species `mangrove_monitor`, and it was not captured, so F36#50 stays unscored on c673.

## Score: F36#92 = 7.47 mapped (board 7.19, so +0.28). 0.03 short of the bar at High.

| | Value |
|---|---|
| Raw a / b / c | 6.8, 6.6, 6.8 |
| Mapped per judge | 7.55, 7.31, 7.55 |
| Dark olive body, low contrast | FIXED (a) / PARTIAL (b) / PARTIAL (c) |
| Faint does not settle | FIXED (a) / PARTIAL (b) / PARTIAL (c) |

The judges read it as "a believable large monitor lizard with a fantasy crest", well over the 1.80 m trainer. Its body is greener, with a cream belly, gold spots and orange spines.

## Frames and batch
- Section: `tb/gpu-frames-1113` a395b2c1e, tree c673d5285, High, pose stage with `--whole-body --context` and the clear ruler.
- Set: 2×2 of hit-000, hit-050, faint-050 and faint-100, cropped to (560, 200, 1560, 840).
- Swim frames were captured but not judged; this row is about the pose and the stage.
- Batch: `yardstick_g_rescore_1113/`. Fit r 0.961, RMSE 0.28. Confirming.

## What the judges see
- **Faint-050 (3/3):** a front leg is lifted or curled and hangs under the raised body. Judge c also sees a detached shadow.
- **Faint-100:**
  - Judges a and c: it lies flat and is grounded.
  - Judge b: the tail tip clips into the floor.
- **Judge c:** the dorsal side is still dark.
- **Judge b:** the orange crest spikes lean slightly cartoon.

## Next asks (LANE-BEINGS)
1. **Faint mid-pose:** fold the lifted front leg under the body, and lower the torso so the shadow stays attached. This is the close-out item, and the row is 0.03 short. Pose data.
2. **Lift the dorsal value slightly** (a lighter olive or a moss band along the spine) so the top line separates from the stage. Material.
3. **Capture F36#50:** species `mangrove_monitor`, with the same `--whole-body --context` and clear ruler, so that row gets its post-#923 re-score.
4. **Confirm the close:** if 1 lands, F36#92 needs High plus Medium in a confirming batch to close.

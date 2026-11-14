# G-below6-overlook-join-c673: F40#15 overlook ridge join (GPU High, base vs arm)

## Verdict: SHIP (gain > 0, 3/3 prefer the arm, no judged set loses)

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base → arm) |
|---|---|---|---|---|---|---|
| Overlook route_day, vista_dusk, walk_01 | 4.86 | **5.28** | **+0.42** | 3/3 | 5.0→5.2, 5.0→5.3, 4.2→4.5 | PRESENT → PARTIAL 3/3 |
| No-loss: sky shrine (4 views/times) | 6.71 | 6.76 | +0.05 | 1/3 (2 ties) | 6.1→6.2, 6.3=6.3, 5.3=5.3 | none recorded |
| No-loss: high perch court (4 views/times) | 5.49 | 5.60 | +0.11 | 1/3 (2 ties) | 5.6=5.6, 5.3=5.3, 4.5→4.7 | none recorded |

All scores are mapped (calibrate.py). No set loses. The perch-court and shrine differences come from different wild-creature spawns between runs, not from the arm. The judges named the creatures but scored the court and shrine the same.

**F40#15 row:** the job frame walk_03_day hardly changes with this arm (mean pixel difference 0.59), so the row's own frame is not moved. Use G-below6-overlook-solid-c673 for the row read.

## Frames
- `tb/gpu-frames-1113` e33f0afd1 (overlook), c34f3cb1e (perches). Tree c673d5285, whose files equal main 4f9ee3967. High, 1920 JPEG.
- Arm: `BELOW6-OVERLOOK-JOIN/overlay.json` (landmass.overlook_ridge_join_1113).
- Set images are three frames stacked; route_day, vista_dusk and walk_01 carry the change (mean pixel difference 6.8, 5.3, 6.1).
- walk_02 (1.9) and walk_03 (0.59) are unchanged and not judged.
- Perches no-loss sample: 8 of the 64 pairs, weighted to the largest base-vs-arm differences. All 64 differences are 1.4–8.5 mean, from spawns, rain and the clock (18:00 vs 18:01).

## Batch `G-overlook-1113` (shared with G-below6-overlook-solid-c673)
- Three fresh code-blind judges, standard prompt, A/B randomised per set.
- Anchors: craft, f36_0_npc:C1, f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.5836, intercept −2.6357, r 0.945, anchor RMSE 0.45. No warnings.
- Files: `yardstick_g_overlook_1113/`.

## What the judges see
- **Arm (3/3):** the long thin black line across the grass at the trainer's feet is gone.
- **Remaining (3/3):**
  - The dark cobble or slab wedge still juts past the path edge toward the void.
  - A hard edge shows where the lifted ground meets the grass in frame 1 (judge a).
- **Both sides (3/3):**
  - Flat, blurry green ramp ground.
  - Open-backed wall slabs, one floating past the tower edge in walk_01.
  - The arch reads as a plain bent beam.
  - The cliff edge over the cloud sea is the only real depth.

## Next asks (LANE-LAND-CS)
1. **Remove the dark wedge slab** beside the path (route_day and vista_dusk, right of the trainer) or ground it. It is the remaining half of the F40#15 defect in these frames. Scene.
2. **Cap or back-face the open-backed wall slabs** so no wall ends in mid-air (walk_01 right tower). Scene.
3. **Replace the flat green ramp** with the board's pale stratified stone: edging and terrace paving at the overlook. Scene, with new art for hero paving if needed.
4. **Do not stack untested.** This arm and OVERLOOK-SOLID were judged separately against the same base. If both land, a combined capture is the honest check.

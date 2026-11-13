# G-rescore-tidewake-fights-c673: F39#7 and F39#19 on main (GPU High, one-sided). F39#3 not scored.

| Row | Mapped | Per judge (a, b, c) | Raw | Board | Change | Defect (a / b / c) |
|---|---|---|---|---|---|---|
| **F39#19** roster contrast | **7.47** | 7.43, 7.43, 7.55 | 6.7, 6.7, 6.8 | 6.56 | **+0.91** | FIXED 3/3 |
| **F39#7** fight actor composition | **7.11** | 7.19, 6.95, 7.19 | 6.5, 6.3, 6.5 | 7.07 | level (+0.04) | PARTIAL 3/3 |

- **F39#19** is 0.03 short at High. The roster on dark slate cells with teal borders and green bars "stays readable over sand and water" (3/3).
- **F39#3** (named destination read) was not scored. Its job frames are Tidewake route_day destinations (drowned_garden_terraces, gull_rest_signal_spire, lantern_cove_drift_arch), and they were not in this fight section.

## Frames and batch
- Section: `tb/gpu-frames-1113` 038ab2ca8, tree c673d5285, High.
- Venn fight: 32 frames, `--fixed-fps 20`; the tool stops at its 32-frame cap with the fight still on. The HUD shows combat verbs only (#947).
- Sets:
  - F39#7: the job frames t-023.02, t-024.02, t-025.02.
  - F39#19: t-000.00, tell-start-000.57 (nearest to the job's 000_48), t-003.02.
- One-sided, so there are no unmatched frames.
- Batch: `yardstick_g_rescore_1113/`. Fit r 0.961, RMSE 0.28. Confirming.

## What the judges see
- **F39#7:**
  - 3/3: the actors are mostly apart, but the opposing trainer (Officer Venn) presses against Cannonback's rear flank in frame 2 and is half-hidden behind the shell in frame 3.
  - Judges b and c: the high camera over flat beige sand makes the staging plain.
  - Judge c: an angular dark rock mass at the top left of frame 1 looks unfinished.
- **F39#19:** judge c notes the roster rows show only small icons, no names.

## Next asks
1. **F39#7 (LANE-SCENE):** keep the opposing trainer at a minimum distance from Cannonback (frames t-024 and t-025) so no part of the trainer sits behind the shell. That is the remaining defect. Scene.
2. **F39#7:** lower the fight camera slightly, or add dune-ripple detail and a little shadow under it. Replace or dress the dark rock block at the top left. Scene.
3. **F39#19:** at 7.47 it is a near-bar close-out item. Optionally add short names to the roster rows. To close it, capture Medium and run a High plus Medium confirming batch with the F38#38 control.
4. **F39#3 (GPU lane):** capture its three route_day frames so it can be re-scored.

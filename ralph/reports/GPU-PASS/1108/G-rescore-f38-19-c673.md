# G-rescore-f38-19-c673: F38#19, F38#10, F38#34 on main (GPU High, one-sided)

| Row | Mapped | Per judge (a, b, c) | Raw | Board | Change | Defect (a / b / c) |
|---|---|---|---|---|---|---|
| **F38#10** secondary menu panels (Build only) | **7.75** | 7.79, 7.67, 7.79 | 7.0, 6.9, 7.0 | 7.38 | +0.37 | PARTIAL 3/3 (Quests and Players not shown) |
| **F38#19** exploration HUD | **7.27** | 7.31, 7.31, 7.19 | 6.6, 6.6, 6.5 | 7.17 | +0.10 | PARTIAL 3/3 |
| **F38#34** placed wall | **6.99** | 6.71, 7.07, 7.19 | 6.1, 6.4, 6.5 | 7.08 | level | FIXED 3/3 |

- **F38#10** meets the bar at High, above the top anchor (7.53), in a confirming batch, but only on the Build panel. The job's other two frames (menu_players, menu_quest_log) were not captured, and the judges marked the defect PARTIAL because they could not see them. It does not close until those two frames and Medium are judged.
- **F38#4 and F38#9** were captured but not judged. Both are closed rows and unchanged here.

## Frames and batch
- Section: `tb/gpu-frames-1113` 7285d72d5, tree c673d5285 (#950 bedroom wood on main), High. Frames: exploration_hud, menu_build, system__building.
- Batch: `yardstick_g_rescore_1113/`. Fit r 0.961, RMSE 0.28. Confirming. Calibrate warns that F38#10 is above the top anchor.

## What the judges see
- **F38#19:** compact gold and teal HUD (3/3 bar B yes). Four to six boxed elements remain: quest card, minimap, quick slots, verb row, "Get up" and vitals. The empty quick-slot boxes sit mid-right.
- **F38#10:** the Build tab is filled with three illustrated cards and a full-width button. A strip of dead space remains above the footer.
- **F38#34:**
  - The wall is half-timbered with diagonal braces, so it reads as a wall (FIXED 3/3).
  - It is still plain cream panels on a flat orange or rust slab and "looks too new" (3/3).
  - A foreground NPC is cropped at the bottom right of the frame (judges a and b).

## Next asks (LANE-SCENE)
1. **F38#10 (GPU lane):** capture menu_players and menu_quest_log, at High and Medium, and run a closing batch with the F38#38 control. Build alone already reads 7.75.
2. **F38#19:** hide the empty quick-slot boxes when nothing is bound, and fold "Get up" into the verb row. Fewer boxes is the ask; the row is 0.23 short. Scene.
3. **F38#34:** give the placed wall weathered plaster and timber, sat on the ground instead of on a flat slab. Re-frame the building capture so the NPC is not cropped. Scene, or new_art for the wall material.

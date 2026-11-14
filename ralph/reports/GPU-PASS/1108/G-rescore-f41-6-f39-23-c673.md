# G-rescore-f41-6-f39-23-c673: F41#6, F39#23 (and F41#3, one frame) on main (GPU High, one-sided)

| Row | Mapped | Per judge (a, b, c) | Raw | Board | Change | Defect (a / b / c) |
|---|---|---|---|---|---|---|
| **F39#23** catch chance HUD | **7.35** | 7.31, 7.19, 7.55 | 6.6, 6.5, 6.8 | 7.35 | level | FIXED / PARTIAL / FIXED |
| **F41#6** named-wild danger and opening | **6.79** | 6.95, 6.47, 6.95 | 6.3, 5.9, 6.3 | 6.83 | level | FIXED 3/3 (no magenta slab) |
| F41#3 actor spacing (1 of 3 job frames) | 6.99 | 7.07, 6.83, 7.07 | 6.4, 6.2, 6.4 | 7.06 | level | PARTIAL / PARTIAL / FIXED |

- **F41#6:** the recorded defect is fixed. The row is held by the camera and the boss finish, not by the cue.
- **F41#3:** only tell1-e-impact was captured; the job frames i01 and tell1-a-start are missing. Treat 6.99 as a partial read.

## Frames and batch
- Section: `tb/gpu-frames-1113` f97716638, tree c673d5285, High.
  - F41#6: capacitor_alpha tell1-d-strike and tell1-e-impact, hollows_alpha tell1-e-impact.
  - F39#23: catch_low, catch_high, 01-aiming-full-health.
- Batch: `yardstick_g_rescore_1113/`. Fit r 0.961, RMSE 0.28. Confirming.

## What the judges see
- **F41#6:**
  - 3/3: hollows_alpha impact (frame 3) has a large teal scaled body or trunk filling the right third to half of the frame. The judges read it as the camera inside geometry. The GPU lane notes it is the scene's tree trunk, not a capture fault. Either way it costs the row.
  - 3/3: the boss's glossy cream-and-gold armour blooms and "reads more like a toy than a believable animal".
- **F39#23:**
  - The percentage sits on a dark plate with large numerals, clear of the trainer.
  - 3/3: the grey translucent companion panel at the bottom left washes out over pale sand.
  - Judges a and b: the capture ring overlaps the lizard and the trainer.
- **F41#3:**
  - Judges a and b: the trainer stands right at Voltarach's claw tips.
  - Judge a: the HUD shows "it's open" and "staggered — punish now" at the same time.
  - Judge b: a white hit flash hides the ally's face.

## Next asks
1. **F41#6 (LANE-LAND-CS / LANE-SCENE):**
   - Add a fight-camera occlusion fade for trunks between the camera and the fighters, or move the hollows_alpha impact camera.
   - Lower the bloom and specular on Voltarach's armour so its form reads.
   
   Scene.
2. **F39#23 (LANE-SCENE):** give the companion status panel the same opaque deep blue-grey backing as the odds plate. This is the near-bar route; the row is at 7.35. Scene.
3. **F41#3 (LANE-SCENE):**
   - Set a minimum gap between the trainer and the boss's claw tips.
   - Show one opening cue, not two.
   - Capture i01 and tell1-a-start so the row is scored on all of its frames.

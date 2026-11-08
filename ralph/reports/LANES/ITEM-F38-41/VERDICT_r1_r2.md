# F38#41 Old Quarry boulders: Blender rounds (LANE-MS, 7 Nov 2026)

Frame: `catalogue_survey.gd --biome=meadows --times=day --subset=quarry` (stand `meadows__band2_stone_and_root__03__the_old_quarry__day`), CPU llvmpipe Compatibility 1280x720. Packet: `anchor_tiles.py` with the pinned anchors craft, f10_2_r3_capacitor and f04_6_r22. Three fresh code-blind judges, JUDGE_PROMPT verbatim, `calibrate.py`.

| Round | Arm | Raw base / cand | Mapped base -> cand | Fit |
|---|---|---|---|---|
| r1 (`qj_r1/`, seed 74107) | q41 r1: subdivided rocks with voronoi fracture displacement and Rock030 at 1.6 m per repeat | 5.7 5.9 5.9 / 6.3 5.4 5.7 | 6.70 -> 6.64 (flat, OFF) | r 0.91 |
| r2 (`qj_r2/`, seed 74219) | q41 r2: 7 bisect split planes, light grain, warm-graded Rock030 at 2.6 m per repeat | 5.2 5.6 5.8 / 5.6 6.2 6.2 | **6.43 -> 6.96 (+0.53), ON** | r 0.83, RMSE 0.65 |

- **r1, judges:** a busy blue-grey speckle on still-rounded silhouettes, with a cold cast.
- **r2, judges:** angular, faceted broken stone (defect moved PRESENT -> PARTIAL, 3/3).
- **Remaining asks:**
  - The speckle is still a little noisy and photographic at range.
  - It clashes with the pale old boulders and white blocks at mid-left (the band2 scatter or worked faces, still the old meshes).
  - No terraced cut face or rubble apron; oversized foreground planks.
  - They ask for one quarry stone family.

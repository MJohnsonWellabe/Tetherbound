# VIS-MEADOWS r1c: first CPU scores for the unscored F38 matrix rows (4 Nov 2026)

Capture: `capture_f38_matrix.gd --f38-preset=Low --f38-baseline --times=day`, CPU llvmpipe Compatibility 1280x720, source 80abd20e8. **Subset only:** 2 of the 22 plan sites (band1_lower_meadows_1 and band2_stone_and_root_0, clear and rain, 4 views each = 14 frames). The run was stopped early because CPU renders take about 4 min a frame, so the full ≥200-frame re-capture that F38#0 asks for needs the GPU rig. One-sided sets (the same frames on both sides), three fresh code-blind judges, anchor_tiles `--pairs 3 --seed 11043`, calibrate.py: linear slope 1.46, r 0.98, anchor RMSE 0.26.

| Item | CPU subset score | Judges |
|---|---|---|
| F38#0 biome re-scored at the look-dev bar | **6.16** | Sky and cool blue distance work. Against: flat card tree walls with no grove or clearing structure, a stretched path texture, the camera pressed into a boulder (band2 gameplay), the owl cropped at the frame edge. |
| F38#41 no magenta, placeholders, floating or clipping | **5.68** | No magenta rings or slabs anywhere (3/3). PARTIAL on placeholders, 3/3: in the old quarry reverse view, a dark flat slab on the path in the foreground, a faceted grey boulder that looks untextured, and an overexposed white primitive cylinder (a conduit lamp). |

The F38#41 slab is identified by `tests/probe_flat_slabs.gd --at=405,1797`: the old-quarry ruin's `Floor_UnevenBrick` floor tiles (`old_quarry.json foundations`, `quarry_foundation` prefab) sit at y -0.52 against terrain at about -0.48. Where the ground dips, a 2.7 m dark square shows through. Candidate fix: sink or ground-tint those floor tiles. The boulder is the `quarry_station` Rock_Medium kit.

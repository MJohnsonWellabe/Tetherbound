# VIS-TIDEWAKE look round 27: water night dim (CPU); flat, stays OFF

- Code (shipped, inert, a11146852): `water.gdshader` gains `night_dim` / `night_tint`, and `water_surface.gd` eases `night_dim` toward `surfaces.water.night_dim_max` while the day cycle is dark. With no `night_dim_max` set, the water does not process and renders exactly as before. Water tests pass (14 tests, 0 failed).
- Candidate: `ov_r27.json` (`surfaces.water.night_dim_max` 0.55, tint #4a6a98) vs r27b. The night water turns from electric blue to deep navy (visible).
- 3 code-blind judges, `anchor_tiles.py --seed 1120`: F39#30b candidate/base 5.0/5.1, 5.0/5.0, 5.6/5.6; F13#5 5.6/5.6, 5.6/5.6, 5.7/6.1. Never ahead, so flat or slightly worse; stays OFF.
- The judges did not flag a neon night shoreline this round on either side. Their night asks are now the pale, flat dune and hull shapes and the regular night current arcs.

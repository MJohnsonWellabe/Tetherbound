# Batch b2 — Cloudreach CPU pre-judge (25 Oct 2026, ~00:50 CT)

Renderer: Low, Compatibility, Mesa llvmpipe CPU, 1280x720; day clear, four matrix views per side. Yardstick: standard prompt verbatim (`judge_prompt_filled.txt`), `anchor_tiles.py --pairs 4 --include craft --seed 2511`, three fresh code-blind judges, `calibrate.py`. Fit: linear, slope 0.951, intercept 0.828, r 0.73, anchor RMSE 0.53, 8 anchor points, top anchor 7.35 (confirming batch); warning: some candidates extrapolated more than 0.5 outside the anchors' measured range. **CPU pre-judge only: GPU decides done.** CPU target for tier 1 = mapped 5.2 (GPU 6 minus the 0.8 gap).

| Item | Control (arm) | Candidate (arm) | Raw j1/j2/j3 cand.; control | Mapped control | Mapped candidate | Candidate defects (j1/j2/j3) |
|---|---|---|---|---|---|---|
| High Perches tidy + compass | CPU recapture stand 7 | `--cloudreach-high-perches-compass-candidate --cloudreach-f40-perches-tidy-candidate` | 6.0/5.8/5.9; 4.5/4.5/4.8 | 5.20 | **6.44** (+1.24) | blue bands FIXED x3; caption FIXED x3 |
| Cliffhold approach (C3 fallback, no flag) | CPU recapture stand 8 | matrix with the wall/arm check | 6.2/6.0/5.7; 5.4/5.0/4.9 | 5.68 | **6.50** (+0.82) | wall FIXED x3 |
| Old Wind Observatory stand (C3, no flag) | CPU recapture stand 9 (centre stand) | new stand (441, 4489) h -45 | 5.0/4.8/5.0; 3.7/3.2/3.8 | 4.22 | **5.52** (+1.30) | columns FIXED x3; planks/blue strips PARTIAL x3 |
| Windscar Beacon spire (C4, Meshy) | flag off | `--cloudreach-f40-beacon-spire-candidate` | 5.3/5.1/5.1; 4.7/4.6/4.5 | 5.20 | **5.74** (+0.54) | lone arch PARTIAL x3; lawn PRESENT x3 |
| Windscar Flight Aerie heading (+115) | old heading -115 (fallback) | heading +115 | 4.7/4.4/4.5; 4.5/4.2/4.5 | 5.01 | 5.14 (+0.13) | aerie PARTIAL x3; black wedge slabs on the slope (new note) |
| Stormward Overlook clean-up r1 | flag off | `--cloudreach-overlook-cleanup-candidate` | 4.4/4.0/4.5; 4.3/4.0/4.3 | 4.82 | 4.92 (+0.10) | cubes PARTIAL x3 (now tan, still floating cubes); strips PRESENT x3 |
| Haze + closer cloud deck r1, gate crag | CPU recapture stand 0 | `--cloudreach-f40-haze-candidate` | identical | 5.84 | 5.84 (0) | judges saw identical sides |
| Haze + closer cloud deck r1, sky shrine | CPU recapture stand 6 | same | identical | 5.52 | 5.52 (0) | identical |

Judges' shared asks: (1) replace the flat lawn foreground at every Cloudreach stand with stratified stone shelves, rock edges and grove clusters near the camera, with distance-graded haze (scene); (2) hero meshes for the overlook arch, beacon, aerie and observatory armillary (new art; the beacon spire already helps); (3) remove stray geometry: overlook cubes and strips, aerie black wedges, observatory blue strips and planks, the cliff-town cyan bedroll slab (scene). Evidence: key, recorded defects, filled prompt, per-judge Bar A, batch/mapped.

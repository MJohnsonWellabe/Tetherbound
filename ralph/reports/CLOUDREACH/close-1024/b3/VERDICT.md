# Batch b3 — Cloudreach CPU pre-judge (25 Oct 2026, ~03:10 CT)

Renderer: Low, Compatibility, Mesa llvmpipe CPU, 1280x720, day clear (F08#3: the settlement tool's 10-view day/night sheet). Yardstick: standard prompt verbatim (`judge_prompt_filled.txt`), `anchor_tiles.py --pairs 4 --include craft --seed 2612`, three fresh code-blind judges, `calibrate.py`. Fit: linear, slope 1.637, intercept -2.966, **r 0.97, anchor RMSE 0.27**, 8 anchor points, top anchor 7.35 (confirming batch), no warnings. **CPU pre-judge only: GPU decides done.**

| Item | Control | Candidate | Raw j1/j2/j3 cand.; control | Mapped control | Mapped candidate | Candidate defects (j1/j2/j3) |
|---|---|---|---|---|---|---|
| Realm Gate Crag island shell (C2, Meshy) | CPU recapture stand 0 | `--cloudreach-f40-gate-shell-candidate` | 6.1/5.6/6.3; 5.2/4.8/5.5 | 5.49 | **6.86** (+1.37) | brown slab FIXED x3; lawn PRESENT x3 |
| F08#3 settlements r18d | c18 (shipping) | `--cloudreach-settlement-r18-candidate` (r18d) | 6.1/5.8/6.4; 5.6/5.3/6.0 | 6.26 | **7.02** (+0.76) | foreground PARTIAL x3; moon-blue PARTIAL x3; rust road PARTIAL x3; windows PARTIAL x3 |
| Windscar Flight Aerie perch platforms (C4, installed Meshy) | heading +115, no platforms | `--cloudreach-f40-aerie-perch-candidate` | 5.4/5.3/5.7; 4.8/4.6/5.0 | 4.89 | **5.98** (+1.09) | launch structure PARTIAL/PARTIAL/FIXED; black wedge slabs PRESENT x3 |
| High Perches island shell (P2-023, Meshy) | flight pair, flag off | `--cloudreach-f40-island-shell-candidate` | 6.0/5.5/6.1; 5.6/5.0/5.8 | 5.98 | **6.64** (+0.66) | slabs/extruded edges PARTIAL x3 (sculpted far-arrival underside; the rim view still shows a straight smeared wall) |
| Stormward Overlook clean-up r2 | ovl-c1 (flag off) | r2 (no wings, no pavers, pale piers, no needle) | 5.0/5.3/5.4; 4.7/4.5/5.0 | 5.00 | 5.38 (+0.38) | cubes PARTIAL/FIXED/PARTIAL; strips FIXED/FIXED/PRESENT |
| Haze r2, gate road | CPU stand 0 | `--cloudreach-f40-haze-candidate` r2 | identical | 5.60 | 5.60 (0) | judges saw the sides as identical |
| Haze r2, sky shrine | CPU stand 6 | same | identical | 6.64 | 6.64 (0) | identical |

Gain rule: haze r1 0, r2 0: two rounds under +0.5, so the fog/haze-value approach stops; a clearly different approach (cloud-sea volumes placed in the midground, as the shrine's existing near cloud banks that judges praise) comes next. Overlook r1 +0.10, r2 +0.38 vs a fresh control: second round under +0.5; next is a clearly different approach (the flat banner cards, the compass ring hung from a tree and the bare lawn, judges' remaining asks).

Judges' shared asks: (1) break up the saturated flat lawn leading every Cloudreach frame with stone shelves, outcrops, level changes and grove edges near the camera, lower grass saturation; (2) midground cloud-sea volumes and aerial perspective; (3) remove the aerie's black wedge slabs, the arch's flat banner cards and hanging compass ring; (4) out of lane: Team Tether grunt face, the homestead wall anchor.

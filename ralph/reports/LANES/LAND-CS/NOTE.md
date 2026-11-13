# LANE-LAND-CS NOTE (branch `tb/land-cs`; world look in Cloudreach and Stormwood)

## State, 13 Nov 2026 about 16:50 UTC
- Branch cut from `origin/tb/coord-wrapup-1113` (c673d528); main did not contain #951 yet. I merge `origin/main` once it lands.
- No ship yet. One new arm pushed: LAND-CS-SOILOFF.

## Waiting on the GPU
| Arm | Rows | Status |
|---|---|---|
| LAND-CS-SOILOFF | F41#22, F41#24 (6.46); riders F41#5, F41#12, F41#2 | New. Cause confirmed by switch-off on CPU. Asks to take THINGS-STORMPOOL round 2's place. |
| BELOW6-OVERLOOK-JOIN, BELOW6-OVERLOOK-SOLID | F40#15 | Inherited, queued. |
| BELOW6-WALL-BAND, BELOW6-GATE-TERRACE | F40#1 | Inherited, queued. |
| THINGS-CLOUDNIGHT round 2 | F40#0, F40#19, F40#21 | Inherited, queued. |
| THINGS-WETPATH3 | F40#21 and paths | Inherited, not judged. |
| THINGS-STORMPOOL round 2 | F41#22, F41#24 | Inherited. Superseded by SOILOFF: withdraw it. |

The inherited arms already exceed two waiting, so I send nothing else until verdicts come back. Further arms are built to CPU-ready and held here.

## Findings
- **Stormwood black cut-outs and the Break slab are the `wet_soil` forest layer** (1,400 opaque near-black discs with a scissored rim), not the terrain pool zones. Switching the layer off removes them at forest and giant. Detail in `LAND-CS-SOILOFF/ARM.md`.
- **Cloudreach ground, named 3/3 across the matrix** (`G-rescore-f40-0-sample`): "uniform lawn with lone blades, blurry low-resolution path and plot splats, unblended path edges". The GPU frames show sparse tall dark blades standing alone on a flat lawn at the gate and the sky shrine. Not yet traced to a cause.

## Next
1. Cloudreach lone blades and flat lawn (F40#1, F40#7, the matrix rows): find what places the lone blades, confirm by switch-off, build one arm.
2. Stormwood F41#10 Glass Sink and F41#1 Stormheart after the ground verdict.

## Runbook additions
- First boot of a fresh container needs `godot --headless --path . --import` (about 20 minutes).
- `capture_stormwood_f10_matrix.gd --stands=forest,giant --phases=calm --no-aftermath` on CPU: about 10 minutes; Break frames add 1 to 8 minutes each.
- List-valued config (such as `forest_layers`) needs a by-name patch flag for overlays; `forest_layers_1113.layers.<name>` is that for Stormwood.

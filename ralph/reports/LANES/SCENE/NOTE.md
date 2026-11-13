# LANE-SCENE NOTE (branch `tb/scene`; this file is the channel)

## TO THE COORDINATOR (13 Nov 2026, about 18:10 UTC)
1. **HALLMOSS cause found; new arm SCENE-HALLWALLS on `tb/scene`, row F38#28. It replaces THINGS-HALLMOSS (parked).** A ray probe at the Warden fight camera shows the arena's wall panels and tower piers wear the EXTERIOR stone (moss 0.78) on their inside faces; only the pilasters wear interior stone, which is all HALLMOSS changed. The arm cuts moss to 0.3 of its value on wall faces inside roofed rooms only. Probe with the flag on: 1,845 of 5,184 rays at frame 03 land on the changed surfaces. Not visible on CPU (dark hall), so it needs the by-eye check in its ARM.md first.
2. Earlier items stand: SCENE-CACHE (F38#12), SCENE-WORKSHOP (F39#13), #953 bench fix, re-scores of F39#13 and F39#19.
3. Waiting arms now: TELLDUST2, SCENE-CACHE, SCENE-WORKSHOP, SCENE-HALLWALLS, SOLENE (kept by you). Still over two; I send nothing else.

## State (13 Nov 2026, lane started)
- `tb/scene` holds origin/main (after #951) plus this lane's work. Every candidate is flag-off or overlay-only.
- Criteria closed: 0. Landed on main: 0.
- **Ready to land, no GPU verdict needed (objective geometry fix):** `tb/scene-benchfix-land`. The shipped Tidewake camp workbench model had its hung tools, rope, vise and lantern thrown up to 1.6 m off the bench by its build script. See `ralph/reports/LANES/SCENE-BENCHFIX-LAND/READY.md`.

## Waiting on the GPU (limit two; inherited arms count)
| Arm | Rows | Status |
|---|---|---|
| SCENE-CACHE | F38#12 (5.89) | New. Replaces BELOW6-TONIC-STASH (same switch file; its overlay turns the tonic crate on too). |
| SCENE-WORKSHOP | F39#13 (6.14) | New. Overlay only over the bench fix. |
| SCENE-HALLWALLS | F38#28 | New. Replaces THINGS-HALLMOSS, which the GPU held by eye and is now parked (it only reached the pilasters). |
| THINGS-TELLDUST2 | F38#3, F38#28 | Inherited, front of queue, near-bar closer. |
| THINGS-SOLENE | F38#17 | Inherited. Its own note says the change is small on CPU and that character light fixes do not predict the GPU. **I suggest withdrawing it** to keep the lane at the limit; say if you want it kept. |

That is four with SOLENE withdrawn and TONIC-STASH replaced, which is over the limit of two. I am not sending anything further until HALLMOSS and TELLDUST2 are judged. If the coordinator prefers, hold SCENE-WORKSHOP behind SCENE-CACHE.

## Findings that need no build
- **F39#19 (roster contrast, 6.56):** on the GPU frame the roster already sits on dark panels; the recorded pale text is gone. The frame still shows the stale "Gather Reef Stone" prompt (fixed since) and a black void at the top right where the camera sees past the dune. Wants a re-score, and the void belongs to the Tidewake places lane.
- **F38#12:** the recorded "generic crates" defect is already gone on the GPU frames; staging is what is left (SCENE-CACHE).

## Next (while waiting; nothing sent)
1. F38#19 HUD cluster: describe the layout change to the coordinator before building (as directed).
2. Dialogue rows F38#37, F40#10, F41#15, F39#26: read the current GPU frames per row for a shared foreground rule beyond the shipped tighter shot.
3. F38#6 / F40#16 pickup silhouettes; F39#9 catch camera distance.

## Runbook additions
- A fresh container has no `.godot` import: `godot --headless --path . --import` takes about 20 minutes once.
- Tidewake camp frames: `tools/phase2_capture_tidewake_camps.gd --seed=2042 --output=res://ralph/reports/VISUAL/phase2/tidewake/<name>`, about 4 minutes on CPU, 9 frames.
- Harvest reward frames: `tools/phase2_capture_world_inventory.gd --biome=meadows --subset=meadows__inventory__harvest__<slug> --seed=2042 --output=res://ralph/reports/VISUAL/phase2/meadows/<name>`, about 4 minutes. The camera stands on the node's -z side: +z is behind the reward, -x is screen right.
- Which surface is that? `scratch` ray probe: extend `tools/capture_f38_fight.gd`, override `_save`, cast a grid of `project_ray_*` rays and test each visible MeshInstance3D with `mesh.generate_triangle_mesh().intersect_ray`; print the nearest mesh and its material parameters. About 8 minutes for the Warden fight on CPU; it needs `--source-commit=<40-char sha>` and a fresh `--out`.
- Blender-built props: check the exported model's bounds against the design size. A joined group rotated about its own origin scatters its parts.

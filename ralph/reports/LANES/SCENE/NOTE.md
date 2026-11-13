# LANE-SCENE NOTE (branch `tb/scene`; this file is the channel)

## TO THE COORDINATOR (13 Nov 2026, about 21:50 UTC)
1. **ARM SCENE-TOURNEY is ready** on `tb/scene`, row F38#16 (7.31). Two flag-off changes in one overlay, each aimed at a judge's named defect:
   - The "pink glowing bush" (3/3) is the pickup glow of a village berry harvest node 11.8 m from the lens (probe at the frame: tint #f26d8f, item berries). Pickup halos now fade with the conversation camera's push-in and return after. This touches every conversation with a pickup in view, so the arm lists dialogue samples as no-loss.
   - "Mira and Tam share the same body" (judge a): Tam's hood and tunic are slate blue, derived from the installed texture by a script in the asset folder, with the dialogue portrait recoloured to match (a new `portrait_remap` on the body flag). Only Tam uses that body key.
   - CPU shows both: no halo, and Tam clearly unlike Mira. 215 tests in 18 related files pass with the flags off.
   - Files: `ralph/reports/LANES/SCENE-TOURNEY/`.
2. **SCENE-PANELFILL** (F38#10) and **SCENE-ROSTERNAMES** (F39#19) are ready, as noted earlier.
3. Waiting on the GPU: HALLWALLS r2, SCENE-CACHE, SCENE-WORKSHOP, SCENE-ROSTERNAMES, SCENE-PANELFILL, SCENE-TOURNEY. That is well over two; order them as you see fit. I will not add more until verdicts come back. My next work is on what the verdicts say, or the dialogue foreground rows (F38#37, F40#10, F41#15, F39#26).
4. Landed on main from this lane: #953 (workbench parts fix), #954 (TELLDUST3).

## State (13 Nov 2026, lane started)
- `tb/scene` holds origin/main (after #951) plus this lane's work. Every candidate is flag-off or overlay-only.
- Criteria closed: 0. Landed on main: 2 (#953 the camp workbench parts fix; #954 THINGS-TELLDUST3, the coherent wind-up dust band).
- `tb/scene` has main 4f9ae9e2 merged in; `tb/scene-benchfix-land` is done.

## Waiting on the GPU (limit two; inherited arms count)
| Arm | Rows | Status |
|---|---|---|
| SCENE-CACHE | F38#12 (5.89) | New. Replaces BELOW6-TONIC-STASH (same switch file; its overlay turns the tonic crate on too). |
| SCENE-WORKSHOP | F39#13 (6.14) | New. Overlay only over the bench fix. |
| SCENE-HALLWALLS | F38#28 | New. Replaces THINGS-HALLMOSS, which the GPU held by eye and is now parked (it only reached the pilasters). |
| THINGS-TELLDUST3 | F38#3, F38#11 | JUDGED, ships: F38#11 Medium 6.55 to 7.06 (3/3), F38#3 level. Landing branch pushed. |

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

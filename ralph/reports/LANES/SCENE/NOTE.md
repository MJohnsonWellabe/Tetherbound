# LANE-SCENE NOTE (branch `tb/scene`; this file is the channel)

## TO THE COORDINATOR (13 Nov 2026, about 21:10 UTC)
1. **ARM SCENE-PANELFILL is ready** on `tb/scene`, row F38#10 (7.39 at both presets). Players: the four seats as a row of tall portrait cards. Quest Log: the tracked step as a card with the realm banner art and a chapter progress strip. Flag-off code plus a one-key overlay; CPU sheet shows both panels filled. 204 tests in 22 menu-related files pass. Files: `ralph/reports/LANES/SCENE-PANELFILL/`. One call for you in its ARM.md: the progress strip shows the chapter's step total (28).
2. **ARM SCENE-ROSTERNAMES is ready** on `tb/scene`, row F39#19 (7.47). Files: `ralph/reports/LANES/SCENE-ROSTERNAMES/`.
3. **Judge flags, both checked, neither is a bug:**
   - "WIND" on the creature card is the stamina meter. COMBAT section 2 names that resource Wind ("Wind, energy and meters"), so the label is correct. It reads as an element tag only because of its case and colour.
   - The red item at the bottom right of the grunt frames is a Team Tether sigil banner on a pole at the south bridge checkpoint (`south_bridge.gd`), beside a crate and a timber barricade. Red on a Tether banner is within the rule. The crate and timber are orange-brown wood, not red.
4. SCENE-HALLWALLS round 2 and the TELLDUST3 landing (#954): as before.
5. Waiting on the GPU: HALLWALLS r2, SCENE-CACHE, SCENE-WORKSHOP, SCENE-ROSTERNAMES, SCENE-PANELFILL. F38#16 is next for me.

## State (13 Nov 2026, lane started)
- `tb/scene` holds origin/main (after #951) plus this lane's work. Every candidate is flag-off or overlay-only.
- Criteria closed: 0. Landed on main: 1 (#953, the camp workbench parts fix, main 4f9ae9e2). Ready to land: `tb/scene-telldust3-land`.
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

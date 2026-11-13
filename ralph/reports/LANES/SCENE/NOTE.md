# LANE-SCENE NOTE (branch `tb/scene`; this file is the channel)

## TO THE COORDINATOR (13 Nov 2026, about 23:15 UTC)
0. **Now working on F39#21 (Venn win camera, 5.84).** Two CPU win captures are running: main as is, and main with `opponent_trainer_stand_1112` off. The suspect is `6719ab86`, which moved Venn behind Cannonback inside the 10 Nov to #951 window; the win and aftermath cameras frame the trainer. A probe logs the lens pose and the ground under and ahead of it. The 9 Nov lens ground clearance is ON but only checks straight down, so a dune face rising ahead of a low lens is not caught. I reply with the cause and a landing branch.
1. ROSTERNAMES r2: noted that the camera shift was a capture artefact. The round-2 footprint code stays in (flag-off): it makes the arm's camera identical to base by construction, which suits matched-camera judging. The solid rows are the substance: no reveal restart, out of the subject fade, white names; CPU solid through the t-012 stagger.
2. F38#16: noted LANE-BEINGS has the faces. SCENE-TOURNEY is the berry-glow fade and Tam's outfit colour only, so it does not overlap.
3. F38#28: TELLDUST3 parked for this row. SCENE-CURB is the floor-arc swing. The Warden dust "heart ribbon" is next in the same arm once CURB has a by-eye result.
4. Ready and waiting: ROSTERNAMES r2, SCENE-CURB, SCENE-PANELFILL, SCENE-TOURNEY, SCENE-CACHE, SCENE-WORKSHOP.

## Earlier (23:00 UTC)
1. **ROSTERNAMES round 2 is on `tb/scene`** (same flag, same overlay). Both causes found in code and fixed:
   - Camera: the fight camera reads HUD control rects through `fight_occupied_controls` and `camera.json hud_dynamic_controls`. The roster now reports a footprint at the old 232 px width on both paths. CPU: scenery pixel-identical to base in t-000 to t-008.
   - Ghost rows, three causes: grey benched names; `set_pinned` called every frame restarting the reveal tween at alpha 0; and the HUD subject fade dimming the roster where the wider strip overlaps a fighter. Now: white names, no restart, and the named roster stays out of the subject fade. CPU: solid in t-003, t-008, t-010 and the t-012 stagger.
   - Details: its ARM.md, "Round 2".
2. **New ARM SCENE-CURB (F38#28)**, the new approach after HALLWALLS parked. A low stone curb with a brass inlay replaces the glowing teal ring, in the Warden arena only. Same radius and rules. CPU (brightened) shows it reading as an authored edge. Files: `ralph/reports/LANES/SCENE-CURB/`.
3. **Aldis's red banner is not a bug:** Aldis is the Team Tether Warden of the occupied stronghold (WORLD: "Team Tether recedes" after his defeat). Red is within the rule there.
4. **F39#20 (6.42):** the recorded defect is FIXED 3/3. The frames still carry the stale "Gather Reef Stone" prompt (fixed by #947) and the dark cliff wedge (LANE-LAND-MT). Needs a re-score, not a build.
5. **F38#35 (6.33):** the role postures do apply (no mismatch warning on Halda, Lark or Oskar), but at about 40 px tall a 4-38 degree offset cannot read. A 1.8x gain barely registered on CPU, so I reverted it rather than queue a weak arm. The row needs authored role poses (hands on hips, folded arms): animation work, not a scene setting.
6. Ready and waiting (your queue order): ROSTERNAMES r2, SCENE-CURB, SCENE-PANELFILL, SCENE-TOURNEY, SCENE-CACHE, SCENE-WORKSHOP.

## State (13 Nov 2026, lane started)
- `tb/scene` holds origin/main (after #951) plus this lane's work. Every candidate is flag-off or overlay-only.
- Criteria closed: 0. Landed on main: 2 (#953 the camp workbench parts fix; #954 THINGS-TELLDUST3, the coherent wind-up dust band).
- `tb/scene` has main 4f9ae9e2 merged in; `tb/scene-benchfix-land` is done.

## Waiting on the GPU (limit two; inherited arms count)
| Arm | Rows | Status |
|---|---|---|
| SCENE-CACHE | F38#12 (5.89) | New. Replaces BELOW6-TONIC-STASH (same switch file; its overlay turns the tonic crate on too). |
| SCENE-WORKSHOP | F39#13 (6.14) | New. Overlay only over the bench fix. |
| SCENE-HALLWALLS | F38#28 | PARKED after two rounds: r2 judged level (0/3, all ties). Replaced by SCENE-CURB. |
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

# LANE-SCENE NOTE (branch `tb/scene`; this file is the channel)

## HANDOFF (wrap-up, 14 Nov 2026)

### State
- Branch `tb/scene`. The head is in the coordinator reply (origin/main merged in). All unlanded arms are flag-off in code and overlay-only.
- From this lane on main: #953 camp workbench parts fix; #954 THINGS-TELLDUST3 (coherent wind-up dust band); #964 F39#21 lens ground clearance (tests the hit length, not the full `spring_length`). The F39#21 re-score is queued.
- Criteria closed: 0.

### Open candidates (all on `tb/scene`; each folder `ralph/reports/LANES/<ARM>/` has ARM.md, CAPTURE.json, overlay.json and a by-eye line)
| Arm | Row | Flag | Status | Next step |
|---|---|---|---|---|
| SCENE-FLEECARD | F41#16 (6.37) | `hud.json flee_card_1114` | CPU checked at 1080p (sheet in folder); queued first | GPU High on Hollows `99-after`; no-loss `i12` and F41#21 win |
| SCENE-ROSTERNAMES r2 | F39#19 | `combat_roster_visual.json compact_names_1113` | CPU solid; waiting on GPU | GPU judge, cameras matched |
| SCENE-CURB | F38#28 (6.81) | `combat.json arena.boundary_curb_1113` | CPU (brightened); waiting | GPU Warden 03/05/08; F38#3 grunt must be identical |
| SCENE-PANELFILL | menu rows | `menu.json panel_fill_1113` | CPU; waiting | GPU judge |
| SCENE-TOURNEY | F38 berry glow in conversations | `pickup_glow.json conversation_fade_1113` | CPU; waiting (glow only) | GPU judge |
| SCENE-CACHE | F38#12 (5.89) | `harvest_stash_support.json cache_dressing_enabled` | CPU; waiting | GPU judge |
| SCENE-WORKSHOP | F39#13 (6.14) | overlay swaps in `camp_workbench_r3.glb` | CPU; waiting | GPU judge |
| SCENE-ROLEPOSES | F38#35 (6.33) | `npc_postures.json role_poses_1114` | Pose bench only; NOT in-world verified | See its ARM.md: capture with `phase2_capture_characters.gd`, keep `npc_post_stances.json` off |

Held: F38#16 Tam outfit (`character_body_flags.json scene_tam_outfit_1113`), pending the BEINGS-TAM-COAT verdict.

### What worked
- Confirming the cause on the judged GPU frames before building. FLEECARD: the "loss" frame is really a flee. F39#21: the lens was tested at the wrong length.
- Probe subclasses of the capture tools (camera pose, ray hits) for camera and occlusion causes.
- Pure static functions for anything a headless test cannot read (MultiMesh placement, curb transforms, card text).
- A scratch xvfb pose bench, which builds NPCs from real art keys with trial profiles and downscales the result to 40 px. On this rig, arm Z sets abduction (− raises the left arm), arm Y twists, forearm −X flexes, and Y twist plus flex brings the hand across the body. Halda's shirt is skinned to her arms, so raised-elbow poses flare it.

### What failed (also in "Tried and failed" below)
- F38#28: wall moss (HALLMOSS, HALLWALLS r1 and r2) and TELLDUST3 for the Warden fight: level.
- F39#19 ROSTERNAMES r1: translucent rows faded (−0.40).
- F38#35: a 1.8x gain on the old role angles did not register.
- F38#12: Kenney props were off-style.

### Runbook
- Fresh container: `godot --headless --path . --import` (about 20 min), then `texture_import_policy.py --apply`. Exclude `.uid` files in `.git/info/exclude`.
- Tests: `godot --headless --path . --script tests/run_tests.gd -- --only=a.gd,b.gd`. Nodes need not be in the tree; `Engine.get_main_loop()` is null in the runner.
- CPU captures: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1920x1080 --fixed-fps 20 --script res://tools/<tool>.gd -- ...`. Run one Godot process at a time with a fresh output dir.
- Overlays: a deep-merge script over `data/config` (keys are repo paths). Commit config first, apply, capture, then `git checkout -- data/config`. Never edit config while a capture runs.
- `capture_named_fights_f10_6.gd --seconds=3 --interval=10` reaches `99-after` in about 10 min on CPU; `--seconds=12 --interval=4` is past 20 min.
- Character frames (`*__inventory__character__*`) come from `phase2_capture_characters.gd` and `phase2_character_plan.json`, not the world-inventory tool.
- GPU frames: `origin/tb/gpu-frames-1113` `gpu-frames-1108/<row>/...`; verdicts on `tb/judge` `ralph/reports/GPU-PASS/1108/`.
- `send_message` to the coordinator was once refused (trusted-device check); NOTE.md is the fallback channel.
- No harness fixes are pending for TECHNICAL §8.1.


## TO THE COORDINATOR (14 Nov 2026, 03:10 UTC; send_message to your session was refused for a trusted-device check, so this file is the channel)
1. **New arm SCENE-FLEECARD (F41#16, 6.37)** on `tb/scene` d4ffeaa03, folder `ralph/reports/LANES/SCENE-FLEECARD/`.
   - Cause, confirmed on the judged GPU frames: the Hollows "loss" frame is a flee. The level-42 party never loses inside the capture window (i12 is mid-fight, 5/5 healthy), and the tool ends the fight with `resolve("fled")`. The shipped `loss_card` handles only `lost`, so judges see one small default-size "You backed off." over the spider, with "Put Sparkit away" under it.
   - Arm: `hud.json flee_card_1114` (flag-off; the overlay turns it on). The flee becomes a framed catch-card-family result card in the upper third, with a 44 px "YOU BACKED OFF / Sparkit got clear. Regroup and try again." and a soft teal edge, no red. The recall line stands down while it holds. Test: `tests/test_flee_card_flag.gd`. CPU sheet in the folder.
   - By-eye: Hollows 99-after at High shows the framed card and no tiny line over the spider. No-loss frames: i12 and F41#21 hollows_win 99-after, both identical.
   - Queue: this is over the limit of two. I suggest it take the place of CACHE or WORKSHOP in the front two.
   - If you would rather judge the row on a real loss: the job's "party 42, idle" setup does not lose inside the window. On a real loss, the shipped `loss_card` draws and this arm is neutral.
2. Next here: F38#35 authored villager role poses.

## Earlier (14 Nov 2026)
1. **LAND F39#21 correctness fix: `tb/scene-lensground-land` c783b7ad3**, cut from main 94fe423d.
   - The grey plane is the dune face seen from a lens resting 0.35 m above it.
   - The 9 Nov lens ground clearance tested the lens at the full `spring_length`. When the arm's own collision had already pulled the camera in against the dune, that point was underground, its downward ray found nothing, and the arm was left alone. Fix: start from `min(spring_length, get_hit_length())`.
   - In-world probe at the Venn end-of-fight spot with the bad heading and a 19 m arm: the old code puts the lens at (356.26, 7.37, 3813.72), 0.35 m up, which matches the bad run; fixed, 1.03 m up.
   - The new pin test fails on the old code. Camera-rig tests: 217, 0 failed.
   - Why after 10 Nov: the heading the fight ends at decides whether the dune cuts the arm. On CPU (one run each, fights drift) the opposing-trainer stand ON ended facing the dune and OFF along the beach. The clearance was the failing part either way.
   - READY: `ralph/reports/LANES/SCENE-LENSGROUND-LAND/READY.md`. A one-sided F39#21 re-score after it lands gives the number.
2. **SCENE-TOURNEY split as asked:** its overlay is now the berry-glow fade only. Tam's outfit flag stays OFF in code and out of every overlay; it returns only if BEINGS-TAM-COAT loses.
3. Ready and waiting: ROSTERNAMES r2, SCENE-CURB, SCENE-PANELFILL, SCENE-TOURNEY, SCENE-CACHE, SCENE-WORKSHOP, and now SCENE-FLEECARD.

## Earlier (13 Nov, 23:15 UTC)
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

## Tried and failed (for the coordinator's index)
- F38#28 PARKED: interior stone moss 0.46 to 0.22 (THINGS-HALLMOSS). It only reached the pilasters; the GPU by-eye check held it.
- F38#28 PARKED: roofed-room wall moss and buttress clip (SCENE-HALLWALLS r1 and r2). r2 judged level, 0/3, all ties; the change is invisible at sheet size.
- F38#28 PARKED: TELLDUST3 for the Warden fight. Level with cameras matched (High 7.27 = 7.27); it stays shipped for F38#11 and the grunt.
- F39#19 PARKED: ROSTERNAMES round 1 (names on translucent rows). The re-judge lost 6.78 to 6.38 (0/3); the named roster faded. Round 2 fixes the fade and is queued.
- F38#35 PARKED: 1.8x gain on the existing role-posture angles. It barely registered on CPU on 40 px villagers; the row needs authored poses.
- F38#12 PARKED: Kenney log, bedroll and fire pit as cache props (CPU only, never judged). Salmon-pink and off-style; replaced inside SCENE-CACHE.
- F38#16 HELD: Tam outfit recolour (`scene_tam_outfit_1113`). It overlaps BEINGS-TAM-COAT; held until that verdict.

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

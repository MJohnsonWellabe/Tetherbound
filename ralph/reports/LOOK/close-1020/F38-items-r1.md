# F38 Meadows item round 1 (close-1020): P2-051 Mira counter, P2-094 placed wall

- **Renderer:** Godot 4.7-stable, Compatibility, OpenGL3 on Mesa llvmpipe under xvfb (CPU-only), 1920x1080, Low. CPU-provisional rule: three-judge Bar A mean ≥ 6.7 counts as met until a GPU pass confirms 7.5.
- **Source:** `tb/look` at ccd205799 (+ origin/main 504357cb7 merged). Arms differ only in the item's flag.
- **P2-051 capture:** `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script res://tools/visual_judge/capture_camera_set.gd -- --set=res://tools/visual_judge/camera_sets/P2-051-mira-counter.json --out=<dir>`. There are three fixed views inside Mira's shop. The old phase2 character stand now frames the cottage from outside, so the item has its own camera set. X uses `shop_counter.meshy_counter.enabled` false, Y true: the Meshy counter, plus kit crate and apple barrel in place of the flat stock boxes, with the slab and box colliders unchanged.
- **P2-094 capture:** `... --script res://tools/phase2_capture_build_systems.gd -- --biome=meadows --output=<dir>` (the catalog's own `meadows__system__building` fixture). X uses `build_wall_interior.json meshy_wall.enabled` false, Y true: the Meshy homestead wall fitted to the kit wall bounds, with grid, collider, cost and save unchanged.
- **Judging:** three fresh code-blind subagents. They saw one shuffled A/B sheet (`_sheet-F38-items-r1.png`; key `F38-items-r1-key.json`), the key art and `palworld-05`, and each item's catalog defect text. Each judge scored every row and gave a PRESENT/FIXED call per side.

| Item | Arm | Judge 1 | Judge 2 | Judge 3 | Mean | Defect (Y) |
|---|---|---|---|---|---|---|
| P2-051 counter (3 views) | X before | 4.43 | 4.53 | 4.47 | 4.48 | |
| | Y after | 7.13 | 6.90 | 6.50 | **6.84** | FIXED ×3 |
| P2-094 wall (1 view) | X before | 4.8 | 4.6 | 3.9 | 4.43 | |
| | Y after | 6.0 | 5.6 | 5.2 | **5.60** | FIXED ×2, PRESENT ×1 |

**P2-051: PASS, CPU-provisional** (6.84 ≥ 6.7, defect fixed by all three judges). The flag is turned ON on `tb/look`. Remaining notes: the foreground crate crowds the side view, the back shelf behind Mira is bare, and the counter reads slightly low. P2-051 (impact 4) is not in F38 #1 or #2; this closes the catalog row only.
- Checks with it ON: `smoke_village_services_redesign` PASS (Mira prompt day/night). `smoke_village_trade` FAILS identically with the flag OFF ("shop has no light", "Mira is standing outside her own shop"), so the failure predates this change and does not come from it.

**P2-094: not passed** (5.60). All three judges name the blown-out near-white infill as the remaining defect. Next round tones the infill to a warm plaster value. It stays OFF.

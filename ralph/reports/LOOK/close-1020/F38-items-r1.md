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

## P2-094 rounds 2–3 (same baseline X, same capture command; two rows: the fixture frame and a 2.5× crop of it)

| Round | Change | Judge 1 | Judge 2 | Judge 3 | After mean | Before mean | Defect (after) |
|---|---|---|---|---|---|---|---|
| r2 | warm infill tint (#c9b48f) | 6.15 | 6.20 | 6.10 | **6.15** | 3.6 | FIXED ×3 |
| r3 | darker tint (#b8a17a), plus an inset kit-plaster backing that closes the open brace bay | 6.25 | 6.20 | 6.75 | **6.40** | 3.6 | FIXED ×3 |
| r4 | weathered multiply (#a68e6c), warmer backing, oak plank coping cap (overhang across the thickness only, so neighbouring walls' bounds are unchanged) | 6.90 | 6.90 | 6.40 | **6.73** | 3.5 | FIXED ×3 |

r3 gained +0.25, the first round under 0.5. The candidate stays OFF.

What the judges still name:
- The infill is bright and flat.
- The timber is uniform new orange.
- There is no top cap, so the panel looks card-thin.
- The footing is pale and merges with the plaster.

Next is a clearly different round: an oak plank coping cap, a darker weathered timber/footing tint and grass blend at the base. Keys: `F38-P2-094-r2-key.json`, `F38-P2-094-r3-key.json`.

**P2-094: PASS, CPU-provisional** (r4 6.73 ≥ 6.7; per-judge means over both rows 6.90/6.90/6.40, all three FIXED). The flag is turned ON on `tb/look`. `smoke_free_build` PASSES with the flag ON (real d-pad/A placement). Sheet `_sheet-F38-P2-094-r4.png`, key `F38-P2-094-r4-key.json`. Remaining judge notes: the infill still lacks weathering, and the base has no ground blend. A GPU pass must confirm 7.5.

Review fix (21 Oct): the hero meshes, backing and coping cap are marked `presentation_only`, and `BuildPiece` leaves them out of the collider AABB. The placed-wall StaticBody is identical with the flag OFF and ON: box `(2.0, 3.124785, 0.406482)` at `(0, 1.560297, -0.110794)`. With the flag ON, `smoke_free_build`, `smoke_build_piece_material_lifetime` and `smoke_build_direct_routes` pass. `smoke_build_menu_footprint` fails the same way without this change (panel 25.8% of the screen, covering the centre); that is the build-menu UI, which this branch does not touch.

## F38 Meadows ledger (rows touching meadows; impact order)

| Row | Impact | Class | Subject | Owner | In #1 top-20 | State |
|---|---|---|---|---|---|---|
| P2-015 | 100 | animation | creature collapse and rest | Look (Meadows) | yes | not started (catalog needs_capture) |
| P2-016 | 100 | animation | creature hurt and movement poses | Look (Meadows) | yes | not started (catalog needs_capture) |
| P2-062 | 100 | camera | fight camera and creature scale | Look (Meadows) | yes | not started (catalog blocked) |
| P2-002 | 80 | ui | map | Stormwood lane (shared UI) | yes | not started (catalog open) |
| P2-017 | 80 | mesh | normal creature scale | Look (Meadows) | yes | not started (catalog needs_capture) |
| P2-033 | 80 | mesh | ground pickup identity | Look (Meadows) | yes | not started (catalog open) |
| P2-058 | 64 | ui | catch aim readability | Stormwood lane (shared UI) | yes | not started (catalog open) |
| P2-119 | 64 | animation | Fly carrier grip pose | Look (Meadows) | yes | not started (catalog open) |
| P2-001 | 60 | ui | menu shell | Stormwood lane (shared UI) | yes | not started (catalog open) |
| P2-007 | 60 | ui | secondary menu panels | Stormwood lane (shared UI) | yes | not started (catalog open) |
| P2-055 | 60 | mesh | named character silhouettes | Look (Meadows) | yes | not started (catalog candidate_off) |
| P2-063 | 60 | animation | shared fight tell and hit effects | Fights lane | yes | not started (catalog open) |
| P2-087 | 48 | camera | named trainer dialogue subject visibility | Look (Meadows) | yes | not started (catalog needs_capture) |
| P2-095 | 48 | ui | craft recipe text | Stormwood lane (shared UI) | yes | catalog: fixed |
| P2-034 | 48 | scene | harvest reward identity | Look (Meadows) | yes | not started (catalog open) |
| P2-059 | 48 | camera | catch sequence camera framing | Look (Meadows) | yes | not started (catalog blocked) |
| P2-060 | 48 | material | catch effect finish | Look (Meadows) | yes | not started (catalog open) |
| P2-086 | 48 | camera | tournament dialogue subject identity | Look (Meadows) | yes | not started (catalog needs_capture) |
| P2-069 | 48 | animation | flight and landing pose read | Look (Meadows) | yes | not started (catalog deferred) |
| P2-004 | 45 | ui | exploration HUD | Stormwood lane (shared UI) | yes | not started (catalog open) |
| P2-003 | 40 | scene | Team Tether stronghold | Look (Meadows) |  | not started (catalog open) |
| P2-013 | 36 | scene | Tether Relay yard | Look (Meadows) |  | not started (catalog open) |
| P2-014 | 36 | mesh | distant mountains | Look (Meadows) |  | candidate r1 FAIL (defect present; ~+0.3) |
| P2-018 | 36 | material | shiny palette distinction | Look (Meadows) |  | not started (catalog open) |
| P2-020 | 36 | scene | creature ground contact | Look (Meadows) |  | not started (catalog open) |
| P2-031 | 36 | ui | settings and binding instructions | Stormwood lane (shared UI) |  | not started (catalog open) |
| P2-064 | 36 | scene | Warden arena boundary | Look (Meadows) |  | not started (catalog open) |
| P2-065 | 36 | animation | trainer defeated presentation | Look (Meadows) |  | not started (catalog open) |
| P2-005 | 36 | scene | ground cover | Look (Meadows) |  | not started (catalog open) |
| P2-006 | 36 | scene | mill and settlements | Look (Meadows) |  | not started (catalog open) |
| P2-012 | 32 | scene | Burrow Warrens hillside | Look (Meadows) |  | not started (catalog open) |
| P2-061 | 27 | ui | catch result hierarchy | Stormwood lane (shared UI) |  | not started (catalog open) |
| P2-019 | 27 | scene | alpha rarity read | Look (Meadows) |  | not started (catalog open) |
| P2-035 | 27 | scene | camp and workshop prop legibility | Look (Meadows) |  | not started (catalog needs_capture) |
| P2-094 | 27 | mesh | placed wall visual | Look (Meadows) |  | PASSED 6.73 (CPU-prov, ON) |
| P2-079 | 24 | camera | Meadows dialogue rock obstruction | Look (Meadows) |  | not started (catalog needs_capture) |
| P2-096 | 24 | ui | craft action hint contrast | Stormwood lane (shared UI) |  | catalog: fixed |
| P2-050 | 24 | animation | human post poses | Look (Meadows) |  | not started (catalog needs_capture) |
| P2-078 | 24 | camera | dialogue speaker occlusion | Look (Meadows) |  | not started (catalog needs_capture) |

F38#1 (top-20): 1/20 passed (catalog-fixed or code-blind PASS); F38#2 (other impact>12): 2/19 passed. P2-051 (impact 4) is a catalog-only pass.

P2-014 r1 (FarRanges sharpness 1.6→1.15, octaves 6→4, tree_line 0.28→0.18, rock #6a7384): walk_02 5.2→5.9, route_day about equal, defect PRESENT ×3 (keys F38-P2-014-r1-key.json). OFF. Next is a different approach: layered ridges with aerial fade, or the Meshy backdrop.

## P2-033 / P2-034 round 1 (Meshy pickup and harvest visuals; `meshy_item_visuals.json`)

Capture: `... --script res://tools/phase2_capture_world_inventory.gd -- --biome=meadows --times=day --subset=<11 catalog sightings>`. X has the flag OFF and Y has it ON (11/11 frames each). Three code-blind judges, shuffled (`F38-P2-033-034-r1-key.json`). Means per row:

| Row | X | Y | |
|---|---|---|---|
| pickup good_candy | 3.60 | 3.70 | both still a glow blob |
| pickup great_candy | 4.03 | 4.17 | |
| pickup rare_candy | 3.80 | 5.40 | Meshy better |
| pickup potion_small | 4.70 | 5.03 | |
| harvest travel_pack | 4.70 | 5.90 | Meshy better |
| harvest orb_basic | 5.53 | 5.57 | |
| harvest attack_tonic | 5.93 | 5.93 | not swapped |
| harvest berries | 6.07 | 4.87 | Meshy worse (muddy basket) |
| harvest hide boots/helm/leggings | 5.83/5.23/5.50 | 4.10 ×3 | Meshy worse (one bedroll for all three) |

No row passes. r2 drops the berry and hide swaps (the originals read better), scales the remaining Meshy items about 1.5×, and cuts the Meshy candy halo to 0.45×, as all three judges asked.

## P2-014 round 2 (clearly different approach: three depth layers, non-ridged far faces)

Candidate: `meadows_horizon.json` with non-ridged FarRanges (bluer rock and forest) and a new MidRanges layer at 1570 m. Judged on the route frame plus two horizon crops; key `F38-P2-014-r2-key.json`.

| | Judge 1 | Judge 2 | Judge 3 | Mean | Defect |
|---|---|---|---|---|---|
| X original | 4.57 | 4.33 | 4.50 | 4.47 | PRESENT ×3 |
| Y r2 | 6.00 | 5.97 | 6.33 | **6.10** | FIXED ×3 |

The judged gain is +1.63, with the defect fixed in every row. It is not passed yet (6.10 < 6.7). For r3 all three judges ask for:
- taller, varied crests with one snow-capped hero peak;
- a darker, more saturated mid layer for aerial depth;
- removal of a darker horizontal band at the base.

## P2-033 / P2-034 round 2 (Meshy items scaled about 1.5×, halo 0.45×; berry and hide swaps dropped)

Same capture, 6 sightings plus a close crop of each (12 rows per arm). X has the flag OFF and Y has it ON. Three code-blind judges, shuffled (`F38-P2-033-034-r2-key.json`). Means per item (wide view / crop):

| Item | X | Y | Y defect | |
|---|---|---|---|---|
| pickup rare_candy | 3.40 / 3.67 | **6.63 / 7.17** | FIXED ×3 | item mean 6.90 |
| harvest travel_pack | 4.77 / 5.13 | **6.47 / 6.93** | FIXED ×3 | item mean 6.70 |
| harvest orb_basic | 5.60 / 5.90 | 6.47 / 6.80 | FIXED ×3 | item mean 6.63 |
| pickup potion_small | 4.20 / 4.87 | 4.90 / 5.90 | mixed | |
| pickup great_candy | 3.73 / 3.97 | 4.60 / 4.93 | PRESENT ×3 | |
| pickup good_candy | 3.37 / 3.53 | 4.13 / 4.40 | PRESENT ×3 | |

Y beats X in every row for every judge. Row means: P2-034 (harvest) X 5.35, Y **6.67**; P2-033 (pickups) X 3.84, Y **5.33**. Neither row passes (both under 6.7). The flag stays OFF.

The rare candy and travel pack pass as single items. What the judges still name:
- good and great candy read as a cabbage and a blue tarp under the glow; they need the rare candy's wrapped-sweet form in their own colours;
- the potion is too small for its frame.

r3: Meshy wrapped-sweet good and great candies requested from the coordinator, the potion scaled up, the orb basket kept.

## P2-014 round 3 (taller crests, a snow-capped hero peak, darker mid layer)

Route frame plus two horizon crops; three code-blind judges, shuffled (`F38-P2-014-r3-key.json`).

| | Judge 1 | Judge 2 | Judge 3 | Mean |
|---|---|---|---|---|
| X original | 5.83 | 5.80 | 5.63 | 5.76 |
| Y r3 | 5.87 | 5.80 | 5.83 | **5.83** |

There is no gain over r2 (6.10), so this is the first flat round. The enlarged hero peak reads as a smooth white board, and the tall far crests repeat like cut-outs, with a pale seam at their base.

All three judges ask for:
- a forested green/blue-green foothill layer between the meadow and the ranges, with stronger aerial-perspective steps (+0.5–0.6);
- rock and snow breakup on the hero peak (+0.5–0.6);
- an irregular silhouette rhythm and no vertical streaks (+0.4–0.5).

r4 goes back to the r2 ranges and adds those.

## P2-012 round 2 (larger non-uniform hill-shell fit)

Failed on sight, not judged. In walk_03 the hidden bank leaves the warren chamber roof floating in the open, because the shell no longer covers it. Next: fit the shell to the bank's own bounds and keep the bank cap where the shell leaves a gap.

## P2-014 round 4 (r3 ranges plus a forested foothill band, secondary peaks, ragged snow line, rock strata, smooth colour variation)

Code: optional `horizon_ranges.gd` layer keys `extra_heroes`, `snow_breakup`, `strata`, `smooth_variation` (inert when absent). Fresh control X4 (current main config) and candidate Y4, captured on the same three frames; rows are the route frame, two horizon crops and the warrens walk. Key `F38-P2-014-r4-key.json`; decoded scores in `F38-P2-014-r4-judges.json`.

| | Judge 1 | Judge 2 | Judge 3 | Mean |
|---|---|---|---|---|
| X control | 5.85 | 5.13 | 5.30 | 5.42 |
| Y r4 | 6.05 | 5.45 | 5.68 | **5.73** |

Y wins the crops and the warrens view, with the defect FIXED ×3. All three judges preferred the control on the route frame, whose single tall peak dominates; r4's hero is broader and lower. Gain over the best (r2 6.10): none. That makes two flat rounds (r3, r4).

What all three judges still name:
- one dominant, sharp snow-capped summit with dark rock faces under crisp snow (+0.4–0.7);
- the vertical streaking on the faces, which comes from long thin ring triangles (+0.4–0.5);
- a brighter, more saturated sky with cumulus (+0.3–0.6).

Next is a clearly different approach: a Meshy hero summit mesh (sculpted rock/snow, sharp apex) set into the far ring at the hero bearing, and denser ring rows to cut the streaks. Under the owner rule this CPU evidence cannot park the item.

## P2-033 round 3 (Meshy single wrapped sweets for good/great candy, fitted by length; potion 0.85 m)

Fresh control X3 and candidate Y3 on the four pickup sightings, each as the gameplay frame plus a crop centred on the item (8 rows). Three code-blind judges, shuffled (`F38-P2-033-r3-key.json`, decoded in `F38-P2-033-r3-judges.json`).

| | Judge 1 | Judge 2 | Judge 3 | Mean |
|---|---|---|---|---|
| X control | 4.31 | 4.50 | 4.21 | 4.34 |
| Y r3 | 6.29 | 6.65 | 6.28 | **6.40** |

Per item (Y, frame/crop): good candy 6.13/6.93, great candy 5.67/6.27, potion 5.87/6.87, rare candy 6.37/7.13. The gain over r2 (5.33) is +1.07; the row is not met (6.40 < 6.7). The flag stays OFF.

All three judges name:
- the items are too small to identify in the wide frames (×1.3–1.5, +0.5–0.8);
- there is no contact shadow, so the candies float on the grass (+0.5);
- the potion keeps a green halo;
- the great candy reads as an egg or ball rather than a wrapped sweet (+0.6 on its rows).

r4: every item scaled up (good 1.1 m, great 1.15 m long; potion 1.1 m; rare 0.9 m), a soft unshaded contact shadow under each (`shadow_m`), the potion halo cut to 0.45×, and the great candy turned broadside like the good candy.

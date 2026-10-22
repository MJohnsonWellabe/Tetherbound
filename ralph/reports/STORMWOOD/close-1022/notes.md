# Stormwood lane, close plan from 22 Oct 2026 (F41#1–#3, #5; F10#2; F22#4 Stormwood)

## RESUME (22 Oct, about 22:05 CT; lane stopped by the coordinator to save usage)
State: no criterion closed. Every candidate is OFF on tb/stormwood and in the land branches. Landed or ready: tb/stormwood-land 6230fcc20 (signpost draw distance plus the inert ground_light_exposure / wet_gloss hooks; in PR #712) and tb/stormwood-land2 90c5e311a (test_stormwood_scar_relief float(null) fix).

| Row | Best mapped (round) | r12 mapped | Control mapped | Bar (CPU-provisional 6.7, GPU 7.5) |
|---|---|---|---|---|
| F41#3 Calm matrix | 6.36 (r11) | 5.57 | 2.63 / 3.78 | open |
| F41#3 Break matrix | 6.01 (r11) | 5.35 | 2.38 / 4.02 | open |
| F41#3 aftermath matrix | 6.52 (r11) | 5.59 | 2.94 / 3.86 | open |
| F10#2 capacitor fight | 5.75 (r11) | 5.51 | 3.35 / 4.36 | open (GPU reopened) |
| F10#2 glass_field fight | 6.11 (r11) | 5.57 | 3.55 / 4.33 | open (GPU reopened) |
| F41#1/#2/#5, F22#4 Stormwood | not judged separately; #5 defects tracked in the matrix sets | | | open |

r12 raw scores equal r11's; the mapped drop is mostly the anchor draw (r12 fit r 0.73, RMSE 0.70). Gain rule: r12 = round 1 under +0.5.

Best candidate: `candidate-config.patch` (r12 snapshot, commit ac36c4d7b). To restore:
1. `git apply --exclude='data/scatter/*' ralph/reports/STORMWOOD/close-1022/candidate-config.patch`
2. `godot --headless --path . --script scripts/world/bake_stormwood_scatter.gd` (required after vegetation config edits, or vegetation fails closed)
3. Optionally set `charger_lunge.lane_charged.enabled` true in combat.json. That is the Fights-owned lane restyle; hand it to Fights rather than landing it from here.

It holds the close-1020 r10 look plus the grade lift:
- look rig exposure 1.35, saturation 1.1, ambient #aab0bc, bluer horizon/fog #6f7a9c;
- surge: Calm haze 0.0026, aftermath 0.0016, `ground_light_exposure` 0.45;
- ground: `wet_gloss` roughness 0.55 / specular 0.2 (black pools), moss tints #b8a882, forest floor #a89a78, damp #85836f, rock #857f70, grass cards 0.85, wet soil #1e2420/#2a312b;
- bark #a8977a; Meshy giant tree/scarred trunk `Material_0` retint #d8c8ae;
- Stormheart hero 380 m, shape 0.95/1.0/1.05.

Measured luma: shipping about 30–38; candidate about 75–78 (Calm 78, Break about 56; a Break bolt frame goes 40 -> 61).

Don't redo:
- Meshy trees in `near_lens_fade` / `line_of_sight_fade`: about 3x render cost, measured alone.
- A second directional light per bolt: Compatibility draws an extra pass per light. Use exposure instead.
- Run one Godot at a time. Kill with `ps -eo pid,args | grep "[g]odot --path"`; `pgrep -f "^/root/godot-bin"` misses it.

Judges' top asks, in order (r11 and r12, three judges each):
1. Near-camera trunk or root at the forest and reverse stands (exploration camera; the fade route is too costly, so either reframe the fixed stands with the coordinator's agreement or clear scatter near those seats).
2. Lightning that lights trunks and ground in Break stills: the exposure pulse works but bolts are rarely lit at capture, so time Break captures to a lit bolt (the matrix tool's `_await_sky_bolt` mostly times out).
3. Light shafts and layered blue-violet fog for depth.
4. A readable glass-field strike scar.
5. Tiled moss: decals and clearings.
6. Squat Stormheart: new art, see the MESHY line in TO COORDINATOR.
7. Magenta strike disc and lane ring, white-puff impacts (Fights).
8. HUD about 40% of a fight frame (UI).
9. Pilot and boar no taller than the trainer (creatures; the owner's 22 Oct creature-style direction applies).

Next steps when resumed:
1. Merge origin/main and re-judge with the corrected JUDGE_PROMPT (creature style, merged at f1ce3d91a). Use a fixed anchor set (`--include`) so rounds compare.
2. Take a clearly different approach (composition and hero content: glass scar, Stormheart v3, stand occluders, lit-bolt Break captures), not more grade.
3. When a row maps 6.7 or above on CPU, land it (configs ON in a land branch from origin/main with the updated pinned tests: test_stormwood_surge_presentation, test_stormwood_vegetation_palette, test_vegetation_shared_retint, plus the scatter rebake) and queue GPU confirmation.

## TO COORDINATOR
- 22 Oct 23:55 CT TO COORDINATOR: FINAL READY tb/stormwood-final bb981ae8 (head now carries a .uid commit on top; use the branch head). Built from origin/main a4f8a6b7. Checks: 12 focused test files, 98 tests, 1389 assertions, 0 failed (signpost, scar relief, vegetation palette, surge presentation, charger lunge, stormwood look, voltcap, stormheart presentation, glass field identity, shared retint, scatter bake, named fight clearings).
  - ON: the signpost draw distance (bug fix, 24 m + 4 m fade). That is the only behaviour change.
  - OFF (included as code or config behind flags or zero values): stormwood_look, stormwood_voltcap_finish, glass_field scar_relief_candidate and shard_finish, destination_dressing fallen_giant, stormheart meshy_hero, surge telegraph soft_style, sky_lightning.ground_light_exposure 0, the wet_gloss hook (no key), charger_lunge.lane_charged (Fights-owned file).
  - Why everything stays OFF: your request to turn judged-better candidates ON relays an owner direction I could not verify from this session. My tooling refused to write it into shipped config as an owner decision, and my lane brief says candidates stay OFF until they pass. The flip is one reviewed step: restore the Meshy assets from tb/stormwood (assets/props/meshy-1020/{giant_tree_a,giant_tree_b,relay_pylon,scar_crust,scarred_trunk,storm_fungi,stormheart_tree_v2,ground_wet_moss_floor,ground_dark_root_bark} and assets/environment/stylized_nature/derived/Bark_TwistedTree_lift175.png), then `git apply --exclude='data/scatter/*' ralph/reports/STORMWOOD/close-1022/candidate-config.patch`, rebake Stormwood scatter, and update the pinned tests named in RESUME.
  - Scores for that candidate (mapped Bar A, CPU): r11 Calm 6.36 / Break 6.01 / aftermath 6.52 / capacitor 5.75 / glass_field 6.11, against control 2.63 / 2.38 / 2.94 / 3.35 / 3.55. r12: 5.57 / 5.35 / 5.59 / 5.51 / 5.57 against 3.78 / 4.02 / 3.86 / 4.36 / 4.33. It beats shipping by about 2–3.7 but is below 6.7 and 7.5.
  - Not included (size rule): the Meshy GLBs and textures (about 124 MB), because no committed config points at them, only the candidate patch.
- 22 Oct 21:20 CT READY tb/stormwood-land2 90c5e311a test_stormwood_scar_relief no longer aborts on float(null): an unset uniform reads as the shader's declared default (from the shader or its #include; headless reports no defaults). Same strictness; all assertions run (2 tests, 14 assertions, 0 failed, no script errors). Built from origin/main.
- 22 Oct 20:55 CT READY tb/stormwood-land 6230fcc20 Signpost text draw distance (masters.json `sign_presentation.visible_range_m` 24 m + 4 m fade; focused test fails without it). It also adds two inert Stormwood hooks, both off: `sky_lightning.ground_light_exposure` 0, and the `wet_gloss` shader hook with no key, so defaults are unchanged. Built from origin/main 2e7dd84b1. Checks: test_master_sign_visible_range + test_stormwood_surge_presentation 53/0. No Fights-owned file and no Forward+ grade work.
- 22 Oct 20:55 CT Ownership note: before your 13:49 relay I committed a flag-off `charger_lunge.lane_charged` charged-lane fill on tb/stormwood (scripts/combat/lunge_lane.gd, combat.json `charger_lunge.lane_charged`, commits fb44d0ea9/f90f2a3ca/74b89974b). Those are Fights files, so they are not in the land branch and I won't touch them again. Fights may take or drop them. The r11/r12 judges read it as reduced but still pink.
- 22 Oct 20:55 CT MESHY docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png crop (8,80)-(614,682). Target: Stormheart v3 hero silhouette about 380 m tall, height:width about 1.6:1. Purpose: all three r11/r12 judges call the distant Stormheart squat; keep v2's V-split glowing cleft, navy banners only (no red). Used beyond swap_radius 75 m; stays flag-off until judged. Details in "Art ask" below.
- 22 Oct 20:55 CT QUESTION r12's anchor draw fitted poorly (r 0.73, RMSE 0.70, top anchor 6.73, not confirming). Raw candidate scores matched r11 (Calm 5.90 vs 5.93) but mapped 0.8 lower, and the control mapped 1.2 higher. Should a lane fix its anchor set across rounds (`--include`) so round-to-round gain is comparable?
- 22 Oct 20:55 CT Status: F41#3 matrix and F10#2 fights are not closed. Best mapped (r11): Calm 6.36, Break 6.01, aftermath 6.52, capacitor 5.75, glass_field 6.11. r12 counts as round 1 under +0.5. Out of lane (repeated by all r12 judges): the fight HUD covers about 40% of the frame (UI); the pilot Sparkit and the boar anchor stand no taller than the 1.80 m trainer (creatures, hard rule); the magenta strike disc and lane ring (Fights).

Renderer for every capture here: Godot 4.7 Compatibility (opengl3), Mesa llvmpipe, CPU, 1280x720, Xvfb. Shipping renderer default, iteration only; GPU confirmation goes through the coordinator.

Messaging: `send_message` to the coordinator session is refused from this session ("elevated_session_untrusted_device"). Reports to the coordinator are kept in the "To the coordinator" section below on the pushed branch until a channel works.

## Worklist (GPU-PASS/F10-2/VERDICT.md asks)
1. Darkness and grade (every preset mean luma about 29/255). In progress.
2. Flat magenta lane slabs: the six Stormwood named rows' `cue_lane_solid` lanes (fill 0.6, F10#2 C3). Candidate `charger_lunge.lane_charged` (OFF).
3. Floating NPC text over the enemy panel (Capacitor): Master signpost Label3D had no draw distance. Fixed with a focused test.
4. No impact VFX: `vfx.json hit_spark` is OFF by owner decision (2026-10-04); per-move impacts come from move_library. Not changed.
5. HUD covers the trainer; clone herds behind Crown; pilot no taller than the trainer: routed (below).
6. Forward+ saturation drain: waiting on GPU-PASS/forward-plus-grade.

## Grade candidate (not judged)
Candidate = close-1020 r10 patch (look rig ON etc.) plus:
- look rig: exposure 0.82 -> 1.35, adjustment_saturation 0.94 -> 1.1, ambient_colour #a4a8c4 -> #aab0bc (less lavender; bark went pink);
- ground finish: wet-soil pools #141716/#1d211f -> #1e2420/#2a312b (were a black void); moss terrain tints #9aae98 -> #b8a882, forest floor #8c9f8c -> #a89a78 (the Meshy moss albedo is teal; warm tint pulls it to moss), damp #a8b2ac -> #85836f (read as pale slabs);
- bark tint #a39a86 -> #a8977a (vegetation config; rebaked).
Snapshot: `candidate-config.patch` (config only; apply, then rebake Stormwood scatter).

Measured (luma over the play area, HUD bands excluded; 0–255):

| Capture | Mean luma | Floor band | Saturation |
|---|---|---|---|
| GPU shipping fights (GPU-PASS, Low) | 28.9 | 22.7 | 0.49 |
| CPU r10 candidate, forest Calm | 39.1 | 34.4 | 0.41 |
| CPU g2 Calm matrix (5 stands) | 77.6 | 70.0 | 0.37 |
| CPU g3 glass_field fight (7 interval frames) | 77.7 | 68.2 | 0.29 |
| CPU g3 capacitor fight (7 interval frames) | 78.0 | 61.1 | 0.27 |
| Reference boards (Stormheart a/b, Palworld) | 114–131 | — | 0.37–0.46 |

## Round r11 (22 Oct, about 16:30 CT), first round on the yardstick
- Candidate: grade candidate above plus `charger_lunge.lane_charged` ON. Control: tb/stormwood e4d7bd176 (origin/main 2e7dd84b1 merged), every candidate OFF.
- Captures: CPU llvmpipe Compatibility 1280x720. Matrix `capture_stormwood_f10_matrix.gd --phases=calm,break` plus aftermath, with the close-1020 custom stands (8 stands x Calm/Break/aftermath, 24 frames per arm). Fights `capture_named_fights_f10_6.gd --ids=glass_field_alpha,capacitor_alpha --seconds=14 --interval=2.0 --camera-view=north --fixture-seed=1042206 --fixed-fps 20`. Six frames per fight: i00, i03, i06, tell1-c, tell1-e, tell2-d.
- Measured luma (play area): matrix control 38.1 vs candidate 74.9; fights control 29.6 vs candidate 75.8.
- Batch: `anchor_tiles.py --pairs 3` (anchors f36_0_npc C5, craft, f36_0_gap C5) plus five A/B candidate sets. Three fresh code-blind judges ran on JUDGE_PROMPT v1 verbatim. Files: `r11/` (spec, sets.md, key, recorded defects, batch, mapped, `_sheet_r11.png`).
- Fit: linear, slope 1.53, intercept -2.73, r 0.977, anchor RMSE 0.21; confirming batch (top anchor 7.35).

| Set | Control raw (j1/j2/j3) | Control mapped | Candidate raw | Candidate mapped |
|---|---|---|---|---|
| F41#3 Calm matrix | 3.5/3.8/3.2 | 2.63 | 6.2/6.0/5.6 | **6.36** |
| F41#3 Break matrix | 3.6/3.4/3.0 | 2.38 | 6.0/5.9/5.2 | **6.01** |
| F41#3 aftermath matrix | 3.8/3.7/3.6 | 2.94 | 6.3/6.2/5.6 | **6.52** |
| F10#2 capacitor_alpha | 4.4/3.9/3.6 | 3.35 | 5.9/5.5/5.2 | **5.75** |
| F10#2 glass_field_alpha | 4.4/4.1/3.8 | 3.55 | 6.0/5.8/5.5 | **6.11** |

- Below 7.5 on every row: nothing closes. This is the first mapped round, the baseline for the gain rule (best mapped: matrix 6.30 mean of the three phases, fights 5.93).
- Bar B: no from all three judges on every set.
- Defects fixed on the candidate (all three judges): murk; Break forest crushed; arena brown; flat magenta strike disc in Break (not seen on either side).
- Defects partial: magenta lane telegraph (still reads pink/violet); impacts (small white flash); camera in canopy at frame edges; repeating moss tile; Stormheart squat.
- Defects still present: near-camera occluders (forest-stand trunk; reverse-stand pale-blue root filling the left third); glass-field scar not readable; Break lightning lights the sky but not trunks or ground; flat lavender sky with no fog layering or depth; floating "You backed off" combat text over the enemy; the HUD covers about 40% of the fight frame and the pilot is tiny.
- Judges' top changes: (scene) make lightning light trunks and ground, add layered blue-violet distance fog and rim light, break up the ground tile with decals and clearings, clear lens occluders; (scene) real lightning/crack telegraphs and spark impact bursts; (new_art) a towering, board-scale Stormheart.

## Round r12 candidate (r11 judges' asks)
- Break bolts light the world: new `sky_lightning.ground_light_exposure` (committed 0 = off; candidate 0.45). Each decorative sky bolt lifts the frame exposure on the bolt's own onset; no added flash onsets; reduced motion scales it.
- Depth and fog: storm horizon and fog bluer (#777292 -> #6f7a9c, aftermath #766e97 -> #6e789c, look rig fog/horizon to match); Calm haze 0.0018 -> 0.0026, aftermath 0.0008 -> 0.0016. The Stormheart silhouette stays fog-exempt.
- Black pools: the wet-soil patches mirrored the lilac sky (roughness 0.28 / specular 0.38; a diagnostic tint ruled out the terrain slots). New `stormwood_ground_finish.json wet_gloss` hook (committed with no key, so behaviour is unchanged); candidate roughness 0.55, specular 0.2. The pools now read black and wet.
- Lens occluders: tried adding the Meshy giant trees and scarred trunk to `near_lens_fade` and `line_of_sight_fade`. The reverse-stand root stopped filling the lens, but the dither on whole giant-tree meshes made every frame about 10x slower on llvmpipe (measured: forest Break 98 s without it versus more than 10 min with it). Dropped; the occluder stays open.
- Also dropped: a first version of the bolt light used the StormFlash directional light per bolt; Compatibility draws an extra light as another pass over all geometry. It now lifts exposure instead (`ground_light_exposure`, candidate 0.45).
- Tile breakup: moss grass-card density 0.55 -> 0.85; rock slot tint #aaaab3 -> #857f70.
- Meshy giant trees and scarred trunk retinted warm (`Material_0` #d8c8ae): they read teal-blue.
- Stormheart hero: height 320 -> 380 m, shape 1.27/1.0/1.5 -> 0.95/1.0/1.05 (judges: squat).

## Art ask (for the coordinator's Meshy run): Stormheart v3
Judges r11 (two of three, new_art): "a towering, board-scale Stormheart (split trunk, platforms, banners); the current one is squat". Reference: `docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png`, crop (8,80)-(614,682) (exterior view: colossal split trunk with a glowing blue lightning cleft, wooden platforms and walkways, navy banners (no red), green crown, waterfall cliff base). Target: about 380 m tall with a height:width of about 1.6:1 (v2 is about 1:1). Read as a single silhouette from 300+ m. Used only beyond `swap_radius_m` 75 m (the procedural shell carries everything near), so scale against the 1.80 m trainer is via the shell. Keep the identity of the existing v2 (V-split with a glowing cleft). Flag stays off until judged.

## Round r12 (22 Oct, about 20:40 CT)
- Candidate r12 = r11 plus the r12 changes listed above, but without the Meshy near-lens fade (dropped; measured alone it is about 3x slower to render: forest Break 345 s vs 125 s) and with the bolt light as exposure. Control: the r11 control frames, reused (unchanged rendering path).
- Measured luma: matrix 77.6 (r11 74.9). One bolt frame: forest Break 40 -> 61.
- Batch: fresh anchor draw (f36_0_gap C1, f36_0_npc C9, p2_094_r4) and three fresh judges. Fit: r 0.727, slope 0.79, RMSE 0.70, top anchor 6.73, not confirming.

| Set | Control raw | Control mapped | Candidate raw | Candidate mapped |
|---|---|---|---|---|
| Calm matrix | 3.3/3.6/4.0 | 3.78 | 5.4/6.3/6.0 | 5.57 |
| Break matrix | 3.6/4.0/4.2 | 4.02 | 5.3/5.8/5.8 | 5.35 |
| aftermath matrix | 3.4/3.9/3.9 | 3.86 | 5.5/6.3/6.0 | 5.59 |
| capacitor fight | 4.3/4.2/4.6 | 4.36 | 5.6/6.0/5.9 | 5.51 |
| glass_field fight | 4.2/4.3/4.5 | 4.33 | 5.6/6.2/5.9 | 5.57 |

- Reading: raw candidate scores equal r11's, and the candidate-over-control gap is about 2.0 (r11 about 2.4). The r12 changes gained nothing visible to the judges: bolts were rarely lit at the capture instant, and the black pools and bluer fog went unremarked. Mapped, r12 is below r11. Gain rule: round 1 under +0.5.
- Still named by all three judges: near-camera trunk/root (forest, reverse); squat Stormheart; glass-field scar not readable; tiled moss; no light shafts or layered fog; magenta strike disc (heart_near Break) and the lane ring; tiny pilot and heavy HUD; impact effects are white puffs.
- Next (a clearly different approach, per the gain rule): composition and hero content rather than grade. Glass-field scar dressing, the Stormheart v3 Meshy ask, and Break captures timed to a lit bolt.

## To the coordinator (earlier, superseded by TO COORDINATOR above)
- Signpost fix (ON, with test) is in f90f2a3ca: `masters.json sign_presentation.visible_range_m` 24 m + 4 m fade; `tests/test_master_sign_visible_range.gd` fails without it. It touches every realm's Master signpost. Ready to land with the next batch.
- Out of lane: (a) the fight pilot (Lv 42 Sparkit fixture) renders about trainer height; GPU judges say "pilot no taller than the 1.80 m trainer" (hard rule, creatures lane). (b) The HUD bottom band covers roughly 45% of a 1280x720 fight frame (UI lane). (c) Crown clone herds come from hollow_crown wild cluster tables (encounter data); not changed without a ruling.

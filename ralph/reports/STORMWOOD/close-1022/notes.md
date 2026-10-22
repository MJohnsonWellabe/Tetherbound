# Stormwood lane, close plan from 22 Oct 2026 (F41#1–#3, #5; F10#2; F22#4 Stormwood)

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

## To the coordinator
- Signpost fix (ON, with test) is in f90f2a3ca: `masters.json sign_presentation.visible_range_m` 24 m + 4 m fade; `tests/test_master_sign_visible_range.gd` fails without it. It touches every realm's Master signpost. Ready to land with the next batch.
- Out of lane: (a) the fight pilot (Lv 42 Sparkit fixture) renders about trainer height; GPU judges say "pilot no taller than the 1.80 m trainer" (hard rule, creatures lane). (b) The HUD bottom band covers roughly 45% of a 1280x720 fight frame (UI lane). (c) Crown clone herds come from hollow_crown wild cluster tables (encounter data); not changed without a ruling.

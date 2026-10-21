# UI lane close run (tb/ui), from 21 Oct 2026

Rows: P2-002, P2-001, P2-007, P2-095, P2-004, P2-031, P2-088, P2-061, P2-032, P2-096.
Rule (coordinator): three code-blind judges on matched before/after frames call the defect FIXED and the after mean is 6.7+ (CPU-provisional, Mesa llvmpipe, Low/Compatibility, xvfb). Shared UI code: one judged set counts for every biome listing the row when it holds frames from each listed biome, or the screen is identical across biomes (stated per row).

Earlier "done" rows (P2-002, P2-007, P2-095, P2-096, P2-088, P2-032) had single-judge verdicts without the three-judge score; they are re-judged here.

## Ledger

| Row | Status | Biomes | Before mean | After mean | Judges | Proof |
|---|---|---|---|---|---|---|

## Rounds

### Blocker correction: catch capture never entered combat (P2-061 proof)
- Criterion: P2-061 catch result hierarchy (F38–F41 #2) needs matched catch verdict frames.
- Failure (reproduced 21 Oct, Meadows): `tools/phase2_capture_catch.gd` pressed the actionable "Engage Bramblebun" offer for 17 minutes and combat never started.
- Cause: the tool adopts the starter but never adds it to the party; with `combat.json` actor_vitals on, a wild fight refuses an unowned fighter. `tests/smoke_controller_catching.gd` already does that ownership step.
- Alternatives checked: `capture_catch_sequence.gd` uses the same adopt path; no other catch capture covers the verdict frames.
- Correction: the same three-line party-add step in `_ensure_ally()`. Next proof: catch before/after runs on Meadows.

### Round 1 (21 Oct ~12:20 CT), Meadows, CPU llvmpipe Low, tb/ui c78f05f22..(+hud_lean, catch_card, controls r7), flags on locally for the after side
Tool: `tools/phase2_capture_ui.gd --biome=meadows --tabs=backpack,creatures,map,quest_log,build,players,save,settings --map-zoom-samples --paired-720 --hud-settle-frames=240`; three code-blind judges, per-row A/B shuffled (keys in r1/).
| Row | Before mean | After mean | After defect verdicts (9–12 judge-rows) | Result |
|---|---|---|---|---|
| P2-001 menu shell | 5.37 | 5.73 | 12 PARTIAL | not passed |
| P2-007 Quests/Build/Players | 5.39 | 5.53 | 5 PRESENT, 3 PARTIAL, 1 FIXED (Build) | not passed |
| P2-031 controls | 5.16 | 5.70 | 8 PARTIAL, 1 PRESENT | not passed |
| P2-002 map (Meadows) | 4.33 | 5.03 | 12 PARTIAL | not passed |
Judges' shared asks: painted region band behind the menu title; pale/teal border instead of lime; real glyphs in a larger footer; no clipped headings (Creatures detail, Build); Quests/Players designed fill; binding cells as glyphs, label the Default column; map terrain across the whole canvas with soft fog edges, region label off the markers in the UI font. Art requested from the coordinator (four region bands).

### Coordinator-reported UI smokes (21 Oct ~13:20 CT)
1. `tests/smoke_build_menu_footprint.gd` — reproduced on main state: crafting category (23 pieces) drew 10 columns x 2 rows, panel 995x537 = 25.8% and over the screen centre. Fix (`scripts/ui/build_menu.gd`): 8 columns, one visible row, `follow_focus` on the grid scroll. Rerun: PASS, 18.1%, centre clear (widest panel 803x468). `tests/smoke_build_menu_pad_pick.gd` PASS. No assertion changed.
2. `tests/smoke_free_build.gd` — did NOT reproduce here: full headless run on tb/ui (build_menu fix applied, configs at committed values) passed end to end in about 14 min ("free build smoke test passed", exit 0), including the "'tent' was armed out of an empty satchel" step and the following pause/settings return. A reported 1700 s hang with no failure line points to load contention (CPU lane running a render beside it) or the 25.8% panel state; no code change made for it.

### Round 2 (21 Oct ~14:20 CT), four regions, gamepad glyphs (`--gamepad`), CPU llvmpipe Low; tb/ui ~f1b5… with region band art; flags on locally for the after side
| Row | Before mean | After mean (j1/j2/j3) | Verdicts on after | Result |
|---|---|---|---|---|
| P2-001 shell (Meadows ×2, Tidewake, Cloudreach, Stormwood, 720p) | 5.79 | 6.98 (7.23/7.12/6.58) | PARTIAL 18/18 | not passed (needs FIXED) |
| P2-007 Quests/Build/Players | 6.11 | 6.78 (7.00/6.87/6.47) | PARTIAL 8, FIXED 1 (Build) | not passed |
| P2-031 controls + quick bindings | 5.44 | 7.03 (7.13/7.20/6.77) | PARTIAL 9/9 | not passed |
| P2-002 map (4 regions) | 5.00 | 6.19 (6.24/6.56/5.78) | PARTIAL 15/15 | not passed |
| P2-032 map active region (Tidewake, Cloudreach, Stormwood) | — | defect FIXED on both sides 9/9 | — | defect already fixed in main; waits on the map screen mean ≥6.7 |
Gain vs round 1: shell +1.25, panels +1.25, controls +1.33, map +1.16. Judges' round-3 asks: carry region tint into the body and make the tracked quest a hero card; legible Day label on band art; larger LB/RB; Players seat cards with silhouettes and a quieter port notice; controls cells as glyphs, primary-contrast row labels, no repeated "Default"; map terrain readable edge to edge, label pill off markers, Tidewake land/sea chart.

### READY P2-095 and P2-096 (21 Oct ~14:45 CT)
- Screen: the production CraftPanel, identical shared code and layout in every realm (craft_panel.gd + craft_presentation.json; no per-biome branch), so one set captured in Stormwood stands for meadows, cloudreach and stormwood, per the coordinator ruling.
- Proof: `xvfb-run ... godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/phase2_capture_build_systems.gd -- --biome=stormwood --seed=2042`, CPU llvmpipe Low/Compatibility. After = main config (readable_recipe_rows, readable_action_hints, glyph_hints true, already shipped); before = those three false locally, same seed and stand. Sheet: craft/_sheet_craft.png (1080 and 720 rows, A/B shuffled; key in craft/).
- Three code-blind judges: after 7.4/7.3, 7.4/7.3, 7.4/7.3 → mean 7.35 (before 4.83). D1 clipping FIXED 6/6, D2 hint contrast FIXED 6/6.
- ROW P2-095 PASS (biomes meadows, cloudreach, stormwood) 7.35 CPU-provisional, judges 3/3 FIXED.
- ROW P2-096 PASS (biomes meadows, cloudreach, stormwood) 7.35 CPU-provisional, judges 3/3 FIXED.
- No code change needed: the fix is already on main with its flags on. Judges' follow-ups (not blocking): taller-than-needed recipe cards (three visible), keyboard glyphs in this keyboard-mode capture, dim description text.

## RESUME (owner pause 21 Oct ~15:05Z: visual work stops until the GPU remote starts)
State at pause: all captures killed, every candidate OFF in committed config. Round-3 code is on tb/ui but was never captured. The capture recipe lives in this note: `tools/phase2_capture_ui.gd --biome=<meadows|water|cloudreach|stormwood> --gamepad --tabs=... --map-zoom-samples --paired-720 --hud-settle-frames=240`, and the after side switches on the flags listed per row below.

| Row (biomes) | Best CPU after mean / verdict | Candidate (all OFF) | Exact next step |
|---|---|---|---|
| P2-095 craft recipe text (meadows, cloudreach, stormwood) | 7.35, FIXED 3/3 — PASS, landed as verdict | already on main | GPU confirmation pass of the same CraftPanel frames (≥7.5) |
| P2-096 craft hint contrast (same) | 7.35, FIXED 3/3 — PASS, landed as verdict | already on main | GPU confirmation pass |
| P2-001 menu shell (4 biomes) | 6.98 r2, PARTIAL | menu.json `shell_scenic` enabled + `border_colour #5fb8b0, header_band, band_art, band_alpha 0.34, glyph_footer, footer_px 28, footer_glyph_px 40, frame_margin_y 44, title_px 42, body_tint 0.07, rail_glyph_px 60`; region band art `assets/ui/region_bands/` (Meshy, provenance.json) | Capture r3 (one-line header, day plate, body tint) on all four biomes vs r2b before; judge for FIXED. Judges still want the body below the band to carry the region (tint/hero quest card). |
| P2-007 Quests/Build/Players (4 biomes) | 6.78 r2, PARTIAL (Build FIXED 1/3) | menu.json `quest_empty_inline` (readable sizes + gold hero card r3) and `players_open_seats` `silhouettes, unavailable_hint, unavailable_alpha 1.0, card_margin 10` | Capture r3; judges want the Quests lower third filled and seat cards with silhouettes. |
| P2-031 settings/bindings (4 biomes) | 7.03 r2, PARTIAL | menu.json `controls_scan` enabled (stripes, row_font_px 28, r3: glyph-only pad cells, Reset header, quiet "·" until a row changes, primary row labels) | Capture r3; remaining asks: stick-direction glyphs (no art installed; would need a Meshy/2D glyph request), scroll cue at the clipped last row. |
| P2-002 map (4 biomes) | 6.19 r2, PARTIAL | map.json fog_veil `sea_lanes, undiscovered_alpha 0.55, undiscovered_colour #0d171c, soft_fog, outside_colour #0d171c, ui_font_labels, glyph_controls` (r3 adds the Tidewake island chart and the label pill) | Capture r3; judges want a readable terrain layer edge to edge (Meadows bake is flat green; Cloudreach/Stormwood have roads only). Highest-impact row: consider a painted per-region map underlay via Meshy 2D. |
| P2-032 map active region (tidewake, stormwood, cloudreach) | defect FIXED 9/9 on both sides; screen mean 6.19 | none needed | Passes when the map screen mean reaches 6.7+/7.5; judge it with P2-002. |
| P2-004 exploration HUD (4 biomes) | not yet judged (r1/r2 captures showed the lean HUD regressing in pad mode; fixed in code since) | hud.json `hud_lean` enabled + `legend_glyph_px 44, pad_glyph_px 32, assigned_slot_height 112, combat_prompt_yield` | Capture r3 HUD in gamepad mode on four biomes vs r2b; judge. |
| P2-061 catch result hierarchy (4 biomes) | not yet judged; Meadows before/after frames captured (card works, enemy panel overlap fixed since) | hud.json `catch_card` enabled + `card_half_width 360, card_top -400, raise_message_rows, message_row_top -380` | Capture catch after (Meadows; identical card code across biomes) with `tools/phase2_capture_catch.gd`; judge 06-breakout/08/09 frames. |
| P2-088 fight roster contrast (tidewake, stormwood, cloudreach) | not yet three-judged; Tidewake Venn fight frames on main (fight_before) show the roster on an opaque plate | none (plus the fight-HUD overlap fix above, `combat_prompt_yield` + `raise_message_rows`) | Judge P2-088 and the coordinator's Tidewake overlap note on `tests/capture_tidewake_named_fights.gd --trainer=water_trainer_venn --pilot=READER --interval=6 --max-frames=40 --cap-s=400 --render-only-saves` before/after. |

Ready for a GPU confirmation pass now: P2-095, P2-096. Ready for a GPU judging round once r3 is captured: P2-001, P2-007, P2-031, P2-002/P2-032, P2-004, P2-061, P2-088.
Not visual (shipped functional fixes): build selector footprint (smoke_build_menu_footprint PASS 18.1%), catch capture party step, mouse-bound action names (LMB/RMB in the fight move cluster; glyph tests 19/187/0 failed — on tb/ui, not in this landing).

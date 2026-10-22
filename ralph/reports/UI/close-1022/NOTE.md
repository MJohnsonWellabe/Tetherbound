# UI lane close run (tb/ui), 22 Oct 2026

## TO COORDINATOR
- 22 Oct 23:55 CT FINAL READY tb/ui-final 3bc29d38 (note commit; code head 070348be) (origin/main a4f8a6b7 + tb/ui; tb/ui-land's content is included via tb/ui, craft flags set here).
  - ON (beat control in yardstick round 2, CPU llvmpipe Low, mapped; ON by coordinator decision for the wind-down where below 7.5): P2-095/096 craft panel `compact_rows` + `craft_button` 7.66 vs 6.25 (meets the bar CPU-provisionally); P2-001 menu shell `shell_scenic` 7.46 vs 5.95 (judged values; floor art 0.22/0.55); P2-007 `quest_empty_inline` 7.34 vs 5.80; P2-031 `controls_scan` 7.30 vs 5.72 (plus unjudged larger stick arrows and flat Reset); P2-002 map `fog_veil` sea_lanes/soft_fog/ui_font_labels/glyph_controls/outside_colour + `painted_chart` + `cloud_fog` 6.91 vs 4.95. `device_hints` (pad glyphs in the Satchel) ON per controller-first, unjudged, verified in a check capture. `players_open_seats` was already ON.
  - Always on (functional, tested): world prompt hides under the fight command bar; world status overlays hide with the HUD; L3 and stick-direction glyphs; `--gamepad` on the craft/Tidewake fight capture tools; `--survey-roads-m` capture fixture.
  - OFF (included): `hud_lean` (6.41 vs control 6.71), `minimap_realm_terrain` (unjudged; fixes the minimap drawing the Meadows bake outside the Meadows), `shell_scenic.collapse_status` (unjudged), `catch_card` (unjudged).
  - Checks on tb/ui-final: smoke_craft_panel_controller, smoke_hud_presentation_lifecycle, smoke_fight_world_prompt_yield, smoke_world_hud_overlay_hides, smoke_menu, smoke_menu_focus, smoke_menu_owns_dpad, smoke_settings, smoke_backpack_pad_target, smoke_backpack_equipment, smoke_local_requests all exit 0; units (glyph, controls, craft station, input owner, map x7, menu data, quest log) 158 tests / 2595 assertions, 0 failed. No new modal; no test changed except an added stick-direction assertion.
  - Evidence: note + key/score .json files, one _sheet per round (filled-prompt .txt files removed). Region band art (4 x ~0.85 MB PNG + 16:9 sources) stays: the shell uses it.
- 22 Oct 22:00 CT INFO lane stopped on coordinator request (usage). All work pushed on tb/ui; every candidate OFF in committed config. READY tb/ui-land 4b8474c1 (P2-095/096) still stands. See RESUME below.
- 22 Oct 20:55 CT READY tb/ui-land 4b8474c1 P2-095/096 craft panel ON (compact rows, Craft button with disabled "Missing materials" state, live pad glyphs): CPU yardstick round 2 mapped 7.66 (7.79/7.40/7.79), all three defects FIXED 3/3, confirming batch (anchors to 7.53); evidence tb/ui ralph/reports/UI/close-1022/r2. Also in it: world prompt hides under the fight command bar (GPU F39-0 finding), world status overlays hide with the HUD, L3/stick-direction glyphs, `--gamepad` on the craft and Tidewake fight capture tools. Checks: 4 smokes + 55 unit tests PASS. Please queue GPU confirmation (Low/Compat + Medium) with `phase2_capture_build_systems.gd --biome=stormwood --seed=2042 --gamepad`.
- 22 Oct 18:25 CT INFO functional fix on tb/ui (not landed): the Stormwood surge tag ("⚡ Calm · Sheltered", a world CanvasLayer) printed through the open pause menu; world status overlays now join `input_owner.WORLD_HUD_OVERLAY_GROUP` and hide with the world HUD. New smoke `tests/smoke_world_hud_overlay_hides.gd` PASS. Also new stick glyphs (agent-drawn, `assets/ui/input_prompts/AGENT_DRAWN.md`): L3 and stick directions now draw glyphs (units 49 tests PASS). Round 2 capture running.
- 22 Oct 18:15 CT INFO Round 1 on the yardstick (CPU llvmpipe Low, tb/ui 11ce7482 + flags on locally for after). Mapped after means: P2-001 shell 7.37 (above_top_anchor), P2-095 craft 7.37 (above_top_anchor), P2-031 settings 7.26, P2-007 panels 7.11, P2-002 map 6.80, P2-004 HUD 6.51. None at 7.5 yet; all but HUD clear the 6.7 CPU-provisional line. Fit linear slope 1.03, r 0.84, RMSE 0.76 (warning). Working the judges' asks for round 2.
- 22 Oct 08:40 CT INFO P2-095/096: shipping CraftPanel unchanged on tb/ui (new candidates OFF). Craft before/after (gamepad glyphs, compact rows, Craft button) capturing now; next batch judges craft + map on the yardstick.
- 22 Oct 08:40 CT INFO fight prompt overlap fix + `--gamepad` capture flags on tb/ui (details below); land branch follows with the next READY.

Yardstick: tools/visual_judge (standard prompt, anchors, calibrate.py), merged from tb/judge-yardstick.
Messaging the coordinator from this session fails (`elevated_session_untrusted_device`); status lives here.

## Status for the coordinator
- P2-095/096 craft panel: shipping frames unchanged on tb/ui. New candidates `compact_rows` and `craft_button` (craft_presentation.json) are committed OFF. Always on: glyph hints redraw when the device switches while the panel is open (no static-frame change). For the GPU rejudge, `tools/phase2_capture_build_systems.gd --gamepad` (tb/ui) shows pad glyphs.
- Functional fix (tb/ui, not landed): the world prompt hides while the fight command bar is shown (GPU finding "E Gather Reef Stone" over the command bar); a phase that releases the bar keeps its prompt. New `tests/smoke_fight_world_prompt_yield.gd` PASS; `smoke_hud_presentation_lifecycle` 70 checks PASS; `smoke_craft_panel_controller` exit 0.
- Fight glyphs: combat HUD already follows the last device (seeded to pad when a joypad is connected). The GPU "keyboard-only" frames came from a capture with no pad. `tools/phase2_capture_tidewake_fights.gd --gamepad` now captures what a pad player sees.
- P2-002 map: candidates `fog_veil.painted_chart` + `fog_veil.cloud_fog` (map.json, OFF). Unsurveyed cells stay opaque (OW3).

## Round 1 (22 Oct, 18:15 CT): yardstick batch, CPU llvmpipe Low/Compatibility, xvfb 1920x1080
- Source: tb/ui 11ce7482. Before = committed config (all candidates OFF). After = `after_on` flags locally: map `fog_veil` sea_lanes/soft_fog/ui_font_labels/glyph_controls + `painted_chart` + `cloud_fog`; menu `shell_scenic` (r3 values), `controls_scan`, `quest_empty_inline`; hud `hud_lean`; craft `compact_rows` + `craft_button`.
- Capture: `tools/phase2_capture_ui.gd --biome=<4 realms> --gamepad --tabs=backpack,creatures,map,quest_log,build,players,settings --map-zoom-samples --hud-settle-frames=60 --survey-roads-m=700` (disclosed survey fixture: fog revealed along each realm's roads within 700 m, identical on both sides); craft `tools/phase2_capture_build_systems.gd --biome=stormwood --seed=2042 --gamepad`.
- Batch: `anchor_tiles.py --include craft --seed 1022`, 9 candidate sets (2 frames per side) + 3 anchor pairs (craft, f36_0_gap, p2_094_r4); standard prompt verbatim (`r1/judge_prompt_filled.txt`); three fresh judges. Key `r1/key.json`, raw `r1/batch1.json`, mapped `r1/mapped1.json`, sheet `r1/_sheet_map_r1.png`.
- Fit: linear, slope 1.029, intercept 0.406, r 0.836, anchor RMSE 0.759 (warning: > 0.75). Confirming batch (top anchor 7.35).

| Row | Before mapped | After mapped (j1/j2/j3) | above_top_anchor | After defect verdicts | Result |
|---|---|---|---|---|---|
| P2-001 shell (2 sets) | 5.93 | 7.37 (7.19/7.50/7.40) | yes | generic panel PARTIAL 6/6; keyboard footer FIXED 6/6 | below 7.5 |
| P2-095/096 craft | 5.55 | 7.37 (7.19/7.61/7.30) | yes | recipe text FIXED 2, PARTIAL 1; hints FIXED 3; 3 recipes/disabled FIXED 3 | below 7.5 |
| P2-031 settings | 6.03 | 7.26 (7.19/7.19/7.40) | no | rows PARTIAL 3; binding glyphs PRESENT 3 | below 7.5 |
| P2-007 panels (2 sets) | 5.91 | 7.11 | no | empty areas PARTIAL 6/6; focus FIXED 3, PARTIAL 3 | below 7.5 |
| P2-002 map (2 sets) | 5.14 | 6.80 | no | dark canvas PARTIAL 6/6; stair-steps FIXED 5, PARTIAL 1; footer FIXED 6 | below 7.5 |
| P2-004 HUD | 6.37 | 6.51 | no | boxes PARTIAL 3; counts PRESENT 1, PARTIAL 2 | below 7.5 |

Judges' asks (round 2 worklist):
- Map: terrain still unread (surveyed strips narrow; unsurveyed stays hidden per OW3); Meadows chart is a narrow centred strip with empty side bars; label on chart bottom edge.
- Shell: body panels flat and identical per tab; worn-equipment list clipped ("Backpack"); small helper text.
- Craft: "Missing" tags tiny; Greater Orb cost wraps to 3 lines; list cut at bottom.
- Settings: binding cells are words ("Left stick up"), want glyphs; Reset column dots read unfinished; faint row separation; last row clipped.
- Panels: empty lower third (Quests, Players); open-seat rows read placeholder; no focused Build card.
- HUD: legend text vanishes on pale sand without its plate; quick-slot counts tiny and overlapping the glyph; minimap flat.
- New art (judges): homestead wall infill (anchor row, not this lane).

## Round 2 (22 Oct, 20:30 CT): yardstick batch, CPU llvmpipe Low/Compatibility
- Source: tb/ui 46a9def7 (round-2 candidates: stick-direction glyphs and quiet Reset in Settings, cloud beyond the realm on the map, craft tag on the name line, lean HUD legend plate + spaced counts, menu floor art; config values committed OFF, `after_on` locally). Before frames reused from round 1 (same committed-OFF config; the only unconditional code changes since are the L3 glyph and the Stormwood surge tag fix).
- Batch: `anchor_tiles.py --include craft --include f36_0_npc:C1 --seed 2210` (anchors f10_2_r3_capacitor, craft, f36_0_npc:C1 up to 7.53); prompt `r2/judge_prompt_filled.txt`; three fresh judges. Key `r2/key.json`, raw `r2/batch2.json`, mapped `r2/mapped2.json`, sheet `r2/_sheet_craft_r2.png`.
- Fit: linear, slope 0.988, intercept 0.583, r 0.844, anchor RMSE 0.742; confirming batch.

| Row | Before mapped | After mapped (j1/j2/j3) | Gain vs r1 | After defect verdicts | Result |
|---|---|---|---|---|---|
| P2-095/096 craft | 6.25 | **7.66** (7.79/7.40/7.79), above_top_anchor, confirming batch | +0.29 | recipe text FIXED 3; hints FIXED 3; 3 recipes/disabled Craft FIXED 3 | **PASS (CPU)** → land |
| P2-001 shell | 5.95 | 7.46 (7.60/7.30/7.50) | +0.09 | generic panel FIXED 6/6; footer FIXED 6/6 | below 7.5 (first low-gain round) |
| P2-007 panels | 5.80 | 7.34 | +0.23 | empty areas PARTIAL 6/6; focus FIXED 6/6 | below 7.5 (first low-gain round) |
| P2-031 settings | 5.72 | 7.30 (7.50/7.00/7.40) | +0.04 | rows FIXED 3; glyphs FIXED 3 | below 7.5 (first low-gain round) |
| P2-002 map | 4.95 | 6.91 | +0.11 | dark canvas PARTIAL 6/6; stair-steps FIXED 3, PARTIAL 3; footer FIXED 6 | below 7.5 (first low-gain round) |
| P2-004 HUD | 6.71 | 6.41 | −0.10 | boxes PRESENT 3; counts FIXED 2, PARTIAL 1 | below; lean approach not gaining |

Round-3 asks:
- Shell: clipped worn-equipment list ("Backpack"); in-panel keyboard hints ("G / Drop", "H / Split", "D-pad / arrows") while a pad is active; empty belt rows read as placeholders.
- Settings: the four stick-direction glyphs look alike (arrow too small); Reset column empty boxes; last row cut at the scroll edge.
- Panels: lower third of Quests empty; Players list is "Open seat" filler.
- Map: still no terrain on the surveyed Meadows/Cloudreach/Stormwood strips; Tidewake island edges step.
- HUD: six or more boxed widgets; flat green minimap; the lean variant added a legend tray and did not reduce the box count. Next: one different approach (consolidate widgets) or park at 6.71.

## RESUME (22 Oct 22:00 CT, lane stopped on coordinator request)
State: all candidates OFF in committed config on tb/ui. Round-3 "after" capture was stopped mid-Cloudreach (Meadows and Tidewake after frames exist locally only, unjudged). Nothing running.

How to run a round: candidates ON locally with the scratchpad `after_on.py` flags (listed per row below), capture with `tools/phase2_capture_ui.gd --biome=<meadows|water|cloudreach|stormwood> --gamepad --tabs=backpack,creatures,map,quest_log,build,players,settings --map-zoom-samples --hud-settle-frames=60 --survey-roads-m=700` (Cloudreach ~50 min, others ~10–30 min on CPU), before side = committed config. Two frames per side per set (`r1/candidates_spec.json` lists the frames and briefs), `anchor_tiles.py --include craft --include f36_0_npc:C1`, standard prompt, three judges, `calibrate.py`.

| Row | Best mapped (round) | Candidate (all OFF) | Next step |
|---|---|---|---|
| P2-095/096 craft panel | 7.66 r2, PASS (CPU) | craft_presentation.json `compact_rows`, `craft_button` (ON in tb/ui-land) | Coordinator lands tb/ui-land 4b8474c1; GPU confirmation with `phase2_capture_build_systems.gd --biome=stormwood --seed=2042 --gamepad` |
| P2-001 menu shell | 7.46 r2 (one low-gain round) | menu.json `shell_scenic` (r3 values + floor art 0.4 + `collapse_status`), `device_hints` | Judge round 3 (collapse_status fixes the clipped equipment list; Satchel hints glyph-only on pad) |
| P2-007 Quests/Build/Players | 7.34 r2 (one low-gain round) | menu.json `quest_empty_inline`, `players_open_seats`, `shell_scenic` floor art | Judge round 3; remaining ask: empty lower third, "Open seat" filler |
| P2-031 settings/bindings | 7.30 r2 (one low-gain round) | menu.json `controls_scan` (stick-direction glyphs, flat Reset when unchanged, cell_glyph_px 56) | Judge round 3 (larger direction arrows redrawn) |
| P2-002 map | 6.91 r2 (one low-gain round) | map.json `fog_veil` sea_lanes/soft_fog/ui_font_labels/glyph_controls/outside_colour + `painted_chart` + `cloud_fog` | Judge round 3; Cloudreach is mostly sky at chart resolution (sampling is correct); terrain read is the remaining ask |
| P2-004 exploration HUD | 6.71 before / 6.51 r1 / 6.41 r2 after | hud.json `hud_lean` (r3: objective card 460 wide, gold left eyebrow) + `minimap_realm_terrain` (minimap used the Meadows bake in every realm; now each realm's own terrain) | Judge round 3 as the different approach; park at 6.71 if it does not gain |
| P2-032 map active region | FIXED on both sides | none | Passes with P2-002 |
| P2-061 catch card, P2-088 fight roster | not judged this run | hud.json `catch_card` | Capture with `tools/phase2_capture_catch.gd` and Tidewake fights `--gamepad` |

Functional fixes: in tb/ui-land (world prompt under the fight command bar, surge tag through the menu, L3/stick-direction glyphs, `--gamepad` capture flags). Still only on tb/ui: `tools/phase2_capture_ui.gd --survey-roads-m` fixture.

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

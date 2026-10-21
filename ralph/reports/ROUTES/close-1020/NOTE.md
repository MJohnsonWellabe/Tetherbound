# Routes close-1020: work note (F49#0 + F19#5, F49#3, F47#0)

Cloud container, Godot 4.7 headless. Branch tb/routes merged with origin/main 2124b1f6c.

## training_t1_altar_1 stall (17 Oct): diagnosis and fix
- Symptom: `EARNED WALK START purpose=harvest rootstone final target=(399,-0.5,1792)` from home (-22.7,2.1,22.7), then ~20 min silent until killed.
- Cause (helper routing, not a game bug, not only a timeout): the Altar costs stone 10, rootstone 4, ironwood 2. Rootstone exists only in the quarry beyond the South Bridge gully (`terrain_playground.json` crossing carve: centre (8,1330), axis 0, half_length 1040, i.e. a gully across the whole meadow at z≈1330). `meadows_earned_material_segment.gd` admits supplies past the crossing once the bridge is open, but `_walk_target` only routed the village fence. The straight line home→quarry meets the gully near x≈286, 280 m east of the span; the navigator's confined-reset watchdog never fails a leg, so it circled at the rim for the whole 106k-frame budget (240 + 60/m × 1770 m).
- Fix (smallest): `_walk_target` inserts the authored bridge approach, near bank and far bank (the same points `altar_training_piece.return_to_bridge` uses) when the player and the supply are on opposite sides of the open bridge, in either direction. Same-side and closed-bridge walks are unchanged (camp/tournament paths unaffected).
- Focused test: `tests/test_material_bridge_legs.gd` (2 tests, 9 assertions, pass).
- Alternatives checked: no existing helper path routes homestead gathering over the bridge; the Fights altar helper reuses this material segment.

## Pieces
Meadows: `godot --headless --fixed-fps 60 --path . --script tools/earned_saves/earned_chain_runner.gd -- --segment=<id> --save-dir=~/routes/<root>/<id>/save --receipt=~/routes/<root>/<id>/receipt.json --training-profile=meadows_training_v1 [--handoff-from=~/routes/<prev-root>/<prev-id>]`. Receipts in `receipts/`; saves stay local.

| Piece | Root | SHA | Wall | Result |
|---|---|---|---|---|
| opening_village (fresh title) | p01_village | 8d96dc518 | 314 s | PASS, L3/2, 19 flags |
| opening_team | p02_team | 8d96dc518 | 1016 s | PASS, five owned L5, 12 flags |
| camp_tournament | p03_camp | 8d96dc518 | 1883 s | PASS, L6/8/7/5/5, 45 flags |
| bridge | p04_bridge | 8d96dc518 | 1280 s | PASS, L7/8/7/5/5, crossed (depth 9.42) |
| opening_village (fresh title) | p01_village | 5e4ccd4f4 | 349 s | PASS, L3/2, 19 flags (current chain; receipts replaced) |
| opening_team | p02_team | 5e4ccd4f4 | 1194 s | PASS, five owned L5 |
| camp_tournament | p03_camp | 5e4ccd4f4 | 1818 s | PASS, L7/7/7/5/5, 45 flags (first attempt failed on the rest helper's exterior-fence detour, stuck on a slope at (30.5,−26.7); one confirming rerun passed) |
| bridge | p04_bridge | 5e4ccd4f4 | 1481 s | PASS, L8/8/7/5/5 |

## F47#0 proposal (owner choice, default-off)
`data/config/essence.json` `_f47_0_clear_time_proposal` (`enabled: false`, read by nothing). Finding: combat XP, not Altar price, dominates leveling (doubling level_cost multipliers moves the ledger break-even from 0.39 to 0.42), so the trickle `auto_xp_scale` is the main lever.
- Option A (ledger-safe): auto_xp_scale 0.35→0.28; attuned_per_creature +1 per Master (t1 3, t2 2, t3–t5 3). Break-even wild-site engagement 0.39→0.50 (+125 first-time fights). Estimate **11.4–16.6 h**.
- Option B (reaches target): auto_xp_scale 0.25; level_cost multipliers L11–60 1.0→2.0; attuned +1. Break-even 0.66 (plausible mismatched team 0.67; all-bodies ceiling still reaches every checkpoint, so no repeat grinding). Estimate **14.4–21.1 h**. Needs the F27 ledger's 0.5 ordinary-engagement assumption moved to 0.66 (owner decision).
- Method: agent estimate v2 + (new break-even − 0.39) × 1132 main-path wild sites × 1.0–1.5 min + attuned gathering 0.5–1 h; break-even by stepping `runScenario` engagement 0.01 with only these values overridden. Checks with the block present: `node --test tests/test_f27_route_ledger.mjs tests/test_economy_ledger.mjs tests/test_economy_difficulty.mjs tests/test_economy_supply_census.mjs` 27/0; `run_tests.gd --only=essence,altar_service` 24 tests/0 failed.

## Tidewake T3 independent chain (disclosed generated boundary `tidewake_t3_ione_independent`)
On 392c8f3c2: generate → 05i_ione_approach (129 s) → 05j_ione_duel_only (93 s, real master_t3 win) → 05k_ione_chest (50 s) → training_t3_preparehome (90 s) → training_t3_altar_1..5 (164/84/83/78/79 s), all PASS; all five L30/cap30. Prior T1/T2 history is generated (disclosed).
- training_t3_kitchen FAIL (252 s): real Forge/stone gather, then `_gather`'s return walk from Main Street (8.3,20) to the station stance (-11.6,21.1) stuck at (2.1,19.3) against Grandpa's crop beds (z 21–23.4), 2 confined resets. Fix: walk via `_go_home`'s interior plot stance (-12,24) first (`homestead_common.gd::_gather`). Requires rerunning from preparehome on the new SHA (exact-SHA predecessor rule); the Meadows prefix is rerun on the same SHA.
- Rerun on b514fbb8d: preparehome + altar_1..5 PASS again (83/154/81/77/79/78 s); the plot-stance return now works (Forge built, Kitchen placed), then `training_t3_kitchen` FAIL (612 s): the trainer froze at (21.7,17.98) for the rest of the piece, can_walk true, velocity 0. A local untracked probe (input-owner print, same SHA) showed `scripts/onboarding/lesson_panel.gd` opening at frame 3386: Tam's onboarding lesson card (`lesson_rules.gd`, teacher radius) opens on its own as the trainer passes and holds input until confirmed. Fix: both walk helpers (`gate_a_material_route.gd`, `gate_b_tail_segment.gd`) confirm a lesson card with the physical confirm button while a walk runs (transcript line per card). This also applies to the Meadows chain once Master/feast lessons become due.
- Process note: editing the checkout during a run dirtied the tree, and camp_tournament (857 s) refused export ("exact clean source commit"). From now on, edits happen only between runs.
- Rerun on 14df3097d: lesson cards were confirmed (feasts/masters/portals/shrines lesson flags saved), Kitchen built; then `training_t3_kitchen` FAIL (855 s): "No plot spot took a green forge ghost". Local probe scan (BuildPlacer.preview_placement over the plot, 2 m grid): the authored north spots' 3 m stances fall outside the village fence (unreachable), the west edge is too steep, (12,22) is obstructed. Valid in-fence spots cluster at x −12…−6, z 10…16. Fix: PLOT_SPOTS gains (−10,14), (−6,14), (−10,10), (−6,10) after the Altar/Kitchen slots.
- opening_team failed 3 times in a row on 14df3097d (two different fresh villages) with the native candy approach's strict terrain-contact refusal (e.g. depth 0.00166 > safe_margin 0.001). It passed 3/3 earlier; the team helper is untouched by these commits. From here, pieces run with Godot `--fixed-fps 60` (disclosed engine flag: deterministic 1/60 frame steps, independent of CPU load from parallel pieces).
- Rerun on 8d96dc518 (fixed-fps): opening_village 327 s, opening_team 1028 s, camp_tournament 1896 s PASS; Tidewake preparehome + altar_1..5 PASS; Kitchen built, Forge built at (−10,14) on the new interior spot; the ironwood walk then crossed via the authored bridge approach. At (31.5,1249) the material walker's old village workshop-lane rule (x 31–39, z>30, with no upper z bound) inserted (35,14) and sent the trainer 1.2 km back toward the village. Fix: bound that rule to the village lane (z<60). The running piece continues on its budget.

## F19#5 portal-sign half
`godot --headless --path . --script tests/run_tests.gd -- --only=test_f19_order_consumers.gd,test_f19_curve.gd` on 5e4ccd4f4: 9 tests, 246 assertions, 0 failed, including `test_every_live_arch_board_names_its_recommended_level_and_sealed_ones_none`, `test_every_live_portal_prompt_keeps_its_recommendation_in_every_travel_state` and `test_recommended_levels_never_gate_the_actual_host_portal_policy`. The sign/no-hidden-gate half of F19#5 passes; the earned-checkpoint half remains tied to the F49#0 pieces.

## Runs on 5e4ccd4f4 (fixed-fps)
Meadows from a fresh village (village PASS 362 s) → team → camp → bridge → altar_1..5 queued; Tidewake T3 rerun from the accepted Ione chest (`t3_05k`): preparehome 129 s, altar_1..5 PASS, Kitchen running (ironwood via the bridge).

- training_t3_kitchen on 5e4ccd4f4 (from ~/edit): real ironwood +3 at (−379.3,2569.8) after the bridge route, carried home; then FAIL "The Forge channel did not refine 2 rootiron_ingot (have 0)" after 7200 frames beside the Forge. `smoke_f32_forge_plates.gd` passes under `--fixed-fps 60`, so the cause is piece-specific; a local probe rerun prints the Forge `channel_stopped` reason.

## training_t1_altar_1 on 5e4ccd4f4 (from the passing bridge save)
FAIL after 7995 s, but every homestead step before payment now passes: Home Key home; supply walk over the authored bridge approach and banks; real rootstone +2/+2 at the quarry (399,1792)/(394,1797); real ironwood +3 at (−361.1,2576.3); carried back over the bridge to Main Street and into the plot; paid Altar built at (−12,20); prompt reached. The 17 Oct stall is fixed. New blocker: "No earned compatible Altar payment in bag or storage". The bridge save holds 0 essence and 0 Tether Candy: opening_team reached L5 on authored candy (training_wins 0), and no earned piece through the bridge defeats wilds or releases a catch. Party L8/8/7/5/5 needs about 288 essence of matching types (or XP from about 60 practice-meadow wild wins) to reach cap 10. No existing helper earns it outside the team segment's practice-meadow loop. Coordinator decision requested (earning piece vs disclosed boundary).

## Essence earning piece (56bf99b16)
`tools/earned_saves/essence_earning_piece.gd` adds `training_t1_earn` and `training_t2_earn` before each tier's Altar slots (profile order in `f49_disk_handoff.gd`, dispatch in `earned_chain_runner.gd`). It takes the Home Key from the far bank, then reuses the team segment's practice-meadow wild choice, approach, pilot care and piloted wins until every retained level to the cap is payable by compatible essence or Tether Candy (`unfunded_levels`, test `test_essence_earning_piece.gd`: 2 tests pass; `test_f49_training_prefix.gd` 6 pass). Nothing is granted; each win is a production victory.

## Load sensitivity of the opening_team helper
opening_team's native candy approach (opening_geometry_navigator) refused on terrain contact depth 0.0024–0.0029 > safe_margin 3 times in a row while a heavy local probe (a per-frame scene scan) loaded the CPU, at the same spot (−425.3,500.7) in one world. The same village then passed with the probe throttled (1155 s). Its wall-time callback caps make it load-sensitive even under --fixed-fps. Run it without heavy concurrent processes.

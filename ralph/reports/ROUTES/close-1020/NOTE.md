# Routes close-1020: work note (F49#0 + F19#5, F49#3, F47#0)

## TO COORDINATOR
- 2026-10-22 13:40Z READY tb/routes 58b29d287 Game fixes with tests: Master/Kitchen/feed chooser names companions (599214425), chains controller focus past the visible list (bc4683e4a), closes on controller B / menu_cancel (049dde025); Meadows pieces may start from an earlier commit's accepted save, `--pinned-start` (66f0d48d6). Piece set passed: Tidewake T3 loop 05i → training_t3_return (seams/ manifests, 1 reviewed difference).
- 2026-10-22 13:40Z Unproven (Routes): Meadows training_t1_master (pinned run m12 on 58b29d287 in progress; Orin travel and chest-return fixes 5e27262e2, 58b29d287), training_t1_kitchen, training_t1_feed, training_t2_earn, t2_altar_1..5, t2_master, t2_kitchen, t2_feed, t2_return, warrens, relay, sigils, hall, warden, tidewake_handoff; Tidewake story pieces 01_opening..05d and 06_swimmer..09_cloudreach_handoff (not run by Routes). Passed: Meadows opening_village → training_t1_altar_5 (0105fc978).
- 2026-10-22 13:55Z READY tb/routes c4bb2e1fd Merged tb/routes-b (incl. its f49_portal_travel rename) and restored f20_portal_travel's LESSON_PANEL; every chain runner (earned, tidewake, cloudreach, stormwood) compiles. Land routes and routes-b together at this head or later.
- 2026-10-22 14:00Z READY tb/routes b7ae385ff Also merges tb/routes-b head 7627675ce (Stormwood pilot swings only within reach, `swing_now`, test_stormwood_pilot_reach.gd per Routes-B: 2 tests pass). Conflict-free merge; adds only those two files over c4bb2e1fd.

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

## Forge refine blocker diagnosed (Tidewake T3 Kitchen)
Local probe (Forge signals): `channel_started rootiron_ingot 2`, then 1.5 s later `channel_stopped commit_refused "The station is unavailable…"`. The saved Satchel was 24/24 slots full (Ione's chest kit: six sluice_metal stacks, reef stone, reed fiber, pearls, blooms, attuned herbs), so the first ingot had no slot and the canonical craft commit refused it. The existing sequence includes `training_t3_storage` (Storage Chest, store all but tools; `_gather` withdraws on demand) between Altar 5 and the Kitchen; earlier runs skipped it. Rerun: storage → kitchen → feed from the accepted Altar 5 save.

## Earn piece pool widened (d51287cbf)
First earn run (practice-meadow L2–5 pool): 3 wins → ~10 XP per member and 1 ground essence each; 17 levels still unfunded. That would take hundreds of wins. The piece now trains on unowned wilds within 260 m of (−20,140) (Lower Meadows clusters around the village), at or below the pilot's level and the tier cap. Meadows chain restarted from a fresh village on d51287cbf.

## Tidewake T3 storage → kitchen (d51287cbf)
`training_t3_storage` PASS (150 s): Storage Chest, every non-tool stack stored. `training_t3_kitchen` FAIL after 9932 s, but every material step now passes: withdrawals from the chest, Kitchen and Forge built on the interior spots, Forge refined 2 rootiron_ingot (exact saved bill), 8 more ironwood earned over the bridge (stock 10). Then "selected kitchen_meadows and the live pending selection is ''": the bag could pay (rootstone 8, ironwood 10, ingots 2), but `_select_piece` reached the cell by counting ui_right presses. The Build catalogue grid wraps at 10 columns, and the home-station category with its tier attachments wraps, so the accept landed on another, unaffordable cell. Fix (`gate_b_tail_segment.gd::_select_piece`): steer by the cells' layout until the wanted cell owns focus, and fail rather than accept any other cell.
- training_t3_kitchen on 92c10d6ac FAIL after 11024 s, with more real progress: Kitchen tier 1 attachment `kitchen_meadows` placed (catalogue fix works), Tidewake materials withdrawn, 2 tidesteel_ingot refined. Placing tier 2 (`kitchen_tidewake`) then failed with "could not get clear of the interact line … Talk to Grandpa". `_clear_of_every_offer` stepped away from each winner in turn (Use Forge → Pick berries → Talk to Grandpa) and walked into the farmhouse (−1…2, 13.7…16.3). Fix: lean away from every nearby offer within 6 m (arbiter candidates), not just the winner.
- training_t1_earn (0c8fb8ef, fresh navigator per engagement) passed the old cap: 54 wins, 3 levels unfunded and still running.
- training_t3_kitchen on 5b77cee5c FAIL (9646 s): "a green kitchen_meadows ghost at (−7.5,14) placed nothing". `_select_piece` first stepped clear of the Forge's prompt to (−5.7,19.4), then pressed place from there. Fix (`homestead_common.gd::_place_at`): walk the armed piece back to its stance before placing.
- Strategy: Tidewake T3 (independent generated boundary) shakes out the homestead Kitchen/feed blockers first. Every source change restarts the Meadows training chain from a fresh village (exact-SHA lineage; light cuts refuse the training profile), so Meadows is re-run once the homestead path is clean.
- training_t3_kitchen on c81e61779 FAIL (8502 s): Kitchen tier 1 placed at (−13,14), tidesteel ingots refined, then "No stance near the kitchen took a green kitchen_tidewake ghost". Cause: `station_rules.placement` refuses tier >1 without `attachment_recipes` (F31#2). The real `relic_hang` transaction grants `next_tier_blueprints(biome)`; the disclosed independent T3 boundary declared `relics_hung: [meadows]` but carried no blueprints. Fix (`earned_chain_runner.gd` generated-fixture path, T3 profile only): carry exactly the blueprints the declared hung relic grants. The T3 chain is regenerated from the boundary.

## training_t1_earn PASS (0105fc978)
Meadows chain from a fresh village on 0105fc978 (`~/edit` checkout): opening_village 367 s; opening_team 808 s FAIL (candy road terrain contact at (−410.7,478.0), the same spot as an earlier failure) → rerun 539 s FAIL (contact depth 0.00119 > 0.001 on near-flat ground) → rerun 1122 s PASS; camp_tournament 2065 s; bridge 1367 s; **training_t1_earn PASS**: Home Key home, 76 ordinary wild wins on Lower Meadows wilds, every retained level to cap 10 funded (essence_ground 49, essence_air 26 at the end), handoff exported. training_t1_altar_1 running from it.

## training_t1_altar_1 PASS (0105fc978), from the passing earn save
16359 s wall (one container restart in between; rerun from the same earn save). The full homestead path passes: Home Key; supply walk over the bridge; rootstone 4/4 at the quarry; ironwood +3 at the Warrens stand; carried home; paid Altar built; slot 1 (Terrapup) already at cap 10 from earned XP, so no payment was due. Party after: L10/10/10/9/9. Altar 2–5 running (slots 4–5 need one paid level each from earned essence).

## training_t1_altar_2..5 PASS (0105fc978)
Each from the previous altar's exported save (`~/routes/p07_t1a2` … `p10_t1a5`, F49 DISK HANDOFF commit 0105fc978, `EARNED CHAIN RESULT failures: []`). All five companions end at cap 10; slots 4 and 5 made real compatible-essence payments.

## Tidewake T3 storage → kitchen → feed PASS
- `training_t3_storage` and `training_t3_kitchen` PASS on 44f4307d7 (Kitchen tier 1 `kitchen_meadows` and tier 2 `kitchen_tidewake` placed; ingots refined).
- `training_t3_feed` first failed: "Controller focus could not reach 'Ascension Feast 3 (ground) …'". Probe: down-focus stopped at the 14th cook row. Game fix bc4683e4a (`breakthrough_panel.gd::_link_focus`, `follow_focus`): rows chain explicitly.
- Then the five feasts cooked and fed, and the piece failed on "'ui_cancel' has no physical joypad binding / Cancel did not close the feed chooser". The chooser closed only on built-in ui_cancel; a controller's B is menu_cancel, so a pad player could not leave the Master/Kitchen/feed chooser. Game fix 049dde025 (`is_cancel` accepts menu_cancel, like the Altar panels; tests in `test_breakthrough_panel_labels.gd`, 20 tests/471 assertions with `test_f28_training_boundaries.gd`).
- **`training_t3_feed` PASS on 049dde025** from `~/tw/t3_kitchen` (224 s): five `feast_t3_ground` cooked (exact saved bill), five companions fed (stay; breakthroughs [1,2,3], exact saved transitions), chooser closed. Receipt `receipts/t3_training_t3_feed.json`. Command: `tidewake_piece_runner.gd -- --segment=training_t3_feed --from=<t3_kitchen> --out=<out>` with `--fixed-fps 60`.
- Merge note: merging origin/main (f20 gained `LESSON_PANEL`) with tb/routes-b (its parent f49 gained the same const) broke every chain runner's compile; 19ea643d7 drops the child's duplicate.
- **`training_t3_return` PASS on 93cd0ac29** from the passing feed save (161 s); receipt `receipts/t3_training_t3_return.json`. The Tidewake T3 loop from the disclosed `tidewake_t3_ione_independent` boundary is now complete: real master_t3 win (05j), Altar slots 1–5, storage, Kitchen tiers 1–2 with Forge ingots, five feasts cooked and fed, return to Tidewake. Cross-commit steps (kitchen 44f4307d7 → feed 049dde025 → return 93cd0ac29) are accepted by `tidewake_piece_runner` (exact SHA is required only for altar/preparereturn) and are listed for the reviewed handoff manifest.

## Meadows chain on one commit (93cd0ac29)
The earned Meadows runner requires the producer's exact commit for the training profile (it refuses light cuts, and main's combat merge touches the light cut's encounter paths), so the passes on 0105fc978 (village → … → altar_5) cannot feed a Master piece on a later commit. A full chain, opening_village → … → training_t1_feed, runs on 93cd0ac29 from a fresh title (`~/routes/q01_village` …). In parallel, Master/Kitchen/feed are shaken out with `--diagnostic` from the 0105fc978 altar_5 save (stamped NOT EVIDENCE).

## Orin route, missing imports, chain restart (063b31600)
- Diagnostic Master run (d11, 4787a41b2) went silent for 29 min on the leg from the South Bridge far bank (8,1338) to Orin's stand. `tools/earned_saves/area_probe.gd -- --x0=360 --x1=476 --z0=1720 --z1=1824 --step=4` maps a rock outcrop at x 428–456, z 1764–1788 across that straight line. Fix 5e27262e2 (`meadows_master.gd::_route_to`): walk to the open Old Quarry floor (412,1780) first, then a stand 4 m from Orin on the quarry side. Diagnostic d12 confirmed it: arrived at (410.5,1779.5), then the stand (434.4,1779.8).
- d12's duel was then refused: `Combat admission refused: {gap 5.0, required inf, stage rendered_gap}` because Orin's burrowback model (`creature_burrowback_installed_retex_v2_lod0.glb`) was not imported. The main merge brought new creature assets and headless runs never re-import, so every run since the merge loaded those creatures as placeholders (hundreds of "Failed loading resource" lines). Both checkouts were re-imported with `godot --headless --path . --import`. Earlier passes since that merge (the 93cd0ac29 chain pieces, Tidewake T3 feed/return on 049dde025/93cd0ac29) ran with placeholders and are rerun where they count.
- Full Meadows chain restarted on 063b31600 (imports present): opening_village first attempt FAIL (`[player] entombed at 25.69,0.52,-27.15 -- recovering`, then the native opening refused after a recovery and could not reach Mira's door; log kept locally); one confirming rerun PASS 394 s. opening_team first attempt FAIL (log overwritten by the retry), second attempt PASS 1444 s. Later pieces running.

## Owner direction 22 Oct: pinned pieces + seam manifests (current status)
Owner (22 Oct, via coordinator): "We shouldn't be doing full route in one go. It should be pieces that start with what they need proven by handoffs of runs that end at the right spot." The fresh-title chain is stopped. `--pinned-start` (66f0d48d6, `earned_chain_runner.gd` + `f49_disk_handoff.gd`, test `test_f49_light_cut.gd` 11/0) lets a Meadows piece load its predecessor's accepted save from any earlier commit; the receipt records an `f49_pinned_start` transition (producer, consumer, boundary). Seam manifests: `seams/<producer>__<consumer>.json`.

### Pieces
| Piece | Start save | End spot | SHA | Result |
|---|---|---|---|---|
| opening_village | fresh title | village, two creatures | 0105fc978 | PASS |
| opening_team | opening_village end | village, five owned L5 | 0105fc978 | PASS |
| camp_tournament | opening_team end | camp/tournament done | 0105fc978 | PASS |
| bridge | camp_tournament end | South Bridge far bank | 0105fc978 | PASS |
| training_t1_earn | bridge end | home, levels to cap 10 funded | 0105fc978 | PASS (76 wins) |
| training_t1_altar_1..5 | previous end | home, all five L10/cap 10 | 0105fc978 | PASS |
| training_t1_master | altar_5 end (pinned) | Orin beaten, recipe chest | 3adc7a887 | RUNNING (diagnostic run d12: real master_t1 win, one round) |
| training_t1_kitchen, training_t1_feed | master end | home, feast cooked and fed | – | unproven |
| training_t2_earn, t2_altar_1..5, t2_master, t2_kitchen, t2_feed, t2_return | t1 feed end | – | – | unproven |
| warrens, relay, sigils, hall, warden, tidewake_handoff | t2_return end (trained order) | – | – | unproven by this lane |
| Tidewake 01_opening … 05d, 06_swimmer … 09_cloudreach_handoff | Tidewake handoff / chapter saves | – | – | not run by this lane |
| 05i_ione_approach, 05j_ione_duel_only, 05k_ione_chest | generated `tidewake_t3_ione_independent` (disclosed) | Ione beaten, chest | 44f4307d7 | PASS |
| training_t3_preparehome, t3_altar_1..5 | previous end | home, all five L30/cap 30 | 44f4307d7 | PASS |
| training_t3_storage, training_t3_kitchen | previous end | Kitchen tiers 1–2, ingots | 44f4307d7 | PASS |
| training_t3_feed | kitchen end | five feasts cooked and fed | 049dde025 | PASS |
| training_t3_return | feed end | back in Tidewake | 93cd0ac29 | PASS |
| Cloudreach T4 / Stormwood T5 | Routes-B boundaries | – | – | Routes-B lane |

Placeholder note: 049dde025 and 93cd0ac29 ran before the asset re-import (creature models as placeholders); feed and return contain no combat or creature-size admission, so their results stand.

### Seams
| Seam | Manifest | Match |
|---|---|---|
| opening_village → opening_team … training_t1_altar_4 → training_t1_altar_5 (9 seams) | `seams/<a>__<b>.json` | MATCH (consumer imported the producer's hash-bound save) |
| 05i → 05j → 05k | `seams/…` | MATCH |
| 05k_ione_chest → training_t3_preparehome | `seams/05k_ione_chest__training_t3_preparehome.json` | reviewed difference: player position (same save; Load seats the trainer 17 m away; the piece leaves by Home Key) |
| training_t3_preparehome → … → training_t3_return (9 seams) | `seams/…` | MATCH |
| training_t1_altar_5 → training_t1_master | written when the pinned piece passes | – |

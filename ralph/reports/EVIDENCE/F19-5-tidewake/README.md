# F19#5 Tidewake checkpoint chain (evidence)

Commit: cf9e6d84 on tb/ev-tidewake-route (from main 9e39d0086). Times CT.

Command (per segment, fresh process):
`tools/earned_saves/run_tidewake_chain.sh <first_segment> "" <log_dir>` which runs
`godot --headless --path . --script tools/earned_saves/tidewake_piece_runner.gd -- --segment=<nn_slug> --from=<prev checkpoint> --out=tests/fixtures/earned_saves/tidewake_<nn_slug>`.

Start: tests/fixtures/earned_saves/tidewake_arrival_generated (generated arrival,
prior_earned_play=false, five L20 companions). No TB_WORLD_SEED; saved population retained.

New harness (disclosed, F19#5's own work): tools/earned_saves/tidewake_piece_runner.gd,
because earned_chain_runner.gd refuses any non-Meadows piece. Same protocol: copy previous
save, production title Load -> Autosave, handoff check (five UIDs in order, flags, items,
realm vs. the previous receipt), unchanged helper(s), Game.save_game(0).

| Segment | Result | Checkpoint |
|---|---|---|
| 01 opening (f49_tidewake_opening) | PASS, 97 s, +2 flags (Pell briefing, swim lesson, 64.9 m swum) | tidewake_01_opening |
| 02 reedhaven | FAIL (see below) | none |
| 03-08 | not run (blocked on 02) | none |

Order note: helpers require Brine before Shellwatch (Shellwatch is the "continuation from
Tovin's Brine Steps victory"), so the runner orders 03_brine, 04_shellwatch.

## 02 Reedhaven findings
1. Game defect, FIXED (cf9e6d84): after a production Load, harvest node
   water:reedhaven:harvest:019 existed twice (WaterPickups + F32 RenewableResources, same
   position). The F32 copy won the arbiter; the helper's (and a player's) chapter copy had
   no source service. Cause: the loaded save has registered stock, so the F32 mount builds
   every Water site before WaterPickups streams its rows in by residency; WaterPickups then
   spawned a second node. Fix: WaterPickups reuses the mount's node for a held site, and the
   mount adopts a resident node already bound to its site. After the fix the ordinary
   Interact pays exactly +3 reed_fiber.
2. Helper assertion, OPEN (needs coordinator approval): water_reedhaven_segment.gd:202/207
   (and water_earned_swimmer_preparation_segment.gd:208) require the legacy world-once flag
   `harvest_node:order:<id>`. A registered F32 renewable site records stock/next_ready_day
   instead and never sets that flag, so the helper fails with
   "did not pay its exact production yield/receipt: gained=3".

## Helper receipt change (coordinator APPROVED, 2026-10-11 ~07:14 CT)
Renewable sites record F32 stock receipts, not world-once flags. water_reedhaven_segment.gd
now accepts either the legacy `harvest_node:order:<id>` flag or, for an F32-registered
site, that same site's receipt: stock revision advanced by exactly one and
next_ready_day > current day (static `harvest_receipt` / `site_stock`). The exact-yield
check and site-id match are unchanged. water_earned_swimmer_preparation_segment.gd:208
treats a site as already harvested on the legacy flag or on that site's next_ready_day > day.

## Run 2026-10-11 07:15 CT (commit e2785dc7)
- 02 Reedhaven PASS, 206 s, +2 flags, same five UIDs; checkpoint tidewake_02_reedhaven.
- 03 Brine FAIL, 170 s: "Tovin challenge never entered its production trainer battle".
  Combat admission refused at Tovin (393.4, 807.4): stage support_missing, then
  clear_seat_search_exhausted after 395 attempts (last: oriented_render_box solid_overlap
  with /root/WaterArchipelago/Terrain). Lead terrapup L20 (belt: terrapup, 3x bramblebun,
  mudsnout).
- Reproduced on current main without any checkpoint save by the existing DRY RUN probe
  `godot --headless --path . --script tests/probe_water_brine_tovin_fight.gd -- --seed=1`:
  PROBE RESULT FAIL, same exhausted 395-attempt seat search (overlap with
  WaterNPCs/water_tovin/Body). So Tovin's battle does not admit on main: a main defect,
  not a save/handoff issue. 04-08 not run (Shellwatch requires Brine's victory).

## Tovin admission fix (51f85d43, coordinator-directed; attempt 1 of 2)
Root cause in combat_manager's staged seat test, not Tovin's position: the oriented render
box (wider than the gameplay footprint) hit uphill terrain above the 0.25 m floor-contact
cut, and the challenging trainer's own body was not excluded. Fix: the director names the
round's trainer (`admission_trainer`, set only around that begin()) and the seat test
excludes its colliders; realm Terrain3D rising within REALM_SEAT_MAX_STEP_M (1.0 m) inside
the box counts as hillside. Non-terrain colliders are reported ahead of terrain and keep
the 0.25 m cut. The support check is unchanged.
Verification (commit 51f85d43):
- probe_water_brine_tovin_fight seeds 1/2/3: PASS/PASS/PASS (was FAIL on main, seed 1);
  fights won in 73.9/71.1/68.1 s.
- run_tests --only=<all test_combat_* + test_*admission*/arena*/seat*>: 292 tests,
  1982 assertions, 0 failed.
- tools/net/run_net_smoke.sh shared_wild_fight: ALL CHECKS PASSED.
- smoke_warrens --guardian-attacks: FAIL "the production aggressive engage route did not
  open combat" both with the fix AND on main's combat files (baseline run) - pre-existing,
  not caused by this change; no admission refusal is logged for the guardian.

## Attempt 2 (support stage) and current 03 Brine state
In the real chain (L20 terrapup lead) attempt 1 still refused Tovin: every candidate failed
at `support_missing` (render corners overhanging the downhill steps by more than the fixed
+/-1 m probe; including TrainerCreature_water_trainer_tovin_1). Attempt 2: a rendered
corner may sit up to REALM_SEAT_MAX_STEP_M + its horizontal distance from the seat (45 deg
walkable slope) above real ground (walkable-normal ray hit, or the existing Terrain3D sphere
fallback stepped down to that depth). The seat centre keeps the step height alone.
Verification with attempt 2: probe seeds 1/2/3 PASS; combat/admission unit tests 292 tests,
1982 assertions, 0 failed; net smoke shared_wild_fight ALL CHECKS PASSED.

03 Brine with attempt 2: admission succeeds, the Tovin battle runs, the first opponent
(water_cannonback) is defeated, then the helper's 180 s fight bound expires with
water_riverdrake at 250 HP ("Tovin combat exceeded 180 seconds"). Belt: five L20 ground
types (terrapup lead, 0.8x vs water). The helper's own note (water_brine_segment.gd:82)
says a terrapup lead needs ~160-180 s even at L55. This is fight-duration vs. the generated
belt, not admission. Open; coordinator decision requested.

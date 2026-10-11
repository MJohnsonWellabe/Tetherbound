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

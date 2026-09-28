# Card M1 (Meadows opening and village): integrated run

**Run.** `ralph/reports/CARDS/m1/m1_run_e35e2611.txt` (trimmed log; engine warnings and world-build chatter removed).

```
TB_WORLD_SEED=15 godot --headless --path . --script res://tests/smoke_four_biome_continuous.gd -- \
  --reload-at-transitions --through-tournament
```

Main `e35e2611` (with only import-generated `.uid` files added on `tb/cards`), Godot 4.7-stable, headless, fresh new game.
Result: `FRESH CAMPAIGN RESULT … "failures":[], "reached":"tournament_won", "requested_prefix_passed":true, "counts_as_proof":true`; process exit 0; 1159 s.

| Card clause | Expected | Observed (this run unless named) |
|---|---|---|
| Fresh controller run: starter and naming | Title, new game, wake, Grandpa, starter picked and named in the real picker | +0.12 s title; +66 s wake; +70.6 s Grandpa and pack; +74.6 s terrapup selected and named (log l.59-62) |
| Real practice fight and catch | Live wild fight, natural weakening, physical orb throw | Bramblebun weakened to 29/106 HP by real combat, throw 1 missed, catch complete with a two-creature party at +125 s; "no seeded progress, HP pinning or reload" (l.66-108) |
| Village and road gate | Gate opens by the earned key | +140.9 s village key earned and consumed by the real gate (l.111) |
| Team earned | No granted members | Further live catches from wild Bramblebuns with earned orbs (l.125-209); five-member party at the reload |
| Camp | Materials gathered, paid campsite built | Earned wood/stone/fiber; "placed paid bedroll through a live green ghost inside the tent", "placed 3 creature beds through the build menu, one per entrant" (l.372) |
| Three-bed tournament consent / readiness | Three entrants each bedded, cared for, rested | Rest receipts `bed_assigned` 3, 4, 5 for party 0-2 plus care beats (l.385) |
| Save/reload | Production save and reload keep flags, party, inventory, condition | `RELOAD rested_team: flags 59 -> 59 (lost [], gained [])`; party, inventory and condition identical; camp re-found from the save |
| Three played bracket rounds in order | Quarter, semi, final by real fights | Mira 2 real defeats / 23 hits, Tam 2 / 29, Oskar 3 / 56; `tournament_won` |
| WORLD §3.2 through-road and side lane; overhead plan | Not the old circle | F01#0 and F01#1 (met; `test_village_road_topology.gd`, lane walks max_off_road 0.00) |
| Day and night ordinary-camera walk; every gate, NPC and interaction | Controller walks reach all targets | F01#2 and F01#3 (met; `ralph/reports/MEADOWS/f01-walks/day_d41ff2f0`, `night_d41ff2f0`, 11/11, code-blind PASS) |
| Two-peer layout | Two peers agree on opening and tournament state | F01#6 (met; PR174 two fresh peers 117 assertions; tournament two-peer 57/0) |
| All three starters, opening to bridge objective | Each starter completes the chain without another starter | F01#4 (met; gate-B full chain per starter, render 36269170273 / 36269360016 / 36269361827) |

**Disclosed shortcuts (relaxed-proof rule, ACCEPTANCE §6.1, STATE §1 ruling 1).**
- Harness-driven controller input (real `InputEvent`s through the live InputMap) and harness fights; headless.
- One seed (15) and one starter (terrapup) in the integrated run; the other two starters come from F01#4, whose chain grants the third member and levels.
- Day/night walks, overhead plan and two-peer layout are feeder evidence, not re-run here. F01#6 records that cold reconnect and road-layout agreement were not re-proved.
- "Every gate, NPC and interaction" is covered in F01's sense: the 11 opening targets of the day/night walks plus the NPC, gate and gather beats this run plays, not all 18 villagers. In the walks the camp, PondGate and TrailGate count as reached by proximity and are not operated.
- Tournament consent is shown by the marshal visit, the bed receipts for party 0-2 and bracket entry; the run prints no explicit three-of-five selection line.
- The two-peer opening witness (PR174) predates the F01 road rebuild; road layout comes from authored config, not the world seed.
- The integrated run is on main `e35e2611`; `tb/cards` then merged main `94e59c48` before landing.
- Composite card: this run plus the F01 feeders. Independent strict re-check: `RECHECK_M1.md`, VERDICT: MET.

**Not in M1's scope, found by the same route:** past the tournament, the South Bridge guardian now fails
on main (see `../m2/BRIDGE_GUARDIAN_REGRESSION.md`). The bridge crossing is M2/F02, and F01#4's
"opening-to-bridge" witness ends at the bridge objective.

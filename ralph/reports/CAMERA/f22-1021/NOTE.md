# Camera lane: F22#4 later-chapter named fights (21 Oct 2026)

Assigned by the coordinator: Nerissa (Tidewake), Veyra (Cloudreach), Captain Marrow/Dynamo (Stormwood). Meadows relay fights stay with the Fights lane.

## Nerissa: Channel Cycle / Pressure Rise (BOSSES §4.11), built OFF (90bfebe62)
Her distinct pattern had no runtime (combat.json carried only a `mechanic` row). Built as specified: Channel Cycle 1.2/0.8/1.6 s (Cannonback, Mirejaw), Pressure Rise 1.0/0.8/1.2 s alternating (Riverdrake), none for Riptusk; 10% max HP once per wave; full-tell exit test at 5.6 m/s; no wave over a creature tell, an overlapped wave strikes nobody; only creatures. Host/battle-owner authoritative, hits through the encounter's `host_deliver_enemy_hit`, lane snapshots over WaterVeilfallTransport, no durable state. Unit tests: `test_water_nerissa_channels.gd` 8 tests, 30 assertions, 0 failed.

### C2 (`godot --headless --path . --fixed-fps 60 --script tests/smoke_water_named_c2c3.gd -- --seeds=24 --case=water_trainer_nerissa [--nerissa-channels] --json=<out>`, on 90bfebe62)
Top-fight C2 (ACCEPTANCE): reader win ≥ 75%, masher lead faints every run, reader median party cost ≤ 55% of the masher's, no single hit ≥ 0.50.

| Starter | Sweeps | Reader win | Party cost reader / masher (ratio) | Masher lead faint | Max hit |
|---|---|---|---|---|---|
| terrapup | off | 1.00 | 0.118 / 0.838 (0.14) | 1.00 | 0.236 |
| terrapup | **on** | 1.00 | 0.412 / 0.879 (0.47) | 1.00 | 0.236 |
| ripplet | off | 1.00 | 0.215 / 0.777 (0.28) | 1.00 | 0.236 |
| ripplet | **on** | 1.00 | 0.287 / 0.785 (0.37) | 1.00 | 0.236 |
| galewisp | off | 1.00 | 0.243 / 0.713 (0.34) | 1.00 | 0.236 |
| galewisp | **on** | 1.00 | 0.325 / 0.783 (0.42) | 1.00 | 0.236 |

**C2 PASS with the sweeps on**, all three starters, 144 runs, 0 errors (rows: `RUN_c2_nerissa_*.txt`). Sweeps per run ≈ 24–26 waves; ≈ 3 strike (most overlap a creature tell and, by the spec's no-forced-combo rule, strike nobody); the exit test exempted none on the flat fixture. The in-world three-judge round is next; the flag stays OFF until it passes.

# F15#2 support: Cloudreach return-route A7 gaps (Tidewake SHARED-FILE REQUEST, #330)

`tests/test_tidewake_return_cadence.gd` walks the measured Stormwood → Meadows return at walk speed,
with every aftermath unlock held. It found two Cloudreach stretches with no live offer for longer
than the A7 limit of 120 s:

| Gap on main | Between | Midpoint | New pair on the route core |
|---|---|---|---|
| 156 s | `upper_summit_road_01` → `upper_plateau_circuit_02` | (-451, 4644) | `road_visibility_upper_plateau_circuit_05` (-450.98, 876.23, 4643.93) |
| 151 s | `upper_plateau_circuit_01` → `windscar_counterweight_pass_13` | (-760, 4035) | `road_visibility_upper_plateau_circuit_06` (-759.87, 766.16, 4035.33) |

Both pairs follow the F07 cadence-pair contract:
- native Upper table, gated by `cloudreach_upper_route_unlocked`;
- count 2, radius 3;
- on the authored `upper_plateau_circuit` polyline core, at its interpolated height;
- not on the counterweight pass;
- not on the arch bridge span (segment 1).

`test_cloudreach_route_cadence`'s pinned pair count is now 13 (11 F07 pairs + these 2).

## Results (branch)
- **Tidewake return test:** `TIDEWAKE RETURN: known-open interval resolved, delete its KNOWN_OPEN row` is printed for both Cloudreach rows.
- **Unit tests:** `cloudreach_route_cadence`, `cloudreach_route_ledger`, `cloudreach_encounters`, `road_creature_visibility` and `tidewake_return_cadence` ran 32 tests with 5245 assertions and 0 failed (`tests_branch.txt`).
- **Runtime support:** `tests/probe_cloudreach_wild_site_support.gd` spawned both pairs for every species pair on the runtime-resolved ground (`failed_sites=0`, `runtime_support.txt`).

Tidewake owns the `KNOWN_OPEN` rows in its test and should delete the two Cloudreach rows.

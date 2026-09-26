# F15#2: the measured physical return, and A7 on it

**Criterion** (Acceptance Board F15#2; ACCEPTANCE §6.1 F15 and T3): "follow the measured physical return without an A7 empty interval". WORLD §6.5 fixes the route:
- First Shore's Stormwood passage;
- Stormwood's Cloudreach return gate;
- Cloudreach's Meadows return gate;
- Grandpa's home.

No new gate, ferry or teleport.

**Verdict: PARTIAL.** The return is now measured end to end.
- **Water (Tidewake-owned):** passes A7 after one placement fix.
- **Stormwood:** passes.
- **Cloudreach:** two gaps remain.
- **Meadows:** two gaps remain, both on the quarry haul road shortcut.

The Cloudreach and Meadows gaps are in data other lanes own, so each has a SHARED-FILE REQUEST on the Tidewake PR. This is a **data-level** measurement, the same method as `tests/test_cloudreach_route_cadence.gd`. It is not a walked or earned continuous witness; that remains separate (F13#0).

Test: `tests/test_tidewake_return_cadence.gd`, auto-discovered by `run_tests.gd`. Run output: `RUN.txt`.

## Method
1. **Route per realm, return direction:**
   - **Water:** the Veilfall passage exit, then each island's authored main spine reversed (`water_world.json` `land_routes`, main_path) and each sheltered swim reversed (`water_routes`), then 12 m to `entry_anchors.return_to_stormwood`.
   - **Stormwood:** shortest path over `stormwood_world.json` `routes`, with every unlock held after the ending, from the Water deck to `transition_points.cloudreach_return`. Spur and approach ends authored beside a road are joined to it. The Stormheart deck ramps are scene geometry and are not in the route data, so the straight drop to the deepwood road's end stands in for them.
   - **Cloudreach:** shortest path over `ground` routes in `cloudreach_world.json`, from `stormwood_return` to `meadows_return`. It joins only at exact shared vertices, as the Cloudreach harness does, because the cliff levels overlap in plan.
   - **Meadows:** shortest path over the trail bands, loops, the quarry haul road, `storm_road` and the village streets, from `meadows_cloudreach_gate_return` to Grandpa's door (`paths.village_topology.home_door`).
2. **Speeds are on foot:** walk 5.0 m/s (`movement.json`) and swim 3.8 m/s (`water_swimming.json`). A gap measured here cannot be hidden by a mount or by sprinting.
3. **What counts on a return journey.** ACCEPTANCE A7 says "repeated scenery does not reset the clock", so only sources that are live again count. Each source counts once across the whole return, at its first offer within its prompt radius.
   - **return_live** (the verdict):
     - ordinary wild sites, which WORLD §2 repopulates after two 600 s world days once every player has left the region (true for every realm crossed hours earlier);
     - NPCs with a line that is new after the ending. Every Water NPC has a `water_currents_restored` branch. Stormwood has `<id>_post_storm`: the player left Stormwood from the Dynamo deck, so these are unheard. Cloudreach has `<name>_after_restoration`: the player left from the summit straight after Veyra;
     - camps and rest points;
     - Cloudreach resource nodes with `world_day_regrow`;
     - the gates themselves.
   - **Never counted:** pickups, trainers, named fights, alphas, quest prompts and permanent harvests. `harvest_node.gd::_deactivate` frees a gathered Water or Meadows node for good.
   - **no_respawn:** the same list without any wild body. It is reported, not asserted: every realm fails it by a wide margin (for example, 2,034 s of Meadows trail with only Grandpa at the end). WORLD §2's "must still clear with no respawn" is a supply-ledger rule, not an A7 rule.
4. **Loading** between realms is a load, not travel, and is off the clock (ACCEPTANCE §7 times loading separately).

## Results (return_live, walking; head of `tb/tidewake-f15-return-cadence`)

| Realm | Walk m | Swim m | Time | A7 |
|---|---|---|---|---|
| Water | 5,154 | 1,986 | 25.9 min | PASS (worst 106 s) after the Rowan fix |
| Stormwood | 6,542 | — | 21.8 min | PASS (worst 79 s) |
| Stormwood, all arches lit | 2,290 | — | 7.6 min | PASS (worst 44 s) |
| Cloudreach | 9,527 | — | 31.8 min | **2 gaps** |
| Meadows, via the haul road | 10,173 | — | 33.9 min | **2 gaps** (both on the haul road) |
| Meadows, band trail | 11,321 | — | 37.7 min | PASS |
| **Whole return** | | | **113.4 min** (99.2 with arches) | **4 gaps** |

**Pacing:**
- At walking pace the whole return is about 1 h 53 min. That is 31.4 km on foot plus 2.0 km swimming, larger than WORLD §6.5's rough 19 km estimate for the three return realms, and it excludes the Stormheart ramps.
- Riding in the Meadows (10 m/s) and Cloudreach, or flying in bursts, roughly halves those two realms.

WORLD says pacing remains unaccepted, and this measurement agrees.

## The four open gaps (all outside Tidewake)

| Gap | Where (realm plan metres) | Proposal |
|---|---|---|
| 156 s, upper summit road → plateau circuit | Cloudreach, midpoint (-451, 4644) | One F07-style `road_visibility_` wild pair on the return line near the midpoint, or an existing prompt moved onto it. Route data is Cloudreach-owned. |
| 151 s, plateau circuit → counterweight pass | Cloudreach, midpoint (-760, 4035) | The same. |
| 133 s, quarry haul road, upper half | Meadows, midpoint (316, 1535) | The haul road (a one-way shortcut toward the village) has no beat. Pace it with a road pair or a haul-road landmark prompt, or accept the band trail (no gap, +3.8 min) as the return. |
| 129 s, quarry haul road, village half | Meadows, midpoint (69, 490) | The same. |

`KNOWN_OPEN` in the test lists these four. A fix in those realms makes the gap disappear and prints "delete its KNOWN_OPEN row"; it never turns this test red. A new gap anywhere on the return fails the test.

## The Water fix
- **The gap:** a 151 s stretch from the Brine Steps camp to the Stormwood gate. It crossed the whole Reedhaven spine and two swims with no live offer.
- **The move:** Pierwright Rowan, whose post-restoration line is new on the return, stood 9.6 m off the spine at its midpoint, outside his 4.2 m prompt. He now stands 2.5 m beside the spine at the same point.
  - New position: world (-13.34, 468.56), about 2° and dry on the analytic field; the old spot was 17°.
  - The change is in `data/config/water_characters.json`, with `_why_offset` recorded.
  - Result: the stretch splits into 71 s and 80 s.
- **Negative control:** `test_water_check_has_teeth` removes Rowan's offer and requires the 151 s gap ending at the gate to return.

## Limits
- This is data-level, not walked. The Water spines are 7-point planning polylines. Stormwood omits the deck ramps, and the Meadows ferry has no points and no runtime, so it is excluded.
- An offer counts within its prompt or engage radius of the route centreline. A body standing 12 m off a path, visible but not in range, does not count. This matches the Cloudreach cadence test.
- Whether a player hears the Stormwood and Cloudreach aftermath lines for the first time on the return is argued from where each chapter ends (above), not traced from a save.

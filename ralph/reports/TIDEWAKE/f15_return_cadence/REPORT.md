# F15#2: the measured physical return, and A7 on it

**Update (cf80ad62): Verdict MET, data-level.** The last two Meadows gaps (quarry haul road, 138 s and 132 s) are closed by two owner-approved roadside pairs, band1 order 1924 and band2 order 2923, 5.5 m off `quarry_haul_road`. The Cloudreach gaps were closed earlier on main by the Cloudreach lane. `KNOWN_OPEN` is now empty, so any interval over 120 s fails the test. `RUN.txt` (refreshed at cf80ad62): 5 tests, 0 failed; live-respawn return `over_a7: []` with arches off (114.2 min), on (100.0 min) and without the haul road (118.0 min); the worst Water gap is 114 s.

**Disclosures:**
- Data-level: shortest path over authored polylines at constant walk 5.0 m/s and swim 3.8 m/s. No physical walk, terrain, combat, detours or co-op. Realm loads are excluded from the clock.
- The Stormheart deck ramps are a straight line; Stormwood arches are excluded from the gating run; Cloudreach uses ground routes only.
- A wild within engage range counts as an offer and is assumed present. Night-, rain-, alpha- and once-only sources never count (daytime, clear weather). The two new sites were not probed in engine.
- Meadows pacing on the return depends on respawned wilds (encounter_director 300 s respawn). The strict no-respawn variant is a report only and shows large gaps (Meadows 2034 s).

The section below is the earlier PARTIAL report, kept for history.

---


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
   - **Water:** the Veilfall passage exit, then each island's authored main spine reversed (`water_world.json` `land_routes`, main_path, safe position to safe position) and each sheltered swim reversed (`water_routes`, shore position to shore position).
     - Each short dock leg between an anchor's safe and shore positions is walked.
     - The route ends with the 21.6 m walk from `entry_anchors.from_stormwood` to `return_to_stormwood`.
   - **Stormwood:** shortest path over `stormwood_world.json` `routes`, with every unlock held after the ending, from the Water deck to `transition_points.cloudreach_return`.
     - Spur and approach ends authored beside a road are joined to it; the chosen path uses none of those joins.
     - The Stormheart deck ramps are scene geometry and not in the route data, so the straight drop to the deepwood road's end stands in for them.
   - **Cloudreach:** shortest path over `ground` routes in `cloudreach_world.json`, from `stormwood_return` to `meadows_return`. It joins only at exact shared vertices, as the Cloudreach harness does, because the cliff levels overlap in plan.
   - **Meadows:** shortest path over the trail bands, loops, the quarry haul road, `storm_road` and the village streets, from `meadows_cloudreach_gate_return` to Grandpa's door (`paths.village_topology.home_door`).
2. **Speeds are on foot:** walk 5.0 m/s (`movement.json`) and swim 3.8 m/s (`water_swimming.json`). A gap measured here cannot be hidden by a mount or by sprinting.
3. **What counts on a return journey.** ACCEPTANCE A7 says "repeated scenery does not reset the clock", so only sources that are live again count. Each source counts once across the whole return, at its first offer within its prompt radius.
   - **return_live** (the verdict):
     - **Ordinary wild sites.** The built behaviour repopulates a defeated site on a session timer: `wild_respawn_seconds` is 240 s in Water and 180 s in Cloudreach (`water_encounter_director.gd`, `cloudreach_encounter_director.gd`). WORLD §2's two-world-day rule is the stricter design target.
     - **Excluded wilds:** Meadows spawns limited to night or rain (`time`/`weather`) never count, because they are not live on every return. Alphas never count either.
     - **NPCs with a line that is new after the ending**, within the 3.8 m `npc_body.gd` greet prompt:
       - every Water NPC has a `water_currents_restored` branch;
       - Stormwood has `<id>_post_storm` (`stormwood_chapter.gd`): the player left Stormwood from the Dynamo deck, so these are unheard;
       - Cloudreach has `<name>_after_restoration`, at the `position_when` it relocates to (Aila moves to the summit): the player left from the summit straight after Veyra.
     - Camps and rest points.
     - Cloudreach resource nodes with `world_day_regrow`.
     - The gates themselves.
   - **Never counted:** pickups, trainers, named fights, quest prompts and permanent harvests. `harvest_node.gd::_deactivate` frees a gathered Water or Meadows node for good.
   - **no_respawn:** the same list without any wild body. It is reported, not asserted: every realm fails it by a wide margin (for example, 2,034 s of Meadows trail with only Grandpa at the end). WORLD §2's "must still clear with no respawn" is a supply-ledger rule, not an A7 rule.
4. **Loading** between realms is a load, not travel, and is off the clock (ACCEPTANCE §7 times loading separately).

## Results (return_live, walking)

| Realm | Walk m | Swim m | Time | A7 |
|---|---|---|---|---|
| Water | 5,396 | 1,986 | 26.7 min | PASS (worst 114 s) after the Rowan fix |
| Stormwood | 6,542 | — | 21.8 min | PASS (worst 79 s) |
| Stormwood, all arches lit | 2,290 | — | 7.6 min | PASS (worst 44 s) |
| Cloudreach | 9,527 | — | 31.8 min | **2 gaps** |
| Meadows, via the haul road | 10,173 | — | 33.9 min | **2 gaps** (both on the haul road) |
| Meadows, band trail | 11,321 | — | 37.7 min | PASS |
| **Whole return** | | | **114.2 min** (100.0 with arches) | **4 gaps** |

**Pacing:**
- At walking pace the whole return is about 1 h 54 min. That is 31.6 km on foot plus 2.0 km swimming, larger than WORLD §6.5's rough 19 km estimate for the three return realms, and it excludes the Stormheart ramps.
- Riding or flying where the realm allows it (Meadows, Cloudreach) roughly halves those two realms.

WORLD says pacing remains unaccepted, and this measurement agrees.

## The four open gaps (all outside Tidewake)

| Gap | Where (realm plan metres) | Proposal |
|---|---|---|
| 156 s, upper summit road → plateau circuit | Cloudreach, midpoint (-451, 4644) | One F07-style `road_visibility_` wild pair on the return line near the midpoint, or an existing prompt moved onto it. Route data is Cloudreach-owned. |
| 151 s, plateau circuit → counterweight pass | Cloudreach, midpoint (-760, 4035) | The same. |
| 133 s, quarry haul road, upper half | Meadows, midpoint (316, 1535) | The haul road (a one-way shortcut toward the village) has no beat. Pace it, or accept the band trail (no gap, +3.8 min) as the return. |
| 138 s, quarry haul road, village half (daytime) | Meadows, midpoint (65, 469) | The same. At night a night-only spawn closes part of it; the verdict does not count that. |

`KNOWN_OPEN` in the test lists these four by realm and midpoint, matched within 200 m, not by the ids at their ends. So another lane's partial edit that shifts an end offer does not turn the test red. A fix that closes a gap prints its stale row. A gap anywhere else fails the test, and `test_known_open_match_rejects_an_unlisted_gap` pins that.

## The Water fix
- **The gap:** a 151 s stretch from the Brine Steps camp to the Stormwood gate. It crossed the whole Reedhaven spine and two swims with no live offer.
- **The move:** Pierwright Rowan, whose post-restoration line is new on the return, stood 9.6 m off the spine at its midpoint, outside his 3.8 m prompt. He now stands 2.5 m beside the spine at the same point.
  - New position: world (-13.34, 468.56). The analytic heightfield samples it as about 2° and dry; the old spot sampled 17°. It is 0.5 m outside the 4 m trail's edge.
  - The change is in `data/config/water_characters.json`, with `_why_offset` recorded.
  - With the dock legs walked, the stretch splits into 78 s and 85 s.
- **Negative control:** `test_water_check_has_teeth` removes Rowan's offer and requires the gap ending at the gate to exceed A7 again.
- **The Water margin is thin.** The worst remaining gap is 114 s, from Shellwatch wild_001 to Tovin, against the 120 s limit.

## Limits
- This is data-level, not walked. The Water spines are 7-point planning polylines. Stormwood omits the deck ramps. The Meadows ferry has no points and no runtime, so it is excluded.
- An offer counts within its prompt or engage radius of the route centreline. A body standing 12 m off a path, visible but not in range, does not count. This matches the Cloudreach cadence test.
- Whether a player hears the Stormwood and Cloudreach aftermath lines for the first time on the return is argued from where each chapter ends (above), not traced from a save.
- The late Water islands (Sluice Isle, Veilfall) are re-crossed minutes after the outward swim. Their wilds count under the built 240 s session timer, not under WORLD's two-world-day target.
- Rowan's standing spot has not been checked in engine for a scatter or collider clash.
- Independent code-blind review: **PASS**. Its six recommended accuracy fixes are applied: dock legs and the gate walk, the 3.8 m prompt, night and rain spawns, Aila's relocation, midpoint matching, and the respawn wording.

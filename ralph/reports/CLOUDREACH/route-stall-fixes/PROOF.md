# Cloudreach route-stall fixes from Cloudreach-B's root causes (#340) — unblocks Cloudreach-B

Base: `tb/cloudreach` with origin/main 0344cbb7 merged in.

| # | Root cause (#340) | Fix | Witness | main | branch |
|---|---|---|---|---|---|
| 1. Shrine-dais corner trap | Each `SkyPillar` was a 2.2 m **box** collider. At (1099.003, 1051.301, 2941.399), every move with an x component was swept into the dais top beside the box corner. That contact is never a wall, so neither step-up nor unwedge fired. The same box filled the Fly launch room. | `cloudreach_world.gd`: the drawn pillar keeps its box mesh, but it now collides as the inscribed **cylinder** (r 1.1, config `landmass.sky_pillar_collider_radius_m`), under the same `SkyPillar/Collision` name. | `tests/smoke_cloudreach_shrine_dais.gd` | FAIL: two box colliders; the launch room hits `SkyPillar/Collision`; the trainer never leaves (1099.002, 1051.301, 2941.399) | PASS: two cylinders; the launch room is clear; `_walk` reaches (1121, 1050, 2938.5) |
| 2. B2 `ravine_wind` | The corridor exemption keyed on the comment key `_why_road_visibility_0907`, and `ravine_wind` lacked it. | `cloudreach_encounter_director.gd`: `site_keeps_trainer_corridor_clear(site)` reads an explicit `trainer_corridor_clear` field. Every site that had the comment key now carries `true`, so behaviour is unchanged. `ravine_wind` and the other on-lane named pairs carry it too. | `test_cloudreach_route_blocker_rules.gd` + `smoke_cloudreach_route_blockers.gd` B2 | (see route-blockers/) | PASS: 0 walk-arounds, with `ravine_wind_0/_1` present |
| 3. B3 `roost_perches` | Its authored point (970, 1050, 3450) had no ground. The nearest-route fallback bound it 1.5 km away on the Voss road. | Re-authored on the High Perches court (900, 1020, 2715); every species pair is supported there (`site_searches.txt`). `resolve_wild_sites` (runtime) **fails closed** beyond 45 m (config `wild_site_max_resolution_m`, default 45). **Air patrols** are no longer re-grounded: re-grounding had pinned the chain-bridge patrols onto the deck walkway. | `smoke_cloudreach_wild_site_resolution.gd`, rules test, B3 walk | – | PASS: 102/104 sites resolve within 45 m (worst 15.7 m); the B3 walk has no `roost_perches` body on the road |
| 4. B1 shelf | Already fixed in 9dd91f05 (landed). | – | B1 walk | FAIL | PASS |

Re-authored so each site resolves within 45 m. Each is placed at the exact home the runtime already gave it, so play, the ledger and cadence are unchanged:
- `causeway_watch`: 184 m;
- `upper_scouts`: 147 m;
- `road_visibility_windscar_floor_loop_14`: 68 m.

**Known unresolved: they now fail closed in play; a design decision is open for each.**
- `road_visibility_broken_causeway_main_03`: no supported ground within 45 m of its composition point. The fallback had put it 17 m from the three-bells west hero approach, which its composition forbids.
- `road_visibility_windscar_floor_loop_15`: likewise. The fallback put it 7 m from the Aerie lesson dais, where its composition requires 90 m.

The visibility model and ledger read authored positions, so they are unchanged. An Air-patrol conversion needs the shared `test_road_creature_visibility` air-patrol rules to change.

**Unit tests:** `--only=test_cloudreach,road_creature_visibility,tidewake_return_cadence`: 279 tests, 18894 assertions, 0 failed.

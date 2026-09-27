# Cloudreach route blockers B1–B3 (Cloudreach-B, #294)

Base: main 51d6dc44. Walk probe: `tests/smoke_cloudreach_route_blockers.gd`. It runs on the production
scene with the real controller and the production encounter director. Wild sites spawn by proximity
and are not parked. The fixture: post-shrine flags, and the player placed once at each leg's start.
Every metre after that is stick input over collision (`_navigate`/`_walk`: a stall is less than
0.4 m of progress over 3 × 120 frames). A leg passes only if it reaches its target, has no failure,
and passes within 12 m of the blocker point.

| # | Blocker | Cause | Fix |
|---|---|---|---|
| B1 | (-128.4, 205.5, 704.5), arrival → `lower_west_anchor` | `_build_embedded_rock_shelves` gives a drawn-only `RockShoulder` spur up to three *colliding* `VegetatedGeologicalShelf`s. It never checked roads, so shelf 2 of `LowerOverlookLoopCliffShoulders/Ridge002RockShoulder38` overhung another route's ribbon. | `cloudreach_world.gd`: a colliding embedded shelf is not built (nor its tree and cover) when it would stand in any ground route's walking space. That means within the ribbon plus the shelf radius (+1 m), and overlapping 0.3–3.2 m (`ROUTE_HEADROOM_M`) above the road. 7 shelves realm-wide. |
| B2 | (223.6, 556.5, 3331.9), aerie → counterweight | The `ravine_wind` wild pair stands on the floor-loop ribbon. The runtime re-grounds the six original named sites onto the nearest ribbon; their road clearance is −1 to −3 m. Unlike the ROAD CP-2 pairs, they had no trainer-corridor exception. | `cloudreach_encounters.json`: all six named sites (`lower_cliff_foragers`, `causeway_watch`, `ravine_wind`, `roost_perches`, `upper_scouts`, `summit_watch`) get the existing ROAD CP-2 exception (`keep_trainer_corridor_clear`). Only the trainer passes through; terrain, attacks and every other body still collide. Position, table, count and radius are unchanged, so the route ledger, cadence and visibility model are unchanged. |
| B3 | (500.5, 986.4, 4890.0), Upper Summit road toward Voss | The same cause with the `roost_perches` pair, which the runtime re-grounds onto `upper_summit_road`. | Same as B2. |

Why not move the named sites off the road? Only `lower_cliff_foragers` (21 m clear) and
`causeway_watch` (10 m) have supported off-road ground nearby. The other four have none within 300 m
of their resolved point, because shoulders register no analytic surface. The two High Roost/upper
crowns that exist are far from their current legs. Moving any site would also change which pairs the
F07#4 ledger credits (within 12 m of the walked path). See `named_sites_road_clearance.txt`.

## Results
| | main 51d6dc44 | branch (run 1) | branch (run 2) |
|---|---|---|---|
| B1 | **FAIL**: walking stalled at (-129.1, 205.6, 704.4) | PASS, nearest 0.4 m, 1019.5 m walked | PASS, 0.4 m |
| B2 | passed this run (nondeterministic; Cloudreach-B hit it on 2 of 3) | PASS, nearest 0.2 m, `ravine_wind_0/_1` within 15 m | PASS, same |
| B3 | **FAIL**: stalled against `roost_perches_0` after mobile-obstacle detours at (502.5, 985.5, 4888.2) | PASS, nearest 0.0 m, `roost_perches_0/_1` within 15 m | PASS, same |
| `b1_shelf2_present` | – | false | false |

Regressions:
- `smoke_cloudreach_ground_truth` PASS.
- `run_tests.gd --only=test_cloudreach`: 260 tests, 18242 assertions, 0 failed.

## Review round 1 (APPROVE WITH NITS) applied
- **Probe hardened.** A leg now also fails on any `mobile_obstacle_detour*` walk-around; that is how a
  walker can squeeze past a pair on main. B2 and B3 also fail unless their named pair
  (`ravine_wind_*`, `roost_perches_*`) actually stood within 15 m of the blocker. The run fails
  unless B1's `VegetatedGeologicalShelf2` is gone.
  - Branch run 3 (`branch_run3_hardened.txt`): PASS. 0 detours on every leg, the named pairs were
    present, and the shelf is absent.
- **Headroom moved to config.** It is now `landmass.route_shelf_headroom_m` (3.2) in `cloudreach_visual.json`.
- **Honest note on B2 for main.** In the one main run, the walker passed B2 with no walk-around, so
  the pair was not on its line that time. Cloudreach-B hit B2 on 2 of 3 runs. Main's B3 failure did
  involve 4 walk-arounds of `roost_perches_0` before the stall.
- **Known limits, inherited from the ROAD CP-2 exception.** Only the local trainer body is exempt. A
  piloted or ally creature body still collides with a pair. Visual-only shelves (i ≥ 3) and landing
  pad caps are not checked, because they cannot block a road.

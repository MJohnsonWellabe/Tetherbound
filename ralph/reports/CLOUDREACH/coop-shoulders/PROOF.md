# Co-op keeps Cloudreach route shoulders (owner ruling 2026-09-26: co-op matches single player)

Before: `cloudreach_world.gd::_build_routes` skipped `_build_route_shoulders` whenever the shell
build was slicing (every live multi-peer crossing and every host shell), because each shoulder
section awaited the RefCounted `_shell_build.breathe()` and Godot 4.7 could lose that deeply nested
continuation. Co-op players therefore walked a different Cloudreach: 7 m road ribbons with no
geological shoulders (no walkable ground beside the road, different silhouettes).

After: shoulders always build; each section yields through the world Node's own `_build_breathe()`
(the same world-owned suspension every other Cloudreach build loop uses to avoid that bug).
Solo is unchanged (`_build_breathe()` releases no frames when not slicing).

Proof: `tests/smoke_cloudreach_coop_shoulders.gd` builds the production world solo, then as a live
crossing (Game.session stand-in reporting multi-peer host -> `shell_build_budget.gd` slices at the
crossing budget) and compares every `*CliffShoulders/Ridge*` node and its walkable Collision.

| | solo | live on main 32bd33079 | live on branch |
|---|---|---|---|
| shoulder ridge nodes | 720 | **0** | **720** (same per-route counts) |
| walkable shoulder collisions | 218 | 0 | 218 |
| build completed | yes | yes (270 yields, 22.9 s) | yes (2760 yields, 95.8 s) |
| worst held slice | – | 356 ms | 1461 ms (37 indivisible slices, each given a heartbeat window) |
| smoke verdict | – | FAIL (exit 1) | PASS (exit 0, 0 SCRIPT ERROR) |

Cost, stated plainly: the sliced crossing build is ~73 s longer (routes step 0.7 s -> 56.1 s) and its
worst single held frame rises to 1.46 s; both measured on main's look pass (the grid fix in PR #311
removes ~140 s from the look). Unit: 258 `test_cloudreach*` tests, 0 failed.
Raw: `main_32bd33079.txt`, `branch.txt`.

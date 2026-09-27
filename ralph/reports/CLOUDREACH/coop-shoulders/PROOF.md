# Co-op keeps Cloudreach route shoulders (owner ruling 2026-09-26: co-op matches single player)

**Before.** `cloudreach_world.gd::_build_routes` skipped `_build_route_shoulders` whenever the shell
build was slicing: every live multi-peer crossing and every host shell. The reason was that each
shoulder section awaited the RefCounted `_shell_build.breathe()`, and Godot 4.7 could lose that
deeply nested continuation. As a result, co-op players walked a different Cloudreach: 7 m road
ribbons, with no geological shoulders beside the road and different silhouettes.

**After.**
- A live crossing builds the shoulders exactly as solo does.
- The sections, and now each ridge's stations, yield through the world Node's own
  `_build_breathe()`. Every other Cloudreach build loop already uses this world-owned suspension to
  avoid the bug.
- A host shell (`simulation_only`) still defers the shoulders, because nobody sees it. What the host
  simulates in it (wilds and trainers) stands on the analytic surfaces the shoulders never register.
  Building them there would run about 20 s of ridge work on a host who is playing in another realm.
- Solo is unchanged: `_build_breathe()` releases no frames when the build is not slicing.

**Why per-station yields.** `ridge_profile_solo.txt` covers 43 ridge sections:
- the station loop takes 20.2 s of the 23 s;
- each ridge holds 250–1,630 ms;
- the mesh and trimesh tail takes 210 ms or less.

In a live crossing, every slice of 250 ms or more costs a 65-frame heartbeat payback. The first
version of this change, which yielded per section only, took 95.8 s with 37 paybacks. Yielding per
station (about 30 ms each) removes all of them.

## Proof: `tests/smoke_cloudreach_coop_shoulders.gd`
The smoke builds the production world three ways:
1. **solo**;
2. **live**: a `Game.session` stand-in that reports a multi-peer host, so `shell_build_budget.gd`
   slices at the 100 ms crossing budget;
3. **host shell**: `simulation_only`, 8 ms budget.

It compares every `*CliffShoulders/Ridge*` node per route. It also takes a sha256 over each ridge's
name, global transform and trimesh collision faces.

| | solo | live, main 32bd33079 | live, branch | shell, main | shell, branch |
|---|---|---|---|---|---|
| ridge nodes / walkable collisions | 720 / 218 | **0 / 0** | **720 / 218** | 0 / 0 | 0 / 0 |
| faces sha256 | `54fc5dea…` on both main and branch (solo is byte-identical) | empty | `54fc5dea…` = solo | empty | empty |
| wall time / yields | – | 24.1 s / 272 | 60.6 s / 600 | 2.7 s / 128 | 2.6 s / 128 |
| worst held slice (step) | – | 289 ms (materials) | 343 ms (materials) | 275 ms | 258 ms |
| heartbeat paybacks | – | 1 | 1 | 1 | 1 |
| verdict | | **FAIL** | **PASS** (0 SCRIPT ERROR) | | |

**Cost, stated plainly.** A co-op crossing into Cloudreach builds for about 36 s longer
(24.1 s → 60.6 s), with no longer held frame. This was measured with main's look pass; the grid fix
in #311 removes about 140 s of look time.

`realm_transition.gd` `TIMEOUT_MS` is 120 s, so 60.6 s leaves about 59 s of margin on this box.
The two-peer net smokes (`smoke_net_cloudreach_riding`, `smoke_net_split_realms`) are the
integration check; they run in the full tier.

**Unit tests:** 258 `test_cloudreach*` tests, 0 failed.
Raw files: `main_32bd33079.txt`, `branch.txt`, `ridge_profile_solo.txt`.

## Folded onto `tb/cloudreach` (one PR per lane), after re-review APPROVE WITH NITS
- **Two-peer net smokes on 0909d164** (the reviewer's merge condition):
  - `smoke_net_cloudreach_riding`: 137 assertions, 0 failures, ALL CHECKS PASSED;
  - `smoke_net_split_realms`: ALL CHECKS PASSED, both peers exited cleanly.

  Files: `net_smokes_0909d164.txt`, `net_*_SUMMARY.md`.
- **Re-run on the combined branch** (main 51d6dc44 plus route blockers, `branch_on_main_51d6dc44.txt`): PASS.
  - Solo and live both have 720 ridges and 218 walkable collisions, with the same faces hash `54fc5dea…`. The shell defers.
  - The live build took 88.7 s with 596 yields, and its worst held slice was 421 ms, with 1 heartbeat payback. On the older base it took 60.6 s. This base carries newer realm content; X05 measured roughly 110 s for local Cloudreach `enter_realm` builds and about 80 s on GitHub runners.
  - The realm transition timeout is 120 s. A slower machine could approach it, so it is worth watching in the full-tier net jobs.
- **Known mismatch, recorded for STATE:** host shells still defer the shoulders. A wild or trainer the host simulates in a shell stands on analytic ground, while the guest's own world has shoulders. This mismatch predates the change.

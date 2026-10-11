
## Round 4: Option A fix and game-time caps (coordinator-approved)
- **Game fix (option A):** `stormwood_harvest_runtime.site_gathered(id)` counts a site when it has the exact legacy `harvest_node:order:<id>` flag, OR its world stock revision is ≥ 1. It is used by `first_stormglass_gathered` and `claimed_crown_glass`. The coordinator's merge adds a missing-Game guard.
- **Approved test changes (same predicate, still exact):**
  - the Crown build helper's receipt checks;
  - the prefix helper's `_harvest_site` and `_harvest_charged_node` receipt checks.
- **Game-time caps:** road/Crown fights (180 s), trainer sequences (300 s) and the Marrow attempt (900 s) now count physics steps instead of wall time. One step is 1/60 s of game time at both the 8x/480 Hz and 1x/60 Hz clocks. Assertions are unchanged.
- **Runner:** the scratch Load copy moved to `user://` (the game rewrote `world.json` after cleanup).
- **Survey of objectives keyed on `harvest_node` flags for renewable sites:**
  - Stormwood: two sites, both fixed.
  - Water: the `tidal_cradle:harvest:007` chain seam is `existing_world_pickup_policy`, so it is not renewable.
  - Meadows/Cloudreach: none.
  - `tests/helpers/water_reedhaven_segment.gd:202` checks Water receipts (Tidewake lane).

Piece 01 progress (`01i`): first Stormglass, pair A gathered/relit/travelled, route pickup, Maren won, Verge rod disabled.

## Finding: frame cost after Maren's fight (not a leak)
The coordinator's suspects were teardown leaks, a re-spawn loop, or a per-frame signal. The monitor (`perf_monitor_01k.log`) samples every 15 s and rules out a leak:
- node count stays at ~73.9–74.0k, objects ~117.4–117.8k, orphans 0;
- the only churn is the combat set (`combat_arena.gd`, `throw_aim.gd`, `tether_command_input.gd`, `move_effect.gd`, wild bodies), which is created and freed with each fight.

`rod_perf_probe.gd` (diagnostic, flag writes allowed because it is not evidence) holds about 9 fps at the Verge road before and after `trainer:officer_maren_verge_rod:defeated` and `rod_verge_disabled`, with an identical set of processing nodes. So the state change is not the cause.

The sim/wall drop comes from back-to-back road-wild combat on the Ash road. Combat frames run at 1–2 fps on this host (process 150–600 ms, physics 20–300 ms), against 6–9 fps out of combat. The earlier "fast" run had not yet met those fights.

No smallest-cause fix exists. Combat frame cost on headless llvm/dummy rendering is a performance question for on-device measurement (RD-25 ROG Ally test), not an evidence-phase change.

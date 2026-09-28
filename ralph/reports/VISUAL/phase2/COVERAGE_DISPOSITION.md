# Phase 2 capture coverage disposition

The per-biome `manifest.csv` files are the frame inventory; `coverage_audit.json` checks their counts, pinned commits, reproduction commands, render paths, and contact-sheet tiles. Individual full-resolution frames have been removed from the current tree; see `COMPACT_EVIDENCE.md` for the page and tile mapping. Each category in each biome has paginated contact sheets. Capture fixtures and their limits are disclosed in the copied `systems/engine_manifest_*.json` files. Unsuccessful attempts have no frame row.

| Checklist row | Meadows | Tidewake | Cloudreach | Stormwood |
| --- | --- | --- | --- | --- |
| Named locations | Approach and close views | Approach and close views | Approach and close views | Approach and close views |
| Route and terrain | Main and off-route seeded samples | Main and off-route seeded samples | Main and off-route seeded samples | Main and off-route seeded samples |
| Creatures | Every indexed species has six core poses and a shiny view; available alpha views | Same | Same | Same |
| Characters | Post and dialogue views; defeated views for combat characters | Same | Same | Same |
| World items | Ground-level pickup, harvest, chest/cache, and prop family views | Same | Same | Same |
| Time and weather | Day, dusk, night | Day, dusk, night; high/low currents | Day, dusk, night | Day, dusk, night; Calm, Building, Break, Fading |
| Systems | Fly, ride, catch, fight, camp, bed, build, craft | Fly, ride, surface swim/current, catch, fight, camp, bed, craft | Fly/perch, ride, catch, fight, camp, bed, build, craft | Fixture Fly, catch, fight, camp, bed, build, craft |
| UI | Exploration and fight HUD, map, creatures, backpack, quick bindings, journal, dialogue, menus, 1920×1080 | Same | Same | Same |

## Current-build system boundaries

- **Meadows swimming:** the scene's pond and river are wading/hazard geometry. `scripts/world/water.gd` states that no swimming system takes over deep water; the player's `swim_controller` is unset outside Tidewake. A water view would not be evidence of swimming.
- **Tidewake building:** the Water world has authored camps, creature beds, and workbenches, captured at three sites. It has no `BuildPlacer` node. The attempted placed-building capture is recorded in `tidewake/systems/open_capture_attempts.json`; no building frame was indexed.
- **Cloudreach swimming:** its player has no swim controller or authored swim surface. Flying and landing/perch are captured here.
- **Cloudreach upper-route pickups:** five authored potion, candy, mushroom, and TM pickups required upper-route progression flags. Their earlier empty or unisolated frames were replaced with nearby production-camera angles using flags set only in memory. Two additional TM art/scale frames use temporary item staging on clear terrain; they do not prove authored placement or accessibility. The frame manifest records the pinned render commit and reproduction command for each replacement and staged frame. `coverage_audit.json` still lists 20 planned IDs from discarded multi-angle probes; these are superseded camera candidates, not missing files or 20 separate pickup families.
- **Stormwood riding and swimming:** its world does not instantiate a `RidingController` or swim controller. Those actions cannot be captured from its current production scene.
- **Stormwood story rewards:** Rootgate Release Key, Dynamo Core Key, and Spark of Stormwood are event grants (`runtime_kind: story_reward`), not loose ground pickups. Their earlier empty-ground survey rows were removed from the frame manifest. The 17 chapter-gated ordinary pickup families were reshot with Crown/Rootgate flags in memory and their actual `ItemCachePickup` visuals.
- **Stormwood Fly reachability:** the world registers a `stormwood_canopy` flight restriction covering the realm, gated by `stormwood:canopy_flight_forbidden`; no production code sets that flag. The unmodified attempt was denied, recorded in the GPU job `phase2-stormwood-flight-search`. Three indexed visual frames use an explicitly disclosed in-memory flag and elevated fixture stand. They show the existing carrier art and real Fly inputs, not a reachable campaign route.
- **Dive and non-Cloudreach perch:** `scripts/player/swim_state.gd` has Land, Human, Mounted, and CombatPaused modes, with no dive state. Tidewake surface and current views are indexed. The authored flying perch is in Cloudreach; other realms have no equivalent perch sequence in this build.

The catalog scores visual defects in captured states. The absent or progression-sealed systems above are coverage limits, not inferred visual defects. Open visual questions remain in `catalog.csv` notes.

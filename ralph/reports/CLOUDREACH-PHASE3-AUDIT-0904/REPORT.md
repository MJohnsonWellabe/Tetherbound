# Cloudreach Phase 3 systems audit — 2026-09-04

This is a read-only architecture handoff for the next implementation agent. It identifies reuse
seams and multi-realm risks before Cloudreach actors/content are wired. It is not evidence that
Phase 3 runtime content exists.

## Recommended production shape

Build one thin Cloudreach content composer under `cloudreach_world.gd`, driven by realm-local
data, while reusing existing actors and UI. Do not clone the complete Meadows world script.

Use the canonical runtime realm id `cloudreach` and namespace new identities as
`cloudreach:<kind>:<id>` (including progression, one-time wilds, pickups, and persistent authored
objects). The new `data/config/cloudreach_chapter.json` is the tested high-level content contract;
split it into runtime catalogues only when the consuming systems exist.

## Critical seams before authoring live content

1. **Realm-aware persistence.** Maps, death satchels, buildings/home lookup, harvest records, and
   wild once-only identities are currently global/Meadows-shaped. Qualify positional records by
   `Game.current_realm`, migrate legacy records to Meadows, and restore only the active realm.
2. **Vertical placement.** Cloudreach layers can overlap in X/Z. Existing NPC, trainer, resource,
   and rest placers mostly accept `[x,z]` and call `ground_height_at()`, which returns the highest
   surface. Cloudreach schemas must accept authored `[x,y,z]`; retain Meadows ground sampling as
   fallback.
3. **Dialogue effects.** `DialogueRunner` loads hardcoded Meadows files and Cloudreach has no
   `SequenceDirector`. Add a dialogue manifest/registry and extract the reusable `flag:`, `give:`,
   `battle:`, `shop:`, and heal operations into a generic effect router. Do not mount the Meadows
   opening state machine in Cloudreach.
4. **Injected catalogues.** `TrainerNPC`, `EncounterDirector`, `ChapterCurve`, `WorldAudio`, and
   several loaders hardcode Meadows config or Z bands. Add realm/catalogue injection with Meadows
   compatibility wrappers. Resolve Cloudreach regions by explicit region id/3D position, not Z.
5. **Map isolation.** The current `MapState` owns one static Meadows grid/bounds set. Convert it to
   a realm-switching store with realm-keyed fog, landmarks, regions, and dynamic markers; migrate
   the legacy payload to `realms.meadows`; make minimap/tab map/baker use active-realm bounds and
   `map_<realm>.png`.

## Existing systems to reuse

- `InteractionArbiter` + `Interactable` are already the correct single controller-first input
  path for NPCs, pickups, camps, shrines, and gates.
- `VillageNPCs.build(player, config_path)` already accepts alternate NPC data and supports
  conditional placement/greetings plus installed humanoid profiles.
- `QuestLog` and flat durable progression flags can express the main/local Cloudreach feed;
  append Cloudreach objectives and use consecutive entries/count flags rather than a new graph.
- The underlying trainer battle flow and wild spawn loop are reusable after catalogue/region
  injection. Build the final boss as a separate authored climax controller that calls the shared
  fight system; do not make it merely a large generic trainer.
- `ItemCachePickup` needs a stable placement `pickup_id` separate from `item_id`, plus count and
  authored 3D position. Otherwise two copies of an item share one persistence flag.
- `HarvestNode` needs a stable realm-qualified id, 3D placement, and an optional success hook so
  Cloudreach does not fire Meadows `HomeProgress` logic.
- `RestPoint`/`NightRest` are reusable after completion flags become caller-supplied and
  Cloudreach uses a non-overlapping bed-id namespace.
- `WorldAudio`/`WorldWeather` cores are reusable after config injection and a parent-world
  `audio_region_id_at(Vector3)` query. Cloudreach should mount the normal combat manager/HUD,
  encounter director, player death, dialogue effect router, world audio/weather, and look adapter.
- Existing `progression_restore` lifecycle is the right save/load hook, but the realm content
  owner must reconcile both directions: remove consumed children and respawn missing children.

## Recommended implementation order

1. Normalize the realm and persistence namespaces.
2. Make maps, deaths, buildings/home lookup, and positional restore records realm-aware.
3. Generalize ordered regional content loading with a Meadows wrapper.
4. Add dialogue manifest loading and the generic effect router.
5. Add authored 3D placement to NPCs, trainers, harvest nodes, pickups, and camps.
6. Inject trainer, spawn, and chapter-curve catalogues.
7. Wire the normal gameplay managers/UI/audio/weather into the Cloudreach scene.
8. Implement and prove Act I first.
9. Implement functional Fly, the objective transition, Sky Shrine, and grounded route release.
10. Add upper-region trainer/resource/side content.
11. Build the separate summit climax, rewards, aftermath, and Waterward reveal.
12. Test stable identities, bidirectional restore, vertical placement, realm map/death isolation,
    and the continuous Act I -> Fly -> shrine -> boss objective path.

The highest-risk failure is authoring apparently working actors before these seams. That would
allow Cloudreach flags to collide with Meadows, corrupt the Meadows fog grid, restore satchels or
buildings into the wrong realm, and place lower-cliff NPCs on the highest overlapping platform.

# Stormwood settlement runtime audit — 2026-09-07

Scope: read-only audit of the new `RodfolkSettlements` mount and focused
headless evidence. This is not a claim that settlement services, inhabitants,
or camp progression run in Stormwood.

## Mount and grounding

`StormwoodWorld` creates `RodfolkSettlements`, injects
`res://data/config/stormwood_settlements.json`, parents it below the Stormwood
world, and awaits its build at `scripts/world/stormwood_world.gd:96-101`.
The generic loader reads the injected path at `scripts/world/village.gd:42`.
It grounds every prefab through its parent world, including its footprint
corners, and places the result at ground minus 0.05 at
`scripts/world/village.gd:170-196`. `StormwoodWorld` answers that query with
its Stormwood heightfield at `scripts/world/stormwood_world.gd:40-44`. This is
a valid realm-local grounding chain; the mount happens after Stormwood Terrain3D
setup at `scripts/world/stormwood_world.gd:70-101`.

The Stormwood data includes fifteen structures, with the inn and cottage
requesting the existing `inn` and `cottage` interiors. The generic loader
creates those as children of the transformed building at
`scripts/world/village.gd:232-245`, so their local layouts inherit the
Stormwood placement/yaw rather than using Meadows coordinates.

## Doors and persistence

Prefab-declared doors receive the existing interactable, hinge animation, and
blocking gate collider through `scripts/world/village.gd:254-272` and
`scripts/world/village_door.gd:56-71`. The door is therefore physically and
verb-ready in the mounted world.

There is one concrete persistence gap: `village_door.gd` stores `_open` only in
node memory (`scripts/world/village_door.gd:41`) and toggles collision/mesh
locally (`scripts/world/village_door.gd:74-85`). It has no save, ledger, realm,
restore, or replication seam. A Stormwood realm unload/rebuild closes every
authored door. This is a blocker if authored-door state is expected to survive
realm travel or be shared by peers; it is not a blocker for intentionally
transient doors.

## Realm correctness blocker

`stormwood_settlements.json` declares `realm_id: "stormwood"`, but
`village.gd::build()` parses only `structures` (`scripts/world/village.gd:65`).
The injected path currently makes the right file mount, but the loader never
compares the data realm to its parent world. A future wrong `config_path` or
wrong-realm data file silently builds in the active realm. Add an explicit
expected-realm input/check before treating this reusable village path as
realm-safe.

## Focused execution evidence

All commands used `D:\Tetherbound-source` and
`D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe`.

| Command | Terminal result | Evidence |
| --- | --- | --- |
| `--headless --path . --script tests/smoke_stormheart_ascent.gd` | exit 0 | 26/26 assertions passed. World and simulation shell both hit all five sampled floors and both rails, then reached the core grounded (`fraction=1.000`, `core_distance=3.08`). |
| `--headless --path . --script tests/run_tests.gd -- --only=stormwood_encounters,stormwood_pickups,stormwood_trainers,stormwood_npcs,stormwood_surge` | exit 0 | 15 tests, 4,215 assertions, 0 failed. |

The ascent result is collision evidence for the post-fascia/two-sided-material
Stormheart geometry. The catalogue/surge result is data/pure-policy evidence;
it does not exercise settlement runtime, multiplayer interaction ownership, or
door restoration.

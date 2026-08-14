# D33 — One map database, for the minimap and the full map both

> Vocabulary note: written when the game called its creatures "pals"; R1.1 (2026-08-14) renamed the term to "creature" throughout the codebase without rewriting this historical record.
**Date:** 2026-08-13 · **Decided by:** the owner, implementing the UI spec's
§6A.12: "Do not implement two separate map databases. The full map is the
expanded strategic version of the minimap."

## The decision

Minimap and full map read from one shared data layer, `MapState` — a plain
`RefCounted`, held as `Game.map` alongside the party and inventory `D14`
already put on the one autoload. It owns three things (spec §6A.13):

1. **Fog-of-war discovery** — a 128×128 cell grid over the ±256m playground
   world, with a ~45m reveal radius around the player as they move.
   Tunable.
2. **Discovered landmarks** — sourced from `data/config/map_landmarks.json`,
   data-driven so a new Band 1–4 landmark (`D23`'s progression bands) joins
   the map with a JSON entry, not a code change.
3. **Dynamic markers** — camps placed through `D16`'s build system, and the
   current tracked objective.

The minimap renders a **baked top-down terrain texture** sampled once from
the Terrain3D heightfield, with a custom-`_draw()` fog and marker overlay on
top. **Not a second live 3D camera.** The spec's own §6A.13 asks for "the
lowest-cost method that stays visually clean and performant on ROG Ally",
and a live orthographic `Camera3D` rendering the world a second time every
frame is the expensive option on exactly the hardware this project treats
as primary.

## Why baked, and why `D09` is the reason

`D09` already established that this codebase asks the terrain for height
data directly (`ground_height_at`) rather than raycasting or re-deriving it
— a second mechanism checking the same thing the primary mechanism produces
is a mechanism that can quietly disagree with it. A live minimap camera is
that mistake at a much higher cost: re-rendering terrain, foliage and
structures a second time, every frame, to answer a question ("what does the
ground look like from above") that only needs answering once. Baking the
texture from the heightfield data the terrain already exposes gets the same
picture for a one-time cost instead of a per-frame one.

## What changes on disk

- `autoload/map_state.gd` — new `RefCounted`, held as `Game.map`. Owns the
  fog grid, landmark discovery state and dynamic markers; no `Node`, no
  transform, testable headlessly the same way `D14`'s `inventory.gd` and
  `party.gd` are (`tests/test_map_state.gd`).
- `data/config/map_landmarks.json` — new. Each entry: id, world position,
  icon, and the minimum discovery condition (proximity, or a story flag for
  landmarks the spec says may appear as a silhouette before discovery —
  spec §6A.4). Data-driven specifically so later biome bands are additive.
- `scripts/ui/minimap.gd` — new. Reads `Game.map`, transforms world
  positions into local map space, clips to the rounded-square frame,
  handles player-up rotation (spec §6A.3), and renders the baked terrain
  texture plus the fog/marker overlay. Lives at the top-right position `D28`
  resolved from the spec's own internal §6A.1/§6.5 conflict.
- `scripts/ui/full_map.gd` — new. Same `Game.map`, same icon vocabulary,
  same discovery state, larger canvas. The "expanded strategic version" the
  spec asks for, not a parallel implementation.
- Save format — the fog grid's discovered cells persist, riding the save
  v2 bump alongside `D30`'s pal fields and `D32`'s `yaw_deg` (see `D27`).

## What was deliberately not built

- **A wild-pal radar.** Spec §6A.6 is explicit: never turn the minimap into
  a radar for nearby wild creatures. Only the player's own active/following
  pal ever gets a marker, and only when separated enough to matter.
- **Fast travel.** The spec's fast-travel landmark icon is conditional ("if
  such a system exists"). No such system exists yet; the icon slot is
  reserved in `map_landmarks.json`'s schema, nothing reads it.
- **Tether Rift reconnection redraw.** The route-change visual `D23`'s
  §38 step 45 and the spec's §6A.11 both describe is real future scope for
  this data layer, not built here — `MapState` is shaped so a biome
  reconnection is a data update to the same grid, not a new system.

## What it supersedes

Nothing existed to supersede — there was no minimap and no map database
before this. It does commit the eventual full map (`GAME_DESIGN.md` §23) to
share `MapState` rather than growing its own discovery tracking later.

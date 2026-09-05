# Cloudreach navigation, atmosphere and aftermath runtime

The new `cloudreach_map_state.gd` extends the existing production MapState interface.
It supplies Cloudreach's instance-owned extent/fog and 3D region/landmark discovery,
using the world and chapter manifests. It does not change Meadows' static extent or
overwrite its map state. `cloudreach_atmosphere.gd` reads canonical flags, plays installed
audio through the production buses, and applies visible changes to supplied world
nodes. Neither runtime creates a story completion event or grants a reward.

## Root integration required

1. Create a Cloudreach map and call `configure_cloudreach(world_data, chapter_data,
   Game.progression)`. Load only its Cloudreach payload. Bind this instance to `Game.map`
   and the existing minimap/full-map consumers while in this realm. Preserve a separate
   Meadows map instance/payload for return travel. This lane does **not** alter Game/save
   realm ownership. Its map payload contains `realm_id: cloudreach`; passing a Meadows
   payload cannot reveal Cloudreach fog or landmarks.
2. Add the atmosphere node and call `configure(Game.progression, cloudreach_map, Player,
   bindings)` before adding it. It can also be configured again after a dependency
   replacement; `restore_progression_from_game` updates the progression reference.
3. Bind arrays of visual nodes under the keys below. Bind already-authored indicators,
   travelers and presentation objects, not physical collision gates. World progression
   code continues to own collision/access. This runtime never opens an enterable Water
   realm or modifies a realm destination.
4. Forward real captain encounter start/finish or finale phase to `set_finale_active`.
   The finale track plays only in the summit region; network freedom silences it even
   if the encounter listener has not yet sent its stop callback.
5. Add `world.map_terrain_texture()` returning `cloudreach_map.bake_terrain(world)` and
   pass that same texture into the production minimap's `configure`. This is a cached
   160×325 survey of the actual world's ground heights, rendered as a readable atlas.
   The full map consumes the optional world hook. Without it, it leaves the terrain
   background empty instead of displaying an unrelated cached Meadows bake.

## Visible binding keys

| Key | Visible/active state |
|---|---|
| `fly_routes` | Fly unlocked: authored perch/streamer/wind-route indicators |
| `upper_routes` | Upper route unlocked: reopened-route presentation |
| `returning_travelers` | Winds restored: already-authored returning travelers |
| `natural_anchor_wind` | Winds restored: natural trails replacing extraction pulses |
| `anchor_drone` | Until network disabled: oppressive anchor visual elements |
| `waterward_overlook` | Captain defeated, winds restored and Waterward revealed |
| `shrine_lights` | Light3D energy brightens to 1.35× original after restoration |

The shrine multiplier uses a remembered original energy, so repeated sync/reload never
compounds it. `presentation_changed(state)` is emitted only when the projected state
changes (or bindings are explicitly reconfigured). Its `waterward_enterable` field is
always false. It may show a distant direction/view, never a portal trigger.

## Navigation and saved state

Normal movement reveals only nearby fog. Region discovery uses full 3D authored
bounds and respects access flags, so standing under a high shrine is not visiting it.
Landmark physical discovery uses 35 m horizontal / 12 m vertical proximity. Chapter
navigation events reveal the named major landmarks after the corresponding flags.
Fly-only markers are absent until Fly; Waterward stays absent until its full aftermath
gate. The runtime creates no objective markers, pickup radar, creature radar or
always-on GPS trail.

The existing minimap and map-tab UI now consume optional `world_bounds()` and
`map_display_name()` capabilities, retaining the original Meadows extent/name when
they are absent. Map fit, pan, projection, fog and terrain sampling agree on the
current realm. Ordinary fog movement updates only its touched cell rectangle.

This realm's grid uses 8 m cells (400×813), preserving its descriptor with the payload.
Fog from a changed grid is discarded; valid landmark/region IDs remain recoverable.
Dynamic markers continue using the existing MapState contract. Saving/reloading this
map is idempotent; preserving **both realm payloads** is the root integration step.

## Audio behavior

The chapter's installed low wind, high wind, birds, settlement canopy, Tether drone
and Warden music streams play on the production Ambience/Music buses and respect the
player's bus sliders. Region profiles live in `cloudreach_atmosphere.json`. High Roost
ducks the low bed and birds while retaining high wind; settlements are audible only
near the two authored settlement positions, including a vertical tolerance.

Crossfades take three seconds. Zero-gain layers stop their actual AudioStreamPlayers.
Network freedom stops the drone and finale music; witnessed restoration brings back
distant calls and an open-wind mix. Empty chapter sources for bespoke bridge creaks
and mix-only high silence are not fabricated. The installed placeholders are still
identified as such in the chapter manifest.

## Evidence

Focused new tests plus legacy map/zoom/minimap regressions pass: 37 tests / 135
assertions. They cover separate bounds, unchanged legacy fallbacks, unlock/Waterward
gates, realm-safe fog persistence, idempotent navigation, mix changes and withheld
story rewards.

The isolated live fixture `tests/smoke_cloudreach_atmosphere.gd` exits 0 cleanly. It
plays real installed streams on actual audio players, applies visible route/traveler
state and shrine light energy, stops the actual drone/music players after freedom,
and reloads canonical flags without compounded lighting or fabricated completion.
Dummy audio teardown initially retained playback handles; explicit stop/release and
one mixer interval now produce clean fixture shutdown.

Remaining production acceptance: root realm-map save/binding and shared atlas hook,
authored traveler/route/light bindings, real chapter encounter signals, GPU route/map
captures and blind review, listening/mix balance and target-hardware profiling. This
fixture proves execution and state, not an accepted final world composition.

# Realm map ownership and save v19

Game now owns one persistent Meadows `MapState` and one persistent
`CloudreachMapState`. `Game.map` remains the active interface used by the existing
minimap and tab map. Switching realms does not reconfigure or clear either grid.
Waterward has no map implementation.

## Scene integration

After realm selection and Player placement, before configuring the minimap or
atmosphere, obtain the canonical instance:

```gdscript
var realm_map: RefCounted = Game.bind_realm_map("cloudreach", player.global_position)
# Pass realm_map to minimap.configure and CloudreachAtmosphere.configure.
# The world's map_terrain_texture() can return realm_map.bake_terrain(self).
```

Do not instantiate a replacement map or call `configure_cloudreach` on this live
instance: configuration intentionally initializes a fresh grid. Repeated calls
to `bind_realm_map` are safe and preserve discoveries. Supplying the position
also synchronizes canonical progression-gated Cloudreach navigation. Omitting
the realm selects `Game.current_realm`; passing an unsupported realm returns null
without replacing the active map. Binding is not a travel authorization and does
not change `current_realm`, scenes, progression, or realm access.

`Game.enter_realm` already selects and binds the destination map before writing
its transition autosave. Save loading binds the saved realm after progression is
restored. A returning Meadows scene can call `Game.bind_realm_map("meadows")`;
normal entry/load already performed that bind. Existing map instances are reused
on same-session loads so mounted consumers retain valid handles. A scene change
must configure its widgets against the returned active map, not an old realm's
handle. `reset_for_new_game` alone discards both maps.

The public persistence hooks `save_realm_maps()` and `restore_realm_maps(payloads)`
are for SaveGame. Worlds do not write separate map files or save stores.

## File shape and migration

Save version 19 stores `realm_maps.meadows` and `realm_maps.cloudreach`. Existing
`map` remains a compatibility alias of the active map for legacy consumers/test
doubles; `realm_maps` is authoritative when both are present. Neither mapping
changes the existing player pose, Fly traversal, active party slot, Realm Heart,
resource, or progression serialization.

Version 18 and older migrate through the existing full migration chain. An
untagged legacy `map` belongs to Meadows **regardless of `current_realm`**: before
realm-map ownership, Cloudreach scene selection could still serialize the
Meadows grid. Only `realm_id: "cloudreach"` identifies a legacy Cloudreach payload.
The other realm starts undiscovered. Already-present realm payloads win over the
legacy alias. This prevents interpreting Meadows fog bytes using Cloudreach's
different extent and losing the original exploration trail.

## Verification

Command:

```powershell
& 'D:\Tetherbound-tools\godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd -- --only=test_realm_map_persistence.gd,test_save_format.gd,test_fly_traversal.gd,test_cloudreach_atmosphere.gd
```

Result: **70 tests, 497 assertions, zero failures**. The existing corrupt-JSON and
future-version negative cases intentionally log their rejection diagnostics.
The existing isolated `tests/smoke_cloudreach_atmosphere.gd` also passes with
real installed audio players, gated navigation, visual bindings, and reload
idempotency after the ownership change.

Six focused tests instantiate the real GameState outside the scene tree and
exercise real SaveGame JSON files in an isolated test directory: there/back
binding and object identity; independent fog/markers; saves while either realm
is selected; UI bounds and display-name contracts; untagged and tagged legacy
migration; exact Meadows fog hashes before/after migration and re-save; current
payload precedence; version-one migration; and fresh-game reset of both maps.
These prove persistence and consumer contracts, not a fully played realm-gate
transition or external visual acceptance. Continuous production world evidence
remains the owning integration lane's responsibility.

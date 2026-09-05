# Realm-safe buildings, satchels and recovery

Save format **20** adds `realm` to every player-building and death-satchel record.
Game's registration APIs tag the active realm. Legacy/untagged records belong to
Meadows even if the saved scene is Cloudreach. Normalization preserves array indices,
storage payloads, tool durability and existing map/Heart/Fly/progression fields.
There is no second save store and no creature storage or party-limit change.

`BuildPlacer` restores only active-realm buildings, filters placement/snap/occupancy
queries, rejects foreign dismantle targets, and syncs only matching live records.
Loaded inactive buildings have no rendered body, collision, or interact prompt.
Meadows HomeProgress counts only Meadows pieces; Cloudreach camps cannot advance
the Meadows home or three-creature-bed construction milestones. Ground placement
prefers `ground_height_near(Vector3)` when the world supplies it, retaining stacked
elevation; Meadows continues using its existing `ground_height_at(x,z)` fallback.

`PlayerDeath` restores only active-realm satchels, retains all inactive records and
uses stable global array indices for marker identities. It immediately records each
new bag's contents, then continues synchronizing the real bag inventories before
saves/transitions. Restore detaches obsolete nodes before deferred disposal so their
prompts/collisions cannot overlap replacement nodes for a frame.

Home recovery chooses the most recent nonremoved bedroll **in the current realm**.
Without one, Cloudreach selects the nearest unlocked authored safe camp by 3D
distance; the camp prerequisite is checked against canonical progression. Candidates
must resolve to finite ground within 8 metres of their authored elevation. The capsule
starts beside the camp furniture, one metre above ground. If no camp is valid, the
world's supplied realm-local spawn is the fallback. Meadows retains its original
bedroll-or-spawn rule. Any active Fly state is ended before respawning.

## World mounting hooks (not performed by this package)

After realm selection and player placement, add one production placer:

```gdscript
var placer := preload("res://scripts/build/build_placer.gd").new()
placer.name = "BuildPlacer"
placer.player_path = NodePath("../Player")
placer.camera_rig_path = NodePath("../CameraRig")
add_child(placer) # _ready restores Game's active-realm records automatically.

var death := preload("res://scripts/world/player_death.gd").new()
death.name = "PlayerDeath"
add_child(death)
death.configure_recovery(chapter_data.camping_contract.camps,
    Callable(self, "ground_height_near"))
death.build(self, player, realm_local_safe_spawn)
death.restore_from_game(Game)
```

`configure_recovery(camps, ground_resolver)` accepts the canonical camp dictionaries
and a `Vector3 -> float` or `Vector3 -> Vector3` callback. Omit it to use chapter
camps plus the parent's `ground_height_near` automatically. `recovery_position(Game,
from_position)` is a public nonmutating query for combat/finale recovery handoff.
`build()` connects the production Player's `died` signal. Do not add another death
handler that also drains inventory. Existing Game save/load lifecycle groups perform
later sync/restore automatically. The normal Game realm transition syncs the outgoing
world before changing realms; preserve that ordering.

The world still needs its normal build-menu mount and controller ownership wiring;
the placer is not a substitute for the menu. This checkpoint does not claim that
Cloudreach's camp spaces, building interactions, death routes or recovery balance have
been played continuously in the production mountain.

## Verification

Godot 4.7 headless selected suites: **140 tests / 880 assertions / zero failures**:
`test_realm_world_records`, `test_register_building`, `test_build_placer_preview`,
`test_home_progress`, `test_realm_map_persistence`, `test_save_format`,
`test_player_death`, `test_free_build`, `test_fly_traversal`, `test_realm_heart_state`,
`test_meadows_realm_save_repair`, `test_cloudreach_resources`.

New `tests/smoke_realm_world_records.gd`: **PASS, 35 checks**, no script errors.
Uses real Player, BuildPlacer, tent bodies, satchel inventories/prompts, map instances,
SaveGame files in an isolated test directory and Player's death signal/timed respawn.
Proves there/back building and multiple-satchel isolation, no duplicate restores,
foreign-target dismantle refusal, nearest-elevation placement, a third Cloudreach
death bag, local authored-camp recovery, and subsequent reload while Meadows bags
remain intact. This is an isolated runtime fixture, not production route evidence.

Initial failures were fixture assumptions: structural floor snapping intentionally
chooses an adjacent legal cell; JSON numeric variants become floats until inventories
rehydrate them. Tests now compare the actual snap contract and normalized numeric
payloads. The shared legacy player-death unit tests still construct bags outside a
SceneTree and print pre-existing pickup-glow tree-null/leak diagnostics; the live
smoke constructs/disposes them in-tree cleanly. Negative corrupt/future-save tests
also emit their expected refusal diagnostics.

An additional existing `smoke_free_build.gd` production-Meadows controller run was
stopped after more than five minutes without reaching a test result. It remained in
world initialization/settling, with terrain/material diagnostics and no controller
assertion output. No pass is claimed for that broader run; repeat it during the
owning full-world integration/evidence pass. The focused free-build/placement unit
regressions above passed, and the new in-tree realm smoke completed in five seconds.

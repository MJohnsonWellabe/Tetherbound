extends RefCounted

## GATE-E — where a body actually STANDS when the world has a building on it.
##
## The problem this exists for, measured rather than reasoned about:
##
##   elite body y=8.56  floor y=8.56  terrain y=1.37
##   f0 ally(75.0, 1.92, 7555.5) foe TrainerCreature_stronghold_elite_1(77.2, 2.49, 7555.5)
##
## That is a stronghold gauntlet fight happening SEVEN METRES BELOW the room it
## was started in, under the building, inside its own revetment skirt. Both
## fighters and the player are teleported there at the moment the fight opens,
## because every placement in combat resolves "the ground" as
## `playground_world.ground_height_at()` — which is the TERRAIN, and the
## stronghold's five spaces are built slabs standing metres above it.
##
## `stronghold_climax.gd` already carries a hand-patch of exactly this for the
## Warden's own NPC body, with a comment explaining it. What that patch could
## not reach is everything the fight itself places: the trainer's deployed
## creature (`encounter_director._send_out_next_creature`), the ally
## (`combat_manager._place`) and the player (`combat_manager._place_player`).
##
## The owner's 2026-08-21 playtest named the symptom without the cause —
## "Stronghold and Burrow Warrens fights sometimes phasing participants outside
## reachable arena bounds and becoming effectively impossible". Under the floor
## is where they went, and whether the fight is winnable from down there depends
## on which side of a support column each body happens to land on: fine on one
## machine, wedged on another. `verify-gate-evidence-shard` reproduced the wedged
## half on GitHub's runner as "the elite's fight never resolved inside 9000
## frames (5 quick attacks landed, 0 missed)" — the ally never once got in range,
## because it was underneath the room.
##
## The resolution is deliberately NOT a change to `ground_height_at`. That
## function is the terrain's, dozens of systems read it (scatter, props, water,
## perimeter, the bake tools), and a structure-aware answer would change all of
## them at once. Instead this asks the same question `combat_manager._arena_bounds`
## already asks, in the same shape and for the same reason: walk to the world,
## then ask every child that claims to be a building whether it has a floor over
## this x/z. A building that does answers with its own floor height; everything
## else answers NAN and nothing changes.

const NO_FLOOR := NAN


## The height of a built floor over `x, z`, or NAN when no building claims it.
##
## `from` is any node in the tree; the world is found by walking up for
## `ground_height_at` — the identical discovery `creature_body._ground_height`
## and `combat_manager._ground_height` already do, so a body in a bare test
## scene simply gets NAN and keeps its old behaviour.
static func height_at(from: Node, x: float, z: float) -> float:
	var world := _world_of(from)
	if world == null:
		return NO_FLOOR
	for child in world.get_children():
		if not child.has_method("built_floor_height_at"):
			continue
		var height := float(child.call("built_floor_height_at", x, z))
		if not is_nan(height):
			return height
	return NO_FLOOR


## The terrain answer, replaced by a building's own floor wherever a building
## CLAIMS the spot.
##
## Claim wins outright rather than "whichever is higher", because the two
## buildings in the chapter sit on opposite sides of the terrain: the
## stronghold's slabs stand metres above it and the warrens' chambers are cut
## into it. A max() rule would fix the stronghold and push every warrens fighter
## up through the cave roof. A building that claims a spot is the authority on
## how high its own floor is there; everywhere else the terrain still is, which
## is every square metre of the open meadow.
static func resolve(from: Node, x: float, z: float, terrain: float) -> float:
	var built := height_at(from, x, z)
	return terrain if is_nan(built) else built


static func _world_of(from: Node) -> Node:
	var node: Node = from
	while node != null:
		if node.has_method("ground_height_at"):
			return node
		node = node.get_parent()
	return null

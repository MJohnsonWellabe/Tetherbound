extends SceneTree

## GAME-F1 and GAME-F2, verified in a REAL booted Meadows rather than from the
## config files the fixes were made in.
##
##   godot --headless --path . --script tools/gate_f/diag/probe_game_f1_f2_in_world.gd
##
## Exit 0 when both hold, 1 otherwise, so this can be run as a check.
##
## Why a world boot and not just the unit tests. `tests/test_practice_fight_level.gd`
## and `tests/test_village_boundary.gd` read the JSON, which is the right place
## to stop a regression -- but neither of them proves that the number in the
## file reaches a creature that actually stands in the meadow, or that a moved
## harvest node still stands on ground and still registers its prompt. The pin
## is applied by `encounter_director.gd` AFTER the band roll, and a harvest node
## is placed by asking the world for its own ground height; both of those are
## things only a booted world can answer.
##
## This is a DIAG instrument. It boots a fresh world and reads it -- no save is
## loaded (so GAME-F4's load-time base-stat loss cannot contaminate it), no
## level-up happens, and nothing is granted.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const BOUNDARY := preload("res://scripts/world/village_boundary.gd")

## The Practice Meadow cluster, `spawns.json` order 0.
const PRACTICE_CENTRE := Vector2(30.0, -40.0)
const PRACTICE_RADIUS := 15.0
const EXPECTED_PRACTICE_LEVEL := 2

## Where GAME-F1 moved the two strays to.
const MOVED_NODES := [Vector2(40.5, -28.0), Vector2(47.0, -34.5)]

var _failures: Array[String] = []
## Guards against a script error aborting a check and the run still
## reporting PASS on an empty failure list -- which is how the first version
## of this probe reported PASS while its GAME-F1 half had crashed.
var _checks_run: int = 0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_check_practice_levels(world)
	_checks_run += 1
	_check_moved_harvest_nodes(world)
	_checks_run += 1

	print("")
	if _failures.is_empty() and _checks_run == 2:
		print("[probe] PASS -- GAME-F1 and GAME-F2 both hold in a live world")
		quit(0)
		return
	if _checks_run != 2:
		print("[probe] FAIL only %d of 2 checks completed -- a check aborted" % _checks_run)
	for line: String in _failures:
		print("[probe] FAIL %s" % line)
	quit(1)


## Every wild creature standing inside the practice cluster's own disc.
func _practice_wilds(world: Node) -> Array:
	var out: Array = []
	var stack: Array = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		var script: Script = node.get_script() as Script
		if script == null or not str(script.resource_path).ends_with("wild_creature.gd"):
			continue
		var body := node as Node3D
		if body == null:
			continue
		var at := Vector2(body.global_position.x, body.global_position.z)
		if at.distance_to(PRACTICE_CENTRE) <= PRACTICE_RADIUS + 1.0:
			out.append(body)
	return out


func _check_practice_levels(world: Node) -> void:
	print("--- GAME-F2: the teaching fight's level ---")
	var wilds := _practice_wilds(world)
	if wilds.is_empty():
		_failures.append("no wild creature stands in the Practice Meadow disc at all")
		return
	for body: Node3D in wilds:
		var instance: RefCounted = body.get("instance")
		if instance == null:
			_failures.append("a practice-meadow creature has no live instance")
			continue
		var level := int(instance.get("level"))
		var species := str(instance.get("species_id"))
		var at := Vector2(body.global_position.x, body.global_position.z)
		var ok := level == EXPECTED_PRACTICE_LEVEL
		print("    %-12s L%-3d at (%.1f, %.1f)  max_hp=%.1f  %s"
			% [species, level, at.x, at.y, float(instance.get("max_hp")), "OK" if ok else "WRONG"])
		if not ok:
			_failures.append("practice %s stands at level %d, not the pinned %d -- the GAME-11 pin is not reaching the world"
				% [species, level, EXPECTED_PRACTICE_LEVEL])


func _check_moved_harvest_nodes(world: Node) -> void:
	print("--- GAME-F1: the two harvest nodes moved inside the fence ---")
	# `village_boundary.gd` extends Node3D, but the three functions this needs
	# are STATIC -- called on the script, never on an instance, exactly as
	# `tests/test_village_boundary.gd` calls them.
	var outline: PackedVector2Array = BOUNDARY.outline(BOUNDARY.load_config())

	for want: Vector2 in MOVED_NODES:
		var best: Node3D = null
		var best_d := 3.0
		for node in world.get_tree().get_nodes_in_group("harvestable"):
			# `harvest_node.gd::_ready` puts the NODE itself in the group (not
			# its child Interactable), and it is the node that carries the
			# authored position.
			var owner_node := node as Node3D
			if owner_node == null:
				continue
			var at := Vector2(owner_node.global_position.x, owner_node.global_position.z)
			var d := at.distance_to(want)
			if d < best_d:
				best_d = d
				best = owner_node
		if best == null:
			_failures.append("no harvestable stands within 3 m of the moved node at (%.1f, %.1f)" % [want.x, want.y])
			continue
		var at := Vector2(best.global_position.x, best.global_position.z)
		var inside: bool = BOUNDARY.contains(outline, at)
		print("    node at (%.2f, %.2f)  y=%.2f  inside_fence=%s" % [at.x, at.y, best.global_position.y, inside])
		if not inside:
			_failures.append("the node at (%.1f, %.1f) is still outside the village fence" % [at.x, at.y])

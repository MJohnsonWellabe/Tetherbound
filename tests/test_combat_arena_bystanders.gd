extends "res://tests/test_case.gd"

## F04#1 (C3 judge 257839f5): a relay grunt stood inside Vance's charging
## Tuskroot. Set-dressing people inside a fight's ring walk out to its edge
## when the fight opens and back when it closes; people outside, and bodies
## not in the bystander group, are left alone.

const ARENA_SCRIPT := preload("res://scripts/combat/combat_arena.gd")


class Walker:
	extends Node3D
	var walks: Array = []
	func walk_to(target: Vector3, speed: float, on_arrived: Callable = Callable()) -> void:
		walks.append([target, speed])
		global_position = target
		if on_arrived.is_valid():
			on_arrived.call()


func _walker(root: Node3D, at: Vector3, bystander: bool) -> Walker:
	var body := Walker.new()
	root.add_child(body)
	body.global_position = at
	if bystander:
		body.add_to_group(ARENA_SCRIPT.BYSTANDER_GROUP)
	return body


func test_bystanders_inside_the_ring_step_to_its_edge_and_come_back() -> void:
	var root := Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(root)
	var inside := _walker(root, Vector3(4.0, 0.0, 0.0), true)
	var outside := _walker(root, Vector3(20.0, 0.0, 0.0), true)
	var fighter := _walker(root, Vector3(0.0, 0.0, 3.0), false)
	var arena := Node3D.new()
	arena.set_script(ARENA_SCRIPT)
	root.add_child(arena)
	arena.call("configure", Vector3.ZERO, {"radius": 11.0, "clear_bystanders": true,
		"bystander_edge_m": 1.0, "bystander_walk_mps": 2.6})
	assert_eq(inside.walks.size(), 1, "the grunt in the ring walks out")
	assert_almost_eq((inside.walks[0][0] as Vector3).x, 12.0, 0.01, "to the ring's edge plus the margin, straight out")
	assert_almost_eq(float(inside.walks[0][1]), 2.6, 0.001, "at the configured pace")
	assert_almost_eq(inside.rotation.y, atan2(-1.0, 0.0), 0.01, "and turns to watch the fight")
	assert_eq(outside.walks.size(), 0, "a bystander already clear is left alone")
	assert_eq(fighter.walks.size(), 0, "a body outside the group is never moved")
	arena.free()
	assert_eq(inside.walks.size(), 2, "the fight closing walks them back")
	assert_almost_eq((inside.walks[1][0] as Vector3).x, 4.0, 0.01, "to where they stood")
	root.free()


func test_the_arena_config_turns_it_on() -> void:
	var arena: Dictionary = preload("res://scripts/combat/combat_math.gd").config()["arena"]
	assert_true(bool(arena.get("clear_bystanders", false)), "fights clear set dressing from the ring")

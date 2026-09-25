extends "res://tests/test_case.gd"

## MEADOWS-VISUAL-PASS: bushes and standing dead trees inside a fight ring
## stand aside while the fight runs (`vegetation.gd::hide_fight_occluders()`)
## and come back when the arena closes, except anything taken for good in the
## meantime. Data level, like `test_vegetation_siting.gd`: a recording stand-in
## replaces the Terrain3D instancer, so no terrain or mesh is built.

const VEGETATION := preload("res://scripts/world/vegetation.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")


class RecordingInstancer extends RefCounted:
	var removed: Array[Vector3] = []
	var added: Array[Transform3D] = []
	var added_mesh_ids: Array[int] = []
	var refreshes := 0

	func remove_instances(at: Vector3, _params: Dictionary) -> void:
		removed.append(at)

	func add_transforms(mesh_id: int, transforms: Array[Transform3D], _colours: PackedColorArray, _update: bool) -> void:
		for t: Transform3D in transforms:
			added.append(t)
			added_mesh_ids.append(mesh_id)

	func update_mmis(_rebuild: bool) -> void:
		refreshes += 1


func _layer(name: String) -> Dictionary:
	return (RULES.config().get("layers", {}) as Dictionary).get(name, {})


func _veg() -> Array:
	var veg: Node3D = VEGETATION.new()
	var instancer := RecordingInstancer.new()
	veg.set("_instancer", instancer)
	return [veg, instancer]


func _record(veg: Node3D, layer_name: String, at: Vector3, mesh_id: int, extra := {}) -> void:
	var models: Array = _layer(layer_name).get("models", [])
	var placement := {"model": str(models[0]), "position": at, "scale": 0.8, "yaw": 1.25}
	placement.merge(extra, true)
	veg.call("_record_soft_occluders", str(models[0]), _layer(layer_name), [placement], mesh_id)
	var known: PackedVector3Array = (veg.get("_instance_positions") as Dictionary).get(mesh_id, PackedVector3Array())
	known.append(at)
	(veg.get("_instance_positions") as Dictionary)[mesh_id] = known


func test_only_what_stands_inside_the_ring_is_hidden() -> void:
	var pair := _veg()
	var veg: Node3D = pair[0]
	var instancer: RecordingInstancer = pair[1]
	_record(veg, "deadfall", Vector3(3.0, 0.0, 0.0), 4)
	_record(veg, "bushes", Vector3(0.0, 0.0, -5.0), 7)
	_record(veg, "deadfall", Vector3(30.0, 0.0, 0.0), 4)
	var token: PackedInt32Array = veg.call("hide_fight_occluders", Vector3.ZERO, 11.0)
	assert_eq(token.size(), 2, "the two plants inside 11 m stand aside")
	assert_eq(instancer.removed.size(), 2)
	assert_false(instancer.removed.has(Vector3(30.0, 0.0, 0.0)), "the far dead tree stays")
	veg.free()


func test_closing_the_arena_puts_every_hidden_plant_back_where_it_stood() -> void:
	var pair := _veg()
	var veg: Node3D = pair[0]
	var instancer: RecordingInstancer = pair[1]
	var at := Vector3(2.0, 5.0, 1.0)
	_record(veg, "deadfall", at, 4)
	var token: PackedInt32Array = veg.call("hide_fight_occluders", Vector3.ZERO, 11.0)
	assert_eq(int(veg.call("restore_fight_occluders", token)), 1)
	assert_eq(instancer.added.size(), 1)
	assert_eq(instancer.added_mesh_ids[0], 4, "back into the same mesh")
	var t: Transform3D = instancer.added[0]
	assert_almost_eq(t.origin.x, at.x, 0.0001)
	assert_almost_eq(t.origin.y, at.y - float(VEGETATION.SINK), 0.0001,
		"sunk exactly as _build_batch sinks it")
	assert_almost_eq(t.basis.get_scale().x, 0.8, 0.0001, "same scale")
	assert_almost_eq(t.basis.get_euler().y, 1.25, 0.0001, "same yaw")
	var known: PackedVector3Array = (veg.get("_instance_positions") as Dictionary)[4]
	assert_eq(known.count(at), 1, "the position ledger holds it exactly once again")
	assert_eq(int(veg.call("restore_fight_occluders", token)), 0, "a second restore is a no-op")
	veg.free()


func test_an_overlapping_second_ring_does_not_take_the_same_plant_twice() -> void:
	var pair := _veg()
	var veg: Node3D = pair[0]
	var instancer: RecordingInstancer = pair[1]
	_record(veg, "bushes", Vector3(5.0, 0.0, 0.0), 7)
	var first: PackedInt32Array = veg.call("hide_fight_occluders", Vector3.ZERO, 11.0)
	var second: PackedInt32Array = veg.call("hide_fight_occluders", Vector3(8.0, 0.0, 0.0), 11.0)
	assert_eq(first.size(), 1)
	assert_eq(second.size(), 1, "the second ring holds the plant too")
	assert_eq(instancer.removed.size(), 1, "but it is removed only once")
	veg.call("restore_fight_occluders", second)
	assert_eq(instancer.added.size(), 0, "the first ring still holds it")
	veg.call("restore_fight_occluders", first)
	assert_eq(instancer.added.size(), 1)
	veg.free()


## Review of PR215: the first arena can close (its `_exit_tree` runs at the end
## of the frame) after a second ring has opened over the same plants. Closing
## the first must not put a bush back inside the ring that is still open.
func test_the_first_ring_closing_leaves_plants_the_second_still_holds_hidden() -> void:
	var pair := _veg()
	var veg: Node3D = pair[0]
	var instancer: RecordingInstancer = pair[1]
	_record(veg, "bushes", Vector3(5.0, 0.0, 0.0), 7)
	var first: PackedInt32Array = veg.call("hide_fight_occluders", Vector3.ZERO, 11.0)
	var second: PackedInt32Array = veg.call("hide_fight_occluders", Vector3(8.0, 0.0, 0.0), 11.0)
	assert_eq(int(veg.call("restore_fight_occluders", first)), 0, "the second ring is still open")
	assert_eq(instancer.added.size(), 0)
	assert_eq(int(veg.call("restore_fight_occluders", second)), 1, "the last ring to close brings it back")
	assert_eq(instancer.added.size(), 1)
	veg.free()


func test_a_bush_harvested_during_the_fight_stays_harvested() -> void:
	var pair := _veg()
	var veg: Node3D = pair[0]
	var instancer: RecordingInstancer = pair[1]
	_record(veg, "bushes", Vector3(1.0, 0.0, 0.0), 7, {"harvest_index": 12})
	(veg.get("_harvest_lookup") as Dictionary)["bushes#12"] = {}
	_record(veg, "bushes", Vector3(-1.0, 0.0, 0.0), 7, {"harvest_index": 13})
	(veg.get("_harvest_lookup") as Dictionary)["bushes#13"] = {}
	var token: PackedInt32Array = veg.call("hide_fight_occluders", Vector3.ZERO, 11.0)
	(veg.get("_harvest_lookup") as Dictionary).erase("bushes#12")
	assert_eq(int(veg.call("restore_fight_occluders", token)), 1)
	assert_almost_eq(instancer.added[0].origin.x, -1.0, 0.0001, "only the unharvested bush returns")
	veg.free()


func test_ground_a_site_cleared_for_good_is_never_restored_by_a_fight() -> void:
	var pair := _veg()
	var veg: Node3D = pair[0]
	var instancer: RecordingInstancer = pair[1]
	_record(veg, "deadfall", Vector3(1.0, 0.0, 0.0), 4)
	veg.call("clear_area", Vector3(1.0, 0.0, 0.0), 3.0)
	instancer.removed.clear()
	var token: PackedInt32Array = veg.call("hide_fight_occluders", Vector3.ZERO, 11.0)
	assert_eq(token.size(), 0, "clear_area already took it")
	assert_eq(instancer.removed.size(), 0)
	veg.free()


func test_nothing_happens_without_an_instancer() -> void:
	var veg: Node3D = VEGETATION.new()
	veg.call("_record_soft_occluders", str((_layer("deadfall").get("models", []) as Array)[0]),
		_layer("deadfall"), [{"position": Vector3.ZERO, "scale": 1.0, "yaw": 0.0}], 4)
	var token: PackedInt32Array = veg.call("hide_fight_occluders", Vector3.ZERO, 11.0)
	assert_eq(token.size(), 0)
	assert_eq(int(veg.call("restore_fight_occluders", PackedInt32Array([0]))), 0)
	veg.free()


# --- Authored harvest nodes built from the same models ----------------------

const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")
const DEAD_TREE := "res://assets/environment/stylized_nature/DeadTree_2.gltf"


func _harvest(model: String) -> Node3D:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", {"item": "wood", "amount": 4, "at": [26.0, -44.0], "model": model, "model_scale": 0.22})
	return node


func test_a_deadwood_node_joins_the_ring_group_and_a_rock_does_not() -> void:
	var dead := _harvest(DEAD_TREE)
	assert_true(dead.is_in_group(HARVEST_NODE.FIGHT_RING_OCCLUDER_GROUP),
		"the band-1 deadwood node the survey fight stood on")
	var stone := _harvest("res://assets/environment/stylized_nature/Rock_Medium_1.gltf")
	assert_false(stone.is_in_group(HARVEST_NODE.FIGHT_RING_OCCLUDER_GROUP),
		"a rock deposit is ground, not a standing occluder")
	dead.free()
	stone.free()


func test_overlapping_rings_keep_the_model_hidden_until_the_last_one_closes() -> void:
	var node := _harvest(DEAD_TREE)
	var visual: Node3D = node.get("_visual")
	node.call("set_fight_hidden", true)
	node.call("set_fight_hidden", true)
	assert_false(visual.visible)
	node.call("set_fight_hidden", false)
	assert_false(visual.visible, "one ring is still open")
	node.call("set_fight_hidden", false)
	assert_true(visual.visible)
	node.call("set_fight_hidden", false)
	assert_true(visual.visible, "an unmatched show never goes negative")
	node.free()

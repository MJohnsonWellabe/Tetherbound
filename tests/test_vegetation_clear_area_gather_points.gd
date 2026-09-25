extends "res://tests/test_case.gd"

## F03 (vault). `vegetation.gd::clear_area()` must remove EVERY layer's gather
## point inside the circle, not only the collidable layers'. A harvestable
## non-collidable layer (fibre, prompt "Gather") has no collision batch; before
## this it kept an invisible, actionable prompt in cleared ground, and in the
## Burrow Warrens vault it won the interaction arbiter over the Heartstone:
##   smoke_warrens --vault-activity: "the Heartstone prompt never won the
##   interaction arbiter; winner={"label": "Gather", "distance": 0.64, ...}"

const VEGETATION := preload("res://scripts/world/vegetation.gd")


func _register_point(veg: Node3D, key: String, at: Vector3) -> Node3D:
	# The bookkeeping `_spawn_harvest_point()` writes, without the Terrain3D
	# asset registration it also does (no Terrain3D in a unit test).
	var point := Node3D.new()
	veg.add_child(point)
	(veg.get("_harvest_lookup") as Dictionary)[key] = {"mesh_id": -1, "position": at,
		"item": "fiber", "amount": 2, "prop_offset": Vector3.ZERO}
	(veg.get("_harvest_nodes") as Dictionary)[key] = point
	veg.set("_harvest_points", int(veg.get("_harvest_points")) + 1)
	return point


func test_clear_area_removes_non_collidable_gather_points_inside_the_circle() -> void:
	var veg: Node3D = VEGETATION.new()
	var inside := _register_point(veg, "bushes#7", Vector3(1.0, 0.0, 1.0))
	var outside := _register_point(veg, "bushes#8", Vector3(20.0, 0.0, 0.0))
	veg.call("clear_area", Vector3.ZERO, 5.0)
	var nodes: Dictionary = veg.get("_harvest_nodes")
	var lookup: Dictionary = veg.get("_harvest_lookup")
	assert_false(nodes.has("bushes#7"), "a fibre gather point inside cleared ground must go")
	assert_false(lookup.has("bushes#7"), "and must not be harvestable later")
	assert_true(inside.is_queued_for_deletion(), "its prompt node is freed")
	assert_true(nodes.has("bushes#8") and lookup.has("bushes#8"), "a point outside the circle stays")
	assert_false(outside.is_queued_for_deletion())
	assert_eq(int(veg.get("_harvest_points")), 1, "the counter drops by exactly the removed point")
	veg.free()

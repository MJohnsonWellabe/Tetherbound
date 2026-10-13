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


## Realm-load profile: registered keys are also filed by cell, and a clearing
## reads only the cells under it. It must still remove exactly the points
## inside the circle, including one in a cell across a negative boundary.
func _register_indexed(veg: Node3D, key: String, at: Vector3) -> Node3D:
	var point := _register_point(veg, key, at)
	var cell := Vector2i(floori(at.x / VEGETATION.HARVEST_CELL_M), floori(at.z / VEGETATION.HARVEST_CELL_M))
	var cells: Dictionary = veg.get("_harvest_cells")
	if not cells.has(cell):
		cells[cell] = []
	(cells[cell] as Array).append(key)
	veg.set("_harvest_indexed", int(veg.get("_harvest_indexed")) + 1)
	return point


func test_indexed_clearing_removes_exactly_the_points_inside() -> void:
	var veg: Node3D = VEGETATION.new()
	var inside_a := _register_indexed(veg, "fibre#1", Vector3(-1.0, 0.0, -1.0))
	var inside_b := _register_indexed(veg, "fibre#2", Vector3(3.0, 0.0, 2.0))
	var edge_out := _register_indexed(veg, "fibre#3", Vector3(5.5, 0.0, 0.0))
	var far := _register_indexed(veg, "fibre#4", Vector3(400.0, 0.0, -300.0))
	veg.call("clear_area", Vector3.ZERO, 5.0)
	var lookup: Dictionary = veg.get("_harvest_lookup")
	assert_false(lookup.has("fibre#1") or lookup.has("fibre#2"), "both points inside go, across cells")
	assert_true(inside_a.is_queued_for_deletion() and inside_b.is_queued_for_deletion())
	assert_true(lookup.has("fibre#3") and lookup.has("fibre#4"), "points outside stay")
	assert_false(edge_out.is_queued_for_deletion() or far.is_queued_for_deletion())
	assert_eq(int(veg.get("_harvest_points")), 2)
	veg.free()


func test_collision_candidates_are_the_cells_under_the_circle_highest_first() -> void:
	var veg: Node3D = VEGETATION.new()
	var cell_m := float(veg.get("COLLISION_STREAM_CELL"))
	var batch := {"placements": [{"position": Vector3(1, 0, 1)}, {"position": Vector3(cell_m * 5, 0, 0)},
		{"position": Vector3(-1, 0, -1)}], "cells": {}}
	veg.call("_reindex_batch_cells", batch)
	var near: PackedInt32Array = veg.call("_batch_candidates_desc", batch, Vector3.ZERO, 2.0)
	assert_eq(Array(near), [2, 0], "only the two placements in cells under the circle, highest index first")
	batch["cells"] = {}
	assert_eq(Array(veg.call("_batch_candidates_desc", batch, Vector3.ZERO, 2.0)), [2, 1, 0], "no index: every placement")
	veg.free()

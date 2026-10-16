extends "res://tests/test_case.gd"

## F03 (vault). `vegetation.gd::clear_area()` must remove EVERY layer's gather
## point inside the circle, not only the collidable layers'. A harvestable
## non-collidable layer (fibre, prompt "Gather") has no collision batch; before
## this it kept an invisible, actionable prompt in cleared ground, and in the
## Burrow Warrens vault it won the interaction arbiter over the Heartstone:
##   smoke_warrens --vault-activity: "the Heartstone prompt never won the
##   interaction arbiter; winner={"label": "Gather", "distance": 0.64, ...}"

const VEGETATION := preload("res://scripts/world/vegetation.gd")


class ClearingTerrain extends Node3D:
	var vertex_spacing := 2.0


class ClearingRegion extends RefCounted:
	var region_size := 256
	var instances: Dictionary = {}
	func get_instances() -> Dictionary:
		return instances


class ClearingData extends RefCounted:
	var region := ClearingRegion.new()
	func get_region_locations() -> Array[Vector2i]:
		return [Vector2i(-1, 0)]
	func get_region(_location: Vector2i) -> Object:
		return region


class ClearingAsset extends RefCounted:
	var height_offset := 2.0


class ClearingAssets extends RefCounted:
	var asset := ClearingAsset.new()
	func get_mesh_asset(_id: int) -> Object:
		return asset


class ClearingInstancer extends RefCounted:
	var data: ClearingData
	var clears: Array = []
	func clear_by_location(location: Vector2i, mesh_id: int) -> void:
		clears.append([location, mesh_id])
		data.region.instances.erase(mesh_id)


func test_render_clear_batches_region_and_preserves_survivor_transform_and_colour() -> void:
	var veg: Node3D = VEGETATION.new()
	var terrain := ClearingTerrain.new()
	var data := ClearingData.new()
	var assets := ClearingAssets.new()
	var instancer := ClearingInstancer.new()
	instancer.data = data
	veg.set("_terrain", terrain)
	veg.set("_data", data)
	veg.set("_assets", assets)
	veg.set("_instancer", instancer)
	# Negative region, non-unit vertex spacing, and a tilted/scaled UP axis.
	# The height offset moves X too; selection must use the original point.
	var basis := Basis(Vector3(1, 0, 0), Vector3(1, 2, 0), Vector3(0, 0, 1))
	var inside := Transform3D(basis, Vector3(12, 7, 10) + basis.y * 2.0)
	var edge := Transform3D(basis, Vector3(17, 7, 10) + basis.y * 2.0)
	var outside := Transform3D(basis, Vector3(18, 7, 10) + basis.y * 2.0)
	var distant := Transform3D(basis, Vector3(200, 7, 100) + basis.y * 2.0)
	var mixed: Array[Transform3D] = [inside, outside]
	var empty_after: Array[Transform3D] = [edge]
	var unchanged: Array[Transform3D] = [distant]
	var untouched_triple := [unchanged, PackedColorArray([Color.BLUE]), false]
	data.region.instances = {3: {
		Vector2i(0, 0): [mixed, PackedColorArray([Color.RED, Color.GREEN]), false],
		Vector2i(1, 0): [empty_after, PackedColorArray([Color.WHITE]), false],
		Vector2i(6, 3): untouched_triple,
	}, 9: {Vector2i.ZERO: untouched_triple}}
	var ids: Array[int] = [3]
	veg.call("_clear_render_area", Vector3(-500, 0, 10), 25.0, ids)
	assert_eq(instancer.clears, [[Vector2i(-1, 0), 3]], "one release for two changed cells")
	var kept: Dictionary = data.region.instances[3]
	assert_false(kept.has(Vector2i(1, 0)), "empty cells leave no phantom instances")
	assert_eq(kept[Vector2i(0, 0)][0], [outside], "survivor basis/origin are untouched")
	assert_eq(kept[Vector2i(0, 0)][1], PackedColorArray([Color.GREEN]), "colour follows its transform")
	assert_true(kept[Vector2i(0, 0)][2], "changed cell is marked for the existing refresh")
	assert_eq(kept[Vector2i(6, 3)], untouched_triple, "distant cell is retained")
	assert_true(data.region.instances.has(9), "another model is never released")
	veg.call("_clear_render_area", Vector3(-500, 0, 10), 25.0, ids)
	assert_eq(instancer.clears.size(), 1, "repeating a clear does not reallocate unchanged cells")
	veg.free()
	terrain.free()


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

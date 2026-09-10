extends "res://tests/test_case.gd"
const MATERIAL := preload("res://tests/helpers/meadows_earned_material_segment.gd")
const AUTHORED := preload("res://scripts/world/harvest_node.gd")
const SCATTER := preload("res://scripts/world/vegetation_harvest_point.gd")

class ClosedBridge extends Node3D:
	func is_open() -> bool:
		return false

class OpenTerrainRoute extends RefCounted:
	func _boundary_approach(_target: Node3D) -> Dictionary:
		return {"required": false, "points": [], "gate": ""}

func _crossing() -> Dictionary:
	var terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	for row: Dictionary in terrain.crossings:
		if str(row.id) == "south_bridge":
			return row
	return {}

func test_closed_crossing_refuses_actual_rescue_edge_and_far_bank() -> void:
	var crossing := _crossing()
	assert_true(MATERIAL.before_crossing(Vector3(13, 0, 1240), crossing))
	assert_false(MATERIAL.before_crossing(Vector3(12, -8, 1325), crossing), "observed repeated rescue position is not supply ground")
	assert_false(MATERIAL.before_crossing(Vector3(8, 0, 1338), crossing))
	assert_false(MATERIAL.before_crossing(Vector3.ZERO, {}))
	var rotated := crossing.duplicate(true)
	rotated.carve.axis_deg = 90.0
	rotated.carve.centre = [0.0, 0.0]
	rotated.road = [[20.0, 0.0]]
	assert_true(MATERIAL.before_crossing(Vector3(20, 0, 0), rotated))
	assert_false(MATERIAL.before_crossing(Vector3(-20, 0, 0), rotated))

func check_live_supply(tree: SceneTree) -> void:
	var world := Node3D.new()
	tree.root.add_child(world)
	var player := CharacterBody3D.new()
	world.add_child(player)
	player.position = Vector3(0, 0, 1000)
	var bridge := ClosedBridge.new()
	bridge.name = "SouthBridge"
	world.add_child(bridge)
	var authored := AUTHORED.new()
	authored._item_id = "wood"
	world.add_child(authored)
	authored.position = Vector3(0, 0, 1100)
	var scatter := SCATTER.new()
	scatter._item_id = "wood"
	world.add_child(scatter)
	scatter.position = Vector3(0, 0, 1005)
	var route := MATERIAL.new()
	route._tree = tree
	route._world = world
	route._player = player
	route._boundary = OpenTerrainRoute.new()
	route._crossing = _crossing()
	assert_eq(route._nearest_supply("wood"), scatter, "authoring source must not outweigh actual walking distance")
	assert_eq(route._nearest_supply("wood", [scatter.get_instance_id()]), authored,
		"an exhausted physical target must yield to another live same-resource supply")
	scatter.position.y = 20
	assert_eq(route._nearest_supply("wood"), authored, "reject unwalkable rise")
	authored.position.z = 1338
	assert_eq(route._nearest_supply("wood"), null, "do not gather across an unearned crossing")
	assert_eq(route._nearest_supply("fiber"), null)
	world.free()

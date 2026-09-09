extends "res://tests/test_case.gd"

const WATER_WORLD := preload("res://scripts/world/water_world.gd")
const REALM_GATE := preload("res://scripts/world/realm_gate.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const STORMWOOD_WORLD := preload("res://scripts/world/stormwood_world.gd")
const STORMWOOD_FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const STORMHEART := preload("res://scripts/world/stormheart_tree.gd")


class WorldFixture extends RefCounted:
	var flags: RefCounted = PROGRESSION.new()


class GameFixture extends Node:
	var world: RefCounted
	var progression: RefCounted = PROGRESSION.new()
	var entered_realm := ""
	var entered_at := ""
	var enter_calls := 0

	func enter_realm(realm: String, entry_id: String = "") -> void:
		enter_calls += 1
		entered_realm = realm
		entered_at = entry_id


func _mounted_gate() -> Dictionary:
	var water := WATER_WORLD.new()
	water.config = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_world.json"))
	water.call("_build_return_gate")
	return {"world": water, "gate": water.get_node_or_null(^"StormwoodReturnRealmGate")}


func _collision_child(body: Node) -> CollisionShape3D:
	for child in body.get_children():
		if child is CollisionShape3D:
			return child as CollisionShape3D
	return null


func _point_in_triangle_xz(point: Vector2, a: Vector3, b: Vector3, c: Vector3) -> bool:
	var p0 := Vector2(a.x, a.z)
	var p1 := Vector2(b.x, b.z)
	var p2 := Vector2(c.x, c.z)
	var denominator := (p1.y - p2.y) * (p0.x - p2.x) + (p2.x - p1.x) * (p0.y - p2.y)
	if absf(denominator) < 0.000001:
		return false
	var u := ((p1.y - p2.y) * (point.x - p2.x) + (p2.x - p1.x) * (point.y - p2.y)) / denominator
	var v := ((p2.y - p0.y) * (point.x - p2.x) + (p0.x - p2.x) * (point.y - p2.y)) / denominator
	var w := 1.0 - u - v
	return u >= -0.0001 and v >= -0.0001 and w >= -0.0001


func _collision_floor_y(shape: ConcavePolygonShape3D, point: Vector2) -> float:
	var faces := shape.get_faces()
	for index in range(0, faces.size(), 3):
		var a: Vector3 = faces[index]
		var b: Vector3 = faces[index + 1]
		var c: Vector3 = faces[index + 2]
		if absf(a.y - b.y) < 0.0001 and absf(a.y - c.y) < 0.0001 \
				and _point_in_triangle_xz(point, a, b, c):
			return a.y
	return NAN


func test_water_mounts_generic_return_gate_at_authored_connection() -> void:
	var mounted := _mounted_gate()
	var water: Node3D = mounted.world
	var gate: Node3D = mounted.gate
	assert_true(gate != null, "Water world did not mount StormwoodReturnRealmGate")
	if gate != null:
		var script := gate.get_script() as Script
		assert_eq(script.resource_path, "res://scripts/world/realm_gate.gd")
		assert_eq(gate.destination_realm, "stormwood")
		assert_eq(gate.destination_entry_id, "stormwood_departure_to_water")
		assert_eq(gate.key_flag, "", "return gate must have no second key/unlock path")
		assert_eq(gate.unlock_flag, "realm_gate_water_unlocked")
		assert_eq(gate.origin_realm, "water")
		assert_eq(gate.position, Vector3(12.0, 1.881, 162.0))
	water.free()


func test_stormwood_arrival_preserves_authored_stormheart_deck_height() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_world.json"))
	var anchor: Dictionary = config.transition_points.water_departure
	var stormwood := STORMWOOD_WORLD.new()
	var arrival: Vector3 = stormwood.resolve_entry_position(anchor)
	assert_eq(str(anchor.id), "stormwood_departure_to_water")
	assert_eq(str(anchor.arrival_height_policy), "authored")
	assert_eq(arrival, Vector3(-100.0, 262.21, 5501.0))

	var field := STORMWOOD_FIELD.new()
	var tree := STORMHEART.new()
	tree.simulation_only = true
	tree.position = Vector3(-100.0, field.height_at(-100.0, 5470.0), 5470.0)
	tree.build()
	var core := tree.get_node_or_null(^"DynamoCore") as StaticBody3D
	assert_true(core != null, "production Stormheart did not build its physical core ring")
	if core != null:
		var collision := _collision_child(core)
		assert_true(collision != null and collision.shape is ConcavePolygonShape3D,
			"production Stormheart core ring lacks its trimesh collision")
		if collision != null and collision.shape is ConcavePolygonShape3D:
			var local_arrival := arrival - tree.position
			var collision_y := _collision_floor_y(collision.shape as ConcavePolygonShape3D,
				Vector2(local_arrival.x, local_arrival.z))
			assert_false(is_nan(collision_y),
				"authored arrival XZ has no horizontal production core collision below it")
			if not is_nan(collision_y):
				assert_almost_eq(collision_y, STORMHEART.CORE_HEIGHT, 0.001)
				assert_true(local_arrival.y > collision_y,
					"authored arrival must retain its clearance above the core collision")
	assert_true(arrival.y > field.height_at(arrival.x, arrival.z) + 100.0,
		"terrain re-grounding would discard the authored elevated deck")
	tree.free()
	stormwood.free()


func test_stormwood_existing_cloudreach_entry_keeps_its_authored_position() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_world.json"))
	var anchor: Dictionary = config.transition_points.cloudreach_entry
	var stormwood := STORMWOOD_WORLD.new()
	var resolved: Vector3 = stormwood.resolve_entry_position(anchor)
	var authored: Array = anchor.position
	var field := STORMWOOD_FIELD.new()
	assert_eq(str(anchor.id), "stormwood_arrival_from_cloudreach")
	assert_false(anchor.has("arrival_height_policy"),
		"ground-level Cloudreach entry must keep the default terrain policy")
	assert_eq(Vector2(resolved.x, resolved.z), Vector2(float(authored[0]), float(authored[2])))
	assert_almost_eq(resolved.y, field.height_at(resolved.x, resolved.z) + 0.3, 0.001,
		"unmarked Cloudreach entry must preserve the existing terrain placement")
	stormwood.free()


func test_return_refuses_personal_unlock_and_water_key_shortcuts_without_mutation() -> void:
	var mounted := _mounted_gate()
	var water: Node3D = mounted.world
	var gate: Node3D = mounted.gate
	var game := GameFixture.new()
	game.world = WorldFixture.new()
	game.progression.set_flag("realm_gate_water_unlocked")
	game.world.flags.set_flag("realm_key_water")
	var before_world: Dictionary = game.world.flags.save_data()
	var before_player: Dictionary = game.progression.save_data()
	assert_eq(gate.call("state_for", game), REALM_GATE.STATE_LOCKED,
		"a personal lookalike flag must not open the shared return gate")
	assert_false(gate.call("try_unlock", game),
		"the consumed Water key must not become a second return unlock")
	assert_false(gate.call("try_enter", game))
	assert_eq(game.enter_calls, 0)
	assert_eq(game.world.flags.save_data(), before_world)
	assert_eq(game.progression.save_data(), before_player)
	water.free()
	game.free()


func test_durable_world_unlock_routes_to_existing_stormwood_destination_without_key_write() -> void:
	var mounted := _mounted_gate()
	var water: Node3D = mounted.world
	var gate: Node3D = mounted.gate
	var game := GameFixture.new()
	game.world = WorldFixture.new()
	game.world.flags.set_flag("realm_gate_water_unlocked")
	var before: Dictionary = game.world.flags.save_data()
	assert_eq(gate.call("state_for", game), REALM_GATE.STATE_UNLOCKED)
	assert_true(gate.call("try_enter", game))
	assert_eq(game.enter_calls, 1)
	assert_eq(game.entered_realm, "stormwood")
	assert_eq(game.entered_at, "stormwood_departure_to_water")
	assert_eq(game.world.flags.save_data(), before,
		"return travel must not consume, restore, or mint any key/flag")
	assert_false(game.world.flags.has("realm_key_water"))
	water.free()
	game.free()


func test_shared_world_unlock_opens_same_return_path_for_a_second_peer() -> void:
	var mounted := _mounted_gate()
	var water: Node3D = mounted.world
	var gate: Node3D = mounted.gate
	var shared_world := WorldFixture.new()
	shared_world.flags.set_flag("realm_gate_water_unlocked")
	var first := GameFixture.new()
	first.world = shared_world
	var second := GameFixture.new()
	second.world = shared_world
	second.progression.set_flag("unrelated_personal_progress")
	assert_eq(gate.call("state_for", first), REALM_GATE.STATE_UNLOCKED)
	assert_eq(gate.call("state_for", second), REALM_GATE.STATE_UNLOCKED,
		"a later peer reads the shared Water gate fact from world authority")
	assert_true(gate.call("try_enter", second))
	assert_eq(second.entered_realm, "stormwood")
	assert_eq(second.entered_at, "stormwood_departure_to_water")
	assert_eq(first.enter_calls, 0, "one peer's local route call does not move another peer")
	water.free()
	first.free()
	second.free()

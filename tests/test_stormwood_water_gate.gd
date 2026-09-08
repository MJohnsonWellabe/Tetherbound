extends "res://tests/test_case.gd"

const GATE := preload("res://scripts/world/stormwood_water_gate.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")


class Saver extends RefCounted:
	var fail_write := false
	var writes := 0
	var store := WORLD_SAVE.new("user://stormwood_water_gate_%d/" % Time.get_ticks_usec())
	func save_world(game: Object, id: String) -> bool:
		writes += 1
		var snapshot: Dictionary = game.world.save_data()
		snapshot.progression = game.world.flags.save_data()
		return false if fail_write else store.write(id, WORLD_SAVE.partition(snapshot))


class GameFixture extends RefCounted:
	var host := true
	var world: RefCounted = WORLD.new()
	var save_system: RefCounted = Saver.new()
	func is_host() -> bool:
		return host


class RouteFixture extends Node:
	var progression: RefCounted
	var session: Node
	var entered_realm := ""
	var entered_at := ""
	var preauthorised := false
	func enter_realm(realm: String, entry: String = "", bypass_gate: bool = false) -> void:
		entered_realm = realm
		entered_at = entry
		preauthorised = bypass_gate


class SessionFixture extends Node:
	var requested: Dictionary = {}
	func request_stormwood_encounter(intent: Dictionary) -> void:
		requested = intent.duplicate(true)


func fixture() -> RefCounted:
	var game := GameFixture.new()
	game.world.world_id = "stormwood-water-gate-world"
	game.world.flags.set_flag(GATE.WATERWARD_FLAG)
	game.world.flags.set_flag(GATE.WATER_KEY_FLAG)
	return game


func test_unlock_consumes_key_and_opens_gate_in_one_saved_delta() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var result: Dictionary = GATE.host_commit(game, ledger)
	assert_true(result.ok)
	assert_eq(result.code, "opened")
	assert_false(game.world.flags.has(GATE.WATER_KEY_FLAG))
	assert_true(game.world.flags.has(GATE.WATER_GATE_FLAG))
	assert_eq(result.delta.ops.size(), 2)
	assert_eq(result.delta.ops[0].id, GATE.WATER_KEY_FLAG)
	assert_false(result.delta.ops[0].value)
	assert_eq(result.delta.ops[1].id, GATE.WATER_GATE_FLAG)
	assert_true(result.delta.ops[1].value)
	assert_eq(game.save_system.writes, 1)
	var restored := WORLD.new()
	restored.load_data(game.save_system.store.read(game.world.world_id))
	assert_false(restored.flags.has(GATE.WATER_KEY_FLAG))
	assert_true(restored.flags.has(GATE.WATER_GATE_FLAG))


func test_failed_journal_restores_key_unlock_revision_and_sequence() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var before: Dictionary = game.world.save_data()
	var revision := int(game.world.revision)
	var sequence := int(ledger.seq)
	game.save_system.fail_write = true
	var result: Dictionary = GATE.host_commit(game, ledger)
	assert_false(result.ok)
	assert_eq(result.code, "journal_failed")
	assert_eq(game.world.save_data(), before)
	assert_eq(game.world.revision, revision)
	assert_eq(ledger.seq, sequence)
	assert_true(game.world.flags.has(GATE.WATER_KEY_FLAG))
	assert_false(game.world.flags.has(GATE.WATER_GATE_FLAG))


func test_unlock_requires_host_waterward_key_and_host_observed_proximity() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	game.host = false
	assert_eq(GATE.host_commit(game, ledger).code, "not_host")
	game.host = true
	game.world.flags.set_flag(GATE.WATERWARD_FLAG, false)
	assert_eq(GATE.host_commit(game, ledger).code, "waterward_hidden")
	game.world.flags.set_flag(GATE.WATERWARD_FLAG)
	game.world.flags.set_flag(GATE.WATER_KEY_FLAG, false)
	assert_eq(GATE.host_commit(game, ledger).code, "missing_key")
	game.world.flags.set_flag(GATE.WATER_KEY_FLAG)
	assert_true(GATE.request_allowed(game.world.flags, Vector3(1, 2, 3), Vector3(4, 2, 3), 6.0))
	assert_false(GATE.request_allowed(game.world.flags, Vector3(1, 2, 3), Vector3(8, 2, 3), 6.0))
	assert_false(GATE.request_allowed(game.world.flags, Vector3(NAN, 2, 3), Vector3(4, 2, 3), 6.0))


func test_open_gate_is_idempotent_and_routes_to_authored_water_arrival() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	assert_true(GATE.host_commit(game, ledger).ok)
	var writes := int(game.save_system.writes)
	var sequence := int(ledger.seq)
	var repeated: Dictionary = GATE.host_commit(game, ledger)
	assert_true(repeated.ok)
	assert_eq(repeated.code, "already_open")
	assert_true(repeated.delta.ops.is_empty())
	assert_eq(game.save_system.writes, writes)
	assert_eq(ledger.seq, sequence)

	var route := RouteFixture.new()
	route.progression = game.world.flags
	route.session = SessionFixture.new()
	var gate := GATE.new()
	gate.call("setup", "water", "water_arrival_from_stormwood", "Water Archipelago",
		GATE.WATER_KEY_FLAG, GATE.WATER_GATE_FLAG)
	assert_true(gate.call("try_enter", route))
	assert_eq(route.entered_realm, "water")
	assert_eq(route.entered_at, "water_arrival_from_stormwood")
	assert_true(route.preauthorised, "the opened physical gate replaces the consumed key check")
	gate.free()
	route.session.free()
	route.free()


func test_production_gate_is_within_content_floor_of_waterward_view() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_world.json"))
	var departure: Array = parsed.transition_points.water_departure.position
	var gate_position := Vector3(float(departure[0]), float(departure[1]), float(departure[2]))
	var view_position := Vector3(-100.0, 262.21, 5487.0)
	assert_true(gate_position.distance_to(view_position) <= 120.0)
	assert_almost_eq(gate_position.distance_to(view_position), 14.0, 0.01,
		"the ordinary gate is the next interaction on the existing Dynamo platform")
	var ending := FileAccess.get_file_as_string("res://scripts/world/stormwood_ending.gd")
	assert_true(ending.contains("_build_water_gate()"))
	assert_true(ending.contains("WATER_GATE.host_commit"))
	assert_true(ending.contains("publish_journaled_delta"))
	var gate_source := FileAccess.get_file_as_string(
		"res://scripts/world/stormwood_water_gate.gd")
	assert_true(gate_source.contains("prompt.activated.connect(_on_water_activated)"),
		"Water must replace the generic key-retaining prompt handler on the production input seam")

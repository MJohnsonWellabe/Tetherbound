extends SceneTree

## A small production interaction fixture. It supplies only the chapter flags
## needed to reach the Crown objective; it does not claim Wen, the guardian, or
## the route to the island were played here.
const CROWN := preload("res://scripts/world/stormwood_crown.gd")
const EVENTS := preload("res://scripts/world/realm_chapter_events.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")

var failures: Array[String] = []
var assertions := 0


class FixtureWorld extends Node3D:
	var simulation_only := false

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	_check(game != null, "Game autoload is available")
	if game == null:
		_finish()
		return
	game.reset_for_new_game()
	game.current_realm = "stormwood"
	var world := FixtureWorld.new()
	world.name = "CrownHeartstoneFixture"
	root.add_child(world)
	var player := _player()
	world.add_child(player)
	var arbiter := ARBITER.new()
	arbiter.name = "InteractionArbiter"
	arbiter.player_path = NodePath("../Player")
	world.add_child(arbiter)
	var chapter := EVENTS.new()
	chapter.name = "StormwoodChapter"
	chapter.realm_id = "stormwood"
	chapter.chapter = _chapter_data()
	world.add_child(chapter)
	var heartstone := CROWN.new()
	heartstone.name = "CrownHeartstone"
	world.add_child(heartstone)
	heartstone.mount(world)
	await process_frame
	await physics_frame

	player.global_position = heartstone.global_position + Vector3(0, 0, -2.5)
	arbiter.call("_recompute")
	_check(arbiter.activate(), "the real heartstone prompt dispatches through InteractionArbiter")
	_check(not game.progression.has("stormwood:rootgate_released"),
		"an early heartstone touch cannot release the Rootgate")

	# Fixture prerequisites establish only the state the Crown interaction is
	# allowed to consume. They intentionally do not impersonate Wen or a fight.
	for flag: String in ["stormwood:act_i_complete", "stormwood:crown_reached",
			"stormwood:engine_truth_learned"]:
		game.progression.set_flag(flag)
	heartstone.restore_progression_from_game(game)
	arbiter.call("_recompute")
	var before := int(game.progression.get("revision"))
	_check(arbiter.activate(), "the same production prompt accepts after Crown and truth prerequisites")
	await process_frame
	_check(game.progression.has("stormwood:rootgate_released"),
		"heartstone event reaches shared chapter-events dispatch and writes Rootgate")
	_check(int(game.progression.get("revision")) > before, "the successful event changes shared progression")
	var after := int(game.progression.get("revision"))
	arbiter.call("_recompute")
	_check(not arbiter.activate(), "opened heartstone disables its interaction offer")
	_check(int(game.progression.get("revision")) == after, "a repeated touch cannot add progression revision")

	var saved: Dictionary = game.world.save_data()
	game.world.load_data({})
	_check(not game.progression.has("stormwood:rootgate_released"), "fresh world data removes the shared Rootgate flag")
	game.world.load_data(saved)
	_check(game.progression.has("stormwood:engine_truth_learned") and
		game.progression.has("stormwood:crown_reached") and
		game.progression.has("stormwood:rootgate_released"),
		"world save/load preserves Crown prerequisite and released Rootgate flags")
	world.queue_free()
	await process_frame
	_finish()


func _chapter_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_chapter.json"))
	return parsed if parsed is Dictionary else {}


func _player() -> CharacterBody3D:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.collision_layer = 1
	player.collision_mask = 1
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	return player


func _check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _finish() -> void:
	for failure: String in failures:
		push_error("STORMWOOD CROWN HEARTSTONE: " + failure)
	print("STORMWOOD CROWN HEARTSTONE: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)

extends SceneTree

## Production interaction fixture for `stormwood_crown_remembers`. The real
## record node, interaction arbiter and chapter-events writer run; a fixture
## panel stands in for the dialogue UI and finishes each conversation on
## request. Flags needed to stand on the Crown are staged and disclosed here;
## the route to the island and Wen's conversation UI are not played.
const RECORDS := preload("res://scripts/world/stormwood_crown_records.gd")
const EVENTS := preload("res://scripts/world/realm_chapter_events.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")

var failures: Array[String] = []
var assertions := 0


class FixtureWorld extends Node3D:
	var simulation_only := false

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


class FixturePanel extends Node:
	signal finished(conversation_id: String)
	var started: Array[String] = []
	var _open := ""

	func is_open() -> bool:
		return _open != ""

	func start(conversation_id: String) -> bool:
		started.append(conversation_id)
		_open = conversation_id
		return true

	func finish() -> void:
		var id := _open
		_open = ""
		finished.emit(id)


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
	world.name = "CrownRecordsFixture"
	root.add_child(world)
	var player := _player()
	world.add_child(player)
	var arbiter := ARBITER.new()
	arbiter.name = "InteractionArbiter"
	arbiter.player_path = NodePath("../Player")
	world.add_child(arbiter)
	var panel := FixturePanel.new()
	panel.name = "DialoguePanel"
	world.add_child(panel)
	var chapter := EVENTS.new()
	chapter.name = "StormwoodChapter"
	chapter.realm_id = "stormwood"
	chapter.chapter = _chapter_data()
	world.add_child(chapter)
	var records := RECORDS.new()
	records.name = "CrownRecords"
	world.add_child(records)
	records.mount(world)
	await process_frame
	await physics_frame

	var first: Node3D = records.get_node("CrownRecord_rain_ledger/RecordInteractable")
	_stand_at(player, first)
	await physics_frame
	arbiter.call("_recompute")
	_check(not arbiter.activate(), "a record cannot be read before the Crown is reached")
	_check(panel.started.is_empty(), "no record text opens before the Crown is reached")

	for flag: String in ["stormwood:act_i_complete", "stormwood:crown_reached"]:
		game.progression.set_flag(flag)
	records.restore_progression_from_game(game)
	for record_id: String in RECORDS.record_ids():
		var prompt: Node3D = records.get_node("CrownRecord_%s/RecordInteractable" % record_id)
		_stand_at(player, prompt)
		await physics_frame
		arbiter.call("_recompute")
		_check(arbiter.activate(), "the production prompt opens %s at the Crown" % record_id)
		_check(panel.started.back() == RECORDS.conversation_for(record_id),
			"%s plays its authored conversation" % record_id)
		panel.finish()
		await process_frame
		_check(game.progression.has(RECORDS.count_flag_for(record_id)),
			"finishing %s writes its record fact through chapter events" % record_id)
		if record_id == "rain_ledger":
			_check(game.progression.has("stormwood:side_crown_remembers_1"), "the first record finds the chain")
			_check(not game.progression.has("stormwood:side_crown_remembers_2"), "one record is not the account")
			var revision := int(game.progression.get("revision"))
			arbiter.call("_recompute")
			_check(arbiter.activate(), "a read record can be reread")
			panel.finish()
			await process_frame
			_check(int(game.progression.get("revision")) == revision, "rereading adds no progression revision")
	_check(game.progression.has("stormwood:side_crown_remembers_2"), "three records complete the reading")
	_check(not game.progression.has("stormwood:side_crown_remembers_complete"), "the chain waits for Wen")
	_check(not game.progression.has("stormwood:engine_truth_learned") \
		and not game.progression.has("stormwood:rootgate_released"),
		"reading records cannot shortcut the main Heartstone story")
	chapter.emit_event("side:stormwood_crown_remembers:step_3")
	_check(game.progression.has("stormwood:side_crown_remembers_complete"), "Wen's report completes the chain")

	var saved: Dictionary = game.world.save_data()
	game.world.load_data({})
	_check(not game.progression.has("stormwood:side_crown_remembers_complete"), "fresh world data clears the chain")
	game.world.load_data(saved)
	var all_read := true
	for record_id: String in RECORDS.record_ids():
		all_read = all_read and game.progression.has(RECORDS.count_flag_for(record_id))
	_check(all_read and game.progression.has("stormwood:side_crown_remembers_complete"),
		"world save/load keeps every record fact and the completed chain")
	world.queue_free()
	await process_frame
	await process_frame
	_finish()


## Stand on the record's reading face, 1.2 m out from its prompt.
func _stand_at(player: Node3D, prompt: Node3D) -> void:
	player.global_position = prompt.global_position + Vector3(0, -0.9, 0) \
		- prompt.global_transform.basis.z * 1.2


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
		push_error("FAIL: " + failure)
	print("STORMWOOD CROWN RECORDS %s: %d assertions, %d failures" % [
		"OK" if failures.is_empty() else "FAILED", assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)

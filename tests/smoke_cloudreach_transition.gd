extends SceneTree

## End-to-end Phase 1 realm smoke using the production Game router and both
## production world scenes. It begins at a real physical RealmGate, enters
## Cloudreach at its authored anchor, uses the return gate, then proves the
## Meadows consumes its own authored Storm Road return anchor.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const REALM_GATE := preload("res://scripts/world/realm_gate.gd")
const TEST_SAVE_DIR := "user://cloudreach_transition_smoke"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	var progression: RefCounted = game.get("progression")
	progression.call("set_flag", "realm_key_cloudreach")
	var source := Node3D.new()
	source.name = "TransitionSmokeSource"
	root.add_child(source)
	current_scene = source
	var gate: Node3D = REALM_GATE.new()
	gate.call("setup", "cloudreach", "cloudreach_arrival_from_meadows", "Cloudreach Cliffs",
		"realm_key_cloudreach", "realm_gate_cloudreach_unlocked")
	source.add_child(gate)
	await process_frame
	_expect(str(gate.call("current_state")) == REALM_GATE.STATE_UNLOCKABLE,
		"Meadows gate did not see the durable Realm Key", failures)
	_expect(bool(gate.call("try_unlock", game)), "Meadows gate refused the Realm Key", failures)
	_expect(bool(gate.call("try_enter", game)), "Meadows gate did not issue the realm transition", failures)
	var cloudreach := await _wait_for_scene("CloudreachCliffs", 600)
	_expect(cloudreach != null, "Cloudreach scene never became current", failures)
	if cloudreach != null:
		await _wait_for_entry_settle(game, 120)
		var player := cloudreach.get_node_or_null(^"Player") as CharacterBody3D
		var anchor: Dictionary = cloudreach.call("entry_anchor", "cloudreach_arrival_from_meadows")
		var expected := _vec3(anchor.get("position", []))
		_expect(player != null and Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(expected.x, expected.z)) < 1.0,
			"Cloudreach did not consume the authored Meadows arrival", failures)
		_expect(str(game.get("pending_realm_entry")) == "", "Cloudreach did not settle its pending entry", failures)
		var return_gate := cloudreach.get_node_or_null(^"MeadowsReturnRealmGate")
		_expect(return_gate != null, "Cloudreach has no physical return gate", failures)
		if return_gate != null:
			_expect(str(return_gate.call("current_state")) == REALM_GATE.STATE_UNLOCKED,
				"Cloudreach return gate forgot the durable unlock", failures)
			_expect(bool(return_gate.call("try_enter", game)), "Cloudreach return gate did not issue return travel", failures)
	var meadows := await _wait_for_scene("MeadowsPlayground", 3600)
	_expect(meadows != null, "Meadows scene never became current on return", failures)
	if meadows != null:
		# Meadows builds its streamed terrain and authored dressing synchronously
		# before the deferred arrival autosave gets an idle turn. Wait on the
		# state contract rather than assuming a fixed two-frame schedule.
		await _wait_for_entry_settle(game, 240)
		var returned := meadows.get_node_or_null(^"Player") as CharacterBody3D
		_expect(returned != null and Vector2(returned.global_position.x, returned.global_position.z).distance_to(Vector2(-33.5, 7494.0)) < 1.5,
			"Meadows did not consume the authored Storm Road return anchor", failures)
		_expect(meadows.get_node_or_null(^"CloudreachRealmGate") != null,
			"the physical Storm Road realm gate is missing", failures)
		_expect(meadows.get_node_or_null(^"MeadowsRealmHeartShrine") != null,
			"the physical Meadows Heart shrine is missing", failures)
	_expect(str(game.get("current_realm")) == "meadows", "Game did not finish in the Meadows", failures)
	_expect(str(game.get("pending_realm_entry")) == "", "Meadows did not settle the return entry", failures)
	_cleanup_test_saves()
	if failures.is_empty():
		print("CLOUDREACH TRANSITION OK meadows -> cloudreach -> meadows")
		quit(0)
		return
	for failure: String in failures:
		push_error("CLOUDREACH TRANSITION: %s" % failure)
	quit(1)


func _wait_for_scene(expected_name: String, frames: int) -> Node:
	for _frame in frames:
		await process_frame
		var scene := current_scene
		if scene != null and scene.name == expected_name:
			# Give the destination's deferred arrival autosave time to settle.
			await physics_frame
			await physics_frame
			await process_frame
			return scene
	return null


func _wait_for_entry_settle(game: Node, frames: int) -> void:
	for _frame in frames:
		if str(game.get("pending_realm_entry")) == "":
			return
		await process_frame


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _vec3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO


func _cleanup_test_saves() -> void:
	var absolute := ProjectSettings.globalize_path(TEST_SAVE_DIR)
	var dir := DirAccess.open(absolute)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute)

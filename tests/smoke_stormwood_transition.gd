extends SceneTree

## Production Phase 1 route proof for Cloudreach -> Stormwood -> Cloudreach.
##
## This is deliberately a scene/router/gate smoke, rather than a JSON or
## `enter_realm()` unit fixture.  It starts inside real Cloudreach, finds the
## mounted Stormward gate, proves the no-key denial, submits the real host
## ledger entitlement, and crosses through both production gates.  The waits
## are generous because each destination constructs its real world.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const REALM_GATE := preload("res://scripts/world/realm_gate.gd")
const TEST_SAVE_DIR := "user://stormwood_transition_smoke"
const SCENE_WAIT_FRAMES := 3600
const SETTLE_WAIT_FRAMES := 600

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	print("STORMWOOD TRANSITION: initializing production route smoke")
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	# This chapter follows a legitimately unlocked Cloudreach; only the next
	# chapter's entitlement is absent for the locked-Stormward assertion.
	game.get("ledger").call("submit", {"kind":"set_world_flag", "realm":"meadows", "id":"realm_key_cloudreach", "value":true})

	var source := Node3D.new()
	source.name = "StormwoodTransitionSmokeSource"
	root.add_child(source)
	current_scene = source
	await process_frame

	# The test enters the real Cloudreach scene only to reach its real mounted
	# gate.  This is a harness entry, not the Stormward crossing under test.
	print("STORMWOOD TRANSITION: loading Cloudreach")
	_expect(await game.call("enter_realm", "cloudreach", "cloudreach_arrival_from_meadows"),
		"router refused harness entry into Cloudreach")
	var cloudreach := await _wait_for_scene("CloudreachCliffs")
	_expect(cloudreach != null, "Cloudreach scene did not become current")
	if cloudreach == null:
		_finish()
		return
	await _wait_for_settle(game)

	var stormward := cloudreach.get_node_or_null(^"StormwardPassage/StormwardRealmGate")
	_expect(stormward != null, "real Cloudreach scene did not mount StormwardPassage/StormwardRealmGate")
	if stormward == null:
		_finish()
		return
	_expect(str(stormward.call("current_state")) == REALM_GATE.STATE_LOCKED,
		"Stormward gate was not locked before the Stormwood key")
	_expect(not bool(stormward.call("try_unlock", game)),
		"Stormward gate unlocked without realm_key_stormwood")
	_expect(not bool(stormward.call("try_enter", game)),
		"Stormward gate issued travel while locked")

	# The entitlement is a world fact.  Submit it through the production host
	# ledger instead of writing the progression fixture directly.
	var ledger: Node = game.get("ledger") as Node
	_expect(ledger != null, "Game did not mount its host ledger")
	if ledger != null:
		var verdict: Dictionary = ledger.call("submit", {
			"kind": "set_world_flag", "realm": "cloudreach",
			"id": "realm_key_stormwood", "value": true,
		})
		_expect(bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false)),
			"host ledger did not commit realm_key_stormwood: %s" % verdict)
	_expect(bool(game.call("world_flags").call("has", "realm_key_stormwood")),
		"host ledger grant did not reach the world flag store")
	await process_frame
	_expect(str(stormward.call("current_state")) == REALM_GATE.STATE_UNLOCKABLE,
		"Stormward gate did not become unlockable after host ledger entitlement")
	_expect(bool(stormward.call("try_unlock", game)), "Stormward gate refused its entitled unlock")
	_expect(bool(game.call("world_flags").call("has", "realm_key_stormwood")),
		"unlock consumed the durable Stormwood key")
	_expect(str(stormward.call("current_state")) == REALM_GATE.STATE_UNLOCKED,
		"Stormward gate did not become unlocked")

	var meadows_map: RefCounted = game.call("realm_map_for", "meadows")
	var cloudreach_map: RefCounted = game.call("realm_map_for", "cloudreach")
	_expect(bool(stormward.call("try_enter", game)), "unlocked Stormward gate did not issue entry")
	var stormwood := await _wait_for_scene("Stormwood")
	_expect(stormwood != null, "Stormwood scene did not become current")
	if stormwood == null:
		_finish()
		return
	await _wait_for_settle(game)
	_expect(str(game.get("current_realm")) == "stormwood", "router did not finish in Stormwood")
	_expect(str(game.get("pending_realm_entry")) == "", "Stormwood did not settle its pending entry")
	_expect(stormwood.get_node_or_null(^"Terrain") != null, "Stormwood did not construct real Terrain3D")
	var player := stormwood.get_node_or_null(^"Player") as CharacterBody3D
	_expect(player != null, "Stormwood has no live local Player")
	if player != null:
		var pos := player.global_position
		var ground := float(stormwood.call("ground_height_at", pos.x, pos.z))
		_expect(is_finite(pos.x) and is_finite(pos.y) and is_finite(pos.z), "Stormwood arrival placed Player at non-finite coordinates")
		_expect(is_finite(ground) and absf(pos.y - ground) < 2.0,
			"Stormwood Player did not settle near authored ground (y=%.2f, ground=%.2f)" % [pos.y, ground])

	var stormwood_map: RefCounted = game.call("realm_map_for", "stormwood")
	_expect(stormwood_map != null and stormwood_map != meadows_map and stormwood_map != cloudreach_map,
		"Stormwood map is not isolated from Meadows/Cloudreach map state")
	var autosave: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.get("save_system").call("slot_path", game.call("autosave_slot"))))
	_expect(str(autosave.get("current_realm", "")) == "stormwood", "settled Stormwood arrival did not autosave its realm")
	_expect(str((autosave.get("player_pose", {}) as Dictionary).get("realm", "")) == "stormwood",
		"settled Stormwood arrival did not autosave its player pose")

	var return_gate := stormwood.get_node_or_null(^"CloudreachReturnRealmGate")
	_expect(return_gate != null, "Stormwood did not construct CloudreachReturnRealmGate")
	if return_gate != null:
		_expect(str(return_gate.call("current_state")) == REALM_GATE.STATE_UNLOCKED,
			"Stormwood return gate did not inherit the world unlock")
		_expect(bool(return_gate.call("try_enter", game)), "Stormwood return gate did not issue Cloudreach return")
	var returned := await _wait_for_scene("CloudreachCliffs")
	_expect(returned != null, "Cloudreach scene did not return from Stormwood")
	if returned != null:
		await _wait_for_settle(game)
		_expect(str(game.get("current_realm")) == "cloudreach", "router did not finish return in Cloudreach")
		_expect(str(game.get("pending_realm_entry")) == "", "Cloudreach did not settle Stormwood return entry")
		var return_player := returned.get_node_or_null(^"Player") as CharacterBody3D
		var anchor: Dictionary = returned.call("entry_anchor", "cloudreach_return_from_stormwood")
		var expected: Vector3 = _vec3(anchor.get("position", []))
		_expect(return_player != null and return_player.global_position.distance_to(expected) < 3.0,
			"Cloudreach return did not consume cloudreach_return_from_stormwood")
	_finish()


func _wait_for_scene(expected_name: String) -> Node:
	for _frame in SCENE_WAIT_FRAMES:
		await process_frame
		if current_scene != null and current_scene.name == expected_name:
			return current_scene
	return null


func _wait_for_settle(game: Node) -> void:
	for _frame in SETTLE_WAIT_FRAMES:
		if str(game.get("pending_realm_entry")) == "":
			return
		await process_frame


func _vec3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	_cleanup_test_saves()
	if _failures.is_empty():
		print("STORMWOOD TRANSITION OK: Cloudreach gate -> Stormwood terrain -> Cloudreach return")
		quit(0)
		return
	for failure: String in _failures:
		push_error("STORMWOOD TRANSITION: %s" % failure)
	quit(1)


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

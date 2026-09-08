extends SceneTree

## Runtime proof for the Meadows procedural-build player hold.
##
## Three production paths in one process:
##   1. a fresh Meadows scene boot;
##   2. a second Meadows scene boot/reload;
##   3. Cloudreach -> Meadows through Game.enter_realm() with the authored
##      `meadows_cloudreach_gate_return` pending entry.
##
## The only progression fixture is `opening:beat:free_play`, set before the
## first departure so the production Player accepts movement input. Cloudreach
## is reached through production debug teleport solely to stage the other side
## of the return; the measured return itself uses ordinary `enter_realm()` with
## no bypass. Every disk write is redirected before reset to a unique test dir.
##
## The terminal wrapper must additionally scan the captured stderr/stdout and
## reject `_clamp_runaway_velocity` / `velocity ... exceeded ... ceiling`.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const MEADOWS_SCENE := "res://scenes/world/meadows_playground.tscn"
const RETURN_ENTRY := "meadows_cloudreach_gate_return"
const RETURN_XZ := Vector2(-33.5, 7494.0)
const SCENE_READY_FRAMES := 1800
const WATCHDOG_MSEC := 12 * 60 * 1000
const MOVE_FRAMES := 60
const MOVE_MIN_METRES := 1.0

var _failures: Array[String] = []
var _finished := false
var _saw_return_pending := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_watchdog.call_deferred()
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	# Replace the saver before reset: even a future reset-side write stays out of
	# the user's slots.
	var save_dir := "user://test_meadows_build_hold_%d_%d/" % [
		OS.get_process_id(), Time.get_ticks_usec()]
	game.set("save_system", SAVE_GAME.new(save_dir))
	game.call("reset_for_new_game")
	game.get("local").set("character_id", "meadows-build-hold-solo")
	game.get("world").set("world_id", "meadows-build-hold-world")
	game.get("progression").call("set_flag", "opening:beat:free_play")

	var source := Node3D.new()
	source.name = "MeadowsBuildHoldSource"
	root.add_child(source)
	current_scene = source
	await process_frame

	if not await _change_to_meadows(game, "fresh boot"):
		_finish()
		return
	await _assert_playable_meadows(game, "fresh boot")
	if not _failures.is_empty():
		_finish()
		return

	if not await _change_to_meadows(game, "same-process second boot"):
		_finish()
		return
	await _assert_playable_meadows(game, "same-process second boot")
	if not _failures.is_empty():
		_finish()
		return

	if not await _stage_cloudreach_with_production_router(game):
		_finish()
		return
	_observe_return_pending(game)
	var returned: bool = await game.call("enter_realm", "meadows", RETURN_ENTRY)
	_expect(returned, "production Cloudreach -> Meadows return was refused")
	_expect(_saw_return_pending,
		"the authored Meadows return never appeared as pending during the crossing")
	if not returned:
		_finish()
		return
	await _assert_playable_meadows(game, "authored solo realm return", RETURN_XZ)
	_finish()


func _change_to_meadows(game: Node, label: String) -> bool:
	var error := change_scene_to_file(MEADOWS_SCENE)
	if error != OK:
		_fail("%s scene request failed with %d" % [label, error])
		return false
	if not await _wait_for_realm_ready("meadows"):
		_fail("%s never mounted a ready Meadows scene" % label)
		return false
	_expect(str(game.get("current_realm")) == "meadows",
		"%s mounted Meadows while Game said %s" % [label, game.get("current_realm")])
	return true


func _wait_for_realm_ready(realm_id: String) -> bool:
	for _frame in SCENE_READY_FRAMES:
		await process_frame
		var scene := current_scene
		if scene == null:
			continue
		# A placeholder/outgoing scene with no readiness API is not the requested
		# production destination merely because it has no reason to say "false".
		if not scene.has_method("world_realm") \
				or str(scene.call("world_realm")) != realm_id:
			continue
		if scene.has_method("shell_build_complete") \
				and not bool(scene.call("shell_build_complete")):
			continue
		return true
	return false


func _assert_playable_meadows(game: Node, label: String,
		expected_xz: Vector2 = Vector2.INF) -> void:
	var world := current_scene
	_expect(world != null and world.has_method("ground_height_at"),
		"%s has no production ground" % label)
	_expect(str(game.get("pending_realm_entry")) == "",
		"%s left pending entry '%s'" % [label, game.get("pending_realm_entry")])
	var player := game.call("find_player") as CharacterBody3D
	if world == null or player == null:
		_fail("%s has no live Player" % label)
		return
	for _frame in 30:
		await physics_frame
	var before := player.global_position
	var ground := float(world.call("ground_height_at", before.x, before.z))
	_expect(before.is_finite() and is_finite(ground),
		"%s produced non-finite player/ground state: player=%s ground=%s" % [label, before, ground])
	_expect(player.process_mode != Node.PROCESS_MODE_DISABLED,
		"%s left Player's build hold active" % label)
	_expect(player.is_physics_processing(),
		"%s left Player physics disabled" % label)
	_expect(bool(player.call("locomotion_enabled")),
		"%s left production locomotion unavailable" % label)
	_expect(player.is_on_floor() and before.y >= ground - 0.1 and before.y <= ground + 2.0,
		"%s is not grounded after release: player=%s ground=%.2f" % [label, before, ground])
	if expected_xz != Vector2.INF:
		_expect(Vector2(before.x, before.z).distance_to(expected_xz) <= 1.0,
			"%s missed authored return %s: player=%s" % [label, expected_xz, before])

	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	if rig != null:
		rig.set("yaw", 0.0)
		rig.rotation = Vector3.ZERO
	Input.action_press("move_forward")
	for _frame in MOVE_FRAMES:
		await physics_frame
	Input.action_release("move_forward")
	for _frame in 10:
		await physics_frame
	var after := player.global_position
	var travelled := Vector2(after.x - before.x, after.z - before.z).length()
	_expect(travelled >= MOVE_MIN_METRES,
		"%s Player released but ordinary input moved only %.2fm" % [label, travelled])
	var after_ground := float(world.call("ground_height_at", after.x, after.z))
	_expect(after.is_finite() and is_finite(after_ground) and player.is_on_floor()
		and after.y >= after_ground - 0.1 and after.y <= after_ground + 2.0,
		"%s Player did not remain grounded after movement: player=%s ground=%.2f" % [
			label, after, after_ground])
	print("MEADOWS BUILD HOLD %s: ready pending='' grounded movement=%.2fm" % [label, travelled])


func _stage_cloudreach_with_production_router(game: Node) -> bool:
	var destination: Dictionary = {}
	for raw: Variant in game.call("debug_teleport_destinations"):
		if raw is Dictionary and str((raw as Dictionary).get("realm", "")) == "cloudreach":
			destination = raw as Dictionary
			break
	if destination.is_empty():
		_fail("debug staging found no authored Cloudreach destination")
		return false
	var target: Vector2 = destination.get("position", Vector2.ZERO)
	var crossed: bool = await game.call("debug_teleport_to", target.x, target.y,
		"cloudreach", str(destination.get("entry_id", "")))
	_expect(crossed, "production debug router could not stage Cloudreach")
	_expect(str(game.get("current_realm")) == "cloudreach",
		"debug staging did not arrive in Cloudreach")
	_expect(str(game.get("pending_realm_entry")) == "",
		"Cloudreach staging entry did not settle")
	return crossed and str(game.get("current_realm")) == "cloudreach"


func _observe_return_pending(game: Node) -> void:
	for _frame in SCENE_READY_FRAMES:
		if str(game.get("pending_realm_entry")) == RETURN_ENTRY:
			_saw_return_pending = true
			return
		await process_frame


func _watchdog() -> void:
	var began := Time.get_ticks_msec()
	while not _finished and Time.get_ticks_msec() - began < WATCHDOG_MSEC:
		await process_frame
	if _finished:
		return
	_fail("three-path Meadows build-hold smoke exceeded %d minutes" % int(WATCHDOG_MSEC / 60000))
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	Input.action_release("move_forward")
	if _failures.is_empty():
		print("MEADOWS BUILD HOLD RUNTIME OK: fresh boot, second boot and authored solo return are playable")
		quit(0)
		return
	for failure: String in _failures:
		push_error("MEADOWS BUILD HOLD RUNTIME: %s" % failure)
	quit(1)

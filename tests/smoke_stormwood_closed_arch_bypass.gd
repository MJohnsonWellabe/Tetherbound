extends SceneTree

## F09: "A closed Arch cannot be bypassed", in the live production Stormwood
## with the production player, camera and ordinary stick/jump input.
##
## Stormwood's closed routes (WORLD §5.3/§5.4; the analytic twin is
## tests/test_stormwood_closed_gates_sealed.gd):
##   - Pair E: the Hollow Crown is reached only through the Crown arch once the
##     Still Grove twin exists. With no twin, the player tries eight radial
##     approaches to the island (stick_navigator toward the plateau, jumping
##     whenever progress stalls).
##   - The Rootgate (Conductor Run -> Deepwood, which pairs C and D sit behind)
##     while `stormwood:rootgate_released` is unset: straight through and
##     around both ends of the 90 m wall.
## Pairs A and B are road shortcuts between places the road already joins,
## so there is nothing to bypass; they are not gates and are not tested here.
##
## Built-in negative control: the same walker reaches a far point along the
## conductor road where a path exists. Then each route is opened the ordinary
## way and the same player crosses: the Rootgate opens on its world flag, and
## the Still Grove twin is placed through the production ledger (free build:
## the footing, recipe, cap and twin rules still apply) and walked through.
##
## Disclosed fixture: the player is placed at each attempt's start (debug
## travel) and the recipe/Rootgate facts come from the host ledger.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const STORMWOOD_SCENE := preload("res://scenes/world/stormwood.tscn")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")

const TEST_SAVE_DIR := "user://stormwood_closed_arch_bypass_smoke"
const CROWN_CENTRE := Vector2(700.0, 2700.0)
const CROWN_ARCH := Vector2(485.0, 2700.0)
const ATTEMPT_FRAMES := 2400
const ROOTGATE_Z := 3550.0

var _failures: Array[String] = []
var _passes := 0
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _camera: Node3D
var _navigator: RefCounted
var _field: RefCounted
var _plateau_y := 0.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(900.0).timeout.connect(func() -> void:
		_expect(false, "900 second watchdog expired")
		_finish())
	_remove_tree(TEST_SAVE_DIR)
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_game = GAME.new()
		_game.name = "Game"
		root.add_child(_game)
	await process_frame
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	_game.get("local").set("character_id", "stormwood-closed-arch-bypass")
	_game.get("world").set("world_id", "stormwood-closed-arch-bypass-world")
	_game.set("current_realm", "stormwood")
	_game.call("bind_realm_map")
	_game.call("announce_realm", "meadows", "stormwood")
	_world = STORMWOOD_SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + 240000
	while not bool(_world.call("shell_build_complete")) and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(bool(_world.call("shell_build_complete")), "production Stormwood built")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_camera = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _camera == null or not _failures.is_empty():
		_finish()
		return
	_navigator = NAVIGATOR.new(self, _player, _camera, _drive)
	_field = FIELD.new()
	_plateau_y = _field.height_at(CROWN_CENTRE.x, CROWN_CENTRE.y)
	Engine.time_scale = 4.0
	Engine.physics_ticks_per_second = 240
	Engine.max_physics_steps_per_frame = 16

	# Negative control: where a path exists, this walker gets there.
	await _place(Vector2(-160.0, 2700.0))
	var control := await _walk(Vector2(-560.0, 2480.0), 9000, false)
	_expect(control.arrived, "negative control: the walker reaches (-560, 2480) along the conductor road (%.1f m left)" % control.left)

	# Pair E closed: eight approaches to the Hollow Crown plateau.
	# The island stands in a void 690 m in radius (heightfield -65 m, below
	# the -45 m kill plane). Each approach starts on the nearest standable
	# mainland ground 705 m out and walks straight for the plateau.
	var recovery := _world.get_node_or_null(^"FallRecovery")
	var recoveries := [0]
	if recovery != null:
		recovery.connect("recovered", func(_body: Variant, _local: bool) -> void: recoveries[0] += 1)
	var reached_island := 0
	var closest := INF
	for i in 8:
		var dir := Vector2.from_angle(TAU * i / 8.0)
		var start := CROWN_CENTRE + dir * 705.0
		await _place(start)
		var before := int(recoveries[0])
		var attempt := await _walk(CROWN_CENTRE, ATTEMPT_FRAMES, true)
		closest = minf(closest, attempt.closest)
		if attempt.on_island:
			reached_island += 1
		print("CLOSED ARCH E approach %d from %s: closest %.1f m to the plateau centre, on_island=%s, fall recoveries %d" % [
			i, str(start), attempt.closest, str(attempt.on_island), int(recoveries[0]) - before])
	_expect(reached_island == 0,
		"with no Still Grove twin, none of 8 approaches from the mainland edge (with jumps) reaches the Crown plateau (closest %.1f m; %d fall recoveries)" % [closest, int(recoveries[0])])

	# Rootgate closed: straight through, and around both ends of the wall.
	var crossed := 0
	# The pass floor is the only standable ground here (the flanks are about
	# 60-degree ridges); every line starts on it and aims through or past
	# either end of the 90 m wall.
	for line: Array in [[Vector2(-650, 3480), Vector2(-650, 3640)], [Vector2(-650, 3480), Vector2(-740, 3640)],
			[Vector2(-650, 3480), Vector2(-560, 3640)], [Vector2(-650, 3480), Vector2(-800, 3560)],
			[Vector2(-650, 3480), Vector2(-500, 3560)]]:
		await _place(line[0])
		var tried := await _walk(line[1], ATTEMPT_FRAMES, true)
		var north := _player.global_position.z
		print("CLOSED ROOTGATE %s -> %s: reached z=%.1f" % [str(line[0]), str(line[1]), north])
		if north > ROOTGATE_Z + 12.0:
			crossed += 1
	_expect(crossed == 0, "with the Rootgate closed, none of 5 lines (through and around it, with jumps) crosses north")

	# Open the Rootgate the ordinary way (its world fact) and cross.
	_expect(_commit_flag("stormwood:rootgate_released"), "Rootgate world fact committed")
	for _i in 20:
		await physics_frame
	await _place(Vector2(-650, 3480))
	var through := await _walk(Vector2(-650, 3640), ATTEMPT_FRAMES, false)
	_expect(through.arrived, "with the Rootgate open, the same player walks through to (-650, 3640)")

	# Open pair E: the Still Grove twin through the production ledger, then
	# walk through it and arrive on the Crown plateau.
	_expect(_commit_flag("stormwood:arch_recipe_known"), "arch recipe fact committed")
	var y: float = _field.height_at(-160.0, 2750.0)
	var placed: Dictionary = _game.get("ledger").call("submit", {"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": [-160.0, y, 2750.0], "yaw_deg": 90.0, "paid": false})
	_expect(bool(placed.get("ok", false)), "Still Grove twin placed through the ledger: %s" % str(placed.get("reason", "")))
	for _i in 60:
		await physics_frame
	await _place(Vector2(-175.0, 2750.0))
	var travelled := false
	for _frame in ATTEMPT_FRAMES:
		if _on_island():
			travelled = true
			break
		if bool(_navigator.call("can_walk")):
			await _navigator.call("step", Vector3(-140.0, y, 2750.0))
		else:
			await physics_frame
	_drive(0, 0)
	_expect(travelled, "with the pair open, walking through the Still Grove twin puts the player on the Crown plateau at %s" % str(_player.global_position))
	_finish()


func _on_island() -> bool:
	var p := _player.global_position
	return Vector2(p.x, p.z).distance_to(CROWN_CENTRE) < 260.0 and p.y > _plateau_y - 8.0


func _place(at: Vector2) -> void:
	_player.global_position = Vector3(at.x, _field.height_at(at.x, at.y) + 1.0, at.y)
	_player.velocity = Vector3.ZERO
	_navigator.call("reset")
	for _i in 30:
		await physics_frame


## Stick toward `target`, jumping (the ordinary jump action) whenever progress
## stalls for 45 frames when `jump` is set.
func _walk(target: Vector2, frames: int, jump: bool) -> Dictionary:
	var goal := Vector3(target.x, _field.height_at(target.x, target.y), target.y)
	var closest := INF
	var on_island := false
	var last := _player.global_position
	for frame in frames:
		var here := Vector2(_player.global_position.x, _player.global_position.z)
		closest = minf(closest, here.distance_to(CROWN_CENTRE))
		on_island = on_island or _on_island()
		if here.distance_to(target) < 2.0:
			_drive(0, 0)
			return {"arrived": true, "left": 0.0, "closest": closest, "on_island": on_island}
		if jump and frame % 45 == 44:
			if _player.global_position.distance_to(last) < 0.5:
				Input.action_press(&"jump")
				await physics_frame
				Input.action_release(&"jump")
			last = _player.global_position
		if bool(_navigator.call("can_walk")):
			await _navigator.call("step", goal)
		else:
			_drive(0, 0)
			await physics_frame
	_drive(0, 0)
	var left := Vector2(_player.global_position.x, _player.global_position.z).distance_to(target)
	return {"arrived": false, "left": left, "closest": closest, "on_island": on_island}


func _drive(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))
	if is_zero_approx(x):
		Input.action_release(&"move_right")
		Input.action_release(&"move_left")
	if is_zero_approx(y):
		Input.action_release(&"move_back")
		Input.action_release(&"move_forward")


func _commit_flag(flag: String) -> bool:
	var verdict: Dictionary = _game.get("ledger").call("submit", {
		"kind": "set_world_flag", "realm": "stormwood", "id": flag, "value": true})
	return bool(verdict.get("ok", false))


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passes += 1
		print("  PASS: ", message)
	else:
		_failures.append(message)
		print("  FAIL: ", message)


var _done := false


func _finish() -> void:
	if _done:
		return
	_done = true
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	_remove_tree(TEST_SAVE_DIR)
	print("STORMWOOD CLOSED ARCH BYPASS %s: %d passed, %d failed" % [
		"OK" if _failures.is_empty() else "FAILED", _passes, _failures.size()])
	quit(0 if _failures.is_empty() else 1)


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	for file: String in DirAccess.get_files_at(absolute):
		DirAccess.remove_absolute(absolute.path_join(file))
	for dir: String in DirAccess.get_directories_at(absolute):
		_remove_tree(path.path_join(dir))
	DirAccess.remove_absolute(absolute)

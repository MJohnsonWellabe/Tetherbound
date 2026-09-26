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
## Every attempt must reach its barrier: each Rootgate line's furthest-north
## point (tracked per attempt, not the final position) must come within
## `ROOTGATE_REACH_M` of the wall's south face, and each pair E approach must
## come within `VOID_REACH_M` of the measured void edge on its own line (where
## standable ground ends), or fall into the void. A line that never reaches its barrier proves nothing.
##
## Negative controls that MUST register a crossing, with the same walker, the
## same line, the same jump rule and the same counting:
##   - Rootgate: the wall's collider is temporarily disabled (no world flag),
##     and the straight line must count as crossed (max z past the crossing
##     line). The collider is then restored.
##   - Pair E: a temporary 8 m walkable bridge spans the void on approach 4's
##     line, and that approach must reach the plateau. The bridge is removed.
## A counter that cannot register a crossing would pass the closed checks
## vacuously; these controls fail in that case.
## The walker also reaches a far point along the conductor road where a path
## exists. Then each route is opened the ordinary way and the same player
## crosses: the Rootgate opens on its world flag, and the Still Grove twin is
## placed through the production ledger (free build: the footing, recipe, cap
## and twin rules still apply) and walked through.
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
## The wall is a 90 x 40 x 15 m box centred on ROOTGATE_Z: its south face.
const ROOTGATE_FACE_Z := ROOTGATE_Z - 7.5
## A line counts as crossed once its furthest-north point passes this.
const ROOTGATE_CROSSED_Z := ROOTGATE_Z + 12.0
## Every closed line must get its furthest-north point this close to the face.
const ROOTGATE_REACH_M := 6.0
## Every closed pair E approach must come this close to the void edge on its
## own line (where standable ground ends; see `_void_edge_radius`), or fall in.
const VOID_REACH_M := 5.0

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
	create_timer(1500.0).timeout.connect(func() -> void:
		_expect(false, "1500 second watchdog expired")
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
	var reached_edge := 0
	var closest := INF
	for i in 8:
		var dir := Vector2.from_angle(TAU * i / 8.0)
		var start := CROWN_CENTRE + dir * 705.0
		var edge := _void_edge_radius(dir)
		await _place(start)
		var before := int(recoveries[0])
		var attempt := await _walk(CROWN_CENTRE, ATTEMPT_FRAMES, true)
		var fell := int(recoveries[0]) - before
		closest = minf(closest, attempt.closest)
		if attempt.on_island:
			reached_island += 1
		var at_edge: bool = fell > 0 or float(attempt.closest) <= edge + VOID_REACH_M
		if at_edge:
			reached_edge += 1
		print("CLOSED ARCH E approach %d from %s: void edge (standable ground ends) %.1f m, closest %.1f m to the plateau centre, reached_edge=%s, on_island=%s, fall recoveries %d" % [
			i, str(start), edge, attempt.closest, str(at_edge), str(attempt.on_island), fell])
	_expect(reached_edge == 8,
		"every pair E approach reached the void edge on its line (within %.0f m, or fell in): %d of 8" % [VOID_REACH_M, reached_edge])
	_expect(reached_island == 0,
		"with no Still Grove twin, none of 8 approaches from the mainland edge (with jumps) reaches the Crown plateau (closest %.1f m; %d fall recoveries)" % [closest, int(recoveries[0])])

	# Pair E negative control: a temporary walkable bridge over the void on
	# approach 4's line. The same walker and counting must reach the plateau.
	var bridge_dir := Vector2.from_angle(TAU * 4 / 8.0)
	var bridge_start := CROWN_CENTRE + bridge_dir * 705.0
	var bridge := _add_bridge(bridge_start, CROWN_CENTRE + bridge_dir * 220.0)
	for _i in 10:
		await physics_frame
	await _place(bridge_start)
	var bridged := await _walk(CROWN_CENTRE, 14000, true)
	print("CONTROL ARCH E bridged approach 4: closest %.1f m, on_island=%s" % [bridged.closest, str(bridged.on_island)])
	_expect(bool(bridged.on_island),
		"negative control: with a temporary bridge over the void, the same walker on approach 4's line reaches the Crown plateau (closest %.1f m)" % bridged.closest)
	bridge.queue_free()
	for _i in 10:
		await physics_frame

	# Rootgate closed: straight through, and around both ends of the wall.
	var crossed := 0
	var reached_wall := 0
	# The pass floor is the only standable ground here (the flanks are about
	# 60-degree ridges); every line starts on it and aims through or past
	# either end of the 90 m wall, at a target well past the crossing line.
	var lines: Array = [[Vector2(-650, 3480), Vector2(-650, 3640)], [Vector2(-650, 3480), Vector2(-740, 3640)],
			[Vector2(-650, 3480), Vector2(-560, 3640)], [Vector2(-650, 3480), Vector2(-800, 3620)],
			[Vector2(-650, 3480), Vector2(-500, 3620)]]
	for line: Array in lines:
		var tried := await _rootgate_attempt(line)
		if tried.crossed:
			crossed += 1
		if tried.reached:
			reached_wall += 1
	_expect(reached_wall == lines.size(),
		"every Rootgate line's furthest-north point came within %.0f m of the wall face z=%.1f: %d of %d" % [
			ROOTGATE_REACH_M, ROOTGATE_FACE_Z, reached_wall, lines.size()])
	_expect(crossed == 0, "with the Rootgate closed, none of %d lines (through and around it, with jumps) crosses north of z=%.1f" % [
		lines.size(), ROOTGATE_CROSSED_Z])

	# Rootgate negative control: the wall's collider disabled with no world
	# flag. The same walker on the same straight line must count a crossing.
	var gate_shape := _world.get_node_or_null(^"Rootgate/CollisionShape3D") as CollisionShape3D
	_expect(gate_shape != null and not gate_shape.disabled, "the closed Rootgate collider exists and is enabled")
	if gate_shape != null:
		gate_shape.set_deferred("disabled", true)
		for _i in 10:
			await physics_frame
		var control_line := await _rootgate_attempt(lines[0])
		_expect(bool(control_line.crossed),
			"negative control: with the wall collider temporarily disabled, the same line counts as crossed (max z %.1f > %.1f)" % [
				control_line.max_z, ROOTGATE_CROSSED_Z])
		gate_shape.set_deferred("disabled", false)
		for _i in 10:
			await physics_frame
		_expect(not gate_shape.disabled, "the Rootgate collider is restored after the control")

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


## One Rootgate line: its furthest-north point decides both whether it
## crossed and whether it reached the wall at all.
func _rootgate_attempt(line: Array) -> Dictionary:
	await _place(line[0])
	var tried := await _walk(line[1], ATTEMPT_FRAMES, true)
	var max_z: float = tried.max_z
	var crossed := max_z > ROOTGATE_CROSSED_Z
	var reached := max_z >= ROOTGATE_FACE_Z - ROOTGATE_REACH_M
	print("ROOTGATE line %s -> %s: max z=%.1f (face %.1f, crossing %.1f) final z=%.1f reached=%s crossed=%s" % [
		str(line[0]), str(line[1]), max_z, ROOTGATE_FACE_Z, ROOTGATE_CROSSED_Z, _player.global_position.z,
		str(reached), str(crossed)])
	return {"max_z": max_z, "crossed": crossed, "reached": reached}


## The void edge on this line: walking in from the mainland start, the first
## point where the ground falls away steeper than the player's own
## `floor_max_angle`, i.e. where standable ground ends and the sink's wall
## (about 50 degrees, down past the -45 m kill plane) begins.
func _void_edge_radius(dir: Vector2) -> float:
	var limit := tan(_player.floor_max_angle)
	var r := 705.0
	while r > 0.5:
		var p := CROWN_CENTRE + dir * r
		var q := CROWN_CENTRE + dir * (r - 0.5)
		if (_field.height_at(p.x, p.y) - _field.height_at(q.x, q.y)) / 0.5 > limit:
			return r
		r -= 0.5
	return 0.0


## A temporary 8 m wide walkable deck from `from` to `to`, top surface at the
## ground height at `from` and the plateau height at `to`.
func _add_bridge(from: Vector2, to: Vector2) -> StaticBody3D:
	var a := Vector3(from.x, _field.height_at(from.x, from.y), from.y)
	var b := Vector3(to.x, _plateau_y, to.y)
	var body := StaticBody3D.new()
	body.name = "NegativeControlBridge"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var length := a.distance_to(b)
	box.size = Vector3(8.0, 1.0, length + 2.0)
	shape.shape = box
	body.add_child(shape)
	_world.add_child(body)
	var mid := (a + b) * 0.5
	body.global_transform = Transform3D(Basis.looking_at(b - a, Vector3.UP), mid - Vector3(0.0, 0.5, 0.0))
	return body


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
	var max_z := _player.global_position.z
	var last := _player.global_position
	for frame in frames:
		var here := Vector2(_player.global_position.x, _player.global_position.z)
		max_z = maxf(max_z, _player.global_position.z)
		closest = minf(closest, here.distance_to(CROWN_CENTRE))
		on_island = on_island or _on_island()
		if here.distance_to(target) < 2.0:
			_drive(0, 0)
			return {"arrived": true, "left": 0.0, "closest": closest, "on_island": on_island, "max_z": max_z}
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
	max_z = maxf(max_z, _player.global_position.z)
	var left := Vector2(_player.global_position.x, _player.global_position.z).distance_to(target)
	return {"arrived": false, "left": left, "closest": closest, "on_island": on_island, "max_z": max_z}


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

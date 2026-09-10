extends SceneTree

## MEADOWS-RELAY-GATE-0909. One retained-world boot proves the replacement
## gate from the two existing route cameras, day and night, while the actual
## Player reaches both stands with ordinary left-stick input, crosses the gate
## and continues over the authored ramp/gantry/pad route.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CONFIG_PATH := "res://data/config/tether_relay.json"
const OUT_DIR := "res://shots/relay_gate_route_0909"
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const RELAY_SCRIPT := preload("res://scripts/world/tether_relay.gd")
const RELAY_ROUTE := preload("res://tests/helpers/meadows_earned_relay_segment.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const BOOT_FRAMES := 240
const LAND_FRAMES := 45
const POSE_FRAMES := 8
const ROUTE_BUDGET := 2400
const PLAYER_HEIGHT := 1.8

## Exact `tools/_capture_locations.gd` 06-relay authored stands and rig.
const APPROACH := {
	"label": "approach", "at": Vector2(-20.0, 0.0),
	"look": Vector2(-14.0, 0.0), "back": 4.0, "up": 3.2,
}
const ROAD := {
	"label": "road", "at": Vector2(0.0, 0.0),
	"look": Vector2(-155.07, 21.26), "back": 7.0, "up": 3.2,
}

var _world: Node3D
var _relay: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _camera: Camera3D
var _look: Node
var _weather: Node
var _nav: RefCounted
var _field: RefCounted
var _config: Dictionary
var _failures: Array[String] = []
var _written := 0
var _travelled := 0.0


func _init() -> void:
	# Global transforms and the physics world do not exist during SceneTree's
	# synchronous constructor. Every measurement begins after initialization.
	_run.call_deferred()


func _run() -> void:
	print("[relay-gate-route] start_utc=%s pid=%d args=%s" % [
		Time.get_datetime_string_from_system(true, true), OS.get_process_id(),
		OS.get_cmdline_args()])
	if DisplayServer.get_name() == "headless":
		_fail("capture requires the real Compatibility renderer")
		_finish()
		return
	_config = _json(CONFIG_PATH)
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for _frame in BOOT_FRAMES:
		await physics_frame
	_relay = _world.get_node_or_null(^"TetherRelay") as Node3D
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	if _relay == null or _player == null or _rig == null:
		_fail("world has no TetherRelay, Player or CameraRig")
		_finish()
		return
	_rig.set_process(false)
	_rig.set_physics_process(false)
	_camera = Camera3D.new()
	_camera.fov = 70.0
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	_nav = NAV.new(self, _player, _rig, _stick)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_hide_huds()

	_probe_gate_footing()
	var outside: Vector2 = _relay.call("world_of", Vector2(-24.0, 0.0)) as Vector2
	await _put_down(outside)
	if not await _walk_local(APPROACH.at, 0.45, "outside fixture -> exact approach stand"):
		_finish()
		return
	await _pin("day")
	await _capture(APPROACH, "day")
	await _pin("night")
	await _capture(APPROACH, "night")

	await _pin("day")
	var gate_path: Array[Vector2] = RELAY_ROUTE.gate_path(_config)
	# The player is already between gate_path[0] and the gate; continue forward
	# through the exact centre and inside point rather than backtracking.
	for index in range(1, gate_path.size()):
		if not await _walk_local(gate_path[index], 0.45, "gate route %d" % index):
			_finish()
			return
		if index == 1:
			_probe_head_clearance()
	if not await _walk_local(ROAD.at, 0.45, "gate inside -> exact road stand"):
		_finish()
		return
	await _capture(ROAD, "day")
	await _pin("night")
	await _capture(ROAD, "night")

	await _pin("day")
	var deck_path: Array[Vector3] = RELAY_ROUTE.deck_path(_config)
	if deck_path.is_empty():
		_fail("authored ramp/gantry/pad route is unavailable")
	else:
		for index in deck_path.size():
			var local: Vector3 = deck_path[index]
			var xz: Vector2 = _relay.call("world_of", Vector2(local.x, local.z)) as Vector2
			var y: float = _ground(xz) if is_nan(local.y) else local.y
			if not await _walk_world(Vector3(xz.x, y, xz.y), 0.6,
					"deck route %d" % index):
				break
			if index > 0 and absf(_player.global_position.y - local.y) > 0.6:
				_fail("deck route %d ended at y %.3f, expected %.3f" % [
					index, _player.global_position.y, local.y])
	print("RELAY GATE ROUTE %s frames=%d travelled=%.2fm end=%s failures=%s" % [
		"PASS" if _failures.is_empty() else "FAIL", _written, _travelled,
		_player.global_position, _failures])
	_finish()


func _walk_local(local: Vector2, radius: float, label: String) -> bool:
	var xz: Vector2 = _relay.call("world_of", local) as Vector2
	return await _walk_world(Vector3(xz.x, _ground(xz), xz.y), radius, label)


func _walk_world(target: Vector3, radius: float, label: String) -> bool:
	var before: Vector3 = _player.global_position
	var ok: bool = bool(await _nav.call("walk_to", target, ROUTE_BUDGET, radius))
	_stick(0.0, 0.0)
	_travelled += before.distance_to(_player.global_position)
	var local: Vector2 = _relay.call("local_of", Vector2(_player.global_position.x,
		_player.global_position.z)) as Vector2
	print("[relay-gate-route] %s ok=%s player=%s local=%s on_floor=%s" % [
		label, ok, _player.global_position, local, _player.is_on_floor()])
	if not ok:
		_fail("ordinary input did not complete " + label)
	return ok


func _put_down(xz: Vector2) -> void:
	_player.global_position = Vector3(xz.x, _ground(xz) + 1.2, xz.y)
	_player.velocity = Vector3.ZERO
	for _frame in LAND_FRAMES:
		await physics_frame


func _probe_head_clearance() -> void:
	var arch := _relay.get_node_or_null(^"Gate/GatePresentationRoot/GatePresentation") as MeshInstance3D
	var collision := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if arch == null or collision == null or not collision.shape is CapsuleShape3D:
		_fail("installed arch or player capsule is missing at the gate centre")
		return
	var fit: Dictionary = _fit(arch.mesh)
	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
	if absf(capsule.height - PLAYER_HEIGHT) > 0.001:
		_fail("production player capsule height is %.3fm, expected %.3fm" % [
			capsule.height, PLAYER_HEIGHT])
	var crown_y: float = (arch.get_parent() as Node3D).global_position.y \
		+ float(fit.get("visible_open_height", 0.0))
	var head_y: float = collision.global_position.y + capsule.height * 0.5
	var margin: float = crown_y - head_y
	print("[relay-gate-route] character head y=%.3f crown y=%.3f clearance=%.3fm" % [
		head_y, crown_y, margin])
	if margin <= 0.25:
		_fail("installed visible crown leaves only %.3fm over the 1.8m player" % margin)


func _probe_gate_footing() -> void:
	var arch := _relay.get_node_or_null(^"Gate/GatePresentationRoot/GatePresentation") as MeshInstance3D
	if arch == null:
		_fail("valid fitted gate did not suppress the box fallback")
		return
	var metrics: Dictionary = RELAY_SCRIPT.gate_presentation_metrics(arch.mesh)
	var bounds: AABB = metrics.get("bounds", AABB())
	var xs: Array[float] = [bounds.position.x, float(metrics.get("left_inner", 0.0)),
		float(metrics.get("right_inner", 0.0)), bounds.end.x]
	var largest_gap := -INF
	var deepest_embed := INF
	for x in xs:
		var sill: Vector3 = arch.to_global(Vector3(x, bounds.position.y, bounds.get_center().z))
		var ground: float = _ground(Vector2(sill.x, sill.z))
		var contact: float = sill.y - ground
		largest_gap = maxf(largest_gap, contact)
		deepest_embed = minf(deepest_embed, contact)
		print("[relay-gate-route] sill x=%.6f world=%s ground=%.3f contact=%+.3fm" % [
			x, sill, ground, contact])
	print("[relay-gate-route] sill contact largest_gap=%+.3fm deepest_embed=%+.3fm" % [
		largest_gap, deepest_embed])
	if largest_gap > 0.05:
		_fail("fitted gate sill floats %.3fm above authored terrain" % largest_gap)


func _fit(mesh: Mesh) -> Dictionary:
	var gate: Dictionary = _config.get("gate", {}) as Dictionary
	var presentation: Dictionary = gate.get("presentation", {}) as Dictionary
	return RELAY_SCRIPT.gate_presentation_fit(mesh, float(gate.get("opening", 0.0)),
		float(gate.get("pier_height", 0.0)) + float(gate.get("lintel_height", 0.0)),
		float(gate.get("pier_depth", 0.0)),
		float(presentation.get("clearance_each_side_m", 0.0)))


func _capture(shot: Dictionary, time: String) -> void:
	var eye: Vector2 = _relay.call("world_of", shot.at as Vector2) as Vector2
	var target: Vector2 = _relay.call("world_of", shot.look as Vector2) as Vector2
	var toward: Vector2 = (target - eye).normalized()
	var back: Vector2 = eye - toward * float(shot.back)
	_camera.global_position = Vector3(back.x, _surface(back) + float(shot.up), back.y)
	_camera.look_at(Vector3(target.x, _surface(target) + 1.6, target.y), Vector3.UP)
	_hide_huds()
	for _frame in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null:
		_fail("viewport returned no %s-%s image" % [shot.label, time])
		return
	var path: String = "%s/06-relay-%s-%s.png" % [OUT_DIR, shot.label, time]
	if image.save_png(path) != OK:
		_fail("could not write " + path)
		return
	_written += 1
	print("[relay-gate-route] wrote %s player=%s camera=%s" % [
		path, _player.global_position, _camera.global_transform])


func _pin(time: String) -> void:
	if _weather != null:
		_weather.set_process(true)
		_weather.set_physics_process(true)
		_weather.call("set_weather", "clear")
	if _look != null:
		if _look.has_method("set_clock_frozen"):
			_look.call("set_clock_frozen", false)
		_look.call("apply_time", time)
		if _look.has_method("set_clock_frozen"):
			_look.call("set_clock_frozen", true)
	for _frame in 30:
		await physics_frame
	if _weather != null:
		_weather.set_process(false)
		_weather.set_physics_process(false)
	print("[relay-gate-route] clock pinned %s clear" % time)


func _surface(at: Vector2) -> float:
	# Byte-for-byte camera seating policy from `_capture_locations.gd`: the
	# analytic height starts Terrain3D's ray and the first collision wins.
	var authored := float(_field.call("height_at", at.x, at.y))
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(at.x, authored + 400.0, at.y), Vector3(at.x, authored - 400.0, at.y))
	query.collide_with_areas = false
	var hit: Dictionary = _world.get_world_3d().direct_space_state.intersect_ray(query)
	return authored if hit.is_empty() else float((hit.position as Vector3).y)


func _ground(at: Vector2) -> float:
	return float(_world.call("ground_height_at", at.x, at.y))


func _stick(x: float, z: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, z]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = int(pair[0])
		event.axis_value = float(pair[1])
		Input.parse_input_event(event)


func _hide_huds() -> void:
	for node in _all(_world):
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _fail(message: String) -> void:
	_failures.append(message)
	print("[relay-gate-route] FAIL " + message)


func _finish() -> void:
	_stick(0.0, 0.0)
	print("[relay-gate-route] end_utc=%s pid=%d exit=%d" % [
		Time.get_datetime_string_from_system(true, true), OS.get_process_id(),
		0 if _failures.is_empty() else 1])
	quit(0 if _failures.is_empty() else 1)

extends SceneTree

## Production First Shore visual proof. The Water scene places the real player
## at its authored arrival. This fixture then uses ordinary left-stick input to
## follow the new pavers around the fixed gate's south/front face, and ordinary
## look input to face it. No actor, gate, camera or terrain transform is assigned.

const WATER_SCENE := preload("res://scenes/world/water_archipelago.tscn")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const BUILD_TIMEOUT_MSEC := 900000
const OUTPUT_DEFAULT := "res://shots/catalogue/water/first-shore-gate-site"

var _output := OUTPUT_DEFAULT
var _failures: Array[String] = []
var _records: Array[Dictionary] = []
var _player: CharacterBody3D
var _rig: Node3D
var _camera: Camera3D
var _world: Node3D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("First Shore gate-site capture requires a rendering display")
		_finish()
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			_output = argument.trim_prefix("--output=")
	var absolute := ProjectSettings.globalize_path(_output)
	DirAccess.make_dir_recursive_absolute(absolute)
	if FileAccess.file_exists(absolute.path_join("manifest.json")):
		_fail("output already has a manifest")
		_finish()
		return

	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("Game autoload is missing")
		_finish()
		return
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	game.get("world").get("flags").call("set_flag", "realm_gate_water_unlocked")
	_world = WATER_SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + BUILD_TIMEOUT_MSEC
	while not bool(_world.call("shell_build_complete")) and Time.get_ticks_msec() < deadline:
		await process_frame
	if not bool(_world.call("shell_build_complete")):
		_fail("production Water shell timed out")
		_finish()
		return
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	var gate := _world.get_node_or_null(^"StormwoodReturnRealmGate") as Node3D
	var site := _world.get_node_or_null(^"FirstShoreGateSite") as Node3D
	if _player == null or _rig == null or _camera == null or gate == null or site == null:
		_fail("production player/camera/gate/site is missing")
		_finish()
		return
	for _frame in 45:
		await physics_frame
	var start := _player.global_position
	var navigator := NAVIGATOR.new(self, _player, _rig, Callable(self, "_drive_stick"))
	var legs: Array[Dictionary] = []
	for target_xz: Vector2 in [Vector2(6.1, 159.4), Vector2(11.4, 156.0), Vector2(12.0, 153.0)]:
		var ground := float(_world.call("ground_height_at", target_xz.x, target_xz.y))
		var target := Vector3(target_xz.x, ground + 0.1 if is_finite(ground) else start.y, target_xz.y)
		var leg_start := _player.global_position
		var reached := await navigator.walk_to(target, 900, 0.9)
		_drive_stick(0.0, 0.0)
		legs.append({"target": _vec3(target), "reached": reached,
			"from": _vec3(leg_start), "to": _vec3(_player.global_position),
			"distance_m": _player.global_position.distance_to(leg_start)})
		if not reached:
			_fail("ordinary paver-route leg did not reach its target")
			_finish()
			return
	for _frame in 18:
		await physics_frame
	var orbit := await _look_at_with_input(gate.global_position)
	if not bool(orbit.get("reached", false)):
		_fail("ordinary look input did not face the gate")
		_finish()
		return
	var banner := _world.find_child("RegionBanner", true, false) as CanvasItem
	var banner_wait := 0
	while banner != null and banner.visible and banner_wait < 300:
		await physics_frame
		banner_wait += 1
	if banner != null and banner.visible:
		_fail("region banner did not clear")
		_finish()
		return

	var look := _world.get_node_or_null(^"WorldLook")
	for preset: String in ["day", "night"]:
		look.call("apply_time", preset)
		for _frame in 12:
			await physics_frame
		await RenderingServer.frame_post_draw
		var image_path := "%s/first-shore-return-gate-ordinary-front-%s.png" % [_output, preset]
		var image := root.get_texture().get_image()
		if image == null or image.is_empty() or image.save_png(image_path) != OK:
			_fail("could not save %s view" % preset)
		else:
			_records.append({"time": preset, "file": image_path, "player_position": _vec3(_player.global_position),
				"camera_position": _vec3(_camera.global_position), "gate_position": _vec3(gate.global_position),
				"player_grounded": _player.is_on_floor(), "gate_distance_m": _player.global_position.distance_to(gate.global_position)})
	var manifest := {
		"schema_version": 1,
		"scene": "res://scenes/world/water_archipelago.tscn",
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"fixture_disclosure": "Production Water scene and ordinary gameplay HUD. Existing world unlock supplied as a visual prerequisite. Real player starts at authored First Shore arrival, then moves only through ordinary left-stick input and faces the gate only through ordinary look input. No actor, gate, camera, terrain, progression reward or route transform assignment.",
		"start_position": _vec3(start),
		"walk_legs": legs,
		"total_displacement_m": _player.global_position.distance_to(start),
		"look_input": orbit,
		"region_banner_found": banner != null,
		"region_banner_visible_at_capture": banner != null and banner.visible,
		"region_banner_wait_frames": banner_wait,
		"site_piece_count": site.get_child_count(),
		"gate_state": str(gate.call("current_state")),
		"frames": _records,
		"failures": _failures,
		"complete": _failures.is_empty() and _records.size() == 2,
		"capture_finished_utc": Time.get_datetime_string_from_system(true),
	}
	var manifest_file := FileAccess.open(absolute.path_join("manifest.json"), FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, "\t") + "\n")
	manifest_file.close()
	_finish()


func _look_at_with_input(target: Vector3) -> Dictionary:
	var view := target - _player.global_position
	var desired := atan2(-view.x, -view.z)
	var start := float(_rig.get("yaw"))
	var frames := 0
	while absf(wrapf(desired - float(_rig.get("yaw")), -PI, PI)) > deg_to_rad(4.0) and frames < 180:
		var delta := wrapf(desired - float(_rig.get("yaw")), -PI, PI)
		var action: StringName = &"look_left" if delta > 0.0 else &"look_right"
		Input.action_press(action, 0.55)
		await physics_frame
		Input.action_release(&"look_left")
		Input.action_release(&"look_right")
		frames += 1
	for _frame in 12:
		await physics_frame
	return {"reached": absf(wrapf(desired - float(_rig.get("yaw")), -PI, PI)) <= deg_to_rad(5.0),
		"start_yaw_deg": rad_to_deg(start), "desired_yaw_deg": rad_to_deg(desired),
		"finish_yaw_deg": rad_to_deg(float(_rig.get("yaw"))), "physics_frames": frames}


func _drive_stick(x: float, y: float) -> void:
	_drive_axis(JOY_AXIS_LEFT_X, x)
	_drive_axis(JOY_AXIS_LEFT_Y, y)


func _drive_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("FIRST SHORE GATE SITE: %s" % message)


func _finish() -> void:
	print("FIRST SHORE GATE SITE %s: %d frame(s)" % ["PASS" if _failures.is_empty() else "FAIL", _records.size()])
	quit(0 if _failures.is_empty() else 1)

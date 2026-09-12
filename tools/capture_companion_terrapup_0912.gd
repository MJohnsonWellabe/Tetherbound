extends SceneTree

## OWNER-0912: one production Meadows boot for the last Terrapup/companion
## visual receipts.
##
## Windows production command (Compatibility renderer; deliberately no
## `--headless`):
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_companion_terrapup_0912.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/final-companion-01
##
## The formation frames retain the production CameraRig and move the ordinary
## player with real input. The rest frames assign that same party Terrapup to
## the Stronghold's shipped CreatureBed, which makes EncounterDirector recall
## the follower and makes creature_bed.gd create its real RestingCreature and
## call play_rest(). No AnimationPlayer seek, model rotation, transform pose,
## or direct `resting` write is used. A close diagnostic camera is used only
## after the real bed owns the subject, so side/three-quarter rest contact can
## be judged without the third-person trainer filling the frame.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")

const READY_TIMEOUT_MS := 420_000
const STAGE := Vector2(-430.0, 470.0)
const OPENING_BYPASS_FLAG := "trainer_defeated_practice"
const TERRAPUP := "terrapup"
const SETTLE_LIMIT := 360
const MOTION_FRAMES := 42
const EXPECTED_CLIP := "faint"

const PLANNED_FRAMES := [
	"01-formation-settled-day",
	"02-formation-settled-night",
	"03-formation-left-motion-day",
	"04-formation-right-motion-day",
	"05-terrapup-lay-side-day",
	"06-terrapup-lay-three-quarter-day",
	"07-terrapup-lay-side-night",
	"08-terrapup-lay-three-quarter-night",
]

var _out_dir := ""
var _game: Node = null
var _world: Node3D = null
var _player: CharacterBody3D = null
var _director: Node = null
var _companion: CharacterBody3D = null
var _rig: SpringArm3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _party: RefCounted = null
var _instance: RefCounted = null
var _follower_cfg: Dictionary = {}
var _last_heading := Vector3.FORWARD
var _records: Array[Dictionary] = []
var _failures: Array[String] = []
var _warnings: Array[String] = []
var _manifest: Dictionary = {}
var _posed_total_vertices := 0
var _posed_skinned_vertices := 0


func _init() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())
	_run()


func _run() -> void:
	if not FRESH_OUTPUT.create_fresh(_out_dir, "Terrapup companion capture"):
		quit(1)
		return
	_begin_manifest()
	_write_manifest()
	if DisplayServer.get_name() == "headless":
		_fail("capture requires a rendering display; do not use --headless")
		_finish(false)
		return
	if not _prepare_game() or not await _mount_world() or not await _deploy_terrapup():
		_finish(false)
		return

	await _capture_formation_sequence()
	if _failures.is_empty():
		await _capture_rest_sequence()
	_finish(_failures.is_empty() and _records.size() == PLANNED_FRAMES.size())


func _prepare_game() -> bool:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("Game autoload is missing")
		return false
	_game.call("reset_for_new_game")
	_game.set("current_realm", "meadows")
	var progression := _game.get("progression") as RefCounted
	if progression == null:
		_fail("Game progression is missing")
		return false
	progression.call("set_flag", OPENING_BYPASS_FLAG)
	_party = _game.get("party") as RefCounted
	if _party == null:
		_fail("Game party is missing")
		return false
	return true


func _mount_world() -> bool:
	var packed := load(SCENE) as PackedScene
	if packed == null:
		_fail("could not load production Meadows scene")
		return false
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			_fail("production Meadows shell build timed out")
			return false
		await physics_frame
	for i in 30:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	if _player == null or _director == null or _rig == null or _camera == null or _look == null:
		_fail("production Player, EncounterDirector, CameraRig/Camera3D or WorldLook is missing")
		return false
	_camera.make_current()
	var opening := JSON.parse_string(FileAccess.get_file_as_string("res://data/config/opening.json"))
	if opening is Dictionary:
		_follower_cfg = (opening as Dictionary).get("follower", {}) as Dictionary
	if _follower_cfg.is_empty():
		_fail("opening.json has no production follower configuration")
		return false
	if _weather != null and _weather.has_method("set_weather"):
		_weather.call("set_weather", "clear")
	return true


func _deploy_terrapup() -> bool:
	if not bool(_game.call("debug_teleport_to", STAGE.x, STAGE.y, "meadows", "")):
		_fail("Game.debug_teleport_to refused the open-field capture stage")
		return false
	for i in 30:
		await physics_frame
	if _director.call("ally_instance") == null:
		if not bool(await _director.call("adopt_starter", TERRAPUP)):
			_fail("production EncounterDirector refused Terrapup adoption")
			return false
	_instance = _director.call("ally_instance") as RefCounted
	_companion = _director.call("ally_body") as CharacterBody3D
	if _instance == null or _companion == null or str(_instance.get("species_id")) != TERRAPUP:
		_fail("the production deployed companion is not Terrapup")
		return false
	if (_party.call("members") as Array).is_empty():
		if not bool(_party.call("add", _instance)):
			_fail("production Party refused the adopted Terrapup")
			return false
	elif _party.call("active") != _instance:
		_fail("the deployed Terrapup is not Party.active")
		return false
	for i in 90:
		await physics_frame
	_manifest["subject"] = {
		"species_id": str(_instance.get("species_id")),
		"party_index": int(_party.call("active_index")),
		"body_path": str(_world.get_path_to(_companion)),
		"body_height_m": float(_companion.call("body_height")),
		"body_radius_m": float(_companion.call("body_radius")),
		"follower_config": _follower_cfg.duplicate(true),
	}
	_manifest["gameplay_camera"] = {
		"path": str(_world.get_path_to(_camera)),
		"rig_path": str(_world.get_path_to(_rig)),
		"fov": _camera.fov,
		"spring_length": _rig.spring_length,
	}
	_write_manifest()
	return true


func _capture_formation_sequence() -> void:
	await _pin_time("day")
	await _drive(["move_forward"], 90)
	await _wait_for_station()
	await _capture_formation("01-formation-settled-day", "day", "settled", [])
	await _pin_time("night")
	await _capture_formation("02-formation-settled-night", "night", "settled", [])

	await _pin_time("day")
	await _capture_motion("03-formation-left-motion-day", ["move_forward", "move_left"])
	await _wait_for_station()
	await _capture_motion("04-formation-right-motion-day", ["move_forward", "move_right"])
	_release_all_motion()
	await _wait_for_station()


func _capture_motion(frame_name: String, actions: Array[String]) -> void:
	_set_actions(actions, true)
	for i in MOTION_FRAMES:
		await physics_frame
		_update_heading_from_velocity()
	await _capture_formation(frame_name, "day", "motion", actions)
	_set_actions(actions, false)
	for i in 8:
		await physics_frame


func _capture_formation(frame_name: String, time_name: String, phase: String,
		actions: Array[String]) -> void:
	if not is_instance_valid(_companion) or _director.call("ally_body") != _companion:
		_fail("%s: production follower disappeared" % frame_name)
		return
	_update_heading_from_velocity()
	_camera.make_current()
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var metrics := _formation_metrics()
	var problems := CAPTURE_CHECK.problems(self, _camera, "clear")
	var record := {
		"frame": frame_name,
		"kind": "formation",
		"time": time_name,
		"phase": phase,
		"held_actions": actions.duplicate(),
		"camera_source": "production CameraRig/Camera3D",
		"camera_transform": _transform(_camera.global_transform),
		"player_transform": _transform(_player.global_transform),
		"companion_transform": _transform(_companion.global_transform),
		"player_velocity": _vec3(_player.velocity),
		"companion_velocity": _vec3(_companion.velocity),
		"formation": metrics,
		"capture_check": problems,
	}
	await _save_frame(frame_name, record)


func _formation_metrics() -> Dictionary:
	var heading := _last_heading
	heading.y = 0.0
	heading = heading.normalized() if heading.length_squared() > 0.001 else Vector3.FORWARD
	var right := heading.cross(Vector3.UP).normalized()
	var target := _player.global_position \
		+ right * float(_follower_cfg.get("side_offset", 0.0)) \
		- heading * float(_follower_cfg.get("back_offset", 0.0))
	var actual_gap := _flat_distance(_companion.global_position, target)
	var line_clearance := _point_segment_distance(
		_companion.global_position, _camera.global_position, _player.global_position) \
		- float(_companion.call("body_radius"))
	var screen := _camera.unproject_position(
		_companion.global_position + Vector3.UP * float(_companion.call("body_height")) * 0.5)
	return {
		"authored_side_offset_m": float(_follower_cfg.get("side_offset", 0.0)),
		"authored_back_offset_m": float(_follower_cfg.get("back_offset", 0.0)),
		"heading": _vec3(heading),
		"expected_station": _vec3(target),
		"station_error_xz_m": actual_gap,
		"player_gap_xz_m": _flat_distance(_companion.global_position, _player.global_position),
		"camera_axis_surface_clearance_m": line_clearance,
		"companion_screen_px": [screen.x, screen.y],
		"companion_behind_camera": _camera.is_position_behind(_companion.global_position),
		"companion_centre_in_frustum": _camera.is_position_in_frustum(_companion.global_position),
		"follower_reports_closing": bool(_companion.call("is_closing")),
	}


func _capture_rest_sequence() -> void:
	_release_all_motion()
	var stronghold := _world.get_node_or_null(^"Stronghold")
	var bed := stronghold.call("recovery_point") as Node3D if stronghold != null else null
	if bed == null or not bed.has_method("assign_creature"):
		_fail("the production Stronghold recovery CreatureBed is missing")
		return
	var party_index := int(_party.call("active_index"))
	if not bool(bed.call("assign_creature", party_index)):
		_fail("the production CreatureBed refused Party.active Terrapup")
		return

	var resting: Node3D = null
	for i in SETTLE_LIMIT:
		await physics_frame
		resting = bed.get_node_or_null(^"RestingCreature") as Node3D
		if resting != null and _director.call("ally_body") == null:
			var player := _animation_player(resting)
			if player != null and not player.is_playing():
				break
	if resting == null:
		_fail("CreatureBed never built its production RestingCreature")
		return
	if _director.call("ally_body") != null:
		_fail("EncounterDirector did not recall the deployed follower when Party marked it resting")
		return
	var animation := _animation_player(resting)
	if animation == null or animation.current_animation != EXPECTED_CLIP or animation.is_playing():
		_fail("Terrapup did not settle at the completed production '%s' rest clip" % EXPECTED_CLIP)
		return
	var expected_anchor := bed.global_transform * CREATURE_BED.REST_ANCHOR
	var posed := _posed_visual_bounds(resting)
	if posed.is_empty() or _posed_skinned_vertices <= 0:
		_fail("could not measure Terrapup's live posed skinned vertices")
		return
	var bed_state := {
		"bed_path": str(_world.get_path_to(bed)),
		"build_index": int(bed.call("build_index")),
		"occupant_index": int(bed.call("occupant_index")),
		"party_resting": bool(_instance.get("resting")),
		"party_rest_bed_index": int(_instance.get("rest_bed_index")),
		"rest_anchor_local": _vec3(CREATURE_BED.REST_ANCHOR),
		"expected_anchor_world": _vec3(expected_anchor),
		"rest_body_origin_world": _vec3(resting.global_position),
		"rest_anchor_error_m": resting.global_position.distance_to(expected_anchor),
		"animation": animation.current_animation,
		"animation_position_s": animation.current_animation_position,
		"animation_length_s": animation.current_animation_length,
		"animation_playing": animation.is_playing(),
		"posed_visual_min_world": _vec3(posed.position),
		"posed_visual_max_world": _vec3(posed.position + posed.size),
		"posed_visual_height_m": posed.size.y,
		"posed_low_to_rest_origin_m": posed.position.y - resting.global_position.y,
		"posed_low_minus_bed_anchor_plane_m": posed.position.y - expected_anchor.y,
		"posed_total_vertices": _posed_total_vertices,
		"posed_skinned_vertices": _posed_skinned_vertices,
	}
	_manifest["rest_state"] = bed_state
	_write_manifest()

	_hide_overlays()
	_rig.set_process(false)
	_rig.set_physics_process(false)
	var rest_camera := Camera3D.new()
	rest_camera.name = "TerrapupRestEvidenceCamera"
	rest_camera.fov = 52.0
	rest_camera.far = 500.0
	_world.add_child(rest_camera)
	rest_camera.make_current()
	for time_name: String in ["day", "night"]:
		await _pin_time(time_name)
		await _capture_rest_view(rest_camera, resting, posed, "side", time_name)
		await _capture_rest_view(rest_camera, resting, posed, "three-quarter", time_name)


func _capture_rest_view(camera: Camera3D, resting: Node3D, posed: AABB,
		view: String, time_name: String) -> void:
	var target := posed.get_center()
	var forward := -resting.global_basis.z.normalized()
	var side := resting.global_basis.x.normalized()
	var direction := side if view == "side" else (side + forward * 0.72).normalized()
	var distance := maxf(5.2, maxf(posed.size.x, posed.size.z) * 1.7)
	var eye := target + direction * distance + Vector3.UP * maxf(0.35, posed.size.y * 0.14)
	camera.global_position = eye
	camera.look_at(target + Vector3.UP * posed.size.y * 0.05, Vector3.UP)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var frame_name := "%02d-terrapup-lay-%s-%s" % [
		5 + _rest_frame_offset(view, time_name), view, time_name]
	var problems := CAPTURE_CHECK.problems(self, camera, "clear", resting)
	var record := {
		"frame": frame_name,
		"kind": "rest",
		"time": time_name,
		"view": view,
		"camera_source": "audit close camera; subject/state remain production",
		"camera_transform": _transform(camera.global_transform),
		"subject_transform": _transform(resting.global_transform),
		"rest_state": _manifest.get("rest_state", {}).duplicate(true),
		"capture_check": problems,
	}
	await _save_frame(frame_name, record)


func _rest_frame_offset(view: String, time_name: String) -> int:
	if time_name == "day":
		return 0 if view == "side" else 1
	return 2 if view == "side" else 3


## Current animated bounds, not bind/rest AABB. Each skinned vertex is carried
## through the live Skeleton3D bone pose and Skin inverse bind, then through
## the model's world transform. This makes the recorded low point a measurable
## property of the exact completed Lay/rest frame shown in the PNG.
func _posed_visual_bounds(body: Node3D) -> AABB:
	var points: Array[Vector3] = []
	_posed_total_vertices = 0
	_posed_skinned_vertices = 0
	for raw: Node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := raw as MeshInstance3D
		if mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
			continue
		var skeleton := _skeleton_for(mesh_instance)
		var skin := mesh_instance.skin
		for surface in mesh_instance.mesh.get_surface_count():
			var arrays := mesh_instance.mesh.surface_get_arrays(surface)
			var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var bones := arrays[Mesh.ARRAY_BONES] as PackedInt32Array
			var weights := arrays[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array
			_posed_total_vertices += vertices.size()
			if skeleton == null or skin == null or bones.is_empty() or weights.is_empty():
				for vertex: Vector3 in vertices:
					points.append(mesh_instance.global_transform * vertex)
				continue
			var stride := int(bones.size() / maxi(vertices.size(), 1))
			for vertex_index in vertices.size():
				var posed := Vector3.ZERO
				var total := 0.0
				for influence in stride:
					var offset := vertex_index * stride + influence
					var weight := float(weights[offset])
					var bind_index := int(bones[offset])
					if weight <= 0.0 or bind_index < 0 or bind_index >= skin.get_bind_count():
						continue
					var bone := skin.get_bind_bone(bind_index)
					if bone < 0:
						bone = skeleton.find_bone(skin.get_bind_name(bind_index))
					if bone < 0:
						continue
					posed += (skeleton.get_bone_global_pose(bone) \
						* skin.get_bind_pose(bind_index) * vertices[vertex_index]) * weight
					total += weight
				if total > 0.0:
					points.append(skeleton.global_transform * (posed / total))
					_posed_skinned_vertices += 1
	if points.is_empty():
		return AABB()
	var low := points[0]
	var high := points[0]
	for point: Vector3 in points:
		low = Vector3(minf(low.x, point.x), minf(low.y, point.y), minf(low.z, point.z))
		high = Vector3(maxf(high.x, point.x), maxf(high.y, point.y), maxf(high.z, point.z))
	return AABB(low, high - low)


func _skeleton_for(mesh: MeshInstance3D) -> Skeleton3D:
	var named := mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
	if named != null:
		return named
	var ancestor := mesh.get_parent()
	while ancestor != null:
		if ancestor is Skeleton3D:
			return ancestor as Skeleton3D
		ancestor = ancestor.get_parent()
	return null


func _animation_player(node: Node) -> AnimationPlayer:
	var found := node.find_children("*", "AnimationPlayer", true, false)
	return null if found.is_empty() else found[0] as AnimationPlayer


func _wait_for_station() -> void:
	_release_all_motion()
	for i in SETTLE_LIMIT:
		await physics_frame
		_update_heading_from_velocity()
		if is_instance_valid(_companion) and not bool(_companion.call("is_closing")):
			var metrics := _formation_metrics()
			if float(metrics.station_error_xz_m) <= float(_follower_cfg.get("station_stop_distance", 0.9)) + 0.15:
				return
	_warning("companion did not settle inside authored station tolerance before capture")


func _drive(actions: Array[String], frames: int) -> void:
	_set_actions(actions, true)
	for i in frames:
		await physics_frame
		_update_heading_from_velocity()
	_set_actions(actions, false)


func _set_actions(actions: Array[String], pressed: bool) -> void:
	for action: String in actions:
		if pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)


func _release_all_motion() -> void:
	_set_actions(["move_forward", "move_back", "move_left", "move_right", "sprint"], false)


func _update_heading_from_velocity() -> void:
	var flat := Vector3(_player.velocity.x, 0.0, _player.velocity.z)
	if flat.length_squared() > 0.01:
		_last_heading = flat.normalized()


func _pin_time(time_name: String) -> void:
	if _weather != null:
		if _weather.has_method("set_weather"):
			_weather.call("set_weather", "clear")
		_weather.set_process(false)
		_weather.set_physics_process(false)
	_look.call("apply_time", time_name)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_look.set_process(false)
	_look.set_physics_process(false)
	for i in 6:
		await physics_frame


func _save_frame(frame_name: String, record: Dictionary) -> void:
	var image := root.get_texture().get_image()
	var path := _out_dir.path_join(frame_name + ".png")
	if image == null or image.is_empty():
		_fail("%s: viewport returned no image" % frame_name)
		return
	if image.save_png(path) != OK:
		_fail("%s: save_png failed" % frame_name)
		return
	record["file"] = path
	record["image_size"] = [image.get_width(), image.get_height()]
	record["bytes"] = FileAccess.get_file_as_bytes(path).size()
	_records.append(record)
	print("COMPANION CAPTURE %s -> %s" % [frame_name, path])
	_write_manifest()


func _hide_overlays() -> void:
	for child: Node in _world.find_children("*", "CanvasLayer", true, false):
		(child as CanvasLayer).visible = false
	for child: Node in root.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false


func _point_segment_distance(point: Vector3, start: Vector3, finish: Vector3) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _transform(value: Transform3D) -> Dictionary:
	return {
		"origin": _vec3(value.origin),
		"basis_x": _vec3(value.basis.x),
		"basis_y": _vec3(value.basis.y),
		"basis_z": _vec3(value.basis.z),
	}


func _begin_manifest() -> void:
	_manifest = {
		"schema_version": 1,
		"production_scene": SCENE,
		"output_directory": _out_dir,
		"started_utc": Time.get_datetime_string_from_system(true),
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [root.size.x, root.size.y],
		"planned_frames": PLANNED_FRAMES.duplicate(),
		"expected_frame_count": PLANNED_FRAMES.size(),
		"fixture_disclosure": "One production Meadows boot and production Party, EncounterDirector, follower_creature, player controller, CameraRig and Stronghold CreatureBed. Player reaches an open capture stage through Game.debug_teleport_to, then moves by real input. Formation uses the gameplay camera. Rest uses the shipped bed assignment/recall/RestingCreature/play_rest path and a close audit camera. Day/night are audit-pinned with clear weather. No AnimationPlayer seek, model/body pose injection, direct resting flag, combat, route-traversal or multiplayer claim.",
		"frames": _records,
		"failures": _failures,
		"warnings": _warnings,
		"complete": false,
	}


func _write_manifest() -> void:
	_manifest["frames"] = _records
	_manifest["captured_frame_count"] = _records.size()
	_manifest["failures"] = _failures
	_manifest["warnings"] = _warnings
	var file := FileAccess.open(_out_dir.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		push_error("could not write companion capture manifest")
		return
	file.store_string(JSON.stringify(_manifest, "\t") + "\n")
	file.close()


func _warning(message: String) -> void:
	_warnings.append(message)
	push_warning(message)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)
	_write_manifest()


func _finish(complete: bool) -> void:
	_release_all_motion()
	_manifest["finished_utc"] = Time.get_datetime_string_from_system(true)
	_manifest["complete"] = complete
	_write_manifest()
	print("COMPANION CAPTURE %s: %d/%d frames -> %s" % [
		"OK" if complete else "FAILED", _records.size(), PLANNED_FRAMES.size(), _out_dir])
	quit(0 if complete else 1)

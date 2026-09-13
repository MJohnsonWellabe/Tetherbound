extends SceneTree

## OWNER-0912: one production Meadows boot for the last Terrapup/companion
## visual receipts.
##
## Windows production command (Compatibility renderer; deliberately no
## `--headless`):
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_companion_terrapup_0912.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/final-companion-11
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
## The old W12 field at [-430,470] is now dense production woodland. The first
## replacement at [22,9] was the Practice Meadow lists stall: open enough for a
## 1.5m-radius body, but not for the enlarged camera-safe flank target beside
## the stall/building. This is the centre of the shipped Stonewater walkable
## thin-wood clearing, visibly open in final-far-country-thin-woods-03 frames
## 05/06 and still ordinary production Meadows terrain.
const STAGE := Vector2(-145.0, 3390.0)
const OPENING_BYPASS_FLAG := "trainer_defeated_practice"
const TERRAPUP := "terrapup"
const SETTLE_LIMIT := 360
const MOTION_FRAMES := 42
const EXPECTED_CLIP := "faint"
## A companion can have its centre outside the viewport and still cover nearly
## every pixel with a Palworld-scale shell. These caps measure the clipped live
## visual bounds, which is the camera-blocking fact the owner reported.
const MAX_FORMATION_VISIBLE_WIDTH_FRAC := 0.42
const MAX_FORMATION_VISIBLE_AREA_FRAC := 0.28

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
var _terrain: Node = null
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
var _posed_unskinned_vertices := 0
var _posed_bone_payload_types: Dictionary = {}
var _posed_weight_payload_types: Dictionary = {}
var _posed_surface_failures: Array[String] = []


func _init() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())
	# SceneTree autoloads are attached after the script constructor returns.
	# Defer the capture so the production Game singleton is available.
	call_deferred("_run")


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
	_terrain = _find_terrain(_world)
	if _player == null or _director == null or _rig == null or _camera == null or _look == null:
		_fail("production Player, EncounterDirector, CameraRig/Camera3D or WorldLook is missing")
		return false
	_camera.make_current()
	var opening: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/config/opening.json"))
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
	if not (await _wait_for_station()):
		return
	await _capture_formation("01-formation-settled-day", "day", "settled", [])
	await _pin_time("night")
	await _capture_formation("02-formation-settled-night", "night", "settled", [])

	await _pin_time("day")
	await _capture_motion("03-formation-left-motion-day", ["move_forward", "move_left"])
	if not (await _wait_for_station()):
		return
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
	problems.append_array(_formation_visual_problems(metrics))
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
	if not problems.is_empty():
		_fail("%s: refused camera-blocked production formation: %s" % [
			frame_name, " | ".join(problems)])
		return
	await _save_frame(frame_name, record)


func _formation_metrics() -> Dictionary:
	var heading := _last_heading
	heading.y = 0.0
	heading = heading.normalized() if heading.length_squared() > 0.001 else Vector3.FORWARD
	var authored_clearance := float(_follower_cfg.get("side_offset", 0.0))
	var resolved_offset := float(_companion.call("resolved_side_offset"))
	var visual_extent := float(_companion.call("visual_flank_extent"))
	var resolved_forward := float(_companion.call("resolved_forward_offset"))
	var target := _companion.call("formation_target") as Vector3
	var actual_gap := _flat_distance(_companion.global_position, target)
	var camera_forward := Vector3(-_camera.global_basis.z.x, 0.0,
		-_camera.global_basis.z.z).normalized()
	var target_offset := target - _player.global_position
	var actual_offset := _companion.global_position - _player.global_position
	var line_clearance := _point_segment_distance(
		_companion.global_position, _camera.global_position, _player.global_position) \
		- float(_companion.call("body_radius"))
	var screen := _camera.unproject_position(
		_companion.global_position + Vector3.UP * float(_companion.call("body_height")) * 0.5)
	var visual_bounds: Variant = _visual_world_bounds(_companion)
	var coverage := _screen_coverage(_camera, visual_bounds as AABB) \
		if visual_bounds is AABB else {"valid": false}
	return {
		"authored_side_clearance_m": authored_clearance,
		"resolved_side_offset_m": resolved_offset,
		"body_radius_m": float(_companion.call("body_radius")),
		"visual_flank_extent_m": visual_extent,
		"authored_back_offset_m": float(_follower_cfg.get("back_offset", 0.0)),
		"authored_visual_lead_height_ratio": float(
			_follower_cfg.get("visual_lead_height_ratio", 0.0)),
		"authored_moving_station_stop_m": float(
			_follower_cfg.get("moving_station_stop_distance", 0.0)),
		"resolved_forward_offset_m": resolved_forward,
		"resolved_station_distance_m": float(_companion.call("resolved_station_distance")),
		"camera_depth_forward": _vec3(camera_forward),
		"target_camera_depth_m": target_offset.dot(camera_forward),
		"actual_camera_depth_m": actual_offset.dot(camera_forward),
		"heading": _vec3(heading),
		"expected_station": _vec3(target),
		"station_error_xz_m": actual_gap,
		"player_gap_xz_m": _flat_distance(_companion.global_position, _player.global_position),
		"camera_axis_surface_clearance_m": line_clearance,
		"companion_screen_px": [screen.x, screen.y],
		"companion_behind_camera": _camera.is_position_behind(_companion.global_position),
		"companion_centre_in_frustum": _camera.is_position_in_frustum(_companion.global_position),
		"follower_reports_closing": bool(_companion.call("is_closing")),
		"visible_bounds": coverage,
	}


func _formation_visual_problems(metrics: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var coverage := metrics.get("visible_bounds", {}) as Dictionary
	if not bool(coverage.get("valid", false)):
		out.append("companion live visual bounds could not be projected")
		return out
	var width := float(coverage.get("visible_frame_width_frac", 1.0))
	var area := float(coverage.get("visible_frame_area_frac", 1.0))
	if width > MAX_FORMATION_VISIBLE_WIDTH_FRAC:
		out.append("companion covers %.0f%% of frame width (%.0f%% maximum)" % [
			width * 100.0, MAX_FORMATION_VISIBLE_WIDTH_FRAC * 100.0])
	if area > MAX_FORMATION_VISIBLE_AREA_FRAC:
		out.append("companion covers %.0f%% of frame area (%.0f%% maximum)" % [
			area * 100.0, MAX_FORMATION_VISIBLE_AREA_FRAC * 100.0])
	return out


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
	var animation: AnimationPlayer = null
	var waited_frames := 0
	var saw_expected_assignment := false
	var saw_expected_playback := false
	var last_animation_state: Dictionary = {}
	for i in SETTLE_LIMIT:
		await physics_frame
		waited_frames = i + 1
		resting = bed.get_node_or_null(^"RestingCreature") as Node3D
		if resting != null and _director.call("ally_body") == null:
			animation = _animation_player(resting)
			if animation != null:
				last_animation_state = _animation_state(animation)
				if animation.assigned_animation == EXPECTED_CLIP:
					saw_expected_assignment = true
					saw_expected_playback = saw_expected_playback or animation.is_playing()
					if not animation.is_playing():
						break
	_manifest["rest_transition"] = {
		"waited_physics_frames": waited_frames,
		"rest_body_built": resting != null,
		"follower_recalled": _director.call("ally_body") == null,
		"expected_clip": EXPECTED_CLIP,
		"expected_assignment_seen": saw_expected_assignment,
		"expected_playback_seen": saw_expected_playback,
		"final_animation": last_animation_state,
	}
	_write_manifest()
	if resting == null:
		_fail("CreatureBed never built its production RestingCreature")
		return
	if _director.call("ally_body") != null:
		_fail("EncounterDirector did not recall the deployed follower when Party marked it resting")
		return
	if animation == null:
		_fail("Terrapup RestingCreature exposes no AnimationPlayer")
		return
	# AnimationPlayer clears `current_animation` when a non-looping clip reaches
	# its end. `assigned_animation` deliberately retains the last clip, so it is
	# the engine's truthful answer to which pose a stopped player is holding.
	# Waiting for stopped playback and then checking `current_animation` made the
	# previous production run reject the exact successful completion it awaited.
	if animation.assigned_animation != EXPECTED_CLIP:
		_fail("Terrapup rest assigned '%s' instead of production '%s' (current='%s', playing=%s, position=%.3f/%.3f)" % [
			animation.assigned_animation, EXPECTED_CLIP, animation.current_animation,
			str(animation.is_playing()), animation.current_animation_position,
			animation.current_animation_length])
		return
	if animation.is_playing():
		_fail("Terrapup production '%s' rest clip did not finish within %d physics frames (position=%.3f/%.3f)" % [
			EXPECTED_CLIP, SETTLE_LIMIT, animation.current_animation_position,
			animation.current_animation_length])
		return
	var expected_anchor := bed.global_transform * CREATURE_BED.REST_ANCHOR
	var posed := _posed_visual_bounds(resting)
	if posed.size.length_squared() <= 0.000001 or _posed_skinned_vertices <= 0 \
			or _posed_total_vertices != _posed_skinned_vertices + _posed_unskinned_vertices \
			or not _posed_surface_failures.is_empty():
		_fail("could not measure Terrapup's complete live posed bounds (total=%d, skinned=%d, unskinned=%d, bone_payloads=%s, weight_payloads=%s, surface_failures=%s)" % [
			_posed_total_vertices, _posed_skinned_vertices, _posed_unskinned_vertices,
			JSON.stringify(_posed_bone_payload_types),
			JSON.stringify(_posed_weight_payload_types),
			JSON.stringify(_posed_surface_failures)])
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
		"animation": animation.assigned_animation,
		"current_animation": animation.current_animation,
		"expected_assignment_seen": saw_expected_assignment,
		"expected_playback_seen": saw_expected_playback,
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
		"posed_unskinned_vertices": _posed_unskinned_vertices,
		"posed_bone_payload_types": _posed_bone_payload_types.duplicate(true),
		"posed_weight_payload_types": _posed_weight_payload_types.duplicate(true),
		"posed_surface_failures": _posed_surface_failures.duplicate(),
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
		await _capture_rest_view(rest_camera, bed, resting, posed, "side", time_name)
		await _capture_rest_view(rest_camera, bed, resting, posed, "three-quarter", time_name)


func _capture_rest_view(camera: Camera3D, bed: Node3D, resting: Node3D, posed: AABB,
		view: String, time_name: String) -> void:
	var target := posed.get_center()
	var forward := -resting.global_basis.z.normalized()
	var side := resting.global_basis.x.normalized()
	# The authored bed sits five metres toward the west wall of its room. The
	# former +side seat followed Terrapup's rotated -X basis through that wall;
	# the opposite bearings below remain inside the chamber and preserve two
	# genuinely different reads of the same untouched live pose.
	var direction := -side if view == "side" else (-side - forward * 0.45).normalized()
	var bed_bounds: Variant = _visual_world_bounds(bed, resting)
	var subjects: Array = [{"name": "Terrapup live rest pose", "aabb": posed, "body": resting}]
	if bed_bounds is AABB:
		subjects.append({"name": "production creature bed", "aabb": bed_bounds, "body": bed})
	var viewport_size := camera.get_viewport().get_visible_rect().size
	var distance := CAPTURE_CHECK.fit_distance(target, direction,
		maxf(0.35, posed.size.y * 0.14), posed.size.y * 0.05,
		camera.fov, viewport_size, subjects, 0.08, 5.2, 12.0, 0.2, 0.72)
	if distance < 0.0:
		_fail("could not fit live Terrapup and its production bed from the %s interior seat" % view)
		return
	camera.global_transform = CAPTURE_CHECK.camera_transform_at(target, direction, distance,
		maxf(0.35, posed.size.y * 0.14), posed.size.y * 0.05)
	if _terrain != null and _terrain.has_method("set_camera"):
		_terrain.call("set_camera", camera)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var frame_name := "%02d-terrapup-lay-%s-%s" % [
		5 + _rest_frame_offset(view, time_name), view, time_name]
	var problems := CAPTURE_CHECK.problems(self, camera, "clear", resting)
	problems.append_array(CAPTURE_CHECK.readable_problems_for_camera(camera,
		[{"name": "Terrapup live rest pose", "aabb": posed, "body": resting}],
		{"min_height_frac": 0.28, "min_inside_frac": 0.90, "max_height_frac": 0.72}))
	if bed_bounds is AABB:
		problems.append_array(CAPTURE_CHECK.readable_problems_for_camera(camera,
			[{"name": "production creature bed", "aabb": bed_bounds, "body": bed}],
			{"min_height_frac": 0.04, "min_inside_frac": 0.75, "max_height_frac": 0.65}))
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
		"posed_screen_coverage": _screen_coverage(camera, posed),
	}
	if not problems.is_empty():
		_fail("%s: refused obstructed/degraded rest frame: %s" % [
			frame_name, " | ".join(problems)])
		return
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
	_posed_unskinned_vertices = 0
	_posed_bone_payload_types.clear()
	_posed_weight_payload_types.clear()
	_posed_surface_failures.clear()
	for raw: Node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := raw as MeshInstance3D
		if mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
			continue
		var skeleton := _skeleton_for(mesh_instance)
		var skin := mesh_instance.skin
		for surface in mesh_instance.mesh.get_surface_count():
			var arrays := mesh_instance.mesh.surface_get_arrays(surface)
			var surface_name := "%s[%d]" % [str(body.get_path_to(mesh_instance)), surface]
			if arrays.size() <= Mesh.ARRAY_WEIGHTS:
				_posed_surface_failures.append("%s returned only %d surface arrays" % [
					surface_name, arrays.size()])
				continue
			var raw_vertices: Variant = arrays[Mesh.ARRAY_VERTEX]
			if not raw_vertices is PackedVector3Array:
				_posed_surface_failures.append("%s vertex payload is %s" % [
					surface_name, type_string(typeof(raw_vertices))])
				continue
			var vertices := raw_vertices as PackedVector3Array
			# ArrayMesh's documented bone payload is PackedInt32Array, but the
			# production Terrapup GLTF has reached different render paths as
			# PackedFloat32Array and PackedInt32Array. Some of its other surfaces
			# are honestly unskinned and return Nil for BOTH bones and weights.
			# Normalize supported numeric payloads, and distinguish that valid
			# paired-Nil case from a malformed half-skinned surface.
			var raw_bones: Variant = arrays[Mesh.ARRAY_BONES]
			var raw_weights: Variant = arrays[Mesh.ARRAY_WEIGHTS]
			_record_payload_type(_posed_bone_payload_types, raw_bones)
			_record_payload_type(_posed_weight_payload_types, raw_weights)
			var bones := _bone_indices(raw_bones)
			var weights := _bone_weights(raw_weights)
			_posed_total_vertices += vertices.size()
			if bones.is_empty() and weights.is_empty():
				for vertex: Vector3 in vertices:
					points.append(mesh_instance.global_transform * vertex)
				_posed_unskinned_vertices += vertices.size()
				continue
			if bones.is_empty() != weights.is_empty():
				_posed_surface_failures.append("%s has unmatched bones/weights (%d/%d)" % [
					surface_name, bones.size(), weights.size()])
				continue
			if skeleton == null or skin == null:
				_posed_surface_failures.append("%s has skin payloads but no live Skeleton3D/Skin" % surface_name)
				continue
			if bones.size() != weights.size() or vertices.is_empty() \
					or bones.size() % vertices.size() != 0:
				_posed_surface_failures.append("%s has invalid vertex/bone/weight sizes (%d/%d/%d)" % [
					surface_name, vertices.size(), bones.size(), weights.size()])
				continue
			var stride := int(bones.size() / maxi(vertices.size(), 1))
			var unweighted_vertices := 0
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
				else:
					unweighted_vertices += 1
			if unweighted_vertices > 0:
				_posed_surface_failures.append("%s has %d weighted vertices with no valid influence" % [
					surface_name, unweighted_vertices])
	if points.is_empty():
		return AABB()
	var low := points[0]
	var high := points[0]
	for point: Vector3 in points:
		low = Vector3(minf(low.x, point.x), minf(low.y, point.y), minf(low.z, point.z))
		high = Vector3(maxf(high.x, point.x), maxf(high.y, point.y), maxf(high.z, point.z))
	return AABB(low, high - low)


## Imported meshes may expose bone indices as integral floats even though the
## surface contract describes integers. Normalize the numeric packed-array
## variants seen across import/render paths; an unsupported payload stays empty
## and is reported by the complete-surface gate above rather than crashing.
func _bone_indices(raw: Variant) -> PackedInt32Array:
	if raw == null:
		return PackedInt32Array()
	if raw is PackedInt32Array:
		return raw as PackedInt32Array
	var out := PackedInt32Array()
	if raw is PackedFloat32Array:
		var float32 := raw as PackedFloat32Array
		out.resize(float32.size())
		for index in float32.size():
			out[index] = int(float32[index])
	elif raw is PackedFloat64Array:
		var float64 := raw as PackedFloat64Array
		out.resize(float64.size())
		for index in float64.size():
			out[index] = int(float64[index])
	elif raw is PackedInt64Array:
		var int64 := raw as PackedInt64Array
		out.resize(int64.size())
		for index in int64.size():
			out[index] = int(int64[index])
	elif raw is Array:
		var values := raw as Array
		out.resize(values.size())
		for index in values.size():
			out[index] = int(values[index])
	return out


## Weight slots have the same renderer/importer variability as bone slots.
## Nil is not an error by itself: a surface with paired Nil bones/weights is
## unskinned and is carried through its MeshInstance3D transform above. Any
## one-sided or unsupported payload remains empty and the surface-failure gate
## rejects it, so this normalization cannot turn malformed skinning into a
## plausible static bound.
func _bone_weights(raw: Variant) -> PackedFloat32Array:
	if raw == null:
		return PackedFloat32Array()
	if raw is PackedFloat32Array:
		return raw as PackedFloat32Array
	var out := PackedFloat32Array()
	if raw is PackedFloat64Array:
		var float64 := raw as PackedFloat64Array
		out.resize(float64.size())
		for index in float64.size():
			out[index] = float(float64[index])
	elif raw is Array:
		var values := raw as Array
		out.resize(values.size())
		for index in values.size():
			out[index] = float(values[index])
	return out


func _record_payload_type(counts: Dictionary, raw: Variant) -> void:
	var payload_type := type_string(typeof(raw))
	counts[payload_type] = int(counts.get(payload_type, 0)) + 1


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


func _animation_state(player: AnimationPlayer) -> Dictionary:
	return {
		"current_animation": player.current_animation,
		"assigned_animation": player.assigned_animation,
		"playing": player.is_playing(),
		"position_s": player.current_animation_position,
		"length_s": player.current_animation_length,
		"speed_scale": player.speed_scale,
	}


func _wait_for_station() -> bool:
	_release_all_motion()
	for i in SETTLE_LIMIT:
		await physics_frame
		_update_heading_from_velocity()
		if is_instance_valid(_companion) and not bool(_companion.call("is_closing")):
			var metrics := _formation_metrics()
			# A stopped follower is deliberately held by the production controller's
			# station hysteresis until it crosses station_resume_distance. During the
			# last few frames of a diagonal release, the leader heading can settle
			# after the follower first entered the tighter stop radius, leaving a
			# truthful stationary error between the two thresholds. Requiring the
			# stop threshold here rejected exactly that valid hold (closing=false at
			# 1.56 m with the authored 1.60 m resume threshold). The honest settled
			# gate is therefore the same one the shipped follower uses: not closing
			# and still inside its resume radius.
			if float(metrics.station_error_xz_m) <= float(
					_follower_cfg.get("station_resume_distance", 1.6)) + 0.05:
				return true
	var final_metrics := _formation_metrics() if is_instance_valid(_companion) else {}
	_fail("companion station settle timed out after %d physics frames (closing=%s, error_xz_m=%s, player_gap_xz_m=%s)" % [
		SETTLE_LIMIT,
		str(_companion.call("is_closing")) if is_instance_valid(_companion) else "missing",
		str(final_metrics.get("station_error_xz_m", "missing")),
		str(final_metrics.get("player_gap_xz_m", "missing")),
	])
	return false


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


func _screen_coverage(camera: Camera3D, bounds: AABB) -> Dictionary:
	var size := camera.get_viewport().get_visible_rect().size
	var projected := CAPTURE_CHECK.projected_rect(camera.global_transform, camera.fov, size, bounds)
	if bool(projected.get("behind", true)):
		return {"valid": false, "reason": "a visual-bound corner is behind the camera"}
	var rect := projected.get("rect", Rect2()) as Rect2
	var frame := Rect2(Vector2.ZERO, size)
	var visible := frame.intersection(rect) if frame.intersects(rect) else Rect2()
	return {
		"valid": true,
		"world_min": _vec3(bounds.position),
		"world_max": _vec3(bounds.end),
		"screen_rect_px": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"visible_frame_width_frac": visible.size.x / maxf(size.x, 1.0),
		"visible_frame_height_frac": visible.size.y / maxf(size.y, 1.0),
		"visible_frame_area_frac": visible.get_area() / maxf(size.x * size.y, 1.0),
		"inside_fraction": visible.get_area() / maxf(rect.get_area(), 0.001),
	}


func _visual_world_bounds(node: Node3D, exclude: Node = null) -> Variant:
	if node == exclude:
		return null
	var result: Variant = null
	if node is VisualInstance3D:
		var local := (node as VisualInstance3D).get_aabb()
		if local.size.length_squared() > 0.000001:
			result = node.global_transform * local
	for child: Node in node.get_children():
		if child is Node3D:
			var child_bounds: Variant = _visual_world_bounds(child as Node3D, exclude)
			if child_bounds is AABB:
				result = (result as AABB).merge(child_bounds) if result is AABB else child_bounds
	return result


func _find_terrain(node: Node) -> Node:
	if node.get_class() == "Terrain3D":
		return node
	for child: Node in node.get_children():
		var found := _find_terrain(child)
		if found != null:
			return found
	return null


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

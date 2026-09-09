extends SceneTree

## Bounded contextual evidence for the four repaired pylon consumer families.
##
## This mounts one unmodified production biome, travels through the same
## Game.debug_teleport_to path as the Settings catalogue, and then uses only
## ordinary movement/look actions. It never writes progression, inventory,
## actor transforms, camera transforms, scale, or production state.
##
## Run one biome per process so evidence from the first survives a later stop:
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_pylon_material_supplement.gd -- \
##     --biome=cloudreach --output=res://shots/catalogue/cloudreach/<fresh> \
##     --launch-head=<sha>

const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SCENES := {
	"cloudreach": "res://scenes/world/cloudreach_cliffs.tscn",
	"stormwood": "res://scenes/world/stormwood.tscn",
}
const LIVE_TEXTURE := "res://assets/environment/team_tether/tether_pylon_albedo.png"
const DEAD_TEXTURE := "res://assets/environment/team_tether/tether_pylon_albedo_dead.png"
const BUILD_TIMEOUT_MSEC := 900000
const BOOT_SETTLE_FRAMES := 24
const TRAVEL_SETTLE_FRAMES := 45
const POSE_SETTLE_FRAMES := 8
const LOOK_TIMEOUT_FRAMES := 360
const LOOK_TOLERANCE_DEG := 2.0
const LOOK_STABLE_FRAMES := 8
const ASCENT_FRAMES := 6000
const ASCENT_TOLERANCE_M := 3.5

var _biome := ""
var _output_dir := ""
var _launch_head := ""
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _look: Node
var _weather: Node
var _navigator: RefCounted
var _frames: Array[Dictionary] = []
var _failures: Array[String] = []
var _manifest: Dictionary = {}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("pylon supplement: supplemental pylon capture requires a rendering display")
		quit(1)
		return
	if not _parse_args() or not _prepare_output():
		_finish(false)
		return
	_begin_manifest()
	_write_manifest()
	if not await _mount_world():
		_finish(false)
		return
	_navigator = NAVIGATOR.new(self, _player, _rig, _drive_stick)
	var passed := false
	if _biome == "cloudreach":
		passed = await _capture_cloudreach()
	else:
		passed = await _capture_stormwood()
	_finish(passed and _failures.is_empty())


func _parse_args() -> bool:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--biome="):
			_biome = argument.trim_prefix("--biome=").strip_edges().to_lower()
		elif argument.begins_with("--output="):
			_output_dir = argument.trim_prefix("--output=").strip_edges().trim_suffix("/")
		elif argument.begins_with("--launch-head="):
			_launch_head = argument.trim_prefix("--launch-head=").strip_edges()
	if not SCENES.has(_biome):
		_stop("--biome must be cloudreach or stormwood")
		return false
	if _output_dir.is_empty() or not _output_dir.begins_with("res://"):
		_stop("--output must name a fresh res:// directory")
		return false
	if _launch_head.is_empty():
		_stop("--launch-head is required")
		return false
	return true


func _prepare_output() -> bool:
	var manifest_path := _output_dir.path_join("manifest.json")
	if FileAccess.file_exists(manifest_path):
		_stop("output already contains a manifest: " + manifest_path)
		return false
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if error != OK:
		_stop("could not create output directory (%d)" % error)
		return false
	return true


func _begin_manifest() -> void:
	_manifest = {
		"schema_version": 1,
		"purpose": "Context views for repaired pylon material consumers",
		"biome_id": _biome,
		"scene": str(SCENES[_biome]),
		"launch_head": _launch_head,
		"capture_started_utc": Time.get_datetime_string_from_system(true),
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [root.size.x, root.size.y],
		"fixture_disclosure": "Unmodified production scene and gameplay HUD. Settings-catalogue debug travel, then ordinary left-stick walking and right-stick orbit only. Audit clock pin. No progress, item, actor-transform, camera-transform, scale, or assertion edit.",
		"frames": _frames,
		"failures": _failures,
		"complete": false,
	}


func _mount_world() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_stop("Game autoload is missing")
		return false
	if game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
	game.set("current_realm", _biome)
	var packed := load(str(SCENES[_biome])) as PackedScene
	if packed == null:
		_stop("could not load production scene")
		return false
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + BUILD_TIMEOUT_MSEC
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			_stop("production world shell build timed out")
			return false
		await process_frame
	for _frame in BOOT_SETTLE_FRAMES:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	if _player == null or _rig == null or _camera == null:
		_stop("production Player or CameraRig/Camera3D is missing")
		return false
	if _look == null or not _look.has_method("apply_time"):
		_stop("production WorldLook/apply_time is missing")
		return false
	_camera.make_current()
	return true


func _capture_cloudreach() -> bool:
	if not await _catalogue_travel(Vector2(100.0, 5350.0), "Summit Eyrie"):
		return false
	var stronghold := _world.get_node_or_null(^"Landmarks/SummitEyrieStronghold") as Node3D
	var summit_pylon := stronghold.get_node_or_null(^"OccupiedSummitPylon") as Node3D \
		if stronghold != null else null
	if not _validate_target(summit_pylon, LIVE_TEXTURE, "Cloudreach occupied summit pylon"):
		return false
	if not await _walk_xz(Vector2(100.0, 5310.0), "Cloudreach summit exterior stand"):
		return false
	if not await _capture_pair("cloudreach__stronghold_occupied_summit_pylon", summit_pylon,
			LIVE_TEXTURE, "cloudreach_world.gd"):
		return false

	if not await _catalogue_travel(Vector2(100.0, 5350.0), "Summit Eyrie"):
		return false
	var dressing := _world.get_node_or_null(^"SummitArenaPresentation/OccupiedArenaDressing") as Node3D
	var arena_pylon := _presentation_pylon(dressing, Vector3(-34.0, 0.15, -8.0))
	if not _validate_target(arena_pylon, LIVE_TEXTURE, "Cloudreach summit presentation pylon"):
		return false
	for waypoint: Vector2 in [Vector2(100.0, 5400.0), Vector2(78.0, 5428.0)]:
		if not await _walk_xz(waypoint, "Cloudreach summit arena approach"):
			return false
	return await _capture_pair("cloudreach__summit_arena_pylon", arena_pylon,
		LIVE_TEXTURE, "cloudreach_summit_presentation.gd")


func _capture_stormwood() -> bool:
	if not await _catalogue_travel(Vector2(-700.0, 2300.0), "Rodline Post"):
		return false
	var camp_rod := _world.get_node_or_null(
		^"StormwoodCamps/rodline_refugeDressing/lightning_rod") as Node3D
	if not _validate_target(camp_rod, DEAD_TEXTURE, "Stormwood Rodline Refuge camp rod"):
		return false
	if not await _walk_xz(Vector2(-675.0, 2310.0), "Rodline Refuge camp stand"):
		return false
	if not await _capture_pair("stormwood__rodline_refuge_drained_rod", camp_rod,
			DEAD_TEXTURE, "stormwood_camps.gd"):
		return false

	if not await _catalogue_travel(Vector2(-100.0, 5470.0), "The Stormheart Tree"):
		return false
	var trunk := _world.get_node_or_null(^"StormheartTree") as Node3D
	if trunk == null:
		_stop("production StormheartTree is missing")
		return false
	if not await _walk_xz(Vector2(-100.0, 5350.0), "Stormheart approach foot"):
		return false
	if not await _walk_stormheart_ascent(trunk):
		return false
	var bank := _world.get_node_or_null(^"StormwoodDynamo/DynamoArena/CapacitorBank0") as Node3D
	var bank_pylon := _material_child(bank, LIVE_TEXTURE)
	if not _validate_target(bank_pylon, LIVE_TEXTURE, "Stormwood Dynamo bank 0 pylon"):
		return false
	if not await _walk_xz(Vector2(-76.0, 5456.0), "Dynamo bank context stand"):
		return false
	return await _capture_pair("stormwood__dynamo_bank0_live_pylon", bank_pylon,
		LIVE_TEXTURE, "stormwood_dynamo_arena.gd")


func _catalogue_travel(at: Vector2, label: String) -> bool:
	_release_inputs()
	var game := root.get_node_or_null(^"Game")
	var moved := game != null and bool(game.call("debug_teleport_to", at.x, at.y, _biome, ""))
	if not moved:
		_stop("Settings-catalogue travel refused " + label)
		return false
	for _frame in TRAVEL_SETTLE_FRAMES:
		await physics_frame
	print("PYLON SUPPLEMENT TRAVEL %s -> %s" % [label, str(_player.global_position)])
	return true


func _walk_xz(at: Vector2, label: String) -> bool:
	var horizontal := Vector2(_player.global_position.x, _player.global_position.z).distance_to(at)
	var budget := maxi(1200, ceili(horizontal * 65.0))
	var target := Vector3(at.x, _player.global_position.y, at.y)
	var arrived := bool(await _navigator.call("walk_to", target, budget, 1.2))
	_drive_stick(0.0, 0.0)
	if not arrived:
		_stop("ordinary walk blocked at %s; stopped at %s" % [label, str(_player.global_position)])
		return false
	print("PYLON SUPPLEMENT WALK %s -> %s" % [label, str(_player.global_position)])
	return true


func _walk_stormheart_ascent(trunk: Node3D) -> bool:
	var started := Engine.get_physics_frames()
	var approach := trunk.to_global(Vector3(0.0, 6.0, -40.0))
	var mouth := trunk.to_global(Vector3(-4.0, 6.0, -26.0))
	var ramp_start: Vector3 = trunk.to_global(trunk.call("ascent_point", 0.0))
	var stage := 0
	var last_progress := 0.0
	var furthest := 0.0
	_navigator.call("reset")
	while Engine.get_physics_frames() - started < ASCENT_FRAMES:
		if stage == 0 and _player.global_position.distance_to(approach) < ASCENT_TOLERANCE_M:
			stage = 1
			_navigator.call("reset")
		if stage == 1 and _player.global_position.distance_to(mouth) < 0.8:
			stage = 2
			_navigator.call("reset")
		if stage == 2 and _player.global_position.distance_to(ramp_start) < 0.8:
			stage = 3
			_navigator.call("reset")
		var progress := clampf((_player.global_position.y - (trunk.global_position.y + 6.0)) / 144.0, 0.0, 1.0)
		furthest = maxf(furthest, progress)
		if stage == 3 and furthest >= 0.998 and _player.is_on_floor() \
				and _player.global_position.distance_to(trunk.call("core_anchor")) <= ASCENT_TOLERANCE_M:
			_drive_stick(0.0, 0.0)
			print("PYLON SUPPLEMENT ASCENT -> %s" % str(_player.global_position))
			return true
		var fraction := minf(1.0, maxf(progress + 0.008, last_progress + 0.002))
		var target := approach
		match stage:
			1: target = mouth
			2: target = ramp_start
			3: target = trunk.to_global(trunk.call("ascent_point", fraction))
		last_progress = maxf(last_progress, progress)
		if bool(_navigator.call("can_walk")):
			await _navigator.call("step", target)
		else:
			await physics_frame
	_drive_stick(0.0, 0.0)
	_stop("physical Stormheart ascent exceeded its existing 6000-frame budget at "
		+ str(_player.global_position))
	return false


func _capture_pair(id: String, target: Node3D, texture_path: String,
		consumer: String) -> bool:
	var bounds := _global_mesh_bounds(target)
	if bounds.size == Vector3.ZERO:
		_stop(id + ": target has no rendered bounds")
		return false
	if not await _orbit_to(bounds.get_center()):
		_stop(id + ": ordinary camera orbit could not frame target")
		return false
	for time_name: String in ["day", "night"]:
		var clock := await _pin_time(time_name)
		if clock.is_empty():
			return false
		for _frame in POSE_SETTLE_FRAMES:
			await process_frame
		if not await _capture(id + "__" + time_name, target, bounds, texture_path,
				consumer, clock):
			return false
	return true


func _orbit_to(target: Vector3) -> bool:
	_release_look()
	var stable := 0
	for _frame in LOOK_TIMEOUT_FRAMES:
		var delta := target - _camera.global_position
		var horizontal := maxf(Vector2(delta.x, delta.z).length(), 0.001)
		var wanted_yaw := atan2(-delta.x, -delta.z)
		var wanted_pitch := atan2(delta.y, horizontal)
		var yaw_error := angle_difference(float(_rig.get("yaw")), wanted_yaw)
		var pitch_error := wanted_pitch - float(_rig.get("pitch"))
		_release_look()
		if absf(rad_to_deg(yaw_error)) > LOOK_TOLERANCE_DEG:
			Input.action_press(&"look_left" if yaw_error > 0.0 else &"look_right", 0.65)
		if absf(rad_to_deg(pitch_error)) > LOOK_TOLERANCE_DEG:
			Input.action_press(&"look_up" if pitch_error > 0.0 else &"look_down", 0.65)
		await process_frame
		if absf(rad_to_deg(yaw_error)) <= LOOK_TOLERANCE_DEG \
				and absf(rad_to_deg(pitch_error)) <= LOOK_TOLERANCE_DEG:
			stable += 1
			if stable >= LOOK_STABLE_FRAMES:
				_release_look()
				return true
		else:
			stable = 0
	_release_look()
	return false


func _pin_time(time_name: String) -> Dictionary:
	if _weather != null and _weather.has_method("set_weather"):
		_weather.call("set_weather", "clear")
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_look.call("apply_time", time_name)
	for _frame in 12:
		await physics_frame
	var observed := {"requested": time_name}
	var cycle: Variant = _look.get("_cycle")
	if cycle != null and cycle.has_method("hour_at"):
		var hour := float(cycle.call("hour_at", float(_look.get("_elapsed_seconds"))))
		observed["hour"] = hour
		observed["time_of_day"] = str(cycle.call("time_of_day", hour))
	return observed


func _capture(id: String, target: Node3D, bounds: AABB, texture_path: String,
		consumer: String, clock: Dictionary) -> bool:
	if not _has_texture(target, texture_path):
		_stop(id + ": installed texture disappeared before capture")
		return false
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := _output_dir.path_join(id + ".png")
	if image == null or image.is_empty() or image.get_width() != root.size.x \
			or image.get_height() != root.size.y:
		_stop(id + ": viewport image is empty or wrong-sized")
		return false
	if image.save_png(path) != OK:
		_stop(id + ": save_png failed")
		return false
	var record := {
		"frame_id": id,
		"file": path,
		"consumer": consumer,
		"target_path": str(_world.get_path_to(target)),
		"target_bounds": _aabb(bounds),
		"installed_texture": texture_path,
		"player_position": _vec3(_player.global_position),
		"camera_position": _vec3(_camera.global_position),
		"camera_transform": _transform(_camera.global_transform),
		"camera_rig_transform": _transform(_rig.global_transform),
		"camera_yaw_deg": rad_to_deg(float(_rig.get("yaw"))),
		"camera_pitch_deg": rad_to_deg(float(_rig.get("pitch"))),
		"observed_clock": clock,
		"ordinary_local_walk": true,
		"ordinary_camera_orbit": true,
		"bytes": FileAccess.get_file_as_bytes(path).size(),
	}
	_frames.append(record)
	_write_manifest()
	print("PYLON SUPPLEMENT CAPTURE %s -> %s" % [id, path])
	return true


func _presentation_pylon(dressing: Node3D, expected_local: Vector3) -> Node3D:
	if dressing == null:
		return null
	for raw: Node in dressing.get_children():
		var anchor := raw as Node3D
		if anchor == null or anchor.position.distance_to(expected_local) > 0.05:
			continue
		return _material_child(anchor, LIVE_TEXTURE)
	return null


func _material_child(parent: Node, texture_path: String) -> Node3D:
	if parent == null:
		return null
	for raw: Node in parent.get_children():
		var candidate := raw as Node3D
		if candidate != null and _has_texture(candidate, texture_path):
			return candidate
	return null


func _validate_target(target: Node3D, texture_path: String, label: String) -> bool:
	if target == null or not is_instance_valid(target):
		_stop(label + " is missing")
		return false
	if not _has_texture(target, texture_path):
		_stop(label + " does not resolve installed texture " + texture_path)
		return false
	var bounds := _global_mesh_bounds(target)
	if bounds.size == Vector3.ZERO:
		_stop(label + " has no actual mesh bounds")
		return false
	print("PYLON SUPPLEMENT TARGET %s path=%s bounds=%s" % [
		label, str(_world.get_path_to(target)), str(bounds)])
	return true


func _has_texture(target: Node, texture_path: String) -> bool:
	for mesh_instance: MeshInstance3D in _meshes(target):
		if mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.get_active_material(surface)
			if material is BaseMaterial3D:
				var texture := (material as BaseMaterial3D).albedo_texture
				if texture != null and texture.resource_path == texture_path:
					return true
	return false


func _meshes(target: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if target is MeshInstance3D:
		result.append(target as MeshInstance3D)
	for raw: Node in target.find_children("*", "MeshInstance3D", true, false):
		result.append(raw as MeshInstance3D)
	return result


func _global_mesh_bounds(target: Node) -> AABB:
	var result := AABB()
	var found := false
	for mesh_instance: MeshInstance3D in _meshes(target):
		if mesh_instance.mesh == null:
			continue
		var bounds: AABB = mesh_instance.global_transform * mesh_instance.mesh.get_aabb()
		result = result.merge(bounds) if found else bounds
		found = true
	return result if found else AABB()


func _drive_stick(x: float, y: float) -> void:
	Input.action_release(&"move_forward")
	Input.action_release(&"move_back")
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	if y < -0.2:
		Input.action_press(&"move_forward", -y)
	elif y > 0.2:
		Input.action_press(&"move_back", y)
	if x < -0.2:
		Input.action_press(&"move_left", -x)
	elif x > 0.2:
		Input.action_press(&"move_right", x)


func _release_look() -> void:
	for action: StringName in [&"look_left", &"look_right", &"look_up", &"look_down"]:
		Input.action_release(action)


func _release_inputs() -> void:
	_drive_stick(0.0, 0.0)
	_release_look()


func _stop(reason: String) -> void:
	if _failures.is_empty():
		_failures.append(reason)
	push_error("pylon supplement: " + reason)
	_write_manifest()


func _finish(complete: bool) -> void:
	_release_inputs()
	_manifest["capture_finished_utc"] = Time.get_datetime_string_from_system(true)
	_manifest["captured_frame_count"] = _frames.size()
	_manifest["complete"] = complete and _failures.is_empty()
	_write_manifest()
	print("PYLON SUPPLEMENT %s %d frames biome=%s output=%s" % [
		"OK" if bool(_manifest.complete) else "FAILED", _frames.size(), _biome, _output_dir])
	quit(0 if bool(_manifest.complete) else 1)


func _write_manifest() -> void:
	if _output_dir.is_empty():
		return
	var file := FileAccess.open(_output_dir.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_manifest, "  "))
		file.close()


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _transform(value: Transform3D) -> Dictionary:
	return {
		"basis_x": _vec3(value.basis.x),
		"basis_y": _vec3(value.basis.y),
		"basis_z": _vec3(value.basis.z),
		"origin": _vec3(value.origin),
	}


func _aabb(value: AABB) -> Dictionary:
	return {"position": _vec3(value.position), "size": _vec3(value.size),
		"center": _vec3(value.get_center())}

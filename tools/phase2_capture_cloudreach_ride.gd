extends SceneTree

## Evidence frames for the F06 riding follow-ups: riding the saddled Meadowhart
## off a survivable ledge and off the arrival terrace into open air, then
## dismounting and remounting, through the production camera. At least 30 s of
## game time with the stick held (ledge 8 s + ride-on 6 s + terrace until the
## mounted-fall recovery, then back along the road); `motion_s` counts only
## physics steps taken while the stick is held, shots included, because the
## stick stays held through a shot.
##
## Needs `tools/capture_cloudreach_lane_common.gd` (frame saving and the
## contact sheet) beside it.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --fixed-fps 60 \
##     --script tools/capture_cloudreach_ride_off.gd -- --tag=after
##
## Run it once on main (`--tag=before`) and once on the branch (`--tag=after`).
## `--fixed-fps 60` makes every frame one 1/60 s step however slowly the
## software renderer draws. Rendering is switched off between saved frames,
## and the simulation is unchanged by that.
##
## Disclosed fixture, the same as tests/smoke_cloudreach_saddle_remount.gd:
##   - The party, the saddle and the saddle flag are seeded.
##   - The trainer is teleported onto the upper surface of each edge, and the
##     mount is placed on the road beside them after the trainer has settled
##     (a following companion catching up after a 1.9 km teleport otherwise
##     lands on the terrace's steep shoulder and slides off). A mount not on
##     the road within 2 m before the ride aborts that sequence with an error.
## Every mount, ride, dismount and remount is the real interact and stick
## input. Only base RidingController calls are used, plus `get` of the
## branch's diagnostics (null on main), so the tool runs unchanged on main.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const OUT := "res://ralph/reports/VISUAL/phase2/cloudreach/ride_live"
const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const TEAM := ["meadowhart", "bramblebun", "mudsnout", "terrapup", "brooktail"]
const LEDGE_ROAD := Vector3(-104.0, 401.6, 1664.0)
const LEDGE_TOWARD := Vector3(-94.0, 390.0, 1647.0)
const TERRACE_ROAD := Vector3(7.6, 105.41, -245.03)
const TERRACE_TOWARD := Vector3(10.6, 83.9, -239.4)

var _tag := "phase2"
var _seed := 2042
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node
var _riding: Node
var _director: Node
var _arbiter: Node
var _frames: Array = []
var _shot := 0
var _motion_s := 0.0
var _errors := 0
var _output := ""
var _graphics_capture: Dictionary = {}
var _records: Array[Dictionary] = []
var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=").trim_suffix("/")
	var named_preset := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			named_preset = true
			if arg.trim_prefix("--preset=") not in ["High", "Medium"]:
				push_error("Cloudreach ride review requires High or Medium")
				quit(1)
				return
	if named_preset:
		_graphics_capture = BOOTSTRAP.prepare(self)
		if _graphics_capture.is_empty():
			quit(1)
			return
	elif _output.is_empty():
		_output = "%s/%s" % [OUT, _tag]
	if DisplayServer.get_name() == "headless":
		push_error("Cloudreach ride capture requires a rendering display")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output)) != OK:
		push_error("Cloudreach ride output could not be created")
		quit(1)
		return
	seed(_seed)
	# Forward+ shell construction awaits drawn frames. Suppress drawing only
	# after the real world and mount have finished booting.
	RenderingServer.render_loop_enabled = true
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	game.set("pending_realm_entry", "")
	game.set("saved_player_pose", {})
	var flags: RefCounted = game.get("progression")
	flags.call("set_flag", "realm_key_cloudreach")
	flags.call("set_flag", RIDING.saddle_fitted_flag("meadowhart"))
	var party: RefCounted = PARTY.new()
	for species: String in TEAM:
		party.call("add", SPECIES.spawn(species))
	party.call("set_active", 0)
	game.set("party", party)
	(game.get("inventory") as RefCounted).call("add", "saddle", 1)
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	_arbiter = _world.get_node(^"InteractionArbiter")
	var boot_deadline := Time.get_ticks_msec() + 900000
	while not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > boot_deadline:
			_capture_error("production Cloudreach shell build timed out")
			_finish()
			return
		await process_frame
	if not await _wait_for_mount():
		_capture_error("the mount never appeared after the production shell built")
		_finish()
		return
	_riding = _world.get_node(^"RidingController")
	RenderingServer.render_loop_enabled = false

	if not await _edge_sequence("ledge", LEDGE_ROAD, LEDGE_TOWARD, Vector3(2.0, 0.0, 1.0), 8.0, 1.0):
		_errors += 1
	else:
		# Dismount on whatever ground the ride ended on, then remount by interact.
		await _press("interact")
		await _advance(1.0)
		await _shoot("ledge_dismounted")
		await _walk_to_mount()
		await _press("interact")
		await _advance(0.6)
		await _shoot("ledge_remounted")
		await _ride_for(6.0, 1.5, "ledge_ride_on", _heading_from_rig())

	var recoveries_before := int(_riding.get("mounted_fall_recoveries")) if _riding.get("mounted_fall_recoveries") != null else 0
	if not await _edge_sequence("terrace", TERRACE_ROAD, TERRACE_TOWARD, Vector3(-1.0, 0.0, -2.5), 20.0, 1.0, true):
		_errors += 1
	else:
		await _advance(1.0)
		await _shoot("terrace_after")
		var body: Node3D = _riding.call("mount_body")
		var recovered := int(_riding.get("mounted_fall_recoveries")) > recoveries_before if _riding.get("mounted_fall_recoveries") != null else false
		print("TERRACE_AFTER %s mounted=%s recovered=%s on_floor=%s mount=%s trainer=%s last_dismount_rule=%s" % [_tag,
			_riding.call("is_mounted"), recovered, (body as CharacterBody3D).is_on_floor() if body is CharacterBody3D else "-",
			body.global_position if body != null else "-", _player.global_position, _riding.get("last_dismount_rule")])
		if bool(_riding.call("is_mounted")) and _motion_s < 30.0:
			# Back along the road, away from the edge, to finish 30 s of riding.
			var back := -_heading_from_rig()
			_aim(back)
			await _advance(0.3)
			await _ride_for(minf(30.0 - _motion_s + 0.5, 16.0), 1.5, "terrace_road_back", back)
	if _motion_s < 30.0:
		print("CAPTURE ERROR %s: only %.1f s of stick-held motion (need 30)" % [_tag, _motion_s])
		_errors += 1
	print("RIDE_OFF %s motion_s=%.1f frames=%d errors=%d" % [_tag, _motion_s, _frames.size(), _errors])
	_finish()


## Stand on `road`, put the mount on the road, mount by interact, and ride
## toward `toward`. Returns false (with a printed error) when the fixture
## could not stand the mount on the road.
func _edge_sequence(label: String, road: Vector3, toward: Vector3, mount_offset: Vector3, ride_s: float, every_s: float, stop_on_recovery: bool = false) -> bool:
	if bool(_riding.call("is_mounted")):
		await _press("interact")
		await _advance(1.0)
	_player.global_position = road
	_player.velocity = Vector3.ZERO
	await _advance(1.0)
	var ally: Node3D = _director.call("ally_body")
	if ally != null:
		ally.call("place_on_ground", road + mount_offset)
	await _advance(0.2)
	var standing := ally is CharacterBody3D and (ally as CharacterBody3D).is_on_floor() \
		and absf(ally.global_position.y - road.y) < 2.0
	if not standing:
		print("CAPTURE ERROR %s %s: the mount is not on the road before the ride (mount %s, road y %.2f)" % [_tag, label,
			ally.global_position if ally != null else "-", road.y])
		return false
	await _walk_to_mount()
	await _press("interact")
	await _advance(0.6)
	var body: Node3D = _riding.call("mount_body")
	if body == null or absf(body.global_position.y - road.y) >= 2.0:
		print("CAPTURE ERROR %s %s: not mounted on the road (mounted %s, mount %s)" % [_tag, label, body != null,
			body.global_position if body != null else "-"])
		return false
	var heading := toward - _player.global_position
	heading.y = 0.0
	heading = heading.normalized()
	_aim(heading)
	await _advance(0.3)
	await _shoot("%s_mounted_at_edge" % label)
	await _ride_for(ride_s, every_s, label, heading, stop_on_recovery)
	return true


## Hold the stick along `heading` for `seconds` of physics steps (shots
## included; the stick stays held through them), shooting every `every_s`.
func _ride_for(seconds: float, every_s: float, label: String, heading: Vector3, stop_on_recovery: bool = false) -> void:
	var steps := int(round(seconds * 60.0))
	var every := maxi(1, int(round(every_s * 60.0)))
	var body: Node3D = _riding.call("mount_body")
	var recoveries := _recoveries()
	var start := Engine.get_physics_frames()
	var next_shot := every
	_steer(heading)
	while int(Engine.get_physics_frames() - start) < steps:
		var from := body.global_position if body != null else _player.global_position
		_steer(heading)
		_aim(heading)
		await physics_frame
		var elapsed := int(Engine.get_physics_frames() - start)
		if elapsed >= next_shot:
			next_shot += every
			await _shoot("%s_%04.1fs" % [label, float(elapsed) / 60.0])
		if not bool(_riding.call("is_mounted")):
			break
		if stop_on_recovery and _recoveries() > recoveries:
			print("RIDE %s %s recovered at t=%.1f mount=%s" % [_tag, label, float(elapsed) / 60.0, body.global_position if body != null else "-"])
			break
		if body != null and from.y - body.global_position.y > 0.05 and elapsed % 30 == 0:
			print("RIDE %s %s t=%.1f y=%.2f" % [_tag, label, float(elapsed) / 60.0, body.global_position.y])
	_motion_s += float(Engine.get_physics_frames() - start) / 60.0
	_release_move()


func _recoveries() -> int:
	var raw: Variant = _riding.get("mounted_fall_recoveries")
	return int(raw) if raw != null else 0


func _aim(heading: Vector3) -> void:
	_rig.set("yaw", atan2(-heading.x, -heading.z))
	_rig.set("pitch", deg_to_rad(-24.0))


func _heading_from_rig() -> Vector3:
	var basis: Basis = _rig.call("planar_basis")
	return -basis.z


func _steer(heading: Vector3) -> void:
	var local: Vector3 = (_rig.call("planar_basis") as Basis).inverse() * heading
	Input.action_press("move_right", maxf(local.x, 0.0))
	Input.action_press("move_left", maxf(-local.x, 0.0))
	Input.action_press("move_back", maxf(local.z, 0.0))
	Input.action_press("move_forward", maxf(-local.z, 0.0))


func _release_move() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _walk_to_mount() -> void:
	for frame in 900:
		_arbiter.call("_recompute")
		if _arbiter.call("winning_provider") == _riding:
			break
		var body: Node3D = _director.call("ally_body")
		if body == null:
			break
		var offset := body.global_position - _player.global_position
		offset.y = 0.0
		_steer(offset.normalized())
		await physics_frame
	_release_move()
	await _advance(0.1)


func _wait_for_mount() -> bool:
	for frame in 2400:
		await physics_frame
		_director = _world.get_node_or_null(^"EncounterDirector")
		if _director == null:
			continue
		if frame % 120 == 90 and _director.call("ally_body") == null:
			await _press("creature_recall")
		var body: Node3D = _director.call("ally_body")
		if body != null and is_instance_valid(body) and body.visible and frame > 60:
			await _advance(1.0)
			return true
	return false


## Render just this frame: the loop is on for two drawn frames, then off again.
func _shoot(name: String) -> void:
	var shown: Array[CanvasLayer] = []
	for layer: Node in _world.find_children("*", "CanvasLayer", true, false):
		if (layer as CanvasLayer).visible:
			shown.append(layer as CanvasLayer)
			(layer as CanvasLayer).visible = false
	RenderingServer.render_loop_enabled = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_shot += 1
	var image := root.get_texture().get_image()
	var observed_preset := GRAPHICS.selected()
	var observed_renderer := RenderingServer.get_current_rendering_method()
	var valid := image != null and not image.is_empty()
	if not _graphics_capture.is_empty():
		valid = valid and image.get_size() == Vector2i(1920, 1080) \
			and observed_preset == str(_graphics_capture.preset) \
			and observed_renderer == str(_graphics_capture.renderer)
	var path := ""
	if valid:
		path = LANE.save_frame(self, _output, "%s_%02d_%s" % [_tag, _shot, name], _frames)
	if not valid or path.is_empty():
		_capture_error("%s: image, observed preset/renderer/raster or PNG save failed" % name)
	else:
		var camera := _world.get_node(^"CameraRig/Camera3D") as Camera3D
		var mount: Node3D = _riding.call("mount_body")
		_records.append({"id": name, "file": path, "bytes": FileAccess.get_file_as_bytes(path).size(),
			"sha256": FileAccess.get_sha256(path), "resolution": [image.get_width(), image.get_height()],
			"graphics_capture": _graphics_capture.duplicate(true),
			"observed_preset": observed_preset, "observed_graphics": GRAPHICS.values(),
			"observed_renderer": observed_renderer, "physics_frame": Engine.get_physics_frames(),
			"motion_s_before_current_leg": _motion_s, "mounted": bool(_riding.call("is_mounted")),
			"player_position": _vec3(_player.global_position), "camera_position": _vec3(camera.global_position),
			"mount_position": _vec3(mount.global_position) if mount != null else [],
			"mount_on_floor": mount is CharacterBody3D and (mount as CharacterBody3D).is_on_floor(),
			"recoveries": _recoveries(), "camera": "production CameraRig/Camera3D"})
	RenderingServer.render_loop_enabled = false
	for layer: CanvasLayer in shown:
		layer.visible = true
	var body: Node3D = _riding.call("mount_body") if _riding != null else null
	print("SHOT %s %s trainer=%s mount=%s mounted=%s" % [_tag, name, _player.global_position,
		body.global_position if body != null else "-", _riding.call("is_mounted") if _riding != null else "-"])


func _advance(seconds: float) -> void:
	for i in int(round(seconds * 60.0)):
		await physics_frame



func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _capture_error(message: String) -> void:
	_errors += 1
	_failures.append(message)
	push_error("Cloudreach ride capture: " + message)


func _finish() -> void:
	_release_move()
	RenderingServer.render_loop_enabled = true
	var ids: Array[String] = []
	for record: Dictionary in _records:
		ids.append(str(record.id))
	for required: String in ["ledge_mounted_at_edge", "ledge_dismounted", "ledge_remounted",
		"terrace_mounted_at_edge", "terrace_after"]:
		if required not in ids:
			_capture_error("required view missing: " + required)
	if _motion_s < 30.0 or _records.size() != _shot:
		_capture_error("30 seconds of stick-held motion and every requested PNG are required")
	var sheet_path := "%s/_sheet_ride_off_%s.png" % [OUT, _tag] if _graphics_capture.is_empty() \
		else _output + "/_sheet.png"
	if not _frames.is_empty():
		LANE.contact_sheet(_frames, sheet_path, 4, 480)
		var sheet := Image.load_from_file(sheet_path)
		if sheet == null or sheet.is_empty():
			_capture_error("contact sheet save/readback failed")
	var manifest := {"tool": "tools/phase2_capture_cloudreach_ride.gd", "biome": "cloudreach",
		"scene": "res://scenes/world/cloudreach_cliffs.tscn", "seed": _seed, "tag": _tag,
		"graphics_capture": _graphics_capture, "display_server": DisplayServer.get_name(),
		"observed_preset": GRAPHICS.selected(), "observed_graphics": GRAPHICS.values(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(), "resolution": [root.size.x, root.size.y],
		"motion_s": _motion_s, "requested_frames": _shot, "frames": _records, "errors": _errors,
		"failures": _failures, "complete": _errors == 0 and not _records.is_empty(),
		"fixture": "Five directly created companions, supplied saddle/flag, two declared edge teleports; real interact and stick ride/dismount/remount. Rendering suppressed between saved frames after boot; HUD hidden only for shots. Visual/movement fixture, no earned campaign, timing or visual PASS claim.",
		"finished_utc": Time.get_datetime_string_from_system(true)}
	var text := JSON.stringify(manifest, "\t") + "\n"
	var file := FileAccess.open(_output + "/manifest.json", FileAccess.WRITE)
	if file == null:
		_capture_error("manifest could not be opened")
	else:
		file.store_string(text)
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK or FileAccess.get_file_as_string(_output + "/manifest.json") != text:
			_capture_error("manifest flush/readback failed")
	quit(0 if _errors == 0 and not _records.is_empty() else 1)

extends SceneTree

## Fixed-camera capture for one visual item (WORKFLOW 8.1 rule 10): boots the
## Meadows, stands the trainer at each view's `player` point (the 1.80 m
## ruler), puts a free camera at `pos` looking at `look_at` (or by
## yaw/pitch), sets WorldLook's named time and WorldWeather's preset, and
## saves <out>/<view id>.png. The same set gives the same cameras every round,
## unlike a walk whose stops drift with frame timing. HUD hidden; the
## companion stays recalled (its clearance is covered by the follower tests).
##
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
##     --script res://tools/visual_judge/capture_camera_set.gd -- \
##     --set=res://tools/visual_judge/camera_sets/F17-6.json --out=/abs/dir

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 12
const RAIN_SETTLE_FRAMES := 16
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _hall_prefabs: RefCounted


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var set_path := ""
	var out := ""
	var expected_preset := ""
	var selected_views: PackedStringArray = []
	var hall_ground_y := NAN
	var hall_arm := "baseline"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--set="):
			set_path = a.trim_prefix("--set=")
		elif a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--preset="):
			expected_preset = a.trim_prefix("--preset=")
		elif a.begins_with("--views="):
			selected_views = a.trim_prefix("--views=").split(",", false)
		elif a.begins_with("--hall-only-ground-y="):
			hall_ground_y = float(a.trim_prefix("--hall-only-ground-y="))
		elif a.begins_with("--hall-arm="):
			hall_arm = a.trim_prefix("--hall-arm=")
	if hall_arm not in ["baseline", "furnishing", "frame", "frame-no-night-floor", "frame-lantern-lit", "frame-window-lit", "frame-waymark"] or (hall_arm != "baseline" and is_nan(hall_ground_y)):
		push_error("CAMERA_SET --hall-arm must be baseline/furnishing/frame/frame-no-night-floor/frame-lantern-lit/frame-window-lit/frame-waymark; candidates require isolated Hall")
		quit(2)
		return
	var camera_set: Variant = JSON.parse_string(FileAccess.get_file_as_string(set_path))
	if not camera_set is Dictionary or out == "":
		push_error("capture_camera_set: needs --set=<camera set json> and --out=<dir>")
		quit(2)
		return
	var contact: Dictionary = camera_set.get("contact_fixture", {})
	if not contact.is_empty():
		if not is_equal_approx(float(contact.get("idle_sample_seconds", -1.0)), 0.2):
			push_error("CAMERA_SET contact fixture requires the measured idle sample")
			quit(2)
			return
		if is_nan(hall_ground_y) or not is_equal_approx(hall_ground_y, float(contact["required_ground_y"])):
			push_error("CAMERA_SET contact fixture requires its measured isolated Hall ground height")
			quit(2)
			return
		for path: String in contact.get("source_hashes", {}):
			var digest := FileAccess.get_sha256(path) if path.ends_with(".glb") or path.ends_with(".bin") \
				else FileAccess.get_file_as_string(path).replace("\r\n", "\n").sha256_text()
			if digest != str(contact["source_hashes"][path]):
				push_error("CAMERA_SET contact fixture source changed; remeasure " + path)
				quit(2)
				return
		for view: Dictionary in camera_set.get("views", []):
			if not is_equal_approx(float(view["player"][1]), float(contact["player_y"])):
				push_error("CAMERA_SET contact fixture has an unmeasured trainer stand")
				quit(2)
				return
		print("CAMERA_SET fixture=%s floor_y=%s idle_sole_offset=%s; fresh paired recapture required" % [
			str(camera_set.get("fixture_version", "")), str(contact["rendered_floor_y"]), str(contact["idle_sole_offset_m"])])
	if DirAccess.make_dir_recursive_absolute(out) != OK:
		push_error("capture_camera_set: cannot create output directory")
		quit(2)
		return
	if not expected_preset.is_empty() and (GRAPHICS.selected() != expected_preset or GRAPHICS.restart_required()):
		push_error("capture_camera_set: actual preset/renderer does not match --preset=" + expected_preset)
		quit(2)
		return
	print("CAMERA_SET graphics: %s / %s" % [GRAPHICS.selected(), RenderingServer.get_current_rendering_method()])
	var views: Array = []
	for view: Dictionary in camera_set.get("views", []):
		if selected_views.is_empty() or str(view.get("id", "")) in selected_views:
			views.append(view)
	if views.is_empty() or (not selected_views.is_empty() and views.size() != selected_views.size()):
		push_error("capture_camera_set: empty set or unknown/duplicate --views selection")
		quit(2)
		return
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	if not is_nan(hall_ground_y):
		for view: Dictionary in views:
			if not str(view.id).begins_with("nave-") and not str(view.id).begins_with("shrine-"):
				push_error("Hall-only diagnostic forbids exterior views")
				world.free()
				quit(2)
				return
		# Keep authored light/environment and the actual trainer rig, but never
		# enter the Meadows world builder or its terrain/placement systems.
		world.set_script(null)
		for child: Node in world.get_children():
			if str(child.name) not in ["Sun", "WorldEnvironment", "WorldLook", "WorldWeather", "Player"]:
				world.remove_child(child)
				child.free()
		var isolated_player := world.get_node_or_null(^"Player")
		if isolated_player != null:
			isolated_player.set_physics_process(false)
	root.add_child(world)
	current_scene = world
	# _ready runs during add_child and can re-enable authored processing.
	# Freeze only afterwards, before any physics-frame settling is allowed.
	if not _hold_capture_trainer(world, views[0]):
		quit(2)
		return
	if not contact.is_empty():
		var contact_model := world.get_node(^"Player/Model") as Node3D
		if str(contact_model.get("_config_key")) != str(contact["appearance"]) \
				or absf(contact_model.position.y) > 0.00001 \
				or not is_equal_approx(float(contact_model.call("height")), 1.8) \
				or str(contact_model.call("clip_for", "idle", "idle")) != "idle":
			push_error("CAMERA_SET contact fixture appearance/model offset differs from measured rig")
			quit(2)
			return
	if not is_nan(hall_ground_y) and not _mount_isolated_hall(world, hall_ground_y, hall_arm):
		quit(2)
		return
	for i in 300:
		await physics_frame
	if not get_nodes_in_group(&"deployed_creature").is_empty():
		push_error("capture_camera_set: companion must be recalled in the isolated capture state")
		quit(2)
		return
	var hud := world.get_node_or_null(^"PlaygroundHUD")
	if hud != null:
		hud.set("visible", false)
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	if look == null or weather == null:
		push_error("capture_camera_set: WorldLook and WorldWeather are required")
		quit(2)
		return
	if look != null:
		look.call("set_clock_frozen", true)
	var player := world.get_node_or_null(^"Player") as Node3D
	if player == null:
		push_error("capture_camera_set: fixed trainer ruler is missing")
		quit(2)
		return
	# A fixed composition must not let gravity/input move the ruler while
	# render frames settle. This diagnostic does not prove traversal.
	player.set_physics_process(false)
	var cam := Camera3D.new()
	root.add_child(cam)
	GRAPHICS.apply_camera(cam)
	var saved := 0
	for raw: Variant in views:
		var view: Dictionary = raw
		if player != null and view.get("player") is Array:
			var p: Array = view["player"]
			player.global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
		var pos: Array = view.get("pos", [0, 0, 0])
		var eye := Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
		cam.fov = float(view.get("fov", 70.0))
		if view.get("look_at") is Array:
			var t: Array = view["look_at"]
			cam.global_transform = Transform3D(Basis(), eye).looking_at(
				Vector3(float(t[0]), float(t[1]), float(t[2])), Vector3.UP)
		else:
			cam.global_transform = Transform3D(Basis.from_euler(Vector3(
				deg_to_rad(float(view.get("pitch", 0.0))), deg_to_rad(float(view.get("yaw", 0.0))), 0.0)), eye)
		cam.current = true
		if player != null and view.get("player") is Array:
			# Trainer faces away from the camera, as the follow camera shows them.
			var away := player.global_position - eye
			player.global_rotation.y = atan2(away.x, away.z)
		var weather_name := str(view.get("weather", "clear"))
		if weather != null:
			weather.call("set_weather", weather_name)
		if look != null:
			look.call("apply_time", str(view.get("time_name", "day")))
		for f in (RAIN_SETTLE_FRAMES if weather_name == "rain" else SETTLE_FRAMES):
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_viewport().get_texture().get_image()
		var file := out.path_join("%s.png" % str(view.get("id", "view")))
		if image != null and not image.is_empty() and image.save_png(file) == OK:
			saved += 1
			print("CAMERA_SET %s saved" % str(view.get("id", "")))
		else:
			push_error("CAMERA_SET image save failed: " + file)
	print("CAMERA_SET done: %d views" % saved)
	quit(0 if saved == views.size() else 2)


func _hold_capture_trainer(world: Node3D, first_view: Dictionary) -> bool:
	var trainer := world.get_node_or_null(^"Player") as CharacterBody3D
	if trainer == null or not first_view.get("player") is Array:
		push_error("CAMERA_SET fixed trainer stand is required")
		return false
	trainer.set_physics_process(false)
	trainer.velocity = Vector3.ZERO
	var stand: Array = first_view["player"]
	trainer.global_position = Vector3(float(stand[0]), float(stand[1]), float(stand[2]))
	var model := trainer.get_node_or_null(^"Model")
	if model == null or not model.has_method("clip_for") or not model.has_method("animation_player"):
		push_error("CAMERA_SET production trainer animation path missing")
		return false
	# With no simulated floor, the normal state selector chooses jump. Use
	# its production idle mapping/play path, then hold one disclosed sample.
	# Do not modify the rig, character scale, clip resource or stand position.
	model.set_physics_process(false)
	var clip := str(model.call("clip_for", "idle", "idle"))
	var animation := model.call("animation_player") as AnimationPlayer
	if animation == null or not animation.has_animation(clip):
		push_error("CAMERA_SET production idle animation missing: " + clip)
		return false
	model.call("play", clip, true)
	animation.advance(0.2)
	animation.pause()
	print("CAMERA_SET trainer held after ready at %s; production idle=%s sample=0.2s" % [trainer.global_position, clip])
	return true


func _mount_isolated_hall(world: Node3D, ground_y: float, arm: String) -> bool:
	_hall_prefabs = load("res://scripts/world/building_prefabs.gd").new()
	var templates := Node3D.new()
	templates.name = "HallTemplates"
	templates.visible = false
	world.add_child(templates)
	_hall_prefabs.call("set_template_holder", templates)
	if not bool(_hall_prefabs.call("load_recipes")):
		return false
	var building := _hall_prefabs.call("instantiate", "crossing_hall_shell") as Node3D
	if building == null:
		return false
	world.add_child(building)
	# Authored village.json placement, with explicitly disclosed ground Y;
	# no synthetic terrain is presented as the real Meadows environment.
	building.position = Vector3(107.0, ground_y - 0.05, 14.0)
	building.rotation.y = deg_to_rad(90.0)
	var hall := load("res://scripts/world/crossing_hall.gd").new() as Node3D
	building.add_child(hall)
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/crossing_hall.json"))
	if not cfg is Dictionary or bool(cfg.get("hall_furnishing", {}).get("enabled", false)) or bool(cfg.get("hall_timber_frame", {}).get("enabled", false)) or bool(cfg.get("hall_waymark", {}).get("enabled", false)):
		push_error("Hall diagnostic requires production furnishing/frame/waymark flags OFF")
		return false
	# This private copy dies with the diagnostic process; never write config.
	# frame compares against furnishing with identical furnishing on both sides.
	var selected: Dictionary = cfg.duplicate(true)
	selected["hall_furnishing"]["enabled"] = arm != "baseline"
	selected["hall_timber_frame"]["enabled"] = arm in ["frame", "frame-no-night-floor", "frame-lantern-lit", "frame-window-lit", "frame-waymark"]
	# Hall III hit the two-flat-round limit for structural changes. This
	# separate diagnostic tests only the Compatibility-era warm emission
	# floor. No production config write, ambient/fog/light or geometry edit.
	if arm == "frame-no-night-floor":
		var ambient: Dictionary = selected.get("interior_ambient", {})
		if not ambient.has("night_floor_energy") or not ambient.has("sealed_night_floor_energy"):
			push_error("Hall night-floor diagnostic requires explicit baseline energies")
			return false
		print("CAMERA_SET night-floor diagnostic: shell=%s sealed=%s -> 0; other settings unchanged" % [
			str(ambient["night_floor_energy"]), str(ambient["sealed_night_floor_energy"])])
		ambient["night_floor_energy"] = 0.0
		ambient["sealed_night_floor_energy"] = 0.0
		selected["interior_ambient"] = ambient
	# Contact-v2 reviewers rejected the zero-floor-only treatment as too dark.
	# Test real material/light response instead of another emissive-floor tune.
	# Only night behavior changes; no world Environment or trainer edits.
	if arm in ["frame-lantern-lit", "frame-window-lit", "frame-waymark"]:
		var ambient: Dictionary = selected.get("interior_ambient", {})
		ambient["night_floor_energy"] = 0.0
		ambient["sealed_night_floor_energy"] = 0.0
		ambient["night_ambient"] = 0.35
		ambient["night_albedo_scale"] = 1.0
		ambient["night_additive_pools_enabled"] = false
		selected["interior_ambient"] = ambient
		var lamps: Dictionary = selected.get("light", {})
		lamps["night_energy_scale"] = 1.5
		lamps["night_range_m"] = 10.0
		# First two authored lights are the central nave and shrine lanterns.
		# Wall lanterns retain their existing unshadowed behavior.
		lamps["night_shadow_light_count"] = 2
		selected["light"] = lamps
		print("CAMERA_SET lantern-lit diagnostic: emission=0 ambient=0.35 albedo=1 lantern_scale=1.5 range=10 central_shadows=2 additive_pools=OFF; night only")
	if arm == "frame-waymark":
		selected["hall_waymark"]["enabled"] = true
		print("CAMERA_SET waymark diagnostic: two rear cloth emblems; lantern baseline lighting/geometry retained")
	if arm == "frame-window-lit":
		selected["interior_ambient"]["day_ambient"] = 0.45
		# Installed lower window glass spans local Y4.217..5.475 on the
		# x=-7 wall. Emit just inside its centre; no new opening or sun edit.
		selected["daylight_windows"] = {
			"enabled": true, "colour": "#fff0d8", "energy": 2.0,
			"range_m": 13.0, "angle_deg": 50.0,
			"sources": [
				{"at": [-6.75, 4.85, -6.0], "target": [0.0, 0.06, -4.0]},
				{"at": [-6.75, 4.85, 6.0], "target": [0.0, 0.06, 8.0]}
			]
		}
		print("CAMERA_SET window-lit diagnostic: day_ambient=0.45 window_spots=2 energy=2 range=13 angle=50 shadows=ON; night matches lantern-lit")
	print("CAMERA_SET Hall arm=%s; production flags OFF; process-local selection only" % arm)
	print("CAMERA_SET ISOLATED HALL DIAGNOSTIC ground_y=%s; no terrain/traversal/world acceptance" % ground_y)
	return bool(hall.call("build", selected))

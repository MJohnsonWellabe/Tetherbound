extends SceneTree

## F13#5 function matrix (ACCEPTANCE §6.1 F13, ART_DIRECTION Tidewake row):
## currents read as currents at the normal camera, docks read as inhabited
## destinations, and Veilfall is readable at distance from First Shore and
## gains detail over the journey. Production Water scene, production
## CameraRig at its normal framing, daytime, clock frozen. Fixtures, disclosed:
## teleport poses and the mid-chapter upstream story flags below.
## Frames are written one JPG each, 1280x720, quality 0.85.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_tidewake_f13_5.gd -- --out=<dir> [--only=veilfall,docks,currents]

const WORLD := preload("res://scenes/world/water_archipelago.tscn")

var world: Node3D
var game: Node
var player: CharacterBody3D
var camera: Node3D
var config: Dictionary
var labels: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _arg(name: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % name):
			return argument.trim_prefix("--%s=" % name)
	return ""


func _on(key: String) -> bool:
	var only := _arg("only")
	return only == "" or key in only.split(",")


func _anchor(anchor_id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.id) == anchor_id:
			var at: Array = anchor.safe_position
			return Vector3(float(at[0]), float(at[1]), float(at[2]))
	return Vector3.INF


func _island_centre(island_id: String) -> Vector2:
	for island: Dictionary in config.islands:
		if str(island.id) == island_id:
			return Vector2(float(island.center_xz_m[0]), float(island.center_xz_m[1]))
	return Vector2.INF


func _pose(at: Vector3, look_at: Vector3) -> void:
	var ground := float(world.call("ground_height_at", at.x, at.z))
	player.global_position = Vector3(at.x, maxf(ground, at.y) + 0.3, at.z)
	player.velocity = Vector3.ZERO
	var toward := Vector2(look_at.x - at.x, look_at.z - at.z)
	camera.set("yaw", atan2(-toward.x, -toward.y))


func _settle(count: int) -> void:
	for _frame in count:
		await physics_frame


func _grab(file: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var out := _arg("out")
	out = out if out.begins_with("/") else ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out)
	image.save_jpg(out.path_join(file), 0.85)
	var line := "%s: %s player=%s" % [file, label, player.global_position]
	labels.append(line)
	print("frame " + line)


func _shot(file: String, at: Vector3, look_at: Vector3, label: String) -> void:
	_pose(at, look_at)
	await _settle(240)
	_pose(at, look_at)
	await _settle(60)
	await _grab(file, label)


## NPCs within `radius` of `at`, for the frame log (who inhabits this dock).
func _people_near(at: Vector3, radius: float) -> Array[String]:
	var out: Array[String] = []
	for node: Node in world.find_children("*", "Node3D", true, false):
		if node == player or not (node.has_meta("water_npc_id") or node.has_meta("water_dock_resident")):
			continue
		var body := node as Node3D
		if body.is_visible_in_tree() and Vector2(body.global_position.x - at.x, body.global_position.z - at.z).length() <= radius:
			out.append(str(body.name))
	return out


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("capture requires a rendering display")
		quit(1)
		return
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	game = root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	game.local.character_id = "f13-5-capture"
	# Mid-chapter: every mandatory dock through Salt Crown is open and its
	# residents are in their post-event places; the Sluice controls, Nerissa
	# and the restoration are not done, so the currents still run adverse.
	for upstream: String in ["water_swim_lesson_complete", "water_dock_reedhaven_repaired",
			"water_dock_brine_steps_trial_won", "water_dock_shellwatch_residents_freed_and_pump_disabled",
			"water_aquaryn_resolved", "water_dock_salt_crown_landing_charted"]:
		game.world.flags.set_flag(upstream)
	game.local.flags.set_flag("water_swim_lesson_briefed")
	game.local.flags.set_flag("water_swim_stone_earned")
	world = WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 1500:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var look := world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
	player = world.get_node(^"Player") as CharacterBody3D
	camera = world.get_node(^"CameraRig") as Node3D

	var peak := Vector3(200.0, 620.0, 4140.0)
	var sightline: Dictionary = config.veilfall_identity.first_shore_sightline
	peak = Vector3(float(sightline.target_position[0]), float(sightline.target_position[1]), float(sightline.target_position[2]))
	if _on("veilfall"):
		var eye: Array = sightline.eye_position
		await _shot("veilfall_1_first_shore.jpg", Vector3(float(eye[0]), float(eye[1]), float(eye[2])), peak,
			"Veilfall from First Shore's authored sightline eye")
		# Mid-journey and last crossing: the departure docks a player leaves
		# from (the Salt Crown landing faces its own island's slope).
		await _shot("veilfall_2_tidal_cradle.jpg", _anchor("tidal_cradle_to_salt_crown_departure"), peak,
			"Veilfall from the Tidal Cradle departure dock (mid-journey)")
		await _shot("veilfall_3_sluice_isle.jpg", _anchor("sluice_isle_to_veilfall_departure"), peak,
			"Veilfall from the Sluice Isle departure dock (last crossing)")

	if _on("docks"):
		# Each mandatory departure dock, seen as a player walks down to it: from
		# 20 m inland (toward the island centre) facing the dock's water end.
		for dock: Dictionary in config.docks:
			if not bool(dock.get("mandatory", false)):
				continue
			var end := _anchor(str(dock.departure_anchor))
			var centre := _island_centre(str(dock.island_id))
			if not end.is_finite() or not centre.is_finite():
				continue
			var inland := (centre - Vector2(end.x, end.z)).normalized() * 20.0
			var stand := Vector3(end.x + inland.x, end.y, end.z + inland.y)
			await _shot("dock_%s.jpg" % str(dock.island_id), stand, end,
				"%s dock (%s) from 20 m inland" % [dock.island_id, dock.id])
			print("  people within 30 m of %s dock: %s" % [dock.island_id, ", ".join(_people_near(end, 30.0))])

	if _on("currents"):
		# Three adverse direct currents at the normal camera, from the dock end
		# looking down the current's own polyline.
		for current_id: String in ["first_shore_to_reedhaven_direct_current",
				"brine_steps_to_shellwatch_direct_current", "salt_crown_to_sluice_isle_direct_current"]:
			for current: Dictionary in config.currents:
				if str(current.id) != current_id:
					continue
				var line: Array = current.polyline
				var first: Array = line[0]
				var mid: Array = line[line.size() / 2]
				var from := Vector3(float(first[0]), 0.0, float(first[2]))
				var toward := Vector3(float(mid[0]), 0.0, float(mid[2]))
				# From the shore behind the current's start, looking obliquely
				# across it (a current seen end-on at the normal camera is a
				# grazing sliver of water).
				var along := (toward - from).normalized()
				var across := Vector3(-along.z, 0.0, along.x)
				var back := -along * 14.0
				var aim := from + along * 30.0 + across * 18.0
				await _shot("current_%s.jpg" % current_id.trim_suffix("_direct_current"), from + back, aim,
					"%s (%.1f m/s adverse) from its start, looking across it" % [current_id, float(current.strength_m_s)])
				await _settle(30)
				await _grab("current_%s_b.jpg" % current_id.trim_suffix("_direct_current"),
					"same view 0.5 s later")

	print("F13#5 CAPTURE OK frames=%d\n%s" % [labels.size(), "\n".join(labels)])
	quit(0)

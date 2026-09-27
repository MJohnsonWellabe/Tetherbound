extends SceneTree

## F13#2 long-range lure witness. For each of the eight authored reward pockets
## (water_world.json `reward_pockets`) the trainer stands ON THE ROUTE the walk
## smoke plans from the island's arrival landing
## (tests/smoke_water_pocket_walk_claim.gd `plan_route`), at the first route
## point that is LURE_M metres or less from the pocket centre (the landing
## itself when the whole walk is shorter). The production CameraRig looks
## toward the pocket: yaw/pitch are steered until the pocket centre sits near
## the left third of the frame at mid height (clear of the trainer at frame
## centre and of the hotbar), as a player looking at the spot. Day, clock frozen,
## terrain and finds streamed by the ordinary services. Pre-gate: Deep Watch's
## cache is shown as a player sees it before Tidecoil is resolved.
## Only the trainer pose and camera yaw/pitch are written. One JPG per pocket.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_tidewake_b_pocket_lures.gd -- --out=<dir>

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const WALK := preload("res://tests/smoke_water_pocket_walk_claim.gd")
const LURE_M := 40.0
const PITCH_DEG := -9.0


func _init() -> void:
	_run.call_deferred()


func _arg(name: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % name):
			return argument.trim_prefix("--%s=" % name)
	return ""


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("lure capture requires a rendering display")
		quit(1)
		return
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	var world := WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var look := world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
	var player := world.get_node(^"Player") as CharacterBody3D
	var camera := world.get_node(^"CameraRig") as Node3D
	var config: Dictionary = world.get("config")
	var out := _arg("out")
	out = out if out.begins_with("/") else ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out)
	var index := 0
	for pocket: Dictionary in config.reward_pockets:
		index += 1
		var at := Vector2(float(pocket.position[0]), float(pocket.position[2]))
		var landing := _landing(config, str(pocket.island_id))
		var plan: Dictionary = WALK.plan_route(world, Vector2(landing.x, landing.z), at)
		var stand := Vector2(landing.x, landing.z)
		var route_m := 0.0
		var previous := stand
		for point: Vector2 in plan.points:
			if previous.distance_to(at) <= LURE_M:
				break
			route_m += previous.distance_to(point)
			previous = point
		stand = previous
		# Stream the neighbourhood in, then steer the production rig's yaw/pitch
		# (the only camera writes) until the pocket centre sits in the left third,
		# clear of the trainer, the way a player looks at a point of interest.
		var centre := Vector3(at.x, float(pocket.position[1]) + 0.5, at.y)
		player.global_position = Vector3(stand.x, float(world.call("ground_height_at", stand.x, stand.y)) + 0.2, stand.y)
		player.velocity = Vector3.ZERO
		var toward := at - stand
		var yaw := atan2(-toward.x, -toward.y)
		player.rotation.y = yaw
		var pitch := deg_to_rad(PITCH_DEG)
		camera.set("yaw", yaw)
		camera.set("pitch", pitch)
		for _frame in 150:
			await physics_frame
		for _iteration in 5:
			var eye0 := root.get_viewport().get_camera_3d()
			if eye0.is_position_behind(centre):
				yaw += PI
			else:
				var screen0 := eye0.unproject_position(centre)
				var size := root.get_visible_rect().size
				var fov := deg_to_rad(eye0.fov)
				yaw -= (screen0.x - size.x * 0.33) / size.y * fov
				pitch = clampf(pitch - (screen0.y - size.y * 0.5) / size.y * fov, deg_to_rad(-40.0), deg_to_rad(20.0))
			camera.set("yaw", yaw)
			camera.set("pitch", pitch)
			for _frame in 30:
				await physics_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.convert(Image.FORMAT_RGB8)
		var eye := root.get_viewport().get_camera_3d()
		var screen := eye.unproject_position(centre)
		var inside := not eye.is_position_behind(centre) and Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(screen)
		var name := "%02d_%s.jpg" % [index, str(pocket.id)]
		image.save_jpg(out.path_join(name), 0.8)
		print("LURE %s island=%s stand=(%.1f,%.1f) dist_to_pocket=%.1fm along_route_from_landing=%.0fm pocket_centre_in_frame=%s screen=(%.0f,%.0f)" % [
			name, str(pocket.island_id), stand.x, stand.y, stand.distance_to(at), route_m, inside, screen.x, screen.y])
	print("LURE CAPTURE OK frames=%d" % index)
	quit(0)


func _landing(config: Dictionary, island_id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.island_id) == island_id and str(anchor.kind) == "arrival":
			var at: Array = anchor.safe_position
			return Vector3(float(at[0]), float(at[1]), float(at[2]))
	return Vector3.INF

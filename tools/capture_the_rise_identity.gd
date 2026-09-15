extends SceneTree

## Production-scene proof for The Rise's corrected tree-and-stone crown.
## Run only through the coordinated real Compatibility-renderer lane:
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_the_rise_identity.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/THE-RISE-IDENTITY-R16

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
# A cold production boot can spend more than seven minutes assembling the full
# four-realm shell even when it is healthy and still making progress. Keep this
# evidence gate fail-closed, but allow the build to finish on slower workstations.
const READY_TIMEOUT_MS := 900_000
const HERO_NODE := ^"Props/the_rise_rock_crown/RiseHeroTree"
const TRAIL_NODE := ^"Props/the_rise_cairn_trail"
const TRAIL_FORK_NODE := ^"Props/the_rise_cairn_trail/RiseTrailForkTorch"
const TRAIL_LAST_NODE := ^"Props/the_rise_cairn_trail/RiseTrailCrownTread"
const OVERLOOK_NODE := ^"Props/the_rise_overlook/RiseOverlookBench"
# Begin on the canonical maintained-road endpoint itself. The former preliminary
# (72, -40) -> (74, -41) hop proved only a steep Terrain3D apron and could stop
# before touching any authored Rise geometry; the remaining route walks every
# installed terrace joint at the original strict tolerance.
const PLAYER_ROUTE := [
	Vector2(74.0, -41.0),
	Vector2(72.6, -46.0), Vector2(70.2, -49.5),
	Vector2(67.8, -53.1), Vector2(65.3, -56.8), Vector2(62.7, -60.2),
	Vector2(66.2, -63.1), Vector2(69.0, -62.0), Vector2(72.0, -61.0),
	Vector2(75.0, -61.0), Vector2(78.0, -61.0), Vector2(81.0, -61.0),
	Vector2(84.0, -60.0), Vector2(86.0, -59.0), Vector2(89.0, -56.0),
	Vector2(90.0, -53.0), Vector2(93.0, -52.0), Vector2(97.0, -54.0),
	# Arrive beside the hero tree, not at the exact centre of its solid trunk.
	# The authored tread still reaches (99.5,-55); an ordinary player uses the
	# adjacent overlook rather than walking through the landmark.
	Vector2(99.0, -54.1),
]

const VIEWS := [
	{"name": "01-road-climb-approach", "role": "maintained road to named crown",
		"stand": Vector2(45.0, -22.0), "target": Vector2(65.3, -56.8),
		"aim_up": 2.0, "back": 1.0, "up": 2.7, "fov": 66.0},
	{"name": "02-road-end-trailhead", "role": "painted road visibly forks onto grounded terrace",
		"stand": Vector2(71.0, -39.2), "target": Vector2(62.7, -60.2),
		"aim_up": 1.5, "back": 2.8, "up": 3.0, "fov": 68.0},
	{"name": "03-full-switchback-climb", "role": "player-scaled lower leg, turn and connected return",
		"stand": Vector2(59.5, -62.5), "target": Vector2(90.0, -55.0),
		"aim_up": 2.2, "back": 4.8, "up": 3.4, "fov": 72.0},
	{"name": "04-crown-overlook", "role": "arrival bench opening onto village country",
		"stand": Vector2(94.0, -57.5), "target": Vector2(20.0, -5.0),
		"aim_up": 1.0, "back": 0.5, "up": 2.9, "fov": 64.0},
]

var _out_dir := ""


func _init() -> void:
	_run()


func _run() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())
	if not FRESH_OUTPUT.create_fresh(_out_dir, "The Rise R16 capture"):
		quit(1)
		return
	var packed := load(SCENE) as PackedScene
	if packed == null:
		push_error("could not load production Meadows scene")
		quit(1)
		return
	var world := packed.instantiate() as Node3D
	# Procedural assembly takes about seven minutes on a cold production boot.
	# Do not let the local Player consume satiety or accumulate unrelated world
	# state while no human could possibly be playing the still-building scene.
	var boot_player := world.get_node_or_null(^"Player") as Node3D
	if boot_player != null:
		boot_player.set_process(false)
		boot_player.set_physics_process(false)
	# Freeze before entering the tree: world._ready() performs the expensive
	# synchronous scatter pass during add_child(), so doing this afterward is late.
	root.add_child(world)
	if not await _wait_for_world(world):
		push_error("production Meadows scene did not finish building")
		quit(1)
		return

	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	var hero := world.get_node_or_null(HERO_NODE) as Node3D
	var trail := world.get_node_or_null(TRAIL_NODE) as Node3D
	var trail_fork := world.get_node_or_null(TRAIL_FORK_NODE) as Node3D
	var trail_last := world.get_node_or_null(TRAIL_LAST_NODE) as Node3D
	var overlook := world.get_node_or_null(OVERLOOK_NODE) as Node3D
	if player == null or look == null or hero == null or trail == null \
			or trail_fork == null or trail_last == null or overlook == null:
		push_error("capture requires production Player, WorldLook, RiseHeroTree, complete Rise switchback and overlook")
		quit(1)
		return
	player.set_process(true)
	player.set_physics_process(true)
	await physics_frame
	var failures: Array[String] = []
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	look.set_process(false)
	look.set_physics_process(false)
	_hide_overlays(world)
	# Before any analytical evidence placement, drive the production Player's
	# real CharacterBody capsule continuously over the installed props/terrain
	# collision. This catches the exact failure that centre-distance config
	# checks cannot: props.gd creates offset, scaled AABB boxes for every stone.
	var traversal_receipt := await _prove_player_route(player as CharacterBody3D, world, rig)
	# Terrain3D streams its live collision window around the active camera. Keep
	# the production rig following the teleported Player throughout traversal;
	# freezing it at world spawn creates an artificial collision boundary at the
	# Rise. Exact evidence framing begins only after the route proof is complete.
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	player.set_process(false)
	player.set_physics_process(false)
	if not bool(traversal_receipt.get("passed", false)):
		failures.append("real-player switchback traversal failed: %s" %
			str(traversal_receipt.get("failure", "unknown failure")))
		_write_manifest({
			"production_scene": SCENE,
			"named_location": "The Rise",
			"fixture_disclosure": "Production traversal was attempted before framing, failed closed, and no visual evidence was captured or claimed.",
			"complete": false,
			"traversal_receipt": traversal_receipt,
			"frames": [],
			"failures": failures,
		})
		quit(1)
		return
	# R5 evidence stabilization. World assembly can still perform one deferred
	# ground-material look reapply after shell_build_complete; R4's very first
	# frame was consequently labelled day while materially darker than its
	# matched night frame. Let deferred assembly drain, then re-pin daylight.
	# No scene content or presentation value is changed by this warm-up.
	for i in 24:
		await process_frame
	_pin_clock(look, "day")
	for i in 8:
		await process_frame

	var camera := Camera3D.new()
	camera.name = "TheRiseEvidenceCamera"
	camera.far = 1200.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var pair_luma: Dictionary = {}
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		for time_name: String in ["day", "night"]:
			_pin_clock(look, time_name)
			var stand: Vector2 = view.stand
			var target: Vector2 = view.target
			var ground := float(world.call("ground_height_at", stand.x, stand.y))
			player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			var toward := (target - stand).normalized()
			player.rotation.y = atan2(toward.x, toward.y)
			var eye_xz := stand - toward * float(view.back)
			camera.fov = float(view.fov)
			camera.global_position = Vector3(eye_xz.x,
				float(world.call("ground_height_at", eye_xz.x, eye_xz.y)) + float(view.up), eye_xz.y)
			camera.look_at(Vector3(target.x,
				float(world.call("ground_height_at", target.x, target.y)) + float(view.aim_up), target.y),
				Vector3.UP)
			for i in 10:
				await process_frame
			_hide_overlays(world)
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			var frame_name := "%s-%s" % [str(view.name), time_name]
			if image == null or image.is_empty():
				failures.append("%s: viewport returned no image" % frame_name)
				continue
			var path := "%s/%s.png" % [_out_dir, frame_name]
			if image.save_png(path) != OK:
				failures.append("%s: save_png failed" % frame_name)
				continue
			var luma := _mean_luma(image)
			pair_luma["%s|%s" % [str(view.name), time_name]] = luma
			records.append({
				"frame": frame_name,
				"time": time_name,
				"composition_role": str(view.role),
				"player_xz": [stand.x, stand.y],
				"target_xz": [target.x, target.y],
				"hero_distance_m": stand.distance_to(Vector2(hero.global_position.x, hero.global_position.z)),
				"fork_distance_m": stand.distance_to(Vector2(trail_fork.global_position.x, trail_fork.global_position.z)),
				"mean_luma_255": luma,
				"image_size": [image.get_width(), image.get_height()],
			})
			print("wrote %s" % path)
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		var day_key := "%s|day" % str(view.name)
		var night_key := "%s|night" % str(view.name)
		if pair_luma.has(day_key) and pair_luma.has(night_key) \
				and float(pair_luma[day_key]) <= float(pair_luma[night_key]) * 1.05:
			failures.append("%s: day frame is not brighter than its matched night frame (%.1f <= %.1f)" % [
				str(view.name), float(pair_luma[day_key]), float(pair_luma[night_key])])

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Rise",
		"fixture_disclosure": "Production Meadows scene with ordinary trainer, live Terrain3D, authoritative scatter, props, encounters and both authored roads. The local Player is frozen only while the seven-minute procedural shell is unavailable, preventing capture-machine boot time from consuming gameplay vitals. Before framing, the untouched production Player CharacterBody then physically walked from the real road through every installed Rise terrace joint to the crown under real collision; its fail-closed receipt is embedded below. Locomotion is frozen again for exact evidence placement; clear day/night clocks are frozen; HUD, capture-time first-run modals and independent SubmersionOverlay are hidden and disabled. No scene content, light, material, pose or progression is injected.",
		"source_contract": {
			"scene": SCENE,
			"props": "res://data/config/bands/band1_lower_meadows/props.json",
			"terrain": "res://data/config/terrain_playground.json",
			"hero_node": str(HERO_NODE),
			"trail_node": str(TRAIL_NODE),
			"road_end_xz": [74.0, -41.0],
			"fork_xz": [62.7, -60.2],
			"switchback_xz": [84.0, -60.0],
			"crown_xz": [99.5, -55.0],
			"overlook_node": str(OVERLOOK_NODE),
			"target_xz": [20.0, -5.0],
		},
		"complete": failures.is_empty() and records.size() == VIEWS.size() * 2,
		"traversal_receipt": traversal_receipt,
		"frames": records,
		"failures": failures,
	}
	if not _write_manifest(manifest):
		failures.append("manifest could not be written")
	quit(0 if failures.is_empty() else 1)


func _prove_player_route(player: CharacterBody3D, world: Node3D, rig: Node) -> Dictionary:
	if player == null:
		return {"passed": false, "failure": "production Player is not a CharacterBody3D"}
	var collision := player.get_node_or_null(^"Collision") as CollisionShape3D
	var capsule: CapsuleShape3D = null
	if collision != null:
		capsule = collision.shape as CapsuleShape3D
	if capsule == null:
		return {"passed": false, "failure": "production Player has no capsule collision"}
	var start: Vector2 = PLAYER_ROUTE[0]
	player.global_position = Vector3(start.x,
		float(world.call("ground_height_at", start.x, start.y)) + 2.2, start.y)
	player.velocity = Vector3.ZERO
	var grounded_frames := 0
	for frame in 120:
		await physics_frame
		if player.is_on_floor():
			grounded_frames += 1
			if grounded_frames >= 4:
				break
	if grounded_frames < 4:
		return {"passed": false, "failure": "player did not settle on production collision at trailhead"}

	var reached := 1
	var physics_steps := 0
	var slide_contacts := 0
	var recent_contacts: Dictionary = {}
	var grounded_steps := 0
	var max_centreline_error := 0.0
	for waypoint_index in range(1, PLAYER_ROUTE.size()):
		var target: Vector2 = PLAYER_ROUTE[waypoint_index]
		var waypoint_reached := false
		var best_distance := INF
		var stalled_steps := 0
		for frame in 300:
			var here := Vector2(player.global_position.x, player.global_position.z)
			var delta := target - here
			if delta.length() <= 0.85:
				_release_route_input()
				waypoint_reached = true
				reached += 1
				break
			var along := delta.normalized()
			_drive_route_input(along, rig)
			await physics_frame
			physics_steps += 1
			slide_contacts += player.get_slide_collision_count()
			for collision_index in player.get_slide_collision_count():
				var slide := player.get_slide_collision(collision_index)
				var collider := slide.get_collider()
				var collider_label := str(collider)
				if collider is Node:
					collider_label = str((collider as Node).get_path())
				recent_contacts[collider_label] = {
					"normal": [slide.get_normal().x, slide.get_normal().y, slide.get_normal().z],
					"position": [slide.get_position().x, slide.get_position().y, slide.get_position().z],
					"waypoint": waypoint_index,
				}
			if player.is_on_floor():
				grounded_steps += 1
			if delta.length() < best_distance - 0.025:
				best_distance = delta.length()
				stalled_steps = 0
			else:
				stalled_steps += 1
			if stalled_steps >= 90:
				var controller_diagnostic := _controller_diagnostic(player, world, rig, target)
				var failed_xyz := [player.global_position.x, player.global_position.y,
					player.global_position.z]
				var failed_route_trials := await _diagnose_failed_route_controls(player, rig, target)
				_release_route_input()
				return {"passed": false, "failure": "stalled before waypoint %d" % waypoint_index,
					"reached_waypoints": reached, "physics_steps": physics_steps,
					"grounded_ratio": float(grounded_steps) / maxf(float(physics_steps), 1.0),
					"slide_contacts": slide_contacts,
					"target_xz": [target.x, target.y], "best_distance_m": best_distance,
					"final_xyz": failed_xyz,
					"recent_contacts": recent_contacts,
					"controller_diagnostic": controller_diagnostic,
					"failed_route_trials": failed_route_trials}
			max_centreline_error = maxf(max_centreline_error,
				_distance_to_route(Vector2(player.global_position.x, player.global_position.z)))
			if max_centreline_error > 2.2:
				_release_route_input()
				return {"passed": false, "failure": "collision displaced player beyond broad tread centreline",
					"reached_waypoints": reached, "physics_steps": physics_steps,
					"max_centreline_error_m": max_centreline_error}
			var terrain_y := float(world.call("ground_height_at",
				player.global_position.x, player.global_position.z))
			if player.global_position.y < terrain_y - 5.0:
				_release_route_input()
				return {"passed": false, "failure": "fell below route before waypoint %d" % waypoint_index,
					"reached_waypoints": reached, "physics_steps": physics_steps}
		if not waypoint_reached:
			_release_route_input()
			return {"passed": false, "failure": "blocked before waypoint %d" % waypoint_index,
				"reached_waypoints": reached, "physics_steps": physics_steps,
				"grounded_ratio": float(grounded_steps) / maxf(float(physics_steps), 1.0),
				"slide_contacts": slide_contacts, "max_centreline_error_m": max_centreline_error,
				"final_xz": [player.global_position.x, player.global_position.z],
				"controller_diagnostic": _controller_diagnostic(player, world, rig, target)}
	var grounded_ratio := float(grounded_steps) / maxf(float(physics_steps), 1.0)
	if reached != PLAYER_ROUTE.size() or grounded_ratio < 0.80:
		return {"passed": false, "failure": "route finished without continuous grounded contact",
			"reached_waypoints": reached, "physics_steps": physics_steps,
			"grounded_ratio": grounded_ratio, "final_xz": [player.global_position.x, player.global_position.z]}
	_release_route_input()
	return {"passed": true, "route_waypoints": PLAYER_ROUTE.size(),
		"reached_waypoints": reached, "physics_steps": physics_steps,
		"grounded_ratio": grounded_ratio, "slide_contacts": slide_contacts,
		"max_centreline_error_m": max_centreline_error,
		"final_xz": [player.global_position.x, player.global_position.z],
		"player_capsule_radius_m": capsule.radius,
		"method": "continuous production Player input and physics controller"}


func _drive_route_input(world_direction: Vector2, rig: Node) -> void:
	var desired := Vector3(world_direction.x, 0.0, world_direction.y)
	if rig != null and rig.has_method("planar_basis"):
		var planar_basis: Basis = rig.call("planar_basis")
		desired = planar_basis.inverse() * desired
	_release_route_input()
	if desired.x < -0.001:
		Input.action_press("move_left", -desired.x)
	if desired.x > 0.001:
		Input.action_press("move_right", desired.x)
	if desired.z < -0.001:
		Input.action_press("move_forward", -desired.z)
	if desired.z > 0.001:
		Input.action_press("move_back", desired.z)


func _release_route_input() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		Input.action_release(action)


func _diagnose_failed_route_controls(player: CharacterBody3D, rig: Node,
		target: Vector2) -> Array[Dictionary]:
	# Diagnostic only: the route has already failed closed. Re-run the same stuck
	# pose under bounded controller variations so one expensive production boot
	# can distinguish a physics setting from a path-angle issue. No trial can
	# convert the failed receipt into a pass or produce visual evidence.
	var original_transform := player.global_transform
	var original_constant := player.floor_constant_speed
	var original_stop := player.floor_stop_on_slope
	var original_snap := player.floor_snap_length
	var trials: Array[Dictionary] = []
	var cases := [
		{"name": "steer_left_25deg", "angle_deg": -25.0},
		{"name": "steer_right_25deg", "angle_deg": 25.0},
		{"name": "floor_constant_speed", "constant": true},
		{"name": "floor_stop_disabled", "stop": false},
		{"name": "floor_snap_disabled", "snap": 0.0},
	]
	for raw: Variant in cases:
		var trial := raw as Dictionary
		_release_route_input()
		player.global_transform = original_transform
		player.velocity = Vector3.ZERO
		player.floor_constant_speed = bool(trial.get("constant", original_constant))
		player.floor_stop_on_slope = bool(trial.get("stop", original_stop))
		player.floor_snap_length = float(trial.get("snap", original_snap))
		player.reset_physics_interpolation()
		for settle_frame in 3:
			await physics_frame
		var start := player.global_position
		var start_distance := Vector2(start.x, start.z).distance_to(target)
		var direction := (target - Vector2(start.x, start.z)).normalized()
		direction = direction.rotated(deg_to_rad(float(trial.get("angle_deg", 0.0))))
		for drive_frame in 36:
			_drive_route_input(direction, rig)
			await physics_frame
		_release_route_input()
		var finish := player.global_position
		trials.append({
			"name": str(trial.get("name", "trial")),
			"start_xyz": str(start),
			"finish_xyz": str(finish),
			"horizontal_displacement_m": Vector2(finish.x - start.x, finish.z - start.z).length(),
			"target_improvement_m": start_distance - Vector2(finish.x, finish.z).distance_to(target),
			"last_motion": str(player.get_last_motion()),
			"velocity": str(player.velocity),
			"on_floor": player.is_on_floor(),
			"on_wall": player.is_on_wall(),
		})
	player.floor_constant_speed = original_constant
	player.floor_stop_on_slope = original_stop
	player.floor_snap_length = original_snap
	return trials


func _controller_diagnostic(player: CharacterBody3D, world: Node3D,
		rig: Node, target: Vector2) -> Dictionary:
	var input_owner: Node = INPUT_OWNER.current(self)
	var dialogue := world.get_node_or_null(^"DialoguePanel")
	var arbiter := world.get_node_or_null(^"InteractionArbiter")
	var camera_basis := Basis.IDENTITY
	if rig != null and rig.has_method("planar_basis"):
		camera_basis = rig.call("planar_basis")
	var collisions: Array[Dictionary] = []
	for collision_index in player.get_slide_collision_count():
		var slide := player.get_slide_collision(collision_index)
		var collider := slide.get_collider()
		collisions.append({
			"body": str((collider as Node).get_path()) if collider is Node else str(collider),
			"normal": str(slide.get_normal()),
			"position": str(slide.get_position()),
		})
	var vitals: RefCounted = player.get("vitals") as RefCounted
	return {
		"target": str(target),
		"body_position": str(player.global_position),
		"collisions": collisions,
		"velocity": str(player.velocity),
		"last_motion": str(player.get_last_motion()),
		"floor_normal": str(player.get_floor_normal()),
		"locomotion_enabled": player.locomotion_enabled(),
		"carried": player.is_carried(),
		"physics_processing": player.is_physics_processing(),
		"can_process": player.can_process(),
		"process_mode": player.process_mode,
		"tree_paused": paused,
		"dialogue_open": bool(dialogue.call("is_open")) if dialogue != null and dialogue.has_method("is_open") else false,
		"input_owner": str(input_owner.get_path()) if input_owner != null else "",
		"input_vector_current": str(Input.get_vector("move_left", "move_right", "move_forward", "move_back")),
		"camera_basis": str(camera_basis),
		"wanted_dir": str(player.get("_wanted_dir")),
		"deflect_dir": str(player.get("_deflect")),
		"deflect_left": player.get("_deflect_left"),
		"walk_speed": player.get("_walk_speed"),
		"move_speed_scale": float(vitals.call("move_speed_scale")) if vitals != null and vitals.has_method("move_speed_scale") else -1.0,
		"time_scale": Engine.time_scale,
		"physics_hz": Engine.physics_ticks_per_second,
		"floor_constant_speed": player.floor_constant_speed,
		"floor_stop_on_slope": player.floor_stop_on_slope,
		"floor_snap_length": player.floor_snap_length,
		"floor_max_angle_deg": rad_to_deg(player.floor_max_angle),
		"is_on_wall": player.is_on_wall(),
		"wall_normal": str(player.get_wall_normal()),
		"arbiter_winner": str(arbiter.get("_winning_provider")) if arbiter != null else "",
	}


func _write_manifest(manifest: Dictionary) -> bool:
	var file := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.close()
	return true


func _distance_to_route(point: Vector2) -> float:
	var nearest := INF
	for index in PLAYER_ROUTE.size() - 1:
		var a: Vector2 = PLAYER_ROUTE[index]
		var b: Vector2 = PLAYER_ROUTE[index + 1]
		var ab := b - a
		var t := clampf((point - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		nearest = minf(nearest, point.distance_to(a + ab * t))
	return nearest


func _mean_luma(source: Image) -> float:
	var image := source.duplicate()
	image.resize(64, 36, Image.INTERPOLATE_BILINEAR)
	var total := 0.0
	for y in image.get_height():
		for x in image.get_width():
			var colour: Color = image.get_pixel(x, y)
			total += 0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b
	return total / float(image.get_width() * image.get_height()) * 255.0


func _pin_clock(look: Node, time_name: String) -> void:
	look.call("apply_time", time_name)
	if look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	look.set_process(false)
	look.set_physics_process(false)


func _hide_overlays(world: Node) -> void:
	# Evidence traversal must not be interrupted by a delayed first-run modal.
	# This changes no progression state; it applies the same presentation-only
	# suppression used by the other production identity captures.
	for overlay_path: NodePath in [
		^"PlaygroundHUD", ^"CombatHUD", ^"DialoguePanel", ^"NamePrompt", ^"StarterPicker"
	]:
		var overlay := world.get_node_or_null(overlay_path) as CanvasLayer
		if overlay != null:
			overlay.visible = false
			overlay.process_mode = Node.PROCESS_MODE_DISABLED
	var submersion := world.get_node_or_null(^"Water/SubmersionOverlay") as CanvasLayer
	if submersion != null:
		submersion.visible = false
	for child: Node in root.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false

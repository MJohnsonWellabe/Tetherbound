extends SceneTree

## Production-scene proof for The Rise's corrected tree-and-stone crown.
## Run only through the coordinated real Compatibility-renderer lane:
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_the_rise_identity.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/THE-RISE-IDENTITY-R5

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const READY_TIMEOUT_MS := 420_000
const HERO_NODE := ^"Props/the_rise_rock_crown/RiseHeroTree"
const TRAIL_NODE := ^"Props/the_rise_cairn_trail"
const TRAIL_FORK_NODE := ^"Props/the_rise_cairn_trail/RiseTrailForkTorch"
const TRAIL_LAST_NODE := ^"Props/the_rise_cairn_trail/RiseTrailCrownTread"

const VIEWS := [
	{"name": "01-road-climb-approach", "role": "maintained road to named crown",
		"stand": Vector2(45.0, -22.0), "target": Vector2(76.0, -43.0),
		"aim_up": 2.6, "back": 1.0, "up": 2.7, "fov": 68.0},
	{"name": "02-road-end-trailhead", "role": "road end to cairn shelf",
		"stand": Vector2(74.0, -41.0), "target": Vector2(66.4, -58.4),
		"aim_up": 1.8, "back": 1.8, "up": 2.8, "fov": 70.0},
	{"name": "03-west-foot-climb", "role": "contour fork and shelf climb",
		"stand": Vector2(64.0, -62.0), "target": Vector2(91.0, -56.4),
		"aim_up": 2.6, "back": 1.2, "up": 3.0, "fov": 66.0},
	{"name": "04-crown-arrival", "role": "close retained crown identity",
		"stand": Vector2(88.0, -43.0), "target": Vector2(99.5, -55.0),
		"aim_up": 7.2, "back": 1.5, "up": 2.8, "fov": 58.0},
]

var _out_dir := ""


func _init() -> void:
	_run()


func _run() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())
	if not FRESH_OUTPUT.create_fresh(_out_dir, "The Rise R4 capture"):
		quit(1)
		return
	var packed := load(SCENE) as PackedScene
	if packed == null:
		push_error("could not load production Meadows scene")
		quit(1)
		return
	var world := packed.instantiate() as Node3D
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
	if player == null or look == null or hero == null or trail == null \
			or trail_fork == null or trail_last == null:
		push_error("capture requires production Player, WorldLook, RiseHeroTree and complete Rise cairn trail")
		quit(1)
		return
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	look.set_process(false)
	look.set_physics_process(false)
	player.set_process(false)
	player.set_physics_process(false)
	_hide_overlays(world)
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
	var failures: Array[String] = []
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
		"fixture_disclosure": "Production Meadows scene with ordinary trainer, live Terrain3D, authoritative scatter, props, encounters and both authored roads. The installed Rise cairn tread and its one production fork torch are untouched scene content. Player locomotion is frozen after exact route-position placement; clear day/night clocks are frozen; HUD and independent SubmersionOverlay are hidden. No scene content, light, material, pose or progression is injected.",
		"source_contract": {
			"scene": SCENE,
			"props": "res://data/config/bands/band1_lower_meadows/props.json",
			"terrain": "res://data/config/terrain_playground.json",
			"hero_node": str(HERO_NODE),
			"trail_node": str(TRAIL_NODE),
			"road_end_xz": [74.0, -41.0],
			"fork_xz": [66.4, -58.4],
			"crown_xz": [99.5, -55.0],
		},
		"complete": failures.is_empty() and records.size() == VIEWS.size() * 2,
		"frames": records,
		"failures": failures,
	}
	var file := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	if file == null:
		failures.append("manifest could not be written")
	else:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	quit(0 if failures.is_empty() else 1)


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
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
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

extends SceneTree

## N14-ROUTED-FOLLOWUPS item 1. The real world, at the stands N09's blind judge
## graded, under four lighting variants -- from ONE world load.
##
## The finding being tested: *"Nothing in the game casts a shadow… the trainer's
## boots meet pale ground with zero darkening and zero contact occlusion. This
## is the loudest defect in the picture."* (N09 `JUDGE2.md` round 2, item 1.)
##
## `tools/_probe_shadow_capability.gd` has already settled the cheap half of the
## question in an isolated scene: this container's software GL **does** draw
## directional shadows, and it draws a strong one (shadowed/lit 0.544) under the
## exact sun `world_look.gd` installs. What it also measured is that under
## `art.json`'s OWN environment block -- `ambient_energy` 1.9 -- the same shadow
## washes out to 0.783 with the lit ground clipping at 1.000. So the question
## this tool answers is the one that isolated scene cannot: on the real terrain,
## at a real stand, how much of the missing shadow is the flat ambient fill and
## how much is the shadow map's own reach.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_n14_shadow_ab.gd [-- --out=res://shots/n14/world --stands=a,b]
##
## A full software-GL world load costs 20-50 minutes in this container, so every
## variant is shot from the SAME load rather than one run each -- the same
## reason `_capture_w22_bridge_signpost.gd` (whose stands, heightfield posing
## and actor placement this borrows) shoots two objects from one load.
##
## Never `--headless` together with a rendering driver.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const DEFAULT_OUT_DIR := "res://shots/n14/world"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 6
const SETTLE_AFTER_MOVE := 20
const ACTOR_CLEARANCE := 0.4
const FOV := 70.0

## Three stands. The first two are N09's own graded checkpoint views, verbatim
## from `_capture_w22_bridge_signpost.gd::BRIDGE_VIEWPOINTS` -- the finding was
## made there, so that is where it has to be answered. The third is the village
## square, a completely different part of the map with different geometry and a
## different ground, because a lighting change affects every frame in the game
## and grading it only where it was found would be grading it where it flatters.
const VIEWPOINTS := [
	{
		"name": "bridge-approach-played",
		"eye": Vector2(9.9, 1313.6), "eye_h": 2.6,
		"target": Vector2(8.0, 1321.5), "target_h": 1.5,
		"horizon": 0.42, "fov": 62.0,
		"actor": Vector2(9.66, 1319.38),
	},
	{
		"name": "bridge-checkpoint-shoulder",
		"eye": Vector2(-2.6, 1310.0), "eye_h": 2.2,
		"target": Vector2(7.4, 1327.0), "target_h": 1.6,
		"horizon": 0.42, "fov": 60.0,
		"actor": Vector2(-1.0, 1313.5),
	},
	{
		# N09's routed §9 stand, `tools/_capture_band1_places.gd`'s own
		# `place5-bridge-approach`, at the coordinates THIS lane moved it to.
		# Kept in step with that file by hand; if the two ever disagree, that
		# file is the one that ships.
		"name": "place5-bridge-approach",
		"eye": Vector2(-6.0, 1319.0), "eye_h": 3.0,
		"target": Vector2(7.0, 1329.0), "target_h": 1.6,
		"horizon": 0.38, "fov": 70.0,
		"actor": Vector2(-4.5, 1316.5),
	},
	{
		"name": "village-square-signpost",
		"eye": Vector2(7.8, -9.2), "eye_h": 1.7,
		"target": Vector2(13.5, -6.9), "target_h": 1.5,
		"fov": 60.0,
		"actor": Vector2(7.0, -9.8),
	},
]

## The four lighting variants, all shot at every stand.
##
## `ambient_mult` scales `art.json`'s `ambient_energy` 1.9; `reach` replaces its
## `shadow_max_distance` 420. Both are applied to the LIVE nodes with WorldLook's
## own `_process` frozen first, so the passive clock's next blend tick cannot
## quietly put the shipped values back between the poke and the shutter.
const VARIANTS := [
	{"name": "A-shipped", "ambient_mult": 1.0, "reach": 420.0},
	{"name": "B-ambient-035", "ambient_mult": 0.35, "reach": 420.0},
	{"name": "C-reach-120", "ambient_mult": 1.0, "reach": 120.0},
	{"name": "D-both", "ambient_mult": 0.35, "reach": 120.0},
]

## Round 2. Round 1 settled WHICH knob: at the shipped `shadow_max_distance`
## 420 the checkpoint has no ground shadow at all, and at 120 every prop,
## barricade and figure casts one -- same frame, same load, nothing else
## changed. What round 1 did NOT settle is whether 420 has to go.
##
## `shadow_bias` is a depth offset scaled by the cascade's own depth RANGE, so
## the same 0.06 that is a few centimetres at 120 m reach is metres at 420 --
## which is exactly `_apply_sun`'s own warning, "lower it if small props stop
## casting", read from the other end. If the bias is what kills the near
## shadow, the reach can stay where T1-HALL-4 put it (its own reason was the
## fortress crenellations at long range) and only the bias moves. These
## variants ask that question directly.
const VARIANTS_BIAS := [
	{"name": "A-shipped", "ambient_mult": 1.0, "reach": 420.0},
	{"name": "E-420-bias-001", "ambient_mult": 1.0, "reach": 420.0, "bias": 0.01},
	{"name": "F-420-bias-0002", "ambient_mult": 1.0, "reach": 420.0, "bias": 0.002},
	{"name": "G-420-bias-0002-nbias-08", "ambient_mult": 1.0, "reach": 420.0, "bias": 0.002, "normal_bias": 0.8},
	{"name": "H-reach-220", "ambient_mult": 1.0, "reach": 220.0},
	{"name": "I-reach-120", "ambient_mult": 1.0, "reach": 120.0},
]

## Round 3, the evidence sheet. Rounds 1 and 2 settled it: the reach is the
## knob (bias at 420 changes nothing, 220 and 120 both restore the shadow), and
## 220 is both `_apply_sun`'s own code default and the value the project shipped
## before T1-HALL-4 raised it to 420 for the fortress crenellations. This pair
## is the before/after a blind judge is given.
const VARIANTS_SHIP := [
	{"name": "A-shipped-420", "ambient_mult": 1.0, "reach": 420.0},
	{"name": "B-reach-220", "ambient_mult": 1.0, "reach": 220.0},
]

static var _out_dir: String = DEFAULT_OUT_DIR
static var _only: PackedStringArray = []
static var _variants: Array = VARIANTS


func _init() -> void:
	_run()


func _viewpoints() -> Array:
	if _only.is_empty():
		return VIEWPOINTS as Array
	var picked: Array = []
	for entry: Variant in VIEWPOINTS:
		if str((entry as Dictionary)["name"]) in _only:
			picked.append(entry)
	return picked


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stands="):
			_only = arg.substr("--stands=".length()).split(",", false)
		elif arg.begins_with("--out="):
			_out_dir = arg.substr("--out=".length())
		elif arg == "--bias-round":
			_variants = VARIANTS_BIAS
		elif arg == "--ship-round":
			_variants = VARIANTS_SHIP
		elif arg == "--as-is":
			# One pass at whatever the tree currently says: an "after" sheet for
			# the changes that are not lighting (the lantern's z, the gate
			# threshold's material, the re-sited place5 stand).
			_variants = [{"name": "as-shipped", "ambient_mult": 1.0, "reach": 220.0}]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)

	var failures: Array[String] = []

	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)

	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	_hide_canvas_layers(world)

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain == null and world.get("_terrain") != null:
		terrain = world.get("_terrain") as Node
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	else:
		failures.append("no Terrain node with set_camera")

	# Pin the look to `day` ONCE, then take WorldLook out of `_process` for the
	# rest of the run: after this the Sun and Environment nodes are ours to set.
	if look != null:
		look.call("apply_time", "day")
		look.set_process(false)
		look.set_physics_process(false)

	var sun := world.get_node_or_null(^"Sun") as DirectionalLight3D
	var env_holder := world.get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	var env: Environment = env_holder.environment if env_holder != null else null
	if sun == null:
		failures.append("no Sun node -- nothing to vary")
	if env == null:
		failures.append("no WorldEnvironment.environment -- nothing to vary")
	if sun == null or env == null:
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return

	var shipped_ambient := env.ambient_light_energy
	var shipped_bias := sun.shadow_bias
	var shipped_normal_bias := sun.shadow_normal_bias
	print("shipped: sun.shadow_enabled=%s reach=%.1f normal_bias=%.2f | env.ambient_energy=%.3f" % [
		"true" if sun.shadow_enabled else "false",
		sun.directional_shadow_max_distance, sun.shadow_normal_bias, shipped_ambient])

	var written := 0
	for entry: Variant in _viewpoints():
		var view: Dictionary = entry
		var stand: String = str(view["name"])
		camera.fov = float(view.get("fov", FOV))
		_pose(camera, field, view)
		_place_actor(player, field, camera, view)
		for i in SETTLE_AFTER_MOVE:
			await physics_frame

		for variant_entry: Variant in _variants:
			var variant: Dictionary = variant_entry
			env.ambient_light_energy = shipped_ambient * float(variant["ambient_mult"])
			sun.directional_shadow_max_distance = float(variant["reach"])
			sun.shadow_bias = float(variant.get("bias", shipped_bias))
			sun.shadow_normal_bias = float(variant.get("normal_bias", shipped_normal_bias))
			for i in POSE_FRAMES:
				await process_frame
			await RenderingServer.frame_post_draw

			var image := root.get_texture().get_image()
			if image == null:
				failures.append("%s/%s: viewport returned no image" % [stand, variant["name"]])
				continue
			var path := "%s/%s__%s.png" % [_out_dir, stand, variant["name"]]
			var error := image.save_png(path)
			if error != OK:
				failures.append("%s/%s: save_png failed (%d)" % [stand, variant["name"], error])
				continue
			written += 1
			print("  %-28s %-16s spread %.3f p05 %.4f -> %s" % [
				stand, variant["name"], _flatness(image), _dark_tail(image), path])

	env.ambient_light_energy = shipped_ambient
	sun.shadow_bias = shipped_bias
	sun.shadow_normal_bias = shipped_normal_bias
	print("")
	print("%d frames -> %s" % [written, _out_dir])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## The number this whole capture exists to move: the 5th-percentile Rec.709 luma
## over the frame's LOWER HALF -- the ground, where a cast shadow lands, with the
## sky excluded so a brighter or darker sky cannot move it. A frame with real
## contact shadows has a dark tail down there; the judge's "zero darkening"
## reading is the claim that this number is not far below the ground's median.
func _dark_tail(image: Image) -> float:
	var step := maxi(1, image.get_width() / 160)
	var samples: Array[float] = []
	for y in range(image.get_height() / 2, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			var c := image.get_pixel(x, y)
			samples.append(0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b)
	if samples.is_empty():
		return 0.0
	samples.sort()
	return samples[int(samples.size() * 0.05)]


func _pose(camera: Camera3D, field: RefCounted, view: Dictionary) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
	var target := Vector3(target_xz.x, field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	if view.has("horizon"):
		camera.rotation = Vector3(
			_pitch_for_horizon(float(view["horizon"]), camera.fov), camera.rotation.y, 0.0)


func _place_actor(player: Node3D, field: RefCounted, camera: Camera3D, view: Dictionary) -> void:
	if player == null or not view.has("actor"):
		return
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	var xz: Vector2 = view["actor"]
	player.global_position = Vector3(xz.x, field.height_at(xz.x, xz.y) + ACTOR_CLEARANCE, xz.y)
	var away := player.global_position - camera.global_position
	player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)


func _pitch_for_horizon(fraction: float, fov: float) -> float:
	var half := tan(deg_to_rad(fov) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


func _flatness(image: Image) -> float:
	var step := maxi(1, image.get_width() / 64)
	var lowest := Vector3(INF, INF, INF)
	var highest := Vector3(-INF, -INF, -INF)
	for y in range(0, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			var c := image.get_pixel(x, y)
			lowest = Vector3(minf(lowest.x, c.r), minf(lowest.y, c.g), minf(lowest.z, c.b))
			highest = Vector3(maxf(highest.x, c.r), maxf(highest.y, c.g), maxf(highest.z, c.b))
	return (highest - lowest).length()

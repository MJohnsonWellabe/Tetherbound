extends SceneTree

## BAND2-63-WARRENS blind-pass capture: the re-sited Burrow Warrens.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_warrens_63.gd
##
## Two things in this pass are visually load-bearing and neither has been
## looked at:
##
##   * The cave now stands in a rock knoll of its own rather than in a
##     hillside, because there is no hillside here (burrow_warrens.json's
##     `_comment_resiting`). Whether that reads as an outcrop with a hole in it
##     or as a grey box dropped in a field is a judgement about frames, not
##     about the probe numbers that put it there.
##   * The Team Tether dressing inside -- mouth, hall and den -- which is the
##     only evidence in the cave that anyone has been working the seam.
##
## Same shape as capture_band2_63.gd, and the same caveat: Compatibility
## renderer under software GL, so composition and silhouette are trustworthy
## and fine lighting judgements are not. Interior eye heights come from the
## CAVE's own `ground_height_at`, not the heightfield -- the floor is metres
## off the terrain and a heightfield-relative camera would sit in the rock.
##
## These frames are for an INDEPENDENT critic. conventions.md forbids grading
## your own; this file only produces them.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/warrens_63"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

## `local` views are in the cave's own frame and are transformed by the
## warrens node; the rest are world metres off the heightfield.
const VIEWPOINTS := [
	# 01 and 02 are not authored here: exterior camera positions were picked by
	# hand twice and both times the camera ended up inside a hillside or
	# looking at one. `_clear_exterior_views()` measures instead -- it rings
	# the cave, casts at it, and keeps the stands that can actually SEE it.
	{
		"name": "03-mouth", "local": true, "ground": true,
		"eye": Vector2(0.0, -12.0), "eye_h": 1.7,
		"target": Vector2(0.0, 4.0), "target_h": 1.2,
	},
	{
		"name": "04-hall-dressing", "local": true,
		"eye": Vector2(-1.0, 17.0), "eye_h": 1.7,
		"target": Vector2(5.4, 18.6), "target_h": 0.6,
	},
	{
		"name": "05-hall-from-the-doorway", "local": true,
		"eye": Vector2(0.0, 13.0), "eye_h": 1.7,
		"target": Vector2(4.0, 24.0), "target_h": 1.0,
	},
	{
		# Aimed at the guardian's own body, not at a hand-guessed point near it:
		# round 2 of the blind pass caught the creature half cropped off the
		# right edge, which is the one thing this frame exists to show.
		"name": "06-den-and-guardian", "local": true, "aim_guardian": true,
		"eye": Vector2(0.0, 33.0), "eye_h": 1.7,
		"target": Vector2(1.0, 43.0), "target_h": 1.2,
	},
	{
		"name": "07-den-dressing", "local": true,
		"eye": Vector2(-1.0, 38.0), "eye_h": 1.7,
		"target": Vector2(-5.6, 41.5), "target_h": 0.6,
	},
]


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if warrens == null:
		push_error("no BurrowWarrens in the scene")
		quit(1)
		return

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	# The time has to be re-applied per frame and the two things that would
	# undo it turned off. `apply_time("day")` once before the loop is what
	# capture_band2_63.gd does and it is not enough: `day_cycle` keeps
	# advancing through `WorldLook::_process` and `world_weather` layers its
	# own sun and fog over the top, so the first capture round of this pass
	# came back with one frame at dusk and one at sunset, which is not a
	# comparison a critic can make.
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		# Clear the weather BEFORE the time: `apply_time()` re-layers whatever
		# `_weather` holds every time it runs (world_look.gd::_layer_weather),
		# so freezing world_weather's process leaves whatever preset was rolled
		# at boot baked into every frame -- which is what put five of the first
		# seven frames under a red flood a blind critic then read, fairly, as a
		# deliberate colour grade.
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")

	# The player is parked far below so a stray trainer model never stands in
	# a frame -- capture_band2_63.gd's own trick.
	# Parked far away ON THE GROUND, hidden, with its physics off -- NOT dropped
	# below the world, which is what capture_band2_63.gd does and what wrecked
	# this pass's first blind round. A player under the map falls into the kill
	# volume, takes damage, and the hurt vignette tints EVERY frame after it
	# red. The critic read five red frames as a deliberate colour grade and
	# spent three of its findings on it. The world was never red.
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var park := Vector2(-373.0, 2476.0) + Vector2(600.0, 600.0)
		var park_y := float(world.call("ground_height_at", park.x, park.y))
		player.global_position = Vector3(park.x, park_y + 0.2, park.y)
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var views: Array = _clear_exterior_views(world, warrens)
	views.append_array(VIEWPOINTS)

	# A stand-in for the torch. The warrens is authored DARK on purpose -- its
	# lights are low-energy pools and OF24's carried torch is the thing that
	# makes it readable (burrow_warrens.json's `_comment_lights`). Capturing the
	# interior with no torch photographs a cave no player ever sees, and the
	# first blind round judged four interior frames it could barely read. This
	# rides with the camera on interior shots only.
	var torch := OmniLight3D.new()
	torch.light_energy = 2.6
	torch.omni_range = 12.0
	torch.light_color = Color("#ffd8a0")
	torch.visible = false
	world.add_child(torch)

	var written: Array[String] = []
	var failures: Array[String] = []
	for entry: Variant in views:
		var view: Dictionary = entry
		var name_value := str(view["name"])
		var eye := _point(world, warrens, view, "eye")
		var target := _point(world, warrens, view, "target")
		if bool(view.get("aim_guardian", false)):
			var guardian: Node3D = warrens.call("guardian") as Node3D
			if guardian != null and is_instance_valid(guardian):
				target = guardian.global_position + Vector3.UP * 0.6
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		var interior := bool(view.get("local", false)) and not bool(view.get("ground", false))
		torch.visible = interior
		torch.global_position = eye + Vector3(0.0, 0.35, 0.0)
		for i in 20:
			await physics_frame
		# AFTER the settle frames, not before them: something in the scene's
		# own day-cycle group re-applies the hour while those frames run, and
		# the first rounds of this pass came back with half the set at sunset.
		if look != null:
			if look.has_method("set_weather"):
				look.call("set_weather", {})
			look.call("apply_time", "day")
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw
		if look != null:
			var env: Environment = null
			for child in world.get_children():
				if child is WorldEnvironment:
					env = (child as WorldEnvironment).environment
			print("      [diag] time=%s processing=%s fog=%s bg=%s" % [
				str(look.get("_time")), str(look.is_processing()),
				str(env.fog_light_color) if env != null else "?",
				str(env.background_mode) if env != null else "?"])

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name_value)
			continue
		var path := "%s/%s.png" % [OUT_DIR, name_value]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name_value, error])
			continue
		written.append(path)
		print("  %-26s -> %s" % [name_value, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. These are for an independent critic, not for this file's author.")
	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## Two exterior stands that can see the cave, found rather than guessed.
##
## A ring of candidates at two radii; from each, a ray at the mound's own
## shoulder. If the first thing it hits belongs to the warrens, that stand sees
## the cave and is worth a frame; if it hits `Terrain` first, a hillside is in
## the way and the frame would be a picture of grass. Ranked by how much of the
## ray got through, and the two kept are forced apart so they are not the same
## photograph twice.
func _clear_exterior_views(world: Node, warrens: Node3D) -> Array:
	var space := (world as Node3D).get_world_3d().direct_space_state
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var aim := mouth + Vector3.UP * 2.5
	var found: Array = []
	for radius in [26.0, 40.0]:
		for step in 24:
			var angle := TAU * float(step) / 24.0
			var at := Vector2(mouth.x + sin(angle) * radius, mouth.z + cos(angle) * radius)
			var ground := float(world.call("ground_height_at", at.x, at.y))
			if is_nan(ground):
				continue
			var eye := Vector3(at.x, ground + 1.7, at.y)
			var query := PhysicsRayQueryParameters3D.create(eye, aim)
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				continue
			var collider: Node = hit["collider"] as Node
			if collider == null or not warrens.is_ancestor_of(collider):
				continue
			var reach: float = eye.distance_to(hit["position"] as Vector3)
			# A stand whose ray dies in the first few metres is a camera with
			# its nose against the rock -- round 2 of the blind pass found two
			# such frames on the sheet and called them what they are: frames
			# that judge nothing.
			if reach < 12.0:
				continue
			found.append({"eye": eye, "angle": angle, "reach": reach})
	found.sort_custom(func(a, b): return float(a["reach"]) > float(b["reach"]))
	var picked: Array = []
	for candidate: Dictionary in found:
		var far_enough := true
		for already: Dictionary in picked:
			if absf(wrapf(float(candidate["angle"]) - float(already["angle"]), -PI, PI)) < 1.2:
				far_enough = false
		if far_enough:
			picked.append(candidate)
		if picked.size() == 2:
			break
	var out: Array = []
	for index in picked.size():
		out.append({
			"name": "%02d-knoll-from-outside" % (index + 1),
			"world_eye": (picked[index]["eye"] as Vector3),
			"world_target": aim,
		})
	if out.is_empty():
		print("  (no exterior stand can see the cave; every ring candidate was blocked)")
	return out


## One camera point. `local: true` views are authored in the cave's own frame,
## so their ground is the CAVE floor and their position goes through the
## warrens node's transform.
func _point(world: Node, warrens: Node3D, view: Dictionary, key: String) -> Vector3:
	if view.has("world_%s" % key):
		return view["world_%s" % key] as Vector3
	var flat: Vector2 = view[key]
	var height: float = float(view["%s_h" % key])
	if bool(view.get("local", false)):
		var at: Vector3 = warrens.to_global(Vector3(flat.x, 0.0, flat.y))
		# `ground: true` means this point is OUTSIDE the cave -- stand it on the
		# meadow, not on the cave floor the warrens would answer with.
		# The WORLD's ground, not `playground_heightfield.gd`'s: the playground
		# root is the authority a player actually stands on, and asking the
		# helper directly put the first round's exterior cameras metres under
		# the surface, inside the cave's own rock. `ground: true` means this
		# point is outside the cave, so it must not take the warrens' answer
		# (which is the cave floor anywhere inside the footprint).
		var floor_y: float = float(world.call("ground_height_at", at.x, at.z)) \
			if bool(view.get("ground", false)) \
			else float(warrens.call("ground_height_at", at.x, at.z))
		return Vector3(at.x, floor_y + height, at.z)
	return Vector3(flat.x, float(world.call("ground_height_at", flat.x, flat.y)) + height, flat.y)

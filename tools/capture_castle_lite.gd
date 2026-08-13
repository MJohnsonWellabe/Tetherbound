extends SceneTree

## Lightweight OF4-rebuild verification capture: terrain + landmark ONLY,
## skipping the full playground's vegetation scatter (25946 instances),
## water, village, NPCs and props -- none of which affect the castle's own
## rendering. The full `tools/capture_wayfinding.gd` loads the entire
## `meadows_playground.tscn` scene and its ~30-100+ minute build cost under
## this container's software (xvfb + opengl3/llvmpipe) renderer, documented
## in `ralph/DONE.md` precedent, exceeds any single foreground command's
## timeout here. This reuses the SAME terrain bake, the SAME ground
## materials, the SAME lighting/environment/fog settings as the real scene
## (copied from meadows_playground.tscn's own WorldEnvironment/Sun nodes),
## and the SAME landmark.gd/building_prefabs.gd code path -- it just never
## instantiates the vegetation/settlement/NPC layers, since `playground_world.
## gd`'s own `_ready()` cannot be run partially: it is invoked automatically
## the instant its node enters the SceneTree. `playground_world.gd`'s
## terrain-building methods are called directly on a detached instance of
## that script (never added to the tree, so its own `_ready()` never fires)
## and only the resulting Terrain3D node is reparented into a real,
## in-tree stage -- the same public/duck-typed methods
## (`_build_terrain`, `_apply_ground_materials`, `ground_height_at`) the
## real scene already relies on, just driven by hand instead of by `_ready`.
##
## `OF4-rebuild`'s blind-critique pass stopped after round 4 with an open
## remainder (the gate opening's jagged seam, see `ralph/DONE.md`) rather
## than a clean convergence -- keep this around for whoever resumes that
## pass; delete it once the remainder is actually closed and nobody needs
## this verification path again. Not a permanent addition to tools/.

const WORLD_SCRIPT := preload("res://scripts/world/playground_world.gd")
const LANDMARK := preload("res://scripts/world/landmark.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const OUT_DIR := "res://shots/wayfinding"
const DATA_DIR := "res://data/terrain/playground"

const SETTLE_FRAMES := 150
const POSE_FRAMES := 4
const FOV := 70.0

## Same coordinates capture_wayfinding.gd uses -- the two viewpoints the
## castle is actually seen from now that OF13 moved it out of sight of the
## village square and Rise path.
const TOWER_AT := Vector2(229.8, -144.4)

const VIEWPOINTS := [
	{
		"name": "silhouette-close",
		"eye": Vector2(229.8, -214.4), "eye_h": 7.0,
		"target": TOWER_AT, "target_h": 14.0,
	},
	{
		"name": "silhouette-approach",
		"eye": Vector2(229.8, -170.4), "eye_h": 1.7,
		"target": TOWER_AT, "target_h": 11.0,
	},
]


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var stage := Node3D.new()
	root.add_child(stage)

	# Lighting/environment/fog: a bare WorldEnvironment + Sun (placeholder
	# starting values, overwritten below), plus a REAL `world_look.gd`
	# instance driving them exactly like the scene does. A first attempt
	# hand-copied the .tscn's raw Environment/Sun values and got a near-black
	# unlit-looking near field in every frame -- `world_look.gd`'s own header
	# explains why a hand-copy misses the point: the .tscn's authored values
	# are only ever a starting pose, and `apply_time("day")` is what actually
	# sets the ambient fill colour the Compatibility renderer depends on
	# (`env.ambient_light_color`/`ambient_light_sky_contribution`, "sky
	# radiance does not reach the terrain under the Compatibility renderer").
	# Skipping that call is what produced the black foreground, not a real
	# rendering defect in the castle.
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = ProceduralSkyMaterial.new()
	world_env.environment = environment
	world_env.name = "WorldEnvironment"
	stage.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	stage.add_child(sun)

	var look: Node = WORLD_LOOK.new()
	look.name = "WorldLook"
	look.set("sun_path", NodePath("../Sun"))
	look.set("environment_path", NodePath("../WorldEnvironment"))
	stage.add_child(look)
	look.call("apply_time", "day")

	# The camera FIRST, current from the start -- Terrain3D's own
	# `_grab_camera()` runs the instant it enters the tree and permanently
	# disables its `_physics_process` if it cannot find one right then
	# (confirmed by a first attempt at this script: terrain entered the tree
	# with no camera yet built, Terrain3D logged exactly that and gave up,
	# and the capture loop then hung waiting on a frame that never properly
	# rendered). `playground_world.gd::_ready()` avoids this the same way --
	# camera and `_terrain.set_camera()` both happen before anything else
	# waits on a real frame.
	# Positioned near the site FROM THE START, not at the origin -- Terrain3D
	# streams regions around wherever `set_camera`'s camera actually is, and
	# the site (~230,-144) is a full region away from the origin. A first
	# attempt left the camera at (0,0,0) through the whole settle phase, then
	# jumped it to the site only for the two brief per-viewpoint waits before
	# capture: the near-camera terrain came back solid black in both frames,
	# undercooked/unstreamed geometry, not a real rendering defect.
	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	camera.global_position = Vector3(TOWER_AT.x, 50.0, TOWER_AT.y)
	stage.add_child(camera)
	camera.make_current()

	# playground_world.gd's script, instantiated but NEVER added to the tree --
	# its own `_ready()` (the full vegetation/water/settlement build) only
	# fires on tree entry, so a detached instance never runs it. Only its
	# terrain-building methods are called directly.
	var world = WORLD_SCRIPT.new()
	print("[lite] calling _build_terrain")
	var terrain: Node3D = world.call("_build_terrain")
	if terrain == null:
		push_error("terrain build failed -- is the bake present at %s?" % DATA_DIR)
		quit(1)
		return
	print("[lite] terrain built, moving from the detached world instance to the real stage")
	# `_build_terrain()` already did `add_child(terrain)` on `world` (which is
	# itself never added to any tree). Plain remove/add rather than
	# `reparent()`: `reparent()` tries to preserve global transform via
	# `get_global_transform()`, which errors (harmlessly, but noisily) on a
	# node whose old parent was never in a tree in the first place.
	world.remove_child(terrain)
	stage.add_child(terrain)
	if terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	for i in 5:
		await physics_frame
	print("[lite] setting data_directory")
	terrain.set("data_directory", DATA_DIR)
	for i in 5:
		await physics_frame
	terrain.set("collision_mode", 3)
	world.set("_terrain", terrain)
	print("[lite] applying ground materials")
	world.call("_apply_ground_materials")

	print("[lite] building landmark")
	var landmark: Node3D = LANDMARK.new()
	landmark.name = "StrongholdSilhouette"
	stage.add_child(landmark)
	landmark.call("build", world)
	print("[lite] landmark built, settling")

	for i in SETTLE_FRAMES:
		await physics_frame
	print("[lite] settled, capturing viewpoints")

	var field: RefCounted = HEIGHTFIELD.new()
	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		var eye_xz: Vector2 = view["eye"]
		var target_xz: Vector2 = view["target"]
		var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
		var target := Vector3(target_xz.x, field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		print("[lite] %s: posed, waiting physics" % name)

		for i in 30:
			await physics_frame
		print("[lite] %s: physics settled, waiting process frames" % name)
		for i in POSE_FRAMES:
			await process_frame
		print("[lite] %s: process settled, waiting frame_post_draw" % name)
		await RenderingServer.frame_post_draw
		print("[lite] %s: frame drawn, reading texture" % name)

		var image := root.get_texture().get_image()
		print("[lite] %s: image read (null=%s)" % [name, image == null])
		if image == null:
			failures.append("%s: viewport returned no image" % name)
			continue
		var path := "%s/%s.png" % [OUT_DIR, name]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name, error])
			continue
		written.append(path)
		print("  %-26s -> %s" % [name, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)

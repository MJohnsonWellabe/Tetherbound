extends SceneTree

## Close-up frames of a rocky rise's slope material, for EV4-hillside-seam's
## local blind-judge pass.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_hillside.gd
##
## Neither tools/survey.gd's fixed five viewpoints nor tools/capture_paths.gd
## frame a rise's flank close enough or wide enough to judge whether the
## grass/soil/rock slope bands read as one coherent transition rather than a
## noisy patchwork — same reasoning as capture_paths.gd's own header, applied
## to `rises.peaks[0]` in data/config/terrain_playground.json (centre
## [140,-90], radius 78 — the one the blind critic's "blotchy all over the
## dome" verdict was about).
##
## Bearing is due EAST from the peak's own centre, not the village-ward
## bearing an earlier pass used — that one ran straight through both
## landmark.gd's stronghold silhouette (RISE_CENTRE + OFFSET, a flat-shaded
## cutout a few metres from the summit) and paths.routes' "The Rise", which
## ends inside this peak's own radius. Both filled the frame with the wrong
## content instead of ground material. debug_slope_probe.gd confirms the
## east bearing clears both and still crosses soil_at (30 deg, ~42m out) and
## rock_at (44 deg, ~57m out) well inside the 78m radius.
##
## Viewpoints sit along that bearing at increasing distance: a wide overview
## that shows the whole dome's silhouette, then progressively closer flank
## shots through the soil band and into the rock band, ending near the outer
## edge where "a hard, unblended seam where grey rock cuts in at the hill's
## base" was reported.
##
## Same honest limits as tools/survey.gd: Compatibility renderer, software
## rendering, placeholder geometry.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/hillside"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

const VIEWPOINTS := [
	{
		# Distant enough that the whole rise reads as one silhouette against
		# the sky — this is the "all over the dome" framing the critic used.
		# Eye sits east of the peak looking back west, so the visible near
		# flank is the same east-facing slope every other viewpoint here
		# samples. MUST stay inside the baked world (+-256m, world_size 512
		# in terrain_playground.json): an eye past the edge parks the player
		# out of bounds too (this file parks at VIEWPOINTS[0]'s own XZ,
		# survey.gd's own fix for the same problem) and broke Terrain3D's
		# streaming for the WHOLE run, not just this one frame — the exact
		# "camera sat below the terrain, world-noise backdrop, floating
		# vegetation" failure survey.gd's header already documents. x=235
		# leaves 21m of margin.
		"name": "dome-overview",
		"eye": Vector2(235.0, -90.0), "eye_h": 6.0,
		"target": Vector2(140.0, -90.0), "target_h": 20.0,
	},
	{
		# Standing in the grass, just below where soil starts (d=42), looking
		# up the slope through the soil band — the angle a player walking
		# toward the rise actually sees it from.
		"name": "flank-lower",
		"eye": Vector2(178.0, -90.0), "eye_h": 1.7,
		"target": Vector2(198.0, -90.0), "target_h": 20.0,
	},
	{
		# Standing mid-soil-band (d=50), looking further up into where rock
		# starts (d=58+) — the soil/rock boundary itself.
		"name": "flank-mid",
		"eye": Vector2(190.0, -90.0), "eye_h": 1.7,
		"target": Vector2(206.0, -90.0), "target_h": 14.0,
	},
	{
		# Standing in the rock band (d=68), looking back down through soil
		# toward grass — the full three-tier transition in one frame, and
		# where "a hard, unblended seam where grey rock cuts in" should show
		# up if it is still there.
		"name": "base-seam",
		"eye": Vector2(208.0, -90.0), "eye_h": 1.6,
		"target": Vector2(178.0, -90.0), "target_h": 2.0,
	},
	{
		# Standing right on the confirmed soil coordinate (d=50, matching
		# debug_control_probe.gd's own sample), looking straight down — the
		# closest read on the material itself, independent of framing.
		"name": "soil-band-direct",
		"eye": Vector2(190.0, -90.0), "eye_h": 1.6,
		"target": Vector2(194.0, -90.0), "target_h": 0.5,
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
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	if look != null:
		look.call("apply_time", "day")

	if player != null:
		var park: Vector2 = VIEWPOINTS[0]["eye"]
		player.global_position = Vector3(park.x, field.height_at(park.x, park.y) - 500.0, park.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

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

		for i in 20:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name)
			continue

		var path := "%s/%s.png" % [OUT_DIR, name]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name, error])
			continue

		written.append(path)
		print("  %-22s -> %s" % [name, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)

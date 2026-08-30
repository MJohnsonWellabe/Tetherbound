extends SceneTree

## T1-CAST evidence render. The four humanoid bodies this lane took off the shelf
## and put into the world, photographed IN the world through the real placement
## code, at the distance a player actually meets them from -- not on a neutral
## backdrop, and not at a portrait crop that flatters a face nobody sees at that
## size.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_t1_cast_world.gd
##
## NEVER `--headless` with a real rendering driver -- it hangs forever and
## leaves a zombie process burning CPU (`ralph/conventions.md`, "Art pipeline
## traps"). Keep `xvfb-run`.
##
## Every shutter runs `tools/capture_check.gd`, which is the whole reason this
## is a new tool rather than an eyeballed screenshot: the 2026-08-30 blind pass
## found frame after frame of committed lane evidence that had silently lost the
## grass field, and every claim reasoned off those frames was made against an
## image missing the largest thing in the real view.
##
## Scratch/evidence tool, not wired into any test.

const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/T1-CAST/shots/world"

const SETTLE_FRAMES := 60
const STREAM_SETTLE_FRAMES := 30
const POSE_FRAMES := 6
const FOV := 60.0

## Player-distance stands on the four reassignments. `eye`/`target` are world XZ;
## heights are metres above the analytic terrain at that XZ, so a stand stays
## correct if the heightfield is retuned.
const VIEWS := [
	{
		"name": "01-bryn-practice-field",
		"eye": Vector2(13.0, 17.0), "eye_h": 1.7,
		"target": Vector2(13.0, 9.0), "target_h": 1.05,
		"_why": "Bryn, the chapter's FIRST trainer fight, now on `young_trainer` "
			+ "instead of a repainted villager_female. 8m out -- roughly where the "
			+ "challenge prompt comes up.",
	},
	{
		"name": "02-bram-off-road",
		"eye": Vector2(195.0, 914.0), "eye_h": 1.7,
		"target": Vector2(195.0, 905.0), "target_h": 1.05,
		"_why": "Old Bram, the retired champion sitting alone off the road, now on "
			+ "`wandering_trainer`. He was on villager_farmer -- which resolves to "
			+ "the FEMALE villager rig -- while his own village_npcs.json entry used "
			+ "the male one.",
	},
	{
		"name": "03-juno-trainer-road",
		"eye": Vector2(-225.0, 5391.0), "eye_h": 1.7,
		"target": Vector2(-225.0, 5400.0), "target_h": 1.05,
		"_why": "Juno on the Band 4 trainer road, now on `rival_trainer`. The one "
			+ "non-Tether trainer standing out in the world rather than in the village.",
	},
	{
		"name": "04-ness-sigil-checkpoint",
		"eye": Vector2(45.0, 7431.0), "eye_h": 1.7,
		"target": Vector2(45.0, 7440.0), "target_h": 1.05,
		"_why": "Warder Ness at the Sigil-gate checkpoint, now on the REGRADED "
			+ "`officer_b` -- the body JUDGE-5 condemned in the courtyard, brought "
			+ "into the faction's colour by tools/regrade_tether_textures.py rather "
			+ "than benched.",
	},
]


func _init() -> void:
	_run()


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return
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
	_hide_canvas_layers(world)

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 3000.0
	# `root` on a SceneTree IS the Window; parent the camera into the world the
	# same way `_judge_capture_hall.gd` does, so `capture_check.gd` finds the
	# grass field's own tree from it.
	world.add_child(camera)
	camera.make_current()

	# Hand Terrain3D and the weather/look rig to THIS camera, exactly as
	# `_judge_capture_hall.gd` does. Round 1 of this tool skipped both and
	# `capture_check` refused the frames for it -- "Terrain3D is streaming
	# around 'Camera3D', not the capture camera" and "WorldWeather is still
	# processing -- the weather pin will drift across a multi-shot pass". That
	# is the check earning its keep: without it these would have been committed
	# as cast evidence while streaming around the wrong camera, which is the
	# precise failure that invalidated this project's earlier visual evidence.
	var terrain: Node = world.get("_terrain") as Node
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")

	# `grass_field.gd` builds its tuft ring around the PLAYER, and Terrain3D's
	# streaming bubble follows it too, so a stand 7km up the map from spawn
	# renders on bare far-cover ground with no grass in it -- the exact "no
	# grass" defect that invalidated this project's earlier evidence. The
	# player goes where the camera goes; it is hidden and frozen either way.
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var field: RefCounted = HEIGHTFIELD.new()
	var written := 0
	var failures: Array[String] = []
	for view: Dictionary in VIEWS:
		var eye_xz: Vector2 = view["eye"]
		var target_xz: Vector2 = view["target"]
		var eye_ground: float = field.call("height_at", eye_xz.x, eye_xz.y)
		var target_ground: float = field.call("height_at", target_xz.x, target_xz.y)
		var eye := Vector3(eye_xz.x, eye_ground + float(view["eye_h"]), eye_xz.y)
		var target := Vector3(target_xz.x, target_ground + float(view["target_h"]), target_xz.y)
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		# Carry the grass ring and the terrain bubble to the stand.
		if player != null:
			player.global_position = eye
		# TWO settle passes with a real drawn frame between them, not one long
		# one. `_judge_capture_hall.gd` paid for this lesson: frame count was
		# never the lever -- the same stand shot twice in one run came back at
		# 5.5% and 54.6% green cover, because what a stand is really waiting on
		# is Terrain3D streaming the region in, and `grass_field` places its
		# tufts in a shader off the live height and region maps. Until the
		# region is resident the field has nothing to stand on and quietly draws
		# almost nothing -- and `capture_check` passes it, because it asks
		# whether the field exists and follows this camera, both true of a
		# half-built one.
		for pass_index in 2:
			for i in STREAM_SETTLE_FRAMES:
				await physics_frame
			for i in POSE_FRAMES:
				await process_frame

		# The player is IGNORED for the inside-a-body check, the same way
		# `_judge_capture_hall.gd` ignores it: this tool deliberately parks it at
		# the camera so the grass ring and terrain bubble stream to the stand, so
		# "the camera is inside 'Player'" is this tool's own doing and not a
		# frame defect. It stays in the check for every OTHER body.
		var problems: Array = CAPTURE_CHECK.warn_only(self, camera, "clear", null,
			[player] if player != null else [])
		if not problems.is_empty():
			failures.append("%s: %s" % [view["name"], ", ".join(problems)])

		await process_frame
		var image := camera.get_viewport().get_texture().get_image()
		var path: String = "%s/%s.png" % [OUT_DIR, view["name"]]
		image.save_png(ProjectSettings.globalize_path(path))
		print("  %-28s -> %s" % [view["name"], path])
		written += 1

	print("\n%d frames -> %s" % [written, OUT_DIR])
	if failures.is_empty():
		print("[capture_check] every frame passed")
	else:
		print("[capture_check] PROBLEMS -- do not judge these as the shipping game:")
		for f: String in failures:
			print("  %s" % f)
	quit()

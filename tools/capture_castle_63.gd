extends SceneTree

## T1-ARCH: the castle (`landmark.gd`'s `StrongholdSilhouette`), at its REAL
## site.
##
## `capture_castle.gd`'s own `SITE` constant is `Vector3(229.8, 0.0, -144.4)`
## -- the OLD `RISE_CENTRE + OFFSET` site, retired by GATE-E2 (2026-08-23,
## `landmark.gd`'s own header) when the corridor rewrite moved the castle to
## `SITE := Vector2(150.0, 7595.0)`. The old file was never updated to follow
## it, so every frame it produces is 7.5km from the actual building -- empty
## corridor grass, not the castle. This file reads `landmark.gd`'s `SITE`
## constant directly (`LANDMARK.SITE`) so it cannot go stale the same way
## again, and stands at the real building.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_castle_63.gd
##
## Four stands: the approach the player actually walks (south, off the ramp
## -- `landmark.gd::RAMP_RUN`'s own comment says the ramp exits toward
## decreasing world z), a far silhouette read, a close corner for material/
## proportion, and a top-down for massing. Day only -- `art.json` already
## puts the sun in the north sky and every approach is southern, so day is
## the hour every player actually sees this face at, per `landmark.gd`'s own
## `stronghold_occupation.gd` comment about the near-field backlighting.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/castle_63"
const LANDMARK := preload("res://scripts/world/landmark.gd")
const SETTLE_FRAMES := 240
const POSE_FRAMES := 6
const FOV := 65.0

## Offsets from the site's own ground-snap point (`SITE.x, ground, SITE.y`),
## not from the plinth centre -- matches how `capture_castle.gd` and
## `landmark.gd::build()` both anchor.
const VIEWS := [
	{
		# The player's own approach: standing at the foot of the ramp, looking
		# up at the gate. `RAMP_RUN` is 11m south of the plinth face.
		"name": "01-approach-gate", "offset": Vector3(2.0, 1.8, 24.0), "look_at": Vector3(2.0, 8.0, 0.0),
	},
	{
		# Far enough out to get the whole mass in frame -- the silhouette read.
		"name": "02-silhouette-far", "offset": Vector3(4.0, 20.0, 70.0), "look_at": Vector3(2.0, 14.0, 0.0),
	},
	{
		# A three-quarter corner, close, for material/proportion judgement.
		"name": "03-corner-close", "offset": Vector3(38.0, 14.0, 38.0), "look_at": Vector3(2.0, 9.0, 12.0),
	},
	{
		"name": "04-top-down", "offset": Vector3(2.0, 110.0, 12.0), "look_at": Vector3(2.0, 0.0, 12.0),
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

	_hide_canvas_layers(root)

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 3000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var park := Vector2(-357.0 + 700.0, 2610.0 + 700.0)
		var park_y := float(world.call("ground_height_at", park.x, park.y))
		player.global_position = Vector3(park.x, park_y + 0.2, park.y)
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var landmark: Node3D = world.get_node_or_null(^"StrongholdSilhouette") as Node3D
	if landmark == null:
		push_error("no StrongholdSilhouette in the scene")
		quit(1)
		return

	var site := LANDMARK.SITE
	var ground: float = float(world.call("ground_height_at", site.x, site.y))
	if is_nan(ground):
		ground = 0.0
	print("[capture_castle_63] LANDMARK.SITE=%s ground=%.2f built_at=%s" % [
		str(site), ground, str(landmark.global_position)])

	var written: Array[String] = []
	var failures: Array[String] = []
	for entry: Variant in VIEWS:
		var view: Dictionary = entry
		var name_value := str(view["name"])
		var offset: Vector3 = view["offset"]
		var look_at_local: Vector3 = view["look_at"]
		camera.global_position = Vector3(site.x, ground, site.y) + offset
		var target := Vector3(site.x, ground, site.y) + look_at_local
		camera.look_at(target, Vector3.UP)
		for i in 12:
			await physics_frame
		if look != null:
			if look.has_method("set_weather"):
				look.call("set_weather", {})
			look.call("apply_time", "day")
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name_value)
			continue
		var path := "%s/%s.png" % [OUT_DIR, name_value]
		if image.save_png(path) != OK:
			failures.append("%s: save_png failed" % name_value)
			continue
		written.append(path)
		print("  %-20s -> %s" % [name_value, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)

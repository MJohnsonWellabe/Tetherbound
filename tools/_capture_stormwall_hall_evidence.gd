extends SceneTree

## T1-STORMWALL (2026-08-30). A single, well-aimed exterior stand of the
## Meadows Hall approach, raised above the Band 5 treeline and aimed at the
## Hall itself (same composition `_judge_capture_hall.gd`'s H-02b later added
## on `ralph/T1-HALL-REBUILD`, for the same reason: at ground level the
## treeline fills the frame end to end and the Hall -- and whatever stands
## behind it -- is not answerable from that height). Used here as the
## before/after stand for `rift_collapse.gd`'s StormWall materials fix:
## `_probe_stormwall_hall.gd` measured the three StormWall slabs at 332-409m
## from the Hall's own site, 5-9 degrees off this stand's own bearing to it,
## so they sit in the sky directly behind the building from this vantage.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_stormwall_hall_evidence.gd -- --out=res://shots/stormwall_after
##
## NEVER --headless with a rendering driver: hangs forever (same warning
## _judge_capture_hall.gd's own header carries).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 90
const POSE_FRAMES := 3
const FOV := 60.0

var _out_dir := "res://shots/stormwall_evidence"

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

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
	camera.name = "EvidenceCamera"
	camera.fov = FOV
	camera.far = 3000.0
	world.add_child(camera)
	camera.make_current()
	var terrain: Node = world.get("_terrain") as Node
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	var grass := _find(world, "GrassField")
	if grass != null and grass.has_method("bind"):
		grass.call("bind", grass.get("_terrain"), camera)

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
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var stronghold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	if stronghold == null:
		push_error("no Stronghold node; the Hall did not build")
		quit(1)
		return

	# Raised stand at the Sigil Gate approach, aimed at the Hall -- above the
	# Band 5 treeline that blocks every ground-level stand.
	var at := Vector2(63.6, 7395.0)
	var ground := float(world.call("ground_height_at", at.x, at.y))
	var eye := Vector3(at.x, ground + 26.0, at.y)
	var target := stronghold.global_position + Vector3(0.0, 12.0, 0.0)
	if player != null:
		player.global_position = eye
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	for i in 40:
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
		push_error("viewport returned no image")
		quit(1)
		return
	var path := "%s/stormwall-behind-hall.png" % _out_dir
	if image.save_png(path) != OK:
		push_error("save_png failed")
		quit(1)
		return
	print("wrote %s" % path)
	quit(0)


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


static func _find(from: Node, want: String) -> Node:
	if from == null:
		return null
	if from.name == want:
		return from
	for child in from.get_children():
		var hit := _find(child, want)
		if hit != null:
			return hit
	return null

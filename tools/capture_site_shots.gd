extends SceneTree

## Capture the download page's screenshots from the real game.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_site_shots.gd
##
## Same honesty rule as tools/survey.sh: these are REAL frames, no touch-ups
## (site/README.md). Compatibility renderer caveat applies — see survey.sh's
## header. Frames land in shots/site/ as PNG; site/README.md's snippet
## converts to JPG for the page.
##
## Every viewpoint is world-space authored HERE because the shots have to
## frame specific authored content (the village square, the bedroom, the
## starter row), which the survey's fixed exploration viewpoints know nothing
## about.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/site"
const SETTLE_FRAMES := 50

## name -> [camera position, look-at target]. The meadow shots are absolute
## world coordinates; the two house shots are DERIVED from the house's own
## markers in `_shots()`, because the house stands on a terrain pad whose
## height is data — hardcoded coordinates went stale the first time the pad
## moved, and the "bedroom" frame was a camera inside the roof.
const SHOTS := {
	"hero-meadow": [Vector3(58.0, 14.0, 28.0), Vector3(-10.0, 4.0, -12.0)],
	"village-square": [Vector3(-6.0, 6.5, 4.0), Vector3(14.0, 3.0, -8.0)],
	"camp-dusk": [Vector3(24.0, 6.0, -30.0), Vector3(30.5, 3.4, -36.0)],
}


func _shots(world: Node) -> Dictionary:
	var shots: Dictionary = SHOTS.duplicate()
	var house: Node3D = world.get_node_or_null(^"GrandpaHouse") as Node3D
	if house == null:
		return shots
	# Inside the loft, from the stair end toward the bed in the west corner.
	var bed: Vector3 = house.call("marker", "bed")
	shots["opening-bedroom"] = [house.to_global(Vector3(0.8, 5.0, 1.7)), bed + Vector3(0.0, 0.2, 0.0)]
	# The starter row waits at the outside marker facing the door; shoot along
	# the row from its south side with the doorway on the left of frame.
	var outside: Vector3 = house.call("marker", "outside")
	var door: Vector3 = house.call("marker", "door")
	var mid := outside.lerp(door, 0.35) + Vector3(0.0, 1.1, 0.0)
	shots["starters-by-the-door"] = [outside + Vector3(-1.0, 1.9, 7.0), mid]
	return shots


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await process_frame

	# No UI in a beauty shot: the debug HUD, interact prompts and menu all live
	# on CanvasLayers, and the first hero capture shipped with the movement
	# readout and a "Get up" prompt baked into it.
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	# Stage a camp for its shot: the real builder, placed as the placer would.
	var camp: Node3D = preload("res://scripts/build/camp.gd").new()
	camp.name = "SiteShotCamp"
	world.add_child(camp)
	camp.call("build_real")
	var ground := float(world.call("ground_height_at", 30.5, -36.0))
	if not is_nan(ground):
		camp.global_position = Vector3(30.5, ground, -36.0)

	var camera := Camera3D.new()
	camera.fov = 62.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	# The opening's staging leaves the player standing ON the mattress; for the
	# bedroom frame, stand them on the loft floor beside the bed instead.
	var house: Node3D = world.get_node_or_null(^"GrandpaHouse") as Node3D
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if house != null and player != null:
		player.global_position = house.to_global(Vector3(-1.6, 3.3, -0.3))
		player.look_at(Vector3(house.call("marker", "bed")) * Vector3(1, 0, 1)
			+ Vector3(0.0, player.global_position.y, 0.0))
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var shots: Dictionary = _shots(world)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for name: String in shots.keys():
		# Frames are ~4-8s each under llvmpipe, so a full run does not fit one
		# timeout budget. Skipping what already landed makes the run resumable.
		if FileAccess.file_exists("%s/%s.png" % [OUT, name]):
			print("skip -> %s.png (already captured)" % name)
			continue
		var spec: Array = shots[name]
		camera.global_position = spec[0]
		camera.look_at(spec[1])
		# Long settle per shot: Terrain3D streams regions toward the camera.
		for i in 25:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT, name])
		print("shot -> %s.png" % name)

	print("done: %d frames in %s" % [shots.size(), OUT])
	quit(0)

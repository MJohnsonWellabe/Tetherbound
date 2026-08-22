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
	# BROKEN VIEWPOINT, 2026-08-22: this eye/target pair frames the inside of a
	# roof -- the captured JPEG was ~70% roof tiles with the square nowhere in
	# it, and it sat on the download page captioned "The village square" until
	# the story rewrite deleted the frame. Whoever next runs a capture: move
	# the eye up and back off the buildings until the square, the well and the
	# paths out are in shot, then re-run tools/site_images.py. Left at the old
	# numbers deliberately -- re-aiming a camera in a 3D scene is not a change
	# to guess at without rendering it.
	"village-square": [Vector3(-6.0, 6.5, 4.0), Vector3(14.0, 3.0, -8.0)],
	"camp-dusk": [Vector3(26.8, 4.8, -32.3), Vector3(30.5, 3.0, -36.0)],
	# R7.2: close enough to actually read a villager as a person rather than a
	# dot. First cut was an 8m-high overview (Mira and Oskar were both a couple
	# of pixels tall) — this is a walking-up shot at near eye height, framing
	# Mira against the well and the barns the way starters-by-the-door frames
	# a creature against the square.
	"village-npcs": [Vector3(16.0, 2.3, 3.0), Vector3(11.5, 1.7, -4.0)],
}


func _shots(world: Node) -> Dictionary:
	var shots: Dictionary = SHOTS.duplicate()
	var house: Node3D = world.get_node_or_null(^"GrandpaHouse") as Node3D
	if house == null:
		return shots
	# Inside the loft, from the stair end toward the bed in the west corner.
	var bed: Vector3 = house.call("marker", "bed")
	shots["opening-bedroom"] = [house.to_global(Vector3(0.8, 5.0, 1.7)), bed + Vector3(0.0, 0.2, 0.0)]
	# The starter row waits at the outside marker facing the door. Shoot FROM
	# the door side, so the creatures face the camera with open meadow and sky
	# behind their silhouettes — the first cut shot them from behind, pressed
	# against the house wall, and the blind critique rightly called it the one
	# frame whose job was to sell the creatures hiding them instead.
	# Off-axis and back from the row: the straight-down-the-axis attempt put
	# the camera a metre from the nearest creature's back, which filled a
	# third of the frame as an out-of-focus blob.
	shots["starters-by-the-door"] = [
		house.to_global(Vector3(6.0, 2.6, -2.5)),
		house.to_global(Vector3(12.6, 0.9, 1.4)),
	]
	# R7.2's interior dressing: Grandpa's own bed and the second bookcase in
	# the south-west corner, the rug under the table/chair/stool cluster, and
	# the gear table by the door, all in one frame from near the stair foot.
	shots["house-interior-dressed"] = [
		house.to_global(Vector3(3.6, 1.7, 3.0)),
		house.to_global(Vector3(-3.3, 0.7, -1.0)),
	]
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

	var house: Node3D = world.get_node_or_null(^"GrandpaHouse") as Node3D
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var look: Node = world.get_node_or_null(^"WorldLook")

	var shots: Dictionary = _shots(world)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for name: String in shots.keys():
		# Frames are ~4-8s each under llvmpipe, so a full run does not fit one
		# timeout budget. Skipping what already landed makes the run resumable.
		if FileAccess.file_exists("%s/%s.png" % [OUT, name]):
			print("skip -> %s.png (already captured)" % name)
			continue

		# Per-shot staging. The player: beside the bed for the bedroom frame
		# (the opening leaves them standing ON the mattress), and standing with
		# the starter row for the door frame — a creature-training game's page
		# had no frame with a trainer and a creature together until it did.
		if house != null and player != null:
			if name == "opening-bedroom":
				player.global_position = house.to_global(Vector3(-1.6, 3.3, -0.3))
				player.look_at(Vector3(house.call("marker", "bed")) * Vector3(1, 0, 1)
					+ Vector3(0.0, player.global_position.y, 0.0))
			elif name == "starters-by-the-door":
				player.global_position = house.to_global(Vector3(11.8, 0.1, 4.6))
				player.look_at(house.to_global(Vector3(8.5, 0.0, 0.5)) * Vector3(1, 0, 1)
					+ Vector3(0.0, player.global_position.y, 0.0))
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
		# The sun: warm for the camp frame — its name promises dusk, and the
		# same noon sky as every other frame does not deliver it — restored
		# to the authored day for everything else. Routed through WorldLook's
		# own art.json presets (EV8) rather than hand-rotating the
		# DirectionalLight3D: a sun-only tweak leaves the sky/fog/ambient at
		# noon values, which is the exact "frame to frame disagreement" the
		# bible's one-sky-treatment rule exists to close, not just a look
		# this one frame happened to want.
		if look != null:
			look.call("apply_time", "golden" if name == "camp-dusk" else "day")

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

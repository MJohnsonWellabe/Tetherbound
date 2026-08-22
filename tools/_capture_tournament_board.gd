extends SceneTree

## TOURNAMENT-1's visual evidence: the tournament ground, from the walk-up.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_tournament_board.gd
##
## Plain `--headless` with `--rendering-driver opengl3` hangs forever; the
## xvfb invocation above is the one that works (ralph/conventions.md).
##
## Two frames, because the board has two jobs and they fail differently:
##
##   * `tournament-board` is the read: close enough that the painted bracket
##     has to be legible, which is the whole point of the owner directive
##     ("the board must be visible to the player so the bracket reads as
##     real"). If the fit arithmetic in `tournament.gd::pixel_size_for()` is
##     wrong this is where it shows.
##   * `tournament-ground` is the walk-up from the village square: does the
##     thing read as village carpentry standing in a field, at the distance a
##     player first sees it, or as a UI panel dropped into the world?
##
## The board is captured MID-BRACKET (the player's quarter-final won, the
## other three quarters resolved) rather than blank, because a blank board is
## the one state that hides a fitting bug -- the longest line only exists once
## the results are painted in.
##
## An underscore-prefixed tool, same as `_capture_berry_farm.gd`: written for
## one visual pass and kept so the next one does not have to reinvent the
## camera placement.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const OUT := "res://shots/tournament"
const SETTLE_FRAMES := 60
const SHOT_FRAMES := 25


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for _i in SETTLE_FRAMES:
		await process_frame

	# No UI in an art frame -- the debug HUD and the interact prompt both live
	# on CanvasLayers and would otherwise be baked into the critique.
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	# Paint the board mid-bracket. Written straight into the real flag store,
	# so what is captured is what the real board draws rather than a mock.
	var game := root.get_node_or_null(^"Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null:
		progression.call("set_flag", "tournament_entered")
		progression.call("set_flag", "tournament_quarter_won")
	for _i in 5:
		await process_frame

	var board := TOURNAMENT.board_position()
	var ground := float(world.call("ground_height_at", board.x, board.y))
	if is_nan(ground):
		push_error("no ground under the board; nothing to photograph")
		quit(1)
		return

	var camera := Camera3D.new()
	camera.fov = 62.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	var terrain: Node = world.get("_terrain") as Node
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	# The board faces `facing_deg`; stand the camera out along that facing so
	# the painted side is the side photographed. Derived rather than
	# hardcoded, so retuning the board's yaw in tournament.json does not
	# silently start photographing its back.
	var yaw := deg_to_rad(TOURNAMENT.board_facing_deg())
	var front := Vector2(sin(yaw), cos(yaw))
	var centre := Vector3(board.x, ground, board.y)

	var shots := {
		"tournament-board": [
			centre + Vector3(front.x, 0.0, front.y) * 3.4 + Vector3(0.0, 1.75, 0.0),
			centre + Vector3(0.0, 1.5, 0.0),
		],
		"tournament-ground": [
			centre + Vector3(front.x, 0.0, front.y) * 14.0 + Vector3(0.0, 3.2, 0.0),
			centre + Vector3(0.0, 1.2, 0.0),
		],
	}

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for name: String in shots.keys():
		var spec: Array = shots[name]
		camera.global_position = spec[0]
		camera.look_at(spec[1])
		# Terrain3D streams regions toward the camera; a short settle
		# photographs a hole in the ground.
		for _i in SHOT_FRAMES:
			await process_frame
		root.get_texture().get_image().save_png("%s/%s.png" % [OUT, name])
		print("shot -> %s.png" % name)

	print("done: %d frames in %s" % [shots.size(), OUT])
	quit(0)

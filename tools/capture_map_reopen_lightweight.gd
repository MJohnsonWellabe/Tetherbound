extends SceneTree

## Render the real pause-map repeatedly without the expensive Meadows world.
## This isolates paused menu rebuilds and texture-cache lifetime: every frame
## must retain complete chrome, labels and fog after close/open.

const OUT_DIR := "res://shots/map-reopen-lightweight"


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await process_frame
	root.size = Vector2i(1280, 800)
	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload missing")
		quit(1)
		return
	var world := Node3D.new()
	world.name = "MapCaptureWorld"
	root.add_child(world)
	current_scene = world
	var player := CharacterBody3D.new()
	player.name = "Player"
	world.add_child(player)
	var map_state: RefCounted = game.get("map")
	map_state.call("reveal_circle", Vector3.ZERO, 70.0)
	game.call("set_objective", "Restore the Old Mill Crossing", Vector3(200.0, 0.0, -140.0))
	var menu: CanvasLayer = game.call("menu")
	for index in 3:
		menu.call("open", "map")
		for frame in 30:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := "%s/reopen_%d.png" % [OUT_DIR, index + 1]
		var error := image.save_png(path)
		if error != OK:
			push_error("failed to save %s: %d" % [path, error])
			quit(1)
			return
		print("  %s" % path)
		menu.call("close")
		for frame in 5:
			await process_frame
	quit(0)

extends SceneTree

## Production menu/map drawing over a previously captured real terrain bake.
## UI-only evidence: no Terrain3D world, HUD/minimap or traversal proof.
const SAVE := preload("res://scripts/save/save_game.gd")
var output_dir := ""
var terrain_path := ""

class BakedMapScene extends Node3D:
	var terrain: Texture2D
	func map_terrain_texture() -> Texture2D:
		return terrain

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			output_dir = argument.trim_prefix("--out-dir=")
		if argument.begins_with("--terrain-image="):
			terrain_path = argument.trim_prefix("--terrain-image=")
	if output_dir.is_empty() or terrain_path.is_empty():
		_fail("Explicit output directory and real terrain bake are required")
		return
	var terrain_image := Image.load_from_file(terrain_path)
	if terrain_image == null or terrain_image.is_empty():
		_fail("Real terrain bake could not be loaded")
		return
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		_fail("Output directory could not be created")
		return
	root.size = Vector2i(1920, 1080)
	var game := root.get_node("Game")
	game.set("save_system", SAVE.new("user://map_ui_capture_%d_%d/" % [
		OS.get_process_id(), Time.get_ticks_usec()]))
	game.call("reset_for_new_game")
	game.get("progression").call("set_flag", "opening:beat:free_play")
	var world := BakedMapScene.new()
	world.terrain = ImageTexture.create_from_image(terrain_image)
	root.add_child(world)
	current_scene = world
	var map_state: RefCounted = game.get("map")
	map_state.call("reveal_all")
	for landmark: Dictionary in map_state.call("landmarks"):
		map_state.call("discover_landmark", str(landmark.get("id", "")))
	game.call("set_objective", "Reach the Old Mill Crossing", Vector3(-152, 0, 4203))
	var menu: CanvasLayer = game.call("menu")
	for index in 2:
		# Exercise production open/build/close, not a handmade map Control.
		menu.call("open", "map")
		for frame in 30:
			await process_frame
		if not bool(menu.call("is_open")) or str(menu.call("current_tab_id")) != "map":
			_fail("Production map menu did not open")
			return
		await RenderingServer.frame_post_draw
		var frame_image := root.get_texture().get_image()
		var destination := output_dir.path_join("map_ui_open_%d.png" % (index + 1))
		if frame_image == null or frame_image.save_png(destination) != OK:
			_fail("Map viewport capture failed")
			return
		print("UI-ONLY MAP CAPTURE: ", destination)
		menu.call("close")
		for frame in 8:
			await process_frame
		if bool(menu.call("is_open")):
			_fail("Production map menu did not close")
			return
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

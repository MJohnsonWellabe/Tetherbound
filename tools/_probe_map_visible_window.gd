extends SceneTree

const SCENE := "res://scenes/world/meadows_playground.tscn"


func _init() -> void:
	_run()


func _run() -> void:
	DisplayServer.window_set_position(Vector2i(0, 0))
	var world := (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in 240:
		await physics_frame
	var game := root.get_node(^"/root/Game")
	game.set("_last_input_was_gamepad", true)
	var map_state: RefCounted = game.get("map")
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player != null:
		map_state.call("mark_visited", player.global_position)
	map_state.call("reveal_circle", Vector3(-6.0, 0.0, -13.0), 55.0)
	for point in [Vector3(-22.0, 0.0, -16.0), Vector3(10.0, 0.0, -10.0), Vector3(27.5, 0.0, -16.0)]:
		map_state.call("mark_visited", point)
	game.call("set_objective", "Restore the Old Mill Crossing", Vector3(200.0, 0.0, -140.0))
	var menu: CanvasLayer = game.call("menu")
	menu.call("open", "map")
	for i in 120:
		await process_frame
	await _capture_screen("map_initial_os_20260907.png")
	menu.call("close")
	for i in 30:
		await process_frame
	menu.call("open", "map")
	for i in 120:
		await process_frame
	await _capture_screen("map_reopened_os_20260907.png")
	for z in range(-230, 231, 40):
		for x in range(-230, 231, 60):
			map_state.call("reveal_circle", Vector3(float(x), 0.0, float(z)), 34.0)
	for i in 120:
		await process_frame
	await _capture_screen("map_surveyed_os_20260907.png")
	menu.call("close")
	for i in 60:
		await process_frame
	await _capture_screen("compass_hud_os_20260907.png")
	quit(0)


func _capture_screen(file_name: String) -> void:
	Input.warp_mouse(Vector2(1276.0, 796.0))
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var screen_image: Image = DisplayServer.screen_get_image()
	if screen_image == null or screen_image.is_empty():
		push_error("DisplayServer returned no screen image")
		quit(1)
		return
	var window_rect := Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	var captured := screen_image.get_region(window_rect)
	var out_dir := ProjectSettings.globalize_path("res://shots/final-os-evidence-20260907")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var err := captured.save_png(out_dir.path_join(file_name))
	print("OS_CAPTURE %s %s %dx%d err=%d" % [file_name, str(window_rect), captured.get_width(), captured.get_height(), err])
	if err != OK:
		quit(1)

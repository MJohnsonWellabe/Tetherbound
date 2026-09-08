extends SceneTree

## Gate A full-map evidence: the production first-open -> close -> second-open
## path, plus the restored HUD minimap after the first close. Screenshots come
## from the game viewport, so foreground desktop windows cannot obscure them.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SAVE := preload("res://scripts/save/save_game.gd")
const OUT_DIR := "res://ralph/reports/FOUR-BIOME-BUILD/hud-map/captures"
const SETTLE_FRAMES := 300
var output_dir := OUT_DIR


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			output_dir = argument.trim_prefix("--out-dir=")
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir)) != OK:
		push_error("could not create capture directory")
		quit(1)
		return
	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload not found")
		quit(1)
		return
	# This is a disclosed map-presentation fixture, never a user's save slot.
	game.set("save_system", SAVE.new("user://map_presentation_%d_%d/" % [
		OS.get_process_id(), Time.get_ticks_usec()]))
	game.call("reset_for_new_game")
	game.get("progression").call("set_flag", "opening:beat:free_play")
	var packed := load(SCENE) as PackedScene
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world := packed.instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	if not bool(world.call("shell_build_complete")):
		push_error("Meadows world did not finish building before map capture")
		quit(1)
		return
	var map_state: RefCounted = game.get("map")
	map_state.call("reveal_all")
	for landmark: Dictionary in map_state.call("landmarks"):
		map_state.call("discover_landmark", str(landmark.get("id", "")))
	for region: Dictionary in map_state.call("regions"):
		var centre: Vector2 = region.get("centre", Vector2.ZERO)
		map_state.call("update_region", Vector3(centre.x, 0.0, centre.y))
	game.call("set_objective", "Reach the Old Mill Crossing", Vector3(-152.0, 0.0, 4203.0))

	await _press_button_action("map")
	for i in 90:
		await process_frame
	var menu: CanvasLayer = game.call("menu") as CanvasLayer
	if menu == null or not bool(menu.call("is_open")) or str(menu.call("current_tab_id")) != "map":
		push_error("physical Map did not produce the first full-map open")
		quit(1)
		return
	if not await _shoot("clean_full_map_first_open"):
		quit(1)
		return

	await _press_button_action("menu_cancel")
	for i in 30:
		await process_frame
	if bool(menu.call("is_open")):
		push_error("physical Back did not close the first full-map open")
		quit(1)
		return
	if not await _shoot("clean_hud_minimap_after_close"):
		quit(1)
		return

	await _press_button_action("map")
	for i in 90:
		await process_frame
	if not bool(menu.call("is_open")) or str(menu.call("current_tab_id")) != "map":
		push_error("physical Map did not produce the second full-map open")
		quit(1)
		return
	var bodies: Array = menu.get("_bodies")
	var reopened_map := bodies[int(menu.get("_index"))] as Control
	var reopened_canvas := reopened_map.get("_canvas") as Control if reopened_map != null else null
	if reopened_canvas == null or not reopened_canvas.clip_contents:
		push_error("second full-map open did not build a valid clipped canvas")
		quit(1)
		return
	if not await _shoot("clean_full_map_second_open"):
		quit(1)
		return

	await _press_button_action("menu_cancel")
	for i in 15:
		await process_frame
	if bool(menu.call("is_open")):
		push_error("physical Back did not close the second full-map open")
		quit(1)
		return
	quit(0)


func _press_button_action(action: String) -> void:
	for event in InputMap.action_get_events(action):
		var binding := event as InputEventJoypadButton
		if binding == null:
			continue
		var down := InputEventJoypadButton.new()
		down.button_index = binding.button_index
		down.pressed = true
		Input.parse_input_event(down)
		await process_frame
		var up := InputEventJoypadButton.new()
		up.button_index = binding.button_index
		up.pressed = false
		Input.parse_input_event(up)
		for i in 8:
			await process_frame
		return
	push_error("no joypad button binding for %s" % action)


func _pulse_motion_action(action: String) -> void:
	for event in InputMap.action_get_events(action):
		var binding := event as InputEventJoypadMotion
		if binding == null:
			continue
		var down := InputEventJoypadMotion.new()
		down.axis = binding.axis
		down.axis_value = binding.axis_value
		Input.parse_input_event(down)
		for i in 5:
			await process_frame
		var up := InputEventJoypadMotion.new()
		up.axis = binding.axis
		up.axis_value = 0.0
		Input.parse_input_event(up)
		for i in 8:
			await process_frame
		return
	push_error("no joypad motion binding for %s" % action)


func _hold_axis(axis: JoyAxis, value: float, frames: int) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = value
	Input.parse_input_event(motion)
	for i in frames:
		await physics_frame
	var release := InputEventJoypadMotion.new()
	release.axis = axis
	release.axis_value = 0.0
	Input.parse_input_event(release)
	for i in 8:
		await physics_frame


func _shoot(name: String) -> bool:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image for %s" % name)
		return false
	var path := "%s/%s.png" % [output_dir, name]
	var error := image.save_png(path)
	if error != OK:
		push_error("save_png failed for %s (%d)" % [name, error])
		return false
	print("  %s -> %s (%dx%d)" % [name, path, image.get_width(), image.get_height()])
	return true

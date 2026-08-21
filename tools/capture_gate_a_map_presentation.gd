extends SceneTree

## Gate A full-map evidence: honest whole-world fit plus the production
## controller zoom/pan path at a readable local scale.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag/gate_a_map_presentation"
const SETTLE_FRAMES := 300


func _init() -> void:
	_run()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
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

	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload not found")
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
	await _shoot("full_map_world_fit")

	# Two physical RT pulses select the 8x local view, then the physical right
	# stick moves it along both axes before the second frame.
	await _pulse_motion_action("map_zoom_in")
	await _pulse_motion_action("map_zoom_in")
	await _hold_axis(JOY_AXIS_RIGHT_X, 1.0, 75)
	await _hold_axis(JOY_AXIS_RIGHT_Y, -0.75, 55)
	for i in 30:
		await process_frame
	await _shoot("full_map_zoomed_panned")
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


func _shoot(name: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image for %s" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		push_error("save_png failed for %s (%d)" % [name, error])
		return
	print("  %s -> %s (%dx%d)" % [name, path, image.get_width(), image.get_height()])

extends RefCounted

## Controller pilot for the ultimate, for engine smokes that fight through the
## real CombatManager (e.g. the Hall route). Same physical input a player uses:
## RB is pressed and RELEASED (a hold never arms), then one fresh face tap fires
## the frozen signature. Nothing here touches the meter or host state.
##
##   const ULTIMATE_PILOT := preload("res://tests/helpers/ultimate_pilot.gd")
##   if await ULTIMATE_PILOT.fire(get_tree(), manager):
##       ...  # the face tap consumed the armed ultimate; check the host for acceptance
##
## Returns false without pressing anything when the meter is not full, and
## false when RB release did not arm (gate off, recovering, input owned).

static func meter_full(manager: Node) -> bool:
	return manager != null and manager.has_method("ultimate_fraction") \
		and is_equal_approx(float(manager.call("ultimate_fraction")), 1.0)


static func fire(tree: SceneTree, manager: Node,
		face: JoyButton = JOY_BUTTON_Y, device: int = 0) -> bool:
	if not meter_full(manager):
		return false
	await press(tree, JOY_BUTTON_RIGHT_SHOULDER, true, device)
	await press(tree, JOY_BUTTON_RIGHT_SHOULDER, false, device)
	if not bool(manager.call("ultimate_armed")):
		return false
	await press(tree, face, true, device)
	await press(tree, face, false, device)
	return not bool(manager.call("ultimate_armed"))


static func press(tree: SceneTree, button: JoyButton, pressed: bool, device: int = 0) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await tree.physics_frame
	await tree.process_frame
	await tree.physics_frame

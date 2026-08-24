extends SceneTree

## GATEB-COORD diagnostic. ONE leg of stick_navigator travel, instrumented.
##
##   godot --headless --path . --script tools/_probe_walk_leg.gd
##
## `tools/_probe_scatter_fill.gd` says the fill "stopped 46.9m short" of a
## stand 4m uphill; it does not say WHY, and the two candidate explanations
## (the free-space probe reading a slope as a wall, versus a stand behind
## terrain nothing can climb) want different fixes. This walks the same leg
## and prints, every quarter second: where the player is, how much of the gap
## is left, whether the navigator thinks it is stalled or detouring, and what
## the body's own velocity and floor state say.
##
## A probe, not evidence.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const VEGETATION_POINT_PATH := "res://scripts/world/vegetation_harvest_point.gd"

var _player: CharacterBody3D
var _rig: Node3D
var _move_x_axis := JOY_AXIS_LEFT_X
var _move_y_axis := JOY_AXIS_LEFT_Y
var _move_x_sign := 1.0
var _move_y_sign := 1.0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for _i in 300:
		await physics_frame

	_player = _find(world, "locomotion_enabled") as CharacterBody3D
	_rig = _find(world, "planar_basis") as Node3D
	if _player == null or _rig == null:
		print("PROBE: missing player/rig")
		quit(1)
		return
	_resolve_bindings()

	var target := _nearest_scatter("wood")
	if target == null:
		print("PROBE: no live wood scatter in the world")
		quit(1)
		return

	var start := _player.global_position
	var to := target.global_position - start
	print("PROBE leg: from %s to %s | horizontal %.1fm | rise %.2fm" % [
		str(start.round()), str(target.global_position.round()),
		Vector2(to.x, to.z).length(), to.y])

	var nav = NAVIGATOR.new(self, _player, _rig, Callable(self, "_send_stick"))
	nav.reset()
	var budget := 240 + int(start.distance_to(target.global_position) * 60.0)
	print("PROBE budget %d frames" % budget)

	var best := INF
	var last := start
	for frame in budget:
		var gap_v := target.global_position - _player.global_position
		gap_v.y = 0.0
		var gap := gap_v.length()
		best = minf(best, gap)
		if gap <= 1.65:
			print("PROBE ARRIVED at frame %d" % frame)
			break
		if frame % 15 == 0:
			var moved := _player.global_position.distance_to(last)
			last = _player.global_position
			print("  f%-5d pos %-22s gap %6.1f best %6.1f | navgap %6.1f stall %2d detourleft %3d side %+0.0f | moved/15f %.3f vel %.2f floor %s" % [
				frame, str(_player.global_position.round()), gap, best,
				float(nav.get("_gap")), int(nav.get("_stall")),
				int(nav.get("_detour_left")), float(nav.get("_side")),
				moved, Vector2(_player.velocity.x, _player.velocity.z).length(),
				str(_player.is_on_floor())])
		await nav.step(target.global_position)
	_send_stick(0.0, 0.0)
	print("PROBE end: gap %.1f (best %.1f)" % [
		Vector2(target.global_position.x - _player.global_position.x,
			target.global_position.z - _player.global_position.z).length(), best])

	# The terrain profile along the straight line, so "unclimbable" is a
	# measurement rather than a guess.
	print("PROBE terrain profile along the straight line:")
	var terrain := get_first_node_in_group(&"terrain")
	if terrain != null and terrain.has_method("ground_height_at"):
		var line := ""
		for i in 21:
			var p: Vector3 = start.lerp(target.global_position, float(i) / 20.0)
			line += "%.1f " % float(terrain.call("ground_height_at", p.x, p.z))
		print("  " + line)
	else:
		print("  no terrain node in group 'terrain'")
	quit(0)


func _nearest_scatter(item_id: String) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for candidate: Node in get_nodes_in_group("harvestable"):
		if not candidate is Node3D or not candidate.has_method("resource_item"):
			continue
		var script := candidate.get_script() as Script
		if script == null or script.resource_path != VEGETATION_POINT_PATH:
			continue
		if str(candidate.call("resource_item")) != item_id:
			continue
		var d := _player.global_position.distance_squared_to((candidate as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = candidate as Node3D
	return best


func _resolve_bindings() -> void:
	for action: StringName in [&"move_right", &"move_left", &"move_back", &"move_forward"]:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			if not event is InputEventJoypadMotion:
				continue
			var motion := event as InputEventJoypadMotion
			if action == &"move_right":
				_move_x_axis = motion.axis
				_move_x_sign = signf(motion.axis_value)
			elif action == &"move_back":
				_move_y_axis = motion.axis
				_move_y_sign = signf(motion.axis_value)


func _send_stick(x: float, y: float) -> void:
	_parse_axis(_move_x_axis, x * _move_x_sign)
	_parse_axis(_move_y_axis, y * _move_y_sign)


func _parse_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _find(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child: Node in node.get_children():
		var found := _find(child, method)
		if found != null:
			return found
	return null

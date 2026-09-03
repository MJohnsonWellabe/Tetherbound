extends SceneTree

## BRAM-EXIT-0903. Bram lives in `inn_interior.gd`, not `shop_interior.gd` --
## `probe_shop_exit_clearance.gd` only ever probed Mira's cottage, so the
## exit-walk defect CURRENT_STATE.md still lists as open ("Bram's shop exit
## clips furniture") was never actually reproduced by that probe. This one
## targets the real room: six furnished pieces (cabinet, two barrels, two
## guest tables with chair+stool, a bed nook) in a 5.38m x 9.38m interior,
## against the same two questions the shop probe already answered there --
## does the harness's own `_exit_through` shape (regain the door axis, then
## walk the door, then clear it) arrive, and can a real player standing in
## each furniture pocket walk out unaided.
##
##   godot --headless --path . --script tools/gate_f/probe_inn_exit_clearance.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SETTLE_FRAMES := 240

## Door-axis regain, same numbers `gate_a_npc_gather_segment.gd::_exit_through`
## uses for the shop -- this is the shape being tested, not a new one.
const DOOR_STEP_IN := 2.2

## Where Oskar stands -- the leg `_visit_villager` walks after Bram, so the
## direct-line comparison point matches the real route rather than an
## arbitrary target.
const OSKAR := Vector3(22.0, 0.9, -6.0)

var _player: CharacterBody3D = null
var _rig: Node3D = null
var _world: Node = null
var _inn: Node3D = null
var _door: Node3D = null
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("PROBE FAIL: player=%s rig=%s" % [_player, _rig])
		quit(1)
		return
	_inn = _find_by_script("inn_interior.gd")
	if _inn == null:
		print("PROBE FAIL: no inn interior found in the scene")
		quit(1)
		return
	_door = _find_door_on(_inn.get_parent())
	if _door == null:
		print("PROBE FAIL: no village_door.gd found on the inn's building")
		quit(1)
		return
	print("inn interior node: %s at %s" % [_inn.get_path(), str(_inn.global_position)])
	print("door node: %s at %s" % [_door.get_path(), str(_door.global_position)])
	var bar: Vector3 = _inn.call("bar_position")
	print("Bram's bar position: %s -> local %s" % [str(bar), str(_to_local(bar))])
	_door.call("force_open", true)

	await _question_1_exit_walk()
	await _question_2_player_pockets()

	print("")
	if _failures.is_empty():
		print("PROBE RESULT: all questions answered clean")
		quit(0)
		return
	print("PROBE RESULT: %d unresolved" % _failures.size())
	for f in _failures:
		print("  - %s" % f)
	quit(1)


# ---------------------------------------------------------------- question 1


## The exact shape `_exit_through` runs: regain the door's own axis at
## `DOOR_STEP_IN` inside, walk to the door, clear it -- started from Bram's
## own bar position (where dialogue actually ends), which the shop probe's
## equivalent question started from Mira's counter for the same reason.
func _question_1_exit_walk() -> void:
	print("")
	print("=== 1. the exit walk from Bram's bar, both ways ===")
	var outward := _door_outward()
	var step := _door.global_position - outward * DOOR_STEP_IN
	print("  door outward=%s  step point=%s (local %s)" % [str(outward), str(step), str(_to_local(step))])

	print("  -- A: straight at Oskar (no axis regain) --")
	await _place(_inn.call("bar_position"))
	var direct := await _traced_walk(OSKAR, 1200, 3.5)

	print("  -- B: regain door axis, then door, then clear it, then Oskar --")
	await _place(_inn.call("bar_position"))
	var to_axis := await _traced_walk(step, 700, 0.7)
	var to_door := false
	var cleared := false
	if to_axis:
		to_door = await _traced_walk(_door.global_position, 400, 0.65)
	if to_door:
		cleared = await _traced_walk(_door.global_position + outward * 2.4, 500, 0.7)
	var staged := false
	if cleared:
		print("     out of the building at local %s" % str(_to_local(_player.global_position)))
		staged = await _traced_walk(OSKAR, 3000, 3.5)

	print("  A (direct)=%s   B (staged: axis=%s door=%s clear=%s, then Oskar)=%s" \
		% [str(direct), str(to_axis), str(to_door), str(cleared), str(staged)])
	if not staged:
		_failures.append("staged exit walk (regain axis, door, clear, then Oskar) did not arrive")


# ---------------------------------------------------------------- question 2


## A real player, no navigator, holding the stick at the door from each
## furnished pocket in the room -- the interaction points a Bram visit
## actually leaves the player near: the bar/counter, both guest tables, the
## bed nook, and the doorway threshold itself.
func _question_2_player_pockets() -> void:
	print("")
	print("=== 2. can a PLAYER walk out of each furniture pocket unaided? ===")
	var door_world := _door.global_position
	var starts := {
		"behind the bar": _local(0.0, 0.9, -4.39),
		"west guest table (near cabinet)": _local(-1.5, 0.9, 1.5),
		"east guest table (near bed nook)": _local(1.5, 0.9, 1.5),
		"bed nook": _local(1.7, 0.9, -1.7),
		"beside the door barrels": _local(-1.6, 0.9, 3.5),
		"doorway threshold": _local(0.0, 0.9, 4.5),
	}
	for label: String in starts:
		var start: Vector3 = starts[label]
		await _place(start)
		var settled := _player.global_position
		var out := await _hold_stick_toward(door_world, 420)
		var moved := settled.distance_to(_player.global_position)
		var gap := _player.global_position.distance_to(door_world)
		print("  %-38s start_local=%s  moved=%.2fm  final_gap_to_door=%.2fm  cleared=%s"
			% [label, str(_to_local(start).round()), moved, gap, str(out)])
		if not out:
			_failures.append("a player holding the stick at the door could not leave"
				+ " the pocket from: " + label)


# ---------------------------------------------------------------- machinery


func _local(x: float, y: float, z: float) -> Vector3:
	return _to_world(Vector3(x, y, z))


## True once the body is out past the doorway threshold (local z beyond the
## front wall) -- i.e. it can see open air, not just crossed some interior
## line the way the shop probe's `x > -0.9` check did for its own room shape.
func _hold_stick_toward(point: Vector3, frames: int) -> bool:
	for i in frames:
		if _to_local(_player.global_position).z > 4.9:
			_stop()
			return true
		var to := point - _player.global_position
		to.y = 0.0
		_push(to.normalized())
		await physics_frame
	_stop()
	return _to_local(_player.global_position).z > 4.9


func _door_outward() -> Vector3:
	var outward: Vector3 = _door.global_transform.basis.z
	outward.y = 0.0
	var inside: Vector3 = _inn.global_position
	var inward := inside - _door.global_position
	inward.y = 0.0
	if outward.dot(inward) > 0.0:
		outward = -outward
	return outward.normalized()


func _find_door_on(building: Node) -> Node3D:
	var stack: Array[Node] = [building]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var script: Script = node.get_script() as Script
		if script != null and script.resource_path.ends_with("village_door.gd"):
			return node as Node3D
		for child in node.get_children():
			stack.append(child)
	return null


func _find_by_script(suffix: String) -> Node3D:
	var stack: Array[Node] = [_world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var script: Script = node.get_script() as Script
		if script != null and script.resource_path.ends_with(suffix):
			return node as Node3D
		for child in node.get_children():
			stack.append(child)
	return null


func _to_world(local: Vector3) -> Vector3:
	return _inn.global_transform * local


func _to_local(world: Vector3) -> Vector3:
	return _inn.global_transform.affine_inverse() * world


func _place(pos: Vector3) -> void:
	_player.global_position = pos + Vector3.UP * 0.2
	_player.velocity = Vector3.ZERO
	_stop()
	for i in 20:
		await physics_frame


func _navigator() -> RefCounted:
	return NAVIGATOR.new(self, _player, _rig,
		func(x: float, y: float) -> void: _push_stick(x, y))


var _stick := Vector2.ZERO


func _push_stick(x: float, y: float) -> void:
	_stick = Vector2(x, y)
	_drive()


func _traced_walk(target: Vector3, budget: int, close_enough: float) -> bool:
	var nav: RefCounted = _navigator()
	nav.call("reset")
	var walked := 0
	while walked < budget:
		var to := target - _player.global_position
		to.y = 0.0
		if to.length() <= close_enough:
			print("  ARRIVED after %d frames at %s" % [walked, str(_player.global_position)])
			_stop()
			return true
		if not bool(nav.call("can_walk")):
			await physics_frame
			continue
		walked += 1
		await nav.call("step", target)
		if walked % 60 == 0:
			print("  t=%d pos=%s local=%s gap=%.2f" % [walked,
				str(_player.global_position.round()),
				str(_to_local(_player.global_position).round()), to.length()])
	print("  BUDGET EXHAUSTED at %s (local %s, %.2fm short)" % [
		str(_player.global_position), str(_to_local(_player.global_position)),
		(target - _player.global_position).length()])
	_stop()
	return false


func _push(direction: Vector3) -> void:
	var basis: Basis = _rig.call("planar_basis")
	var local := basis.inverse() * direction
	_stick = Vector2(clampf(local.x, -1.0, 1.0), clampf(local.z, -1.0, 1.0))
	_drive()


func _stop() -> void:
	_stick = Vector2.ZERO
	_drive()


func _drive() -> void:
	_press_axis(&"move_right", clampf(_stick.x, 0.0, 1.0))
	_press_axis(&"move_left", clampf(-_stick.x, 0.0, 1.0))
	_press_axis(&"move_back", clampf(_stick.y, 0.0, 1.0))
	_press_axis(&"move_forward", clampf(-_stick.y, 0.0, 1.0))


func _press_axis(action: StringName, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength <= 0.001:
		Input.action_release(action)
	else:
		Input.action_press(action, strength)
	var binding := _physical_binding(action)
	var motion := binding as InputEventJoypadMotion
	if motion == null:
		return
	var m := InputEventJoypadMotion.new()
	m.axis = motion.axis
	m.axis_value = signf(motion.axis_value) * strength
	Input.parse_input_event(m)


func _physical_binding(action: StringName) -> InputEvent:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return event
	return null

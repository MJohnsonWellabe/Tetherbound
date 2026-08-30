extends SceneTree

## T2-GATEF-RUN5: GAME-8 / RIG-23, the exit walk out of Mira's shop.
##
## Three questions in one stand-up, because standing the Meadows up is the
## expensive part and asking them separately costs three times as much:
##
##   1. WHAT DID THE OLD PROBE SEE? Reads clearance out of the wedge point with
##      the one hip-height hairline ray `tests/helpers/stick_navigator.gd` used
##      before this session, and with the nine-ray body sweep that replaced it.
##      If the diagnosis in PROBE_HEIGHTS' own comment is right, the old numbers
##      are a flat 3.0 in both directions (a tie, which the side chooser breaks
##      to +1 -- west, on the way out) and the new ones are not.
##   2. DOES THE EXIT WALK ARRIVE? Drives the real navigator from Mira's counter
##      out past the door and on to Oskar, the exact leg `S03-60` fails.
##   3. CAN A REAL PLAYER GET STUCK THERE? Puts the body in the pocket between
##      the west wall and the stock crates and pushes the stick the way a person
##      would. A harness that cannot get out is a rig bug; a PLAYER who cannot
##      get out is a Meadows the owner must not ship.
##
##   godot --headless --path . --script tools/gate_f/probe_shop_exit_clearance.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SETTLE_FRAMES := 240

## What the navigator used to probe with: one ray, hip height, no width.
const OLD_PROBE_HEIGHT := 1.0
const OLD_PROBE_REACH := 3.0

## Oskar's stance, and the leg S03-60 asks for.
const OSKAR := Vector3(22.0, 0.9, -6.0)

var _stick_left := Vector2.ZERO
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _world: Node = null
var _shop: Node3D = null
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
	_shop = _find_shop()
	if _shop == null:
		print("PROBE FAIL: no shop interior found in the scene")
		quit(1)
		return
	print("shop interior node: %s at %s" % [_shop.get_path(), str(_shop.global_position)])
	print("  local (0,0.9,0)      -> world %s" % str(_to_world(Vector3(0.0, 0.9, 0.0))))
	print("  local (-1.37,0.9,1.2)-> world %s   [the wedge]" % str(_to_world(Vector3(-1.37, 0.9, 1.2))))
	print("  local (1.0,0.9,3.5)  -> world %s   [outside the door]" % str(_to_world(Vector3(1.0, 0.9, 3.5))))

	# S03 opens this door by hand at S03-52a and never closes it again, so every
	# question below is asked of the world the exit walk actually happens in.
	# Left shut, the walk stops dead in the doorway at local (0.95, 2.37) and
	# the reading is about the door, not about the room.
	_open_shop_door()

	await _question_1_clearance()
	await _question_2_exit_walk()
	await _question_3_player_wedge()

	print("")
	if _failures.is_empty():
		print("PROBE RESULT: all three questions answered clean")
		quit(0)
		return
	print("PROBE RESULT: %d unresolved" % _failures.size())
	for f in _failures:
		print("  - %s" % f)
	quit(1)


# ---------------------------------------------------------------- question 1


func _question_1_clearance() -> void:
	print("")
	print("=== 1. clearance out of the wedge: old hairline ray vs new body sweep ===")
	# Stand in the pocket the walker wedges in, facing the way S03-60 sends it.
	await _place(_to_world(Vector3(-1.37, 0.9, 1.2)))
	var to_oskar := OSKAR - _player.global_position
	to_oskar.y = 0.0
	var perpendicular := to_oskar.normalized().cross(Vector3.UP).normalized()
	var nav: RefCounted = _navigator()
	for named: Array in [["+1 (the tie-break default)", 1.0], ["-1", -1.0]]:
		var dir: Vector3 = perpendicular * float(named[1])
		var old_reading := _old_free_space(dir)
		var new_reading: float = nav.call("_free_space", dir)
		print("  side %-24s old=%.2fm  new=%.2fm  world_dir=%s"
			% [named[0], old_reading, new_reading, str(dir.round())])
	if absf(_old_free_space(perpendicular) - _old_free_space(-perpendicular)) > 0.2:
		print("  NOTE: the old probe did NOT tie here; the tie-break story needs revisiting")
	else:
		print("  the old probe TIED (both sides read the same to within 0.2m)"
			+ " -- which is why it always chose +1")


# ---------------------------------------------------------------- question 2


## The two shapes S03 can give the exit, run back to back from the same start.
##
## A: what `S03-60` does today -- one straight leg at Oskar. Oskar is at
##    building-local (-5.66, 0): due WEST of the room, straight through the
##    wall the crates are stacked against. No obstacle-avoidance heuristic can
##    solve that, because the way out is the door at local z=+2.69 and the
##    target is 180 degrees from it.
## B: out through the door FIRST -- `S03-59a`'s own staging point, local
##    (1.0, 4.0), which is OUTSIDE the building -- then on to Oskar.
##    `S03-59a` already asks for this point and still lands inside: its
##    `close_enough` is 2.0m, and the doorway is 1.9m from it.
func _question_2_exit_walk() -> void:
	print("")
	print("=== 2. the exit walk, two ways, from behind Mira's counter ===")
	var staging := _to_world(Vector3(1.0, 0.9, 4.0))
	print("  door staging point local (1,4) = world %s" % str(staging))
	print("  Oskar world %s = local %s" % [str(OSKAR), str(_to_local(OSKAR))])

	print("  -- A: straight at Oskar (today's S03-60) --")
	await _place(_to_world(Vector3(-0.2, 0.9, 0.6)))
	var direct := await _traced_walk(OSKAR, 1200, 3.5)

	print("  -- B: door staging point at 0.8m, then Oskar --")
	await _place(_to_world(Vector3(-0.2, 0.9, 0.6)))
	var out_the_door := await _traced_walk(staging, 1200, 0.8)
	var staged := false
	if out_the_door:
		print("     out of the building at local %s" % str(_to_local(_player.global_position)))
		staged = await _traced_walk(OSKAR, 3000, 3.5)

	print("  A (direct)=%s   B (staged)=%s" % [str(direct), str(staged)])
	if not staged:
		_failures.append("staged exit walk (door point, then Oskar) did not arrive")


# ---------------------------------------------------------------- question 3


## GAME-8's own open question: is the wedge a harness artefact or a hole a real
## player can fall into? Drive the body the way a person does -- stick held at
## the doorway, no detour logic at all -- from the tightest point in the pocket.
func _question_3_player_wedge() -> void:
	print("")
	print("=== 3. can a PLAYER walk out of the wall/crate pocket unaided? ===")
	var door := _to_world(Vector3(1.0, 0.9, 3.5))
	var starts := {
		"deepest, beside the lower crate": Vector3(-1.45, 0.9, 1.5),
		"north of the crates": Vector3(-1.45, 0.9, 2.2),
		"south of the crates, counter behind": Vector3(-1.45, 0.9, 0.4),
		"crate corner": Vector3(-1.5, 0.9, 1.25),
	}
	for label: String in starts:
		var start: Vector3 = _to_world(starts[label] as Vector3)
		await _place(start)
		var settled := _player.global_position
		var out := await _hold_stick_toward(door, 420)
		var moved := settled.distance_to(_player.global_position)
		print("  %-38s start=%s  moved=%.2fm  reached_door_lane=%s"
			% [label, str(settled.round()), moved, str(out)])
		if not out:
			_failures.append("a player holding the stick at the door could not leave"
				+ " the pocket from: " + label)


# ---------------------------------------------------------------- machinery


## Hold the stick straight at `point`, with no navigator and no detour, for
## `frames`. True once the body clears the crates' own z lane and is east of
## them -- i.e. it is back in the open room and can see the door.
func _hold_stick_toward(point: Vector3, frames: int) -> bool:
	for i in frames:
		var local := _to_local(_player.global_position)
		if local.x > -0.9:
			_stop()
			return true
		var to := point - _player.global_position
		to.y = 0.0
		_push(to.normalized())
		await physics_frame
	_stop()
	return _to_local(_player.global_position).x > -0.9


## Open every village door on the shop's own building, the way S03-52a does.
func _open_shop_door() -> void:
	var building: Node = _shop.get_parent()
	var stack: Array[Node] = [building]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.has_method("force_open") and node.has_method("is_open"):
			node.call("force_open", true)
			print("opened door %s (is_open=%s)" % [node.get_path(), str(node.call("is_open"))])
		for child in node.get_children():
			stack.append(child)


func _find_shop() -> Node3D:
	var stack: Array[Node] = [_world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var script: Script = node.get_script() as Script
		if script != null and script.resource_path.ends_with("shop_interior.gd"):
			return node as Node3D
		for child in node.get_children():
			stack.append(child)
	return null


func _to_world(local: Vector3) -> Vector3:
	return _shop.global_transform * local


func _to_local(world: Vector3) -> Vector3:
	return _shop.global_transform.affine_inverse() * world


func _place(pos: Vector3) -> void:
	_player.global_position = pos + Vector3.UP * 0.2
	_player.velocity = Vector3.ZERO
	_stop()
	for i in 20:
		await physics_frame


## The probe `stick_navigator.gd` had before this session: one ray, hip height,
## zero width. Kept here rather than in the navigator so the comparison in
## question 1 is against the real thing and not a paraphrase of it.
func _old_free_space(direction: Vector3) -> float:
	var space := _player.get_world_3d().direct_space_state
	var from := _player.global_position + Vector3.UP * OLD_PROBE_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(from,
		from + direction.normalized() * OLD_PROBE_REACH)
	query.collide_with_areas = false
	query.exclude = [_player.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return OLD_PROBE_REACH
	return from.distance_to(hit.get("position", from) as Vector3)


func _navigator() -> RefCounted:
	return NAVIGATOR.new(self, _player, _rig,
		func(x: float, y: float) -> void: _stick_left = Vector2(x, y); _drive())


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
	_stick_left = Vector2(clampf(local.x, -1.0, 1.0), clampf(local.z, -1.0, 1.0))
	_drive()


func _stop() -> void:
	_stick_left = Vector2.ZERO
	_drive()


func _drive() -> void:
	_press_axis(&"move_right", clampf(_stick_left.x, 0.0, 1.0))
	_press_axis(&"move_left", clampf(-_stick_left.x, 0.0, 1.0))
	_press_axis(&"move_back", clampf(_stick_left.y, 0.0, 1.0))
	_press_axis(&"move_forward", clampf(-_stick_left.y, 0.0, 1.0))


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

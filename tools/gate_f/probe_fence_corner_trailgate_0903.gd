extends SceneTree

## FENCE-CORNER-0903. CI-TRUTH-0903 diagnosed why
## `smoke_gate_b_continuous` fails at
##
##   gather route: controller could not reach authored fiber at (-5.0, 141.0)
##   (stopped 114.6m short)
##
## as `stick_navigator.gd` oscillating in a ~10m band (x -1..-12, z 26-27)
## against `VillageBoundary/FencePanelCollision_10`/`_11` -- the panels either
## side of outline vertex 6 (`data/config/village_boundary.json`, `(0.37,
## 27.23)`), just past TrailGate -- and called it "a harness/geometry
## interaction, not a broken reachability of the authored node itself"
## without driving a real player body at the corner to check. This is that
## check.
##
## THE QUESTION. Outline vertex 5 -- `(11.6, 22.21)`, TrailGate's own WEST
## jamb -- is a REFLEX vertex of the polygon (signed turn cross product
## -26.25, against the polygon's own CCW winding, versus +79.74 at vertex 6):
## the boundary folds inward exactly at the gate's west side, so the village
## INTERIOR still reaches a few metres north of the gate line there before
## the fence proper (the vertex 5->6->7 run) closes it off. A straight line
## from the gate to the fiber node passes 2.2m from vertex 5 and stays
## outside the polygon for its entire 114m -- checked by shoelace/point-in-
## polygon arithmetic against the real `village_boundary.json` points before
## this was written -- so the abstract boundary is not the obstacle on the
## direct line. What the arithmetic cannot answer is whether the REAL built
## fence (panel thickness, the corner guard post's 1.1m half-width, gate leaf
## collision) leaves a human-plausible walk enough room, and whether a player
## who ends up in the exact pocket the navigator got stuck in (unlike the
## navigator, without its stall/detour machinery) can still get out by
## holding the stick at the target and letting ordinary `move_and_slide`
## resolve it.
##
## METHOD. No `stick_navigator.gd` here -- deliberately. Each case below
## places the player at a real position (queried from the live TrailGate
## node, or the navigator's own logged trap coordinates) and holds the stick
## AT THE TARGET the whole time, the same "no navigator" shape
## `probe_inn_exit_clearance.gd`'s question 2 uses to test whether a human
## just walking toward the door -- not an algorithm -- can clear a room.
## Ordinary `CharacterBody3D.move_and_slide` still slides along whatever it
## grazes; what it will not do is choose to walk sideways on purpose. If that
## is enough to clear the corner from every one of these starts, the corner
## is a harness defect (b): `stick_navigator.gd`'s own stall-then-detour
## logic, not the world, put the walker in the pocket and then could not
## back itself out because progress is measured as straight-line closing
## distance on a target 114m away, and a sideways slide along a
## perpendicular fence barely moves that number. If even the on-axis,
## straight-out-the-gate case cannot clear it, that is (a): a world defect
## in the corner guard's own geometry.
##
##   godot --headless --path . --script tools/gate_f/probe_fence_corner_trailgate_0903.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const VILLAGE_BOUNDARY := preload("res://scripts/world/village_boundary.gd")
const HARVEST_NODE_SCRIPT := "res://scripts/world/harvest_node.gd"
const SETTLE_FRAMES := 300
const TARGET_AT_XZ := Vector2(-5.0, 141.0)
## Close enough that "arrived" means "would go on to actually harvest it",
## the same number `_probe_gather_route_fiber_141_0903.gd` uses.
const CLOSE_ENOUGH := 1.65
## 100s at 60fps -- the navigator itself burned 133s oscillating without
## covering the ~114m that remained; a plain hold that is going to clear the
## corner shows unmistakable progress well inside this, and one that is
## truly stuck reads the same as the navigator's own trace did.
const BUDGET_FRAMES := 6000

var _player: CharacterBody3D
var _rig: Node3D
var _world: Node3D
var _target: Node3D
var _gate: Node3D
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for _i in SETTLE_FRAMES:
		await physics_frame

	_player = _find(_world, "locomotion_enabled") as CharacterBody3D
	_rig = _find(_world, "planar_basis") as Node3D
	if _player == null or _rig == null:
		print("PROBE FAIL: player=%s rig=%s" % [_player, _rig])
		quit(1)
		return

	_gate = _find_named(_world, "TrailGate")
	if _gate == null:
		print("PROBE FAIL: no TrailGate node in the built scene")
		quit(1)
		return
	_gate.call("open_permanently")
	var game := root.get_node_or_null(^"/root/Game")
	if game != null:
		var progression: RefCounted = game.get("progression")
		if progression != null:
			progression.call("set_flag", "road_gate_open", true)
	print("TrailGate at %s (opened directly, no key hunt -- geometry only)" % str(_gate.global_position))

	_target = _fiber_node_near(TARGET_AT_XZ)
	if _target == null:
		print("PROBE FAIL: no fiber harvest_node.gd found near %s" % str(TARGET_AT_XZ))
		quit(1)
		return
	print("fiber target '%s' at %s" % [_target.name, str(_target.global_position.round())])
	print("")

	var gate_xz := Vector2(_gate.global_position.x, _gate.global_position.z)
	# Which way is "outward"? Don't assume a basis convention -- ask the real
	# outline the same question `village_boundary.gd::contains()` answers for
	# the game itself: try local +Z first, and if that reads as still INSIDE
	# the settlement, it is the reflex-vertex peninsula this probe exists
	# because of, so use -Z instead.
	var outline_points := VILLAGE_BOUNDARY.outline(VILLAGE_BOUNDARY.load_config())
	var probe_z := gate_xz + Vector2(0.0, 3.0)
	var outward := Vector3(0.0, 0.0, 1.0)
	if VILLAGE_BOUNDARY.contains(outline_points, probe_z):
		outward = Vector3(0.0, 0.0, -1.0)
	print("outward direction from the gate resolved to %s (checked against the live outline)" % str(outward))

	# ---- Case set A: approach headings AT THE GATE, on-axis and offset either
	# side of it by a few metres -- what a player who walked up to TrailGate
	# from slightly different angles is actually standing at the moment they
	# clear the leaf.
	var side: Vector3 = outward.cross(Vector3.UP).normalized()
	var cases: Array[Dictionary] = []
	cases.append({"label": "on-axis, 1.5m past the gate", "at": Vector2(gate_xz.x, gate_xz.y) + Vector2(outward.x, outward.z) * 1.5})
	cases.append({"label": "2.5m past the gate, 2m toward the west jamb", "at": Vector2(gate_xz.x, gate_xz.y) + Vector2(outward.x, outward.z) * 2.5 + Vector2(side.x, side.z) * -2.0})
	cases.append({"label": "2.5m past the gate, 2m toward the east jamb", "at": Vector2(gate_xz.x, gate_xz.y) + Vector2(outward.x, outward.z) * 2.5 + Vector2(side.x, side.z) * 2.0})
	cases.append({"label": "4m past the gate, hugging the west jamb (4m)", "at": Vector2(gate_xz.x, gate_xz.y) + Vector2(outward.x, outward.z) * 4.0 + Vector2(side.x, side.z) * -4.0})

	# ---- Case set B: the EXACT trap the navigator logged, so this probe
	# checks the pocket itself, not just a cleaner line into it.
	# `_probe_gather_route_fiber_141_0903.gd`'s own trace oscillated inside
	# x -1..-12, z 26-27 for the rest of its budget; these are real logged
	# positions from that band.
	cases.append({"label": "navigator's own trap coordinate (-1, 26)", "at": Vector2(-1.0, 26.0)})
	cases.append({"label": "navigator's own trap coordinate (-8, 26)", "at": Vector2(-8.0, 26.0)})
	cases.append({"label": "navigator's own trap coordinate (-12, 26)", "at": Vector2(-12.0, 26.0)})

	print("=== plain stick-hold at the fiber target, no navigator, from each start ===")
	for c: Dictionary in cases:
		var at: Vector2 = c["at"]
		var g := _ground(at.x, at.y)
		if is_nan(g):
			print("  %-46s -- SKIP, no ground at %s" % [c["label"], str(at)])
			continue
		_player.global_position = Vector3(at.x, g + 1.0, at.y)
		_player.velocity = Vector3.ZERO
		_stop()
		for _i in 20:
			await physics_frame
		var start := _player.global_position
		var arrived := await _hold_toward(_target.global_position, BUDGET_FRAMES, c["label"])
		var final_gap := Vector2(_target.global_position.x - _player.global_position.x,
			_target.global_position.z - _player.global_position.z).length()
		print("  %-46s start=%s  arrived=%s  final_gap=%.1fm  final_pos=%s" % [
			c["label"], str(start.round()), str(arrived), final_gap, str(_player.global_position.round())])
		if not arrived:
			_failures.append(c["label"])

	print("")
	if _failures.is_empty():
		print("PROBE VERDICT: (b) HARNESS DEFECT -- every human-plausible start, plain stick-hold at the")
		print("  target with no navigator, cleared the corner via ordinary move_and_slide. The corner is")
		print("  round-able; stick_navigator.gd's own detour/stall logic is what got stuck, not the world.")
		quit(0)
	else:
		print("PROBE VERDICT: %d of %d starts could NOT clear the corner with a plain stick-hold:" % [_failures.size(), cases.size()])
		for f in _failures:
			print("  - %s" % f)
		print("  If the on-axis case is among them, this reads as (a) a world defect in the corner")
		print("  guard/gate siting, not a harness defect.")
		quit(1)


## Hold the stick toward `point` every frame, no stall/detour logic at all --
## pure `move_and_slide` deciding what a straight push resolves to. Reports
## progress once a second the same way the CI-TRUTH probe did, so a stuck
## case is legible without re-running anything.
func _hold_toward(point: Vector3, budget: int, label: String) -> bool:
	var last_report_sec := -1
	for frame in budget:
		var to := point - _player.global_position
		to.y = 0.0
		var gap := to.length()
		if gap <= CLOSE_ENOUGH:
			_stop()
			return true
		_push(to.normalized())
		await physics_frame
		var elapsed_sec := int(float(frame) / 60.0)
		if elapsed_sec != last_report_sec and elapsed_sec % 10 == 0:
			last_report_sec = elapsed_sec
			print("    [%s] t=%3ds pos=%s gap=%.1f" % [label, elapsed_sec, str(_player.global_position.round()), gap])
	_stop()
	return false


func _ground(x: float, z: float) -> float:
	if not _world.has_method("ground_height_at"):
		return NAN
	return float(_world.call("ground_height_at", x, z))


func _fiber_node_near(at: Vector2) -> Node3D:
	var nearest: Node3D = null
	var distance := INF
	for node: Node in get_nodes_in_group("harvestable"):
		if not node is Node3D or not node.has_method("resource_item"):
			continue
		var script := node.get_script() as Script
		if script == null or script.resource_path != HARVEST_NODE_SCRIPT:
			continue
		if str(node.call("resource_item")) != "fiber":
			continue
		var gap := Vector2((node as Node3D).global_position.x - at.x,
			(node as Node3D).global_position.z - at.y).length()
		if gap < distance:
			distance = gap
			nearest = node as Node3D
	return nearest


func _find_named(node: Node, target_name: String) -> Node3D:
	if node.name == target_name:
		return node as Node3D
	for child: Node in node.get_children():
		var found := _find_named(child, target_name)
		if found != null:
			return found
	return null


func _find(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child: Node in node.get_children():
		var found := _find(child, method)
		if found != null:
			return found
	return null


var _move_x_axis := JOY_AXIS_LEFT_X
var _move_y_axis := JOY_AXIS_LEFT_Y
var _move_x_sign := 1.0
var _move_y_sign := 1.0
var _bindings_resolved := false


## Read the real sign each axis carries from the live InputMap, the same way
## `_probe_gather_route_fiber_141_0903.gd::_resolve_bindings` does, rather
## than assume a convention -- `project.godot` has move_forward on axis 1 at
## -1.0, and guessing wrong here would silently invert every push below.
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
	_bindings_resolved = true


func _push(direction: Vector3) -> void:
	if not _bindings_resolved:
		_resolve_bindings()
	var basis: Basis = _rig.call("planar_basis")
	var local := basis.inverse() * direction
	_parse_axis(_move_x_axis, clampf(local.x, -1.0, 1.0) * _move_x_sign)
	_parse_axis(_move_y_axis, clampf(local.z, -1.0, 1.0) * _move_y_sign)


func _stop() -> void:
	if not _bindings_resolved:
		_resolve_bindings()
	_parse_axis(_move_x_axis, 0.0)
	_parse_axis(_move_y_axis, 0.0)


func _parse_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)

extends SceneTree

## CI-TRUTH-0903. Why `tests/smoke_gate_b_continuous.gd` fails at
##
##   gather route: controller could not reach authored fiber at (-5.0, 141.0)
##   (stopped 114.6m short)
##
## `gate_a_material_route.gd::AUTHORED_ROUTE` calls this stop "deliberately on
## ordinary open-spine travel" -- the previous stop is fiber at (30.0, -8.0),
## so the leg the walker actually attempts is (30,-8) -> (-5,141), a ~153m
## diagonal. World lanes landed today (MID-LAYER and friends) added scatter
## along Band 1's spine, and CURRENT_STATE.md records the open question as
## "an unreachable node, a walker that gives up too early, or congestion".
##
## This spawns the real world, stands the player at the real previous-stop
## position, and walks the same leg `stick_navigator.gd` walks -- logging
## position, navigator internals (stall/detour/side) and what is directly
## ahead once a second, so the answer comes from the built scene rather than
## from geometry worked out on paper. Does NOT touch vegetation/scatter data;
## read-only investigation per CI-TRUTH-0903's scope.
##
##   godot --headless --path . --script tools/_probe_gather_route_fiber_141_0903.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const FROM_AT := Vector2(30.0, -8.0)
const TARGET_AT := Vector2(-5.0, 141.0)
const HARVEST_NODE_SCRIPT := "res://scripts/world/harvest_node.gd"
const VEGETATION_POINT_SCRIPT := "res://scripts/world/vegetation_harvest_point.gd"
const SETTLE_FRAMES := 300

var _world: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _move_x_axis := JOY_AXIS_LEFT_X
var _move_y_axis := JOY_AXIS_LEFT_Y
var _move_x_sign := 1.0
var _move_y_sign := 1.0


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
		print("PROBE: missing player/rig")
		quit(1)
		return
	_resolve_bindings()

	var target := _fiber_node_at(TARGET_AT)
	if target == null:
		print("PROBE: no harvest_node.gd for fiber found near %s" % str(TARGET_AT))
		_dump_terrain_profile()
		quit(1)
		return
	print("PROBE: fiber node '%s' resolved at %s" % [target.name, str(target.global_position.round())])

	var ground := ground_height_at(FROM_AT.x, FROM_AT.y)
	if is_nan(ground):
		print("PROBE: no ground under the previous stop at %s" % str(FROM_AT))
		quit(1)
		return
	_player.global_position = Vector3(FROM_AT.x, ground + 1.0, FROM_AT.y)
	_player.velocity = Vector3.ZERO
	for _i in 30:
		await physics_frame

	var start := _player.global_position
	var to := target.global_position - start
	print("PROBE leg: (30,-8) %s -> fiber node %s | horizontal %.1fm | rise %.2fm" % [
		str(start.round()), str(target.global_position.round()),
		Vector2(to.x, to.z).length(), to.y])

	var nav = NAVIGATOR.new(self, _player, _rig, Callable(self, "_send_stick"))
	nav.reset()
	var budget := 240 + int(start.distance_to(target.global_position) * 60.0)
	print("PROBE budget %d frames (%.1fs)" % [budget, budget / 60.0])

	var best := INF
	var last := start
	var last_report_sec := -1
	var elapsed_sec := 0.0
	var side_flip_count := 0
	var last_side := 0.0
	for frame in budget:
		var gap_v := target.global_position - _player.global_position
		gap_v.y = 0.0
		var gap := gap_v.length()
		best = minf(best, gap)
		if gap <= 1.65:
			print("PROBE ARRIVED at frame %d (%.1fs)" % [frame, elapsed_sec])
			_dump_result(true, gap, best)
			quit(0)
			return
		elapsed_sec = float(frame) / 60.0
		var cur_side: float = float(nav.get("_side"))
		if cur_side != last_side:
			side_flip_count += 1
			last_side = cur_side
		var this_sec := int(elapsed_sec)
		if this_sec != last_report_sec:
			last_report_sec = this_sec
			var moved := _player.global_position.distance_to(last)
			last = _player.global_position
			var ahead := _what_is_ahead(target.global_position)
			print(("  t=%3ds pos %-24s gap %6.1f best %6.1f | navgap %6.1f stall %2d "
				+ "detourleft %3d side %+0.0f flips %3d | moved/1s %.2f vel %.2f floor %s | ahead: %s") % [
				this_sec, str(_player.global_position.round()), gap, best,
				float(nav.get("_gap")), int(nav.get("_stall")),
				int(nav.get("_detour_left")), cur_side, side_flip_count,
				moved, Vector2(_player.velocity.x, _player.velocity.z).length(),
				str(_player.is_on_floor()), ahead])
		await nav.step(target.global_position)
	_send_stick(0.0, 0.0)
	var final_gap := Vector2(target.global_position.x - _player.global_position.x,
		target.global_position.z - _player.global_position.z).length()
	print("PROBE end: NOT ARRIVED. gap %.1f (best %.1f), stopped at %s, %d side flips" % [
		final_gap, best, str(_player.global_position.round()), side_flip_count])
	_dump_result(false, final_gap, best)
	quit(0)


## What is directly ahead, and what harvestable scatter sits within 8m of the
## player right now -- a dense cluster is what "congestion" would look like.
func _what_is_ahead(target: Vector3) -> String:
	var world3d := _player.get_world_3d()
	var space := world3d.direct_space_state if world3d != null else null
	if space == null:
		return "<no space state>"
	var from := _player.global_position + Vector3.UP * 0.9
	var dir := target - _player.global_position
	dir.y = 0.0
	if dir.length() < 0.01:
		return "<at target>"
	dir = dir.normalized()
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 6.0)
	query.collide_with_areas = false
	if _player is CollisionObject3D:
		query.exclude = [(_player as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	var ahead_str := "clear 6m ahead"
	if not hit.is_empty():
		var collider: Variant = hit.get("collider")
		var where: Vector3 = hit.get("position", Vector3.ZERO)
		var name := "<?>"
		if collider is Node:
			var parent := (collider as Node).get_parent()
			name = "%s/%s" % [str(parent.name) if parent != null else "?", str((collider as Node).name)]
		ahead_str = "%s at (%.1f,%.1f,%.1f), %.1fm away" % [
			name, where.x, where.y, where.z, from.distance_to(where)]
	var nearby := 0
	for node: Node in get_nodes_in_group("harvestable"):
		if not node is Node3D:
			continue
		if (node as Node3D).global_position.distance_to(_player.global_position) <= 8.0:
			nearby += 1
	return "%s | %d harvestable within 8m" % [ahead_str, nearby]


func _dump_result(arrived: bool, final_gap: float, best_gap: float) -> void:
	print("")
	print("PROBE VERDICT: arrived=%s final_gap=%.1f best_gap=%.1f" % [str(arrived), final_gap, best_gap])
	_dump_terrain_profile()
	print("")
	print("PROBE scatter density along the straight line (harvestable count within 4m of 11 sample points):")
	var from3 := Vector3(FROM_AT.x, 0.0, FROM_AT.y)
	var to3 := Vector3(TARGET_AT.x, 0.0, TARGET_AT.y)
	var all_harvestable: Array[Node3D] = []
	for node: Node in get_nodes_in_group("harvestable"):
		if node is Node3D:
			all_harvestable.append(node as Node3D)
	for i in 11:
		var p: Vector3 = from3.lerp(to3, float(i) / 10.0)
		var count := 0
		for node: Node3D in all_harvestable:
			var flat := Vector2(node.global_position.x - p.x, node.global_position.z - p.z)
			if flat.length() <= 4.0:
				count += 1
		print("  sample %2d at (%.1f,%.1f): %d harvestable within 4m" % [i, p.x, p.z, count])


func _dump_terrain_profile() -> void:
	print("")
	print("PROBE terrain profile along the straight (30,-8) -> (-5,141) line:")
	var terrain := get_first_node_in_group(&"terrain")
	var from3 := Vector3(FROM_AT.x, 0.0, FROM_AT.y)
	var to3 := Vector3(TARGET_AT.x, 0.0, TARGET_AT.y)
	if terrain != null and terrain.has_method("ground_height_at"):
		var line := ""
		for i in 21:
			var p: Vector3 = from3.lerp(to3, float(i) / 20.0)
			line += "%.1f " % float(terrain.call("ground_height_at", p.x, p.z))
		print("  " + line)
	else:
		print("  no terrain node in group 'terrain'")


func ground_height_at(x: float, z: float) -> float:
	if not _world.has_method("ground_height_at"):
		return NAN
	return float(_world.call("ground_height_at", x, z))


func _fiber_node_at(at: Vector2) -> Node3D:
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

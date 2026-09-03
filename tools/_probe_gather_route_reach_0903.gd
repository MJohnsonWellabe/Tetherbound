extends SceneTree

## GATHER-ROUTE-0903. Why `tests/smoke_gate_b_continuous.gd` fails at
##
##   gather route: controller could not reach authored wood at (16.0, -28.0)
##   (stopped 22.9m short)
##
## The real run's own transcript (captured before this probe was written)
## shows the leg that fails is NOT the walk out of the village -- it is the
## walk from the RoadGate, immediately after the route takes the key and
## opens it for real:
##
##   gather route | took the old key at (30.7, -15.9)
##   gather route | unlocked the road gate with the old key
##   gate B continuous FAIL: gather route: controller could not reach
##   authored wood at (16.0, -28.0) (stopped 22.9m short)
##
## `village_boundary.json`'s RoadGate sits at (38.72, -19.85); the wood node
## is 24.1m away in a straight line. `data/config/village.json` authors TWO
## `fence_run` panels "along the practice-meadow path" at (14,-20) and
## (19.5,-25.5), both yaw 55 -- a combined ~11m run with only a ~2m seam
## between them -- and that run crosses the RoadGate -> wood-node straight
## line (checked by segment intersection against the panels' own collider
## geometry in `data/config/building_prefabs.json`, not eyeballed).
##
## This spawns the world, teleports the player to the RoadGate (the real
## post-unlock position, not a guess), and walks the same leg
## `gate_a_material_route.gd` walks, logging position, navigator internals
## and what is directly ahead of the player once a second -- so the
## question "authored node unreachable" vs "walker can't get around a
## finite fence" is answered from the real built scene, not from geometry
## worked out on paper.
##
##   godot --headless --path . --script tools/_probe_gather_route_reach_0903.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const ROAD_GATE_AT := Vector2(38.72, -19.85)
const WOOD_NODE_AT := Vector2(16.0, -28.0)
const HARVEST_NODE_SCRIPT := "res://scripts/world/harvest_node.gd"
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

	var target := _wood_node_at(WOOD_NODE_AT)
	if target == null:
		print("PROBE: no harvest_node.gd found near %s" % str(WOOD_NODE_AT))
		quit(1)
		return
	print("PROBE: wood node '%s' resolved at %s" % [target.name, str(target.global_position.round())])

	# Teleport to the RoadGate -- the real position the material route is
	# standing at the moment it starts this leg, per the captured transcript
	# ("unlocked the road gate with the old key" is the line immediately
	# before the failure).
	var ground := ground_height_at(ROAD_GATE_AT.x, ROAD_GATE_AT.y)
	if is_nan(ground):
		print("PROBE: no ground under the RoadGate at %s" % str(ROAD_GATE_AT))
		quit(1)
		return
	_player.global_position = Vector3(ROAD_GATE_AT.x, ground + 1.0, ROAD_GATE_AT.y)
	_player.velocity = Vector3.ZERO
	for _i in 30:
		await physics_frame

	var start := _player.global_position
	var to := target.global_position - start
	print("PROBE leg: RoadGate %s -> wood node %s | horizontal %.1fm | rise %.2fm" % [
		str(start.round()), str(target.global_position.round()),
		Vector2(to.x, to.z).length(), to.y])

	var nav = NAVIGATOR.new(self, _player, _rig, Callable(self, "_send_stick"))
	nav.reset()
	var budget := 240 + int(start.distance_to(target.global_position) * 60.0)
	print("PROBE budget %d frames" % budget)

	var best := INF
	var last := start
	var last_report_sec := -1
	var elapsed_sec := 0.0
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
		var this_sec := int(elapsed_sec)
		if this_sec != last_report_sec:
			last_report_sec = this_sec
			var moved := _player.global_position.distance_to(last)
			last = _player.global_position
			var ahead := _what_is_ahead(target.global_position)
			print(("  t=%3ds pos %-24s gap %6.1f best %6.1f | navgap %6.1f stall %2d "
				+ "detourleft %3d side %+0.0f | moved/1s %.2f vel %.2f floor %s | ahead: %s") % [
				this_sec, str(_player.global_position.round()), gap, best,
				float(nav.get("_gap")), int(nav.get("_stall")),
				int(nav.get("_detour_left")), float(nav.get("_side")),
				moved, Vector2(_player.velocity.x, _player.velocity.z).length(),
				str(_player.is_on_floor()), ahead])
		await nav.step(target.global_position)
	_send_stick(0.0, 0.0)
	var final_gap := Vector2(target.global_position.x - _player.global_position.x,
		target.global_position.z - _player.global_position.z).length()
	print("PROBE end: NOT ARRIVED. gap %.1f (best %.1f), stopped at %s" % [
		final_gap, best, str(_player.global_position.round())])
	_dump_result(false, final_gap, best)
	quit(0)


## Walk the terrain height and, separately, whatever solid body a straight
## ray from the player toward the target hits first -- the fence panels are
## thin (0.16m) StaticBody3D slabs, easy to miss on a coarse terrain-only
## profile.
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
	if hit.is_empty():
		return "clear 6m ahead"
	var collider: Variant = hit.get("collider")
	var where: Vector3 = hit.get("position", Vector3.ZERO)
	var name := "<?>"
	if collider is Node:
		var parent := (collider as Node).get_parent()
		name = "%s/%s" % [str(parent.name) if parent != null else "?", str((collider as Node).name)]
	return "%s at (%.1f,%.1f,%.1f), %.1fm away" % [
		name, where.x, where.y, where.z, from.distance_to(where)]


func _dump_result(arrived: bool, final_gap: float, best_gap: float) -> void:
	print("")
	print("PROBE VERDICT: arrived=%s final_gap=%.1f best_gap=%.1f" % [str(arrived), final_gap, best_gap])
	print("")
	print("PROBE terrain profile along the straight RoadGate -> wood-node line:")
	var terrain := get_first_node_in_group(&"terrain")
	var gate_pos := Vector3(ROAD_GATE_AT.x, 0.0, ROAD_GATE_AT.y)
	var node_pos := Vector3(WOOD_NODE_AT.x, 0.0, WOOD_NODE_AT.y)
	if terrain != null and terrain.has_method("ground_height_at"):
		var line := ""
		for i in 21:
			var p: Vector3 = gate_pos.lerp(node_pos, float(i) / 20.0)
			line += "%.1f " % float(terrain.call("ground_height_at", p.x, p.z))
		print("  " + line)
	else:
		print("  no terrain node in group 'terrain'")

	print("")
	print("PROBE fence_run bodies within 15m of the straight line's midpoint:")
	var mid := gate_pos.lerp(node_pos, 0.5)
	for node: Node in _descendants(_world):
		if not node is StaticBody3D:
			continue
		var n := node as StaticBody3D
		if not str(n.name).begins_with("Fence") and not str(n.name).to_lower().contains("fence"):
			continue
		var d := Vector2(n.global_position.x, n.global_position.z).distance_to(Vector2(mid.x, mid.z))
		if d <= 15.0:
			print("  %s at %s, %.1fm from midpoint" % [n.name, str(n.global_position.round()), d])


func ground_height_at(x: float, z: float) -> float:
	if not _world.has_method("ground_height_at"):
		return NAN
	return float(_world.call("ground_height_at", x, z))


func _wood_node_at(at: Vector2) -> Node3D:
	var nearest: Node3D = null
	var distance := INF
	for node: Node in get_nodes_in_group("harvestable"):
		if not node is Node3D or not node.has_method("resource_item"):
			continue
		var script := node.get_script() as Script
		if script == null or script.resource_path != HARVEST_NODE_SCRIPT:
			continue
		if str(node.call("resource_item")) != "wood":
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


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child: Node in node.get_children():
		out.append_array(_descendants(child))
	return out

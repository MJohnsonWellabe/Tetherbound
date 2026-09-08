extends "res://tests/helpers/gate_a_material_route.gd"

## Gather the current catalogue's actual campsite cost: the authored first
## camp in lesson mode, otherwise one bed per entrant. No inventory grant.
const CAMP := preload("res://tests/helpers/meadows_earned_camp_segment.gd")
const BOUNDARY := preload("res://tests/helpers/meadows_earned_team_segment.gd")
var _boundary: RefCounted
var _crossing: Dictionary = {}


func run(tree: SceneTree, world: Node3D, game: Node, player: CharacterBody3D,
		camera_rig: Node3D, lesson_mode: bool = false) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = camera_rig
	if bool(game.get("free_build")):
		_fail("earned material gathering requires paid build costs")
		return _result()
	_arbiter = tree.get_first_node_in_group(&"interaction_arbiter")
	if _arbiter == null or not _resolve_move_bindings() or not _verify_tool_hotbar():
		_fail("earned material route lacks its production input dependencies")
		return _result()
	_nav = NAVIGATOR.new(_tree, _player, _rig, _send_stick)
	_boundary = BOUNDARY.new()
	_boundary._world = _world
	_boundary._player = _player
	var terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	for crossing: Dictionary in terrain.get("crossings", []):
		if str(crossing.get("id", "")) == "south_bridge":
			_crossing = crossing
	var needed := CAMP.required_stock(game, lesson_mode)
	for item: String in needed:
		if not TOOL_ID.has(item):
			_fail("campsite now requires an unimplemented gathering verb: " + item)
			return _result()
		for _stop in 64:
			if _count(item) >= int(needed[item]):
				break
			var node := _nearest_supply(item)
			if node == null:
				_fail("no live %s supply remains for the campsite (%d/%d)" % [item, _count(item), needed[item]])
				return _result()
			var at := node.global_position
			var authored := (node.get_script() as Script).resource_path == HARVEST_NODE_PATH
			var before := _count(item)
			print("EARNED CAMP MATERIAL target=", node.get_path(), " at=", at, " player=", _player.global_position)
			if not await _walk_supply(node, _travel_budget(at)) \
					and _player.global_position.distance_to(at) > WITHIN_REACH:
				_fail("ordinary material walk stopped short of %s at %s" % [item, at])
				return _result()
			if not await _harvest_node(node, item, authored):
				return _result()
			if _count(item) <= before:
				_fail("real %s harvest produced no receipt" % item)
				return _result()
			var receipt := "earned %s +%d at %s, stock %d/%d" % [
				item, _count(item) - before, at, _count(item), needed[item]]
			transcript.append(receipt)
			print("EARNED CAMP MATERIAL — ", receipt)
		if _count(item) < int(needed[item]):
			_fail("64 physical harvests did not fund campsite " + item)
			return _result()
	transcript.append("actual campsite catalogue cost funded: " + str(needed))
	var patch: Vector2 = CAMP.BUILD_PATCH_XZ
	var destination := Vector3(patch.x, _world.ground_height_at(patch.x, patch.y), patch.y)
	if not await _walk_target(destination, _travel_budget(destination)):
		_fail("earned campsite supply could not return through the actual village gate to the build patch")
		return _result()
	transcript.append("carried actual materials back to the campsite build patch")
	return _result()


func _nearest_supply(item: String) -> Node3D:
	var nearest: Node3D = null
	var distance := INF
	for candidate: Node in _tree.get_nodes_in_group(&"harvestable"):
		if not candidate is Node3D or not candidate.has_method("resource_item"):
			continue
		var script := candidate.get_script() as Script
		if script == null or script.resource_path not in [HARVEST_NODE_PATH, VEGETATION_POINT_PATH]:
			continue
		if not candidate.is_inside_tree() or candidate.is_queued_for_deletion():
			continue
		if str(candidate.call("resource_item")) != item:
			continue
		if script.resource_path == HARVEST_NODE_PATH and not _is_unspent(candidate):
			continue
		if absf(candidate.global_position.y - _player.global_position.y) > WALKABLE_RISE:
			continue
		var bridge := _world.get_node_or_null("SouthBridge")
		if bridge == null or (not bool(bridge.call("is_open")) and not before_crossing(candidate.global_position, _crossing)):
			continue
		var route: Dictionary = _boundary._boundary_approach(candidate)
		if bool(route.required) and (route.points as Array).is_empty():
			continue
		var gap := _player.global_position.distance_squared_to(candidate.global_position)
		if gap < distance:
			distance = gap
			nearest = candidate
	return nearest


static func before_crossing(at: Vector3, crossing: Dictionary) -> bool:
	var carve: Dictionary = crossing.get("carve", {})
	var raw: Array = carve.get("centre", [])
	var road: Array = crossing.get("road", [])
	if raw.size() != 2 or road.is_empty():
		return false
	var centre := Vector2(raw[0], raw[1])
	var axis := deg_to_rad(float(carve.get("axis_deg", 0.0)))
	var across := Vector2(-sin(axis), cos(axis))
	var near := Vector2(road[0][0], road[0][1]) - centre
	var signed_gap := (Vector2(at.x, at.z) - centre).dot(across) * signf(near.dot(across))
	return signed_gap > float(carve.get("half_width", 0.0)) + float(carve.get("rim", 0.0))


func _walk_supply(node: Node3D, budget: int) -> bool:
	return await _walk_target(node.global_position, budget)


func _clear_a_statement_off_the_button() -> bool:
	# The normal Call out / Put away hint has priority -1/-2. It is the
	# fallback when a harvest offer is out of reach or occluded, not a
	# lockout that recalling can clear. Continue the existing physical
	# approach in that case; retain recall for the priority-100 fainted line.
	var offer: Dictionary = _arbiter.call("winner")
	if int(offer.get("priority", 0)) <= 0:
		return false
	return await super._clear_a_statement_off_the_button()


func _walk_target(target: Vector3, budget: int) -> bool:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BOUNDARY.BOUNDARY_CONFIG))
	var open_ids: Array[String] = []
	for entry: Dictionary in (config.get("gates", {}) as Dictionary).get("entries", []):
		var id := str(entry.get("id", ""))
		if _boundary._open_boundary_gate(id):
			open_ids.append(id)
	var route := BOUNDARY.boundary_approach(config, Vector2(_player.global_position.x, _player.global_position.z),
		Vector2(target.x, target.z), open_ids)
	if bool(route.required) and (route.points as Array).is_empty():
		return false
	var points: Array[Vector3] = []
	for at: Vector2 in route.points:
		points.append(Vector3(at.x, _world.ground_height_at(at.x, at.y), at.y))
	points.append(target)
	var started := Engine.get_physics_frames()
	for index in points.size():
		if str(route.gate) != "" and not _boundary._open_boundary_gate(str(route.gate)):
			return false
		var remaining := budget - int(Engine.get_physics_frames() - started)
		if remaining <= 0:
			return false
		# Retain the navigator's held-input and confined-detour recovery. The
		# original total budget covers every gate waypoint, including held time.
		var tolerance := 1.65 if index == points.size() - 1 else 1.0
		if not await _walk_to(points[index], tolerance, remaining):
			return false
	return Engine.get_physics_frames() - started <= budget \
		and (str(route.gate) == "" or _boundary._open_boundary_gate(str(route.gate)))

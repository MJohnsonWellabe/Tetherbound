extends "res://tests/helpers/gate_a_material_route.gd"

## Gather the current catalogue's actual campsite cost: the authored first
## camp in lesson mode, otherwise one bed per entrant. No inventory grant.
const CAMP := preload("res://tests/helpers/meadows_earned_camp_segment.gd")
const BOUNDARY := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const RENEWABLE_SITES := preload("res://scripts/world/renewable_site_catalog.gd")
var _boundary: RefCounted
var _crossing: Dictionary = {}
## Optional absolute stock targets for a paid homestead trip. Empty keeps the
## existing campsite bill. The route still earns every missing item in-world.
var stock_override: Dictionary = {}
## A finite point returns materials to the caller; INF keeps the camp default.
var return_to := Vector3.INF


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
	var needed := CAMP.required_stock(game, lesson_mode) if stock_override.is_empty() else stock_override.duplicate()
	for item: String in needed:
		var tool := str(_game.get("items").call("gathered_with", item))
		if not (_game.get("items").call("ids") as Array).has(item) or tool not in ["", "axe", "pickaxe", "knife"] \
				or not (needed[item] is int or needed[item] is float) or not is_finite(float(needed[item])) \
				or float(needed[item]) < 0.0 or float(needed[item]) != floorf(float(needed[item])):
			_fail("earned stock target has an unsupported item, tool or quantity: " + item)
			return _result()
		var refused: Array[int] = []
		var refusals_in_a_row := 0
		for _stop in 64:
			if _count(item) >= int(needed[item]):
				break
			var node := _nearest_supply(item, refused)
			if node == null:
				_fail("no live %s supply remains for the campsite (%d/%d)" % [item, _count(item), needed[item]])
				return _result()
			var node_id := node.get_instance_id()
			var at := node.global_position
			var authored := (node.get_script() as Script).resource_path == HARVEST_NODE_PATH
			var before := _count(item)
			var failures_before := failures.size()
			print("EARNED CAMP MATERIAL target=", node.get_path(), " at=", at, " player=", _player.global_position)
			_active_walk_purpose = "harvest %s" % item
			var reached := await _walk_supply(node, _travel_budget(at))
			if not reached \
					and _player.global_position.distance_to(at) > WITHIN_REACH:
				_fail("ordinary material walk stopped short of %s at %s" % [item, at])
			elif not await _harvest_node(node, item, authored):
				pass # The physical harvest path recorded the exact reason.
			elif _count(item) <= before:
				_fail("real %s harvest produced no receipt" % item)
			else:
				var receipt := "earned %s +%d at %s, stock %d/%d" % [
					item, _count(item) - before, at, _count(item), needed[item]]
				transcript.append(receipt)
				print("EARNED CAMP MATERIAL — ", receipt)
				# A real receipt proves the production path still works. Only that
				# resets the consecutive-refusal guard.
				refusals_in_a_row = 0
				continue
			# Match the established live-scatter policy in the base route: a
			# player leaves one obstructed/contested stand and tries another
			# supply of the same resource. Keep why it was abandoned in the
			# transcript, but do not let a tolerated stand decide the run.
			refusals_in_a_row += 1
			refused.append(node_id)
			var why := str(failures[failures.size() - 1]) if failures.size() > failures_before \
				else "no reason recorded"
			if refusals_in_a_row > REFUSALS_ALLOWED:
				_fail(("%d live %s supplies in a row refused during earned campsite gathering, "
					+ "the last at %s. Last reason: %s") %
					[refusals_in_a_row, item, at, why])
				return _result()
			failures.resize(failures_before)
			transcript.append("earned %s supply at (%.1f, %.1f) refused (%s); " %
				[item, at.x, at.z, why] + "walking to another same-resource supply (%d/%d tolerated)" %
				[refusals_in_a_row, REFUSALS_ALLOWED])
		if _count(item) < int(needed[item]):
			_fail("64 physical harvests did not fund campsite " + item)
			return _result()
	transcript.append("actual campsite catalogue cost funded: " + str(needed))
	var patch: Vector2 = CAMP.BUILD_PATCH_XZ
	var custom_return := return_to.is_finite()
	var destination := return_to if custom_return else Vector3(patch.x, _world.ground_height_at(patch.x, patch.y), patch.y)
	_active_walk_purpose = "return campsite materials"
	if not await _walk_target(destination, _travel_budget(destination)):
		_fail("earned campsite supply could not return by ordinary walk to the requested return point" if custom_return
			else "earned campsite supply could not return through the actual village gate to the build patch")
		return _result()
	transcript.append("carried actual materials to the requested return point" if custom_return
		else "carried actual materials back to the campsite build patch")
	return _result()


func _equip(item_id: String) -> bool:
	# Reuse the input-only tool toggle with the production item's tool, including
	# rootstone/ironwood. Do not change the resource checked by the harvest path.
	match str(_game.get("items").call("gathered_with", item_id)):
		"axe": return await super._equip("wood")
		"pickaxe": return await super._equip("stone")
		"knife": return await super._equip("fiber")
		"": return true
	_fail("No controller tool route for " + item_id)
	return false


## Essence stands expose their essence as the primary item, but the canonical
## harvest transaction also pays attuned ingredients. Select by that authored
## output without changing the stand or asking the host for a different item.
static func supply_yields(node: Node3D, item: String) -> bool:
	if str(node.call("resource_item")) == item:
		return true
	var script := node.get_script() as Script
	if script == null or script.resource_path != HARVEST_NODE_PATH:
		return false
	var site := RENEWABLE_SITES.by_id(str(node.get("_realm_id")), str(node.get("_renewable_site_id")))
	return int((site.get("outputs", {}) as Dictionary).get(item, 0)) > 0


func _harvest_node(node: Node3D, item_id: String, authored: bool) -> bool:
	var primary := str(node.call("resource_item"))
	if primary == item_id:
		return await super._harvest_node(node, item_id, authored)
	if not authored or not supply_yields(node, item_id):
		_fail("live supply no longer yields " + item_id)
		return false
	var before := _count(item_id)
	if not await super._harvest_node(node, primary, true):
		return false
	if not await _wait_for_inventory_gain(item_id, before, 120):
		_fail("the actual harvest paid no promised secondary ingredient: " + item_id)
		return false
	return true


func _nearest_supply(item: String, refused: Array[int] = []) -> Node3D:
	var nearest: Node3D = null
	var distance := INF
	var nearest_authored: Node3D = null
	var authored_distance := INF
	for candidate: Node in _tree.get_nodes_in_group(&"harvestable"):
		if not candidate is Node3D or not candidate.has_method("resource_item"):
			continue
		if refused.has(candidate.get_instance_id()):
			continue
		var script := candidate.get_script() as Script
		if script == null or script.resource_path not in [HARVEST_NODE_PATH, VEGETATION_POINT_PATH]:
			continue
		if not candidate.is_inside_tree() or candidate.is_queued_for_deletion():
			continue
		if not supply_yields(candidate as Node3D, item):
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
		# Keep the nearest eligible stand of each kind, then take the shorter
		# real walk. An authored stand wins an exact-distance tie.
		if script.resource_path == HARVEST_NODE_PATH:
			if gap < authored_distance:
				authored_distance = gap
				nearest_authored = candidate
		elif gap < distance:
			distance = gap
			nearest = candidate
	return nearest_authored if authored_distance <= distance else nearest


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
	var target := node.global_position
	var target_path := str(node.get_path())
	var start := _player.global_position
	var started := Engine.get_physics_frames()
	var reached := await _walk_target(target, budget)
	if not reached:
		# Observe the existing failed walk once, before any next supply is chosen.
		# No extra movement, physics probes, recovery or changed refusal policy.
		var contacts: Array[Dictionary] = []
		for index in _player.get_slide_collision_count():
			var contact := _player.get_slide_collision(index)
			var collider: Object = contact.get_collider()
			contacts.append({"collider": str(collider.get_path()) if collider is Node else str(collider),
				"position": str(contact.get_position()), "normal": str(contact.get_normal())})
		var provider: Object = _arbiter.call("winning_provider")
		var observation := {"beat": "material_walk_refused", "target_path": target_path,
			"target": str(target), "start_player": str(start), "player": str(_player.global_position),
			"start_frame": started, "end_frame": Engine.get_physics_frames(), "budget": budget,
			"used_frames": Engine.get_physics_frames() - started, "velocity": str(_player.velocity),
			"on_floor": _player.is_on_floor(), "on_wall": _player.is_on_wall(), "contacts": contacts,
			"input_owner": str(INPUT_OWNER.current(_tree)), "offer": _arbiter.call("winner"),
			"winning_provider": str(provider.get_path()) if provider is Node else str(provider),
			"can_walk": _nav.can_walk(), "nav_stall": _nav.get("_stall"), "nav_side": _nav.get("_side"),
			"nav_detour": str(_nav.get("_detour")), "nav_detour_left": _nav.get("_detour_left"),
			"nav_confined_resets": _nav.confined_resets()}
		var evidence := JSON.stringify(observation)
		transcript.append(evidence)
		print("EARNED MATERIAL WALK REFUSED " + evidence)
	return reached


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
	var route_purpose := _active_walk_purpose
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
	# The workshop at (26, 26) blocks the direct chord from TrailGate to
	# the narrow public lane between the north road houses. Walk along the
	# existing street first, then use that lane in either direction.
	if _player.global_position.x > 31.0 and _player.global_position.x < 39.0 \
			and _player.global_position.z > 30.0:
		points.append(Vector3(35.0, _world.ground_height_at(35.0, 14.0), 14.0))
	for at: Vector2 in route.points:
		points.append(Vector3(at.x, _world.ground_height_at(at.x, at.y), at.y))
	if target.x > 31.0 and target.x < 39.0 and target.z > 30.0:
		points.append(Vector3(35.0, _world.ground_height_at(35.0, 14.0), 14.0))
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
		_active_walk_purpose = "%s final" % route_purpose if index == points.size() - 1 \
			else "%s boundary waypoint %d/%d" % [route_purpose, index + 1, points.size() - 1]
		if not await _walk_to(points[index], tolerance, remaining):
			return false
	return Engine.get_physics_frames() - started <= budget \
		and (str(route.gate) == "" or _boundary._open_boundary_gate(str(route.gate)))

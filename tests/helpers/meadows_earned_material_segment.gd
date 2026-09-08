extends "res://tests/helpers/gate_a_material_route.gd"

## Gather the current catalogue's actual campsite cost, including one bed for
## each configured tournament entrant. No old house budget or inventory grant.
const CAMP := preload("res://tests/helpers/meadows_earned_camp_segment.gd")


func run(tree: SceneTree, world: Node3D, game: Node, player: CharacterBody3D,
		camera_rig: Node3D) -> Dictionary:
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
	var needed := CAMP.required_stock(game)
	for item: String in needed:
		if not TOOL_ID.has(item):
			_fail("campsite now requires an unimplemented gathering verb: " + item)
			return _result()
		for _stop in 64:
			if _count(item) >= int(needed[item]):
				break
			var node := _nearest_authored(item)
			var authored := node != null
			if node == null:
				node = _nearest_live_scatter(item)
			if node == null:
				_fail("no live %s supply remains for the campsite (%d/%d)" % [item, _count(item), needed[item]])
				return _result()
			var at := node.global_position
			var before := _count(item)
			if not await _walk_to(at, 1.65, _travel_budget(at)) \
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
	return _result()


func _nearest_authored(item: String) -> Node3D:
	var nearest: Node3D = null
	var distance := INF
	for candidate: Node in _tree.get_nodes_in_group(&"harvestable"):
		if not candidate is Node3D or not candidate.has_method("resource_item"):
			continue
		var script := candidate.get_script() as Script
		if script == null or script.resource_path != HARVEST_NODE_PATH:
			continue
		if not candidate.is_inside_tree() or candidate.is_queued_for_deletion():
			continue
		if str(candidate.call("resource_item")) != item or not _is_unspent(candidate):
			continue
		if absf(candidate.global_position.y - _player.global_position.y) > WALKABLE_RISE:
			continue
		var gap := _player.global_position.distance_squared_to(candidate.global_position)
		if gap < distance:
			distance = gap
			nearest = candidate
	return nearest

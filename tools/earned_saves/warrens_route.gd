extends "res://tests/helpers/meadows_earned_warrens_segment.gd"

## Earned Quarry/Warrens for the C1 chain. It is the read-only helper
## (`tests/helpers/meadows_earned_warrens_segment.gd`) with two disclosed
## route changes (tools/earned_saves/BLOCKERS.md B2, an open Meadows defect):
##   * before the fourth rootstone (401,1809), an ordinary controller walk
##     round the conduit pylon's east side (the helper's direct leg stalls);
##   * the fifth rootstone, harvest order 16 at (393,1802), is SKIPPED. Five
##     attempts from the north, west and south never came within its 2.2 m
##     prompt: it is enclosed by the quarry foundation and the cut face on
##     main 10b635d38. By coordinator ruling it may be skipped only if nothing
##     later needs the stone. Nothing does: no later earned helper
##     (relay/hall/warden) and no Warrens/Relay/Mill/Sigil/Hall gate costs
##     rootstone. The Warrens itself only runs this quarry beat as route
##     content. The remaining reachable stops (orders 2020, 2021) are still
##     harvested by the helper's own swings, so no shortfall needs replacing.
## `_travel()` below is the helper's own `_travel()`, copied verbatim except
## for the stop filter and the removed routing-only clearance for the skipped
## stone. No position, flag or item is written.
const FOURTH_STOP := Vector2(401.0, 1809.0)
const UNREACHABLE_STOP := Vector2(393.0, 1802.0)
const UNREACHABLE_ORDER := 16
const EAST_DETOUR: Array[Vector2] = [Vector2(408.5, 1803.5), Vector2(406.5, 1809.5)]

## B3: the helper's undertrail leg (-420,2470)->(-380,2540) runs over the
## Warrens mound (peaks[5], centre (-380,2488), r 30) and stalls against it at
## about (-406,2488). Walk the ordinary ground west of the mound first.
const UNDERTRAIL_KNEE := Vector2(-380.0, 2540.0)
const MOUND_WEST_DETOUR: Array[Vector2] = [Vector2(-432.0, 2492.0), Vector2(-418.0, 2528.0)]

var _detoured := false
var _mound_detoured := false


func reachable_stops(stops: Array[Dictionary]) -> Array[Dictionary]:
	var kept: Array[Dictionary] = []
	for row: Dictionary in stops:
		if int(row.get("order", -1)) == UNREACHABLE_ORDER and _v2(row.at).distance_to(UNREACHABLE_STOP) < 0.1:
			_receipt("unreachable_node_skipped", {"order": UNREACHABLE_ORDER, "at": UNREACHABLE_STOP,
				"item": "rootstone", "amount": int(row.get("amount", 0)),
				"evidence": "5 ordinary-walk attempts (north, west, south) never within the 2.2 m prompt; BLOCKERS.md B2 (open Meadows defect)",
				"later_need": "none: no later chain step consumes rootstone",
				"replacement_nodes": "none needed; remaining reachable stops still harvested"})
			continue
		kept.append(row)
	return kept


func _walk_ground(at: Vector2, radius: float = 1.5) -> bool:
	if not _detoured and at.distance_to(FOURTH_STOP) < 0.1:
		_detoured = true
		_receipt("quarry_east_detour", {"from": _player.global_position, "waypoints": str(EAST_DETOUR),
			"reason": "helper's direct leg (406,1800)->(401,1809) stalls west of the foundation; ordinary walk around the pylon's east side"})
		for point: Vector2 in EAST_DETOUR:
			if not await super._walk_ground(point, 1.5):
				return false
	if not _mound_detoured and at.distance_to(UNDERTRAIL_KNEE) < 0.1:
		_mound_detoured = true
		_receipt("undertrail_mound_detour", {"from": _player.global_position, "waypoints": str(MOUND_WEST_DETOUR),
			"reason": "helper's undertrail leg stalls against the Warrens mound at about (-406,2488); ordinary walk west of it"})
		for point: Vector2 in MOUND_WEST_DETOUR:
			if not await super._walk_ground(point, 1.5):
				return false
	return await super._walk_ground(at, radius)


func _travel() -> bool:
	var stops := reachable_stops(rootstone_stops(_read(HARVEST)))
	var terrain := _read(TERRAIN)
	var road := trail_points(terrain, "bands", "band2_stone_and_root")
	var undertrail := trail_points(terrain, "loops", "warren_undertrail")
	var chambers := passage_path(_config, "mouth", str((_config.get("guardian", {}) as Dictionary).get("chamber", "")))
	if stops.is_empty() or road.is_empty() or undertrail.is_empty() or chambers.is_empty():
		return _fail("Current authored quarry, Band2 trail or ungated guardian route is absent")
	var quarry_centre := Vector2.ZERO
	for row: Dictionary in stops:
		quarry_centre += _v2(row.at)
	quarry_centre /= float(stops.size())
	var quarry_join := nearest_index(road, quarry_centre)
	var warren_join := nearest_index(road, undertrail[0])
	if quarry_join < 0 or warren_join <= quarry_join:
		return _fail("The current trail no longer places the quarry before the Warrens approach")
	if not await _prepare():
		return false
	for index in range(quarry_join + 1):
		if not await _walk_ground(road[index]):
			return false
	var gather := QuarryInput.new()
	gather._tree = _tree
	gather._world = _world
	gather._game = _game
	gather._player = _player
	gather._rig = _rig
	gather._arbiter = _arbiter
	gather.walk = _walk
	if not gather._resolve_move_bindings():
		return _fail("The carried pickaxe route lacks its actual controller movement binding")
	gather._nav = NAV.new(_tree, _player, _rig, gather._send_stick)
	for row: Dictionary in stops:
		var at := _v2(row.at)
		# HarvestNode's production prompt is configured at 2.4m. Requiring a
		# 1.5m centre approach first adds a stricter, non-gameplay collision
		# gate; 2.2m gets the real prompt/arbiter check its intended turn.
		if not await _walk_ground(at, 2.2):
			return false
		var node := gather._authored_node_at(at, "rootstone")
		if node == null:
			return _fail("No unspent authored quarry rootstone at " + str(at))
		var node_id := node.get_instance_id()
		var amount := int(node.call("resource_amount"))
		if amount != int(row.amount):
			return _fail("The live rootstone node does not expose its configured remaining amount")
		var expected := int((_game.get("items") as RefCounted).call("harvest_yield", "rootstone", amount, true, false))
		var before := _count("rootstone")
		if not await gather._harvest_node(node, "rootstone", true):
			return _fail("Actual pickaxe/rootstone input failed: " + str(gather.failures))
		if expected <= 0 or _count("rootstone") - before != expected or not _failures.is_empty():
			return _fail("The actual quarry swing did not yield the configured carried rootstone amount")
		_receipt("quarry_rootstone", {"at": at, "node_id": node_id, "yield": expected,
			"before": before, "after": _count("rootstone")})
	for index in range(quarry_join + 1, warren_join + 1):
		if not await _walk_ground(road[index]):
			return false
	var available: Array = _warrens.call("chamber_ids")
	for chamber: String in chambers:
		if not available.has(chamber):
			return _fail("The loaded cave is missing authored chamber " + chamber)
	var entrance: Vector3 = _warrens.call("marker", "entrance")
	var mouth: Vector3 = _warrens.call("marker", "mouth")
	var outside := outside_approach(entrance, mouth, float((_config.get("site", {}) as Dictionary).get("apron_run_m", 0.0)))
	if outside == Vector3.INF:
		return _fail("The live entrance has no usable mouth direction or authored apron")
	for index in range(nearest_index(undertrail, Vector2(outside.x, outside.z)) + 1):
		if not await _walk_ground(undertrail[index]):
			return false
	# This is a staging pose outside the authored mouth, not an interaction.
	# Ordinary wild detours can finish against the bank about 4.2 m from this
	# computed point while already standing on the same clear approach apron.
	# Keep the cave entrance, guardian admission and every prompt exact; this
	# wider tolerance applies only to the non-interactive preparation checkpoint.
	if not await _walk_ground(Vector2(outside.x, outside.z), OUTSIDE_STAGING_RADIUS) or not await _prepare():
		return false
	_allow_guardian = true
	# Use marker Y underground. Terrain height there describes the bank above
	# the room, and projecting a chamber back to that surface would walk the roof.
	if not await _walk(entrance):
		return false
	for chamber: String in chambers:
		if not await _walk(_warrens.call("marker", chamber)):
			return false
	if _guardian_wins == 0:
		if not await _engage_guardian() or not await _fight():
			return false
	if not _guardian_verified:
		return _fail("The guardian victory never produced a complete immediate reward receipt")
	for index in range(chambers.size() - 2, -1, -1):
		if not await _walk(_warrens.call("marker", chambers[index])):
			return false
	if not await _walk(entrance) or not await _walk_ground(Vector2(outside.x, outside.z), OUTSIDE_STAGING_RADIUS):
		return false
	if not retained_five(_initial_ids, _party_ids()) or _tree.current_scene != _world \
			or str(_game.get("current_realm")) != "meadows" or _fighting():
		return _fail("The same five earned creatures did not leave the cave in the same world")
	_receipt("warrens_exited", {"player": _player.global_position, "entrance": entrance,
		"outside": outside, "party_ids": _party_ids()})
	return true


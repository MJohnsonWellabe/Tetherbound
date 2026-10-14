extends "res://tests/helpers/water_shellwatch_segment.gd"

## Bounded ordinary-input pieces, including one island/crossing per return save.
## Each piece requires its real predecessor position; none relocates the player.
const VISIT := preload("res://tools/earned_saves/master_visit.gd")
const MASTERS := preload("res://scripts/creatures/breakthrough.gd")
const CROSSING := "reedhaven_to_gull_rest_sheltered"
var phase := "approach"
var master_receipts: Array = []

func _init(piece: String = "approach") -> void:
	phase = piece

func run() -> bool:
	if _game == null or _player == null or _world == null or _manager == null \
			or _director == null or _arbiter == null or str(_game.current_realm) != "water":
		return _fail("Ione requires the live Tidewake world and ordinary services")
	var riding := _world.get_node_or_null("RidingController")
	if (riding != null and riding.is_mounted()) or not _player.is_on_floor() \
			or _player.swim_controller.is_swimming() or _game.local.party.size() != 5:
		return _fail("Ione piece must start dry, unmounted, with the retained five")
	var carried: Array = _game.local.party.members().duplicate()
	if phase in ["first_shore", "reedhaven_ione", "reedhaven_brine", "brine_shellwatch", "shellwatch_tidal"] \
			and (not _game.local.redesign_character.get("master_wins", []).has("master_t3") \
			or not _game.world.flags.has("water_aquaryn_resolved")):
		return _fail("Homestead return route requires saved Ione and Tidal wins")
	var passed := false
	match phase:
		"first_shore": passed = await _first_shore()
		"reedhaven_ione": passed = await _forward_island("reedhaven", CROSSING, false)
		"reedhaven_brine": passed = await _forward_island("reedhaven", "reedhaven_to_brine_steps_sheltered")
		"brine_shellwatch": passed = await _forward_island("brine_steps", "brine_steps_to_shellwatch_sheltered")
		"shellwatch_tidal": passed = await _forward_island("shellwatch", "shellwatch_to_tidal_cradle_sheltered")
		"tidal_return": passed = await _return_crossing("tidal_cradle", "shellwatch_to_tidal_cradle_sheltered", 2)
		"shellwatch_return": passed = await _return_crossing("shellwatch", "brine_steps_to_shellwatch_sheltered", 6)
		"brine_return": passed = await _return_crossing("brine_steps", "reedhaven_to_brine_steps_sheltered", 6)
		"reedhaven_departure": passed = await _reedhaven_departure()
		"approach": passed = await _approach()
		"duel": passed = await _visit()
		"duel_only": passed = await _visit(false)
		"chest":
			if not _game.local.redesign_character.get("master_wins", []).has("master_t3"):
				return _fail("Ione chest piece requires its saved Master win")
			passed = await _visit()
		_: return _fail("Unknown Ione piece " + phase)
	_stop_combat_input()
	if _game.local.party.members() != carried or _game.pending_catch != null:
		return _fail("Ione piece changed the retained five")
	_completed = passed and failures.is_empty()
	return _completed

func result() -> Dictionary:
	var value := super.result()
	value["receipts"] = [{"travel": transcript.duplicate(), "master": master_receipts.duplicate(true)}]
	return value

func _first_shore() -> bool:
	var departure := _anchor("first_shore_to_reedhaven_departure")
	if not departure.is_finite() or _player.global_position.distance_to(departure) > 30.0:
		return _fail("Homestead return requires the saved First Shore portal arrival")
	return await _cross("first_shore_to_reedhaven_sheltered", false)

func _forward_island(island: String, route_id: String, cross_water: bool = true) -> bool:
	var spine := _land_route(island + "_exploration_spine")
	if spine.size() != 7 or _player.global_position.distance_to(spine[0]) > 15.0:
		return _fail("Forward crossing requires the saved " + island + " arrival")
	# The optional Gull Rest branch leaves from Reedhaven's inland approach;
	# the main path continues down its authored departure slope.
	var last := 6 if cross_water else 4
	for index in range(1, last + 1):
		if not await _walk_to(spine[index], "Homestead return " + island): return false
	if cross_water: return await _cross(route_id, false)
	return await _walk_to(_anchor(str(_water_route(route_id).get("from_anchor", ""))), "Ione reapproach departure")

func _return_crossing(island: String, route_id: String, start_index: int) -> bool:
	if not _game.world.flags.has("water_aquaryn_resolved"):
		return _fail("Ione return chain requires the saved Tidal victory")
	var spine := _land_route(island + "_exploration_spine")
	if spine.size() != 7 or _player.global_position.distance_to(spine[start_index]) > 130.0:
		return _fail("Ione return piece is not at its saved " + island + " approach")
	# Tidal index3 is Aquaryn's occupied spawn. Return through its proven camp
	# approach (index2→1→0), rather than walking into the creature's centre.
	for index in range(start_index, -1, -1):
		if not await _walk_to(spine[index], "Ione return " + island): return false
	return await _cross(route_id, true)

func _reedhaven_departure() -> bool:
	var spine := _land_route("reedhaven_exploration_spine")
	if spine.size() != 7 or _player.global_position.distance_to(spine[6]) > 15.0:
		return _fail("Ione departure requires the saved reverse Brine crossing")
	for index in [5, 4]:
		if not await _walk_to(spine[index], "Reedhaven return landing"): return false
	return await _walk_to(_anchor("reedhaven_to_gull_rest_departure"), "Gull Rest departure")

func _approach() -> bool:
	var route := _water_route(CROSSING)
	if route.is_empty() or route.get("requires_compatible_active_swim_mount", true) \
			or route.get("rest_anchor_ids", []).is_empty():
		return _fail("Ione sheltered human crossing/rest anchors are missing")
	var departure := _anchor(str(route.from_anchor))
	if not departure.is_finite() or _player.global_position.distance_to(departure) > 15.0:
		return _fail("Ione approach requires a saved ordinary arrival at Reedhaven departure")
	if not await _cross(CROSSING, false): return false
	var spine := _land_route("gull_rest_exploration_spine")
	if spine.size() != 7: return _fail("Gull Rest authored land approach is missing")
	for index in [1, 2, 3]:
		if not await _walk_to(spine[index], "Gull Rest arena spine"): return false
	var position: Array = MASTERS.master("master_t3").position
	var near := _vector(position) + Vector3(0, 0, -12)
	near.y = _world.ground_height_at(near.x, near.z) + 0.1
	if not await _walk_to(near, "Ione arena approach"): return false
	return _player.is_on_floor() and not _player.swim_controller.is_swimming()

func _cross(route_id: String, reverse: bool) -> bool:
	var route := _water_route(route_id)
	if route.is_empty() or not route.get("polyline") is Array or route.polyline.size() < 2 \
			or not route.get("rest_anchor_ids", []) is Array:
		return _fail("Missing authored sheltered crossing " + route_id)
	var rest_ids: Array = route.get("rest_anchor_ids", [])
	# The original lesson crossing is an authored 82.27m continuous swim. All
	# other crossings in this helper require their intermediate rest shoals.
	if rest_ids.is_empty() and route_id != "first_shore_to_reedhaven_sheltered":
		return _fail("Sheltered crossing lost its rest shoals: " + route_id)
	if rest_ids.is_empty():
		var length := 0.0
		for index in range(1, route.polyline.size()):
			length += _vector(route.polyline[index - 1]).distance_to(_vector(route.polyline[index]))
		if length > 85.0: return _fail("First Shore continuous crossing exceeds its authored human interval")
	var points: Array = route.polyline.duplicate(true)
	if reverse: points.reverse()
	var departure := _anchor(str(route.to_anchor if reverse else route.from_anchor))
	if not await _walk_to(departure, "Ione crossing departure") or not await _rest(): return false
	for raw: Array in points:
		var point := _vector(raw)
		if not await _swim_to(point, "Ione sheltered crossing"): return false
		for id: String in rest_ids:
			var rest := _anchor(id)
			if Vector2(point.x, point.z).distance_to(Vector2(rest.x, rest.z)) < 2.0:
				if not await _walk_to(rest, "Ione rest shoal") or not await _rest(): return false
	if not await _swim_to(_anchor(str(route.from_anchor if reverse else route.to_anchor)), "Ione crossing dry arrival"): return false
	return _player.is_on_floor() and not _player.swim_controller.is_swimming()

func _rest() -> bool:
	_stop_stick()
	for frame in 3600:
		if not _player.is_on_floor() or _player.swim_controller.is_swimming():
			return _fail("Ione rest must be on dry ground")
		if float(_player.vitals.stamina) >= float(_player.vitals.max_stamina): return true
		await _tree.physics_frame
	return _fail("Ione natural stamina recovery timed out")

func _visit(open_chest: bool = true) -> bool:
	var position: Array = MASTERS.master("master_t3").position
	var center := _vector(position)
	if Vector2(center.x, center.z).distance_to(Vector2(_player.global_position.x, _player.global_position.z)) > 30.0:
		return _fail("Ione duel requires the saved Gull Rest approach")
	var visit := VISIT.new()
	var outcome: Dictionary = await visit.run(_tree, _world, _game, {
		"master_id": "master_t3", "chest": open_chest,
		"interact": func(prompt: Node3D) -> bool: return await _activate(prompt, "Ione visit"),
		"tap": func(action: String) -> void: await _tap(StringName(action)),
		"fight_round": _fight_round})
	master_receipts = outcome.get("receipts", []).duplicate(true)
	failures.append_array(outcome.get("failures", []))
	return bool(outcome.get("passed", false))

func _fight_round() -> Dictionary:
	var elapsed := 0.0
	while _manager.is_fighting() and elapsed < TRAINER_FIGHT_SIM_S:
		var ally: Node3D = _director.ally_body()
		var enemy: Node3D = _manager.enemy_body()
		if not is_instance_valid(ally) or not is_instance_valid(enemy):
			_stop_combat_input()
			return {"passed": false, "reason": "Ione combat body disappeared", "sim_seconds": elapsed}
		_pilot.drive(_manager, ally, enemy)
		await _tree.physics_frame
		elapsed += Engine.time_scale / float(Engine.physics_ticks_per_second)
	_stop_combat_input()
	return {"passed": not _manager.is_fighting(), "timed_out": _manager.is_fighting(), "sim_seconds": elapsed}

extends "res://tests/helpers/water_shellwatch_segment.gd"

## Bounded ordinary-input pieces. Approach requires an earned save beside the
## Reedhaven departure; reaching that anchor from Tidal remains a separate job.
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
	var passed := false
	match phase:
		"approach": passed = await _approach()
		"duel": passed = await _visit()
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

func _approach() -> bool:
	var route := _water_route(CROSSING)
	if route.is_empty() or route.get("requires_compatible_active_swim_mount", true) \
			or route.get("rest_anchor_ids", []).is_empty():
		return _fail("Ione sheltered human crossing/rest anchors are missing")
	var departure := _anchor(str(route.from_anchor))
	if not departure.is_finite() or _player.global_position.distance_to(departure) > 15.0:
		return _fail("Ione approach requires a saved ordinary arrival at Reedhaven departure")
	if not await _walk_to(departure, "Ione departure") or not await _rest(): return false
	for raw: Array in route.polyline:
		var point := _vector(raw)
		if not await _swim_to(point, "Ione sheltered crossing"): return false
		for id: String in route.rest_anchor_ids:
			var rest := _anchor(id)
			if Vector2(point.x, point.z).distance_to(Vector2(rest.x, rest.z)) < 2.0:
				if not await _walk_to(rest, "Ione rest shoal") or not await _rest(): return false
	if not await _swim_to(_anchor(str(route.to_anchor)), "Gull Rest dry arrival"): return false
	var position: Array = MASTERS.master("master_t3").position
	var near := _vector(position) + Vector3(0, 0, -12)
	near.y = _world.ground_height_at(near.x, near.z) + 0.1
	if not await _walk_to(near, "Ione arena approach"): return false
	return _player.is_on_floor() and not _player.swim_controller.is_swimming()

func _rest() -> bool:
	_stop_stick()
	for frame in 3600:
		if not _player.is_on_floor() or _player.swim_controller.is_swimming():
			return _fail("Ione rest must be on dry ground")
		if float(_player.vitals.stamina) >= float(_player.vitals.max_stamina): return true
		await _tree.physics_frame
	return _fail("Ione natural stamina recovery timed out")

func _visit() -> bool:
	var position: Array = MASTERS.master("master_t3").position
	var center := _vector(position)
	if Vector2(center.x, center.z).distance_to(Vector2(_player.global_position.x, _player.global_position.z)) > 30.0:
		return _fail("Ione duel requires the saved Gull Rest approach")
	var visit := VISIT.new()
	var outcome: Dictionary = await visit.run(_tree, _world, _game, {
		"master_id": "master_t3", "chest": true,
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

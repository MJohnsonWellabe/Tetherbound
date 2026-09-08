extends "res://tests/helpers/water_shellwatch_segment.gd"

## Same live chapter state: liberated Shellwatch -> human crossing -> ordinary
## camp recovery -> Aquaryn defeat -> Iona's earned recipe. No fixture writes.
## Deliberately stops BEFORE the saddle/mount path: material harvesting and a
## five-slot capture/release ceremony still need ordinary continuous evidence.
const TIDAL_ROUTE := "shellwatch_to_tidal_cradle_sheltered"
const ALPHA_FLAG := "water_aquaryn_resolved"
const STONE_FLAG := "water_swim_stone_earned"
const RECIPE_FLAG := "water_swim_saddle_recipe_learned"
const TIDAL_CAMP := "water_camp_tidal_cradle"


func run() -> bool:
	if _game == null or _world == null or _director == null or _camps == null:
		return _fail("Tidal segment lacks its live Water services")
	if not _game.world.flags.has(COMBINED_FLAG) or not _player.is_on_floor() \
			or _player.swim_controller.is_swimming():
		return _fail("Tidal segment requires liberated Shellwatch and a dry departure")
	if _game.world.flags.has(ALPHA_FLAG) or _game.local.flags.has(STONE_FLAG) \
			or _game.local.flags.has(RECIPE_FLAG):
		return _fail("Tidal segment cannot credit pre-completed Alpha/Stone/recipe")
	var carried: Array = _game.local.party.members().duplicate()
	if carried.size() != 5:
		return _fail("Tidal composition requires the unchanged five-member chapter party")
	var route := _water_route(TIDAL_ROUTE)
	if not tidal_route_contract(route):
		return _fail("Tidal authored human crossing contract is missing")
	if not await _walk_to(_anchor(str(route.from_anchor)), "Shellwatch onward departure"):
		return false
	for raw: Array in route.polyline:
		if not await _swim_to(_vector(raw), TIDAL_ROUTE):
			return false
	if not await _swim_to(_anchor(str(route.to_anchor)), "Tidal dry arrival"):
		return false
	if not _player.is_on_floor() or _player.swim_controller.is_swimming():
		return _fail("Tidal crossing did not finish on grounded dry land")
	_note("112.113m authored sheltered human crossing completed")
	var spine := _land_route("tidal_cradle_exploration_spine")
	if spine.size() != 7:
		return _fail("Tidal exploration spine is missing")
	if not await _walk_to(spine[1], "Tidal camp approach") \
			or not await _recover_at_camp("Tidal before Aquaryn", TIDAL_CAMP):
		return false
	for index in [2, 3]:
		if not await _walk_to(spine[index], "Tidal basin spine point %d" % index):
			return false
	if not await _fight_alpha():
		return false
	var iona := _world.find_child("water_iona", true, false) as Node3D
	if iona == null:
		return _fail("Production Iona body is missing")
	if not await _activate(iona.call("prompt_node") as Node3D, "Iona earned recipe dialogue"):
		return false
	var panel := _world.get_node_or_null("DialoguePanel")
	if panel == null or not panel.is_open():
		return _fail("Iona controller interaction did not open dialogue")
	for line in 40:
		if not panel.is_open():
			break
		await _tap(&"interact")
	if panel.is_open() or not _game.local.flags.has(RECIPE_FLAG):
		return _fail("Iona conversation did not finish and teach the earned recipe")
	if _game.local.party.members() != carried or _game.pending_catch != null:
		return _fail("Defeat-only Alpha segment changed the five-member party")
	_completed = true
	_note("Alpha defeated, personal Stone and recipe earned; same five retained. STOP before paid saddle/capture ceremony.")
	return true


func _fight_alpha() -> bool:
	var alpha := _world.get_node_or_null("WaterAlpha")
	if alpha == null or not alpha.ready_for_intents or not is_instance_valid(alpha.body) \
			or str(alpha.body.instance.species_id) != "water_aquaryn" or int(alpha.body.instance.level) != 49:
		return _fail("Production level-49 Aquaryn is missing")
	if not await _ensure_ally_deployed("Aquaryn"):
		return false
	if not await _activate(alpha.get("_challenge_prompt") as Node3D, "Aquaryn challenge"):
		return false
	for frame in 180:
		if _manager.is_fighting():
			break
		await _tree.physics_frame
	if not _manager.is_fighting() or _manager.encounter_id() != alpha.authority.encounter_id:
		return _fail("Real Aquaryn interaction did not enter its authoritative fight")
	var deadline := Time.get_ticks_msec() + 180000
	var tick := 0
	while _manager.is_fighting() and Time.get_ticks_msec() < deadline:
		var enemy: Node3D = _manager.enemy_body()
		var ally: Node3D = _director.ally_body()
		_stop_combat_input()
		if is_instance_valid(enemy) and is_instance_valid(ally):
			var offset := enemy.global_position - ally.global_position
			offset.y = 0.0
			if offset.length() > _manager.combat_move_reach("quick") * 0.8:
				var local: Vector3 = _camera.planar_basis().inverse() * offset.normalized()
				_stick(local.x, local.z)
			if tick % 20 == 0:
				Input.action_press("combat_quick")
		tick += 1
		await _tree.physics_frame
	_stop_combat_input()
	if _manager.is_fighting():
		return _fail("Aquaryn fight exceeded 180 seconds")
	if str(alpha.authority.resolution.get("outcome", "")) != "defeated" \
			or not await _wait_world_flag(ALPHA_FLAG, 240) or not _game.local.flags.has(STONE_FLAG):
		return _fail("Aquaryn fight ended without real defeat and personal Swim Stone")
	_note("Aquaryn defeat earned world completion and personal Swim Stone")
	return true


static func tidal_route_contract(route: Dictionary) -> bool:
	return str(route.get("id", "")) == TIDAL_ROUTE \
		and str(route.get("intended_traversal", "")) == "human_level_0" \
		and str(route.get("required_departure_flag", "")) == COMBINED_FLAG \
		and str(route.get("from_anchor", "")) == "shellwatch_to_tidal_cradle_departure" \
		and str(route.get("to_anchor", "")) == "shellwatch_to_tidal_cradle_arrival" \
		and absf(float(route.get("measured_surface_polyline_m", 0.0)) - 112.113) < 0.001 \
		and (route.get("polyline", []) as Array).size() == 3


func _note(message: String) -> void:
	transcript.append(message)
	print("WATER TIDAL: " + message)

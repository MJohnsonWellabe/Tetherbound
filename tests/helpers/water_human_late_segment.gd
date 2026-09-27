extends "res://tests/helpers/water_earned_late_segment.gd"

## Late Water by the player's own swimming, with the same five retained: no
## catch, no release, no mount. It follows the same authored sheltered crossings
## the mounted segment uses. WORLD marks every late critical-path crossing
## `human_level_0` (water_world.json `sea_routes` *_sheltered). The only
## difference is how the water is crossed: the stick swims the polyline, and on
## each authored rest shoal (the route's `rest_anchor_ids`, which are polyline
## vertices) the player idles with no input until natural stamina regen is full.
## There are no pose, stamina, flag or inventory writes. The fights, controls,
## camps, Veilfall entry, pumps, Nerissa and tether are the parent segment's
## own steps. "Retained creature" here means whichever of the five is active,
## not a caught swimmer.
##
##   var late := HUMAN_LATE.new(); late.setup(tree, world, player, rig)
##   var ok: bool = await late.run_human()

const REST_FRAME_LIMIT := 3600


func run_human() -> bool:
	# Reader-pace trainer fights (Calder median 214-329 s in C2) and the swum
	# sheltered crossings need more than the mounted segment's bounds.
	fight_bound_ms = 600000
	watchdog_ms = 120 * 60 * 1000
	_swimmer = _game.local.party.active() if _game != null else null
	_abort = func(_reason: String) -> void: pass
	return await run()


func _entry_valid() -> bool:
	if _tree == null or _world == null or _game == null or _player == null \
			or _camera == null or _arbiter == null or _director == null or _manager == null \
			or _camps == null or _docks == null:
		return _fail("Human late Water requires live services")
	_riding = _world.get_node_or_null("RidingController")
	if _riding != null and _riding.is_mounted():
		return _fail("Human late Water starts on foot")
	if str(_game.current_realm) != "water" or _game.local.party.size() != 5 or _game.pending_catch != null:
		return _fail("Human late Water requires the unchanged full belt in Water")
	if not _game.world.flags.has("water_aquaryn_resolved"):
		return _fail("Human late Water requires the resolved Aquaryn departure gate")
	for flag in ["water_dock_salt_crown_landing_charted", "water_sluice_west_disabled",
		"water_sluice_east_disabled", "defeated_water_trainer_bex", "defeated_water_trainer_calder",
		"defeated_water_trainer_venn", "water_captain_nerissa_defeated", "water_veilfall_intake_stopped",
		"water_veilfall_return_opened", "water_guardian_freed", "water_guardian_claimed",
		"water_tether_disabled", "water_guardian_settled", "water_currents_restored"]:
		if _game.world.flags.has(flag):
			return _fail("Cannot credit pre-completed late Water milestone " + flag)
	return true


func _run_route() -> bool:
	var tidal := _land_route("tidal_cradle_exploration_spine")
	if tidal.size() != 7:
		return _fail("Tidal departure requires the complete authored seven-point spine")
	for point: Vector3 in tidal.slice(1):
		if not await _walk_to(point, "Tidal spine"):
			return false
	if not await _walk_to(_anchor(START_ANCHOR), "Tidal sheltered departure", 1.8):
		return false
	if not await _cross_route(LATE_ROUTES[0]):
		return false
	if not await _walk_land_route("salt_crown_exploration_spine") \
			or not await _activate_dock_action("salt_crown_chart", "water_dock_salt_crown_landing_charted"):
		return false
	if not await _cross_route(LATE_ROUTES[1]):
		return false
	var sluice := _land_route("sluice_isle_exploration_spine")
	if sluice.size() < 6:
		return _fail("Sluice exploration spine is incomplete")
	if not await _walk_to(sluice[1], "Sluice approach waypoint 1") \
			or not await _defeat_trainer("water_trainer_bex", "defeated_water_trainer_bex") \
			or not await _activate_dock_action("sluice_west_control", "water_sluice_west_disabled") \
			or not await _recover_at_camp("after Bex", "water_camp_sluice_isle"):
		return false
	for index in range(2, 6):
		if not await _walk_to(sluice[index], "Sluice ascent/departure waypoint %d" % index):
			return false
	if not await _defeat_trainer("water_trainer_calder", "defeated_water_trainer_calder") \
			or not await _activate_dock_action("sluice_east_control", "water_sluice_east_disabled") \
			or not await _wait_world_flag("water_dock_sluice_isle_both_controls_disabled", 240):
		return _fail("Both physical Sluice controls did not publish completion")
	_note("Bex/Calder defeated; both controls and final crossing barrier opened")
	if not await _cross_route(LATE_ROUTES[2]) \
			or not await _recover_at_camp("before Venn", "water_camp_veilfall"):
		return false
	var veilfall := _land_route("veilfall_exploration_spine")
	if veilfall.size() < 3:
		return _fail("Veilfall exploration spine is incomplete")
	for index in range(1, veilfall.size() - 1):
		if not await _walk_to(veilfall[index], "Veilfall exterior waypoint %d" % index):
			return false
	if not await _defeat_trainer("water_trainer_venn", "defeated_water_trainer_venn"):
		return false
	for index in range(veilfall.size() - 2, 0, -1):
		if not await _walk_to(veilfall[index], "Veilfall recovery waypoint %d" % index):
			return false
	if not await _recover_at_camp("after Venn", "water_camp_veilfall"):
		return false
	for index in range(2, veilfall.size()):
		if not await _walk_to(veilfall[index], "Veilfall return waypoint %d" % index):
			return false
	var cave := _world.get_node_or_null("WaterVeilfall") as Node3D
	if cave == null or not await _activate(cave.get("_entry_prompt"), "Veilfall waterfall entrance"):
		return _fail("Physical Veilfall entrance did not activate")
	await _frames(12)
	if not cave.contains_interior(_player.global_position):
		return _fail("Same player did not enter actual Veilfall interior")
	var controls: Dictionary = cave.get("_controls")
	if not controls.has_all(["intake_pump", "sluice_wheel", "guardian_tether"]):
		return _fail("Veilfall production controls are incomplete")
	var origin: Vector3 = cave.interior.global_position
	if not await _walk_to(origin + Vector3(-5, 0, 18.9), "intake pump") \
			or not await _activate(controls.intake_pump, "Veilfall intake pump") \
			or not await _wait_world_flag("water_veilfall_intake_stopped", 180):
		return _fail("Physical intake control sequence failed")
	if not await _walk_to(origin + Vector3(0, 0, 34), "opened intake grille") \
			or not await _walk_to(origin + Vector3(9, 0, 45.9), "return sluice") \
			or not await _activate(controls.sluice_wheel, "Veilfall return sluice") \
			or not await _wait_world_flag("water_veilfall_return_opened", 180):
		return _fail("Physical return-sluice sequence failed")
	for point in [Vector3(0, 0, 56), Vector3(0, 0, 70), Vector3(0, 0, 87)]:
		if not await _walk_to(origin + point, "Veilfall interior waypoint"):
			return false
	if not await _defeat_trainer("water_trainer_nerissa", "water_captain_nerissa_defeated") \
			or not await _activate(controls.guardian_tether, "Abyssal Guardian tether") \
			or not await _wait_world_flag("water_guardian_freed", 240):
		return _fail("Nerissa victory did not permit physical Guardian release")
	if not _game.world.flags.has("water_tether_disabled") \
			or _game.pending_catch != null or _game.world.flags.has("water_guardian_claimed") \
			or _game.world.flags.has("water_guardian_settled") \
			or _game.world.flags.has("water_currents_restored"):
		return _fail("Late segment crossed its pre-invitation boundary")
	_note("Nerissa defeated, tether released by human swimming; STOP before Guardian invitation, same five retained")
	return _same_party() and not _expired()


## Swim the authored sheltered polyline, resting on its rest shoals.
func _cross_route(id: String) -> bool:
	var route := _water_route(id)
	if route.is_empty():
		return _fail("Missing authored sheltered crossing " + id)
	var rests: Array[Vector3] = []
	for rest_id: Variant in route.get("rest_anchor_ids", []):
		rests.append(_anchor(str(rest_id)))
	for raw: Array in route.polyline:
		var point := _vector(raw)
		if not await _walk_to(point, id + " swim", 2.5):
			return false
		for rest: Vector3 in rests:
			if Vector2(point.x - rest.x, point.z - rest.z).length() < 0.6:
				await _rest_on_shoal(id)
	if not await _walk_to(_anchor(str(route.to_anchor)), id + " landing", 1.8):
		return false
	_note("Human sheltered crossing completed %s (%d rest shoals)" % [id, rests.size()])
	return true


func _rest_on_shoal(id: String) -> void:
	_stop_stick()
	var vitals: Object = _player.get("vitals")
	var frames := 0
	while vitals != null and float(vitals.stamina) < float(vitals.max_stamina) and frames < REST_FRAME_LIMIT:
		if _expired():
			return
		await _tree.physics_frame
		frames += 1
	_note("%s rest shoal: idled %.1f s to stamina %.0f/%.0f" % [id, frames / 60.0,
		float(vitals.stamina) if vitals != null else -1.0, float(vitals.max_stamina) if vitals != null else -1.0])


## The retained creature is whichever of the five is active and able.
func _same_deployed_swimmer() -> bool:
	return _director.ally_body() != null and _same_party()


func _ensure_ally_deployed(label: String) -> bool:
	if _expired() or not _same_party():
		return _fail(label + " lost the retained five")
	if _director.ally_body() == null:
		await _tap(&"creature_recall")
	for frame in 180:
		if _expired():
			return false
		if _director.ally_body() != null:
			return true
		await _tree.physics_frame
	return _fail(label + " did not controller-deploy an active creature")

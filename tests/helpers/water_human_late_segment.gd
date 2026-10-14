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
##   var ok: bool = await late.run_human("salt_bex")

const REST_FRAME_LIMIT := 3600
const SHORT_SEGMENTS := {"07a1_departure": "departure", "07a2_salt_crossing": "salt_crossing",
	"07a3_salt_chart": "salt_chart", "07a4_sluice_crossing": "sluice_crossing",
	"07a5_bex": "bex", "07a6_bex_recovery": "bex_recovery"}
const SHORT_PREDECESSORS := {"07a1_departure": "05_tidal", "07a2_salt_crossing": "07a1_departure",
	"07a3_salt_chart": "07a2_salt_crossing", "07a4_sluice_crossing": "07a3_salt_chart",
	"07a5_bex": "07a4_sluice_crossing", "07a6_bex_recovery": "07a5_bex"}
const SHORT_WATCHDOG_MS := 240000
var piece := "all"
const BEX_FLAGS := ["water_dock_salt_crown_landing_charted", "water_sluice_west_disabled", "defeated_water_trainer_bex"]
const CALDER_FLAGS := ["water_sluice_east_disabled", "water_dock_sluice_isle_both_controls_disabled", "defeated_water_trainer_calder"]
const VENN_FLAGS := ["defeated_water_trainer_venn"]
const END_FLAGS := ["water_captain_nerissa_defeated", "water_veilfall_intake_stopped",
	"water_veilfall_return_opened", "water_guardian_freed", "water_guardian_claimed",
	"water_tether_disabled", "water_guardian_settled", "water_currents_restored"]


static func piece_entry_error(selected: String, flags: Array) -> String:
	if selected in SHORT_SEGMENTS.values():
		var required: Array = []
		if selected in ["sluice_crossing", "bex", "bex_recovery"]: required.append(BEX_FLAGS[0])
		if selected == "bex_recovery": required.append("defeated_water_trainer_bex")
		for flag: String in BEX_FLAGS + CALDER_FLAGS + VENN_FLAGS + END_FLAGS:
			if flags.has(flag) != required.has(flag): return "Short piece milestone differs: " + flag
		return ""
	if selected not in ["salt_bex", "calder", "venn", "nerissa"]: return "Use split late pieces: salt_bex, calder, venn, nerissa"
	for flag: String in BEX_FLAGS + CALDER_FLAGS + VENN_FLAGS + END_FLAGS:
		var required := (selected in ["calder", "venn", "nerissa"] and flag in BEX_FLAGS) \
			or (selected in ["venn", "nerissa"] and flag in CALDER_FLAGS) \
			or (selected == "nerissa" and flag in VENN_FLAGS)
		if flags.has(flag) != required:
			return ("Missing predecessor milestone " if required else "Cannot credit pre-completed milestone ") + flag
	return ""


static func short_exit_error(selected: String, flags: Array) -> String:
	var next := {"departure": "salt_crossing", "salt_crossing": "salt_chart",
		"salt_chart": "sluice_crossing", "sluice_crossing": "bex", "bex": "bex_recovery", "bex_recovery": "calder"}
	if not next.has(selected): return "Unknown short exit"
	return piece_entry_error(str(next[selected]), flags)


## A movement-only boundary needs its actual predecessor and saved position;
## identical flags alone cannot distinguish the two sides of a crossing.
static func short_receipt_error(selected: String, receipt: Variant, loaded: Dictionary) -> String:
	var predecessor := str(SHORT_PREDECESSORS.get(selected, "07a6_bex_recovery" if selected == "07b_calder" else ""))
	if predecessor.is_empty(): return "Unknown short handoff"
	var required := ["uids", "flags", "items", "realm", "player"]
	if selected != "07a1_departure": required.append("training")
	var error := preload("res://tests/helpers/four_biome_checkpoints.gd").piece_receipt_error(receipt, predecessor, required)
	if not error.is_empty(): return error
	for key: String in required:
		if key == "player": continue
		if not loaded.has(key) or JSON.parse_string(JSON.stringify(receipt.after[key])) != JSON.parse_string(JSON.stringify(loaded[key])):
			return "Short handoff differs: " + key
	if selected != "07a1_departure" and (not receipt.after.training is Dictionary or receipt.after.training.is_empty()):
		return "Short predecessor requires actual training snapshot"
	var positions: Array[Vector3] = []
	for point: Variant in [receipt.after.player, loaded.get("player")]:
		if not point is Array or point.size() != 3: return "Short handoff position missing"
		for value: Variant in point:
			if not (value is int or value is float) or not is_finite(float(value)): return "Short handoff position invalid"
		positions.append(Vector3(float(point[0]), float(point[1]), float(point[2])))
	if positions[0].distance_to(positions[1]) > 3.0: return "Short handoff loaded away from its saved boundary"
	return ""


func result() -> Dictionary:
	var observed := super.result()
	observed["piece"] = piece
	if piece == "salt_bex": observed.endpoint = "after_bex_sluice_camp"
	elif piece == "calder": observed.endpoint = "after_calder_sluice_controls"
	elif piece == "venn": observed.endpoint = "after_venn_veilfall_camp"
	elif piece in SHORT_SEGMENTS.values(): observed.endpoint = "short_late_" + piece
	return observed


func run_human(selected: String = "all") -> bool:
	piece = selected
	if piece not in ["salt_bex", "calder", "venn", "nerissa"] and piece not in SHORT_SEGMENTS.values():
		return _fail("Combined late runs are retired: use salt_bex, calder, venn, nerissa with saved handoffs")
	# Reader-pace trainer fights (Calder median 214-329 s in C2) and the swum
	# sheltered crossings need more than the mounted segment's bounds.
	fight_bound_ms = 600000
	watchdog_ms = 30 * 60 * 1000
	if piece in SHORT_SEGMENTS.values(): watchdog_ms = SHORT_WATCHDOG_MS
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
	var flags: Array = []
	for flag: String in BEX_FLAGS + CALDER_FLAGS + VENN_FLAGS + END_FLAGS:
		if _game.world.flags.has(flag): flags.append(flag)
	var entry_error := piece_entry_error(piece, flags)
	if not entry_error.is_empty(): return _fail(entry_error)
	return true


func _run_route() -> bool:
	if piece in SHORT_SEGMENTS.values():
		var passed := false
		match piece:
			"departure": passed = await _tidal_departure()
			"salt_crossing": passed = await _cross_route(LATE_ROUTES[0])
			"salt_chart": passed = await _salt_chart()
			"sluice_crossing": passed = await _sluice_approach()
			"bex": passed = await _defeat_trainer("water_trainer_bex", "defeated_water_trainer_bex")
			"bex_recovery": passed = await _bex_recovery()
		if not passed: return false
		var flags: Array = []
		for flag: String in BEX_FLAGS + CALDER_FLAGS + VENN_FLAGS + END_FLAGS:
			if _game.world.flags.has(flag): flags.append(flag)
		var exit_error := short_exit_error(piece, flags)
		if not exit_error.is_empty(): return _fail(exit_error)
		_stop_stick()
		for frame in 120:
			if _player.is_on_floor() and not _player.swim_controller.is_swimming(): break
			await _frames(1)
		if not _player.is_on_floor() or _player.swim_controller.is_swimming():
			return _fail("Short piece must finish grounded on land before checkpoint save")
		return _same_party() and not _expired()
	if piece == "salt_bex" and not await _salt_bex(): return false
	if piece == "calder" and not await _calder(): return false
	if piece == "venn" and not await _venn(): return false
	if piece == "nerissa" and not await _nerissa(): return false
	return _same_party() and not _expired()


func _salt_bex() -> bool:
	if not await _tidal_departure() or not await _cross_route(LATE_ROUTES[0]) \
			or not await _salt_chart() or not await _sluice_approach() \
			or not await _defeat_trainer("water_trainer_bex", "defeated_water_trainer_bex") \
			or not await _bex_recovery(): return false
	return _same_party() and not _expired()


func _tidal_departure() -> bool:
	var tidal := _land_route("tidal_cradle_exploration_spine")
	if tidal.size() != 7:
		return _fail("Tidal departure requires the complete authored seven-point spine")
	for point: Vector3 in tidal.slice(1):
		if not await _walk_to(point, "Tidal spine"):
			return false
	if not await _walk_to(_anchor(START_ANCHOR), "Tidal sheltered departure", 1.8):
		return false
	return true


func _salt_chart() -> bool:
	if not await _walk_land_route("salt_crown_exploration_spine") \
			or not await _activate_dock_action("salt_crown_chart", "water_dock_salt_crown_landing_charted"):
		return false
	return true


func _sluice_approach() -> bool:
	if not await _cross_route(LATE_ROUTES[1]):
		return false
	var sluice := _land_route("sluice_isle_exploration_spine")
	if sluice.size() < 6:
		return _fail("Sluice exploration spine is incomplete")
	return await _walk_to(sluice[1], "Sluice approach waypoint 1")


func _bex_recovery() -> bool:
	if not await _activate_dock_action("sluice_west_control", "water_sluice_west_disabled") \
			or not await _recover_at_camp("after Bex", "water_camp_sluice_isle"):
		return false
	return _same_party() and not _expired()


func _calder() -> bool:
	var sluice := _land_route("sluice_isle_exploration_spine")
	if sluice.size() < 6: return _fail("Sluice exploration spine is incomplete")
	for index in range(2, 6):
		if not await _walk_to(sluice[index], "Sluice ascent/departure waypoint %d" % index):
			return false
	if not await _defeat_trainer("water_trainer_calder", "defeated_water_trainer_calder") \
			or not await _activate_dock_action("sluice_east_control", "water_sluice_east_disabled") \
			or not await _wait_world_flag("water_dock_sluice_isle_both_controls_disabled", 240):
		return _fail("Both physical Sluice controls did not publish completion")
	_note("Bex/Calder defeated; both controls and final crossing barrier opened")
	return _same_party() and not _expired()


func _venn() -> bool:
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
	# Venn stands by the landing camp, not at the far end of the spine: walk
	# back from the spine waypoint nearest where the fight left the player.
	var back_from := veilfall.size() - 2
	for index in range(1, veilfall.size() - 1):
		if _player.global_position.distance_to(veilfall[index]) < _player.global_position.distance_to(veilfall[back_from]):
			back_from = index
	for index in range(back_from, 0, -1):
		if not await _walk_to(veilfall[index], "Veilfall recovery waypoint %d" % index):
			return false
	if not await _recover_at_camp("after Venn", "water_camp_veilfall"):
		return false
	return _same_party() and not _expired()


func _nerissa() -> bool:
	var veilfall := _land_route("veilfall_exploration_spine")
	if veilfall.size() < 3: return _fail("Veilfall exploration spine is incomplete")
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

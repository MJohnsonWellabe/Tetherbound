extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/water_shellwatch_segment.gd")
const RUNTIME := preload("res://scripts/world/water_encounter_runtime_data.gd")


func test_recovery_reselects_bedded_member_after_party_auto_cycle() -> void:
	var party := preload("res://autoload/party.gd").new()
	var species := preload("res://scripts/creatures/creature_species.gd")
	for id in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		party.add(species.spawn(id))
	var retained: RefCounted = party.active()
	assert_true(party.set_resting(0, true, 7))
	assert_false(party.active() == retained, "negative control: bed assignment changes who recall summons")
	assert_eq(SEGMENT.recovery_cycle_count(party, retained), -1, "a sleeping member remains unavailable")
	party.set_resting(0, false)
	assert_false(party.active() == retained, "unbedding does not restore active selection")
	party.at(2).fainted = true
	var presses := SEGMENT.recovery_cycle_count(party, retained)
	assert_eq(presses, 3, "controller cycling skips the fainted member")
	for step in presses:
		assert_true(party.cycle_active(1))
	assert_true(party.active() == retained, "the next recall now summons the recovered identity")
	assert_eq(SEGMENT.recovery_cycle_count(party, retained), 0)
	assert_eq(SEGMENT.recovery_cycle_count(party, species.spawn("terrapup")), -1)


func test_live_trainer_contract_uses_production_namespaced_species() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var characters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	var encounters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_encounters.json"))
	var translated := RUNTIME.build(world, characters, encounters,
		func(_x: float, _z: float) -> float: return 0.0)
	assert_true(translated.ok)
	var trainers: Dictionary = translated.trainer_specs
	assert_false(SEGMENT.trainer_contract(trainers[SEGMENT.SOLM_ID], SEGMENT.SOLM_ID, 47,
		["mirejaw", "mangrove_monitor"]), "negative control reproduces old raw-ID comparison against live specs")
	assert_true(SEGMENT.trainer_contract(trainers[SEGMENT.SOLM_ID], SEGMENT.SOLM_ID, 47,
		["water_mirejaw", "water_mangrove_monitor"]))
	assert_true(SEGMENT.trainer_contract(trainers[SEGMENT.IRVA_ID], SEGMENT.IRVA_ID, 48,
		["water_riptusk", "water_cannonback"]))
	var changed: Dictionary = trainers[SEGMENT.IRVA_ID].duplicate(true)
	changed.team[0].level = 47
	assert_false(SEGMENT.trainer_contract(changed, SEGMENT.IRVA_ID, 48,
		["water_riptusk", "water_cannonback"]), "runtime contract still requires exact authored levels")


func test_result_requires_explicit_clean_completion() -> void:
	var segment := SEGMENT.new()
	assert_false(segment.result().ok)
	assert_false(SEGMENT.verdict(false, []))
	assert_false(SEGMENT.verdict(true, ["action failed"]))
	assert_true(SEGMENT.verdict(true, []))


func test_authored_route_trainers_and_actions_match_segment() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_world.json"))
	var characters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_characters.json"))
	var docks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_dock_actions.json"))
	var route: Dictionary = {}
	for candidate: Dictionary in world.water_routes:
		if str(candidate.id) == SEGMENT.ROUTE_ID:
			route = candidate
	var trainers: Dictionary = {}
	for candidate: Dictionary in characters.trainers:
		trainers[str(candidate.id)] = candidate
	assert_true(SEGMENT.route_contract(route))
	assert_true(SEGMENT.trainer_contract(trainers.get(SEGMENT.SOLM_ID, {}),
		SEGMENT.SOLM_ID, 47, ["mirejaw", "mangrove_monitor"]))
	assert_true(SEGMENT.trainer_contract(trainers.get(SEGMENT.IRVA_ID, {}),
		SEGMENT.IRVA_ID, 48, ["riptusk", "cannonback"]))
	assert_true(SEGMENT.dock_contract(docks))
	assert_true(SEGMENT.world_dock_contract(world))
	assert_eq(SEGMENT.DEPARTURE_BARRIER, "shellwatch_to_tidal_cradle_dockBarrier")
	var camp: Dictionary = {}
	var camp_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_camps.json"))
	for candidate: Dictionary in camp_data.camps:
		if str(candidate.id) == SEGMENT.CAMP_ID:
			camp = candidate
	assert_eq(str(camp.get("island_id", "")), "shellwatch")
	assert_eq(camp.get("at", []), [359.289459228516, 971.46923828125])

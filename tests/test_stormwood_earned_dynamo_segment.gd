extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/stormwood_earned_dynamo_segment.gd")

class Flags extends RefCounted:
	var values: Dictionary = {}
	func has(flag: String) -> bool:
		return values.has(flag)

class QuietSegment extends SEGMENT:
	func _fail(message: String) -> bool:
		failures.append(message)
		return false

func test_each_earned_entry_prerequisite_is_required() -> void:
	var flags := Flags.new()
	for flag: String in SEGMENT.ENTRY_FLAGS:
		flags.values[flag] = true
	assert_true(SEGMENT.missing_entry_flags(flags).is_empty())
	for flag: String in SEGMENT.ENTRY_FLAGS:
		flags.values.erase(flag)
		assert_eq(SEGMENT.missing_entry_flags(flags), [flag])
		flags.values[flag] = true
	assert_eq(SEGMENT.missing_entry_flags(null).size(), SEGMENT.ENTRY_FLAGS.size())

func test_dynamo_null_entry_cannot_claim_core_completion() -> void:
	var segment := QuietSegment.new()
	assert_false(segment.result().passed)
	var observed: Dictionary = await segment.run(null, null, null)
	assert_false(observed.passed)
	assert_eq(observed.failures.size(), 1)
	assert_eq(observed.endpoint, "earned physical Dynamo core, before Marrow")

func test_named_rosters_and_switch_guards_match_production_catalogues() -> void:
	var cast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_trainers.json"))
	var authored: Dictionary = {}
	for row: Dictionary in cast.trainers:
		authored[str(row.id)] = row
	for id: String in SEGMENT.TRAINERS:
		assert_true(authored.has(id), id + " must be an actual production roster")
		assert_eq(authored[id].party.size(), 3)
	var rods: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_rod_stations.json"))
	for pair in [["deepwood_rod_station", SEGMENT.TRAINERS[0]],
			["dynamo_approach_rod_station", SEGMENT.TRAINERS[1]]]:
		var found := false
		for row: Dictionary in rods.stations:
			if str(row.id) == pair[0]:
				found = true
				assert_eq(str(row.guard_trainer_id), pair[1])
				assert_eq(str(row.guard_defeat_flag), "stormwood:trainer:%s:defeated" % pair[1])
		assert_true(found)

func test_no_progression_or_pose_bypass_and_no_marrow_start() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/stormwood_earned_dynamo_segment.gd")
	for bypass in ["global_position =", "face_towards", "emit_event(", "enter_realm(",
		"travel_for_peer(", "request_stormwood_arch_travel(", "inventory.add(",
		"progression.set(", "begin_for_peer(", "captain_marrow_dynamo_core"]:
		assert_false(source.contains(bypass), bypass)
	for receipt in ["stormwood:captive_truth_learned", "stormwood:deepwood_station_disabled",
		"stormwood:all_rods_disabled", "stormwood:ember_bivouac_reached", "stormwood:kestrel_defeated",
		"_roster_ids() != _party_before", "ascent_point", "_player.is_on_floor()", "furthest >= 0.998"]:
		assert_true(source.contains(receipt), receipt)

func test_whole_ascent_matches_existing_smoke_clock_and_budget() -> void:
	var smoke := FileAccess.get_file_as_string("res://tests/smoke_stormheart_ascent.gd")
	assert_true(smoke.contains("const MAX_WALK_FRAMES := %d" % SEGMENT.ASCENT_FRAMES))
	assert_true(smoke.contains("const TEST_TIME_SCALE := %.1f" % SEGMENT.ASCENT_SCALE))
	assert_eq(SEGMENT.ASCENT_HZ, 60)
	assert_true(smoke.contains("const CORE_TOLERANCE := %.1f" % SEGMENT.CORE_TOLERANCE))
	var source := FileAccess.get_file_as_string("res://tests/helpers/stormwood_earned_dynamo_segment.gd")
	var ascent := source.substr(source.find("func _walk_actual_ascent"))
	assert_true(ascent.contains("Engine.get_physics_frames() - started < ASCENT_FRAMES"))
	assert_false(ascent.contains("await _fight_current"))

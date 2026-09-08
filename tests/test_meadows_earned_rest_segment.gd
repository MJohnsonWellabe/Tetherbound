extends "res://tests/test_case.gd"

const REST := preload("res://tests/helpers/meadows_earned_rest_segment.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TOURNAMENT := preload("res://scripts/world/tournament.gd")


func test_rest_refuses_missing_live_context_without_claiming_a_night() -> void:
	var rest := REST.new()
	var observed: Dictionary = await rest.run(null, null, null, [], null)
	assert_false(observed.passed)
	assert_false(observed.completed)
	assert_eq(observed.receipts, [])
	assert_true(not observed.failures.is_empty())


func test_paid_bed_receipt_rejects_free_removed_foreign_and_wrong_structures() -> void:
	assert_true(REST.paid_record_matches({"id": "creature_bed", "paid": true, "realm": "meadows"}, "creature_bed"))
	assert_false(REST.paid_record_matches({"id": "creature_bed", "paid": false}, "creature_bed"))
	assert_false(REST.paid_record_matches({"id": "creature_bed"}, "creature_bed"))
	assert_false(REST.paid_record_matches({"id": "creature_bed", "paid": true, "removed": true}, "creature_bed"))
	assert_false(REST.paid_record_matches({"id": "creature_bed", "paid": true, "realm": "stormwood"}, "creature_bed"))
	assert_false(REST.paid_record_matches({"id": "tent", "paid": true}, "bedroll"))


func test_bed_assignment_maps_strength_order_back_to_actual_party_slots() -> void:
	var party := PARTY.new()
	for level: int in [2, 6, 3, 5, 4]:
		var member: RefCounted = SPECIES.spawn("bramblebun")
		member.call("set_level", level, PROGRESSION.config())
		party.add(member)
	var before := REST.party_ids(party)
	var indices := REST.entrant_indices(party)
	var expected: Array[int] = [1, 3, 4, 2, 0]
	assert_eq(indices, expected.slice(0, TOURNAMENT.required_party_size()))
	var entrants := TOURNAMENT.entrants(party)
	for ordinal in indices.size():
		assert_eq(party.at(indices[ordinal]), entrants[ordinal].creature,
			"a bed panel must focus the real slot, not the sorted entrant ordinal")
	assert_eq(REST.party_ids(party), before)


func test_food_shortfall_reads_thresholds_and_leaves_fed_unhappy_creatures_for_rest() -> void:
	var member: RefCounted = SPECIES.spawn("bramblebun")
	member.set("nourishment", 20.0)
	member.set("happiness", 40.0)
	var cfg := {"nourishment": {"max": 100.0, "fed_at": 0.6},
		"happiness": {"max": 100.0, "happy_at": 0.7}}
	var food := {"nourishment": 20.0, "happiness": 10.0}
	assert_eq(REST.berries_needed(member, food, cfg), 2,
		"food supplies hunger; another real night can supply the missing happiness")
	assert_eq(member.get("nourishment"), 20.0)
	assert_eq(member.get("happiness"), 40.0)
	member.set("nourishment", 60.0)
	assert_eq(REST.berries_needed(member, food, cfg), 0,
		"fed but unhappy must return to bed instead of exhausting the food picker")
	member.set("nourishment", 100.0)
	assert_eq(REST.berries_needed(member, food, cfg), 0,
		"a full and unhappy creature cannot be a Satchel feeding target")
	member.set("nourishment", 59.9)
	assert_eq(REST.berries_needed(member, food, cfg), 1)


func test_legacy_feeding_and_sleep_composition_are_fail_closed() -> void:
	var driver := REST.BedInput.new()
	driver._feed_the_team()
	assert_eq(driver.failures.size(), 1)
	assert_false(driver._sleep_the_team_into_condition())
	assert_eq(driver.failures.size(), 2)


func test_rest_source_has_no_injected_prerequisites_or_direct_care_callbacks() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/meadows_earned_rest_segment.gd")
	for forbidden: String in ["set_flag(", "inventory.add(", "party.add(",
		"set_level(", "take_damage(", "gain_xp(", "heal(", "revive(",
		"CONDITION.feed(", "pass_the_night(", "advance_day(", "set_resting(",
		"assign_creature(", "_on_target_row(", "load_game(", "global_position =",
		"set_physics_process(", "set_process(", "rig.set(", "time_scale ="]:
		assert_false(source.contains(forbidden), "rest must earn state through input: " + forbidden)

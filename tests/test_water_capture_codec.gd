extends "res://tests/test_case.gd"

const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const PARTY := preload("res://autoload/party.gd")
const SAVE := preload("res://scripts/save/save_game.gd")

func populated() -> RefCounted:
	var creature := SPECIES.spawn("water_aquaryn")
	creature.iv_hp = 0.79
	creature.iv_attack = 0.23
	creature.iv_defence = 0.61
	creature.boost_hp = 2
	creature.boost_attack = 3
	creature.boost_defence = 1
	creature.set_level(49, PROGRESSION.config())
	creature.hp *= 0.43
	creature.nickname = "Returning Tide"
	creature.trait_primary = "hardy"
	creature.trait_secondary = "swift"
	creature.shiny = true
	creature.swim_stamina_fraction = 0.271
	creature.energy = 13.5
	creature.bond = 31
	creature.xp = 87
	creature.battles_fought = 17
	creature.caught_on_day = 9
	creature.levels_gained_with_you = 3
	creature.landmarks_visited_together = 7
	creature.distance_m_together = 1837.25
	creature.rest_nights_together = 4
	creature.feeds_together = 11
	creature.nourishment = 68.4
	creature.happiness = 81.2
	creature.rested_seconds_left = 74.5
	return creature

func test_aquaryn_json_round_trip_matches_every_canonical_saved_field() -> void:
	var original := populated()
	var owner := PARTY.new()
	assert_true(owner.add(original))
	var expected: Dictionary = SAVE.new()._party_to_array(owner)[0]
	var payload := CODEC.encode(original)
	assert_eq(payload, expected)
	var restored := CODEC.decode(JSON.parse_string(JSON.stringify(payload)))
	assert_true(restored != null)
	assert_true(restored != original)
	var actual := CODEC.encode(restored)
	assert_eq(actual.size(), expected.size())
	for key: String in expected:
		if expected[key] is float:
			assert_true(is_equal_approx(float(actual[key]), float(expected[key])), "Saved float survives: " + key)
		else:
			assert_eq(actual[key], expected[key], "Saved field survives: " + key)
	assert_eq(owner.members().size(), 1)
	assert_true(owner.members()[0] == original)
	assert_eq(CODEC.encode(original), expected)
	var destination := PARTY.new()
	assert_true(destination.add(restored))
	assert_true(destination.remove_at(0) == restored)
	assert_eq(destination.members().size(), 0)

func test_malformed_records_refuse_without_repair_or_species_invention() -> void:
	var valid := CODEC.encode(populated())
	for invalid: Variant in [null, [], "water_aquaryn", {}, {"species_id":"water_aquaryn"}]:
		assert_true(CODEC.decode(invalid) == null)
	for pair: Array in [["species_id", "missing_creature"], ["hp", INF], ["attack", NAN], ["level", 0], ["level", 2.5], ["fainted", "false"], ["nickname", []], ["swim_stamina_fraction", -0.1], ["swim_stamina_fraction", 1.1], ["max_hp", -1.0]]:
		var broken := valid.duplicate(true)
		broken[pair[0]] = pair[1]
		assert_true(CODEC.decode(broken) == null, "Reject malformed " + str(pair[0]))
	var missing := valid.duplicate(true)
	missing.erase("trait_secondary")
	assert_true(CODEC.decode(missing) == null)
	var extra := valid.duplicate(true)
	extra["hidden_sixth_slot"] = true
	assert_true(CODEC.decode(extra) == null)
	assert_true(CODEC.encode(null).is_empty())
	assert_true(CODEC.encode(RefCounted.new()).is_empty())

func test_repeat_decode_does_not_add_to_any_gameplay_party() -> void:
	var owner := PARTY.new()
	for i in 5:
		assert_true(owner.add(populated()))
	var before: Array = owner.members().duplicate()
	var payload := CODEC.encode(before[0])
	var first := CODEC.decode(payload)
	var second := CODEC.decode(payload)
	assert_true(first != null and second != null and first != second)
	assert_eq(owner.members(), before)
	assert_false(owner.add(first))
	assert_false(owner.add(second))
	assert_eq(owner.members().size(), 5)

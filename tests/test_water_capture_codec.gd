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

func test_actual_alpha_trait_packet_decodes_with_modern_loadout_without_mutating_source() -> void:
	var original := SPECIES.spawn("mosshell")
	var packet := preload("res://scripts/creatures/traits.gd").roll_spawn("capture-world", "wild_once_1900", 1, true, false, false)
	assert_false(packet.is_empty())
	assert_true(original.loadout_initialized)
	var payload := CODEC.encode(original)
	var before := payload.duplicate(true)
	var traits_before := packet.duplicate(true)
	var restored := CODEC.decode(payload, packet)
	assert_true(restored != null, "Modern Alpha offer must decode with its actual retained traits")
	if restored != null:
		assert_eq(restored.uid, original.uid)
		assert_eq(restored.known_moves, original.known_moves)
		assert_eq(restored.rolled_traits, packet.rolled_traits)
		assert_eq(restored.get_meta("foundation_capture_traits"), packet)
		assert_eq(CODEC.encode(restored), payload)
	var offer := {"offer_id": "real-source-offer", "source_key": "capture:real-source-offer",
		"world_namespace": "capture-world", "session_id": "epoch", "participants": ["guest-owner"],
		"realm": "meadows", "creature": payload, "capture_traits": packet}
	assert_true(preload("res://scripts/net/foundation_capture_rules.gd").offer_valid(offer))
	assert_eq(payload, before)
	assert_eq(packet, traits_before)
	var malformed := payload.duplicate(true)
	malformed.known_moves.append("forged_move")
	assert_true(CODEC.decode(malformed, packet) == null, "Mirror construction cannot repair invalid source moves")
	var forged := packet.duplicate(true)
	forged.captured_from.spawn_generation = 0
	assert_true(CODEC.decode(payload, forged) == null)

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

func test_complete_legacy_capture_shape_remains_valid_without_loadout_adoption() -> void:
	var original := populated()
	original.loadout_initialized = false
	original.known_moves.clear()
	original.move_mastery_uses = {}
	original.move_mastery_receipts = {}
	original.move_utility = ""
	original.move_ultimate = ""
	original.loadout_revision = 0
	original.loadout_last_edit = {}
	var payload := CODEC.encode(original)
	assert_false(payload.is_empty())
	assert_false(payload.has("known_moves"))
	var restored := CODEC.decode(JSON.parse_string(JSON.stringify(payload)))
	assert_true(restored != null)
	if restored == null: return
	assert_false(restored.loadout_initialized)
	assert_eq(restored.uid, original.uid)
	var actual := CODEC.encode(restored)
	assert_eq(actual.size(), payload.size())
	for key: String in payload:
		if payload[key] is float:
			assert_true(is_equal_approx(float(actual[key]), float(payload[key])), "Legacy saved float survives: " + key)
		else:
			assert_eq(actual[key], payload[key], "Legacy saved field survives: " + key)

func test_new_capture_loadout_is_complete_and_semantically_valid_or_refused() -> void:
	var valid := CODEC.encode(populated())
	assert_false(valid.is_empty())
	assert_true(valid.has("known_moves"))
	assert_true(CODEC.decode(valid) != null)
	for field: String in ["known_moves", "move_mastery_uses", "move_mastery_receipts",
		"move_utility", "move_ultimate", "loadout_revision", "loadout_last_edit"]:
		var partial := valid.duplicate(true)
		partial.erase(field)
		assert_true(CODEC.decode(partial) == null, "Partial new document never enters legacy path: " + field)
	for pair: Array in [["known_moves", ["invented_move"]], ["move_mastery_uses", {"invented_move": 1}],
		["loadout_revision", 0.5], ["move_utility", "invented_move"], ["loadout_last_edit", {"edit_id": "forged"}]]:
		var malformed := valid.duplicate(true)
		malformed[pair[0]] = pair[1]
		assert_true(CODEC.decode(malformed) == null, "Refuse malformed new document: " + str(pair[0]))


## Portable owner records (character_record_rules.portable_projection, since
## 187a3f24) leave out each card's in-fight energy meter. A host decoding
## such a card got null from both entry points, so the F20 guest homecoming
## and every other host-side read of a portable party failed silently.
func test_portable_projection_cards_decode_and_decode_owned_without_energy() -> void:
	var game := preload("res://autoload/game_state.gd").new()
	game.reset_for_new_game()
	game.local.character_id = "character-portable"
	assert_true(game.party.call("add", game.local.call("make_creature", "terrapup", "Pip")))
	var personal: Dictionary = preload("res://scripts/net/character_record_rules.gd").portable_projection(game.local.save_data())
	var card: Dictionary = personal.party[0]
	assert_false(card.has("energy"), "the portable card has no energy")
	var owned: RefCounted = CODEC.decode_owned(card, personal.redesign_character)
	assert_true(owned != null, "decode_owned reads the portable card")
	assert_eq(owned.get("uid"), card.uid)
	assert_eq(float(owned.get("energy")), 0.0, "the transient meter starts empty")
	var wild: Dictionary = CODEC.encode(populated())
	wild.erase("energy")
	var decoded: RefCounted = CODEC.decode(wild)
	assert_true(decoded != null, "decode reads a card without its energy")
	assert_false(wild.has("energy"), "the caller's wild card is not mutated")
	assert_false(card.has("energy"), "the caller's card is not mutated")
	var broken: Dictionary = card.duplicate(true)
	broken.erase("level")
	assert_true(CODEC.decode_owned(broken, personal.redesign_character) == null, "any other missing field still refuses")
	game.free()

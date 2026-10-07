extends "res://tests/test_case.gd"

## F31#2 (HOMESTEAD §4, RD-20): hanging biome N's relic grants biome N+1's
## attachment blueprints to that character, once, inside the relic_hang
## receipt. Meadows attachments need no blueprint. Pure stage functions.
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const RULES := preload("res://scripts/build/station_rules.gd")


func _character(held: Array) -> Dictionary:
	return {"character_id": "character-test", "redesign_character": {
		"relics_held": held.duplicate(), "relics_hung": [], "transaction_receipts": [], "attachment_recipes": []}}


func _hang(current: Dictionary, biome: String) -> Dictionary:
	return ACTIONS._relic(current, "relic_hang", {"biome": biome}, {"pedestal_biome": biome, "realm": "meadows"})


func test_meadows_relic_grants_the_tidewake_column() -> void:
	var result := _hang(_character(["meadows"]), "meadows")
	assert_true(result.get("ok") == true, "hang accepted")
	var known: Array = result.state.redesign_character.attachment_recipes
	known.sort()
	assert_eq(known, ["altar_tidewake", "den_tidewake", "forge_tidewake", "kitchen_tidewake"], "next tier only, every station")
	assert_true(result.state.redesign_character.relics_hung.has("meadows"))


func test_each_relic_unlocks_the_next_tier_and_stormwood_the_reserved_fifth() -> void:
	var cfg := RULES.config()
	assert_eq(RULES.next_tier_blueprints(cfg, "tidewake").size(), 4)
	assert_true(RULES.next_tier_blueprints(cfg, "tidewake").has("forge_cloudreach"))
	assert_true(RULES.next_tier_blueprints(cfg, "cloudreach").has("den_stormwood"))
	var fifth := RULES.next_tier_blueprints(cfg, "stormwood")
	assert_eq(fifth.size(), 4, "Stormwood's relic unlocks the reserved tier 5 column")
	assert_true(fifth.has("altar_biome5"))
	assert_true(RULES.next_tier_blueprints(cfg, "not_a_biome").is_empty())
	# Exercise the actual hang action for every live handoff, including the
	# reserved fifth column, rather than only the configuration helper.
	for biome: String in ["meadows", "tidewake", "cloudreach", "stormwood"]:
		var expected := RULES.next_tier_blueprints(cfg, biome)
		expected.sort()
		var original := _character([biome])
		var frozen := var_to_bytes(original)
		var granted := _hang(original, biome)
		assert_true(granted.get("ok") == true, "actual hang: " + biome)
		assert_eq(var_to_bytes(original), frozen, "staging preserves the original owner record")
		if granted.get("ok") != true: continue
		var actual: Array = granted.state.redesign_character.attachment_recipes
		actual.sort()
		assert_eq(actual, expected, "exact next-column action grant: " + biome)
		assert_eq(granted.state.redesign_character.relics_hung, [biome])
		assert_eq((granted.state.redesign_character.transaction_receipts as Array).count("relic_hang:%s:character-test" % biome), 1)


func test_the_grant_is_once_and_keeps_earlier_blueprints() -> void:
	var first := _hang(_character(["meadows", "tidewake"]), "meadows")
	var second := _hang(first.state, "tidewake")
	assert_true(second.get("ok") == true)
	var known: Array = second.state.redesign_character.attachment_recipes
	assert_eq(known.size(), 8, "Tidewake and Cloudreach columns, no duplicates")
	var again := _hang(second.state, "tidewake")
	assert_true(again.get("ok") != true, "a second hang of the same relic is refused (no second grant)")


func test_without_the_relic_nothing_is_granted() -> void:
	var result := _hang(_character([]), "meadows")
	assert_eq(result.get("code"), "personal_relic_required")

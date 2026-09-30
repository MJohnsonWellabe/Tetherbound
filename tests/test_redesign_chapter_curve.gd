extends "res://tests/test_case.gd"

## F19#1: pins the authored RD-10 targets and real runtime encounter tables.
## Does not prove the earned hybrid-level ledger (F27/F47) or route time.
const ORDER := preload("res://scripts/data/biome_order.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const REWARDS := preload("res://scripts/net/encounter_rewards.gd")


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "missing/invalid curve input: " + path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _ints(raw: Array) -> Array:
	var out: Array = []
	for value: Variant in raw:
		out.append(int(value))
	return out


func _levels(team: Array) -> Array:
	var out: Array = []
	for raw: Variant in team:
		out.append(int((raw as Dictionary).get("level", 0)))
	return out


func test_four_chapter_curve_uses_foundation_order_and_pins_owner_envelopes() -> void:
	assert_eq(ORDER.runtime_ids(), ["meadows", "water", "cloudreach", "stormwood"])
	var chapters: Dictionary = CURVE.config().get("chapters", {})
	var targets := {"meadows": [3, 22, 2, 20], "water": [20, 33, 18, 32],
		"cloudreach": [31, 44, 29, 43], "stormwood": [42, 55, 40, 54]}
	assert_eq(chapters.size(), 4)
	for realm: String in ORDER.runtime_ids():
		var chapter: Dictionary = chapters.get(realm, {})
		var team: Dictionary = chapter.get("team", {})
		var wild: Array = chapter.get("wild_band", [])
		assert_eq([int(team.get("enter", 0)), int(team.get("exit", 0))]
			+ _ints(wild), targets[realm], realm + " curve drift")
		assert_eq(int(chapter.get("recommended_level", 0)), int(team.get("enter", 0)))
		assert_false(chapter.has("min_level"), "recommendation must never become a portal gate")


func test_meadows_retains_contiguous_split_and_replacement_catches() -> void:
	var expected := [[3, 9, 2, 6], [9, 12, 7, 10], [12, 15, 10, 13],
		[15, 18, 13, 17], [18, 22, 16, 20]]
	var regions: Array = CURVE.regions(CURVE.config())
	assert_eq(regions.size(), expected.size())
	var last_exit := 3
	for index in regions.size():
		var region: Dictionary = regions[index]
		var team: Dictionary = region.get("team", {})
		var wild: Array = region.get("wild_band", [])
		assert_eq([int(team.get("enter", 0)), int(team.get("exit", 0))]
			+ _ints(wild), expected[index])
		assert_eq(int(team.get("enter", 0)), last_exit)
		assert_true(int(wild[0]) <= int(team.get("enter", 0)))
		assert_true(int(wild[1]) <= int(team.get("exit", 0)))
		assert_true(int(wild[1]) >= int(team.get("enter", 0)) - 2)
		last_exit = int(team.get("exit", 0))


func _assert_wild_tables(tables: Array, low: int, high: int) -> void:
	var actual_low := 1000
	var actual_high := 0
	for raw: Variant in tables:
		var table: Dictionary = raw
		var levels: Array = table.get("level_range", [])
		assert_eq(levels.size(), 2, str(table.get("id", "")))
		if levels.size() != 2:
			continue
		assert_true(int(levels[0]) <= int(levels[1]))
		assert_true(int(levels[0]) >= low and int(levels[1]) <= high,
			str(table.get("id", "")) + " exceeds the owner wild envelope")
		actual_low = mini(actual_low, int(levels[0]))
		actual_high = maxi(actual_high, int(levels[1]))
	assert_eq([actual_low, actual_high], [low, high], "entire envelope must remain represented")


func test_runtime_wild_tables_span_the_new_chapter_envelopes() -> void:
	_assert_wild_tables(_read("res://data/config/water_encounters.json").get("tables", []), 18, 32)
	_assert_wild_tables(_read("res://data/config/cloudreach_chapter.json").get("encounter_tables", []), 29, 43)
	_assert_wild_tables(_read("res://data/config/stormwood_encounters.json").get("tables", []), 40, 54)


func test_each_named_boss_team_matches_the_pinned_curve() -> void:
	var specs := [
		["res://data/config/trainers.json", "warden_aldis", "team", [21, 21, 21, 22, 22]],
		["res://data/config/water_characters.json", "water_trainer_nerissa", "team", [32, 32, 33, 33]],
		["res://data/config/stormwood_trainers.json", "captain_marrow_dynamo_core", "party", [54, 54, 54, 55, 55]],
	]
	for raw: Variant in specs:
		var spec: Array = raw
		var data: Dictionary = BAND_CONTENT.load_config(str(spec[0]), "trainers") \
			if str(spec[0]).ends_with("/trainers.json") else _read(str(spec[0]))
		var found := false
		for trainer: Variant in data.get("trainers", []):
			var row: Dictionary = trainer
			if str(row.get("id", "")) == str(spec[1]):
				found = true
				assert_eq(_levels(row.get(str(spec[2]), [])), spec[3], str(spec[1]))
		assert_true(found, "missing named boss " + str(spec[1]))
	var cloud := _read("res://data/config/cloudreach_chapter.json")
	for raw: Variant in cloud.get("trainer_ladder", []):
		var row: Dictionary = raw
		if str(row.get("id", "")) == "captain_veyra_storm_anchor":
			assert_eq(_levels((row.get("team_contract", {}) as Dictionary).get("slots", [])), [43, 43, 44])
	assert_eq(_levels((cloud.get("final_encounter", {}).get("opposition_contract", {}) as Dictionary).get("slots", [])), [43, 43, 44])


func test_meadows_alpha_ceiling_preserves_bonuses_within_chapter_exit() -> void:
	var spawns: Array = BAND_CONTENT.load_config("res://data/config/spawns.json", "spawns").get("spawns", [])
	for raw: Variant in spawns:
		var row: Dictionary = raw
		var at: Array = row.get("centre", [])
		if at.size() < 3:
			continue
		var range: Array = CURVE.wild_band_at(float(at[2]), CURVE.config())
		for key: String in ["alpha", "elder"]:
			var leader: Dictionary = row.get(key, {})
			if leader.is_empty():
				continue
			var maximum := int(range[1]) + int(leader.get("level_bonus", 0))
			if maximum > 20:
				assert_eq(int(leader.get("level_ceiling", 0)), 20, "leader above Meadows envelope: " + str(row.get("order", 0)))


func test_stormheart_uses_existing_legendary_and_volunteers() -> void:
	var captive: Dictionary = _read("res://data/config/stormwood_dynamo.json").get("captive", {})
	assert_eq(str(captive.get("placeholder_species", "")), "fulgocobra")
	assert_eq(int(captive.get("level", 0)), 55)
	var offer: Dictionary = _read("res://data/config/stormwood_encounters.json").get("legendary_placeholder", {})
	assert_eq(str(offer.get("placeholder_species", "")), "fulgocobra")
	assert_false(bool(offer.get("catchable", true)))
	assert_eq(int(_read("res://data/config/water_alpha.json").get("level", 0)), 26)
	assert_eq(int((_read("res://data/config/cloudreach_solmane_climax.json").get("legendary", {}) as Dictionary).get("level", 0)), 44)


func test_boss_hand_offs_keep_typed_keys_distinct_from_item_skus() -> void:
	var config := _read("res://data/config/chapter_rewards.json")
	var targets := {
		"warden_aldis": ["meadows", "meadows", "tidewake_portal_key", "portal_key_tidewake"],
		"water_trainer_nerissa": ["water", "tidewake", "cloudreach_portal_key", "portal_key_cloudreach"],
		"captain_veyra_storm_anchor": ["cloudreach", "cloudreach", "stormwood_portal_key", "portal_key_stormwood"],
		"captain_marrow_dynamo_core": ["stormwood", "stormwood", "fifth_portal_key", "portal_key_biome5"],
	}
	assert_eq((config.get("boss_hand_offs", {}) as Dictionary).size(), 4)
	for trainer: String in targets:
		var want: Array = targets[trainer]
		var row := REWARDS.chapter_hand_off(trainer, str(want[0]), config)
		assert_eq([row.get("runtime_realm"), row.get("relic_biome"),
			row.get("portal_key_item"), row.get("portal_key_id")], want)
		var grants: Array = REWARDS.chapter_grants(trainer, str(want[0]), [1, 2, 2], config)
		assert_eq(grants.size(), 2)
		if grants.size() != 2:
			continue
		var key: Dictionary = grants[0]
		var relic: Dictionary = grants[1]
		assert_eq(key.get("peers"), [1, 2], "one full reward for each admitted participant")
		assert_eq(relic.get("peers"), [1, 2])
		assert_eq(key.get("item"), want[2])
		assert_eq(int(key.get("count", 0)), 1)
		assert_eq(relic.get("relic_biome"), want[1])
		assert_eq(key.get("source"), "trainer:%s:item:%s" % [trainer, str(want[2])])
		assert_eq(relic.get("source"), "trainer:%s:relic:%s" % [trainer, str(want[1])])
		assert_eq(REWARDS.chapter_grants(trainer, "wrong_realm", [1], config), [])
		assert_eq(REWARDS.chapter_grants(trainer, str(want[0]), [], config), [])
	assert_eq(REWARDS.chapter_grants("not_a_boss", "meadows", [1], config), [])

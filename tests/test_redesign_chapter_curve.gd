extends "res://tests/test_case.gd"

## F19#1: pins the authored RD-10 targets and real runtime encounter tables.
## Does not prove the earned hybrid-level ledger (F27/F47) or route time.
const ORDER := preload("res://scripts/data/biome_order.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const REWARDS := preload("res://scripts/net/encounter_rewards.gd")
const POLICY := preload("res://scripts/creatures/level_curve_policy.gd")


## F19#3 config gate scan. This inspects authored prerequisite fields; actual
## portal admission and traversal remain separate runtime proof obligations.
func _gate_strings(node: Variant, out: Array[String], prerequisite: bool = false) -> void:
	if node is Dictionary:
		for raw_key: Variant in node:
			var key := str(raw_key).to_lower()
			if key.begins_with("_"):
				continue
			var gated := prerequisite or key.begins_with("require") or key.begins_with("need") \
				or key in ["access", "gate", "map_reveal_requires", "unlock_prerequisite"]
			if gated and node[raw_key] is bool and bool(node[raw_key]):
				out.append(key)
			_gate_strings(node[raw_key], out, gated)
	elif node is Array:
		for raw: Variant in node:
			_gate_strings(raw, out, prerequisite)
	elif node is String and prerequisite:
		out.append(str(node).to_lower())


func test_authored_traversal_gates_do_not_require_fly_in_tidewake_or_later_rewards() -> void:
	var files := DirAccess.get_files_at("res://data/config")
	for realm: String in ["water", "cloudreach", "stormwood"]:
		var scanned := 0
		var prerequisites: Array[String] = []
		for file: String in files:
			if not file.begins_with(realm + "_") or not file.ends_with(".json"):
				continue
			var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/" + file))
			assert_true(raw is Dictionary or raw is Array, "invalid gate input: " + file)
			scanned += 1
			_gate_strings(raw, prerequisites)
		assert_true(scanned > 0 and not prerequisites.is_empty(), realm + " gate scan reached real prerequisite fields")
		for gate: String in prerequisites:
			if realm == "water":
				assert_false(gate == "fly" or gate.contains("flight") or gate.contains("fly_traversal") \
					or gate.contains("requires_fly") or gate.contains("require_fly"), "Tidewake Fly gate: " + gate)
			if realm == "cloudreach":
				assert_false(gate.contains("fulgocobra") or gate.contains("stormheart") \
					or gate.contains("realm_heart_stormwood") or gate.contains("stormwood:legendary"),
					"Cloudreach assumes Stormwood's later reward: " + gate)
			if realm in ["cloudreach", "stormwood"]:
				for future: String in ["biome5", "biome6", "biome7", "biome8"]:
					assert_false(gate.contains(future + "_relic") or gate.contains("realm_heart_" + future) \
						or gate.contains(future + ":legendary"), "unreleased biome reward gate: " + gate)


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "missing/invalid curve input: " + path)
	if not parsed is Dictionary:
		return {}
	return _candidate_view(path, parsed as Dictionary)


## The production JSON already carries the new levels. A manifest application
## must therefore be idempotent, never a substitute for checking the live data.
func _candidate_view(path: String, base: Dictionary) -> Dictionary:
	var authored := POLICY.config()
	assert_eq(authored.get("runtime_enabled"), true)
	if not (authored.get("overlays", {}) as Dictionary).has(path.trim_prefix("res://")):
		return base
	var next := POLICY.apply(path, base, true, authored)
	assert_false(next.is_empty(), "manifest refuses stale level/identity: " + path)
	assert_eq(next, base, "live data already contains RD-10: " + path)
	return base


func _candidate_curve() -> Dictionary:
	return _candidate_view(CURVE.CONFIG_PATH, CURVE.config())


func _candidate_bands(key: String) -> Dictionary:
	var head := BAND_CONTENT.load_config("res://data/config/%s.json" % key, key).duplicate(true)
	var rows: Array = []
	for band: String in BAND_CONTENT.BANDS:
		var path := "res://data/config/bands/%s/%s.json" % [band, key]
		if FileAccess.file_exists(path):
			rows.append_array(_read(path).get(key, []))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.order) < int(b.order))
	head[key] = rows
	return head


func _ints(raw: Array) -> Array:
	var out: Array = []
	for value: Variant in raw:
		assert_true(value is int or value is float, "candidate level must be numeric")
		if not (value is int or value is float):
			continue
		assert_true(is_finite(float(value)) and float(value) == floorf(float(value)),
			"candidate level must be finite and integral before normalization")
		if is_finite(float(value)) and float(value) == floorf(float(value)):
			out.append(int(value))
	return out


func _levels(team: Array) -> Array:
	var out: Array = []
	for raw: Variant in team:
		out.append(int((raw as Dictionary).get("level", 0)))
	return out


func _assert_no_level_gate(node: Variant, context: String) -> void:
	if node is Dictionary:
		for raw_key: Variant in node:
			var key := str(raw_key)
			if key.begins_with("_"):
				continue
			if key in ["min_level", "challenge_level"]:
				assert_true(int(node[raw_key]) <= 0,
					"recommended levels must not hard-gate a chapter fight: " + context + "/" + key)
			_assert_no_level_gate(node[raw_key], context + "/" + key)
	elif node is Array:
		for index in node.size():
			_assert_no_level_gate(node[index], context + "/" + str(index))


func test_chapter_trainers_have_no_active_hidden_level_gate() -> void:
	var meadows := BAND_CONTENT.load_config("res://data/config/trainers.json", "trainers")
	assert_true((meadows.get("trainers", []) as Array).size() > 0)
	_assert_no_level_gate(meadows, "Meadows merged trainers")
	for path: String in ["res://data/config/water_characters.json",
			"res://data/config/cloudreach_chapter.json", "res://data/config/stormwood_trainers.json"]:
		_assert_no_level_gate(_read(path), path)


func test_four_chapter_curve_uses_foundation_order_and_pins_owner_envelopes() -> void:
	assert_eq(ORDER.runtime_ids(), ["meadows", "water", "cloudreach", "stormwood"])
	var chapters: Dictionary = _candidate_curve().get("biomes", {})
	var targets := {"meadows": [3, 22, 2, 20], "water": [20, 33, 18, 32],
		"cloudreach": [31, 44, 29, 43], "stormwood": [42, 55, 40, 54]}
	assert_eq(chapters.size(), 4)
	for realm: String in ORDER.runtime_ids():
		var biome := "tidewake" if realm == "water" else realm
		var chapter: Dictionary = chapters.get(biome, {})
		var team: Array = chapter.get("team", [])
		var wild: Array = chapter.get("wild", [])
		assert_eq(_ints(team) + _ints(wild), targets[realm], realm + " curve drift")
		assert_eq(int(chapter.get("recommended_level", 0)), int(team[0]))
		assert_false(chapter.has("min_level"), "recommendation must never become a portal gate")


func test_meadows_retains_contiguous_split_and_replacement_catches() -> void:
	var expected := [[3, 9, 2, 6], [9, 12, 7, 8], [12, 15, 9, 13],
		[15, 18, 12, 16], [18, 22, 16, 20]]
	var regions: Array = CURVE.regions(_candidate_curve())
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
		var data: Dictionary = _candidate_bands("trainers") \
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
	var spawns: Array = _candidate_bands("spawns").get("spawns", [])
	for raw: Variant in spawns:
		var row: Dictionary = raw
		var at: Array = row.get("centre", [])
		if at.size() < 3:
			continue
		var range: Array = CURVE.wild_band_at(float(at[2]), _candidate_curve())
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
	assert_eq(int((_read("res://data/config/stormwood_chapter.json").get("final_encounter", {}) as Dictionary).get("legendary_level", 0)), 55)
	assert_eq(POLICY.config().get("runtime_enabled"), true, "the actual joining path uses RD-10")
	var live_dynamo: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_dynamo.json"))
	assert_true(live_dynamo is Dictionary, "the actual captive remains authored")
	if live_dynamo is Dictionary:
		var live_captive: Dictionary = live_dynamo.get("captive", {})
		assert_eq(float(live_captive.get("level", 0)), 55.0, "live captive matches the last chapter's level")
	assert_eq(preload("res://scripts/world/stormwood_ending.gd").legendary_level(), 55,
		"the actual joining companion reads the live level55")
	var offer: Dictionary = _read("res://data/config/stormwood_encounters.json").get("legendary_placeholder", {})
	assert_eq(str(offer.get("placeholder_species", "")), "fulgocobra")
	assert_false(bool(offer.get("catchable", true)))
	assert_eq(int(_read("res://data/config/water_alpha.json").get("level", 0)), 26)
	assert_eq(int((_read("res://data/config/cloudreach_solmane_climax.json").get("legendary", {}) as Dictionary).get("level", 0)), 44)


func test_numeric_activation_preserves_chapter_arrival_prerequisite_identities() -> void:
	var expected_entry := {"cloudreach": ["realm_key_cloudreach"], "stormwood": ["realm_key_stormwood"]}
	var expected_arrival := {"cloudreach": "cloudreach_arrive", "stormwood": "stormwood_chapter_started"}
	for realm: String in ["cloudreach", "stormwood"]:
		var old_key := "realm_key_" + realm
		var path := "res://data/config/%s_chapter.json" % realm
		var live: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var acts: Array = live.get("acts", [])
		assert_false(acts.is_empty(), "legacy arrival remains authored")
		assert_eq(_read(path).get("acts", []), acts, "a numeric candidate never changes admission guards")
		if not acts.is_empty():
			assert_eq(acts[0].get("entry_flags", []), expected_entry[realm],
				"numeric activation preserves each realm's saved entry contract")
		var legacy_arrivals := 0
		for act: Dictionary in acts:
			for row: Dictionary in act.get("objectives", []):
				if str(row.get("id", "")) == expected_arrival[realm]:
					legacy_arrivals += 1
					assert_eq(row.get("requires_flags", []), [old_key], "the arrival objective retains its saved key guard")
				else:
					assert_false((row.get("requires_flags", []) as Array).has(old_key))
		assert_eq(legacy_arrivals, 1, "retain each realm's exact guarded arrival identity")
	var npc_config := _read("res://data/config/cloudreach_npc_runtime.json")
	var expected_guards := {"cloudreach_aila_arrival": ["realm_key_cloudreach", "cloudreach_chapter_started"],
		"cloudreach_maela_flight_trial": ["realm_key_cloudreach", "windscar_aerie_prepared"]}
	var guards_found := 0
	for guard: Dictionary in npc_config.get("dialogue_event_guards", []):
		var conversation := str(guard.get("conversation", ""))
		if expected_guards.has(conversation):
			guards_found += 1
			assert_eq(guard.get("requires_flags", []), expected_guards[conversation])
	assert_eq(guards_found, 2, "both live arrival/trial event guards retain their story prerequisite")
	var trial_found := false
	for npc: Dictionary in npc_config.get("npcs", []):
		if str(npc.get("id", "")) != "keeper_maela":
			continue
		for greeting: Dictionary in npc.get("greeting_when", []):
			if str(greeting.get("conversation", "")) == "cloudreach_maela_flight_trial":
				trial_found = true
				assert_eq(greeting.get("if_flag", []), ["windscar_aerie_prepared"])
	assert_true(trial_found, "actual Maela trial greeting remains available after canonical portal arrival")


func test_numeric_activation_preserves_saved_stormwood_aftermath_and_consumed_key_contract() -> void:
	var chapter := _read("res://data/config/stormwood_chapter.json")
	var rewards: Dictionary = chapter.get("rewards", {})
	assert_eq(rewards.get("next_realm_key"), "portal_key_biome5")
	assert_false(bool(rewards.get("next_realm_enterable", true)), "the fifth key never opens a live biome")
	var aftermath_found := false
	for act: Dictionary in chapter.get("acts", []):
		for objective: Dictionary in act.get("objectives", []):
			if str(objective.get("id", "")) != "stormwood_waterward_revealed":
				continue
			aftermath_found = true
			assert_eq(objective.get("completion_event"), "aftermath:waterward_view",
				"retain the existing durable event identity")
			assert_eq(objective.get("requires_flags"), ["stormwood:legendary_offer_made"],
				"numeric activation preserves the saved aftermath story prerequisite")
			assert_eq(objective.get("grants_flags"), ["realm_key_water", "waterward_route_revealed", "stormwood:chapter_complete"],
				"numeric activation retains the saved view grant identities")
			assert_eq(objective.get("consumed_grants"), {"realm_key_water": "realm_gate_water_unlocked"},
				"the legacy key keeps its existing gate consumption mapping")
			assert_eq(objective.get("how"), "Return to the high platform for the newly clear view of water.",
				"numeric activation retains the authored view instruction")
	assert_true(aftermath_found, "actual Stormwood aftermath remains authored")


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

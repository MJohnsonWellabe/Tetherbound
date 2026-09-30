extends "res://tests/test_case.gd"

const DATA := preload("res://scripts/data/redesign_data.gd")
const BIOMES := preload("res://scripts/data/biome_order.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")

func test_every_authored_contract_validates() -> void:
	for domain: String in DATA.DOMAINS:
		var result := DATA.load_catalog(domain)
		assert_true(result.ok, "%s: %s" % [domain, result.get("errors", [])])

func test_missing_unknown_and_duplicate_ids_fail_in_every_table() -> void:
	for domain: String in DATA.DOMAINS:
		var value: Variant = DATA.json(DATA.ROOT + domain + ".json")
		var schema: Dictionary = DATA.json(DATA.ROOT + domain + ".schema.json")
		if value is Array:
			var unknown: Array = value.duplicate(true)
			unknown[0].id = "does_not_exist"
			assert_false((DATA.validate(unknown, schema) + DATA._relations(domain, unknown)).is_empty(), domain + " must reject unknown id")
			var missing: Array = value.duplicate(true)
			missing[0].erase("id")
			assert_false(DATA.validate(missing, schema).is_empty(), domain + " must reject missing id")
			var absent: Array = value.duplicate(true)
			absent.remove_at(0)
			assert_false((DATA.validate(absent, schema) + DATA._relations(domain, absent)).is_empty(), domain + " must reject absent row")
			var duplicate: Array = value.duplicate(true)
			if duplicate.size() > 1:
				duplicate[1] = duplicate[0].duplicate(true)
			else:
				duplicate.append(duplicate[0].duplicate(true))
			var path := "user://schema_duplicate.json"
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_string(JSON.stringify(duplicate))
			file.close()
			assert_false(DATA.load_catalog(domain, path).ok, domain + " rejects duplicate authored rows")
			DirAccess.remove_absolute(path)
		else:
			var unknown: Dictionary = value.duplicate(true)
			unknown.id = "does_not_exist"
			assert_false(DATA.validate(unknown, schema).is_empty())

func test_foreign_unknown_ids_and_wrong_slot_pairs_refuse() -> void:
	var cases := {
		"material_tiers": {"raws": ["does_not_exist"], "refined": "does_not_exist", "tier": 8, "biome": "stormwood"},
		"traits": {"effect": "does_not_exist"},
		"evolution_lines": {"source": "does_not_exist", "target": "does_not_exist", "extra_ingredient": "does_not_exist"},
		"attachments": {"station_id": "den"},
		"level_caps": {"level": 11},
		"portals": {"key_id": "portal_key_stormwood", "entry_id": "does_not_exist"},
		"waystones": {"entry_id": "does_not_exist"},
		"gear_tiers": {"slots": ["harness", "harness"]},
		"feasts": {"attuned_types": ["ground", "ground", "ground", "ground", "ground", "ground", "ground", "ground"]},
	}
	for domain: String in cases:
		for field: String in cases[domain]:
			var value: Array = DATA.json(DATA.ROOT + domain + ".json").duplicate(true)
			value[0][field] = cases[domain][field]
			assert_false(DATA._relations(domain, value).is_empty(), "%s.%s must refuse" % [domain, field])

func test_eight_slots_have_exactly_four_live_and_four_sealed() -> void:
	assert_eq(BIOMES.ids(), ["meadows", "tidewake", "cloudreach", "stormwood", "biome5", "biome6", "biome7", "biome8"])
	for domain: String in ["material_tiers", "gear_tiers", "portals"]:
		var value: Array = DATA.json(DATA.ROOT + domain + ".json")
		var live := 0
		for row: Dictionary in value:
			if row.status == "live": live += 1
		assert_eq(live, 4, domain)
		for row: Dictionary in value:
			row.biome = "meadows"
			row.status = "live"
		assert_false(DATA._relations(domain, value).is_empty())
	for id: String in BIOMES.ids().slice(4): assert_eq(BIOMES.display_name(id), "Sealed")
	assert_eq(BIOMES.runtime_ids(), ["meadows", "water", "cloudreach", "stormwood"])
	assert_false(BIOMES.legacy_physical_crossings())

func test_durable_schema_rejects_unknown_fields_ids_and_unowned_uid() -> void:
	var state := STATE.defaults("character")
	assert_eq(STATE.validate("character", state), [])
	state.portal_unlocks = ["unknown_biome"]
	assert_false(STATE.validate("character", state).is_empty())
	state = STATE.defaults("world")
	state.undeclared = true
	assert_false(STATE.validate("world", state).is_empty())
	state = STATE.defaults("character")
	state.last_waystones = {"meadows": "stormwood_entry"}
	assert_false(STATE.validate("character", state).is_empty())
	state = STATE.defaults("character")
	state.creatures = {"unowned": {}}
	assert_false(STATE.validate("character", state, []).is_empty())

func test_registry_declares_scope_transactions_and_every_schema_field() -> void:
	var registry: Dictionary = DATA.json("res://data/progression/flag_scopes.json").get("durable_fields", {})
	for scope: String in ["world", "character"]:
		var defaults := STATE.defaults(scope)
		for field: String in defaults:
			var path := "redesign_%s.%s" % [scope, field]
			assert_true(registry.has(path), path)
			var row: Dictionary = registry.get(path, {})
			assert_eq(str(row.get("scope", "")), scope)
			assert_true(not str(row.get("transaction", "")).is_empty())
			assert_true(not str(row.get("authority", "")).is_empty())
			assert_true(not str(row.get("persistence", "")).is_empty())

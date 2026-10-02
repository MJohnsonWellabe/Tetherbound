extends "res://tests/test_case.gd"

const WORLD := preload("res://autoload/world_state.gd")
const PRICE := [{"id": "stone", "n": 10}, {"id": "rootstone", "n": 4}, {"id": "ironwood", "n": 2}]

func _catalogue() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/items/buildables.json"))

func _altar(data: Dictionary) -> Dictionary:
	for row: Dictionary in data.homestead_buildables:
		if row.id == "altar": return row
	return {}

func test_real_homestead_altar_resolves_exact_settled_price_without_mutating_source() -> void:
	var data := _catalogue()
	var before := data.duplicate(true)
	assert_false((data.buildables as Array).any(func(row: Dictionary) -> bool: return row.id == "altar"),
		"the actual Altar is not a legacy buildable")
	assert_eq(WORLD.altar_recipe(), PRICE, "the production reader reaches the authored homestead Altar")
	var resolved: Array = WORLD.altar_recipe_from_catalogue(data)
	assert_eq(resolved, PRICE)
	resolved[0].n = 999
	assert_eq(data, before, "the returned price cannot mutate the raw catalogue")
	assert_eq(WORLD.altar_recipe_from_catalogue(data), PRICE)

func test_duplicate_altar_identity_in_either_catalogue_table_refuses() -> void:
	for table: String in ["buildables", "homestead_buildables"]:
		var data := _catalogue()
		data[table].append(_altar(data).duplicate(true))
		assert_eq(WORLD.altar_recipe_from_catalogue(data), [], "duplicate authored identity cannot choose a price")

func test_wrong_identity_price_and_malformed_catalogue_refuse() -> void:
	for field: String in ["station_id", "home_only", "category"]:
		var data := _catalogue()
		_altar(data)[field] = false if field == "home_only" else "another-station"
		assert_eq(WORLD.altar_recipe_from_catalogue(data), [])
	for invalid: Variant in [0, 11, 10.5, "10"]:
		var data := _catalogue()
		_altar(data).cost[0].n = invalid
		assert_eq(WORLD.altar_recipe_from_catalogue(data), [], "a free, altered, fractional or string price cannot authorize payment")
	var changed := _catalogue()
	_altar(changed).cost[1].id = "wood"
	assert_eq(WORLD.altar_recipe_from_catalogue(changed), [])
	changed = _catalogue()
	_altar(changed).cost.append({"id": "fiber", "n": 1})
	assert_eq(WORLD.altar_recipe_from_catalogue(changed), [])
	assert_eq(WORLD.altar_recipe_from_catalogue({"buildables": [], "homestead_buildables": []}), [])
	assert_eq(WORLD.altar_recipe_from_catalogue({"buildables": [], "homestead_buildables": {}}), [])

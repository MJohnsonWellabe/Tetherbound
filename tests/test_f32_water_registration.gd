extends "res://tests/test_case.gd"

## F32 acceptance #5 (registration half): the ten Tidewake water_crafting
## proposals are registered in the actual runtime item/recipe book. Uses the
## production ItemDB constructor (the same `ITEM_DB.new()` Game calls), never a
## hand-built dictionary.

const ITEM_DB := preload("res://autoload/item_db.gd")
const REGISTRATION := preload("res://scripts/world/f32_catalogue_registration.gd")
const WATER_PATH := "res://data/config/water_crafting.json"


func _runtime_books(db: Object) -> Array:
	var items := {}
	for id: Variant in db.ids():
		items[id] = db.definition(str(id))
	var recipes := {}
	for id: Variant in db.recipe_ids():
		recipes[id] = db.recipe(str(id))
	return [items, recipes]


func test_water_crafting_config_has_exactly_ten_recipes() -> void:
	var water: Variant = JSON.parse_string(FileAccess.get_file_as_string(WATER_PATH))
	assert_true(water is Dictionary, "water_crafting.json parses")
	assert_true(water.get("recipes") is Dictionary, "water_crafting.json has recipes")
	assert_eq(water.recipes.size(), 10, "exactly ten water recipes")


func test_production_item_db_registers_all_water_proposals() -> void:
	var books := _runtime_books(ITEM_DB.new())
	var errors := REGISTRATION.water_registration_errors(books[0], books[1])
	assert_eq(errors, [] as Array[String], "registration errors: %s" % [errors])
	var water: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WATER_PATH))
	for id: String in water.recipes:
		assert_true(books[1].has(id), "runtime recipe book has " + id)
	for id: String in water.item_registration_proposals:
		assert_true(books[0].has(id), "runtime item book has " + id)


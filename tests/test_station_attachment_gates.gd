extends "res://tests/test_case.gd"

## F31#1 recipe tier requires the attachment; F31#3 each station shows ONE
## next-upgrade target with ONE missing requirement. Pure stage/projection
## functions on the real stations config and F16 catalog.
const ACTIONS := preload("res://scripts/build/station_actions.gd")
const NEXT := preload("res://scripts/build/station_next_upgrade.gd")
const RULES := preload("res://scripts/build/station_rules.gd")
const CRAFT_ID := "0123456789abcdef0123456789abcdef"


func _context(station: String, tier: int) -> Dictionary:
	return {"character_id": "character-test", "expected_revision": 3, "homestead": true, "in_range": true,
		"in_combat": false, "recipe_known": true, "source_key": "home:kitchen", "station_id": station,
		"effective_tier": tier, "foundation_runtime_authorized": true}


func _craft(recipe_id: String, recipe: Dictionary, station: String, tier: int) -> Dictionary:
	return ACTIONS.stage_craft({"character_id": "character-test"}, 3, {"recipe_id": recipe_id, "craft_id": CRAFT_ID},
		_context(station, tier), recipe, true)


func test_a_kitchen_recipe_needs_the_kitchen_attachment() -> void:
	assert_eq(_craft("potion_small", {}, "kitchen", 0).get("code"), "attachment_required", "no Spice rack, no tier-1 cooking")
	assert_true(_craft("potion_small", {}, "kitchen", 1).get("code") != "attachment_required", "the Spice rack opens it")


func test_a_tier_two_recipe_needs_the_second_attachment() -> void:
	var recipe := {"station_id": "forge", "station_tier": 2}
	assert_eq(_craft("tier_two_probe", recipe, "forge", 1).get("code"), "attachment_required")
	assert_true(_craft("tier_two_probe", recipe, "forge", 2).get("code") != "attachment_required")


func test_the_wrong_station_never_crafts_it() -> void:
	assert_eq(_craft("potion_small", {}, "forge", 4).get("code"), "attachment_required")


func _blueprint(id: String) -> Dictionary:
	for row: Dictionary in RULES.config().attachments:
		if row.id == id:
			return row
	return {}


func _describe(station: String, tier: int, known: Array, inventory: Array, blueprint_id: String) -> Dictionary:
	var world := {"world_id": "world-test", "redesign_world": {"station_tiers": {station: tier}}}
	var me := {"character_id": "character-test", "redesign_character": {"attachment_recipes": known}, "inventory": inventory}
	return NEXT.describe(station, world, me, _blueprint(blueprint_id))


func test_a_new_forge_points_at_the_bellows_and_its_first_missing_cost() -> void:
	var view := _describe("forge", 0, [], [], "forge_meadows")
	assert_true(bool(view.get("visible")), "one target shown")
	assert_eq(view.get("name"), "Bellows")
	assert_eq(view.get("missing_requirement"), "Needs 8 Rootstone: Gather in Meadows", "one missing requirement, in cost order")


func test_tier_two_points_at_the_shrine_until_the_relic_is_hung() -> void:
	assert_eq(_describe("forge", 1, [], [], "forge_tidewake").get("missing_requirement"),
		"Hang the previous biome's relic in the Shrine Room.")
	var known := _describe("forge", 1, ["forge_tidewake"], [], "forge_tidewake")
	assert_true(str(known.get("missing_requirement")).begins_with("Needs 8 "), "with the blueprint, the next missing cost")


func test_a_fully_paid_attachment_reads_ready() -> void:
	var stock := [{"id": "rootstone", "n": 8}, {"id": "ironwood", "n": 8}, {"id": "rootiron_ingot", "n": 2}]
	var view := _describe("forge", 0, [], stock, "forge_meadows")
	assert_true(bool(view.get("requirements_satisfied")))
	assert_eq(view.get("missing_requirement"), "")
	for station: String in ["forge", "kitchen", "altar", "den"]:
		var starting := _describe(station, 0, [], stock, station + "_meadows")
		assert_true(starting.get("requirements_satisfied") == true,
			"Meadows attachment needs no personal relic/blueprint: " + station)
		assert_eq(starting.get("missing_requirement"), "", "no starting blueprint gate: " + station)


func test_after_stormwood_only_the_reserved_slot_remains() -> void:
	assert_eq(_describe("kitchen", 4, [], [], "kitchen_biome5").get("missing_requirement"), "Reserved for a future biome.")


func test_the_workbench_shows_no_attachment_track() -> void:
	var world := {"world_id": "world-test", "redesign_world": {"station_tiers": {}}}
	var view := NEXT.describe("workbench", world, {"character_id": "character-test", "redesign_character": {"attachment_recipes": []}})
	assert_false(bool(view.get("visible")))

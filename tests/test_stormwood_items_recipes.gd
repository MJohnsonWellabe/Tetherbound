extends "res://tests/test_case.gd"

## Integration-payload guard for Stormwood §13 and §§20–21. This reads the
## standalone payload directly because central ItemDB/buildable integration is
## deliberately owned by another lane.

const PAYLOAD_PATH := "res://data/config/stormwood_items_recipes.json"
const ITEMS_PATH := "res://data/items/items.json"
const CHAPTER_PATH := "res://data/config/stormwood_chapter.json"
const REQUIRED_RESOURCES := ["stormglass", "thunderwood", "conductor_vine", "glowmoss", "voltcap", "sparkfur"]
const REQUIRED_GEAR := ["insulated_helm", "insulated_vest", "insulated_leggings", "insulated_boots"]
const REQUIRED_BUILDABLES := ["stormglass_arch", "lightning_rod", "moss_lantern", "insulated_workbench_upgrade"]
const ARMOR_SLOTS := ["helmet", "upper_body", "lower_body", "boots", "backpack"]


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _payload() -> Dictionary:
	return _json(PAYLOAD_PATH)


func _known_item_ids(payload: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for id: String in (_json(ITEMS_PATH).get("items", {}) as Dictionary).keys():
		ids.append(id)
	for id: String in (payload.get("items", {}) as Dictionary).keys():
		if not ids.has(id):
			ids.append(id)
	return ids


func _chapter_flags() -> Array[String]:
	var persistent: Dictionary = _json(CHAPTER_PATH).get("persistent_flags", {})
	var flags: Array[String] = []
	for group: Variant in persistent.values():
		for flag: Variant in group as Array:
			flags.append(str(flag))
	return flags


func test_payload_is_a_stormwood_tier_three_package() -> void:
	var payload := _payload()
	assert_eq(str(payload.get("realm_id", "")), "stormwood")
	assert_false((payload.get("items", {}) as Dictionary).is_empty())
	assert_false((payload.get("recipes", {}) as Dictionary).is_empty())
	assert_false((payload.get("buildables", []) as Array).is_empty())


func test_exactly_six_required_stormwood_resources_are_authored() -> void:
	var items: Dictionary = _payload().get("items", {})
	for id in REQUIRED_RESOURCES:
		assert_true(items.has(id), "Stormwood §20 is missing resource '%s'" % id)
	assert_eq(REQUIRED_RESOURCES.size(), 6)


func test_all_four_insulated_gear_pieces_are_valid_equipment() -> void:
	var items: Dictionary = _payload().get("items", {})
	for id in REQUIRED_GEAR:
		var gear: Dictionary = items.get(id, {})
		assert_eq(str(gear.get("kind", "")), "armor", "%s must use the existing armor kind" % id)
		assert_true(ARMOR_SLOTS.has(str(gear.get("armor_slot", ""))), "%s names no existing armor slot" % id)
		assert_true(float(gear.get("defense", 0.0)) > 0.0, "%s must provide passive defense" % id)
		assert_true(float(gear.get("storm_strike_reduction", 0.0)) > 0.0, "%s must declare strike reduction" % id)
		assert_true(float(gear.get("static_duration_scale", 1.0)) < 1.0, "%s must shorten Static" % id)
		assert_true(ResourceLoader.exists(str(gear.get("world_model", ""))), "%s names no existing pickup model" % id)
		assert_true(float(gear.get("world_model_scale", 0.0)) > 0.0, "%s must state a pickup scale" % id)
	assert_eq(str((items.get("insulated_leggings", {}) as Dictionary).get("acquisition", "")), "found_pickup")
	assert_eq(str((items.get("insulated_boots", {}) as Dictionary).get("acquisition", "")), "found_pickup")


func test_recipes_meet_the_contract_count_and_cross_reference_items() -> void:
	var payload := _payload()
	var recipes: Dictionary = payload.get("recipes", {})
	var buildable_ids: Array[String] = []
	for entry: Variant in payload.get("buildables", []):
		buildable_ids.append(str((entry as Dictionary).get("id", "")))
	assert_true(recipes.size() >= 12, "Stormwood §20 requires at least twelve recipes")
	var known := _known_item_ids(payload)
	var chapter_flags := _chapter_flags()
	for id: String in recipes.keys():
		var recipe: Dictionary = recipes[id]
		assert_eq(str(recipe.get("realm_id", "")), "stormwood", "%s is not realm-scoped" % id)
		assert_true(chapter_flags.has(str(recipe.get("unlocked_by", ""))), "%s uses a flag absent from stormwood_chapter.json" % id)
		assert_false((recipe.get("cost", []) as Array).is_empty(), "%s has no cost" % id)
		var output: Dictionary = recipe.get("output", {})
		var output_id := str(output.get("id", ""))
		assert_true(known.has(output_id) or buildable_ids.has(output_id), "%s produces unresolved '%s'" % [id, output_id])
		for line: Variant in recipe.get("cost", []):
			var need: Dictionary = line
			assert_true(known.has(str(need.get("id", ""))), "%s costs unresolved '%s'" % [id, str(need.get("id", ""))])
			assert_true(int(need.get("n", 0)) > 0, "%s has a non-positive cost" % id)
	assert_eq(str((recipes.get("voltcap_stew", {}) as Dictionary).get("output", {}).get("id", "")), "voltcap_stew")
	assert_eq(str((recipes.get("glowmoss_tonic", {}) as Dictionary).get("output", {}).get("id", "")), "glowmoss_tonic")


func test_four_required_buildables_have_existing_models_icons_and_costs() -> void:
	var payload := _payload()
	var entries: Dictionary = {}
	for entry: Variant in payload.get("buildables", []):
		var piece: Dictionary = entry
		entries[str(piece.get("id", ""))] = piece
	var known := _known_item_ids(payload)
	for id in REQUIRED_BUILDABLES:
		assert_true(entries.has(id), "Stormwood §13 is missing buildable '%s'" % id)
		var piece: Dictionary = entries.get(id, {})
		assert_true(ResourceLoader.exists(str(piece.get("mesh", ""))), "%s names a missing model" % id)
		assert_true(ResourceLoader.exists(str(piece.get("thumbnail", ""))), "%s names a missing thumbnail" % id)
		assert_eq(str(piece.get("integration_status", "")), "blocked_pending_consumer", "%s must not be blindly merged into the current build table" % id)
		var requirements: Dictionary = piece.get("integration_requirements", {})
		assert_true((requirements.get("bounds", []) as Array).size() == 3, "%s needs explicit placement bounds" % id)
		assert_false(str(requirements.get("material", "")).is_empty(), "%s needs a material finish request" % id)
		assert_false((requirements.get("requires_flags", []) as Array).is_empty(), "%s needs a chapter placement gate" % id)
		assert_false(str(requirements.get("placement", "")).is_empty(), "%s needs a placement mode" % id)
		for line: Variant in piece.get("cost", []):
			var need: Dictionary = line
			assert_true(known.has(str(need.get("id", ""))), "%s costs unresolved '%s'" % [id, str(need.get("id", ""))])


func test_payload_item_icons_are_concrete_existing_assets() -> void:
	for id: String in (_payload().get("items", {}) as Dictionary).keys():
		var item: Dictionary = (_payload().get("items", {}) as Dictionary)[id]
		assert_true(ResourceLoader.exists(str(item.get("icon", ""))), "%s names a missing icon" % id)

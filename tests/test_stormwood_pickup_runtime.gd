extends "res://tests/test_case.gd"

const RUNTIME := preload("res://scripts/world/stormwood_pickup_runtime.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")


func test_catalogue_mounts_only_current_ordinary_item_definitions() -> void:
	var mounted := RUNTIME.ordinary_specs()
	assert_eq(mounted.size(), 222)
	for spec: Dictionary in mounted:
		assert_eq(str(spec.get("runtime_kind", "")), "item")
		assert_true(RUNTIME.item_definitions().has(str(spec.get("item_id", ""))))


func test_withheld_rows_are_story_events_or_missing_item_definitions() -> void:
	var withheld := RUNTIME.withheld_specs()
	assert_eq(withheld.size(), 7)
	var ids: Array[String] = []
	for spec: Dictionary in withheld:
		ids.append(str(spec.get("id", "")))
		if str(spec.get("runtime_kind", "")) == "story_reward":
			assert_false(bool(spec.get("collectible", true)))
		else:
			assert_false(RUNTIME.item_definitions().has(str(spec.get("item_id", ""))))
	assert_eq(ids, [
		"stormwood_pickup_pocket_202", "stormwood_pickup_pocket_203",
		"stormwood_pickup_pocket_204", "stormwood_pickup_pocket_205",
		"stormwood_pickup_pocket_208", "stormwood_pickup_pocket_209",
		"stormwood_pickup_pocket_210",
	])


func test_stable_placement_flags_are_realm_qualified() -> void:
	var spec: Dictionary = RUNTIME.ordinary_specs()[0]
	var flag := CACHE.flag_id(str(spec["item_id"]), str(spec["id"]), RUNTIME.REALM_ID)
	assert_eq(flag, "cache:stormwood:%s" % str(spec["id"]))
	assert_ne(flag, CACHE.flag_id(str(spec["item_id"]), str(spec["id"]), "cloudreach"))


func test_every_mountable_item_resolves_to_installed_pickup_art() -> void:
	var definitions := RUNTIME.item_definitions()
	for spec: Dictionary in RUNTIME.ordinary_specs():
		var presentation := RUNTIME.presentation_for(str(spec["item_id"]), definitions[str(spec["item_id"])])
		var model := str(presentation.get("model", ""))
		assert_true(not model.is_empty() and ResourceLoader.exists(model),
			"%s must not fall back to ItemCachePickup's warning box" % str(spec["id"]))

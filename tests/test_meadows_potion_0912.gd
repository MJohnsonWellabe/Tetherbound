extends "res://tests/test_case.gd"

## OWNER_PLAYTEST_2026-09-12: Small Potions felt too weak. Keep the owner-facing
## value explicit, meaningful, and below the Ironwood-tier Ridge Tonic.

const ITEMS_PATH := "res://data/items/items.json"


func test_small_potion_restores_fifty_hp_and_keeps_the_tier_ladder() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ITEMS_PATH))
	assert_true(parsed is Dictionary, "items.json must parse")
	if not parsed is Dictionary:
		return
	var items: Dictionary = (parsed as Dictionary).get("items", {})
	var small: Dictionary = items.get("potion_small", {})
	var ridge: Dictionary = items.get("potion_large", {})
	assert_eq(int(small.get("heal", 0)), 50,
		"the 09/12 Meadows tuning must make one small potion materially useful")
	assert_true(int(ridge.get("heal", 0)) > int(small.get("heal", 0)),
		"the late-game Ridge Tonic must remain the stronger healing tier")

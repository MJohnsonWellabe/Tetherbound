extends "res://tests/test_case.gd"

const REGISTRATION := preload("res://scripts/world/f32_catalogue_registration.gd")

func test_production_overlay_preserves_canonical_economy_and_item_metadata() -> void:
	var canonical: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/items.json")).items
	var merged := REGISTRATION.apply_items(canonical)
	for id: String in ["rootiron_ingot", "tidesteel_ingot", "skyglass_ingot", "stormglass_plate", "tide_pearl", "seed_ground", "seed_water", "seed_air", "seed_electric", "seed_fire", "seed_dark", "seed_ice", "seed_psychic"]:
		var expected: Dictionary = canonical[id].duplicate(true)
		expected.stack = int(expected.stack)
		assert_eq(merged[id], expected, id)
	assert_eq(merged.tide_pearl.stack, 30)
	assert_eq(merged.hide_helm.name, "Padded Helm")

func test_compatible_duplicate_metadata_merges_but_real_conflicts_refuse() -> void:
	var existing := {"name": "Canonical", "stack": 30, "description": "Keep this"}
	var frozen := existing.duplicate(true)
	assert_eq(REGISTRATION.compatible_item(existing, {"name": "Canonical", "stack": 30.0, "icon": "installed"}),
		{"name": "Canonical", "stack": 30, "description": "Keep this", "icon": "installed"})
	assert_true(REGISTRATION.compatible_item(existing, {"stack": 50}).is_empty())
	assert_true(REGISTRATION.compatible_item(existing, {"name": "Replacement"}).is_empty())
	assert_eq(existing, frozen)

extends "res://tests/test_case.gd"

## Stormwood's offline terrain baker contract. These checks stay pure so they
## can run quickly without instantiating Terrain3D or touching shipped output.

const BAKER := preload("res://scripts/world/build_stormwood_terrain.gd")
const ALIGNMENT := preload("res://scripts/world/terrain_region_alignment.gd")

const BOUNDS := {"min_x": -2560.0, "max_x": 2048.0, "min_z": 0.0, "max_z": 6144.0}


func test_stormwood_bounds_form_9_by_12_grid() -> void:
	assert_eq(ALIGNMENT.check_alignment(BOUNDS, 256, 2.0), "")
	assert_eq(ALIGNMENT.region_counts(BOUNDS, 256, 2.0), Vector2i(9, 12))
	assert_eq(ALIGNMENT.region_locations(BOUNDS, 256, 2.0).size(), 108)


func test_config_validation_accepts_authored_contract() -> void:
	var file := FileAccess.open("res://data/config/terrain_stormwood.json", FileAccess.READ)
	assert_true(file != null)
	var config: Variant = JSON.parse_string(file.get_as_text())
	assert_true(config is Dictionary)
	assert_eq(BAKER.validate_config(config), "")


func test_explicit_regions_are_parsed_as_terrain_locations() -> void:
	var locations := BAKER.parse_regions(["--regions=-5:0,-4:11"], BOUNDS)
	assert_eq(locations, [Vector2i(-5, 0), Vector2i(-4, 11)])


func test_full_set_requires_exact_membership_and_no_duplicates() -> void:
	var all := ALIGNMENT.region_locations(BOUNDS, 256, 2.0)
	assert_true(BAKER.is_full_region_set(all, BOUNDS))
	var duplicate := all.duplicate()
	duplicate[duplicate.size() - 1] = duplicate[0]
	assert_false(BAKER.is_full_region_set(duplicate, BOUNDS))
	var wrong := all.duplicate()
	wrong[0] = Vector2i(99, 99)
	assert_false(BAKER.is_full_region_set(wrong, BOUNDS))


func test_dependency_fingerprint_is_order_independent_and_source_sensitive() -> void:
	var first := {"a": "one\r\ntwo", "b": "three"}
	var reordered := {"b": "three", "a": "one\ntwo"}
	assert_eq(BAKER.dependency_fingerprint(first), BAKER.dependency_fingerprint(reordered))
	assert_ne(BAKER.dependency_fingerprint(first), BAKER.dependency_fingerprint({"a": "changed", "b": "three"}))
	assert_ne(BAKER.canonical_hash("same", "a"), BAKER.canonical_hash("same", "b"))

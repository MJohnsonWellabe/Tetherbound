extends "res://tests/test_case.gd"

const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const WATER_WORLD := preload("res://scripts/world/water_world.gd")


func test_water_profile_uses_its_own_surface_ids_and_sea_gate() -> void:
	var profile: Variant = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/config/water_ground_cover.json"))
	assert_true(profile is Dictionary)
	var field := GRASS_FIELD.new()
	field.configure_profile(profile, ["grass", "shore", "rock"],
			PackedVector3Array([Vector3(10.0, 20.0, 8.0)]))
	var receipt := field.profile_receipt()
	assert_eq(receipt.forbidden_mask, 6,
			"Water cover must reject shore (bit 1) and rock (bit 2), while allowing grass (bit 0)")
	assert_true(float(receipt.min_ground_height) > 0.0,
			"Water cover must stay above the sea-level terrain surface")
	assert_eq(receipt.authored_clearance_count, 1)
	field.free()


func test_profiles_own_independent_copies() -> void:
	var source := {"enabled": false, "forbidden_ground": ["rock"],
			"field_radius": 40.0, "snap": 1.25}
	var first := GRASS_FIELD.new()
	var second := GRASS_FIELD.new()
	first.configure_profile(source, ["grass", "shore", "rock"])
	second.configure_profile(source, ["grass", "shore", "rock"])
	source.forbidden_ground.append("shore")
	assert_eq(first.profile_receipt().forbidden_mask, 4)
	assert_eq(second.profile_receipt().forbidden_mask, 4)
	assert_almost_eq(GRASS_FIELD.profile_lattice_cell(source), 1.25, 0.001,
			"A realm profile's lattice must not fall back to the shared static config")
	first.free()
	second.free()


func test_water_profile_clearances_match_small_service_footprints() -> void:
	var world := WATER_WORLD.new()
	world.config = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/config/water_world.json"))
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/config/water_ground_cover.json"))
	var clearances: PackedVector3Array = world._ground_cover_clearances(profile)
	assert_true(clearances.size() >= int(world.config.get("anchors", []).size()) + 8,
			"Water cover must clear every arrival plus the eight authored camps")
	assert_true(clearances.has(Vector3(7.0, 142.0, 5.0)),
			"First Shore camp needs a cover-free service footprint")
	assert_true(clearances.has(Vector3(0.0, 162.0, 3.5)),
			"First Shore arrival must use the ground-cover footprint, not the 12m tree radius")
	world.free()

extends "res://tests/test_case.gd"

## tb/vis-water-sky group 2: Cloudreach dry/lush turf patches ship off, and the
## field the tuft thinning reads is smooth, bounded and has both patch kinds.

const MATERIALS := preload("res://scripts/world/cloudreach_environment_materials.gd")


func test_ships_off() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_ground_cluster.json"))
	assert_false(bool(parsed.get("enabled", true)))
	assert_true(MATERIALS.ground_cluster().is_empty(), "off: no turf or tuft change")


func test_field_is_bounded_and_has_dry_and_lush_ground() -> void:
	var dry := 0
	var lush := 0
	for i in 400:
		var x := float(i % 20) * 37.0 - 300.0
		var z := float(i / 20) * 41.0 + 200.0
		var f: float = MATERIALS.turf_patch_field(x, z, 0.035)
		assert_true(absf(f) <= 1.0001)
		if f > 0.45:
			dry += 1
		elif f < -0.45:
			lush += 1
		var near: float = MATERIALS.turf_patch_field(x + 0.5, z, 0.035)
		assert_true(absf(near - f) < 0.1, "smooth at half a metre")
	assert_true(dry > 20 and lush > 20, "both patch kinds appear (dry %d, lush %d)" % [dry, lush])

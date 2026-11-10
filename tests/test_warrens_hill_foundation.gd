extends "res://tests/test_case.gd"

## F38#30 / F38#24 (LANE-NEWAPPROACH, judged on GPU 10 Nov): a grass foundation
## with collision closes the ground under the Burrow Warrens chamber shells,
## which hung in open air where the meadow falls below the cave floor.

func _foundation() -> Dictionary:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/burrow_warrens.json"))
	return cfg.bank.hill_shell.get("foundation", {})

func test_foundation_ships_on_with_collision_and_gain_recorded() -> void:
	var f := _foundation()
	assert_true(bool(f.get("enabled", false)), "foundation ships ON after the GPU judge")
	assert_true(bool(f.get("collision", false)), "the ground under the shells is solid")
	assert_true(str(f.get("_why_on", "")).contains("+0.57"), "the judged gain is recorded")

func test_builder_is_wired_and_named() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")
	assert_true(src.contains("_build_hill_foundation()"), "the build calls the foundation")
	assert_true(src.contains("\"HillFoundation\""), "the foundation node is named")

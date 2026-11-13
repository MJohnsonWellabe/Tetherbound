extends "res://tests/test_case.gd"

## F40#17 `perch_rim_cluster_1112.rim_glow_1113` (LANE-LAND-CS): OFF until judged.
## On, only the three High Perches rim placements get a smaller pickup glow.

const PRESENTATION := preload("res://scripts/world/mushroom_pickup_presentation.gd")
const VARIANTS := "res://data/config/mushroom_pickup_variants.json"
const RIM := "cr_recovery_high_roost_flight_speed_01"


func test_ships_off_and_off_keeps_full_glow() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VARIANTS))
	assert_false(bool(cfg.perch_rim_cluster_1112.rim_glow_1113.get("enabled", true)), "rim_glow_1113 ships OFF until judged")
	assert_eq(PRESENTATION.glow_scale(RIM), 1.0, "OFF: the rim pickup keeps the full glow")
	assert_eq(PRESENTATION.glow_scale(""), 1.0, "no placement: full glow")
	assert_eq(PRESENTATION.glow_scale("cr_candy_broken_route_good_07"), 1.0, "another pickup: full glow")


func test_scale_is_clamped_and_still_glows() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VARIANTS))
	var scale := float(cfg.perch_rim_cluster_1112.rim_glow_1113.get("scale", 1.0))
	assert_true(scale >= 0.2 and scale < 1.0, "a smaller glow that is never removed (owner OP-0830-3)")
	assert_eq((cfg.perch_rim_cluster_1112.only_placements as Array).size(), 3, "three rim placements only")

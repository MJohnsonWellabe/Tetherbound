extends "res://tests/test_case.gd"

## F40#17 `perch_rim_cluster_1112.rim_glow_1113` (LANE-LAND-CS): ships ON (GPU High,
## 14 Nov 2026, G-land-cs-rimglow: F40#17 6.03 -> 6.61, 3/3). Only the three High
## Perches rim placements get a smaller pickup glow; every other pickup is unchanged.

const PRESENTATION := preload("res://scripts/world/mushroom_pickup_presentation.gd")
const VARIANTS := "res://data/config/mushroom_pickup_variants.json"
const RIM := "cr_recovery_high_roost_flight_speed_01"


func test_ships_on_with_its_verdict() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VARIANTS))
	var glow: Dictionary = cfg.perch_rim_cluster_1112.rim_glow_1113
	assert_true(bool(glow.get("enabled", false)), "rim_glow_1113 ships ON")
	assert_true(str(glow.get("_why_on", "")).contains("G-land-cs-rimglow.md"), "ON cites its GPU verdict")
	assert_true(str(glow.get("_why_on", "")).contains("6.03 -> 6.61"), "and its judged score")
	assert_eq(PRESENTATION.glow_scale(RIM), float(glow.scale), "ON: the rim pickup takes the smaller glow")
	assert_eq(PRESENTATION.glow_scale(""), 1.0, "no placement: full glow")
	assert_eq(PRESENTATION.glow_scale("cr_candy_broken_route_good_07"), 1.0, "another pickup: full glow")


func test_scale_is_clamped_and_still_glows() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VARIANTS))
	var scale := float(cfg.perch_rim_cluster_1112.rim_glow_1113.get("scale", 1.0))
	assert_true(scale >= 0.2 and scale < 1.0, "a smaller glow that is never removed (owner OP-0830-3)")
	assert_eq((cfg.perch_rim_cluster_1112.only_placements as Array).size(), 3, "three rim placements only")

extends "res://tests/test_case.gd"

## BEINGS-WMONITOR-GROUND landed (F36#92, 13 Nov 2026): the water mangrove
## monitor's faint lets its limbs sink half its standing height, so the trunk
## reaches the floor mid-faint. GPU High 6.68 -> 7.03, 3/3
## (G-beings-wmonitor-ground.md).

const SETTLE := preload("res://scripts/creatures/creature_pose_settle.gd")
const CONFIG := "res://data/config/creature_pose_settle.json"


func _row() -> Dictionary:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return ((cfg.get("faint", {}) as Dictionary).get("per_species", {}) as Dictionary).get("water_mangrove_monitor", {})


func test_the_shipped_limb_sink_is_pinned_with_its_verdict() -> void:
	var crumple: Dictionary = _row().get("crumple", {})
	assert_eq(float(crumple.get("limb_sink_frac", 0.0)), 0.5, "limbs may sink half the standing height")
	var why := str(crumple.get("_why_limb_sink", ""))
	assert_true(why.contains("G-beings-wmonitor-ground") and why.contains("6.68") and why.contains("7.03"),
		"the value cites its verdict and both scores")
	assert_eq(float(crumple.get("min_top_frac", 0.0)), 0.5, "the end pose still keeps half its height above the floor")


func test_the_species_bake_reads_the_shipped_value_and_the_land_form_does_not() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var water := SETTLE._for_species(cfg, "water_mangrove_monitor")
	var land := SETTLE._for_species(cfg, "mangrove_monitor")
	assert_eq(float(((water.get("faint", {}) as Dictionary).get("crumple", {}) as Dictionary).get("limb_sink_frac", 0.0)), 0.5,
		"the water form's bake uses 0.5")
	assert_eq(float(((land.get("faint", {}) as Dictionary).get("crumple", {}) as Dictionary).get("limb_sink_frac", 0.0)), 0.6,
		"the land form keeps the roster value")

extends "res://tests/test_case.gd"

## Correctness (LANE-LAND-MT, 13 Nov): current-lane drift floaters travelled a
## straight line at sea level and hovered over wet sand where a lane crossed a
## beach (the Venn fight's floating driftwood log, GPU G-venn-floating-log).
## A floater now shows only over water at least min_depth deep.

const MARKERS := preload("res://scripts/world/water_current_drift_markers.gd")
const HEIGHTFIELD := preload("res://scripts/world/water_heightfield.gd")


func test_floaters_hide_over_sand_and_show_over_deep_water() -> void:
	var field: RefCounted = HEIGHTFIELD.shared()
	var dry := Vector2(366.0, 3794.0)    # the Venn landing shelf, ground about 2.8 m
	var deep := Vector2(557.0, 3501.0)   # open water south of Veilfall, ground about -32 m
	assert_true(float(field.call("height_at", dry.x, dry.y)) > 0.5, "the shelf point is dry land")
	assert_true(float(field.call("height_at", deep.x, deep.y)) < -5.0, "the sea point is deep water")
	assert_false(MARKERS.afloat(field, dry, 0.05, 0.4), "a floater over the shelf is hidden")
	assert_true(MARKERS.afloat(field, deep, 0.05, 0.4), "a floater over deep water shows")


func test_no_heightfield_keeps_every_floater() -> void:
	assert_true(MARKERS.afloat(null, Vector2.ZERO, 0.05, 0.4), "without a heightfield nothing is hidden")


func test_min_depth_is_configurable() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	var drift: Dictionary = (((parsed as Dictionary).get("current_flow", {}) as Dictionary).get("drift_markers", {}))
	assert_true(float(drift.get("min_depth_m", 0.4)) > 0.0, "a positive draft is configured or defaulted")

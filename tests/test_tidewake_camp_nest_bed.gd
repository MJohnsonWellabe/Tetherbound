extends "res://tests/test_case.gd"

## F39#12 (VIS-TIDEWAKE qj/n12, 7 Nov 2026): the raised woven nest bed ships ON
## for the Tidewake camp creature bed, with its judged score recorded.

const CAMP := preload("res://scripts/world/meshy_camp_props.gd")


func test_nest_bed_ships_with_its_score() -> void:
	var bed: Dictionary = CAMP.settings().get("bed", {})
	assert_true(bool(bed.get("enabled", false)), "the Meshy camp bed layer is on")
	var nest: Dictionary = bed.get("nest_candidate", {})
	assert_true(bool(nest.get("enabled", false)), "the judged nest bed is in play")
	assert_true(ResourceLoader.exists(str(nest.get("model", ""))), "the nest model exists")
	assert_true(str(nest.get("_why_on", "")).contains("5.98"), "the nest's mapped score is recorded")


func test_blender_workbench_stays_off() -> void:
	# qj/w13 lost (6.41 -> 5.14): the Meshy bench already in play stays.
	var bench: Dictionary = CAMP.settings().get("workbench", {})
	assert_false(bool((bench.get("vl_candidate", {}) as Dictionary).get("enabled", false)))

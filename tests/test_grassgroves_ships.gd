extends "res://tests/test_case.gd"

## LANE-LAND-MT GRASSGROVES (GPU judged ship, G-land-mt-grassgroves-r2,
## 13 Nov 2026): Tidewake dune grass in denser clumps with wider bare gaps.
## The look profile's dune_grass_candidate is applied last to the grass field
## (water_world.gd _stand_up_ground_cover), so the values live there.

const LOOK := "res://data/config/tidewake_look.json"


func test_grass_groves_ship_in_the_last_applied_section() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOOK))
	var grass: Dictionary = (parsed as Dictionary).get("dune_grass_candidate", {})
	assert_eq(float(grass.get("density_gain", 0.0)), 1.2, "the judged density ships")
	assert_eq(float(grass.get("clump_patch_start", 0.0)), 0.56, "the judged clump threshold ships")
	assert_eq(float(grass.get("dune_gap_start", 0.0)), 0.42, "the judged bare gaps ship")
	assert_true(str(grass.get("_why_grassgroves", "")).contains("+0.16"), "the verdict is cited")
	assert_false(((parsed as Dictionary).get("sections_off", []) as Array).has("dune_grass_candidate"),
		"the section is live, not in sections_off")
	var source := FileAccess.get_file_as_string("res://scripts/world/water_world.gd")
	assert_true(source.contains("\"dune_grass_candidate\""), "the grass field still reads this section")

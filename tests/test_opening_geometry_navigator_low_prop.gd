extends "res://tests/test_case.gd"

## F02#3/F17#4: the earned walk stepped onto the village_twins_yard woodpile
## log (top ~0.3 m above the road) and left the floor stepping off it. Contacts
## rising past a floor-cone capsule contact but within a step are steered round.
const NAV := preload("res://tests/helpers/opening_geometry_navigator.gd")


func test_a_woodpile_log_is_a_low_prop_climb() -> void:
	assert_true(NAV.is_low_prop_climb(0.30, 0.35), "a 0.3 m log top is climbed, not walked on")
	assert_true(NAV.is_low_prop_climb(0.35, 0.35), "a full step is still a climb")
	assert_true(NAV.is_low_prop_climb(0.3500004, 0.35), "the STEP_HEIGHT-tall woodpile box edge is not lost to float error")


func test_floor_contacts_and_walls_are_not_low_prop_climbs() -> void:
	assert_false(NAV.is_low_prop_climb(0.0, 0.35), "level floor")
	assert_false(NAV.is_low_prop_climb(0.117, 0.35), "a 45-degree floor-cone capsule contact")
	assert_false(NAV.is_low_prop_climb(0.30, 0.0), "no configured step")
	assert_false(NAV.is_low_prop_climb(NAN, 0.35))

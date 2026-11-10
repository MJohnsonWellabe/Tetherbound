extends "res://tests/test_case.gd"

## Capture stand fix (LANE-MESHY): `heading_overrides` in capture_stands.json
## turns Officer Nysa's post stand to the open route side, so the production
## camera arm no longer backs into the Deepwood rod station behind her.

const INVENTORY := preload("res://tools/phase2_capture_world_inventory.gd")
const STANDS := "res://data/config/capture_stands.json"
const NYSA := "stormwood__inventory__trainer__officer_nysa_deepwood_rod"


func test_nysa_stand_views_from_the_route_side() -> void:
	var heading: Variant = INVENTORY.stand_heading_override(STANDS, NYSA)
	assert_true(heading != null, "Nysa has a reviewed heading override")
	assert_almost_eq(float(heading), 0.0, 0.001, "viewed from the south, the station behind her")
	# forward (sin h, cos h); the stand sits at target - forward * offset.
	var forward := Vector2(sin(deg_to_rad(float(heading))), cos(deg_to_rad(float(heading))))
	var post := Vector2(-890.0, 4482.0)
	var station := Vector2(-890.0, 4490.0)
	var stand := post - forward * 2.0
	var camera := stand - forward * 5.2
	assert_true(camera.distance_to(station) > post.distance_to(station) + 5.0,
		"the camera arm points away from the rod station")


func test_other_frames_keep_their_generated_heading() -> void:
	assert_true(INVENTORY.stand_heading_override(STANDS, "stormwood__inventory__trainer__rodfolk_guard_bram") == null)
	assert_true(INVENTORY.stand_heading_override("res://does/not/exist.json", NYSA) == null)

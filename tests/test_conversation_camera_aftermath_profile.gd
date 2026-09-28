extends "res://tests/test_case.gd"

## F04#3: a trainer's victory lines use camera.json conversation.profiles.aftermath,
## a wider, higher shot than the villager push-in; unknown names fall back.

const CAM := preload("res://scripts/player/conversation_camera.gd")


func test_aftermath_frames_wider_than_the_villager_push_in() -> void:
	var base := CAM.config()
	var aftermath := CAM.profile_config("aftermath")
	assert_true(float(aftermath["distance"]) > float(base["distance"]), "aftermath stands further back")
	assert_true(float(aftermath["fov"]) > float(base["fov"]), "aftermath is wider")
	assert_true(float((aftermath["fallback"] as Dictionary)["distance"]) \
		> float((base["fallback"] as Dictionary)["distance"]), "its cramped fallback is wider too")
	assert_eq((aftermath["fallback"] as Dictionary).get("swing_search_deg"),
		(base["fallback"] as Dictionary).get("swing_search_deg"), "fallback keys it does not name are kept")
	assert_eq(float(aftermath["blend_time"]), float(base["blend_time"]), "unnamed keys are kept")


func test_unknown_and_empty_profiles_are_the_ordinary_shot() -> void:
	assert_eq(CAM.profile_config(""), CAM.config())
	assert_eq(CAM.profile_config("no_such_profile"), CAM.config())

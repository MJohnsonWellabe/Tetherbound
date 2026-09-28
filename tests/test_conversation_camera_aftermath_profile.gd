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


## F04#6 (judge r4 7121d40c): a captain beaten ten metres off stayed small
## behind a signpost through her victory lines. The aftermath shot keeps its
## lens within max_speaker_distance_m of the speaker however far the player is.
func test_aftermath_lens_stays_near_a_far_speaker() -> void:
	var aftermath := CAM.profile_config("aftermath")
	var cap := float(aftermath["max_speaker_distance_m"])
	var trainer := Vector3(0.0, 1.4, 0.0)
	for far: float in [3.0, 10.0, 18.0]:
		var speaker := Vector3(0.0, 1.5, -far)
		var shot := CAM.solve(trainer, speaker, Vector3.FORWARD, aftermath)
		var lens: Vector3 = shot["pivot"] + shot["dir"] * float(shot["distance"])
		assert_true(lens.distance_to(speaker) <= cap + 0.01,
			"the lens is %.2f m from a speaker %.0f m off (cap %.1f)" % [lens.distance_to(speaker), far, cap])
	var plain := CAM.solve(trainer, Vector3(0.0, 1.5, -18.0), Vector3.FORWARD, CAM.config())
	var plain_lens: Vector3 = plain["pivot"] + plain["dir"] * float(plain["distance"])
	assert_true(plain_lens.distance_to(Vector3(0.0, 1.5, -18.0)) > cap,
		"the villager push-in, which names no cap, is unchanged")

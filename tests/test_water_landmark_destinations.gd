extends "res://tests/test_case.gd"

## close-1024 s3/s4: the destination re-seats replace lm2's pieces by
## landmark_id, a later layer (s4) beats an earlier one (s3), and id-less
## dressing props are all kept.
const LANDMARKS := preload("res://scripts/world/water_landmark_models.gd")


func test_later_layers_replace_by_landmark_id_and_keep_dressing() -> void:
	var look := {
		"destination_landmarks_candidate": [{"landmark_id": "pumps", "v": "lm2"}, {"landmark_id": "jetty", "v": "lm2"}],
		"destination_landmarks_s3_candidate": [{"landmark_id": "pumps", "v": "s3"}, {"landmark_id": "boat", "v": "s3"}],
		"destination_landmarks_s4_candidate": [{"landmark_id": "pumps", "v": "s4"}, {"id": "hut", "v": "s4"}, {"id": "rack", "v": "s4"}],
	}
	var picked: Array = LANDMARKS._destinations(look)
	var by_key := {}
	for spec: Dictionary in picked:
		by_key[str(spec.get("landmark_id", spec.get("id", "")))] = spec.v
	assert_eq(picked.size(), 5, "jetty, pumps, boat and both dressing props, no duplicates")
	assert_eq(by_key.pumps, "s4", "the latest layer wins")
	assert_eq(by_key.jetty, "lm2", "an untouched lm2 piece stays")
	assert_eq(by_key.boat, "s3")
	assert_true(by_key.has("hut") and by_key.has("rack"), "id-less dressing props are all kept")


func test_without_layers_lm2_is_unchanged() -> void:
	var base := [{"landmark_id": "pumps"}]
	assert_eq(LANDMARKS._destinations({"destination_landmarks_candidate": base}), base)

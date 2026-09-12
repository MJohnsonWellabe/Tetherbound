extends "res://tests/test_case.gd"

## The post-Warden reconnection remains visible from the Meadows seam, but it
## is atmospheric background rather than a giant Cloudreach-sized wall.

const CONFIG_PATH := "res://data/config/rift_collapse.json"


func _far_country() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	assert_true(parsed is Dictionary, "rift collapse config parses")
	return (parsed as Dictionary).get("far_country", {}) as Dictionary \
		if parsed is Dictionary else {}


func test_far_country_is_a_distant_low_contrast_reconnection_view() -> void:
	var far := _far_country()
	var ridges := far.get("ridges", []) as Array
	assert_eq(ridges.size(), 4, "the reconnection silhouette remains a layered view")
	for raw: Variant in ridges:
		var ridge := raw as Dictionary
		assert_true(float(ridge.get("distance", 0.0)) >= 600.0,
			"the far country must not loom at near-landmark distance")
		assert_true(float(ridge.get("distance", 0.0)) <= 850.0,
			"the reconnection view remains inside the authored full-opacity horizon band")
		assert_true(float(ridge.get("alpha", 1.0)) <= 0.5,
			"the distant silhouette keeps atmospheric contrast")
	var glow := far.get("glow", {}) as Dictionary
	assert_true(float(glow.get("distance", 0.0)) >= 600.0,
		"the horizon glow belongs with the distant ridge tier")
	assert_true(float(glow.get("alpha", 1.0)) <= 0.1,
		"the reconnection glow cannot become a giant luminous card")


func test_far_country_remains_presentation_only() -> void:
	var far := _far_country()
	for key: Variant in far.keys():
		assert_true(str(key) in ["_comment", "ridges", "glow", "_comment_glow"],
			"far-country backdrop gained non-presentation key %s" % str(key))
	for raw: Variant in (far.get("ridges", []) as Array):
		var ridge := raw as Dictionary
		for key: Variant in ridge.keys():
			assert_true(str(key) in ["distance", "yaw_deg", "width", "height", "base", "colour", "alpha"],
				"far-country ridge gained gameplay key %s" % str(key))

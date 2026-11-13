extends "res://tests/test_case.gd"

## F40#15 candidate: darker Cloudreach bark tints, OFF until a GPU verdict.


func test_bark_tone_candidate_is_off_with_three_colours() -> void:
	var cfg: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var tone: Dictionary = cfg.get("tree_bark_tone_1112", {})
	assert_false(bool(tone.get("enabled", true)))
	var colours: Array = tone.get("colours", [])
	assert_eq(colours.size(), 3)
	for raw: Variant in colours:
		var colour := Color(str(raw))
		# Cool and dark: never a red or oxblood tint.
		assert_true(colour.b >= colour.r)
		assert_true(colour.v < 0.6)

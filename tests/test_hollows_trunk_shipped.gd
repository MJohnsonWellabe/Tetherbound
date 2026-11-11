extends "res://tests/test_case.gd"

## F41#3 / F41#22 (giant trees in the fight-only sight fade) and the Hall
## timber red-rule retint ship ON after the GPU judge (11 Nov).

func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func test_giant_trees_fight_fade_ships_on_with_gain_recorded() -> void:
	var cfg: Dictionary = _json("res://data/config/foliage_camera_visibility.json").line_of_sight_fade.giant_trees_1110
	assert_true(bool(cfg.get("enabled", false)), "giant trees join the fight fade")
	assert_true(str(cfg.get("_why_on", "")).contains("+1.09"), "the judged gain is recorded")

func test_hall_timber_retint_ships_on_with_gain_recorded() -> void:
	var cfg: Dictionary = _json("res://data/config/crossing_hall.json").hall_waymark.materials.timber_1110
	assert_true(bool(cfg.get("enabled", false)), "the nave post leaves the red family")
	assert_true(str(cfg.get("_why_on", "")).contains("brown wood"), "the judged read is recorded")

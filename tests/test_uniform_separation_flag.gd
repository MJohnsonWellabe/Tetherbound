extends "res://tests/test_case.gd"

## F41#18 candidate `uniform_separation_1113`: OFF until a GPU verdict.

const PRESENTATION := preload("res://scripts/world/stormwood_character_presentation.gd")
const CONFIG := "res://data/config/stormwood_character_presentation.json"


func test_candidate_is_off_and_live_uniforms_are_unchanged() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var block: Dictionary = cfg.get("uniform_separation_1113", {})
	assert_false(bool(block.get("enabled", true)))
	assert_eq(float(block.get("emission_floor", 1.0)), 0.0)
	var live: Dictionary = PRESENTATION.decorate({"config_key": "grunt"}, "dace", "lieutenant")
	assert_eq(float(live.get("emission_floor", -1.0)), float((cfg.uniform as Dictionary).emission_floor))
	for item: Dictionary in live.get("accessories", []):
		assert_false(str(item.get("name", "")).begins_with("rank_"), "no rank marks while OFF")


func test_rank_marks_scale_with_the_candidate() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	(cfg.uniform_separation_1113 as Dictionary)["enabled"] = true
	var identity: Dictionary = (cfg.identities as Dictionary).get("dace", {})
	var marks: Array = PRESENTATION.rank_marks(cfg, identity, "lieutenant")
	assert_eq(marks.size(), 3)
	var knot: Dictionary = marks[0]
	var authored := 0.14 * 1.15
	assert_true(float(knot.size) < authored, "marks are scaled down")
	assert_eq(str(knot.color), str(identity.get("rim_color", "")))

extends "res://tests/test_case.gd"

## LANE-NEWAPPROACH: hud.json result_focus ships ON (judged 10 Nov, F41#16
## +2.10); the listed tiers yield while a fight result (loss card, catch card,
## beaten line) is up.

const HUD := preload("res://scripts/ui/playground_hud.gd")
const POLICY := preload("res://scripts/ui/hud_presentation_policy.gd")


func test_result_focus_ships_on_with_a_hide_list() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	assert_true(bool(parsed.result_focus.enabled), "result_focus ships ON after its judged gain")
	assert_true(str(parsed.result_focus.get("_why_on", "")).contains("+2.10"), "the judged gain is recorded")
	assert_true((parsed.result_focus.hide as Array).has("hotbar"), "the quickbar is in the hide list")


func test_result_focus_hides_the_exploration_tiers() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	var mode := POLICY.resolve("exploration", false, false, false)
	var focused := HUD.victory_focus_mode(mode, parsed.result_focus)
	for key: String in ["hotbar", "exploration", "party", "prompt", "task", "minimap"]:
		assert_true(bool(mode[key]), "%s is shown in plain exploration" % key)
		assert_false(bool(focused[key]), "%s yields to the fight result" % key)
	assert_true(bool(focused.human_vitals), "the trainer's own vitals stay")

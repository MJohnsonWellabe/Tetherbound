extends "res://tests/test_case.gd"

## VIS-CLOUDREACH lane (4 Nov 2026): judged CPU gains that ship ON. Each flag
## records its score in `_why_on`; this test keeps both ON and the score on
## record (ralph/reports/LANES/VIS-CLOUDREACH/r3b/VERDICT.md).

const PHYSICAL := "res://data/config/cloudreach_physical_runtime.json"
const VISUAL := "res://data/config/cloudreach_visual.json"


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func test_mounted_drop_scramble_is_on_with_its_score() -> void:
	var spec: Dictionary = _read(PHYSICAL).get("mounted_drop_no_air_drive", {})
	assert_true(spec.get("enabled") == true, "P2-105 mounted_drop_no_air_drive ships ON")
	assert_true(str(spec.get("_why_on", "")).contains("4.82 -> 5.91"), "P2-105 CPU score recorded")
	assert_true(float(spec.get("scramble_after_s", 0.0)) > 0.0, "the scramble-back part is active")
	assert_true(float(spec.get("airborne_s", 0.0)) > 0.0, "a hop under airborne_s keeps control")


func test_island_low_mist_is_on_with_its_score() -> void:
	var roots: Dictionary = _read(VISUAL).get("island_roots", {})
	var low: Dictionary = roots.get("low_mist", {})
	assert_true(low.get("enabled") == true, "P2-106 island_roots.low_mist ships ON")
	assert_true(str(low.get("_why_on", "")).contains("4.97 -> 6.03"), "P2-106 CPU score recorded")
	assert_true(float(low.get("mist_below_m", 0.0)) > float(roots.get("mist_below_m", 0.0)),
		"the collar sits lower than the base config")


func test_catch_card_is_on_with_its_score() -> void:
	var card: Dictionary = _read("res://data/config/hud.json").get("catch_card", {})
	assert_true(card.get("enabled") == true, "P2-118 hud.json catch_card ships ON")
	assert_true(str(card.get("_why_on_cloudreach", "")).contains("3.77 -> 4.61"), "P2-118 CPU score recorded")


func test_full_team_line_is_on_with_its_score() -> void:
	var line: Dictionary = (_read("res://data/config/hud.json").get("catch_card", {}) as Dictionary).get("full_team_line", {})
	assert_true(line.get("enabled") == true, "P2-118 catch_card.full_team_line ships ON")
	assert_true(str(line.get("_why_on", "")).contains("3.57 -> 4.98"), "P2-118 full-team line CPU score recorded")
	assert_false(str(line.get("text", "")).is_empty(), "the line has text")


func test_landing_tree_clear_is_on_with_its_score() -> void:
	var spec: Dictionary = _read(VISUAL).get("landing_tree_clear", {})
	assert_true(spec.get("enabled") == true, "P2-105 landing_tree_clear ships ON")
	assert_true(str(spec.get("_why_on", "")).contains("3.68 -> 5.28"), "P2-105 tree-clear CPU score recorded")
	assert_true((spec.get("names", []) as Array).has("LandingTree171"), "the road-side canopy tree is the one cleared")


func test_early_scramble_is_on_with_its_score() -> void:
	var spec: Dictionary = _read(PHYSICAL).get("mounted_drop_no_air_drive", {})
	assert_true(is_equal_approx(float(spec.get("scramble_after_s", 0.0)), 0.3), "P2-105 scramble_after_s ships at 0.3")
	assert_true(str(spec.get("_scramble_after_s_why_on", "")).contains("4.38 -> 6.10"), "P2-105 early-scramble CPU score recorded")


func test_thinner_island_mist_is_on_with_its_score() -> void:
	var roots: Dictionary = _read(VISUAL).get("island_roots", {})
	assert_true(is_equal_approx(float(roots.get("mist_core_alpha", 0.0)), 0.45), "P2-106 island mist core ships at 0.45")
	assert_true(is_equal_approx(float((roots.get("low_mist", {}) as Dictionary).get("mist_below_m", 0.0)), 260.0), "P2-106 low mist collar ships 260 m below")
	assert_true(str(roots.get("_mist_thin_why_on", "")).contains("6.00 -> 6.43"), "P2-106 mist-thin CPU score recorded")


func test_catch_card_portrait_is_on_with_its_score() -> void:
	var portrait: Dictionary = (_read("res://data/config/hud.json").get("catch_card", {}) as Dictionary).get("portrait", {})
	assert_true(portrait.get("enabled") == true, "P2-118 catch_card.portrait ships ON")
	assert_true(str(portrait.get("_why_on", "")).contains("5.91 -> 6.19"), "P2-118 portrait CPU score recorded")
	assert_true(float(portrait.get("px", 0.0)) > 0.0, "the portrait has a size")


func test_catch_card_party_row_is_on_with_its_score() -> void:
	var line: Dictionary = (_read("res://data/config/hud.json").get("catch_card", {}) as Dictionary).get("full_team_line", {})
	var row: Dictionary = line.get("party_row", {})
	assert_true(row.get("enabled") == true, "P2-118 full_team_line.party_row ships ON")
	assert_true(str(row.get("_why_on", "")).contains("5.58 -> 6.85"), "P2-118 party-row CPU score recorded")


func test_catch_card_party_names_are_on_with_their_score() -> void:
	var row: Dictionary = ((_read("res://data/config/hud.json").get("catch_card", {}) as Dictionary).get("full_team_line", {}) as Dictionary).get("party_row", {})
	assert_true(int(row.get("name_px", 0)) > 0, "P2-118 party row names ship ON")
	assert_true(float(row.get("px", 0.0)) >= 96.0, "P2-118 party row portraits ship at 96 px")
	assert_true(str(row.get("_names_why_on", "")).contains("5.58 -> 6.18"), "P2-118 party-names CPU score recorded")


func test_wider_catch_card_is_on_with_its_score() -> void:
	var card: Dictionary = _read("res://data/config/hud.json").get("catch_card", {})
	assert_true(float(card.get("card_half_width", 0.0)) >= 560.0, "P2-118 catch card ships at half width 560")
	assert_true(str(card.get("_card_half_width_why_on", "")).contains("5.99 -> 6.74"), "P2-118 wider-card CPU score recorded")


func test_beacon_approach_is_on_with_its_score() -> void:
	var found := false
	for cand: Dictionary in _read("res://data/config/cloudreach_f40_items.json").get("candidates", []):
		if str(cand.get("preview_arg", "")) == "--cloudreach-wd-beacon-approach":
			found = true
			assert_true(cand.get("enabled") == true, "F40#3 P2-024 beacon approach ships ON")
			assert_true(str(cand.get("_why_on", "")).contains("5.84 -> 6.46"), "F40#3 beacon CPU score recorded")
	assert_true(found, "the beacon approach candidate exists")

extends "res://tests/test_case.gd"

## NEAR6-TW judged gains (owner 4 Nov 2026: every judged CPU improvement ships
## ON with its score). Each flag below is ON and records its mapped CPU score
## from the lane's verdict (ralph/reports/LANES/NEAR6-TW/qj/).


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _assert_on(block: Dictionary, score: String, label: String) -> void:
	assert_true(bool(block.get("enabled", false)), "%s ships ON (judged gain)" % label)
	assert_true(str(block.get("_why_on", "")).contains(score), "%s records %s" % [label, score])


## r27: F39#27 grass around named characters 6.03 -> 6.23.
func test_water_character_rim_ships_on() -> void:
	_assert_on(_json("res://data/config/water_character_rim.json"), "6.23", "water_character_rim")


## The fill uniform defaults to 0, so the Stormwood rim keeps its rim-only look.
func test_rim_overlay_fill_defaults_off() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/character_rim_overlay.gdshader")
	assert_true(code.contains("uniform float fill_energy = 0.0;"), "fill_energy defaults to 0")
	var stormwood := _json("res://data/config/stormwood_character_rim.json")
	assert_false(stormwood.has("fill_energy"), "Stormwood rim sets no fill")

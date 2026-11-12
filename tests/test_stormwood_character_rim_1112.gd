extends "res://tests/test_case.gd"

## Stormwood runs without the character night rim (LANE-THINGS, 12 Nov 2026;
## GPU High G-things-stormrim.md: F41#18 5.60 -> 6.22, F41#15 6.18 -> 6.59).
## The rim at full weight under Stormwood's bright ambient blew the player and
## the officers out to a pink-white glow.


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_clear_weather_look_has_no_character_rim() -> void:
	var env: Dictionary = (_json("res://data/config/stormwood_look.json").get("rig", {}) as Dictionary).get("environment", {})
	assert_almost_eq(float(env.get("player_character_rim_scale", -1.0)), 0.0, 0.0001, "clear-weather rim weight")
	assert_true(str(env.get("_why_on_rim_1112", "")).contains("G-things-stormrim"), "records its verdict")


func test_surge_base_has_no_character_rim() -> void:
	var doc := _json("res://data/config/stormwood_surge.json")
	var env: Dictionary = doc["presentation"]["storm_base"]["overrides"]["environment"]
	assert_almost_eq(float(env.get("player_character_rim_scale", -1.0)), 0.0, 0.0001, "surge rim weight")

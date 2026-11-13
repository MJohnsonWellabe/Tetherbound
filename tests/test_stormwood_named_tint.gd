extends "res://tests/test_case.gd"

## F41#8 named_tint_1112 (LANE-BELOW6, 12 Nov 2026): a listed villager's body albedo
## is multiplied by its own grey only while the flag is on; the default is unchanged.

const PRESENTATION := preload("res://scripts/world/stormwood_character_presentation.gd")
const CONFIG_PATH := "res://data/config/stormwood_character_presentation.json"


func test_flag_is_declared_with_scope_and_neutral_tints() -> void:
	var cfg: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH)) as Dictionary).get("named_tint_1112", {})
	assert_false(cfg.is_empty(), "named_tint_1112 is declared")
	assert_eq(str(cfg.get("scope", "")), "client_presentation")
	for id: String in ["elder_maud", "rodkeeper_hesk", "warden_elect_bryn"]:
		var colour := Color(str((cfg.get("tints", {}) as Dictionary).get(id, "")))
		assert_true(is_equal_approx(colour.r, colour.g) and is_equal_approx(colour.g, colour.b),
			"%s is tinted by a neutral grey (no hue shift, no red)" % id)
		assert_true(colour.r >= 0.55 and colour.r < 1.0, "%s is darkened, not crushed" % id)


func test_decorate_follows_the_flag() -> void:
	var saved: Dictionary = PRESENTATION._settings.duplicate(true)
	var settings: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH)) as Dictionary)
	settings["named_tint_1112"]["enabled"] = false
	PRESENTATION._settings = settings
	assert_false(PRESENTATION.decorate({"config_key": "local_historian"}, "elder_maud").has("tint"), "off: no tint")
	settings["named_tint_1112"]["enabled"] = true
	var on: Dictionary = PRESENTATION.decorate({"config_key": "local_historian"}, "elder_maud")
	assert_eq(str(on.get("tint", "")), str(settings["named_tint_1112"]["tints"]["elder_maud"]), "on: the listed villager is tinted")
	assert_false(PRESENTATION.decorate({"config_key": "trader"}, "oswin").has("tint"), "on: an unlisted villager is untouched")
	PRESENTATION._settings = saved

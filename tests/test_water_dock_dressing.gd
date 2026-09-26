extends "res://tests/test_case.gd"

## X04 / F13#5: the dock dressing layer is presentation only, uses installed
## models, never Team Tether red, and stands beside the swim lane.

const CONFIG := "res://data/config/water_dock_dressing.json"
const SCRIPT := "res://scripts/world/water_dock_dressing.gd"


func _cfg() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_every_dressing_model_is_installed() -> void:
	var cfg := _cfg()
	var paths: Array = [str((cfg.pier as Dictionary).deck_model), str((cfg.pier as Dictionary).post_model),
		str((cfg.lanterns as Dictionary).model)]
	for item: Variant in (cfg.cargo as Dictionary).items:
		paths.append(str((item as Dictionary).model))
	for path: String in paths:
		assert_true(ResourceLoader.exists(path), "installed model exists: %s" % path)


func test_layer_is_presentation_only_and_clear_of_the_lane() -> void:
	var source := FileAccess.get_file_as_string(SCRIPT)
	assert_true(not source.contains("CollisionShape3D") and not source.contains("StaticBody3D"),
		"the dressing adds no collision")
	var pier := _cfg().pier as Dictionary
	assert_true(float(pier.lateral_offset_m) >= float(pier.width_m) * 0.5 + 2.0,
		"the pier stands beside the safe->shore swim lane, not across it")


func test_lantern_light_and_piling_tint_are_not_team_tether_red() -> void:
	var c := Color(str((_cfg().lanterns as Dictionary).light_colour))
	assert_true(not (c.r > c.g * 1.6 and c.r > c.b * 1.6), "lantern light is warm, not red")
	var tint := Color(str((_cfg().pier as Dictionary).get("post_tint", "#ffffff")))
	assert_true(tint.get_luminance() < 0.35 and not (tint.r > tint.g * 1.6 and tint.r > tint.b * 1.6),
		"pier pilings are darkened to wet wood, not the log texture's salmon pink")
	assert_true(float((_cfg().lanterns as Dictionary).get("glow_energy", 0.0)) > 0.0,
		"dock lanterns glow so they read lit at night")

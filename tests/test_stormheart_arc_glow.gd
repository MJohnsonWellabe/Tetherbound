extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#1: hero_interior.round2.arcs.glow_1104
## gives the core arcs a white-violet core and an additive violet halo. It
## ships OFF until judged, and its colours stay storm violet, never red.

const CONFIG_PATH := "res://data/config/stormheart_presentation.json"


func _glow() -> Dictionary:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return raw.hero_interior.round2.arcs.glow_1104


func test_arc_glow_ships_off() -> void:
	assert_false(bool(_glow().get("enabled", true)), "ships OFF until judged")


func test_arc_glow_is_violet_not_red() -> void:
	var glow := _glow()
	for key: String in ["core_colour", "halo_colour"]:
		var c := Color(str(glow[key]))
		assert_true(c.b >= c.r, "%s leans violet-blue" % key)
		assert_false(c.r > c.g * 1.4 and c.r > c.b * 1.4, "%s is no red or oxblood" % key)
	assert_true(float(glow.halo_width_m) > 0.16, "the halo is wider than the arc")
	assert_true(float(glow.halo_alpha) > 0.0 and float(glow.halo_alpha) < 1.0, "the halo is translucent")

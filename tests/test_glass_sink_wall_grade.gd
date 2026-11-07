extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#10: glass_sink.wall_grade_1104 dims the
## Meshy sink shell's glow and darkens it to cool glass rock. Ships OFF until
## judged; ON it is dimmer than the shipped glow and never red.

const HL := preload("res://scripts/world/hero_landmarks_1101.gd")


func _sink() -> Dictionary:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hero_landmarks_1101.json"))
	return raw.glass_sink


func test_wall_grade_ships_off() -> void:
	var sink := _sink()
	assert_false(bool(sink.wall_grade_1104.get("enabled", true)), "ships OFF until judged")
	assert_eq(HL.wall_grade(sink), {}, "OFF returns no grade")


func test_wall_grade_dims_and_stays_cool() -> void:
	var sink := _sink()
	sink.wall_grade_1104["enabled"] = true
	var grade := HL.wall_grade(sink)
	assert_true(float(grade.glow_energy) < float(sink.glow_energy), "dimmer than the shipped glow")
	var tint := Color(str(grade.tint))
	assert_true(tint.get_luminance() < 0.6, "a darker shell")
	for key: String in ["tint", "glow_colour"]:
		var c := Color(str(grade[key]))
		assert_false(c.r > c.g * 1.4 and c.r > c.b * 1.4, "%s is no red or oxblood" % key)
		assert_true(c.b >= c.r, "%s stays cool" % key)

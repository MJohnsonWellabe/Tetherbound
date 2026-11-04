extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#18 P2-056: rank_marks_1104 gives uniformed
## Stormwood ranks pale shoulder knots and a collar ring in their identity
## colour. It ships OFF and adds nothing while OFF.

const PRESENTATION := preload("res://scripts/world/stormwood_character_presentation.gd")


func _settings() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION.CONFIG_PATH))


func test_rank_marks_ship_off_and_add_nothing() -> void:
	var settings := _settings()
	assert_false(bool(settings.rank_marks_1104.get("enabled", true)), "rank marks ship OFF until judged")
	assert_eq(PRESENTATION.rank_marks(settings, settings.identities.dace, "lieutenant"), [], "OFF adds no marks")


func test_rank_marks_on_use_identity_colour_and_rank_scale() -> void:
	var settings := _settings()
	settings.rank_marks_1104["enabled"] = true
	var officer: Array = PRESENTATION.rank_marks(settings, settings.identities.nysa, "officer")
	var lieutenant: Array = PRESENTATION.rank_marks(settings, settings.identities.dace, "lieutenant")
	assert_eq(officer.size(), 3, "two shoulder knots and a collar")
	var bones := []
	for mark: Dictionary in officer:
		bones.append(str(mark.bone))
		assert_eq(str(mark.color), str(settings.identities.nysa.rim_color), "identity colour")
		var tint := Color(str(mark.color))
		assert_false(tint.r > tint.g * 1.4 and tint.r > tint.b * 1.4, "no red or oxblood on a mark")
	assert_eq(bones, ["LeftArm", "RightArm", "neck"], "marks sit on the upper arms and the neck")
	assert_true(float(lieutenant[0].size) > float(officer[0].size), "a lieutenant's marks are larger")

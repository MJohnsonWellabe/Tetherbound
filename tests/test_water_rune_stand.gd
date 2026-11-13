extends "res://tests/test_case.gd"

## LANE-THINGS, 13 Nov 2026 (GPU lane: Rune's dialogue never engaged the
## conversation camera). Rune's authored Gull Rest offset (6, 0, -20) stood him
## on a steep sand face: the ground fell 12 m within 10 m on one side and rose
## 5 m on the other, so nobody could stand beside him and he was in no frame.
## He now stands on the flat top of the same dune, about 11 m away, where the
## ground within 4 m is within 1 m of his own height (CPU terrain probe) and
## the dialogue capture finds its stand ("near").
const PATH := "res://data/config/water_characters.json"


func _rune() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert_true(parsed is Dictionary)
	for row: Variant in (parsed as Dictionary).get("trainers", []):
		if row is Dictionary and str((row as Dictionary).get("id", "")) == "water_trainer_rune":
			return row
	return {}


func test_rune_stands_on_the_flat_dune_top() -> void:
	var rune := _rune()
	assert_false(rune.is_empty(), "Rune is still a Tidewake trainer")
	assert_eq(str(rune.get("island_id", "")), "gull_rest", "he keeps his island")
	var offset: Array = rune.get("island_local_offset", [])
	assert_eq(offset.size(), 3)
	assert_eq(float(offset[0]), -2.0)
	assert_eq(float(offset[1]), 0.0)
	assert_eq(float(offset[2]), -12.0)


func test_rune_is_not_back_on_the_steep_face() -> void:
	var offset: Array = _rune().get("island_local_offset", [])
	var old := Vector2(6.0, -20.0)
	assert_true(Vector2(float(offset[0]), float(offset[2])).distance_to(old) > 8.0,
		"the old spot and everything within 8 m of it on the seaward side is a slope nobody can stand on")

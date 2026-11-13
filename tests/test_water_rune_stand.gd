extends "res://tests/test_case.gd"

## LANE-THINGS, 13 Nov 2026 (GPU lane: Rune's dialogue never engaged the
## conversation camera). Rune's authored Gull Rest offset (6, 0, -20) stood him
## on a steep sand face: the ground fell 12 m within 10 m on one side and rose
## 5 m on the other, so nobody could stand beside him and he was in no frame.
## He now stands on the flat top of the same dune, where the ground within 6 m
## is within 1 m of his own height (CPU terrain probe) and the dialogue capture
## finds its stand. The first move (-2, 0, -12) was flat but 7.5 m from the
## Gull Rest wild cluster (test_water_trainer_ring_clearance needs 15.5 m);
## this spot is 17.7 m from it.
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
	assert_eq(float(offset[0]), 3.0)
	assert_eq(float(offset[1]), 0.0)
	assert_eq(float(offset[2]), 3.0)


func test_rune_is_not_back_on_the_steep_face() -> void:
	var offset: Array = _rune().get("island_local_offset", [])
	var old := Vector2(6.0, -20.0)
	assert_true(Vector2(float(offset[0]), float(offset[2])).distance_to(old) > 8.0,
		"the old spot and everything within 8 m of it on the seaward side is a slope nobody can stand on")


func test_rune_keeps_clear_of_the_gull_rest_wild_cluster() -> void:
	var world: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var encounters: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_encounters.json"))
	var centre := Vector2.ZERO
	for island: Dictionary in (world as Dictionary).get("islands", []):
		if str(island.id) == "gull_rest":
			centre = Vector2(float(island.center_xz_m[0]), float(island.center_xz_m[1]))
	var offset: Array = _rune().get("island_local_offset", [])
	var spot := centre + Vector2(float(offset[0]), float(offset[2]))
	for site: Dictionary in (encounters as Dictionary).get("wild_sites", []):
		if str(site.get("id", "")) == "water_gull_rest_wild_001":
			var at: Array = site.position
			assert_true(spot.distance_to(Vector2(float(at[0]), float(at[2]))) >= 15.5,
				"Rune's fight ring must clear the Gull Rest wild cluster")

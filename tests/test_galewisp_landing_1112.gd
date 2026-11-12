extends "res://tests/test_case.gd"
## Pins the Galewisp landing presentation judged on GPU High on 12 Nov 2026
## (G-galeland2.md, tb/item-scout-1108 244c8064): landed 6.34 -> 8.11.

func _fly() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/fly_traversal.json"))

func test_landed_carrier_stands_beside_the_trainer() -> void:
	var landing: Dictionary = _fly().get("landing_presentation", {})
	assert_almost_eq(float(landing.get("side_m", 0.0)), 2.3, 0.001, "carrier lands a full body width aside")
	assert_almost_eq(float(landing.get("forward_m", 0.0)), 2.4, 0.001, "forward distance unchanged (closer crops the ears)")

func test_galewisp_art_height_is_at_its_ceiling() -> void:
	var cap: Dictionary = (_fly().get("capabilities", {}) as Dictionary).get("galewisp", {})
	assert_almost_eq(float(cap.get("presentation_height_m", 0.0)), 3.4, 0.001, "Galewisp carrier art height")
	assert_true(float(cap.get("presentation_height_m", 0.0)) > 1.8, "taller than the trainer")

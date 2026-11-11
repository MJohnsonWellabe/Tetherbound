extends "res://tests/test_case.gd"

## F39#30 (11 Nov 2026): the Tidewake dune ripple relief ships soft. A low sun
## turned the old 8-degree ripple normal tilt into hard, regular dark stripes
## across the sand at dawn and golden hour (GPU High G-floor2-sand-ripple-relief,
## F39#30 5.85 -> 6.16). The ripple tint carries the pattern instead.

const LOOK := "res://data/config/tidewake_look.json"


func _dunes() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOOK))
	assert_true(raw is Dictionary, "tidewake_look.json parses")
	return (raw as Dictionary).get("dunes", {})


func test_ripple_relief_ships_soft() -> void:
	var dunes := _dunes()
	assert_true(float(dunes.get("normal_strength", 1.0)) <= 0.05, "ripple normal tilt stays small so a low sun cannot stripe the sand")
	assert_true(float(dunes.get("ripple_strength", 0.0)) >= 0.02, "the ripple tint carries the pattern at every time of day")
	assert_true(str(dunes.get("_why_ripple_relief_1111", "")).contains("5.85 -> 6.16"), "the dune block records its GPU verdict")

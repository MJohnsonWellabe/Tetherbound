extends "res://tests/test_case.gd"

## Fallen Giant trunk dither (LANE-MESHY): near_lens_fade.narrow_band_1110
## narrows the near-lens dither band. Ships ON after the GPU judge (grove
## +1.30, 3/3, no regression on F41#3/#4/#5); OFF keeps the 3-7 m band.

func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/foliage_camera_visibility.json"))

func test_narrow_band_values_and_scope() -> void:
	var fade: Dictionary = _cfg().near_lens_fade
	var band: Dictionary = fade.narrow_band_1110
	assert_true(float(band.opaque_above_m) - float(band.invisible_below_m) <= 1.5, "dither covers at most 1.5 m")
	assert_true(float(band.invisible_below_m) >= 2.5, "the trunk is still gone right at the lens")
	assert_true(float(band.opaque_above_m) < float(fade.opaque_above_m), "solid sooner than the wide band")
	var src := FileAccess.get_file_as_string("res://scripts/world/foliage_camera_visibility.gd")
	assert_true(src.contains("narrow_band_1110"), "near_lens_fade reads the candidate")

func test_ships_on_with_judged_gain_recorded() -> void:
	var band: Dictionary = _cfg().near_lens_fade.narrow_band_1110
	assert_true(bool(band.get("enabled", false)), "narrow band ships ON after the GPU judge")
	assert_true(str(band.get("_why_on", "")).contains("+1.30"), "the judged gain is recorded")

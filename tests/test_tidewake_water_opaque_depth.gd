extends "res://tests/test_case.gd"

## CARD:T2 / F13#5 water cleanup (LANE-NEWAPPROACH, judged on GPU 10 Nov):
## Tidewake water turns opaque past `opaque_depth_m` so the straight edges of
## the sparse baked seabed regions no longer show through as pale wedges, and
## the water night dim is on. The shader default keeps other water unchanged.

func _water() -> Dictionary:
	var look: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/tidewake_look.json"))
	return look.surfaces.water

func test_shader_declares_opaque_depth_off_by_default() -> void:
	var src := FileAccess.get_file_as_string("res://shaders/water.gdshader")
	assert_true(src.contains("uniform float opaque_depth_m = 0.0;"), "opaque depth defaults off")
	assert_true(src.contains("if (opaque_depth_m > 0.0)"), "it only acts when set")

func test_tidewake_ships_opaque_depth_and_night_dim_with_gain_recorded() -> void:
	var water := _water()
	assert_true(float(water.get("opaque_depth_m", 0.0)) > 0.0, "Tidewake water is opaque past a depth")
	assert_true(float(water.get("opaque_depth_m", 0.0)) <= 3.0, "shallows still show the seabed")
	assert_true(float(water.get("night_dim_max", 0.0)) > 0.0, "water night dim is on")
	assert_true(str(water.get("_why_t2_cleanup_1110", "")).contains("+0.85"), "the judged gain is recorded")

func test_no_raw_string_reaches_a_colour_uniform() -> void:
	# water_surface.gd converts only *colour keys to Color; any other key is
	# passed to the shader raw, so a hex string there would never apply.
	for key: String in _water().keys():
		if key.begins_with("_") or key.ends_with("colour"):
			continue
		assert_false(_water()[key] is String, "%s is not a raw string" % key)

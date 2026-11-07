extends "res://tests/test_case.gd"

## P2-108 UIPOSES candidate: water_mount_presentation ships OFF; sink and bob
## arithmetic; the seated rider stays above sea level at the deepest bob.

const LOOK := preload("res://scripts/world/water_mount_presentation.gd")


func test_ships_on_with_its_judged_score() -> void:
	# tb/vis-tidewake-1104 r1: F39#8 CPU 4.93 -> 6.09, F39#22 CPU 5.25 -> 6.28 (camera_hide).
	var cfg := LOOK.config()
	assert_true(bool(cfg.get("enabled", false)))
	assert_true(str(cfg.get("_why_on", "")).contains("6.09"))
	assert_false(LOOK.row("water_aquaryn").is_empty())
	assert_true(LOOK.row("water_aquaryn").has("wake"))
	var hide: Dictionary = cfg.get("camera_hide", {})
	assert_true(bool(hide.get("enabled", false)))
	assert_true(str(hide.get("_why_on", "")).contains("6.28"))


func test_off_row_is_empty() -> void:
	assert_true(LOOK.row("water_aquaryn", {"enabled": false, "mounts": {"water_aquaryn": {}}}).is_empty())


func test_row_matches_with_or_without_water_prefix() -> void:
	var cfg := {"enabled": true, "mounts": {"water_aquaryn": {"extra_sink_m": 0.9}}}
	assert_false(LOOK.row("aquaryn", cfg).is_empty())
	assert_false(LOOK.row("water_aquaryn", cfg).is_empty())
	assert_true(LOOK.row("ripplet", cfg).is_empty())


func test_rider_stays_above_sea_at_deepest_bob() -> void:
	var mounts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_mounts.json")).mounts
	var geo: Dictionary = mounts.water_aquaryn
	var look: Dictionary = LOOK.config().mounts.water_aquaryn
	var deepest := float(geo.surface_origin_offset_m) - float(look.extra_sink_m) - float(look.bob_amplitude_m)
	var rider_art := deepest + float(geo.mount_offset[1]) - 0.92
	assert_true(rider_art > 0.08, "rider art origin %.2f m stays above sea level" % rider_art)
	assert_true(absf(LOOK.origin_delta(look, 0.0) + float(look.extra_sink_m)) < 0.0001)


## F39#8 (LANE-TW, 7 Nov): the rider's own sea-floor shadow is off while
## mounted-swimming and Aquaryn sits 1.0 m deeper (judged gain, CPU 4.97 -> 6.38).
func test_f39_8_rider_shadow_and_sink_ship_on() -> void:
	var look: Dictionary = LOOK.config().mounts.water_aquaryn
	assert_true(bool(look.rider_shadows_off), "the rider's shadow is off while mounted-swimming")
	assert_true(absf(float(look.extra_sink_m) - 1.0) < 0.001, "Aquaryn sits 1.0 m deeper")
	assert_true(str(look._why_on_1107).contains("4.97 -> 6.38"), "records its score")
	var swim := FileAccess.get_file_as_string("res://scripts/world/water_mounted_swim.gd")
	assert_true(swim.contains("look.get(\"rider_shadows_off\", false)"), "the swim reads the flag")


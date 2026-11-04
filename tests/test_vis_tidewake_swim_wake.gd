extends "res://tests/test_case.gd"

## tb/vis-tidewake-1104 r4: the swimmer's waterline ring and trailing wake ship
## wider and longer (F39#5 surface swimming CPU 5.31 -> 5.63, three code-blind
## judges, calibrated r 0.96). Values only; the ring view stays local presentation.
const VIEW := preload("res://scripts/player/human_water_contact_view.gd")


func test_wake_trail_ships_on_with_its_judged_score() -> void:
	var cfg: Dictionary = VIEW.load_settings()
	assert_true(bool(cfg.get("enabled", false)))
	assert_true(str(cfg.get("_why_wake_trail_on", "")).contains("5.63"))
	assert_eq(float(cfg.get("ring_diameter_m", 0.0)), 2.1)
	assert_eq(int(cfg.get("max_trail_rings", 0)), 12)
	assert_eq(float(cfg.get("trail_lifetime_s", 0.0)), 2.6)


func test_trail_stays_within_the_view_clamp() -> void:
	# human_water_contact_view.gd clamps the ring to 3.0 m and the trail to 12 rings.
	var cfg: Dictionary = VIEW.load_settings()
	assert_true(float(cfg.ring_diameter_m) <= 3.0)
	assert_true(int(cfg.max_trail_rings) <= 12)

extends "res://tests/test_case.gd"

## F14#0 C3: the combat lens shifts up only as far as it takes to keep a tall
## uphill opponent's head below the boss panel band, never pushes the ally out
## of the bottom of the frame, and is level on flat ground
## (combat_manager.gd::top_band_lift, combat.json camera.hud_safe.top_band).

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const H := 720.0
const FOV := 46.0
const FOE_DEPTH := 16.0
const ALLY_DEPTH := 10.0


func _focal() -> float:
	return H * 0.5 / tan(deg_to_rad(FOV) * 0.5)


func _lift(live: float, foe_top: float, ally_bottom: float) -> float:
	return MANAGER.top_band_lift(live, foe_top, FOE_DEPTH, ally_bottom, ALLY_DEPTH, H, FOV,
		0.25, 0.02, 0.97, 3.0)


func test_level_when_the_opponent_already_sits_below_the_band() -> void:
	assert_almost_eq(_lift(0.0, 300.0, 600.0), 0.0, 0.0001)


func test_lifts_to_put_the_opponent_top_on_the_band_line() -> void:
	var lift := _lift(0.0, 150.0, 560.0)
	assert_true(lift > 0.0, "an opponent head at y=150 lifts the lens")
	assert_almost_eq(150.0 + lift * _focal() / FOE_DEPTH, 0.27 * H, 0.5)


func test_never_pushes_the_ally_out_of_the_bottom() -> void:
	var lift := _lift(0.0, 40.0, 660.0)
	assert_true(660.0 + lift * _focal() / ALLY_DEPTH <= 0.97 * H + 0.5, "ally bounds stay inside 97% of the frame")


func test_capped_and_eases_back_to_level() -> void:
	assert_almost_eq(_lift(0.0, -4000.0, 100.0), 3.0, 0.0001)
	assert_true(_lift(2.0, 400.0, 500.0) < 2.0, "a lower opponent releases the lift")
	assert_almost_eq(_lift(0.5, 700.0, 500.0), 0.0, 0.0001)


func test_band_is_opt_in_per_opponent() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
	var band: Dictionary = cfg.camera.hud_safe.top_band
	assert_false(bool(band.enabled), "off for every fight that does not ask for it")
	var alpha: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_alpha.json"))
	assert_true(bool(alpha.combat_camera.framing.top_band), "Aquaryn asks for it")
	assert_true(float(band.max_lift_m) <= 4.0, "a small presentation shift, not a new camera")

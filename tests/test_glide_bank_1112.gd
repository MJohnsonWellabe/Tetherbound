extends "res://tests/test_case.gd"

## fly_traversal.json glide_bank_1112 (LANE-THINGS, 12 Nov 2026; F38#15): the
## carrier art rolls into a turn and dips its nose with speed. Art only.

const FLY := preload("res://scripts/player/fly_controller.gd")
const BANK := {"max_bank_deg": 24.0, "nose_down_deg": 8.0, "roll_sign": -1.0, "pitch_sign": 1.0}


func test_level_when_hovering() -> void:
	var t := FLY.glide_bank_targets(BANK, Vector3.ZERO, Vector3.ZERO, 0.016, Basis.IDENTITY, 16.0, 12.0)
	assert_almost_eq(t.x, 0.0, 0.0001, "no roll at rest")
	assert_almost_eq(t.y, 0.0, 0.0001, "no pitch at rest")


func test_rolls_toward_the_turn_and_is_bounded() -> void:
	var right := FLY.glide_bank_targets(BANK, Vector3(5, 0, -10), Vector3(0, 0, -10), 0.016, Basis.IDENTITY, 16.0, 12.0)
	var left := FLY.glide_bank_targets(BANK, Vector3(-5, 0, -10), Vector3(0, 0, -10), 0.016, Basis.IDENTITY, 16.0, 12.0)
	assert_true(right.x < 0.0 and left.x > 0.0, "roll follows the side the carrier accelerates toward")
	assert_true(absf(right.x) <= deg_to_rad(24.0) + 0.0001, "roll never exceeds max_bank_deg")


func test_nose_dips_with_forward_speed() -> void:
	var t := FLY.glide_bank_targets(BANK, Vector3(0, 0, -16), Vector3(0, 0, -16), 0.016, Basis.IDENTITY, 16.0, 12.0)
	assert_almost_eq(t.y, deg_to_rad(8.0), 0.0001, "full speed reaches nose_down_deg")
	assert_almost_eq(t.x, 0.0, 0.0001, "straight flight does not roll")


func test_flag_ships_declared() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/fly_traversal.json"))
	var bank: Dictionary = cfg.get("glide_bank_1112", {})
	assert_true(bank.has("enabled"), "flag is declared")
	assert_eq(str(bank.get("scope", "")), "client_presentation", "art only")

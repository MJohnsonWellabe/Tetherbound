extends "res://tests/test_case.gd"

## F38#5 / F38#26 / F38#31 (LANE-FLOOR2): `creature_ruler_depth` in
## capture_stands.json moves the creature pose stage's subject from 7 m or more
## beyond the trainer to beside the trainer, so the 1.80 m ruler and the
## subject share a depth. Ships ON (GPU round 3). Capture tooling only.

const STAGE := preload("res://tools/phase2_capture_creatures.gd")
const STANDS := "res://data/config/capture_stands.json"
const CAMERA_ARM_M := 5.2
const TRAINER_M := 1.8


func _cfg() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STANDS))
	assert_true(parsed is Dictionary, "capture_stands.json parses")
	return (parsed as Dictionary).get("creature_ruler_depth", {})


## On-screen height of a subject relative to the trainer's, by similar
## triangles from the production camera arm behind the trainer.
func _apparent_ratio(height: float, offsets: Vector2) -> float:
	var subject_range := Vector2(offsets.x, CAMERA_ARM_M + offsets.y).length()
	return (height / subject_range) / (TRAINER_M / CAMERA_ARM_M)


func test_ruler_depth_ships_on() -> void:
	# G-floor2-creature-ruler-depth-r3 (GPU High): F38#5 5.80 -> 7.77, F38#31 ->
	# 7.20, F38#26 -> 6.85, 3/3 judges. The subject starts ON the trainer's depth
	# plane (0 m ahead); the fit rule may only move it sideways or away.
	var cfg := _cfg()
	assert_true(bool(cfg.get("enabled", false)), "creature_ruler_depth ships ON")
	assert_true(str(cfg.get("_why_on", "")).contains("G-floor2-creature-ruler-depth-r3"), "the verdict is cited")
	for height: float in [2.4, 3.9, 9.0]:
		assert_almost_eq(STAGE.stage_offsets(height, cfg).y, 0.0, 0.0001, "0 m ahead of the trainer at %.1f m" % height)
	assert_true(float(cfg.get("fit_contact_band_m", 0.0)) > 0.0, "the ground-contact rule has its band")


func test_off_keeps_the_old_stage() -> void:
	for height: float in [1.9, 2.4, 2.9, 3.9, 6.0]:
		var got: Vector2 = STAGE.stage_offsets(height, {})
		assert_almost_eq(got.x, clampf(height * 0.7, 2.0, 5.0), 0.0001, "side unchanged")
		assert_almost_eq(got.y, maxf(7.0, height * 1.8), 0.0001, "distance unchanged")
		var disabled: Vector2 = STAGE.stage_offsets(height, {"enabled": false, "ahead_min_m": 3.0})
		assert_almost_eq(disabled.y, got.y, 0.0001, "a disabled block changes nothing")


func test_old_stage_draws_a_taller_creature_no_taller_than_the_trainer() -> void:
	# The reproduced cause: a 2.9 m hare 7 m beyond the trainer.
	var ratio := _apparent_ratio(2.9, STAGE.stage_offsets(2.9, {}))
	assert_true(ratio < 1.0, "2.9 m subject draws shorter than the 1.80 m trainer (%.2f)" % ratio)


func test_on_keeps_real_height_order_on_screen() -> void:
	var cfg := _cfg().duplicate()
	cfg["enabled"] = true
	for height: float in [2.2, 2.4, 2.9, 3.3, 3.9, 6.0, 9.0]:
		var offsets: Vector2 = STAGE.stage_offsets(height, cfg)
		assert_true(offsets.y >= 0.0 and offsets.y <= 12.0, "ahead stays in range")
		assert_true(offsets.x >= 2.0, "subject stands clear of the trainer's side")
		var ratio := _apparent_ratio(height, offsets)
		assert_true(ratio > 1.0, "%.1f m subject draws taller than the trainer (%.2f)" % [height, ratio])
	# An alpha's size step survives the stage (trailpup 2.4 m, alpha x1.35).
	var normal := _apparent_ratio(2.4, STAGE.stage_offsets(2.4, cfg))
	var alpha := _apparent_ratio(2.4 * 1.35, STAGE.stage_offsets(2.4 * 1.35, cfg))
	assert_true(alpha > normal * 1.1, "alpha draws clearly larger than its normal form")

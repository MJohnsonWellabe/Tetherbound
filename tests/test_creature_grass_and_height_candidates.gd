extends "res://tests/test_case.gd"

## P2-020 / P2-017 (vis-meadows, OFF until GPU-judged): wider grass clearing
## while a creature ambles, and a fourth taller-than-trainer scale batch.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CLEAR := "res://data/config/creature_grass_clear.json"
const FLAGS := "res://data/config/creature_scale_flags.json"


func test_grass_clear_candidate_off_is_shipped_and_on_widens() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CLEAR))
	assert_false(bool(cfg.p2_020_candidate.get("enabled", true)), "ships OFF")
	assert_eq(JSON.stringify(BODY.with_grass_clear_candidate(cfg)), JSON.stringify(cfg))
	cfg.p2_020_candidate.enabled = true
	var on := BODY.with_grass_clear_candidate(cfg)
	assert_true(float(on.radius_scale) > float(cfg.radius_scale))
	assert_true(float(on.still_speed) > float(cfg.still_speed))
	assert_true(bool(on.enabled), "the clearing itself stays on")


func test_height_batch_4_ships_off_and_only_grows() -> void:
	var flags: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FLAGS))
	var batch: Dictionary = flags.flags.creatures_f36_taller_than_trainer_4
	assert_false(bool(batch.get("enabled", true)), "ships OFF")
	for id: String in batch.species:
		assert_true(float(batch.species[id]) >= 1.0, "grow, never shrink: " + id)

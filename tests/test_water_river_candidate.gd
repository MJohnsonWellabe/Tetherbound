extends "res://tests/test_case.gd"

## P2-006 (vis-meadows, OFF until GPU-judged): water.json
## `river.surface_candidate` changes only the river's own config and material.

const WATER := preload("res://scripts/world/water.gd")
const CONFIG := "res://data/config/water.json"


func _shipping() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary


func test_candidate_ships_off_and_off_changes_nothing() -> void:
	var cfg := _shipping()
	assert_false(bool(cfg.river.surface_candidate.get("enabled", true)), "P2-006 candidate ships OFF")
	var applied := cfg.duplicate(true)
	WATER.apply_river_candidate(applied)
	assert_eq(JSON.stringify(applied), JSON.stringify(cfg))
	assert_eq(WATER.river_candidate_shader(cfg), {})


func test_on_merges_river_only_and_converts_colours() -> void:
	var cfg := _shipping()
	cfg.river.surface_candidate.enabled = true
	var pond_before := JSON.stringify(cfg.get("pond", {}))
	var surface_before := JSON.stringify(cfg.get("surface", {}))
	var reeds_models: Array = cfg.river.reeds.models.duplicate()
	WATER.apply_river_candidate(cfg)
	assert_eq(int(cfg.river.reeds.clumps), 130)
	assert_eq(cfg.river.reeds.models, reeds_models, "unmentioned nested keys stay")
	assert_eq(JSON.stringify(cfg.get("pond", {})), pond_before)
	assert_eq(JSON.stringify(cfg.get("surface", {})), surface_before)
	var shader := WATER.river_candidate_shader(cfg)
	assert_true(shader.deep_colour is Color, "hex strings become colours")
	assert_almost_eq(float(shader.wave_strength), 0.8)


func test_r2_adds_bank_rocks_only_through_the_candidate() -> void:
	var cfg := _shipping()
	assert_false(cfg.river.has("bank_rocks"), "no river rocks while OFF")
	cfg.river.surface_candidate.enabled = true
	WATER.apply_river_candidate(cfg)
	assert_true(cfg.river.has("bank_rocks"))
	for model: Variant in cfg.river.bank_rocks.models:
		assert_true(ResourceLoader.exists(str(model)), "rock model installed: " + str(model))

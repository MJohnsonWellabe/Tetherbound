extends "res://tests/test_case.gd"

const BRIDGE := preload("res://scripts/world/south_bridge.gd")
const HERO := preload("res://assets/environment/team_tether/south_bridge_gate.glb")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")


func test_checkpoint_gate_is_a_fortified_chapter_threshold_at_trainer_scale() -> void:
	var model := HERO.instantiate() as Node3D
	assert_true(model != null, "the approved South Bridge hero gate must load")
	if model == null:
		return
	var raw := BOUNDS.measure(model)
	assert_true(raw.size.y > 0.0, "the approved gate has measurable geometry")
	var fitted_width := raw.size.x * BRIDGE.HERO_GATE_HEIGHT / raw.size.y
	assert_almost_eq(BRIDGE.HERO_GATE_HEIGHT, 4.4, 0.001)
	assert_true(BRIDGE.HERO_GATE_HEIGHT / 1.8 >= 2.4,
		"the chapter gate must stand at least 2.4 trainer-heights")
	assert_true(fitted_width >= 9.0,
		"the fortified gate must span the bridge and its gully shoulders")
	model.free()

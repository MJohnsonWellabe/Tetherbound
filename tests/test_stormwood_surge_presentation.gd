extends "res://tests/test_case.gd"

const SURGE := preload("res://scripts/world/stormwood_surge.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")


func test_phase_delta_preserves_existing_light_contract_and_sets_shadow_opacity() -> void:
	var surge := SURGE.new()
	var expected := {
		"calm": {"shadow": 0.68, "energy": 0.85, "colour": "#b6d5c5", "fog": 0.0},
		"building": {"shadow": 0.68, "energy": 0.85, "colour": "#d7a77b", "fog": 0.0},
		"break": {"shadow": 1.0, "energy": 0.65, "colour": "#d2ccff", "fog": 0.00015},
		"fading": {"shadow": 0.68, "energy": 0.85, "colour": "#e0b397", "fog": 0.0},
	}
	for phase: String in expected:
		var delta: Dictionary = surge.light_delta_for_phase(phase)
		var sun: Dictionary = delta.sun
		var environment: Dictionary = delta.environment
		assert_almost_eq(float(sun.shadow_opacity), float(expected[phase].shadow))
		assert_almost_eq(float(sun.energy_mult), float(expected[phase].energy))
		assert_eq(str(environment.ambient_colour), str(expected[phase].colour))
		assert_almost_eq(float(environment.ambient_energy_mult), 0.85)
		assert_almost_eq(float(environment.fog_density_add), float(expected[phase].fog))
	surge.free()


func test_production_phase_application_reaches_world_look_and_live_sun() -> void:
	var world := Node3D.new()
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_opacity = 0.13
	world.add_child(sun)

	var look: Node = WORLD_LOOK.new()
	look.name = "WorldLook"
	look.set("sun_path", NodePath("../Sun"))
	look.set("_config", {
		"sun": {"energy": 1.4, "shadow_enabled": true},
		"sky": {},
		"environment": {},
		"times": {"day": {"hour": 8.0}},
	})
	world.add_child(look)

	var surge := SURGE.new()
	surge.world = world
	surge.phase = "calm"
	surge.call("_apply_phase_light")
	assert_almost_eq(sun.shadow_opacity, 0.68, 0.0001,
		"Calm must restore Stormwood's authored shadow floor after WorldLook applies the global default")
	assert_almost_eq(sun.light_energy, 1.4 * 0.85, 0.0001,
		"the existing non-Break energy multiplier remains in the production application path")

	surge.phase = "break"
	surge.call("_apply_phase_light")
	assert_almost_eq(sun.shadow_opacity, 1.0, 0.0001,
		"Break keeps the authored hard-shadow presentation")
	assert_almost_eq(sun.light_energy, 1.4 * 0.65, 0.0001,
		"the existing Break energy multiplier remains in the production application path")

	surge.free()
	world.free()

extends "res://tests/test_case.gd"

## F10 phase readability wiring. Values come from
## data/config/stormwood_surge.json `presentation`; these tests pin that the
## production node applies them (rain visible, sky overrides for every storm
## phase, Break-only flashes, a distinct aftermath) rather than any one tuning.

const SURGE := preload("res://scripts/world/stormwood_surge.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const PHASES := ["calm", "building", "break", "fading"]


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_surge.json"))


func _world_with_look() -> Dictionary:
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
	return {"world": world, "sun": sun, "look": look}


func test_every_storm_phase_has_a_complete_presentation_row() -> void:
	var block: Dictionary = _config().presentation
	for phase: String in PHASES:
		assert_true(block.phases.has(phase), "presentation.phases.%s missing" % phase)
		var row: Dictionary = block.phases[phase]
		for key: String in ["sun_energy_mult", "ambient_colour", "ambient_energy_mult", "fog_density_add",
				"sky_top", "sky_horizon", "sky_ground_horizon", "ceiling_colour", "ceiling_opacity",
				"ceiling_speed", "rain_visible", "rain_amount", "flashes"]:
			assert_true(row.has(key), "presentation.phases.%s.%s missing" % [phase, key])
		assert_true(bool(row.rain_visible), "%s: Stormwood rains in every storm phase" % phase)
		assert_true(float(row.sun_energy_mult) >= 0.4,
			"%s: sun multiplier %.2f would make the phase unplayably dark" % [phase, float(row.sun_energy_mult)])
		for key: String in ["sky_top", "sky_horizon", "sky_ground_horizon", "ceiling_colour", "ambient_colour"]:
			var colour := Color(str(row[key]))
			# Copper/amber (hue ~30 degrees) is Stormwood's; red/oxblood (hue
			# within ~16 degrees of 0) is Team Tether's.
			var reddish := colour.s > 0.25 and (colour.h < 0.045 or colour.h > 0.94)
			assert_false(reddish,
				"%s.%s %s reads red; oxblood/red is reserved for Team Tether" % [phase, key, str(row[key])])


func test_every_phase_delta_overrides_sky_fog_and_light_from_config() -> void:
	var surge := SURGE.new()
	var rows: Dictionary = _config().presentation.phases
	var shadows: Dictionary = _config().presentation.shadow_opacity
	for phase: String in PHASES:
		var delta: Dictionary = surge.light_delta_for_phase(phase)
		var row: Dictionary = rows[phase]
		assert_true(delta.has("sky"), "%s must override the sky gradient" % phase)
		assert_eq(Color(str(delta.sky.top_colour)).to_html(false), Color(str(row.sky_top)).to_html(false))
		assert_eq(Color(str(delta.sky.horizon_colour)).to_html(false), Color(str(row.sky_horizon)).to_html(false))
		assert_eq(Color(str(delta.sky.ground_horizon_colour)).to_html(false), Color(str(row.sky_ground_horizon)).to_html(false))
		assert_eq(str(delta.environment.fog_colour), str(delta.sky.horizon_colour),
			"%s: fog must equal the horizon (art.json seam rule)" % phase)
		assert_almost_eq(float(delta.sun.energy_mult), float(row.sun_energy_mult))
		assert_almost_eq(float(delta.sun.shadow_opacity), float(shadows[phase]))
		assert_almost_eq(float(delta.environment.fog_density_add), float(row.fog_density_add))
		assert_eq(Color(str(delta.environment.ambient_colour)).to_html(false), Color(str(row.ambient_colour)).to_html(false))
	surge.free()


func test_phases_are_mutually_distinct_and_break_is_darkest() -> void:
	var surge := SURGE.new()
	var seen := {}
	for phase: String in PHASES:
		var delta: Dictionary = surge.light_delta_for_phase(phase)
		var signature := "%s|%s|%.3f" % [delta.sky.top_colour, delta.sky.horizon_colour, float(delta.sun.energy_mult)]
		assert_false(seen.has(signature), "%s shares its sky/light signature with %s" % [phase, str(seen.get(signature, ""))])
		seen[signature] = phase
	var break_top := Color(str(surge.light_delta_for_phase("break").sky.top_colour)).get_luminance()
	for phase: String in ["calm", "building", "fading"]:
		assert_true(Color(str(surge.light_delta_for_phase(phase).sky.top_colour)).get_luminance() > break_top,
			"Break's sky must be darker than %s" % phase)
	surge.free()


func test_night_scale_dims_storm_sky() -> void:
	var surge := SURGE.new()
	var day := Color(str(surge.light_delta_for_phase("calm", false, 1.0).sky.top_colour))
	var night := Color(str(surge.light_delta_for_phase("calm", false, 0.2).sky.top_colour))
	assert_true(night.get_luminance() < day.get_luminance() * 0.5,
		"a daylight storm sky must not light up the night")
	surge.free()


func test_rain_is_visible_and_scaled_per_phase() -> void:
	var parts := _world_with_look()
	var surge := SURGE.new()
	surge.world = parts.world
	surge._rain = surge._build_rain()
	surge.add_child(surge._rain)
	assert_false(surge._rain.visible, "precondition: world_weather builds its emitter hidden")
	var rows: Dictionary = _config().presentation.phases
	for phase: String in PHASES:
		surge.phase = phase
		surge.call("_apply_phase_light")
		assert_true(surge._rain.visible, "%s: Stormwood rain must draw" % phase)
		assert_true(surge._rain.emitting, "%s: rain must emit" % phase)
		assert_almost_eq(surge._rain.amount_ratio, float(rows[phase].rain_amount))
	assert_true(float(rows.break.rain_amount) > float(rows.calm.rain_amount),
		"Break rains harder than Calm")
	surge.free()
	parts.world.free()


func test_only_break_schedules_flashes() -> void:
	var surge := SURGE.new()
	for phase: String in PHASES:
		assert_eq(bool(surge.presentation_for(phase).get("flashes", false)), phase == "break",
			"flash rhythm belongs to Break only (%s)" % phase)
	surge.phase = "break"
	surge.settle_presentation()
	surge.call("_advance_flash", 0.016)
	assert_true(surge.flash_level() > 0.0, "a settled Break starts its flash rhythm")
	for _i in 60:
		surge.call("_advance_flash", 0.05)
	surge.phase = "calm"
	surge.settle_presentation()
	for _i in 60:
		surge.call("_advance_flash", 0.05)
	assert_almost_eq(surge.flash_level(), 0.0, 0.0001, "Calm has no flashes")
	surge.free()


func test_aftermath_calm_restores_sky_and_is_distinct() -> void:
	var surge := SURGE.new()
	var after: Dictionary = surge.light_delta_for_phase("calm", true)
	assert_false(after.has("sky"), "aftermath Calm leaves art.json's own sky (the restored sky)")
	assert_false(after.environment.has("ambient_colour"), "aftermath Calm returns ordinary ambient colour")
	assert_false(after.environment.has("fog_colour"))
	for phase: String in PHASES:
		assert_true(float(after.sun.energy_mult) > float(surge.light_delta_for_phase(phase).sun.energy_mult),
			"aftermath sun is brighter than storm %s" % phase)
	var row: Dictionary = surge.presentation_for("calm", true)
	assert_almost_eq(float(row.ceiling_opacity), 0.0, 0.0001, "the ceiling opens after the Long Storm")
	assert_false(bool(row.rain_visible), "no rain under the restored sky")
	# The short aftermath storm still reads as a storm.
	assert_true(surge.light_delta_for_phase("break", true).has("sky"))
	surge.free()


func test_aftermath_flag_hides_rain_in_production_path() -> void:
	var parts := _world_with_look()
	var surge := SURGE.new()
	surge.world = parts.world
	surge._rain = surge._build_rain()
	surge.add_child(surge._rain)
	surge.phase = "calm"
	surge.call("_apply_phase_light")
	assert_true(surge._rain.visible)
	surge.set("_aftermath", true)
	surge.call("_apply_phase_light")
	assert_false(surge._rain.visible, "aftermath Calm stops the rain")
	assert_eq(surge.presentation_key(), "aftermath:calm")
	surge.free()
	parts.world.free()


func test_production_phase_application_reaches_world_look_and_live_sun() -> void:
	var parts := _world_with_look()
	var sun: DirectionalLight3D = parts.sun
	var rows: Dictionary = _config().presentation.phases
	var surge := SURGE.new()
	surge.world = parts.world
	surge.phase = "calm"
	surge.call("_apply_phase_light")
	assert_almost_eq(sun.shadow_opacity, 0.68, 0.0001,
		"Calm must restore Stormwood's authored shadow floor after WorldLook applies the global default")
	assert_almost_eq(sun.light_energy, 1.4 * float(rows.calm.sun_energy_mult), 0.0001)
	surge.phase = "break"
	surge.call("_apply_phase_light")
	assert_almost_eq(sun.shadow_opacity, 1.0, 0.0001, "Break keeps the authored hard-shadow presentation")
	assert_almost_eq(sun.light_energy, 1.4 * float(rows["break"].sun_energy_mult), 0.0001)
	surge.free()
	parts.world.free()


func test_cross_fade_passes_through_intermediate_values() -> void:
	var surge := SURGE.new()
	var calm: Dictionary = surge.call("_resolved", surge.presentation_for("calm"))
	var brk: Dictionary = surge.call("_resolved", surge.presentation_for("break"))
	var mid: Dictionary = surge.call("_mix", calm, brk, 0.5, {})
	assert_true(float(mid.sun_energy_mult) < float(calm.sun_energy_mult) and float(mid.sun_energy_mult) > float(brk.sun_energy_mult))
	assert_true(float(mid.rain_amount) > float(calm.rain_amount) and float(mid.rain_amount) < float(brk.rain_amount))
	surge.free()

extends "res://tests/test_case.gd"

## F10 phase readability wiring. Values come from
## data/config/stormwood_surge.json `presentation`; these tests pin that the
## production node applies them (rain visible, sky overrides for every storm
## phase, Break-only flashes, a distinct aftermath, night dimming without a
## cross-fade jump, strike flashes gated per peer) rather than any one tuning.

const SURGE := preload("res://scripts/world/stormwood_surge.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const LIGHTNING := preload("res://scripts/world/stormwood_lightning.gd")
const DAY_CYCLE := preload("res://scripts/world/day_cycle.gd")
const PHASES := ["calm", "building", "break", "fading"]



class LightningFixture extends LIGHTNING:
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass


class SimulationWorld extends Node3D:
	var simulation_only := true


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_surge.json"))


func _art() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))


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
	var player := Node3D.new()
	player.name = "Player"
	world.add_child(player)
	return {"world": world, "sun": sun, "look": look, "player": player}


## `_base_look()` exactly as production builds it, from the real art.json and
## day_cycle.gd at a given hour.
func _real_base(surge: Node, hour: float) -> Dictionary:
	var art := _art()
	return surge.base_look_at(art, DAY_CYCLE.new(art), hour)


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
		assert_true(float(row.sun_energy_mult) >= 0.25,
			"%s: sun multiplier %.2f would make the phase unplayably dark" % [phase, float(row.sun_energy_mult)])
		for key: String in ["sky_top", "sky_horizon", "sky_ground_horizon", "ceiling_colour", "ambient_colour"]:
			_assert_not_red(Color(str(row[key])), "%s.%s" % [phase, key])
	for key: String in ["rim_colour", "edge_colour", "fill_colour"]:
		_assert_not_red(Color(str(block.telegraph[key])), "telegraph.%s" % key)
	_assert_not_red(Color(str(block.flash.colour)), "flash.colour")


func _assert_not_red(colour: Color, label: String) -> void:
	# Copper/amber (hue ~30 degrees) is Stormwood's; red/oxblood (hue within
	# ~16 degrees of 0) is Team Tether's.
	var reddish := colour.s > 0.25 and (colour.h < 0.045 or colour.h > 0.94)
	assert_false(reddish, "%s %s reads red; oxblood/red is reserved for Team Tether" % [label, colour.to_html(false)])


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
		assert_almost_eq(float(delta.environment.ambient_energy_mult), float(row.ambient_energy_mult))
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
	var brk: Dictionary = surge.light_delta_for_phase("break")
	for phase: String in ["calm", "building", "fading"]:
		var other: Dictionary = surge.light_delta_for_phase(phase)
		assert_true(Color(str(other.sky.top_colour)).get_luminance() > Color(str(brk.sky.top_colour)).get_luminance(),
			"Break's sky must be darker than %s" % phase)
		assert_true(float(other.sun.energy_mult) > float(brk.sun.energy_mult), "Break's sun is the lowest (J2)")
		assert_true(float(other.environment.ambient_energy_mult) >= float(brk.environment.ambient_energy_mult))
	surge.free()


# ---------------------------------------------------------------- night (S1/S2)

func test_night_base_from_real_art_config_dims_storm_sky() -> void:
	var surge := SURGE.new()
	var day := _real_base(surge, 8.0)
	var night := _real_base(surge, 23.0)
	assert_almost_eq(float(day.night_scale), 1.0, 0.001, "day preset is the reference")
	assert_true(float(night.night_scale) < 0.5, "the real night sky is much darker than day")
	var day_top := Color(str(surge.light_delta_for_phase("calm", false, day).sky.top_colour))
	var night_top := Color(str(surge.light_delta_for_phase("calm", false, night).sky.top_colour))
	assert_true(night_top.get_luminance() < day_top.get_luminance() * 0.5,
		"a daylight storm sky must not light up the night")
	surge.free()


## S1: a cross-fade that passes through the native sky (aftermath Calm has no
## sky override) must start exactly on the native sky, end exactly on the
## scaled storm sky, and never dip below both (the old code night-scaled the
## already-dark base a second time, so the fade dipped and snapped back).
func test_cross_fade_through_native_sky_has_no_dip_at_night_dusk_or_dawn() -> void:
	var surge := SURGE.new()
	for hour: float in [23.0, 18.5, 5.5]:
		var base := _real_base(surge, hour)
		var native: Color = base.sky_top
		surge._to = surge._resolved(surge.presentation_for("calm", true))
		surge._blend = 1.0
		var from: Dictionary = surge._current(base)
		assert_false(from.has("sky_top"), "aftermath Calm leaves the sky native")
		surge._from = from
		surge._to = surge._resolved(surge.presentation_for("calm"))
		var end: Color = surge._final(surge._to, base).sky_top
		var lo := minf(native.get_luminance(), end.get_luminance()) - 0.002
		var hi := maxf(native.get_luminance(), end.get_luminance()) + 0.002
		for step in 11:
			surge._blend = step / 10.0
			var top: Color = surge._current(base).sky_top
			assert_true(top.get_luminance() >= lo and top.get_luminance() <= hi,
				"hour %.1f t=%.1f sky lum %.3f outside [%.3f, %.3f]" % [hour, step / 10.0, top.get_luminance(), lo, hi])
		surge._blend = 0.0
		assert_eq(surge._current(base).sky_top.to_html(false), native.to_html(false),
			"hour %.1f: fade starts on the native sky, not a re-scaled one" % hour)
		surge._blend = 0.999
		var near_end: Color = surge._current(base).sky_top
		surge._blend = 1.0
		var at_end: Color = surge._current(base).sky_top
		assert_true(absf(near_end.get_luminance() - at_end.get_luminance()) < 0.005,
			"hour %.1f: no snap when the fade completes" % hour)
	surge.free()


## S2: the storm ambient keeps its authored hue but never lifts the ground
## above art.json's own ambient for the hour, at night or by day.
func test_storm_ambient_never_brightens_the_night() -> void:
	var surge := SURGE.new()
	var night := _real_base(surge, 23.0)
	var native: Color = night.ambient_colour
	var rows: Dictionary = _config().presentation.phases
	for phase: String in PHASES:
		var delta: Dictionary = surge.light_delta_for_phase(phase, false, night)
		var ambient := Color(str(delta.environment.ambient_colour))
		assert_true(ambient.get_luminance() <= native.get_luminance() + 0.01,
			"%s night ambient %.3f above native night %.3f" % [phase, ambient.get_luminance(), native.get_luminance()])
		assert_true(float(delta.environment.ambient_energy_mult) <= 1.0, "%s: no ambient energy boost" % phase)
		assert_true(float(delta.environment.ambient_energy_mult) >= 0.9,
			"%s: at night the storm does not sink art.json's night readability either" % phase)
		assert_true(float(delta.sun.energy_mult) >= 0.9, "%s: moonlight keeps the night read" % phase)
		var day_base := _real_base(surge, 8.0)
		var day := Color(str(surge.light_delta_for_phase(phase, false, day_base).environment.ambient_colour))
		var authored := Color(str(rows[phase].ambient_colour))
		assert_true(day.get_luminance() <= (day_base.ambient_colour as Color).get_luminance() + 0.01,
			"%s: by day too, the storm adds no fill light over clear weather" % phase)
		assert_almost_eq(day.h, authored.h, 0.02, "%s: the authored storm hue is kept" % phase)
	surge.free()


# ---------------------------------------------------------------- production path

func test_rain_is_visible_and_scaled_per_phase() -> void:
	var parts := _world_with_look()
	var surge := SURGE.new()
	surge.world = parts.world
	surge._rain = surge._build_rain()
	surge.add_child(surge._rain)
	assert_false(surge._rain.visible, "precondition: world_weather builds its emitter hidden")
	surge._style_rain()
	var rows: Dictionary = _config().presentation.phases
	for phase: String in PHASES:
		surge.phase = phase
		surge.call("_apply_phase_light")
		assert_true(surge._rain.visible, "%s: Stormwood rain must draw" % phase)
		assert_true(surge._rain.emitting, "%s: rain must emit" % phase)
		assert_almost_eq(surge._rain.amount_ratio, float(rows[phase].rain_amount))
	assert_true(float(rows.break.rain_amount) > float(rows.calm.rain_amount), "Break rains harder than Calm")
	surge.free()
	parts.world.free()


## J3: drops vary in size and alpha, and a second farther layer rides along.
func test_rain_streaks_vary_and_have_a_far_layer() -> void:
	var surge := SURGE.new()
	surge._rain = surge._build_rain()
	surge._style_rain()
	var cfg: Dictionary = _config().presentation.rain
	var process := surge._rain.process_material as ParticleProcessMaterial
	assert_true(process.scale_max - process.scale_min >= 0.5, "drop size must vary")
	assert_true(process.color_initial_ramp != null, "per-drop alpha ramp")
	# Unshaded streaks dim with the night instead of glowing on it.
	var day_colour := process.color
	surge.call("_update_rain", {"rain_visible": true, "rain_amount": 1.0, "night_scale": 0.12})
	assert_true(process.color.get_luminance() < day_colour.get_luminance() * 0.5, "rain tint dims at night")
	assert_almost_eq(process.color.a, day_colour.a, 0.001, "alpha is unchanged; only the tint dims")
	var ramp := (process.color_initial_ramp as GradientTexture1D).gradient
	assert_almost_eq(ramp.get_color(0).a, float(cfg.alpha_min_fraction), 0.001)
	var far: GPUParticles3D = surge._rain_far
	assert_true(far != null and far.get_parent() == surge._rain, "far layer follows the main emitter")
	var far_process := far.process_material as ParticleProcessMaterial
	assert_almost_eq(far_process.emission_ring_radius, float(cfg.far_layer.outer_radius_m), 0.001)
	assert_true((far.draw_pass_1 as BoxMesh).size.y != (surge._rain.draw_pass_1 as BoxMesh).size.y,
		"the far layer's streaks are a different length")
	surge._rain.free()
	surge.free()


func test_ceiling_builds_and_opens_in_the_aftermath() -> void:
	var parts := _world_with_look()
	var surge := SURGE.new()
	surge.world = parts.world
	surge.call("_build_ceiling")
	assert_eq(surge._ceiling.name, "StormCeiling")
	assert_almost_eq((surge._ceiling.mesh as SphereMesh).radius, float(_config().presentation.ceiling.radius_m))
	for phase: String in PHASES:
		surge.phase = phase
		surge.call("_apply_phase_light")
		assert_true(surge._ceiling.visible, "%s: storm ceiling drawn" % phase)
		assert_almost_eq(float(surge._ceiling_material.get_shader_parameter("opacity")),
			float(_config().presentation.phases[phase].ceiling_opacity), 0.0001)
	surge.phase = "calm"
	surge.set("_aftermath", true)
	surge.call("_apply_phase_light")
	assert_false(surge._ceiling.visible, "aftermath Calm: the ceiling is open")
	surge.free()
	parts.world.free()


func test_advance_presentation_cross_fades_over_real_deltas() -> void:
	var parts := _world_with_look()
	var sun: DirectionalLight3D = parts.sun
	var rows: Dictionary = _config().presentation.phases
	var seconds := float(_config().presentation.transition_seconds)
	var surge := SURGE.new()
	surge.world = parts.world
	surge.call("_build_ceiling")
	surge.phase = "calm"
	surge.settle_presentation()
	var calm_energy := 1.4 * float(rows.calm.sun_energy_mult)
	var break_energy := 1.4 * float(rows["break"].sun_energy_mult)
	assert_almost_eq(sun.light_energy, calm_energy, 0.0001)
	surge.phase = "break"
	surge.call("_begin_transition")
	var elapsed := 0.0
	while elapsed < seconds * 0.5:
		surge.call("_advance_presentation", 0.05)
		elapsed += 0.05
	assert_true(sun.light_energy < calm_energy - 0.01 and sun.light_energy > break_energy + 0.01,
		"half-way through the fade the sun is between Calm and Break (%.3f)" % sun.light_energy)
	while elapsed < seconds + 0.5:
		surge.call("_advance_presentation", 0.05)
		elapsed += 0.05
	assert_almost_eq(sun.light_energy, break_energy, 0.0001, "fade lands exactly on Break")
	var before := float(surge._ceiling_material.get_shader_parameter("cloud_time"))
	for _i in 20:
		surge.call("_advance_presentation", 0.05)
	var advanced := float(surge._ceiling_material.get_shader_parameter("cloud_time")) - before
	assert_almost_eq(advanced, float(rows["break"].ceiling_speed) * 1.0, 0.0005,
		"cloud time accumulates speed x delta (no TIME wrap)")
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


## B1 (pure gate; the lightning _receive path is exercised in both directions
## in tests/smoke_stormwood_lightning_cleanup.gd, which needs a scene tree).
## A strike broadcast from elsewhere (e.g. a guest in the glass sink during
## Calm) must not flash this peer's sky; one nearby still does; in Break
## every strike flashes the sky.
func test_strike_sky_flash_is_gated_by_phase_and_distance() -> void:
	var parts := _world_with_look()
	var surge := SURGE.new()
	surge.world = parts.world
	var range_m := float(_config().presentation.flash.strike_sky_range_m)
	surge.phase = "calm"
	surge.settle_presentation()
	assert_almost_eq(surge.sky_flash_for_strike(Vector3(300, 0, 0)), 0.0, 0.0001, "far Calm strike: no sky flash")
	assert_almost_eq(surge.sky_flash_for_strike(Vector3(range_m + 1.0, 0, 0)), 0.0, 0.0001, "beyond range: none")
	assert_true(surge.sky_flash_for_strike(Vector3(3, 0, 0)) > 0.8, "a strike beside the player still flashes")
	surge.phase = "break"
	surge.settle_presentation()
	assert_almost_eq(surge.sky_flash_for_strike(Vector3(300, 0, 0)), 1.0, 0.0001, "Break: every strike flashes")
	surge.free()
	parts.world.free()


## J1: the telegraph keeps the 1.2 s / 3 m contract exactly.
func test_telegraph_ring_keeps_the_strike_contract() -> void:
	var lightning := LightningFixture.new()
	var strike: Dictionary = _config().strike
	var ring: MeshInstance3D = lightning._build_telegraph(Vector3.ZERO)
	assert_almost_eq(float(ring.get_meta("rim_radius_m")), float(strike.radius_m), 0.0001)
	assert_almost_eq(float(strike.radius_m), 3.0, 0.0001, "WORLD 5.2: 3 m")
	assert_almost_eq(float(ring.get_meta("telegraph_seconds")), 1.2, 0.0001, "WORLD 5.2: 1.2 s")
	var material := ring.material_override as ShaderMaterial
	assert_almost_eq(float(material.get_shader_parameter("telegraph_seconds")), float(strike.telegraph_seconds), 0.0001)
	var falloff := float(_config().presentation.telegraph.edge_falloff_m)
	var outer := float(strike.radius_m) + falloff
	assert_almost_eq(float(material.get_shader_parameter("rim_fraction")) * outer, float(strike.radius_m), 0.001,
		"the bright rim is drawn at the damage radius")
	var aabb := ring.mesh.get_aabb()
	assert_almost_eq(aabb.size.x * 0.5, outer, 0.05, "mesh reaches only the soft falloff past the rim")
	assert_true(aabb.size.y < 0.2, "flat: hugs the ground rather than standing as a tube")
	ring.free()
	lightning.free()


func test_simulation_only_world_builds_no_presentation() -> void:
	var world := SimulationWorld.new()
	var surge := SURGE.new()
	world.add_child(surge)
	surge._ready()
	assert_false(surge._local, "simulation shell is not local")
	assert_true(surge._rain == null and surge._ceiling == null and surge._flash_light == null and surge._glyph == null,
		"no rain, ceiling, flash light or HUD glyph on a simulation shell")
	assert_almost_eq(surge.sky_flash_for_strike(Vector3.ZERO), 0.0, 0.0001, "no player, no flash")
	assert_true(surge.light_delta_for_phase("break").has("sky"), "pure queries still work")
	world.free()


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
	assert_true(surge.light_delta_for_phase("break", true).has("sky"), "the short aftermath storm still reads as a storm")
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

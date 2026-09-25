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
const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")
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
		assert_true(float(row.sun_energy_mult) >= 0.2,
			"%s: sun multiplier %.2f would make the phase unplayably dark" % [phase, float(row.sun_energy_mult)])
		assert_almost_eq(float(row.ceiling_opacity), 1.0, 0.0001,
			"%s: the ceiling is opaque, so no sun/moon ghost disc shows through" % phase)
		for key: String in ["sky_top", "sky_horizon", "sky_ground_horizon", "ceiling_colour", "ambient_colour"]:
			_assert_not_red(Color(str(row[key])), "%s.%s" % [phase, key])
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


func test_phases_are_mutually_distinct_and_break_has_the_darkest_ground() -> void:
	var surge := SURGE.new()
	var seen := {}
	for phase: String in PHASES:
		var delta: Dictionary = surge.light_delta_for_phase(phase)
		var signature := "%s|%s|%.3f" % [delta.sky.top_colour, delta.sky.horizon_colour, float(delta.sun.energy_mult)]
		assert_false(seen.has(signature), "%s shares its sky/light signature with %s" % [phase, str(seen.get(signature, ""))])
		seen[signature] = phase
	var brk: Dictionary = surge.light_delta_for_phase("break")
	var brk_hue := Color(str(brk.sky.top_colour)).h * 360.0
	assert_true(brk_hue >= 220.0 and brk_hue <= 280.0, "Break's sky is violet (hue %.0f)" % brk_hue)
	for phase: String in ["calm", "building", "fading"]:
		var other: Dictionary = surge.light_delta_for_phase(phase)
		# Round 4: day Break's sky is deliberately lifted (a storm afternoon,
		# not night); Break is identified by its violet hue and by the
		# darkest ground (lowest sun and fill), not the darkest sky.
		var hue := Color(str(other.sky.top_colour)).h * 360.0
		assert_false(hue >= 220.0 and hue <= 280.0, "only Break's sky is violet (%s hue %.0f)" % [phase, hue])
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


class GroundWorld extends Node3D:
	var calls := 0
	func ground_height_near(at: Vector3) -> float:
		calls += 1
		return at.x * 0.1


## J1 / judge (c): the telegraph keeps the 1.2 s / 3 m contract exactly and
## reads as a warning (amber rim, darkened interior), never red.
func test_telegraph_ring_keeps_the_strike_contract() -> void:
	var lightning := LightningFixture.new()
	var strike: Dictionary = _config().strike
	var ring: MeshInstance3D = lightning._build_telegraph(Vector3.ZERO)
	assert_almost_eq(float(ring.get_meta("rim_radius_m")), float(strike.radius_m), 0.0001)
	assert_almost_eq(float(strike.radius_m), 3.0, 0.0001, "WORLD 5.2: 3 m")
	assert_almost_eq(float(ring.get_meta("telegraph_seconds")), 1.2, 0.0001, "WORLD 5.2: 1.2 s")
	var material := ring.material_override as ShaderMaterial
	assert_almost_eq(float(material.get_shader_parameter("telegraph_seconds")), float(strike.telegraph_seconds), 0.0001)
	var cfg: Dictionary = _config().presentation.telegraph
	var outer := float(strike.radius_m) + float(cfg.edge_falloff_m)
	assert_almost_eq(float(material.get_shader_parameter("rim_fraction")) * outer, float(strike.radius_m), 0.001,
		"the bright rim is drawn at the damage radius")
	assert_almost_eq(float(material.get_shader_parameter("rim_radius")), float(strike.radius_m), 0.0001)
	# Round 4: the rim and glow ARE the game's hazard colour, read from
	# combat.json at runtime (one source), and stay >= 25 degrees of hue from
	# every reserved Team Tether oxblood (tests/test_telegraph_glow.gd's rule).
	var combat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
	var hazard := Color(str(combat.telegraph.colour))
	var rim: Color = material.get_shader_parameter("rim_colour")
	assert_eq(rim.to_html(false), hazard.to_html(false), "rim = combat.json telegraph.colour")
	assert_eq((material.get_shader_parameter("edge_colour") as Color).to_html(false), hazard.to_html(false), "glow = hazard colour")
	assert_false(cfg.has("rim_colour") or cfg.has("edge_colour"), "no copied colour in stormwood_surge.json")
	var reserved: Array = ["#6b2a20", "#7a2430"]
	var palette: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/palette.json"))
	if palette.get("accent", {}).has("tether_oxblood"):
		reserved.append(str(palette.accent.tether_oxblood))
	for hex: Variant in reserved:
		var d := absf(rim.h - Color(str(hex)).h) * 360.0
		assert_true(minf(d, 360.0 - d) >= 25.0, "rim %.0f degrees from reserved %s" % [minf(d, 360.0 - d), str(hex)])
	assert_true(Color(str(cfg.fill_colour)).get_luminance() < 0.15, "interior darkens the ground")
	# Round 4: pull about grass height, rim and glow only (not the fill).
	assert_true(float(cfg.depth_pull_m) >= 0.2 and float(cfg.depth_pull_m) <= 0.3, "depth pull ~ grass height")
	var pull_from := float(material.get_shader_parameter("pull_start_radius"))
	assert_true(pull_from > float(strike.radius_m) - 0.2 and pull_from < float(strike.radius_m) - 0.12,
		"only the rows from rim - 0.12 m outward (rim and glow) are pulled; the fill rows are not")
	ring.free()
	lightning.free()


## Review R2-1: a warning must be cheap on its own frame. One shared indexed
## mesh, and at most 25 terrain height samples per strike.
func test_telegraph_build_stays_cheap() -> void:
	var world := GroundWorld.new()
	var lightning := LightningFixture.new()
	lightning.world = world
	var first: MeshInstance3D = lightning._build_telegraph(Vector3(10, 2, 5))
	assert_true(world.calls <= 25, "height calls %d > 25 budget" % world.calls)
	assert_eq(lightning.last_telegraph_height_calls, world.calls)
	var second: MeshInstance3D = lightning._build_telegraph(Vector3(-40, 1, 90))
	assert_true(is_same(first.mesh, second.mesh), "every warning shares one cached mesh")
	var arrays := first.mesh.surface_get_arrays(0)
	assert_true(arrays[Mesh.ARRAY_INDEX] != null and (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() > 0, "indexed mesh")
	assert_true((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() <= 400, "small unit mesh")
	var heights: PackedFloat32Array = (first.material_override as ShaderMaterial).get_shader_parameter("rim_heights")
	assert_eq(heights.size(), 16)
	# Rim sample 0 sits at +x of (10, 2, 5): ground 0.1 * 13 = 1.3, relative to y 2.
	assert_almost_eq(heights[0], 1.3 - 2.0, 0.0001, "heights are relative to the strike point")
	first.free()
	second.free()
	lightning.free()
	world.free()


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


## Review R2-2: storm horizon (and fog) keep at least 65% of the native
## horizon luminance for the hour, day and night.
func test_storm_horizon_and_fog_have_a_floor() -> void:
	var surge := SURGE.new()
	var fraction := float(_config().presentation.floors.horizon_fraction)
	assert_true(fraction >= 0.6, "floor stays near the reviewed 65%")
	for hour: float in [8.0, 18.5, 23.0, 5.5]:
		var base := _real_base(surge, hour)
		var native := (base.sky_horizon as Color).get_luminance()
		for phase: String in PHASES:
			var delta: Dictionary = surge.light_delta_for_phase(phase, false, base)
			var horizon := Color(str(delta.sky.horizon_colour))
			assert_true(horizon.get_luminance() >= native * fraction - 0.01,
				"hour %.1f %s horizon %.3f < %.0f%% of native %.3f" % [hour, phase, horizon.get_luminance(), fraction * 100.0, native])
			assert_eq(str(delta.environment.fog_colour), str(delta.sky.horizon_colour), "fog follows the floored horizon")
	surge.free()


## Round-2 judge (a): night Break keeps its own violet/indigo identity and is
## not just a darker night Building.
func test_night_break_has_its_own_hue() -> void:
	var surge := SURGE.new()
	var night := _real_base(surge, 23.0)
	var brk: Dictionary = surge._final(surge._resolved(surge.presentation_for("break")), night)
	var bld: Dictionary = surge._final(surge._resolved(surge.presentation_for("building")), night)
	for key: String in ["sky_horizon", "ceiling_colour"]:
		var hb: float = (brk[key] as Color).h * 360.0
		var hd: float = (bld[key] as Color).h * 360.0
		assert_true(hb >= 220.0 and hb <= 280.0, "night Break %s is violet/indigo (hue %.0f)" % [key, hb])
		var gap := absf(hb - hd)
		assert_true(minf(gap, 360.0 - gap) >= 60.0, "night Break and Building %s hues differ (%.0f vs %.0f)" % [key, hb, hd])
	surge.free()


## Round-2 judge (e): no ceiling gaps at night (they opened onto lit flecks).
func test_ceiling_breakup_closes_at_night() -> void:
	var surge := SURGE.new()
	var fading := surge._resolved(surge.presentation_for("fading"))
	assert_true(float(surge._final(fading, _real_base(surge, 8.0)).ceiling_breakup) > 0.3, "Fading clears by day")
	assert_almost_eq(float(surge._final(fading, _real_base(surge, 23.0)).ceiling_breakup), 0.0, 0.0001, "closed at night")
	surge.free()


## Nit: day Break stays readable (replaces the old raw sun-energy guard):
## effective ground fill keeps a floor.
func test_day_break_ground_fill_keeps_a_floor() -> void:
	var surge := SURGE.new()
	var day := _real_base(surge, 8.0)
	var native := (day.ambient_colour as Color).get_luminance()
	for phase: String in PHASES:
		var delta: Dictionary = surge.light_delta_for_phase(phase, false, day)
		var fill := Color(str(delta.environment.ambient_colour)).get_luminance() * float(delta.environment.ambient_energy_mult)
		assert_true(fill >= native * 0.3, "%s ground fill %.3f below 30%% of clear day %.3f" % [phase, fill, native])
	surge.free()


## Round-2 judge (d): rain slants with the wind, the far layer is shorter and
## fainter, and at night rain is dimmer than the native night horizon.
func test_rain_slants_fades_with_depth_and_dims_at_night() -> void:
	var surge := SURGE.new()
	surge._rain = surge._build_rain()
	surge._style_rain()
	var cfg: Dictionary = _config().presentation.rain
	var near := surge._rain.process_material as ParticleProcessMaterial
	assert_true(near.particle_flag_align_y, "streaks align to their velocity")
	assert_true(Vector2(near.direction.x, near.direction.z).length() > 0.1, "constant wind slant")
	assert_true(float(cfg.far_layer.streak_length_m) < float(cfg.streak_length_m), "far streaks shorter")
	assert_true(float(cfg.far_layer.alpha) < float(cfg.alpha), "far streaks fainter")
	var night := _real_base(surge, 23.0)
	var shown: Dictionary = surge._final(surge._resolved(surge.presentation_for("building")), night)
	surge.call("_update_rain", shown)
	var drop := near.color
	var night_horizon := Color(str(surge.light_delta_for_phase("building", false, night).sky.horizon_colour))
	assert_true(drop.get_luminance() * drop.a < night_horizon.get_luminance(),
		"night rain (%.3f x %.2f) must not outshine the night horizon (%.3f)" % [drop.get_luminance(), drop.a, night_horizon.get_luminance()])
	surge._rain.free()
	surge.free()


## Horizontal (x, z) positions a drop of `emitter` can occupy over its life,
## relative to the emitter centre: spawn points round the inner ring edge
## (shifted by the upwind offset) moved by the mean drift, then pushed
## sideways by the worst `spread` drift (sin(spread) * v * t) toward `toward`.
func _drop_path(emitter: GPUParticles3D, radius: float, toward: Vector2) -> Array[Vector2]:
	var process := emitter.process_material as ParticleProcessMaterial
	var drift: Vector3 = SURGE.rain_drift(process, emitter.lifetime)
	var spread: float = SURGE.rain_spread_drift(process, emitter.lifetime)
	var offset := process.emission_shape_offset
	var points: Array[Vector2] = []
	for step in 72:
		var angle := TAU * step / 72.0
		var spawn := Vector2(cos(angle), sin(angle)) * radius + Vector2(offset.x, offset.z)
		for k in 21:
			var t := k / 20.0
			var at := spawn + Vector2(drift.x, drift.z) * t
			var push := (toward - at)
			if push.length() > 0.0001:
				at += push.normalized() * minf(spread * t, push.length())
			points.append(at)
	return points


func _camera_arms() -> Array[float]:
	var movement: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/movement.json"))
	var margin := float(movement.camera.get("collision_margin", 0.6))
	var longest := maxf(float(movement.camera.distance), float(movement.riding.camera.distance)) + margin
	var pitch_min := deg_to_rad(float(movement.camera.pitch_min_deg))
	# Horizontal camera-to-trainer distance: from the steepest pitch on foot
	# to the riding arm at level pitch.
	return [(float(movement.camera.distance) + margin) * cos(pitch_min), float(movement.camera.distance) + margin, longest]


## Task #8: the rain is centred on the camera. No drop may pass within 1.5 m
## of the lens horizontally (a lower bound on 3D distance), including the
## base emitter's 2-degree spread (sin(spread) * v * t) and the streak's own
## sideways half-extent, for the near and far layers.
func test_slanted_rain_never_crosses_the_lens() -> void:
	var surge := SURGE.new()
	surge._rain = surge._build_rain()
	surge._style_rain()
	var camera := Vector3(40.0, 12.0, -7.0)
	var centre: Vector3 = surge.rain_centre(camera, camera + Vector3(5, -3, 0))
	var lens := Vector2(camera.x - centre.x, camera.z - centre.z)
	assert_true(lens.length() < 0.001, "the rain emitter is centred on the camera")
	for emitter: GPUParticles3D in [surge._rain, surge._rain_far]:
		var process := emitter.process_material as ParticleProcessMaterial
		var streak := emitter.draw_pass_1 as BoxMesh
		var streak_h := streak.size.y * process.scale_max * 0.5 * Vector2(process.direction.x, process.direction.z).length()
		var closest := INF
		for at: Vector2 in _drop_path(emitter, process.emission_ring_inner_radius, lens):
			closest = minf(closest, at.distance_to(lens) - streak_h)
		assert_true(closest >= 1.5, "%s: a drop passes %.2f m from the lens (needs >= 1.5)" % [emitter.name, closest])
		assert_true(SURGE.rain_drift(process, emitter.lifetime).length() > 1.0, "the wind slant is real")
		assert_true(SURGE.rain_spread_drift(process, emitter.lifetime) > 0.3, "spread drift is modelled")
	surge._rain.free()
	surge.free()


## Task #8: the trainer stands in rain, not a dry disc. For every camera
## distance (steep on foot, level on foot, riding) and yaw, some near-layer
## drop passes within 3 m of the trainer horizontally.
func test_rain_reaches_the_trainer() -> void:
	var surge := SURGE.new()
	surge._rain = surge._build_rain()
	surge._style_rain()
	var process := surge._rain.process_material as ParticleProcessMaterial
	var worst := 0.0
	for arm: float in _camera_arms():
		for step in 24:
			var yaw := TAU * step / 24.0
			var player := Vector3(100.0, 5.0, 50.0)
			var camera := player - Vector3(sin(yaw), 0.0, cos(yaw)) * arm + Vector3(0, 2.0, 0)
			var centre: Vector3 = surge.rain_centre(camera, player)
			var trainer := Vector2(player.x - centre.x, player.z - centre.z)
			var nearest := INF
			for radius: float in [process.emission_ring_inner_radius,
					(process.emission_ring_inner_radius + process.emission_ring_radius) * 0.5,
					process.emission_ring_radius]:
				for at: Vector2 in _drop_path(surge._rain, radius, Vector2(1e6, 1e6)):
					nearest = minf(nearest, at.distance_to(trainer))
			worst = maxf(worst, nearest)
	assert_true(worst <= 3.0, "the nearest drop is %.2f m from the trainer in the worst framing (needs <= 3)" % worst)
	surge._rain.free()
	surge.free()


## Round 4 item 6: a storm afternoon is clearly lighter than a storm night.
func test_day_break_sky_is_clearly_lighter_than_night_break() -> void:
	var surge := SURGE.new()
	var row := surge._resolved(surge.presentation_for("break"))
	var day: Dictionary = surge._final(row, _real_base(surge, 14.0))
	var night: Dictionary = surge._final(row, _real_base(surge, 23.0))
	for key: String in ["sky_top", "ceiling_colour"]:
		var d := (day[key] as Color).get_luminance()
		var n := (night[key] as Color).get_luminance()
		assert_true(d >= 2.0 * n, "Break %s: day %.3f must be >= 2x night %.3f" % [key, d, n])
		assert_true(d >= 0.3, "Break %s by day reads as a storm afternoon (lum %.3f)" % [key, d])
	surge.free()


static func _lab(c: Color) -> Vector3:
	var lin := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	var r: float = lin.call(c.r)
	var g: float = lin.call(c.g)
	var b: float = lin.call(c.b)
	var x := (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
	var y := 0.2126 * r + 0.7152 * g + 0.0722 * b
	var z := (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	var fx: float = f.call(x)
	var fy: float = f.call(y)
	var fz: float = f.call(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


## Round 4 item 7: at 23:00 each adjacent phase pair differs clearly in its
## dominant sky element (the ceiling), by hue and/or value (CIELAB dE >= 10),
## and each keeps its identity: Calm neutral, Building olive, Break violet,
## Fading warm.
func test_night_phases_separate_by_hue_and_value() -> void:
	var surge := SURGE.new()
	var night := _real_base(surge, 23.0)
	var ceiling := {}
	for phase: String in PHASES:
		ceiling[phase] = surge._final(surge._resolved(surge.presentation_for(phase)), night).ceiling_colour
	for pair: Array in [["calm", "building"], ["building", "break"], ["break", "fading"], ["fading", "calm"]]:
		var de := _lab(ceiling[pair[0]]).distance_to(_lab(ceiling[pair[1]]))
		assert_true(de >= 10.0, "night %s vs %s ceilings differ by only dE %.1f" % [pair[0], pair[1], de])
	assert_true((ceiling.calm as Color).s < 0.1, "night Calm is a neutral grey")
	var h := func(c: Color) -> float: return c.h * 360.0
	assert_true(h.call(ceiling.building) >= 50.0 and h.call(ceiling.building) <= 90.0 and (ceiling.building as Color).s >= 0.2, "night Building is olive")
	assert_true(h.call(ceiling["break"]) >= 220.0 and h.call(ceiling["break"]) <= 280.0, "night Break is violet")
	assert_true(h.call(ceiling.fading) >= 20.0 and h.call(ceiling.fading) <= 45.0 and (ceiling.fading as Color).s >= 0.2, "night Fading stays warm")
	var brk_h := surge._final(surge._resolved(surge.presentation_for("break")), night).sky_horizon as Color
	assert_true(brk_h.get_luminance() > (ceiling["break"] as Color).get_luminance(), "night Break has a lit horizon under its ceiling")
	surge.free()


## Runs a settled Break for `seconds` and returns each flash onset's time and
## peak level.
func _break_flashes(surge: Node, seconds: float) -> Array[Vector2]:
	surge.phase = "break"
	surge.settle_presentation()
	surge._flash = 0.0
	var onsets: Array[Vector2] = []
	var t := 0.0
	var last := 0.0
	while t < seconds:
		surge.call("_advance_flash", 0.02)
		var level: float = surge.flash_level()
		if level > last + 0.001:
			if onsets.is_empty() or t - onsets[-1].x > 0.3:
				onsets.append(Vector2(t, level))
			else:
				onsets[-1].y = maxf(onsets[-1].y, level)
		last = level
		t += 0.02
	return onsets


## Coordinator review (MEDIUM): a telegraph-less distant flash must never read
## as a missed warning: clearly weaker than a real strike's full flash and
## on its own cadence, slower than the 4-8 s strike spacing.
func test_distant_flashes_are_weaker_and_slower_than_strikes() -> void:
	var cfg: Dictionary = _config().presentation.flash
	var strike: Dictionary = _config().strike
	assert_true(float(cfg.distant_strength_max) <= 0.4, "distant flash max %.2f vs strike 1.0" % float(cfg.distant_strength_max))
	assert_true(float(cfg.double_strength) <= float(cfg.distant_strength_max), "echo no brighter than a distant flash")
	assert_true(float(cfg.distant_interval_min) > float(strike.interval_max), "distant cadence apart from strikes")
	MOTION_PREFS.set_reduced_motion(false)
	var surge := SURGE.new()
	var onsets := _break_flashes(surge, 200.0)
	assert_true(onsets.size() >= 8, "Break keeps a flash rhythm (%d flashes in 200 s)" % onsets.size())
	for i in onsets.size():
		assert_true(onsets[i].y <= float(cfg.distant_strength_max) + 0.001, "distant flash %.2f too strong" % onsets[i].y)
		if i > 0:
			assert_true(onsets[i].x - onsets[i - 1].x >= float(cfg.distant_interval_min) - 0.05,
				"distant flashes %.1f s apart (min %.1f)" % [onsets[i].x - onsets[i - 1].x, float(cfg.distant_interval_min)])
	surge.flash(surge.sky_flash_for_strike(Vector3(500, 0, 0)))
	assert_almost_eq(surge.flash_level(), 1.0, 0.0001, "a real strike still flashes at full strength")
	surge.free()


## UX 8: reduced motion lowers these non-essential sky flashes (distant and
## strike); the telegraph and bolt are covered in the lightning cleanup smoke.
func test_reduced_motion_scales_sky_flashes_down() -> void:
	var scale := float(_config().presentation.flash.reduced_motion_scale)
	assert_true(scale <= 0.2, "reduced motion scales sky flashes down strongly")
	var surge := SURGE.new()
	MOTION_PREFS.set_reduced_motion(true)
	surge.phase = "break"
	surge.settle_presentation()
	surge._flash = 0.0
	surge.flash(surge.sky_flash_for_strike(Vector3(500, 0, 0)))
	assert_true(surge.flash_level() <= scale + 0.0001, "strike sky flash %.2f under reduced motion" % surge.flash_level())
	var onsets := _break_flashes(surge, 120.0)
	for onset: Vector2 in onsets:
		assert_true(onset.y <= float(_config().presentation.flash.distant_strength_max) * scale + 0.001,
			"distant flash %.3f under reduced motion" % onset.y)
	MOTION_PREFS.set_reduced_motion(false)
	surge._flash = 0.0
	surge.flash(1.0)
	assert_almost_eq(surge.flash_level(), 1.0, 0.0001, "full flashes return with reduced motion off")
	surge.free()

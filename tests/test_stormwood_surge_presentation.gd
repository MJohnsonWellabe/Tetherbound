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


var _saved_reduced_motion := false


## The reduced-motion pref is static: save it before and restore it after
## EVERY test, so a failing assert can never leak it into later tests.
func before_each() -> void:
	_saved_reduced_motion = MOTION_PREFS.reduced_motion()


func after_each() -> void:
	MOTION_PREFS.set_reduced_motion(_saved_reduced_motion)


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


## `_base_look()` exactly as production builds it: the real art.json handed
## through the surge's storm pin, and day_cycle.gd at a given hour.
func _real_base(surge: Node, hour: float) -> Dictionary:
	var art: Dictionary = surge.pinned_look_config(_art())
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
	for phase: String in ["calm", "building", "fading"]:
		var other: Dictionary = surge.light_delta_for_phase(phase)
		# WO-F10-08: every phase shares the purple sky family, so Break is
		# identified by the darkest ground (lowest key and fill), its rain
		# and its flashes, not by sky hue.
		assert_true(float(other.sun.energy_mult) > float(brk.sun.energy_mult), "Break's sun is the lowest (J2)")
		assert_true(float(other.environment.ambient_energy_mult) >= float(brk.environment.ambient_energy_mult))
	surge.free()


# ---------------------------------------------------------------- night (S1/S2)

## WO-F10-08 (rewritten from the old night-dimming test): the storm base is
## the same at every hour, so nothing night-scales the storm.
func test_storm_base_is_identical_at_every_hour() -> void:
	var surge := SURGE.new()
	var noon := _real_base(surge, 12.0)
	for hour: float in [0.0, 5.0, 6.0, 18.0, 23.0]:
		var base := _real_base(surge, hour)
		assert_almost_eq(float(base.night_scale), 1.0, 0.0001, "hour %.0f night_scale" % hour)
		for key: String in ["sky_top", "sky_horizon", "ambient_colour"]:
			assert_eq((base[key] as Color).to_html(false), (noon[key] as Color).to_html(false), "hour %.0f %s" % [hour, key])
	surge.free()

## S1, rewritten for WO-F10-08: a phase cross-fade never dips below both
## endpoints and lands without a snap, at any hour.
func test_cross_fade_between_phases_has_no_dip_at_any_hour() -> void:
	var surge := SURGE.new()
	for hour: float in [23.0, 18.5, 5.5, 12.0]:
		var base := _real_base(surge, hour)
		surge._to = surge._resolved(surge.presentation_for("calm"))
		surge._blend = 1.0
		surge._from = surge._current(base)
		surge._to = surge._resolved(surge.presentation_for("break"))
		var start: Color = surge._from.sky_top
		var end: Color = surge._final(surge._to, base).sky_top
		var lo := minf(start.get_luminance(), end.get_luminance()) - 0.002
		var hi := maxf(start.get_luminance(), end.get_luminance()) + 0.002
		for step in 11:
			surge._blend = step / 10.0
			var top: Color = surge._current(base).sky_top
			assert_true(top.get_luminance() >= lo and top.get_luminance() <= hi, "hour %.1f t=%.1f dips" % [hour, step / 10.0])
		surge._blend = 0.999
		var near_end: Color = surge._current(base).sky_top
		surge._blend = 1.0
		assert_true(absf(near_end.get_luminance() - (surge._current(base).sky_top as Color).get_luminance()) < 0.005, "no snap")
	surge.free()

## S2, rewritten for WO-F10-08: the storm ambient keeps its hue and never
## exceeds the storm base's ambient value, at any hour.
func test_storm_ambient_never_exceeds_the_storm_base() -> void:
	var surge := SURGE.new()
	var rows: Dictionary = _config().presentation.phases
	for hour: float in [0.0, 12.0]:
		var base := _real_base(surge, hour)
		for phase: String in PHASES:
			var delta: Dictionary = surge.light_delta_for_phase(phase, false, base)
			var ambient := Color(str(delta.environment.ambient_colour))
			assert_true(ambient.get_luminance() <= (base.ambient_colour as Color).get_luminance() + 0.01, "%s ambient above base" % phase)
			assert_true(float(delta.environment.ambient_energy_mult) <= 1.0, "%s: no ambient energy boost" % phase)
			var authored := Color(str(rows[phase].ambient_colour))
			if authored.s > 0.05:
				assert_almost_eq(ambient.h, authored.h, 0.02, "%s: authored hue kept" % phase)
	surge.free()

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
	assert_true(SURGE.streak_length(far) != SURGE.streak_length(surge._rain),
		"the far layer's streaks are a different length")
	surge._rain.free()
	surge.free()


## WO-F10-08 owner ruling (rewritten; the ceiling used to open to a blue
## restored sky): the ceiling stays over Stormwood in the aftermath too.
func test_ceiling_builds_and_stays_in_the_aftermath() -> void:
	var parts := _world_with_look()
	var surge := SURGE.new()
	surge.world = parts.world
	surge.call("_build_ceiling")
	assert_eq(surge._ceiling.name, "StormCeiling")
	assert_almost_eq((surge._ceiling.mesh as SphereMesh).radius, float(_config().presentation.ceiling.radius_m))
	for aftermath: bool in [false, true]:
		surge.set("_aftermath", aftermath)
		for phase: String in PHASES:
			surge.phase = phase
			surge.call("_apply_phase_light")
			assert_true(surge._ceiling.visible, "%s aftermath=%s: storm ceiling drawn" % [phase, aftermath])
			assert_almost_eq(float(surge._ceiling_material.get_shader_parameter("opacity")), 1.0, 0.0001)
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


## WO-F10-08 owner ruling (rewritten; this used to require a restored blue
## sky): the aftermath stays purple and reads only as the calmest, stillest
## storm: lighter rain than Calm, no flashes, the slowest and least
## contrasted ceiling, a steadier higher key light.
func test_aftermath_is_the_calmest_purple() -> void:
	var surge := SURGE.new()
	var calm: Dictionary = surge._resolved(surge.presentation_for("calm"))
	for phase: String in PHASES:
		var row: Dictionary = surge._resolved(surge.presentation_for(phase, true))
		assert_true(row.has("sky_top"), "%s aftermath keeps the storm sky (no blue restored sky)" % phase)
		var hue := (row.sky_top as Color).h * 360.0
		assert_true(hue >= 235.0 and hue <= 290.0, "%s aftermath sky is purple (hue %.0f)" % [phase, hue])
		assert_true(bool(row.rain_visible) and float(row.rain_amount) > 0.0, "it still rains in the aftermath")
		assert_true(float(row.rain_amount) < float(calm.rain_amount), "aftermath rain is lighter than Calm")
		assert_false(bool(row.flashes), "no flashes in the aftermath")
		assert_true(float(row.ceiling_speed) < float(calm.ceiling_speed), "stiller ceiling than Calm")
		# Round 3 (blind judge 8: "a flat, blank lavender card"): still, but a
		# structured deck; see test_aftermath_deck_is_still_but_structured.
		assert_true(float(row.ceiling_contrast) > float(calm.ceiling_contrast), "a more defined deck than Calm's")
		assert_true(float(row.sun_energy_mult) >= float(calm.sun_energy_mult), "steadier, not darker, key light")
	surge.free()

## WO-F10-08 (rewritten; the aftermath used to stop the rain): with the
## flag set, the production path keeps a light rain falling.
func test_aftermath_flag_lightens_rain_in_production_path() -> void:
	var parts := _world_with_look()
	var surge := SURGE.new()
	surge.world = parts.world
	surge._rain = surge._build_rain()
	surge.add_child(surge._rain)
	surge.phase = "calm"
	surge.call("_apply_phase_light")
	var storm_rain := surge._rain.amount_ratio
	surge.set("_aftermath", true)
	surge.call("_apply_phase_light")
	assert_true(surge._rain.visible, "aftermath rain still draws")
	assert_true(surge._rain.amount_ratio > 0.0 and surge._rain.amount_ratio < storm_rain, "lighter than Calm")
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
	# Round 3: 0.55 (was the reviewed 0.65, set for a night that the pinned
	# storm no longer has) so Break's horizon can sit below Building's and
	# Calm's in the monotonic ladder; still well clear of night-black.
	assert_true(fraction >= 0.55, "floor stays near the reviewed 55-65%")
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


## Rewritten for WO-F10-08 (was night-only): Break keeps its violet
## identity at every hour.
func test_break_keeps_its_violet_identity_at_every_hour() -> void:
	var surge := SURGE.new()
	for hour: float in [0.0, 12.0]:
		var brk: Dictionary = surge._final(surge._resolved(surge.presentation_for("break")), _real_base(surge, hour))
		for key: String in ["sky_horizon", "ceiling_colour"]:
			var hb: float = (brk[key] as Color).h * 360.0
			assert_true(hb >= 220.0 and hb <= 280.0, "Break %s violet at hour %.0f (hue %.0f)" % [key, hour, hb])
	surge.free()

## Rewritten for WO-F10-08: ceiling breakup (and every ceiling value) is the
## same at every hour; there is no night to close gaps.
func test_ceiling_breakup_is_the_same_at_every_hour() -> void:
	var surge := SURGE.new()
	for phase: String in PHASES:
		var row := surge._resolved(surge.presentation_for(phase))
		var noon: Dictionary = surge._final(row, _real_base(surge, 12.0))
		var midnight: Dictionary = surge._final(row, _real_base(surge, 23.0))
		assert_almost_eq(float(midnight.ceiling_breakup), float(noon.ceiling_breakup), 0.0001, phase)
		assert_eq((midnight.ceiling_colour as Color).to_html(false), (noon.ceiling_colour as Color).to_html(false), phase)
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


## Judge (d), rewritten for WO-F10-08: rain slants with the wind, the far
## layer is shorter and fainter, and the rain tint is the same at any hour.
func test_rain_slants_and_fades_with_depth() -> void:
	var surge := SURGE.new()
	surge._rain = surge._build_rain()
	surge._style_rain()
	var cfg: Dictionary = _config().presentation.rain
	var near := surge._rain.process_material as ParticleProcessMaterial
	assert_true(near.particle_flag_align_y, "streaks align to their velocity")
	assert_true(Vector2(near.direction.x, near.direction.z).length() > 0.1, "constant wind slant")
	assert_true(float(cfg.far_layer.streak_length_m) < float(cfg.streak_length_m), "far streaks shorter")
	assert_true(float(cfg.far_layer.alpha) < float(cfg.alpha), "far streaks fainter")
	surge.call("_update_rain", surge._final(surge._resolved(surge.presentation_for("building")), _real_base(surge, 12.0)))
	var noon := near.color
	surge.call("_update_rain", surge._final(surge._resolved(surge.presentation_for("building")), _real_base(surge, 0.0)))
	assert_eq(near.color.to_html(true), noon.to_html(true), "rain looks the same at midnight and noon")
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
		var streak_h := SURGE.streak_length(emitter) * process.scale_max * 0.5 * Vector2(process.direction.x, process.direction.z).length()
		var closest := INF
		for at: Vector2 in _drop_path(emitter, process.emission_ring_inner_radius, lens):
			closest = minf(closest, at.distance_to(lens) - streak_h)
		assert_true(closest >= 1.5, "%s: a drop passes %.2f m from the lens (needs >= 1.5)" % [emitter.name, closest])
		assert_true(SURGE.rain_drift(process, emitter.lifetime).length() > 1.0, "the wind slant is real")
		assert_true(SURGE.rain_spread_drift(process, emitter.lifetime) > 0.1, "spread drift is modelled")
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


## Item 6, rewritten for WO-F10-08: Break's sky is a storm afternoon at
## every hour, never night-black, and identical at 14:00 and 23:00.
func test_break_sky_is_a_storm_afternoon_at_every_hour() -> void:
	var surge := SURGE.new()
	var row := surge._resolved(surge.presentation_for("break"))
	var day: Dictionary = surge._final(row, _real_base(surge, 14.0))
	var night: Dictionary = surge._final(row, _real_base(surge, 23.0))
	for key: String in ["sky_top", "ceiling_colour"]:
		assert_true((day[key] as Color).get_luminance() >= 0.3, "Break %s reads as a storm afternoon" % key)
		assert_eq((night[key] as Color).to_html(false), (day[key] as Color).to_html(false), "Break %s same at 23:00" % key)
	surge.free()

## WO-F10-08 round 2 (owner: "I like the building and break pictures. The
## other two aren't fantastic enough"): every phase and the aftermath sit in
## Break's deep purple band: sky top and ceiling luminance within
## 0.8-1.15x of Break's (the owner-liked Building sits at 0.84/1.12; the
## rejected pale Calm was 1.19/1.27), horizon within the same band, and hue
## within 15 degrees of Break's.
func test_every_phase_sits_in_the_deep_purple_band() -> void:
	var surge := SURGE.new()
	var base := _real_base(surge, 12.0)
	var reference: Dictionary = surge._final(surge._resolved(surge.presentation_for("break")), base)
	var rows := {}
	for phase: String in PHASES:
		rows[phase] = surge._final(surge._resolved(surge.presentation_for(phase)), base)
	rows["aftermath"] = surge._final(surge._resolved(surge.presentation_for("calm", true)), base)
	for name: String in rows:
		for key: String in ["sky_top", "sky_horizon", "ceiling_colour"]:
			var c: Color = rows[name][key]
			var r: Color = reference[key]
			var ratio := c.get_luminance() / maxf(0.001, r.get_luminance())
			assert_true(ratio >= 0.85 and ratio <= 1.2, "%s %s luminance %.2fx Break's (band 0.85-1.2)" % [name, key, ratio])
			var dh := absf(c.h - r.h) * 360.0
			dh = minf(dh, 360.0 - dh)
			assert_true(dh <= 15.0, "%s %s hue %.0f deg from Break's" % [name, key, dh])
	surge.free()


## Adjacent phases (and the aftermath against Calm) still differ in at least
## two non-sky cues, each by a margin a blind viewer can see (reviewer: no
## token thresholds): rain amount by >= 0.2 of full (visible streak density),
## ceiling speed by >= 1.5x (visibly faster churn), wind by >= 0.2 (streak
## lean), sheet glow by >= 0.1, or flashes on/off. Ceiling motion is ordered
## Calm slow < Building < Break fastest, Fading slowing below Building,
## aftermath almost still (judge finding 4).
func test_phases_separate_by_non_sky_cues() -> void:
	var surge := SURGE.new()
	var rows := {}
	for phase: String in PHASES:
		rows[phase] = surge._resolved(surge.presentation_for(phase))
	rows["aftermath"] = surge._resolved(surge.presentation_for("calm", true))
	for pair: Array in [["calm", "building"], ["building", "break"], ["break", "fading"], ["fading", "calm"], ["aftermath", "calm"]]:
		var a: Dictionary = rows[pair[0]]
		var b: Dictionary = rows[pair[1]]
		var cues := 0
		if absf(float(a.rain_amount) - float(b.rain_amount)) >= 0.2: cues += 1
		if absf(float(a.wind) - float(b.wind)) >= 0.2: cues += 1
		var fast := maxf(float(a.ceiling_speed), float(b.ceiling_speed))
		var slow := maxf(0.0001, minf(float(a.ceiling_speed), float(b.ceiling_speed)))
		if fast / slow >= 1.5: cues += 1
		if absf(float(a.sheet_glow) - float(b.sheet_glow)) >= 0.1: cues += 1
		if bool(a.flashes) != bool(b.flashes): cues += 1
		if absf(float(a.steam) - float(b.steam)) >= 0.3: cues += 1
		assert_true(cues >= 2, "%s vs %s differ by only %d non-sky cues" % [pair[0], pair[1], cues])
	var speed := func(n: String) -> float: return float(rows[n].ceiling_speed)
	assert_true(speed.call("calm") < speed.call("building") and speed.call("building") < speed.call("break"), "Calm < Building < Break")
	assert_true(speed.call("fading") < speed.call("building") and speed.call("aftermath") < speed.call("calm"), "Fading slows, aftermath almost still")
	var fading_end := SURGE.ramped(rows.fading, rows.fading.ramp, 1.0)
	assert_true(float(rows.aftermath.rain_amount) < float(fading_end.rain_amount) and float(fading_end.rain_amount) < float(rows.calm.rain_amount)
		and float(rows.calm.rain_amount) < float(rows.fading.rain_amount),
		"rain: aftermath drizzle < Fading's end < Calm < Fading's opening")
	assert_true(float(rows["break"].sheet_glow) >= 0.4, "Break carries persistent in-cloud lightning a still can catch")
	assert_true(float(rows.building.sheet_glow) > 0.0 and float(rows.building.sheet_glow) < float(rows["break"].sheet_glow) * 0.5, "Building: faint flicker only")
	for name: String in ["calm", "fading", "aftermath"]:
		assert_almost_eq(float(rows[name].sheet_glow), 0.0, 0.0001, "%s has no lightning" % name)
		assert_false(bool(rows[name].flashes))
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


## Review should-fix: under a physics roof the near rain layer fades out (not
## a snap) and fades back outside; the far layer is untouched. The physics
## ray itself is exercised with a real StaticBody roof in
## tests/smoke_stormwood_lightning_cleanup.gd.
func test_roof_fades_the_near_rain_out_and_back() -> void:
	var surge := SURGE.new()
	surge._rain = surge._build_rain()
	surge._style_rain()
	surge.call("_update_rain", {"rain_visible": true, "rain_amount": 1.0, "night_scale": 1.0, "day_t": 1.0})
	assert_almost_eq(surge._rain.amount_ratio, 1.0, 0.0001)
	surge._roofed = true
	surge.call("_advance_roof", 0.1)
	assert_true(surge._rain.amount_ratio < 1.0 and surge._rain.amount_ratio > 0.5, "fades, does not snap (%.2f)" % surge._rain.amount_ratio)
	for _i in 20:
		surge.call("_advance_roof", 0.05)
	assert_almost_eq(surge._rain.amount_ratio, 0.0, 0.0001, "no near rain under a roof")
	assert_almost_eq(surge._rain_far.amount_ratio, 1.0, 0.0001, "distant rain outside still falls")
	surge.call("_update_rain", {"rain_visible": true, "rain_amount": 1.0, "night_scale": 1.0, "day_t": 1.0})
	assert_almost_eq(surge._rain.amount_ratio, 0.0, 0.0001, "a phase re-apply keeps the roof suppression")
	surge._roofed = false
	for _i in 20:
		surge.call("_advance_roof", 0.05)
	assert_almost_eq(surge._rain.amount_ratio, 1.0, 0.0001, "rain returns outside")
	surge._rain.free()
	surge.free()


## Review nit 5 / WO-F10-07: the near band is anchored to the floor (the
## higher of the terrain under the camera and the trainer), never floating
## with a high camera; with no ground known it falls back to camera + offset.
func test_rain_volume_is_clamped_near_the_ground() -> void:
	var surge := SURGE.new()
	var rain: Dictionary = _config().presentation.rain
	var mid := (float(rain.spawn_band_above_ground_m[0]) + float(rain.spawn_band_above_ground_m[1])) * 0.5
	var high: Vector3 = surge.rain_centre(Vector3(0, 120, 0), Vector3.ZERO, 10.0)
	assert_almost_eq(high.y, 10.0 + mid, 0.0001, "a high camera does not lift the rain off the ground")
	assert_true(high.y <= 10.0 + float(rain.max_height_above_ground_m))
	var fallback: Vector3 = surge.rain_centre(Vector3(0, 14, 0), Vector3.ZERO)
	assert_almost_eq(fallback.y, 14.0 + float(rain.camera_height_offset_m), 0.0001, "no ground known: camera + offset")
	surge.free()


## Review nit 2: under reduced motion the telegraph rim is steady (the fill
## still grows with progress to carry the timing); normally it pulses.
func test_reduced_motion_steadies_the_telegraph_rim() -> void:
	var lightning := LightningFixture.new()
	MOTION_PREFS.set_reduced_motion(false)
	var pulsing: MeshInstance3D = lightning._build_telegraph(Vector3.ZERO)
	assert_almost_eq(float((pulsing.material_override as ShaderMaterial).get_shader_parameter("pulse_enabled")), 1.0, 0.0001)
	MOTION_PREFS.set_reduced_motion(true)
	var steady: MeshInstance3D = lightning._build_telegraph(Vector3.ZERO)
	var material := steady.material_override as ShaderMaterial
	assert_almost_eq(float(material.get_shader_parameter("pulse_enabled")), 0.0, 0.0001, "steady rim")
	assert_almost_eq(float(material.get_shader_parameter("telegraph_seconds")), 1.2, 0.0001, "timing contract unchanged")
	assert_true(LIGHTNING.TELEGRAPH_SHADER.contains("progress") and LIGHTNING.TELEGRAPH_SHADER.contains("fill"), "fill carries the timing")
	pulsing.free()
	steady.free()
	lightning.free()


## Review N1: on walkables far above the terrain (Stormheart ascent, Dynamo
## platforms, bridges) the rain volume stays with the trainer: the clamp
## uses the higher of the terrain and the trainer, not the terrain alone.
func test_rain_volume_follows_a_raised_trainer() -> void:
	var surge := SURGE.new()
	var player := Vector3(0, 60, 0)
	var camera := player + Vector3(0, 2.5, 6.0)
	var centre: Vector3 = surge.rain_centre(camera, player, 0.0)
	assert_true(centre.y >= player.y, "rain centre %.1f m sits below a trainer at %.1f m" % [centre.y, player.y])
	var band: Array = _config().presentation.rain.spawn_band_above_ground_m
	assert_almost_eq(centre.y, player.y + (float(band[0]) + float(band[1])) * 0.5, 0.0001,
		"the near band sits over the trainer's floor, not the terrain far below")
	surge.free()


## WO-F10-07 foreground regression. From a production exploration camera
## pose (pivot 1.75 m, arm 5.8 m, 8 degrees down, 70 degree vertical FOV,
## 16:9) over flat ground, near-layer drops are sampled from the LIVE emitter
## parameters and projected through that camera. In Break (amount 1.0) at
## least 35 drops must be visible in the bottom 45% of the view (the grass
## between camera and trainer) at any moment, and at least 40% of the near
## drops must be above ground. At the old camera-centred 14 m column this was
## ~17 drops and ~27% (the dry foreground).
func test_near_rain_fills_the_foreground() -> void:
	var surge := SURGE.new()
	surge._rain = surge._build_rain()
	surge._style_rain()
	var rain := surge._rain
	var process := rain.process_material as ParticleProcessMaterial
	var player := Vector3.ZERO
	var pivot := player + Vector3(0, 1.75, 0)
	var pitch := deg_to_rad(8.0)
	var camera_pos := pivot + Vector3(0, sin(pitch), -cos(pitch)) * 5.8
	var camera := Transform3D(Basis.looking_at(pivot - camera_pos, Vector3.UP), camera_pos)
	var view := camera.affine_inverse()
	var projection := Projection.create_perspective(70.0, 16.0 / 9.0, 0.05, 9000.0)
	var centre: Vector3 = surge.rain_centre(camera_pos, player, 0.0)
	var direction := process.direction.normalized()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var n := 20000
	var above := 0
	var bottom := 0
	var inner := process.emission_ring_inner_radius
	var outer := process.emission_ring_radius
	for i in n:
		var r := sqrt(rng.randf_range(inner * inner, outer * outer))
		var a := rng.randf() * TAU
		var local := process.emission_shape_offset + Vector3(cos(a) * r,
			rng.randf_range(-process.emission_ring_height * 0.5, process.emission_ring_height * 0.5), sin(a) * r)
		var at := centre + local + direction * rng.randf_range(process.initial_velocity_min, process.initial_velocity_max) * rng.randf() * rain.lifetime
		if at.y <= 0.0:
			continue
		above += 1
		var v := view * at
		if v.z >= -0.05:
			continue
		var clip := projection * Vector4(v.x, v.y, v.z, 1.0)
		var ndc := Vector2(clip.x / clip.w, clip.y / clip.w)
		if absf(ndc.x) > 1.0 or absf(ndc.y) > 1.0:
			continue
		if ndc.y < -0.1:
			bottom += 1
	var expected_bottom := float(bottom) / n * rain.amount
	assert_true(float(above) / n >= 0.4, "only %.0f%% of near drops are above ground" % (100.0 * above / n))
	assert_true(expected_bottom >= 35.0, "only %.1f near drops in the bottom 45%% of the view in Break (needs >= 35)" % expected_bottom)
	rain.free()
	surge.free()


## WO-F10-08 owner direction: for every phase (storm and aftermath) the look
## at hours 0, 6, 12 and 18 is identical: sky top and horizon, fog colour and
## density, ambient colour and energy, exposure, and the key light's energy,
## angle and colour, as WorldLook would layer them on the pinned config.
func test_look_is_identical_at_every_hour() -> void:
	var surge := SURGE.new()
	var art: Dictionary = surge.pinned_look_config(_art())
	var cycle := DAY_CYCLE.new(art)
	for aftermath: bool in [false, true]:
		for phase: String in PHASES:
			var reference := ""
			for hour: float in [0.0, 6.0, 12.0, 18.0]:
				var look := _layered_look(surge, art, cycle, hour, phase, aftermath)
				if reference.is_empty():
					reference = look
				assert_eq(look, reference, "%s aftermath=%s differs at hour %.0f" % [phase, aftermath, hour])
	surge.free()


## What WorldLook would put on screen for `phase` at `hour`: its blended
## config for the hour with the surge's weather delta layered on, as a string.
func _layered_look(surge: Node, art: Dictionary, cycle: RefCounted, hour: float, phase: String, aftermath: bool) -> String:
	var blended: Dictionary = WORLD_LOOK.blended_config_at(art, cycle, hour)
	var base: Dictionary = surge.base_look_at(art, cycle, hour)
	var delta: Dictionary = surge.light_delta_for_phase(phase, aftermath, base)
	var sun: Dictionary = blended.sun
	var sky: Dictionary = blended.sky
	var env: Dictionary = blended.environment
	var parts := [
		str(delta.get("sky", {}).get("top_colour", sky.get("top_colour"))),
		str(delta.get("sky", {}).get("horizon_colour", sky.get("horizon_colour"))),
		str(delta.environment.get("fog_colour", env.get("fog_colour"))),
		"%.6f" % (float(env.get("fog_density", 0.0)) + float(delta.environment.get("fog_density_add", 0.0))),
		str(delta.environment.get("ambient_colour", env.get("ambient_colour"))),
		"%.6f" % (float(env.get("ambient_energy", 1.0)) * float(delta.environment.get("ambient_energy_mult", 1.0))),
		"%.6f" % float(env.get("exposure", 1.0)),
		"%.6f" % (float(sun.get("energy", 1.0)) * float(delta.sun.get("energy_mult", 1.0))),
		"%.4f/%.4f" % [float(sun.get("pitch_deg", 0.0)), float(sun.get("yaw_deg", 0.0))],
		str(sun.get("colour")),
	]
	return "|".join(parts)


## WO-F10-08: leaving Stormwood restores the world clock look. The pin is
## per WorldLook instance and never touches art.json or the shared config:
## the next realm's WorldLook loads art.json with its day/night presets, and
## the clock itself (day length, dark window) is identical inside Stormwood.
func test_leaving_stormwood_restores_the_clock_look() -> void:
	var surge := SURGE.new()
	var art := _art()
	var before := JSON.stringify(art)
	var pinned: Dictionary = surge.pinned_look_config(art)
	assert_eq(JSON.stringify(art), before, "pinning never mutates the loaded art config")
	assert_eq(float(pinned.day_length_seconds), float(art.day_length_seconds), "world clock length unchanged")
	var stormwood_cycle := DAY_CYCLE.new(pinned)
	var world_cycle := DAY_CYCLE.new(art)
	for hour: float in [0.0, 12.0, 23.0]:
		assert_eq(stormwood_cycle.is_dark(hour), world_cycle.is_dark(hour), "is_dark() gameplay window unchanged at %.0f" % hour)
	# The next realm: a fresh WorldLook loads art.json (no realm pin).
	var next_look: Node = WORLD_LOOK.new()
	var next_config: Dictionary = next_look.call("_load")
	var noon: Dictionary = WORLD_LOOK.blended_config_at(next_config, DAY_CYCLE.new(next_config), 12.0)
	var midnight: Dictionary = WORLD_LOOK.blended_config_at(next_config, DAY_CYCLE.new(next_config), 0.0)
	assert_ne(str(noon.sun.get("pitch_deg")), str(midnight.sun.get("pitch_deg")), "outside Stormwood the sun moves with the clock")
	assert_ne(str(noon.sky.get("top_colour")), str(midnight.sky.get("top_colour")), "outside Stormwood night is dark again")
	# A WorldLook that Stormwood pinned keeps its own config; a new one does not inherit it.
	var parts := _world_with_look()
	var look: Node = parts.look
	look.set("_config", art.duplicate(true))
	surge.world = parts.world
	surge.call("_pin_world_look")
	assert_ne(JSON.stringify(look.get("_config").times), JSON.stringify(next_config.times), "only the Stormwood WorldLook is pinned")
	next_look.free()
	surge.free()
	parts.world.free()


## Judge finding 1 + UX 8: the sheet lightning reaches the ceiling shader in
## Break, and under reduced motion it drops to the flash floor and stops
## pulsing (glow_time frozen).
func test_sheet_glow_reaches_the_ceiling_and_respects_reduced_motion() -> void:
	var parts := _world_with_look()
	var surge := SURGE.new()
	surge.world = parts.world
	surge.call("_build_ceiling")
	surge.phase = "break"
	surge.settle_presentation()
	surge.call("_advance_flash", 0.1)
	var glow := float(surge._ceiling_material.get_shader_parameter("sheet_glow"))
	assert_almost_eq(glow, float(_config().presentation.phases["break"].sheet_glow), 0.0001)
	var t0 := float(surge._ceiling_material.get_shader_parameter("glow_time"))
	surge.call("_advance_flash", 0.5)
	assert_true(float(surge._ceiling_material.get_shader_parameter("glow_time")) > t0, "glow moves")
	MOTION_PREFS.set_reduced_motion(true)
	surge.call("_advance_flash", 0.1)
	var t1 := float(surge._ceiling_material.get_shader_parameter("glow_time"))
	surge.call("_advance_flash", 0.5)
	assert_almost_eq(float(surge._ceiling_material.get_shader_parameter("glow_time")), t1, 0.0001, "no pulse under reduced motion")
	assert_true(float(surge._ceiling_material.get_shader_parameter("sheet_glow")) <= glow * 0.2, "glow at the flash floor")
	surge.free()
	parts.world.free()


## Wind response per phase stays inside the lens-safe maximum slant, and the
## intensity hook reports the phase.
func test_phase_wind_and_intensity_hook() -> void:
	var surge := SURGE.new()
	surge._rain = surge._build_rain()
	surge._style_rain()
	var process := surge._rain.process_material as ParticleProcessMaterial
	var full := Vector2(process.direction.x, process.direction.z).length()
	surge.call("_update_rain", surge._resolved(surge.presentation_for("calm")))
	var calm := Vector2(process.direction.x, process.direction.z).length()
	assert_true(calm < 0.01, "Calm's rain falls straight down (lean %.3f)" % calm)
	surge.call("_update_rain", surge._resolved(surge.presentation_for("building")))
	var building := Vector2(process.direction.x, process.direction.z).length()
	assert_true(building > full * 0.7, "Building leans with the wind (%.3f of %.3f)" % [building, full])
	for phase: String in PHASES:
		assert_true(float(surge.presentation_for(phase).wind) <= 1.0, "%s wind within the lens-safe maximum" % phase)
	surge.phase = "break"
	surge.settle_presentation()
	assert_almost_eq(surge.surge_intensity(), 1.0, 0.0001)
	surge.phase = "calm"
	surge.settle_presentation()
	assert_true(surge.surge_intensity() < 0.5)
	surge._rain.free()
	surge.free()


## Review: a jump does not bob the rain field (the anchor holds the last
## grounded height), the floor eases instead of stepping, and a big jump
## (teleport, realm change) snaps.
func test_rain_anchor_holds_through_jumps_and_eases_on_slopes() -> void:
	var anchor: float = SURGE.grounded_anchor(NAN, 10.0, false)
	assert_almost_eq(anchor, 10.0, 0.0001, "unset anchor takes the current height")
	anchor = SURGE.grounded_anchor(anchor, 10.0, true)
	anchor = SURGE.grounded_anchor(anchor, 11.4, false)
	assert_almost_eq(anchor, 10.0, 0.0001, "mid-jump: still the grounded height")
	anchor = SURGE.grounded_anchor(anchor, 12.0, true)
	assert_almost_eq(anchor, 12.0, 0.0001, "landed higher: follows")
	var eased: float = SURGE.smooth_floor(0.0, 2.0, 0.016, 8.0)
	assert_true(eased > 0.0 and eased < 0.5, "a 2 m slope step eases in (%.2f after one frame)" % eased)
	assert_almost_eq(SURGE.smooth_floor(0.0, 50.0, 0.016, 8.0), 50.0, 0.0001, "a teleport snaps")


## Review: the storm pin's off switch really restores the clock blend.
func test_pin_off_restores_the_clock_look() -> void:
	var surge := SURGE.new()
	var art := _art()
	surge.rules.config.presentation.storm_base.pin_time_of_day = false
	assert_true(is_same(surge.pinned_look_config(art), art), "pin off: WorldLook keeps art.json as loaded")
	var cycle := DAY_CYCLE.new(art)
	var noon: Dictionary = surge.base_look_at(art, cycle, 12.0)
	var midnight: Dictionary = surge.base_look_at(art, cycle, 0.0)
	assert_ne((noon.sky_top as Color).to_html(false), (midnight.sky_top as Color).to_html(false), "the clock look is back")
	assert_true(float(midnight.night_scale) < 1.0, "night scaling applies again")
	surge.free()


# ------------------------------------------------ round 3 (blind judge 8)

## Judge 8: Building read brighter and greyer than Calm, so the tension read
## as falling. The sky (ceiling, horizon/fog and sky top) darkens and
## saturates strictly from Calm to Building to Break, by a visible step.
func test_sky_darkens_and_saturates_from_calm_to_break() -> void:
	var surge := SURGE.new()
	var base := _real_base(surge, 12.0)
	var rows := {}
	for phase: String in ["calm", "building", "break"]:
		rows[phase] = surge._final(surge._resolved(surge.presentation_for(phase)), base)
	for key: String in ["ceiling_colour", "sky_horizon", "sky_top"]:
		var calm: Color = rows.calm[key]
		var building: Color = rows.building[key]
		var brk: Color = rows["break"][key]
		assert_true(calm.get_luminance() > building.get_luminance() * 1.03 and building.get_luminance() > brk.get_luminance() * 1.03,
			"%s value falls Calm %.3f > Building %.3f > Break %.3f (>= 3%% steps)" % [key, calm.get_luminance(), building.get_luminance(), brk.get_luminance()])
		assert_true(calm.s + 0.03 <= building.s and building.s + 0.03 <= brk.s,
			"%s saturation rises Calm %.2f < Building %.2f < Break %.2f" % [key, calm.s, building.s, brk.s])
	surge.free()


## Judge 8: the aftermath was "a flat, blank lavender card". It stays the
## stillest ceiling but is a defined, high-contrast deck with lit rims and
## thin spots, in the deep purple.
func test_aftermath_deck_is_still_but_structured() -> void:
	var surge := SURGE.new()
	var calm: Dictionary = surge._resolved(surge.presentation_for("calm"))
	for phase: String in PHASES:
		var row: Dictionary = surge._resolved(surge.presentation_for(phase, true))
		assert_true(float(row.ceiling_contrast) >= 0.55, "%s aftermath deck contrast %.2f (>= 0.55)" % [phase, float(row.ceiling_contrast)])
		assert_true(float(row.ceiling_definition) >= 0.5, "%s aftermath cloud body is defined" % phase)
		assert_true(float(row.ceiling_rim) >= 0.2 and float(row.ceiling_thin_glow) > 0.0, "%s aftermath deck has lit rims and thin spots" % phase)
		assert_true(float(row.ceiling_speed) <= float(calm.ceiling_speed) * 0.5, "%s aftermath still almost still" % phase)
	for phase: String in PHASES:
		assert_almost_eq(float(surge._resolved(surge.presentation_for(phase)).ceiling_rim), 0.0, 0.0001, "%s storm deck has no aftermath rims" % phase)
	surge.free()


## Judge 8 swapped Calm and Fading twice: Fading gets its own signature
## carried over from Break. Steam and afterglow exist only in Fading, start
## strong and ease to zero across it; nothing else (the aftermath included)
## carries any.
func test_steam_and_afterglow_only_in_fading_and_ease_to_zero() -> void:
	var surge := SURGE.new()
	for phase: String in PHASES:
		for aftermath: bool in [false, true]:
			var row: Dictionary = surge._resolved(surge.presentation_for(phase, aftermath))
			if phase == "fading" and not aftermath:
				continue
			for progress: float in [0.0, 0.5, 1.0]:
				var shown := SURGE.ramped(row, row.ramp, progress)
				assert_almost_eq(float(shown.steam), 0.0, 0.0001, "%s%s has no steam" % ["aftermath " if aftermath else "", phase])
				assert_almost_eq(float(shown.afterglow), 0.0, 0.0001, "%s%s has no afterglow" % ["aftermath " if aftermath else "", phase])
	var fading: Dictionary = surge._resolved(surge.presentation_for("fading"))
	var last := INF
	for step in 11:
		var shown := SURGE.ramped(fading, fading.ramp, step / 10.0)
		assert_true(float(shown.steam) <= last + 0.0001, "steam never rises across Fading")
		last = float(shown.steam)
		if step == 0:
			assert_true(float(shown.steam) >= 0.9 and float(shown.afterglow) >= 0.9, "Fading opens with full steam and afterglow")
	var end := SURGE.ramped(fading, fading.ramp, 1.0)
	assert_almost_eq(float(end.steam), 0.0, 0.0001, "steam eased to zero by Fading's end")
	assert_almost_eq(float(end.afterglow), 0.0, 0.0001, "afterglow decayed by Fading's end")
	# Production path: the steam emitter follows the phase and its progress.
	surge._build_steam()
	var steam: GPUParticles3D = surge._steam
	assert_true(steam != null, "the steam emitter is built from presentation.steam")
	surge.phase = "fading"
	surge.set_phase_progress(0.05)
	surge.settle_presentation()
	surge.call("_advance_presentation", 0.016)
	assert_true(steam.visible and steam.emitting and steam.amount_ratio > 0.8, "early Fading steams (%.2f)" % steam.amount_ratio)
	surge.set_phase_progress(0.6)
	surge.call("_advance_presentation", 0.016)
	assert_true(steam.amount_ratio < 0.6 and steam.amount_ratio > 0.0, "mid Fading steam is thinning (%.2f)" % steam.amount_ratio)
	surge.set_phase_progress(1.0)
	surge.call("_advance_presentation", 0.016)
	assert_false(steam.visible, "no steam at Fading's end")
	for phase: String in ["calm", "building", "break"]:
		surge.phase = phase
		surge.set_phase_progress(0.05)
		surge.settle_presentation()
		surge.call("_advance_presentation", 0.016)
		assert_false(steam.visible, "%s shows no steam" % phase)
	surge.free()


## Fading carries Break's slant and heavier rain over at its start and
## straightens and thins them; Calm is straight-down light rain at about
## half of Fading's opening count.
func test_fading_rain_carries_break_slant_then_straightens() -> void:
	var surge := SURGE.new()
	var brk: Dictionary = surge._resolved(surge.presentation_for("break"))
	var calm: Dictionary = surge._resolved(surge.presentation_for("calm"))
	var fading: Dictionary = surge._resolved(surge.presentation_for("fading"))
	var start := SURGE.ramped(fading, fading.ramp, 0.0)
	var end := SURGE.ramped(fading, fading.ramp, 1.0)
	assert_true(float(start.wind) >= float(brk.wind) * 0.9, "Fading opens with Break's slant")
	assert_true(float(end.wind) <= 0.25, "Fading's rain straightens (%.2f)" % float(end.wind))
	assert_true(float(calm.wind) <= 0.05, "Calm's rain falls straight down")
	var ratio := float(calm.rain_amount) / float(start.rain_amount)
	assert_true(ratio >= 0.4 and ratio <= 0.6, "Calm rains about half of Fading's opening (%.2f)" % ratio)
	# Production path: the emitter's lean follows the ramp.
	surge._rain = surge._build_rain()
	surge._style_rain()
	var process := surge._rain.process_material as ParticleProcessMaterial
	surge.phase = "fading"
	surge.set_phase_progress(0.0)
	surge.settle_presentation()
	var early := Vector2(process.direction.x, process.direction.z).length()
	surge.set_phase_progress(1.0)
	surge._ramp_left = 0.0
	surge.call("_advance_presentation", 0.016)
	var late := Vector2(process.direction.x, process.direction.z).length()
	assert_true(late < early * 0.3, "the live rain straightens across Fading (%.3f -> %.3f)" % [early, late])
	assert_almost_eq(surge._rain.amount_ratio, float(end.rain_amount), 0.01, "and thins")
	surge._rain.free()
	surge.free()


## Judge 8: Break's rain was "sparse thin streaks". Break draws a denser near
## sheet, the far layer and a distant curtain beyond it, within the lens rule
## (test_slanted_rain_never_crosses_the_lens) and a stated particle budget.
func test_break_rain_has_a_near_sheet_and_a_distant_curtain() -> void:
	var cfg: Dictionary = _config().presentation.rain
	var near := int(cfg.max_drops)
	var far := int(cfg.far_layer.max_drops)
	var curtain := int(cfg.curtain_layer.max_drops)
	assert_true(near >= 1500, "near sheet %d drops at Break (was 1100)" % near)
	assert_true(near + far + curtain >= 3800 and near + far + curtain <= 4500, "Break total %d within the 4500 budget" % (near + far + curtain))
	assert_true(float(cfg.curtain_layer.inner_radius_m) > float(cfg.far_layer.outer_radius_m), "the curtain is beyond the far layer")
	var surge := SURGE.new()
	surge._rain = surge._build_rain()
	surge._style_rain()
	var layer: GPUParticles3D = surge._rain_curtain
	assert_true(layer != null and layer.get_parent() == surge._rain, "the curtain rides with the rain")
	assert_eq(layer.amount, curtain)
	surge.call("_update_rain", surge._resolved(surge.presentation_for("calm")))
	assert_almost_eq(layer.amount_ratio, float(surge.presentation_for("calm").rain_amount), 0.001, "the curtain scales with the phase")
	surge._rain.free()
	surge.free()


## Runs a settled phase for `seconds` at 60 fps with seeded generators and
## real strikes every 4-8 s; returns {onsets: [[t, kind]], visible: fraction
## of 1 s windows with lightning on screen, cloud_peak, bolt_peak}.
func _run_sky(surge: Node, phase: String, aftermath: bool, seconds: float) -> Dictionary:
	surge.phase = phase
	surge._aftermath = aftermath
	surge.settle_presentation()
	surge._sky_rng.seed = 8
	surge._flash_rng.seed = 9
	surge.sky_log.clear()
	var strike_rng := RandomNumberGenerator.new()
	strike_rng.seed = 10
	var next_strike := strike_rng.randf_range(4.0, 8.0)
	var dt := 1.0 / 60.0
	var t := 0.0
	var windows := 0
	var lit_windows := 0
	var window_lit := false
	var cloud_peak := 0.0
	var bolt_peak := 0.0
	while t < seconds:
		surge.call("_advance_flash", dt)
		t += dt
		if t >= next_strike:
			next_strike += strike_rng.randf_range(4.0, 8.0)
			surge.flash(surge.sky_flash_for_strike(Vector3.ZERO))
		cloud_peak = maxf(cloud_peak, surge.cloud_flash_level())
		bolt_peak = maxf(bolt_peak, surge.bolt_level())
		window_lit = window_lit or surge.sky_lightning_visible()
		if floori(t) != floori(t - dt):
			windows += 1
			lit_windows += 1 if window_lit else 0
			window_lit = false
	return {"onsets": surge.sky_log.duplicate(), "visible": float(lit_windows) / maxf(1.0, windows),
		"cloud_peak": cloud_peak, "bolt_peak": bolt_peak}


static func _max_in_any_second(onsets: Array) -> int:
	var worst := 0
	for i in onsets.size():
		var count := 0
		for j in range(i, onsets.size()):
			if float(onsets[j][0]) - float(onsets[i][0]) < 1.0:
				count += 1
		worst = maxi(worst, count)
	return worst


## Judge 8: Break needs real lightning a still or a strip can catch. Most
## 1 s windows show some (cloud flash, bolt or scene flash), bolts are
## frequent, and UX 8's photosensitivity limit holds: no second ever holds
## more than 3 flash onsets, real strikes included; the decorative events
## alone stay within the configured cap less the strike reserve.
func test_break_sky_lightning_cadence_and_photosensitivity() -> void:
	MOTION_PREFS.set_reduced_motion(false)
	var cfg: Dictionary = _config().presentation.get("sky_lightning", {})
	assert_false(cfg.is_empty(), "Break's sky lightning is configured")
	assert_true(int(cfg.get("max_flashes_per_second", 3)) <= 3, "configured cap within UX 8's 3 per second")
	var surge := SURGE.new()
	var run := _run_sky(surge, "break", false, 600.0)
	var onsets: Array = run.onsets
	assert_true(_max_in_any_second(onsets) <= 3, "at most 3 flash onsets in any second (worst %d)" % _max_in_any_second(onsets))
	var decorative := onsets.filter(func(o: Array) -> bool: return str(o[1]) != "scene")
	assert_true(_max_in_any_second(decorative) <= int(cfg.get("max_flashes_per_second", 3)) - int(cfg.get("strike_reserve", 1)),
		"decorative onsets leave room for a strike (worst %d)" % _max_in_any_second(decorative))
	var per_second := float(onsets.size()) / 600.0
	assert_true(per_second <= 2.0, "well below the limit in practice (%.2f onsets/s)" % per_second)
	assert_true(float(run.visible) >= 0.8, "lightning on screen in %.0f%% of 1 s windows (>= 80%%)" % (float(run.visible) * 100.0))
	var bolts := onsets.filter(func(o: Array) -> bool: return str(o[1]) == "bolt")
	assert_true(bolts.size() >= 100, "%d distant bolts in 10 min" % bolts.size())
	assert_true(float(run.cloud_peak) >= 0.35, "in-cloud flashes light the cloud (%.2f)" % float(run.cloud_peak))
	surge.free()


## UX 8 reduced motion: the in-cloud and scene flashes drop to the 0.15
## floor, flickers, restrikes and scene echoes are dropped, and the bolts
## stay visible (a bolt is not a flash).
func test_break_sky_lightning_reduced_motion() -> void:
	var scale := float(_config().presentation.flash.reduced_motion_scale)
	var cfg: Dictionary = _config().presentation.sky_lightning
	MOTION_PREFS.set_reduced_motion(true)
	var surge := SURGE.new()
	var run := _run_sky(surge, "break", false, 300.0)
	assert_true(float(run.cloud_peak) <= float(cfg.cloud_strength_max) * scale + 0.001, "cloud flash %.3f under reduced motion" % float(run.cloud_peak))
	assert_true(float(run.cloud_peak) > 0.0, "a faint cloud cue remains")
	assert_true(float(run.bolt_peak) >= 0.95, "bolts stay fully visible (%.2f)" % float(run.bolt_peak))
	var onsets: Array = run.onsets
	var bolts := onsets.filter(func(o: Array) -> bool: return str(o[1]) == "bolt")
	assert_true(bolts.size() >= 40, "%d bolts in 5 min under reduced motion" % bolts.size())
	var flickers := onsets.filter(func(o: Array) -> bool: return str(o[1]).ends_with("_flicker"))
	assert_eq(flickers.size(), 0, "no flickers or restrikes under reduced motion")
	assert_true(_max_in_any_second(onsets) <= 3)
	surge.free()


## The decorative lightning is Break's alone: no other phase, and no
## aftermath phase, shows any.
func test_only_break_shows_sky_lightning() -> void:
	MOTION_PREFS.set_reduced_motion(false)
	var surge := SURGE.new()
	for target: Array in [["calm", false], ["building", false], ["fading", false], ["break", true], ["calm", true]]:
		var run := _run_sky(surge, str(target[0]), bool(target[1]), 60.0)
		var decorative := (run.onsets as Array).filter(func(o: Array) -> bool: return str(o[1]) != "scene")
		assert_eq(decorative.size(), 0, "%s%s has no sky lightning" % ["aftermath " if bool(target[1]) else "", str(target[0])])
		assert_almost_eq(float(run.bolt_peak), 0.0, 0.0001)
	surge.free()

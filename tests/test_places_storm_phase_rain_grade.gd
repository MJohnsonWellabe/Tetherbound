extends "res://tests/test_case.gd"

## LANE-PLACES P1/P2 (11 Nov 2026). `storm_phase_1111` (Stormwood layered
## storm sky, held white-violet bolts, mist layers) and `rain_time_grade`
## (Cloudreach rain that follows the clock). Checked on enabled copies, so the
## rules hold whichever way each arm ships.

const RULES := preload("res://scripts/world/stormwood_surge_rules.gd")
const SURGE := preload("res://scripts/world/stormwood_surge.gd")
const FOG := preload("res://scripts/world/stormwood_fog_layers.gd")
const CR_WEATHER := preload("res://scripts/world/cloudreach_weather.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const DAY_CYCLE := preload("res://scripts/world/day_cycle.gd")


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_storm_phase_ships_on_with_its_judged_gain() -> void:
	var block: Dictionary = _json(RULES.PATH).presentation.storm_phase_1111
	assert_true(bool(block.enabled), "storm_phase_1111 ships ON (GPU G-places-stormlight, F41#2 +0.80)")
	assert_true(str(block.get("_why_on", "")).contains("G-places-stormlight"), "the judged verdict is recorded")
	var bodies: Dictionary = _json("res://data/config/stormwood_npcs.json").distinct_bodies_1111
	assert_true(bool(bodies.enabled) and str(bodies.get("_why_on", "")).contains("G-places-stormlight"),
		"distinct_bodies_1111 ships ON with its verdict (F41#8 +0.58)")
	var rain: Dictionary = _json("res://data/config/cloudreach_visual.json").rain_time_grade
	assert_true(bool(rain.enabled) and str(rain.get("_why_on", "")).contains("G-places-raintime"),
		"the Cloudreach rain time grade ships ON with its verdict (+0.70 on rain sets)")


func _surge_with(on: bool) -> Dictionary:
	var source := _json(RULES.PATH)
	source.presentation.storm_phase_1111.enabled = on
	return RULES.with_presentation_candidates(source)


func test_storm_phase_off_changes_nothing_and_is_presentation_only() -> void:
	var off := _surge_with(false)
	assert_false(off.presentation.get("fog_layers", {}).get("enabled", false), "no mist layers when off")
	assert_false(off.presentation.ceiling.get("layered", {}).get("enabled", false), "no layered sky when off")
	assert_false(off.presentation.sky_lightning.has("far"), "no far bolts when off")
	var on := _surge_with(true)
	for key: String in off:
		if key != "presentation":
			assert_eq(JSON.stringify(on[key]), JSON.stringify(off[key]), "%s is untouched by the storm phase arm" % key)
	assert_eq(str(_json(RULES.PATH).presentation.storm_phase_1111.scope), "client_presentation")


func test_storm_phase_on_orders_the_phases_and_never_lights_calm() -> void:
	var rows: Dictionary = _surge_with(true).presentation.phases
	assert_true(float(rows.calm.deck_dark) < float(rows.building.deck_dark)
		and float(rows.building.deck_dark) < float(rows["break"].deck_dark), "the deck darkens Calm < Building < Break")
	assert_eq(float(rows.calm.far_bolts), 0.0, "Calm has no lightning")
	# Owner, 12 Nov 2026: sky lightning stays the Break-only danger cue (F10), so
	# no phase carries far-horizon bolts; the judged arm had faint ones in Building.
	for phase: String in RULES.PHASES:
		assert_eq(float(rows[phase].far_bolts), 0.0, "%s carries no far bolts (owner: lightning is Break's cue)" % phase)
	assert_false(bool(rows.building.flashes), "Building takes no whole-sky flashes")
	for phase: String in RULES.PHASES:
		assert_true(float(rows[phase].horizon_glow) >= 0.5, "%s keeps a pale band under the deck (lift, don't darken)" % phase)
		assert_true(float(rows[phase].fog_layers) > 0.0, "%s has mist layers" % phase)
	var sky: Dictionary = _surge_with(true).presentation.sky_lightning
	assert_true(int(sky.max_flashes_per_second) <= 3, "the flash budget is unchanged")
	assert_true(bool(sky.hold_bolts_during_warning), "decorative bolts stay held during a ground warning")
	assert_true(float(sky.far.level) < 1.0 and float(sky.far.bolt_distance_min_m) > float(sky.bolt_distance_max_m),
		"far bolts are fainter and farther than Break's")


func test_no_phase_fires_far_bolts() -> void:
	# Owner, 12 Nov 2026: lightning stays Break's alone; Building fires nothing.
	var surge := SURGE.new()
	surge.rules = RULES.new(_surge_with(true))
	for phase: String in ["calm", "building", "fading"]:
		surge.sky_log.clear()
		surge.set("_to", surge._resolved(surge.presentation_for(phase)))
		surge.set("_blend", 1.0)
		for step in 200:
			surge.call("_advance_sky_lightning", 0.1)
		assert_eq(surge.sky_log.size(), 0, "%s fires no sky lightning" % phase)
	surge.free()


## Owner rule (12 Nov): lightning is Break-only. A bolt, cloud flash or sky
## flash alive when the phase leaves Break is out at once, on a cross-fade and
## on a settle (the GPU phase stills shot Fading right after Break).
func test_leaving_break_puts_out_live_lightning_at_once() -> void:
	for settle: bool in [true, false]:
		var surge := SURGE.new()
		surge.phase = "break"
		surge.set("_to", surge._resolved(surge.presentation_for("break")))
		surge.set("_blend", 1.0)
		surge.set("_bolt_levels", [1.0, 0.6] as Array[float])
		surge.set("_cloud_flash", 0.7)
		surge.set("_flash", 0.3)
		assert_true(surge.sky_lightning_visible(), "Break has live lightning")
		surge.phase = "fading"
		if settle:
			surge.settle_presentation()
		else:
			surge.call("_begin_transition")
		assert_false(surge.sky_lightning_visible(), "no lightning survives into Fading")
		assert_almost_eq(surge.bolt_level(), 0.0, 0.0001)
		assert_almost_eq(surge.flash_level(), 0.0, 0.0001)
		surge.free()
	var kept := SURGE.new()
	kept.phase = "break"
	kept.set("_bolt_levels", [1.0] as Array[float])
	kept.call("_begin_transition")
	assert_almost_eq(kept.bolt_level(), 1.0, 0.0001, "entering Break keeps its own bolts")
	kept.free()


func test_bolt_halo_adds_a_faint_wide_strip_only_when_asked() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var plain := SURGE.bolt_mesh(Vector3(0, 100, 0), Vector3.ZERO, Vector3.RIGHT, rng, {"bolt_segments": 8})
	rng.seed = 7
	var halo := SURGE.bolt_mesh(Vector3(0, 100, 0), Vector3.ZERO, Vector3.RIGHT, rng,
		{"bolt_segments": 8, "bolt_halo_width_mul": 5.0, "bolt_halo_alpha": 0.16})
	var plain_count := (plain.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var colours: PackedColorArray = halo.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	assert_eq(colours.size(), plain_count + 2 * 8 * 6, "two nested halo strips along the main channel")
	var top := 0.0
	for index in 2 * 8 * 6:
		top = maxf(top, colours[index].a)
	assert_true(top <= 0.161, "the halo is faint (alpha %.3f)" % top)


func test_mist_banks_are_deterministic_and_can_never_out_shine_the_horizon() -> void:
	var cfg: Dictionary = _surge_with(true).presentation.fog_layers
	var a := FOG.placements(Vector2i(3, -7), cfg)
	var b := FOG.placements(Vector2i(3, -7), cfg)
	assert_eq(JSON.stringify(a), JSON.stringify(b), "same cell, same banks")
	var ring := int(cfg.ring)
	assert_eq(a.size(), (ring * 2 + 1) * (ring * 2 + 1))
	var lit := a.filter(func(p: Dictionary) -> bool: return float(p.alpha) > 0.0).size()
	assert_true(lit > a.size() / 4 and lit < a.size(), "some cells carry a bank, some do not (%d of %d)" % [lit, a.size()])
	assert_true(float(cfg.near_fade_m[0]) >= 25.0, "no bank over the near ground")
	assert_true(float(cfg.max_alpha) <= 0.65, "one bank is never opaque (judged at 0.6)")
	for horizon: Color in [Color("#7a74a8"), Color("#ffffff"), Color("#d8d4f0")]:
		var bank := FOG.bank_colour(horizon, cfg)
		assert_true(bank.get_luminance() <= float(cfg.max_luminance) + 0.001,
			"bank luminance %.3f stays under the glare cap" % bank.get_luminance())
	var storm := FOG.bank_colour(Color("#7a74a8"), cfg)
	assert_true(storm.b >= storm.r, "the bank stays in the violet family, never warm or red")


func _graded(hour: float) -> Dictionary:
	var arm: Dictionary = (_json("res://data/config/cloudreach_visual.json").rain_time_grade as Dictionary).duplicate(true)
	var art := _json("res://data/config/art.json")
	var cycle: RefCounted = DAY_CYCLE.new(art)
	var preset := CR_WEATHER.realm_preset("rain", _json("res://data/config/weather.json").get("presets", {}).get("rain", {}), "cloudreach_cliffs")
	var now: Dictionary = WORLD_LOOK.blended_config_at(art, cycle, hour)
	var day_sky: Dictionary = WORLD_LOOK._merged_from(art, "sky", WORLD_LOOK._preset_over(art, "day"))
	return {"base": preset, "graded": CR_WEATHER.time_graded_preset(preset, now, day_sky, arm), "now": now}


func test_cloudreach_rain_stays_night_at_night_and_keeps_golden_light() -> void:
	var noon := _graded(12.0)
	var base_top := Color(str(noon.base.sky.top_colour))
	assert_true(absf(Color(str(noon.graded.sky.top_colour)).get_luminance() - base_top.get_luminance()) < 0.02,
		"day rain keeps the judged storm sky")
	var night := _graded(0.0)
	var night_top := Color(str(night.graded.sky.top_colour))
	assert_true(night_top.get_luminance() < base_top.get_luminance() * 0.5,
		"night rain sky %.3f is far darker than the day storm sky %.3f" % [night_top.get_luminance(), base_top.get_luminance()])
	assert_true(Color(str(night.graded.environment.fog_colour)).get_luminance()
		< Color(str(night.base.environment.fog_colour)).get_luminance() * 0.5, "night rain fog is dark too")
	var native_ambient: Variant = night.now.environment.ambient_colour
	var native_lum := (native_ambient as Color).get_luminance() if native_ambient is Color else Color(str(native_ambient)).get_luminance()
	assert_true(Color(str(night.graded.environment.ambient_colour)).get_luminance() <= native_lum + 0.01,
		"a storm never lights the night")
	var best := 0.0
	var best_sun := 0.0
	for hour: float in [5.5, 6.0, 6.5, 7.0, 17.0, 17.5, 18.0, 18.5, 19.0]:
		var golden := _graded(hour)
		var horizon := Color(str(golden.graded.sky.horizon_colour))
		if horizon.r - horizon.b > best:
			best = horizon.r - horizon.b
			best_sun = float(golden.graded.sun.energy_mult)
	assert_true(best > 0.03, "some golden or dawn hour keeps a warm horizon under the rain (r-b %.3f)" % best)
	assert_true(best_sun > float(noon.base.sun.energy_mult), "and more of the low sun than day rain")


## ground_wet_path_1112 round 2 (GPU G-places-wetpath): no rain darkening at
## night; the full amount by day; no wetness in clear weather.
func test_cloudreach_wet_ground_fades_out_at_night_and_needs_rain() -> void:
	var arm: Dictionary = _json("res://data/config/cloudreach_visual.json").ground_wet_path_1112
	var day := Color("#3b6f93")
	assert_almost_eq(CR_WEATHER.wet_day_scale(day, day, arm), 1.0, 0.001, "full by day")
	assert_almost_eq(CR_WEATHER.wet_day_scale(Color(day.r * 0.1, day.g * 0.1, day.b * 0.1), day, arm), 0.0, 0.001, "none at night")
	var clear := CR_WEATHER.ground_wet_path_value(arm, {}, {})
	assert_almost_eq(clear.x, 0.0, 0.001, "clear weather is dry")
	assert_true(clear.y > 0.0 and clear.z > 0.0, "the trail keeps its duller, frayed edge in clear weather")
	var rain := CR_WEATHER.ground_wet_path_value(arm, {"ground_wetness": 0.6}, {"ground_wetness": 1.0})
	assert_almost_eq(rain.x, 1.0, 0.001, "rain wets the ground")

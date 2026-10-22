extends "res://tests/test_case.gd"

## GPU-PASS forward-plus-grade (ralph/reports/GPU-PASS/forward-plus-grade on
## tb/gpu-pass): Forward+ renders the shared grade greyer and darker than
## Compatibility, so Medium/High scale fog, exposure and saturation by
## `graphics_presets.<preset>.forward_plus_grade`. The factors multiply each
## WorldLook write once; Compatibility writes exactly what it always did.

const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const MEADOWS_LOOK := preload("res://scripts/world/meadows_look.gd")
const TIDEWAKE_LOOK := preload("res://scripts/world/tidewake_world_look.gd")
const GRAPHICS_PREFS := preload("res://scripts/ui/graphics_prefs.gd")

const GRADE := {"fog_density_scale": 0.5, "exposure_scale": 0.80 / 0.60, "saturation_scale": 1.2}

var _roots: Array[Node] = []


func after_each() -> void:
	GRAPHICS_PREFS.set_grade_override_for_test(null)
	for root: Node in _roots:
		root.free()
	_roots.clear()
	super.after_each()


func _rig(script: GDScript, realm_look_path: String = "") -> Node:
	var root := Node.new()
	_roots.append(root)
	var holder := WorldEnvironment.new()
	holder.name = "WorldEnvironment"
	holder.environment = Environment.new()
	root.add_child(holder)
	var look: Node = script.new()
	look.name = "WorldLook"
	look.set("environment_path", NodePath("../WorldEnvironment"))
	look.set("realm_look_path", realm_look_path)
	root.add_child(look)
	look.set("_config", look.call("_load"))
	return look


func _env(look: Node) -> Environment:
	return (look.get_parent().get_node("WorldEnvironment") as WorldEnvironment).environment


func _cfg(fog: float, exposure: float = 0.6, adjust: bool = false) -> Dictionary:
	return {"fog_density": fog, "exposure": exposure, "adjustment_enabled": adjust,
		"adjustment_brightness": 1.05, "adjustment_contrast": 0.95, "adjustment_saturation": 0.9}


func _snapshot(env: Environment) -> Array:
	return [env.fog_density, env.tonemap_exposure, env.adjustment_enabled, env.adjustment_saturation,
		env.adjustment_brightness, env.adjustment_contrast]


func test_forward_plus_scales_the_written_values_once() -> void:
	GRAPHICS_PREFS.set_grade_override_for_test(GRADE)
	var look := _rig(WORLD_LOOK)
	look.call("_apply_environment", _cfg(0.00135), {})
	var env := _env(look)
	assert_almost_eq(env.fog_density, 0.00135 * 0.5, 0.0000001)
	assert_almost_eq(env.tonemap_exposure, 0.80, 0.0001, "exposure relative: 0.60 x 0.80/0.60")
	assert_true(env.adjustment_enabled, "saturation needs the adjustment block")
	# The write left adjustment off, so Low shows none of 1.05/0.95/0.9: the
	# block switched on for saturation starts from neutral, not from them.
	assert_almost_eq(env.adjustment_saturation, 1.2, 0.0001)
	assert_almost_eq(env.adjustment_brightness, 1.0, 0.0001, "hidden brightness never appears")
	assert_almost_eq(env.adjustment_contrast, 1.0, 0.0001, "hidden contrast never appears")
	assert_eq(env.adjustment_color_correction, null, "hidden LUT never appears")


func test_an_enabled_adjustment_keeps_its_written_grade() -> void:
	GRAPHICS_PREFS.set_grade_override_for_test(GRADE)
	var look := _rig(WORLD_LOOK)
	look.call("_apply_environment", _cfg(0.001, 0.6, true), {})
	var env := _env(look)
	assert_true(env.adjustment_enabled)
	assert_almost_eq(env.adjustment_saturation, 0.9 * 1.2, 0.0001)
	assert_almost_eq(env.adjustment_brightness, 1.05, 0.0001, "brightness stays as written")
	assert_almost_eq(env.adjustment_contrast, 0.95, 0.0001, "contrast stays as written")


func test_reapply_and_clock_changes_do_not_compound() -> void:
	GRAPHICS_PREFS.set_grade_override_for_test(GRADE)
	var look := _rig(WORLD_LOOK)
	for i in 5:
		look.call("_apply_environment", _cfg(0.001), {})
	var env := _env(look)
	assert_almost_eq(env.fog_density, 0.0005, 0.0000001, "five re-applies still scale once")
	assert_almost_eq(env.tonemap_exposure, 0.80, 0.0001)
	assert_almost_eq(env.adjustment_saturation, 1.2, 0.0001)
	# The real clock paths, repeatedly and at different hours.
	look.call("apply_time", "day")
	var day := _snapshot(env)
	look.call("apply_time", "night")
	look.call("apply_time", "day")
	look.call("apply_time", "day")
	assert_eq(_snapshot(env), day, "day after night and repeats is the same day")
	var cycle: RefCounted = look.get("_cycle")
	if cycle == null:
		cycle = preload("res://scripts/world/day_cycle.gd").new(look.get("_config"))
		look.set("_cycle", cycle)
	look.call("_apply_blended", 13.0)
	var noon := _snapshot(env)
	look.call("_apply_blended", 21.5)
	look.call("_apply_blended", 13.0)
	look.call("_apply_blended", 13.0)
	assert_eq(_snapshot(env), noon, "blended clock re-applies never compound")


func test_compatibility_path_is_untouched() -> void:
	GRAPHICS_PREFS.set_grade_override_for_test({})
	var look := _rig(WORLD_LOOK)
	look.call("_apply_environment", _cfg(0.00135), {})
	var env := _env(look)
	assert_almost_eq(env.fog_density, 0.00135, 0.0000001)
	assert_almost_eq(env.tonemap_exposure, 0.6, 0.0001)
	assert_false(env.adjustment_enabled, "Compatibility never turns adjustment on")
	assert_almost_eq(env.adjustment_saturation, 0.9, 0.0001)
	# Headless runs the non-Forward+ renderer: the live lookup must be empty.
	GRAPHICS_PREFS.set_grade_override_for_test(null)
	assert_false(GRAPHICS_PREFS.forward_plus(), "headless test renderer is not Forward+")
	assert_eq(GRAPHICS_PREFS.renderer_grade(), {}, "no factors unless Forward+ is running")


func test_identity_saturation_leaves_adjustment_off() -> void:
	GRAPHICS_PREFS.set_grade_override_for_test({"fog_density_scale": 0.5, "exposure_scale": 1.0, "saturation_scale": 1.0})
	var look := _rig(WORLD_LOOK)
	look.call("_apply_environment", _cfg(0.001), {})
	assert_false(_env(look).adjustment_enabled)
	assert_almost_eq(_env(look).adjustment_saturation, 0.9, 0.0001)


func test_every_biome_write_gets_the_factors() -> void:
	# Each realm's own look class and config, at its own fog density.
	var biomes := {
		"meadows": [MEADOWS_LOOK, "res://data/config/meadows_look.json", 0.001],
		"stormwood": [WORLD_LOOK, "", 0.00135],
		"tidewake": [TIDEWAKE_LOOK, "", 0.00055],
		"cloudreach": [WORLD_LOOK, "", 0.0009],
	}
	for biome: String in biomes:
		var spec: Array = biomes[biome]
		var expected := {}
		for graded: bool in [false, true]:
			GRAPHICS_PREFS.set_grade_override_for_test(GRADE if graded else {})
			var look := _rig(spec[0], spec[1])
			var config: Dictionary = look.get("_config")
			(config["environment"] as Dictionary)["fog_density"] = spec[2]
			look.call("apply_time", "day")
			look.call("apply_time", "day")
			var env := _env(look)
			if not graded:
				expected = {"fog": env.fog_density, "exposure": env.tonemap_exposure,
					"saturation": env.adjustment_saturation if env.adjustment_enabled else 1.0}
				continue
			assert_almost_eq(env.fog_density, float(expected.fog) * 0.5, 0.0000001, biome + " fog")
			assert_almost_eq(env.tonemap_exposure, float(expected.exposure) * 0.80 / 0.60, 0.0001, biome + " exposure")
			assert_almost_eq(env.adjustment_saturation, float(expected.saturation) * 1.2, 0.0001, biome + " saturation")
			assert_true(env.adjustment_enabled, biome + " adjustment on for saturation")


func test_config_declares_forward_plus_presets_only() -> void:
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	var presets: Dictionary = art["graphics_presets"]
	assert_false((presets["Low"] as Dictionary).has("forward_plus_grade"), "Low ships its look unchanged")
	for name: String in ["Medium", "High"]:
		assert_eq(str(presets[name]["renderer"]), "forward_plus")
		var grade: Dictionary = GRAPHICS_PREFS.validated_grade(presets[name].get("forward_plus_grade"))
		assert_almost_eq(float(grade.get("fog_density_scale", 0.0)), 0.5, 0.0001, name)
		assert_almost_eq(float(grade.get("exposure_scale", 0.0)), 0.80 / 0.60, 0.0001, name)
		assert_almost_eq(float(grade.get("saturation_scale", 0.0)), 1.2, 0.0001, name)


func test_grade_keys_are_validated_and_tunable() -> void:
	var tuned: Dictionary = GRAPHICS_PREFS.validated_grade({"fog_density_scale": 0.3, "exposure_scale": 1, "saturation_scale": 1.5})
	assert_almost_eq(float(tuned.fog_density_scale), 0.3, 0.0001)
	assert_almost_eq(float(tuned.exposure_scale), 1.0, 0.0001, "ints accepted")
	assert_almost_eq(float(tuned.saturation_scale), 1.5, 0.0001)
	var bad: Dictionary = GRAPHICS_PREFS.validated_grade({"fog_density_scale": -1.0, "exposure_scale": "x",
		"saturation_scale": 99.0})
	assert_eq(bad, {}, "invalid factors fall back to identity, which is no grade")
	var partial: Dictionary = GRAPHICS_PREFS.validated_grade({"fog_density_scale": 0.5, "exposure_scale": INF})
	assert_almost_eq(float(partial.fog_density_scale), 0.5, 0.0001)
	assert_almost_eq(float(partial.exposure_scale), 1.0, 0.0001)
	assert_almost_eq(float(partial.saturation_scale), 1.0, 0.0001, "missing key is identity")
	assert_eq(GRAPHICS_PREFS.validated_grade(null), {})
	assert_eq(GRAPHICS_PREFS.validated_grade({}), {})


func test_weather_layers_before_the_grade() -> void:
	# Weather adds fog and multiplies saturation in cfg; the grade then scales
	# that weathered write once, and a weather re-roll never compounds it.
	var weather := {"environment": {"fog_density_add": 0.0004, "adjustment_saturation_mult": 0.8}}
	var expected := {}
	for graded: bool in [false, true]:
		GRAPHICS_PREFS.set_grade_override_for_test(GRADE if graded else {})
		var look := _rig(WORLD_LOOK)
		(look.get("_config")["environment"] as Dictionary)["fog_density"] = 0.00135
		look.set("_weather", weather)
		look.call("apply_time", "day")
		var env := _env(look)
		if not graded:
			assert_true(env.adjustment_enabled, "weather saturation turns the block on")
			expected = {"fog": env.fog_density, "exposure": env.tonemap_exposure,
				"saturation": env.adjustment_saturation, "brightness": env.adjustment_brightness}
			continue
		look.call("set_weather", weather)
		look.call("set_weather", weather)
		assert_almost_eq(env.fog_density, float(expected.fog) * 0.5, 0.0000001, "weathered fog scaled once")
		assert_almost_eq(env.tonemap_exposure, float(expected.exposure) * 0.80 / 0.60, 0.0001)
		assert_almost_eq(env.adjustment_saturation, float(expected.saturation) * 1.2, 0.0001)
		assert_almost_eq(env.adjustment_brightness, float(expected.brightness), 0.0001,
			"weather-enabled block keeps its written brightness")


func test_cloudreach_realm_fog_scale_layers_on_the_grade() -> void:
	GRAPHICS_PREFS.set_grade_override_for_test(GRADE)
	var look := _rig(WORLD_LOOK)
	look.call("_apply_environment", _cfg(0.0009), {})
	var env := _env(look)
	var realm: Node3D = preload("res://scripts/world/cloudreach_look.gd").new()
	realm.set("_fog_env", env)
	realm.set("_fog_density_scale", 0.55)
	realm.call("_process", 0.0)
	realm.call("_process", 0.0)
	assert_almost_eq(env.fog_density, 0.0009 * 0.5 * 0.55, 0.0000001, "realm x grade, frozen frames no-op")
	# The clock moves the base; each WorldLook rewrite is graded once and the
	# realm scale applies once on top. (An IDENTICAL rewrite is skipped by
	# cloudreach_look's own cache on every renderer; pre-existing, not graded.)
	for base: float in [0.001, 0.0011, 0.001]:
		look.call("_apply_environment", _cfg(base), {})
		realm.call("_process", 0.0)
		realm.call("_process", 0.0)
		assert_almost_eq(env.fog_density, base * 0.5 * 0.55, 0.0000001, "rewrite %.4f never compounds" % base)
	realm.free()

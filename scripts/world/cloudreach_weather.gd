extends "res://scripts/world/world_weather.gd"

## The production weather controller, with Cloudreach's base atmosphere delta
## retained underneath the named shared presets. No capture-only weather state.
var _realm_atmosphere_delta: Dictionary = {}
const TIME_GRADE_LOOK := preload("res://scripts/world/world_look.gd")
const TIME_GRADE_SKY_KEYS := ["top_colour", "horizon_colour", "ground_horizon_colour", "cloud_lit", "cloud_shade", "cloud_base"]
var _time_grade: Dictionary = {}
var _time_grade_left := 0.0
var _streak_colour := Color(0, 0, 0, 0)


func _ready() -> void:
	# A server's simulation-only Cloudreach shell has no local weather visuals.
	if bool(get_parent().get("simulation_only")):
		set_process(false)
		return
	super._ready()
	_apply_rain_streak_arm()
	_load_time_grade()


## F40#19 rain (NEAR6-CR, flag-off): `rain_streaks` in cloudreach_visual.json
## makes Cloudreach rain read as falling water (denser, longer, brighter
## streaks) instead of only a desaturated grade. Meadows rain is unchanged.
func _apply_rain_streak_arm() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	if not raw is Dictionary or _rain == null:
		return
	var arm: Dictionary = (raw as Dictionary).get("rain_streaks", {})
	if arm.get("enabled") != true:
		return
	_rain.amount = int(arm.get("amount", RAIN_AMOUNT))
	var streak := _rain.draw_pass_1 as BoxMesh
	var size: Array = arm.get("streak_size", [])
	if streak != null and size.size() == 3:
		streak.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
	var colour := Color(str(arm.get("colour", RAIN_COLOUR.to_html())))
	if streak != null and streak.material is StandardMaterial3D:
		(streak.material as StandardMaterial3D).albedo_color = colour
	if _rain.process_material is ParticleProcessMaterial:
		(_rain.process_material as ParticleProcessMaterial).color = colour


func configure_realm_atmosphere(delta: Dictionary) -> void:
	_realm_atmosphere_delta = delta.duplicate(true)
	_apply_realm_weather()


func set_weather(name: String) -> void:
	# Retain production named state, normal timer bookkeeping and rain emitter.
	super.set_weather(name)
	_apply_realm_weather()


func _apply_realm_weather() -> void:
	var look: Node = get_node_or_null(look_path)
	if look != null and look.has_method("set_weather"):
		var preset := realm_preset(weather(), _presets.get(weather(), {}), _scene_id())
		look.call("set_weather", combined_delta(_realm_atmosphere_delta, _time_graded(preset, look)))
	_apply_ground_wet_path()
	# Seat the mist ceiling now too, not only from _process: a pinned capture
	# freezes this node's processing (phase2_capture_locations.gd), and the
	# GPU F40#19 frames then drew no mist at all (ceiling never left its
	# "no ground reading" value).
	_mist_floor_y = NAN
	_follow_mist_floor()


## The world scene this controller runs under (cloudreach_cliffs, or
## water_archipelago, which reuses this script), for arms scoped by `scenes`.
func _scene_id() -> String:
	var parent := get_parent()
	return parent.scene_file_path.get_file().get_basename() if parent != null else ""


var _mist_floor_y := NAN


func _process(delta: float) -> void:
	super._process(delta)
	_follow_mist_floor()
	# The time grade follows the clock: re-layer the weather now and then.
	if _time_grade_applies():
		_time_grade_left -= delta
		if _time_grade_left <= 0.0:
			_apply_realm_weather()


## P2 rain (LANE-PLACES, `rain_time_grade` in cloudreach_visual.json, OFF
## until judged). GPU judges on the F40#0 matrix (half its frames are rain):
## "night rain reads as day", "golden-hour rain loses the golden light",
## "thick white overlay streaks". Cause: a weather preset's sky, cloud and fog
## colours are absolute, so the rain storm's day-slate sky replaces the night
## and golden skies outright, and the streaks are one bright near-opaque
## colour at every hour. On, for the listed weathers:
## - the preset's sky, cloud and fog colours are scaled by how dark the clock's
##   own sky is against day (hue kept; never below `night_floor`), and the
##   storm ambient is capped at the clock's own ambient value, so a storm
##   never lights the night;
## - where the clock's horizon is warm (golden hour, dawn), the storm horizon,
##   lit cloud and fog take `warm_mix` of that warm colour and the sun and
##   saturation cuts ease toward `warm_sun_mult` / `warm_saturation_mult`, so a
##   band of golden light stays under the slate deck;
## - streaks become finer and translucent (`streak_*`) and dim with the night.
## Device-local presentation; nothing else reads it.
func _load_time_grade() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	if not raw is Dictionary:
		return
	var arm: Variant = (raw as Dictionary).get("rain_time_grade", {})
	if arm is Dictionary and (arm as Dictionary).get("enabled") == true:
		_time_grade = arm
		_style_time_grade_streaks()


## `ground_wet_path_1112` (cloudreach_visual.json, OFF until judged; GPU
## judges at the realm gate: "rain has no wet darkening or sheen", "the orange
## path is too saturated and its edges are not blended into the grass"). One
## shader global (cloudreach_ground_1112) read by the Cloudreach turf, trail
## and worn-ground shaders: rain wetness from the weather preset's
## ground_wetness, and a duller, frayed, wider-feathered trail. Cloudreach
## scene only; all zero when off.
func _apply_ground_wet_path() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var arm: Dictionary = (raw as Dictionary).get("ground_wet_path_1112", {}) if raw is Dictionary else {}
	var value := Vector4.ZERO
	if arm.get("enabled") == true and _scene_id() in (arm.get("scenes", ["cloudreach_cliffs"]) as Array):
		value = ground_wet_path_value(arm, _presets.get(weather(), {}), realm_preset(weather(), _presets.get(weather(), {}), _scene_id()))
		value.x *= _wet_day_scale(arm)
	RenderingServer.global_shader_parameter_set(&"cloudreach_ground_1112", value)


## Round 2 (GPU G-places-wetpath: summit night rain -0.34, the wet trail read
## as "a black, char-like smear"): the rain darkening fades out with the
## clock's own sky value, so a night that is already dark takes none.
func _wet_day_scale(arm: Dictionary) -> float:
	var look: Node = get_node_or_null(look_path)
	if look == null:
		return 1.0
	var config: Variant = look.get("_config")
	var cycle: Variant = look.get("_cycle")
	if not config is Dictionary or (config as Dictionary).is_empty() or cycle == null:
		return 1.0
	var now: Dictionary = TIME_GRADE_LOOK.blended_config_at(config, cycle, float(look.call("hour")))
	var day_sky: Dictionary = TIME_GRADE_LOOK._merged_from(config, "sky", TIME_GRADE_LOOK._preset_over(config, "day"))
	return wet_day_scale(_grade_colour((now.get("sky", {}) as Dictionary).get("top_colour"), "#3b6f93"),
		_grade_colour(day_sky.get("top_colour"), "#3b6f93"), arm)


## 1 by day, 0 at night (pure; tested): the sky's value against day, eased
## between the arm's `wet_night_band`.
static func wet_day_scale(top_now: Color, top_day: Color, arm: Dictionary) -> float:
	var band: Array = arm.get("wet_night_band", [0.2, 0.6])
	var k := clampf(top_now.get_luminance() / maxf(0.001, top_day.get_luminance()), 0.0, 1.0)
	return smoothstep(float(band[0]), float(band[1]), k)


## The shader global for an enabled arm (pure; tested).
static func ground_wet_path_value(arm: Dictionary, shared_preset: Dictionary, realm: Dictionary) -> Vector4:
	var wetness := float(realm.get("ground_wetness", shared_preset.get("ground_wetness", 0.0)))
	return Vector4(clampf(wetness, 0.0, 1.0) * float(arm.get("rain_wet", 1.0)),
		clampf(float(arm.get("path_feather", 1.0)), 0.0, 1.0), clampf(float(arm.get("path_dull", 0.5)), 0.0, 1.0), 0.0)


func _time_grade_applies() -> bool:
	if _time_grade.is_empty() or not weather() in (_time_grade.get("weathers", ["rain"]) as Array):
		return false
	return not _time_grade.has("scenes") or _scene_id() in (_time_grade["scenes"] as Array)


func _style_time_grade_streaks() -> void:
	if _rain == null or not _time_grade.has("streak_colour"):
		return
	var streak := _rain.draw_pass_1 as BoxMesh
	var size: Array = _time_grade.get("streak_size", [])
	if streak != null and size.size() == 3:
		streak.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
	if _time_grade.has("streak_amount"):
		_rain.amount = int(_time_grade["streak_amount"])
	_streak_colour = Color(str(_time_grade["streak_colour"]))
	_tint_streaks(1.0)


func _tint_streaks(shade: float) -> void:
	if _rain == null or _streak_colour.a <= 0.0:
		return
	var colour := Color(_streak_colour.r * shade, _streak_colour.g * shade, _streak_colour.b * shade, _streak_colour.a)
	var streak := _rain.draw_pass_1 as BoxMesh
	if streak != null and streak.material is StandardMaterial3D:
		(streak.material as StandardMaterial3D).albedo_color = colour
	# The streak material multiplies its albedo by the particle colour, so the
	# particle colour stays white: the colour and alpha apply once.
	if _rain.process_material is ParticleProcessMaterial:
		(_rain.process_material as ParticleProcessMaterial).color = Color.WHITE


func _time_graded(preset: Dictionary, look: Node) -> Dictionary:
	if not _time_grade_applies():
		return preset
	_time_grade_left = float(_time_grade.get("reapply_seconds", 2.0))
	var config: Variant = look.get("_config")
	var cycle: Variant = look.get("_cycle")
	if not config is Dictionary or (config as Dictionary).is_empty() or cycle == null:
		return preset
	var now: Dictionary = TIME_GRADE_LOOK.blended_config_at(config, cycle, float(look.call("hour")))
	var day_sky: Dictionary = TIME_GRADE_LOOK._merged_from(config, "sky", TIME_GRADE_LOOK._preset_over(config, "day"))
	var graded := time_graded_preset(preset, now, day_sky, _time_grade)
	_tint_streaks(lerpf(float(_time_grade.get("streak_night_shade", 0.4)), 1.0, float(graded.get("_time_scale", 1.0))))
	graded.erase("_time_scale")
	return graded


static func _grade_colour(value: Variant, fallback: String) -> Color:
	if value is Color:
		return value
	return Color(str(value)) if value != null else Color(fallback)


## The graded preset for the clock's blended look `now` (pure; tested).
## `_time_scale` in the result is the night scale that was used (1 = day).
static func time_graded_preset(preset: Dictionary, now: Dictionary, day_sky: Dictionary, arm: Dictionary) -> Dictionary:
	var out := preset.duplicate(true)
	var sky_now: Dictionary = now.get("sky", {})
	var env_now: Dictionary = now.get("environment", {})
	var top_now := _grade_colour(sky_now.get("top_colour"), "#3b6f93")
	var top_day := _grade_colour(day_sky.get("top_colour"), "#3b6f93")
	var k := clampf(top_now.get_luminance() / maxf(0.001, top_day.get_luminance()), float(arm.get("night_floor", 0.1)), 1.0)
	var native_horizon := _grade_colour(sky_now.get("horizon_colour"), "#a6bccb")
	var warmth := clampf((native_horizon.r - native_horizon.b) / maxf(0.01, float(arm.get("warm_span", 0.25))), 0.0, 1.0)
	var warm_mix := float(arm.get("warm_mix", 0.5)) * warmth
	var sky: Dictionary = (out.get("sky", {}) as Dictionary).duplicate(true)
	for key: String in TIME_GRADE_SKY_KEYS:
		if not sky.has(key):
			continue
		var c := Color(str(sky[key]))
		c = Color(c.r * k, c.g * k, c.b * k)
		if key in ["horizon_colour", "ground_horizon_colour", "cloud_lit"]:
			c = c.lerp(native_horizon, warm_mix)
		sky[key] = "#" + c.to_html(false)
	out["sky"] = sky
	var env: Dictionary = (out.get("environment", {}) as Dictionary).duplicate(true)
	if env.has("fog_colour"):
		var fog := Color(str(env["fog_colour"]))
		fog = Color(fog.r * k, fog.g * k, fog.b * k).lerp(native_horizon, warm_mix)
		env["fog_colour"] = "#" + fog.to_html(false)
	if env.has("ambient_colour"):
		var storm := Color(str(env["ambient_colour"]))
		var native := _grade_colour(env_now.get("ambient_colour"), "#9db3c6")
		var dim := minf(1.0, native.get_luminance() / maxf(0.001, storm.get_luminance()))
		env["ambient_colour"] = "#" + Color(storm.r * dim, storm.g * dim, storm.b * dim).lerp(native, warm_mix).to_html(false)
	if env.has("adjustment_saturation_mult"):
		env["adjustment_saturation_mult"] = lerpf(float(env["adjustment_saturation_mult"]), float(arm.get("warm_saturation_mult", 1.0)), warmth)
	out["environment"] = env
	var sun: Dictionary = (out.get("sun", {}) as Dictionary).duplicate(true)
	if sun.has("energy_mult"):
		sun["energy_mult"] = lerpf(float(sun["energy_mult"]), float(arm.get("warm_sun_mult", 0.8)), warmth)
	out["sun"] = sun
	out["_time_scale"] = k
	return out


## F40#19 rain mist: a weather `environment.fog_height_above_ground_m` keeps
## the height-fog ceiling that far above the ground under the local player,
## eased so cliffs and steps do not pop it. Uses the terrain under the player,
## not the player's own height, so flying never lifts the mist into the sky.
func _follow_mist_floor() -> void:
	var look: Node = get_node_or_null(look_path)
	if look == null or not look.has_method("set_weather_fog_floor") \
			or not bool(look.call("weather_fog_follows_ground")):
		return
	var player := get_node_or_null(player_path) as Node3D
	var world := get_parent()
	if player == null or world == null or not world.has_method("ground_height_at"):
		return
	var ground := float(world.call("ground_height_at", player.global_position.x, player.global_position.z))
	if not is_finite(ground):
		return
	_mist_floor_y = ground if not is_finite(_mist_floor_y) else lerpf(_mist_floor_y, ground, MIST_FLOOR_EASE)
	look.call("set_weather_fog_floor", _mist_floor_y)


const MIST_FLOOR_EASE := 0.05


## F40#19 (NEAR6-CR): `cloudreach_visual.json` `weather_arms.<name>` (each OFF
## until judged) merge Cloudreach-only keys over a shared weather preset, so the
## realm's rain can carry its own mood without touching the Meadows presets.
static func realm_preset(name: String, preset: Dictionary, scene_id: String = "") -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	if not raw is Dictionary:
		return preset
	var result := preset.duplicate(true)
	var arms: Dictionary = (raw as Dictionary).get("weather_arms", {})
	for arm_name: String in arms:
		var arm: Variant = arms[arm_name]
		if not (arm is Dictionary) or (arm as Dictionary).get("enabled") != true:
			continue
		# An arm may name the world scenes it applies to (this script also runs
		# Tidewake's water_archipelago); without `scenes` it applies everywhere.
		if (arm as Dictionary).has("scenes") and not scene_id in ((arm as Dictionary)["scenes"] as Array):
			continue
		var over: Variant = ((arm as Dictionary).get("presets", {}) as Dictionary).get(name)
		if not (over is Dictionary):
			continue
		for block: String in over:
			if block.begins_with("_"):
				continue
			var value: Variant = (over as Dictionary)[block]
			if value is Dictionary and result.get(block) is Dictionary:
				var merged: Dictionary = (result[block] as Dictionary).duplicate(true)
				for key: String in value:
					if not key.begins_with("_"):
						merged[key] = (value as Dictionary)[key]
				result[block] = merged
			else:
				result[block] = value
	return result


static func combined_delta(realm_delta: Dictionary, preset: Dictionary) -> Dictionary:
	var result := preset.duplicate(true)
	var base_environment: Dictionary = realm_delta.get("environment", {})
	var environment: Dictionary = result.get("environment", {}).duplicate(true)
	# fold_atmosphere_into_base retains only these two delta operators; all
	# realm colours already live in WorldLook's time-aware base configuration.
	if base_environment.has("fog_density_add"):
		environment["fog_density_add"] = float(base_environment["fog_density_add"]) \
			+ float(environment.get("fog_density_add", 0.0))
	if base_environment.has("ambient_energy_mult"):
		environment["ambient_energy_mult"] = float(base_environment["ambient_energy_mult"]) \
			* float(environment.get("ambient_energy_mult", 1.0))
	if not environment.is_empty():
		result["environment"] = environment
	return result

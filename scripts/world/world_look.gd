extends Node

## Applies data/config/art.json to the scene's light and environment.
##
## These values existed in the config for a whole art pass and nothing read
## them. The scene kept the sun and environment it was authored with, so every
## "the lighting is too flat" fix was written into a file the game ignored — and
## the blind critic measured the result: the darkest one percent of an entire
## exploration frame was luminance 129, a mid-tone, where the references reach
## single digits.
##
## So the rule the rest of the project already follows applies here too: if a
## number can be argued about, it lives in data, and something must actually
## read it.
##
## M10 makes it CONTINUOUS. The four named hours in art.json are keyframes on a
## 24-hour curve rather than four separate presets, and `apply_moment()` takes a
## fractional hour and a weather and produces the look between them: energies,
## colours, fog and exposure interpolated, and the sky itself cross-faded in a
## sky shader. `scripts/world/sky_cycle.gd` owns the clock and the weather state
## machine and is the only thing that calls it in the running game. This file
## still owns every value: nothing else in the project touches a light.

const CONFIG_PATH := "res://data/config/art.json"

const DEFAULT_TIME := "day"
## The weather every path falls back to. Its entry in art.json is the identity —
## every multiplier 1 and every mix 0 — so "clear" and "no weather at all" are
## the same picture, and a misspelt weather id degrades to the hour alone.
const DEFAULT_WEATHER := "clear"

## How much a lightning flash lifts the sky and the fill light at strength 1.0.
##
## Additive, on top of whatever the hour and the storm had already decided,
## which is what makes one number work at noon and at midnight. Not tunable in
## data on purpose: `lightning.strength` in weather.json is the knob, and having
## two multipliers for one effect is how a value ends up being tuned in the
## wrong file (D18's whole subject).
const FLASH_SKY := 2.4
const FLASH_AMBIENT := 3.2

## Cross-fades two panoramas and lays a cloud dome over the result.
##
## A ShaderMaterial rather than PanoramaSkyMaterial because a day/night cycle
## needs the sky to MOVE between two states, and `PanoramaSkyMaterial` holds
## exactly one texture: with it, dawn arrives as a single-frame cut from black
## to amber. Verified to render under the Compatibility renderer the survey is
## forced onto (D06) before any of the look was tuned on top of it.
##
## The uv maths is copied from Godot's own `PanoramaSkyMaterial` — atan2(x, z)
## over 2pi, acos(y) over pi — so a keyframe naming one panorama at rotation 0
## renders bit-for-bit what `PanoramaSkyMaterial` rendered before this milestone.
## That is not a guess: `tools/preview_weather.gd` re-checks it against the
## built-in material and fails if the two ever drift apart. D18 is about
## precisely this — four art rounds tuned a texture that was not on screen —
## and the cheapest defence is to prove which input is being sampled.
const SKY_SHADER := """
shader_type sky;

uniform sampler2D sky_a : filter_linear, source_color, hint_default_black, repeat_enable;
uniform sampler2D sky_b : filter_linear, source_color, hint_default_black, repeat_enable;
uniform sampler2D sky_overcast : filter_linear, source_color, hint_default_black, repeat_enable;
uniform float rot_a = 0.0;
uniform float rot_b = 0.0;
uniform float rot_overcast = 0.0;
uniform float energy_a = 1.0;
uniform float energy_b = 1.0;
uniform float blend = 0.0;
uniform float overcast_blend = 0.0;
uniform float overcast_energy = 1.0;
uniform vec3 overcast_tint = vec3(1.0);
uniform float flash = 0.0;

void sky() {
	// NEGATED, and that sign is the whole of D18 in one character. Written the
	// obvious way round — atan(x, z) — the sky renders MIRRORED: the same
	// panorama, the same clouds, in the wrong half of the world, which is
	// completely invisible in a still frame of a sky nobody has memorised and
	// which would have put the moon on the opposite side from the moonlight.
	// The equivalence check in tools/preview_weather.gd measured it at mean
	// 0.118 against the built-in material and 0.015 with the sign corrected;
	// nothing else about the frame would have said so.
	float phi = -atan(EYEDIR.x, EYEDIR.z) * (1.0 / (2.0 * PI)) + 0.5;
	float theta = acos(clamp(EYEDIR.y, -1.0, 1.0)) * (1.0 / PI);
	vec3 a = texture(sky_a, vec2(phi + rot_a, theta)).rgb * energy_a;
	vec3 b = texture(sky_b, vec2(phi + rot_b, theta)).rgb * energy_b;
	vec3 cloud = texture(sky_overcast, vec2(phi + rot_overcast, theta)).rgb
		* overcast_energy * overcast_tint;
	COLOR = mix(mix(a, b, blend), cloud, overcast_blend) + vec3(flash);
}
"""

@export var sun_path: NodePath
@export var environment_path: NodePath

var _config: Dictionary = {}
var _time: String = DEFAULT_TIME
var _hour: float = 0.0
var _weather: String = DEFAULT_WEATHER

## Keyframes, sorted by clock hour: {"name", "hour", "sun", "sky", "environment"}
## with every block already merged over the base. Built once, because merging
## four dictionaries per frame for a value that cannot change at run time is
## work nobody asked for.
var _frames: Array[Dictionary] = []

## Somebody posed this deliberately — `apply_time()` — and the clock should keep
## its hands off until it is released. `tools/survey.gd` calls `apply_time()`
## five times to capture five named hours, and a SkyCycle ticking in the same
## scene would overwrite each pose in the frame after it was set.
var _manual: bool = false

var _sky_material: ShaderMaterial = null
## False when a panorama named in art.json is missing, in which case the old
## single-texture path runs and the sky snaps between hours instead of fading.
## A missing texture should degrade to a worse sky, not to a black void.
var _shader_sky: bool = false


func _ready() -> void:
	_config = _load()
	if _config.is_empty():
		push_warning("art.json missing or unreadable; the scene keeps its authored look")
		return
	_frames = _build_frames()
	# Not `apply_time()`: the boot pose must not latch the manual flag, or the
	# SkyCycle beside this node would never get to run at all.
	_apply_named(DEFAULT_TIME, false)


## Set the hour by NAME, and hold it there.
##
## The last survey shipped two frames named `01-spawn-outward` and
## `05-spawn-low-sun` whose skies were BIT-IDENTICAL — 46.8% of the whole frame
## pixel-for-pixel the same — because the only thing the low-sun frame changed
## was the DirectionalLight3D's pitch. The sun disc, the sky gradient, the
## horizon haze and the fog colour all stayed at noon. The key art board asks
## for "day and night create different moods", and a sky that does not
## participate in the time of day cannot deliver one.
##
## So the hour is a single value and sun, sky, fog and ambient are all derived
## from it. Anything that wants to change the light asks for a time rather than
## reaching for the light directly — which is the only way they cannot drift
## apart again.
##
## This also SUSPENDS the day/night cycle until `release()` is called, so a tool
## that poses a named hour gets the hour it asked for and keeps it.
func apply_time(name: String) -> void:
	_apply_named(name, true)


func _apply_named(name: String, manual: bool) -> void:
	if _config.is_empty():
		return
	var times: Dictionary = _config.get("times", {})
	if not times.has(name):
		if name != DEFAULT_TIME:
			push_warning("no time-of-day called '%s' in art.json; using '%s'" % [name, DEFAULT_TIME])
		name = DEFAULT_TIME
	_time = name
	_manual = manual
	_weather = DEFAULT_WEATHER
	_hour = _hour_of(name)
	_apply(_hour, _weather_knobs(DEFAULT_WEATHER, DEFAULT_WEATHER, 0.0), 0.0)


## The look at a fractional hour, under a weather that may itself be part way
## into becoming another one.
##
## `blend` is 0 at `from_weather` and 1 at `to_weather`; passing the same id
## twice is a settled weather. `flash` is a 0..1 lightning scalar, additive over
## everything else.
func apply_moment(
	hour: float, from_weather: String = DEFAULT_WEATHER,
	to_weather: String = DEFAULT_WEATHER, blend: float = 0.0, flash: float = 0.0
) -> void:
	if _config.is_empty():
		return
	_manual = false
	_hour = fposmod(hour, 24.0)
	_weather = to_weather if blend >= 0.5 else from_weather
	_time = nearest_time(_hour)
	_apply(_hour, _weather_knobs(from_weather, to_weather, blend), clampf(flash, 0.0, 1.0))


## Hand the light back to the clock after `apply_time()` pinned it.
func release() -> void:
	_manual = false


func is_manually_posed() -> bool:
	return _manual


func time_of_day() -> String:
	return _time


func hour() -> float:
	return _hour


func weather() -> String:
	return _weather


func times_available() -> Array:
	var found: Array = []
	for key: String in _config.get("times", {}).keys():
		if not key.begins_with("_"):
			found.append(key)
	return found


func weathers_available() -> Array:
	var found: Array = []
	for key: String in _config.get("weather", {}).keys():
		if not key.begins_with("_"):
			found.append(key)
	return found


## Clock hour of each named time, for anything that wants to jump to one.
func time_hours() -> Dictionary:
	var found: Dictionary = {}
	for frame in _frames:
		found[str(frame["name"])] = float(frame["hour"])
	return found


## Which named hour this moment is closest to. Only a label — the look is the
## interpolation, not the nearest keyframe — but it is what a HUD or a log line
## should say, and it is how `apply_moment()` keeps `time_of_day()` meaningful.
func nearest_time(at: float) -> String:
	if _frames.is_empty():
		return DEFAULT_TIME
	var best := str(_frames[0]["name"])
	var closest := INF
	for frame in _frames:
		var away: float = absf(fposmod(float(frame["hour"]) - at + 12.0, 24.0) - 12.0)
		if away < closest:
			closest = away
			best = str(frame["name"])
	return best


func _hour_of(name: String) -> float:
	for frame in _frames:
		if str(frame["name"]) == name:
			return float(frame["hour"])
	return 0.0


## --- the curve ------------------------------------------------------------


func _build_frames() -> Array[Dictionary]:
	var built: Array[Dictionary] = []
	var times: Dictionary = _config.get("times", {})
	for name: String in times.keys():
		if name.begins_with("_"):
			continue
		var over: Dictionary = _with_inheritance(times, name)
		built.append({
			"name": name,
			"hour": fposmod(float(over.get("at_hour", 0.0)), 24.0),
			"sun": _merged("sun", over),
			"sky": _merged("sky", over),
			"environment": _merged("environment", over),
		})
	built.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["hour"]) < float(b["hour"]))
	if built.is_empty():
		push_warning("art.json declares no times; nothing can be applied")
	return built


## A keyframe may say `same_as` and take another one's whole look.
##
## This exists because interpolation makes DEEP NIGHT a single instant. With one
## night keyframe the meadow spends every hour of darkness on a ramp towards
## either dusk or dawn, and it rendered exactly like that: a moon and a star
## field over grass at very nearly its noon brightness. A plateau needs a
## keyframe at each end of it, and the alternative — writing the same fourteen
## values out twice — is the thing the note above `_merged()` warns about, where
## two copies of one look silently disagree about something nobody meant to vary.
##
## One level deep, deliberately. A chain of inheritance in a look file is a
## thing nobody can read.
func _with_inheritance(times: Dictionary, name: String) -> Dictionary:
	var over: Dictionary = (times[name] as Dictionary).duplicate(true)
	var parent := str(over.get("same_as", ""))
	if parent == "":
		return over
	if not times.has(parent) or parent == name:
		push_warning("time '%s' says same_as '%s', which is not another time" % [name, parent])
		return over
	var base: Dictionary = (times[parent] as Dictionary).duplicate(true)
	for key: String in over.keys():
		# `at_hour` is the whole point of a held keyframe: it is the SAME look at
		# a DIFFERENT hour, so the child's own hour always wins.
		base[key] = over[key]
	base.erase("same_as")
	return base


## Which two keyframes an hour sits between, and how far.
##
## Static and taking plain hours so `tests/test_weather.gd` can prove the
## wrap-around — the segment from the last keyframe of one day to the first of
## the next is the only one that can be wrong, and it is the one that contains
## midnight.
static func bracket_hours(hours: Array, at: float) -> Dictionary:
	if hours.is_empty():
		return {"before": 0, "after": 0, "t": 0.0}
	if hours.size() == 1:
		return {"before": 0, "after": 0, "t": 0.0}
	at = fposmod(at, 24.0)
	for i in hours.size():
		var start := float(hours[i])
		var next := i + 1
		var end := float(hours[next]) if next < hours.size() else float(hours[0]) + 24.0
		if next >= hours.size():
			next = 0
		if at >= start and at < end:
			return {"before": i, "after": next, "t": (at - start) / maxf(0.0001, end - start)}
	# Before the first keyframe of the day: the tail of the wrapping segment.
	var last := hours.size() - 1
	var from := float(hours[last]) - 24.0
	var to := float(hours[0])
	return {"before": last, "after": 0, "t": (at - from) / maxf(0.0001, to - from)}


## Blend two look blocks. Numbers lerp, `#rrggbb` strings lerp as colours,
## anything else takes whichever side is nearer.
##
## Keys beginning with `_` are comments and are dropped: art.json carries its
## reasoning inline, and a comment is not a value to interpolate.
static func blend_blocks(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out: Dictionary = {}
	for key: String in a.keys():
		if key.begins_with("_"):
			continue
		var left: Variant = a[key]
		if not b.has(key):
			out[key] = left
			continue
		var right: Variant = b[key]
		if (left is float or left is int) and (right is float or right is int):
			out[key] = lerpf(float(left), float(right), t)
		elif left is String and right is String and (left as String).begins_with("#"):
			out[key] = "#" + Color(left as String).lerp(Color(right as String), t).to_html(false)
		else:
			out[key] = left if t < 0.5 else right
	for key: String in b.keys():
		if not key.begins_with("_") and not out.has(key):
			out[key] = b[key]
	return out


## A weather's full knob set, with `clear` underneath it.
##
## `clear` is the identity, so every knob has a value even when a state names
## only the three it cares about — the same reason a time of day states only
## what it changes.
func _weather_block(id: String) -> Dictionary:
	var all: Dictionary = _config.get("weather", {})
	var block: Dictionary = (all.get(DEFAULT_WEATHER, {}) as Dictionary).duplicate(true)
	if not all.has(id) and id != DEFAULT_WEATHER:
		push_warning("no weather called '%s' in art.json; using '%s'" % [id, DEFAULT_WEATHER])
	for key: String in (all.get(id, {}) as Dictionary).keys():
		block[key] = all[id][key]
	return block


func _weather_knobs(from_id: String, to_id: String, blend: float) -> Dictionary:
	if from_id == to_id:
		return _weather_block(from_id)
	return blend_blocks(_weather_block(from_id), _weather_block(to_id), clampf(blend, 0.0, 1.0))


func _apply(at: float, knobs: Dictionary, flash: float) -> void:
	if _frames.is_empty():
		return
	var hours: Array = []
	for frame in _frames:
		hours.append(float(frame["hour"]))
	var span := bracket_hours(hours, at)
	var before: Dictionary = _frames[int(span["before"])]
	var after: Dictionary = _frames[int(span["after"])]
	var t := float(span["t"])

	_apply_sun(blend_blocks(before["sun"], after["sun"], t), knobs)
	_apply_environment(
		blend_blocks(before["environment"], after["environment"], t),
		blend_blocks(before["sky"], after["sky"], t),
		before["sky"], after["sky"], t, knobs, flash
	)


## A time-of-day states only what it changes; everything else comes from the
## base block. Full copies of every value per hour is how two of them end up
## silently disagreeing about something nobody meant to vary.
func _merged(section: String, over: Dictionary) -> Dictionary:
	var base: Dictionary = (_config.get(section, {}) as Dictionary).duplicate(true)
	for key: String in (over.get(section, {}) as Dictionary).keys():
		base[key] = over[section][key]
	return base


func _load() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## The single highest-leverage thing in the whole art pass.
##
## `05-spawn-low-sun` was the only survey frame with real darks and was, by the
## critic's own reading, visibly the best-looking one — which shows the gap is a
## sun angle and a shadow, not a fidelity ceiling.
func _apply_sun(cfg: Dictionary, knobs: Dictionary) -> void:
	var sun: DirectionalLight3D = get_node_or_null(sun_path) as DirectionalLight3D
	if sun == null or cfg.is_empty():
		return

	sun.rotation = Vector3(
		deg_to_rad(float(cfg.get("pitch_deg", -46.0))),
		deg_to_rad(float(cfg.get("yaw_deg", -40.0))),
		0.0
	)
	# Weather multiplies the hour rather than replacing it, so one `rain` entry
	# darkens a noon and a midnight correctly instead of needing an entry per
	# combination.
	sun.light_energy = float(cfg.get("energy", 1.25)) * float(knobs.get("sun_energy", 1.0))
	sun.light_color = Color(str(cfg.get("colour", "#fff3e0"))).lerp(
		Color(str(knobs.get("sun_colour", "#ffffff"))),
		clampf(float(knobs.get("sun_mix", 0.0)), 0.0, 1.0)
	)
	# A cloud is a very large light source. Widening the disc is what makes an
	# overcast shadow edge go soft, and it is most of why cloud reads as cloud
	# rather than as somebody having turned the sun down.
	sun.light_angular_distance = maxf(
		0.0,
		float(cfg.get("angular_distance", 0.6)) + float(knobs.get("sun_softness", 0.0))
	)

	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = float(cfg.get("shadow_max_distance", 220.0))
	# Normal bias fights the acne a heightmap terrain produces at grazing angles.
	# Raise it if the ground looks striped; lower it if small props stop casting.
	sun.shadow_normal_bias = float(cfg.get("shadow_normal_bias", 1.4))
	sun.shadow_bias = float(cfg.get("shadow_bias", 0.06))
	sun.shadow_blur = float(cfg.get("shadow_blur", 1.0))

	# Fade the last splits out instead of stopping dead.
	#
	# The critic found "a hard shadow-distance cutoff as a horizontal line across
	# 04" — everything nearer than `shadow_max_distance` shaded, everything past
	# it uniformly lit, with a visible seam between. That seam is the artefact,
	# not the distance: pushing the distance out just moves the line further away
	# while costing shadow resolution everywhere nearer.
	#
	# `fade_start` is a FRACTION of the max distance at which the fade begins, so
	# 0.7 means the outer third dissolves. The line becomes a gradient, which the
	# aerial perspective and fog then finish hiding.
	sun.directional_shadow_fade_start = clampf(float(cfg.get("shadow_fade_start", 0.7)), 0.0, 1.0)
	# Splits blended into each other rather than butted together, which removes
	# the same seam at each of the three interior cascade boundaries. It is the
	# identical defect three more times over, just closer to the camera and so
	# smaller and easier to miss.
	sun.directional_shadow_blend_splits = bool(cfg.get("shadow_blend_splits", true))


## An image sky if the times of day name one, the procedural gradient otherwise.
##
## The blind critic measured the procedural sky's horizontal variation at
## **0.020** against **0.140–0.289** across the Palworld references — seven to
## fourteen times less — and called it out plainly: no clouds, no sun disc, "the
## build sky contributes nothing". It named this the cheapest large win
## available, and it was right: a `ProceduralSkyMaterial` can produce a vertical
## gradient and a soft sun blob and nothing else, ever. There is no amount of
## tuning that puts a cumulus in it.
##
## So a time of day names an HDRI panorama, and the two bracketing hours are
## cross-faded with the cloud dome laid over the pair. The gradient stays as the
## fallback, because a missing texture should degrade to the old sky rather than
## to a black void — and in that mode the panorama snaps at the halfway point
## rather than fading, which is worse and visible and says so in a warning.
func _apply_sky(
	sky: Sky, blended: Dictionary, before: Dictionary, after: Dictionary,
	t: float, knobs: Dictionary, flash: float
) -> void:
	var a := str(before.get("panorama", ""))
	var b := str(after.get("panorama", ""))
	var cloud := str(blended.get("overcast_panorama", ""))
	if _can_shade(a) and _can_shade(b) and _can_shade(cloud):
		_shader_sky = true
		if _sky_material == null or sky.sky_material != _sky_material:
			_sky_material = ShaderMaterial.new()
			var shader := Shader.new()
			shader.code = SKY_SHADER
			_sky_material.shader = shader
			sky.sky_material = _sky_material
		_sky_material.set_shader_parameter("sky_a", load(a))
		_sky_material.set_shader_parameter("sky_b", load(b))
		_sky_material.set_shader_parameter("sky_overcast", load(cloud))
		_sky_material.set_shader_parameter("rot_a", float(before.get("rotation_deg", 0.0)) / 360.0)
		_sky_material.set_shader_parameter("rot_b", float(after.get("rotation_deg", 0.0)) / 360.0)
		_sky_material.set_shader_parameter("rot_overcast", 0.0)
		_sky_material.set_shader_parameter("energy_a", float(before.get("energy", 1.0)))
		_sky_material.set_shader_parameter("energy_b", float(after.get("energy", 1.0)))
		_sky_material.set_shader_parameter("blend", clampf(t, 0.0, 1.0))
		_sky_material.set_shader_parameter(
			"overcast_blend", clampf(float(knobs.get("overcast", 0.0)), 0.0, 1.0))
		_sky_material.set_shader_parameter(
			"overcast_energy",
			float(blended.get("overcast_energy", 1.0)) * float(knobs.get("overcast_energy", 1.0))
		)
		var tint := Color(str(blended.get("overcast_tint", "#ffffff")))
		_sky_material.set_shader_parameter("overcast_tint", Vector3(tint.r, tint.g, tint.b))
		_sky_material.set_shader_parameter("flash", flash * FLASH_SKY)
		return

	if _shader_sky:
		_shader_sky = false
		_sky_material = null

	var panorama := b if t >= 0.5 else a
	if panorama != "" and ResourceLoader.exists(panorama):
		var image := sky.sky_material as PanoramaSkyMaterial
		if image == null:
			image = PanoramaSkyMaterial.new()
			sky.sky_material = image
		image.panorama = load(panorama) as Texture2D
		image.energy_multiplier = float(blended.get("energy", 1.0))
		# Filtering on, because a 2K panorama stretched across a sky dome shows
		# its texels at the horizon otherwise, which reads as banding.
		image.filter = true
		return

	if panorama != "":
		push_warning("time of day names a sky panorama that does not exist: %s" % panorama)

	var gradient := sky.sky_material as ProceduralSkyMaterial
	if gradient == null:
		gradient = ProceduralSkyMaterial.new()
		sky.sky_material = gradient
	gradient.sky_top_color = Color(str(blended.get("top_colour", "#3b6f93")))
	gradient.sky_horizon_color = Color(str(blended.get("horizon_colour", "#b9c8cf")))
	gradient.ground_horizon_color = Color(str(blended.get("ground_horizon_colour", "#b9c8cf")))
	gradient.ground_bottom_color = Color(str(blended.get("ground_bottom_colour", "#4a5648")))
	gradient.sun_angle_max = float(blended.get("sun_angle_max_deg", 24.0))
	gradient.sun_curve = float(blended.get("sun_curve", 0.18))
	gradient.energy_multiplier = float(blended.get("energy", 1.0))


func _can_shade(path: String) -> bool:
	return path != "" and ResourceLoader.exists(path)


## True when the cross-fading sky shader is in use rather than the fallback.
## `tools/preview_weather.gd` asserts this, because the fallback looks almost
## right in a still and cannot fade at all in motion.
func blending_sky() -> bool:
	return _shader_sky


func _apply_environment(
	cfg: Dictionary, sky_blended: Dictionary, sky_before: Dictionary,
	sky_after: Dictionary, t: float, knobs: Dictionary, flash: float
) -> void:
	var holder: WorldEnvironment = get_node_or_null(environment_path) as WorldEnvironment
	if holder == null or holder.environment == null:
		return
	var env := holder.environment

	if not sky_blended.is_empty() and env.sky != null:
		_apply_sky(env.sky, sky_blended, sky_before, sky_after, t, knobs, flash)

	if cfg.is_empty():
		return

	# ACES holds highlights on sunlit grass instead of clipping them to white,
	# which was the single worst thing about the previous prototype's look.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = float(cfg.get("exposure", 1.0)) * float(knobs.get("exposure", 1.0))
	env.tonemap_white = float(cfg.get("white", 6.0))
	env.ambient_light_energy = (
		float(cfg.get("ambient_energy", 1.0)) * float(knobs.get("ambient_energy", 1.0))
		+ flash * FLASH_AMBIENT
	)
	# Ambient from the sky, dialled DOWN. Full-strength sky ambient fills every
	# shadow back in, which is precisely how a scene ends up with no darks.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# ...but a real colour underneath it, because sky ambient is not portable.
	#
	# Measured: quadrupling `ambient_energy` with sky ambient changed the survey
	# frames by nothing at all — not one thousandth — while an explicit colour
	# ambient lifted the shaded near ground by 55%. Sky radiance does not reach
	# the terrain under the Compatibility renderer the survey is forced to use
	# (D06), so a scene lit only by sky ambient has ZERO fill in every frame a
	# critic ever sees, while looking correct in the Forward+ build that ships.
	#
	# `sky_contribution` blends between this colour and the sky, so specifying
	# both means shaded ground is lit under either renderer. It is also just the
	# more honest way to state it: "shadows are filled by this much of this
	# colour" is a decision, and reading it off a procedural sky was never one.
	#
	# It is also why a night that looks right in the survey is a night that
	# looks right in the game: the fill at midnight is a stated deep blue rather
	# than whatever radiance a star field happens to produce.
	env.ambient_light_color = Color(str(cfg.get("ambient_colour", "#9fb4c6"))).lerp(
		Color(str(knobs.get("ambient_colour", "#ffffff"))),
		clampf(float(knobs.get("ambient_mix", 0.0)), 0.0, 1.0)
	)
	env.ambient_light_sky_contribution = float(cfg.get("ambient_sky_contribution", 0.55))

	env.ssao_enabled = bool(cfg.get("ssao_enabled", true))
	env.ssao_intensity = float(cfg.get("ssao_intensity", 1.6))
	env.ssao_radius = float(cfg.get("ssao_radius", 1.2))

	env.fog_enabled = bool(cfg.get("fog_enabled", true))
	env.fog_light_color = Color(str(cfg.get("fog_colour", "#c4d2d8"))).lerp(
		Color(str(knobs.get("fog_colour", "#ffffff"))),
		clampf(float(knobs.get("fog_mix", 0.0)), 0.0, 1.0)
	)
	env.fog_density = maxf(0.0, float(cfg.get("fog_density", 0.0016)) * float(knobs.get("fog_density", 1.0)))
	# Sky affect is zero in clear weather, deliberately. Fog that tints the sky
	# produces the hard grey band the critic found across `03-rise-overlook`,
	# where the terrain rose out of a white void. Under a full cloud dome the
	# sky and the fog already agree about their colour, so the band cannot form
	# and letting fog reach the sky is what stops the horizon reading as a
	# cut-out — which is why this is a weather knob and not a constant.
	env.fog_sky_affect = clampf(float(knobs.get("fog_sky_affect", 0.0)), 0.0, 1.0)
	env.fog_aerial_perspective = clampf(
		float(cfg.get("aerial_perspective", 0.4)) * float(knobs.get("aerial", 1.0)), 0.0, 1.0)

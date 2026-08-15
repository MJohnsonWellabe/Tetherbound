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

const CONFIG_PATH := "res://data/config/art.json"
const DAY_CYCLE := preload("res://scripts/world/day_cycle.gd")

const DEFAULT_TIME := "day"

## Nodes in this group get their clock snapped back to morning by
## reset_to_morning() -- how scripts/build/camp.gd's "rest to morning" reaches
## the sky without camp.gd needing to know world_look.gd exists.
const GROUP := "day_cycle"

@export var sun_path: NodePath
@export var environment_path: NodePath

var _config: Dictionary = {}
var _time: String = DEFAULT_TIME
var _cycle: RefCounted = null
var _elapsed_seconds: float = 0.0

## R5.2: a weather delta layered on top of whichever time-of-day preset is
## active, set by world_weather.gd. Empty means no weather override -- the
## time-of-day preset's own look, unchanged. Kept as a second axis rather
## than folded into `times` so a rainy noon and a clear noon still share the
## same sun angle.
var _weather: Dictionary = {}


func _ready() -> void:
	_config = _load()
	if _config.is_empty():
		push_warning("art.json missing or unreadable; the scene keeps its authored look")
		return
	_cycle = DAY_CYCLE.new(_config)
	add_to_group(GROUP)
	apply_time(DEFAULT_TIME)


## Real time passing, not gameplay -- there is no pause here on purpose: the
## build/inventory menus pause the world with the sky still visible behind
## them, and a clock that stops the moment a menu opens would make every menu
## a free way to hold off dusk forever.
func _process(delta: float) -> void:
	if _cycle == null:
		return
	_elapsed_seconds += delta
	var hour: float = _cycle.hour_at(_elapsed_seconds)
	var preset: String = _cycle.preset_at(hour)
	if preset != "" and preset != _time:
		apply_time(preset)


## Camp rest calls this (by group, not by node reference -- see GROUP above)
## so waking up actually reads as morning instead of the sky staying wherever
## it was when the player made camp.
func reset_to_morning() -> void:
	apply_time(DEFAULT_TIME)


func is_dark() -> bool:
	return _cycle != null and _cycle.is_dark(_cycle.hour_at(_elapsed_seconds))


## Set the hour, and let everything that depends on it move together.
##
## The last survey shipped two frames named `01-spawn-outward` and
## `05-spawn-low-sun` whose skies were BIT-IDENTICAL — 46.8% of the whole frame
## pixel-for-pixel the same — because the only thing the low-sun frame changed
## was the DirectionalLight3D's pitch. The sun disc, the sky gradient, the
## horizon haze and the fog colour all stayed at noon. The key art board asks
## for "day and night create different moods", and a sky that does not
## participate in the time of day cannot deliver one.
##
## So the hour is a single named value, and sun, sky, fog and ambient are all
## derived from it. Anything that wants to change the light asks for a time
## rather than reaching for the light directly — which is the only way they
## cannot drift apart again.
##
## R5.1: this is also the ONE place _elapsed_seconds is written outside
## _process(), so tools/survey.gd calling this directly (it picks a time by
## name, per viewpoint) cannot be undone by the very next _process() tick
## deciding, from stale elapsed time, that some other preset is due.
func apply_time(name: String) -> void:
	if _config.is_empty():
		return
	var times: Dictionary = _config.get("times", {})
	if not times.has(name):
		if name != DEFAULT_TIME:
			push_warning("no time-of-day called '%s' in art.json; using '%s'" % [name, DEFAULT_TIME])
		name = DEFAULT_TIME
	_time = name

	var over: Dictionary = times.get(name, {})
	var sun_cfg := _merged("sun", over)
	var sky_cfg := _merged("sky", over)
	var env_cfg := _merged("environment", over)
	_layer_weather(sun_cfg, sky_cfg, env_cfg)

	_apply_sun(sun_cfg)
	_apply_environment(env_cfg, sky_cfg)

	if _cycle != null and over.has("hour"):
		_elapsed_seconds = _cycle.elapsed_for_hour(float(over["hour"]))


## R5.2: world_weather.gd calls this whenever the weather changes. `delta` is
## one entry from data/config/weather.json's `presets` block (or {} for
## "clear"/no override). Re-applies the CURRENT time of day immediately so
## the new weather takes effect without waiting for the next natural preset
## change, and so weather never has to be reapplied by hand when the clock
## advances on its own -- apply_time() always re-layers whatever `_weather`
## currently holds.
func set_weather(delta: Dictionary) -> void:
	_weather = delta
	apply_time(_time)


## Multiplies/overrides onto the already-merged time-of-day dicts, never onto
## a live node property -- reading `sun.light_energy` back and multiplying it
## again on the next weather change would compound every time weather rolls,
## since the previous weather's multiplier is already baked into the node.
## Computing from the fresh per-call `_merged()` result is idempotent: the
## same weather delta on the same time of day always lands on the same value.
func _layer_weather(sun_cfg: Dictionary, sky_cfg: Dictionary, env_cfg: Dictionary) -> void:
	if _weather.is_empty():
		return
	var sun_over: Dictionary = _weather.get("sun", {})
	if sun_over.has("energy_mult"):
		sun_cfg["energy"] = float(sun_cfg.get("energy", 1.25)) * float(sun_over["energy_mult"])
	if sun_over.has("angular_distance"):
		sun_cfg["angular_distance"] = float(sun_over["angular_distance"])
	if sun_over.has("shadow_enabled"):
		sun_cfg["shadow_enabled"] = bool(sun_over["shadow_enabled"])

	var sky_over: Dictionary = _weather.get("sky", {})
	for key: String in ["top_colour", "horizon_colour", "ground_horizon_colour"]:
		if sky_over.has(key):
			sky_cfg[key] = sky_over[key]

	var env_over: Dictionary = _weather.get("environment", {})
	if env_over.has("ambient_energy_mult"):
		env_cfg["ambient_energy"] = float(env_cfg.get("ambient_energy", 1.0)) * float(env_over["ambient_energy_mult"])
	if env_over.has("ambient_colour"):
		env_cfg["ambient_colour"] = env_over["ambient_colour"]
	if env_over.has("fog_density_add"):
		env_cfg["fog_density"] = float(env_cfg.get("fog_density", 0.0016)) + float(env_over["fog_density_add"])
	if env_over.has("fog_colour"):
		env_cfg["fog_colour"] = env_over["fog_colour"]


func time_of_day() -> String:
	return _time


func times_available() -> Array:
	var found: Array = []
	for key: String in _config.get("times", {}).keys():
		if not key.begins_with("_"):
			found.append(key)
	return found


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
func _apply_sun(cfg: Dictionary) -> void:
	var sun: DirectionalLight3D = get_node_or_null(sun_path) as DirectionalLight3D
	if sun == null or cfg.is_empty():
		return

	sun.rotation = Vector3(
		deg_to_rad(float(cfg.get("pitch_deg", -46.0))),
		deg_to_rad(float(cfg.get("yaw_deg", -40.0))),
		0.0
	)
	sun.light_energy = float(cfg.get("energy", 1.25))
	sun.light_color = Color(str(cfg.get("colour", "#fff3e0")))
	sun.light_angular_distance = float(cfg.get("angular_distance", 0.6))

	# R5.2 tried driving this false for overcast weather (a real diffuse sky
	# casts no hard directional shadow) and reverted it: with no shadow map,
	# Terrain3D's own shader rendered the entire ground as if fully occluded
	# instead of fully lit -- confirmed by an isolated before/after render
	# with every other value held constant. A known, narrower version of the
	# same class of Compatibility-renderer/Terrain3D interaction
	# EV4-textures-lighting-remainder already catalogued (shadow_blur and
	# light_angular_distance both no-op under Compatibility). Left
	# overridable via config in case a future renderer/Terrain3D version
	# fixes the interaction, but nothing in this project sets it false today.
	sun.shadow_enabled = bool(cfg.get("shadow_enabled", true))
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = float(cfg.get("shadow_max_distance", 220.0))
	# Normal bias fights the acne a heightmap terrain produces at grazing angles.
	# Raise it if the ground looks striped; lower it if small props stop casting.
	sun.shadow_normal_bias = float(cfg.get("shadow_normal_bias", 1.4))
	sun.shadow_bias = float(cfg.get("shadow_bias", 0.06))
	sun.shadow_blur = float(cfg.get("shadow_blur", 1.0))


## An image sky if the time of day names one, the procedural gradient otherwise.
##
## The blind critic measured the procedural sky's horizontal variation at
## **0.020** against **0.140–0.289** across the Palworld references — seven to
## fourteen times less — and called it out plainly: no clouds, no sun disc, "the
## build sky contributes nothing". It named this the cheapest large win
## available, and it was right: a `ProceduralSkyMaterial` can produce a vertical
## gradient and a soft sun blob and nothing else, ever. There is no amount of
## tuning that puts a cumulus in it.
##
## So a time of day may name an HDRI panorama instead. The gradient stays as the
## fallback, because a missing texture should degrade to the old sky rather than
## to a black void, and because the procedural path is still the right answer for
## anywhere that wants a stylised flat sky later.
func _apply_sky(sky: Sky, cfg: Dictionary) -> void:
	var panorama := str(cfg.get("panorama", ""))
	if panorama != "" and ResourceLoader.exists(panorama):
		var image := sky.sky_material as PanoramaSkyMaterial
		if image == null:
			image = PanoramaSkyMaterial.new()
			sky.sky_material = image
		image.panorama = load(panorama) as Texture2D
		image.energy_multiplier = float(cfg.get("energy", 1.0))
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
	gradient.sky_top_color = Color(str(cfg.get("top_colour", "#3b6f93")))
	gradient.sky_horizon_color = Color(str(cfg.get("horizon_colour", "#b9c8cf")))
	gradient.ground_horizon_color = Color(str(cfg.get("ground_horizon_colour", "#b9c8cf")))
	gradient.ground_bottom_color = Color(str(cfg.get("ground_bottom_colour", "#4a5648")))
	gradient.sun_angle_max = float(cfg.get("sun_angle_max_deg", 24.0))
	gradient.sun_curve = float(cfg.get("sun_curve", 0.18))
	gradient.energy_multiplier = float(cfg.get("energy", 1.0))


func _apply_environment(cfg: Dictionary, sky_cfg: Dictionary) -> void:
	var holder: WorldEnvironment = get_node_or_null(environment_path) as WorldEnvironment
	if holder == null or holder.environment == null:
		return
	var env := holder.environment

	if not sky_cfg.is_empty() and env.sky != null:
		_apply_sky(env.sky, sky_cfg)

	if cfg.is_empty():
		return

	# ACES holds highlights on sunlit grass instead of clipping them to white,
	# which was the single worst thing about the previous prototype's look.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = float(cfg.get("exposure", 1.0))
	env.tonemap_white = float(cfg.get("white", 6.0))
	env.ambient_light_energy = float(cfg.get("ambient_energy", 1.0))
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
	env.ambient_light_color = Color(str(cfg.get("ambient_colour", "#9fb4c6")))
	env.ambient_light_sky_contribution = float(cfg.get("ambient_sky_contribution", 0.55))

	env.ssao_enabled = bool(cfg.get("ssao_enabled", true))
	env.ssao_intensity = float(cfg.get("ssao_intensity", 1.6))
	env.ssao_radius = float(cfg.get("ssao_radius", 1.2))

	env.fog_enabled = bool(cfg.get("fog_enabled", true))
	env.fog_light_color = Color(str(cfg.get("fog_colour", "#c4d2d8")))
	env.fog_density = float(cfg.get("fog_density", 0.0016))
	# Sky affect at zero, deliberately. Fog that tints the sky produces the hard
	# grey band the critic found across `03-rise-overlook`, where the terrain rose
	# out of a white void.
	env.fog_sky_affect = float(cfg.get("fog_sky_affect", 0.0))
	env.fog_aerial_perspective = float(cfg.get("aerial_perspective", 0.4))

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

const SKY_SHADER_PATH := "res://shaders/sky_clouds.gdshader"
const CONFIG_PATH := "res://data/config/art.json"
const DAY_CYCLE := preload("res://scripts/world/day_cycle.gd")
## T1-WORLD: for the character emission floor only -- see `_apply_environment`.
## Preloaded for its STATIC setter; this node never builds or owns a character.
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
## WORLD-ART aerial-fade pass, 2026-09-02. For the terrain's distance-fade
## colour only -- see `_apply_environment`'s own comment on
## `aerial_fade_colour`. Preloaded for its STATIC setter, same reasoning as
## CHARACTER_MODEL directly above: this node never builds or owns the terrain.
const PLAYGROUND_WORLD := preload("res://scripts/world/playground_world.gd")

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

## OWNER-0901-DAYNIGHT-CYCLE. `_elapsed_seconds` above already measures real
## time against `day_length_seconds`, but nothing ever told `Game.day` about
## it -- the HUD/pause-menu "Day N" readout only moved when the player slept
## (autoload/game_state.gd::advance_day(), called from camp.gd/night_rest.gd).
## A whole session with no sleep left it stuck on "Day 1" no matter how much
## real time passed. Tracked as its own accumulator rather than derived from
## `_elapsed_seconds` because `apply_time()` (below) rewrites that to a
## same-cycle hour on every rest/scene-start snap, which would otherwise make
## a day-count derived from it run backwards or double-count.
var _auto_day_accum: float = 0.0

## R5.2: a weather delta layered on top of whichever time-of-day preset is
## active, set by world_weather.gd. Empty means no weather override -- the
## time-of-day preset's own look, unchanged. Kept as a second axis rather
## than folded into `times` so a rainy noon and a clear noon still share the
## same sun angle.
var _weather: Dictionary = {}


func _ready() -> void:
	# OWNER-0901-DAYNIGHT-CYCLE. The comment on _process() below has always
	# claimed menus can't pause this clock, but WorldLook was never actually
	# exempted from the pause game_menu.gd sets while any tab is open, so it
	# silently did stop -- and however long a session happened to spend in
	# menus (different every playthrough) is exactly what made night fall at
	# what read as a random time instead of on `day_length_seconds`.
	process_mode = Node.PROCESS_MODE_ALWAYS
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
##
## OP23-05/OP23-06 (owner ROG playtest). This used to call apply_time(preset)
## only at the instant preset_at() crossed a keyframe boundary -- a hard snap
## from whatever the previous preset looked like straight to the new one's
## authored numbers, no matter how far apart they were. Golden hour to night
## is the worst case: bright, warm and lit all the way to hour 24, then one
## frame later the NIGHT-LIGHT tuning (ambient_energy 2.3, desaturation, the
## whole ramp) lands at full strength with nothing eased in -- which is
## exactly "flashed instantly instead of progressing" and exactly why night
## reads as "too dark... worst immediately after nightfall": the numbers
## were never wrong, arriving at them in one frame was. `_apply_blended()`
## below reads day_cycle.gd's new interpolate_at() and re-derives sun/sky/
## environment every BLEND_INTERVAL seconds as a continuous lerp between
## whichever two keyframes bracket the current hour, so the whole day sweeps
## rather than holding three fixed poses. Throttled rather than run every
## frame: the clock moves slowly (one in-game hour is day_length_seconds/24
## real seconds, minutes even on a short day), so recomputing this every
## frame would burn CPU OP23-01 already called out as scarce for no visible
## gain.
##
## apply_time(name) itself is UNCHANGED and still snaps exactly -- every
## survey/capture/diagnostic tool in tools/ calls it by name expecting a
## reproducible pinned frame, and that contract has to hold.
const BLEND_INTERVAL := 0.2
var _blend_accum: float = BLEND_INTERVAL

## R6-CLOCK-FREEZE. OFF by default -- this exists purely for capture/diagnostic
## tools and must never change gameplay's own experience of the day/night cycle.
##
## `day_length_seconds` is 600 (data/config/art.json), so one in-game HOUR is
## 25 real seconds. Under software rendering (llvmpipe, no GPU on this box) a
## single frame costs on the order of a real second, so `delta` above is huge
## by normal-frame standards. A capture tool that calls `apply_time("golden")`
## to pin an exact keyframe and then waits even 20-30 frames "to let the pose
## settle" is really waiting 20-30 real seconds -- 0.8 to 1.2 in-game HOURS --
## before the shutter, and every one of those frames' `_process` ticks fires
## `_apply_blended(hour)` (below), which re-derives sun/sky/environment from
## THAT drifted hour and overwrites whatever `apply_time()` just pinned. A
## "golden hour" capture shot this way came back looking like flat midday --
## not because golden hour was mistuned, but because the clock had already
## walked most of the way back into the day preset's own hour range by the
## time the frame was actually drawn.
##
## So `set_clock_frozen(true)` makes this function return before it does
## anything the passive clock relies on: `_elapsed_seconds` stops advancing,
## `_auto_day_accum` stops advancing (no automatic Game.day roll under a
## frozen capture rig), and `_apply_blended()` never runs. `apply_time(name)`
## itself is UNCHANGED and keeps working while frozen -- it still snaps
## exactly and still pins `_elapsed_seconds` from the preset's own `hour` (see
## that function's own comment) -- so a tool can freeze once, then call
## `apply_time()` per viewpoint and pose for as many settle frames as it
## likes with zero drift, restoring the "every survey/capture/diagnostic tool
## calls apply_time() by name expecting a reproducible pinned frame" contract
## this file has always claimed to honour.
var _clock_frozen: bool = false


## Capture/diagnostic-only. See `_clock_frozen`'s own comment for why this
## exists and the arithmetic that makes it necessary. Never called from any
## gameplay path -- leaving this off is what keeps the day/night cycle
## exactly as it always was for a player.
func set_clock_frozen(frozen: bool) -> void:
	_clock_frozen = frozen


func _process(delta: float) -> void:
	if _cycle == null:
		return
	if _clock_frozen:
		return
	_elapsed_seconds += delta
	var hour: float = _cycle.hour_at(_elapsed_seconds)
	var preset: String = _cycle.preset_at(hour)
	if preset != "":
		_time = preset

	# OWNER-0901-DAYNIGHT-CYCLE: advance Game.day automatically as real time
	# passes, instead of leaving it to only ever move on a manual rest. A
	# `while` rather than `if` so a single huge delta (a long stall, an
	# alt-tab) still lands on the right day rather than under-counting.
	_auto_day_accum += delta
	while _auto_day_accum >= _cycle.day_length_seconds:
		_auto_day_accum -= _cycle.day_length_seconds
		var game := get_node_or_null(^"/root/Game")
		if game != null:
			game.call("advance_day")

	_blend_accum += delta
	if _blend_accum < BLEND_INTERVAL:
		return
	_blend_accum = 0.0
	_apply_blended(hour)


## Camp rest calls this (by group, not by node reference -- see GROUP above)
## so waking up actually reads as morning instead of the sky staying wherever
## it was when the player made camp.
func reset_to_morning() -> void:
	apply_time(DEFAULT_TIME)
	# A rest already advances Game.day itself (camp.gd/night_rest.gd call
	# advance_day() directly); without this the automatic accumulator above
	# would still be sitting close to a rollover from the time already spent
	# before the player slept, and fire again just moments into the new day.
	_auto_day_accum = 0.0


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
## "clear"/no override). Re-applies the current look immediately so the new
## weather takes effect without waiting for the next natural preset change,
## and so weather never has to be reapplied by hand when the clock advances
## on its own -- both apply_time() and _apply_blended() always re-layer
## whatever `_weather` currently holds.
##
## OP23-05: re-applies through _apply_blended(), not apply_time(_time). The
## latter snaps to the nearest NAMED preset's exact numbers -- fine before
## the clock blended continuously, but now it would pop the whole scene back
## to that preset every time weather rolls (every 4-8 real minutes) even
## mid-transition, undoing the smooth sweep this same task just added. Falls
## back to apply_time() only when there is no clock to read a live hour from
## (e.g. a scene with WorldLook but day_cycle.gd's config failed to load).
func set_weather(delta: Dictionary) -> void:
	_weather = delta
	if _cycle == null:
		apply_time(_time)
		return
	_apply_blended(_cycle.hour_at(_elapsed_seconds))


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
	# VIS-WORLD: see _apply_sun's own comment -- the weather presets' existing
	# angular_distance overrides are a no-op under Compatibility, so this is
	# the key that lets an overcast preset actually soften its own light.
	if sun_over.has("shadow_opacity"):
		sun_cfg["shadow_opacity"] = float(sun_over["shadow_opacity"])

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


## The live clock hour (0..24), for anything that wants to DISPLAY the time
## rather than react to a preset. `gate_f_probe.gd::clock_weather()` reads
## `_cycle`/`_elapsed_seconds` directly because it predates this and needs the
## preset too; this is the plain accessor a HUD widget should call instead of
## reaching into those same privates a second way.
func hour() -> float:
	return _cycle.hour_at(_elapsed_seconds) if _cycle != null else 0.0


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


## OP23-05. The passive clock's own tick: blend sun/sky/environment between
## whichever two keyframes day_cycle.gd's interpolate_at() says bracket
## `hour`, instead of ever snapping straight to one preset's numbers.
func _apply_blended(hour: float) -> void:
	if _cycle == null:
		return
	var interp: Dictionary = _cycle.call("interpolate_at", hour)
	var from_name: String = str(interp.get("from", DEFAULT_TIME))
	var to_name: String = str(interp.get("to", from_name))
	var t: float = float(interp.get("t", 0.0))
	var times: Dictionary = _config.get("times", {})
	var from_over: Dictionary = times.get(from_name, {})
	var to_over: Dictionary = times.get(to_name, {})

	var sun_cfg := _blend_dict(_COLOUR_KEYS.sun, _merged("sun", from_over), _merged("sun", to_over), t)
	var sky_cfg := _blend_dict(_COLOUR_KEYS.sky, _merged("sky", from_over), _merged("sky", to_over), t)
	var env_cfg := _blend_dict(_COLOUR_KEYS.environment, _merged("environment", from_over), _merged("environment", to_over), t)
	_layer_weather(sun_cfg, sky_cfg, env_cfg)

	_apply_sun(sun_cfg)
	_apply_environment(env_cfg, sky_cfg)


## Which keys in each merged section are hex-colour strings rather than plain
## numbers/flags -- `_blend_dict` needs to know before it can decide HOW to
## interpolate a key, since a colour lerped as a bare float is nonsense.
const _COLOUR_KEYS := {
	"sun": ["colour"],
	"sky": ["top_colour", "horizon_colour", "ground_horizon_colour", "ground_bottom_colour",
		# VP1: the cloud and sun colours used to snap at the blend midpoint
		# because they were not listed here; a driven clock now lerps them.
		"cloud_lit", "cloud_shade", "cloud_base", "sun_colour",
		# VP1 sky retune round 1: the new haze tint blends the same way.
		"horizon_haze_colour"],
	# WORLD-ART aerial-fade pass: aerial_fade_colour used to snap at the blend
	# midpoint (the default branch in `_blend_dict` below, for anything not
	# named here); it now lerps the same way fog/ambient already do, so the
	# terrain's own distance fade eases across a time-of-day transition
	# instead of popping between two presets' colours.
	"environment": ["fog_colour", "ambient_colour", "aerial_fade_colour"],
}

## yaw_deg wraps at +-180 -- a bare float lerp from day's 140 to golden's -66
## would sweep the LONG way around the compass (206 degrees) instead of the
## short way (154), which reads as the sun visibly crossing the wrong side
## of the sky. Everything else numeric lerps as a plain float; nothing else
## here is an angle that wraps.
const _ANGLE_KEYS := ["yaw_deg"]


## `a` and `b` are already-`_merged()` dicts for the same section (sun/sky/
## environment) at the FROM and TO keyframe. Colour keys lerp as Color,
## `yaw_deg` lerps the short way around the compass, every other numeric
## value lerps as a plain float, and anything else (booleans, the panorama
## path string) snaps at the midpoint -- there is no meaningful blend for
## "is this shadow-casting" or "which texture", and every such key in this
## project is already identical across every time-of-day preset in practice.
func _blend_dict(colour_keys: Array, a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out: Dictionary = a.duplicate(true)
	for key: String in b.keys():
		var bv: Variant = b[key]
		var av: Variant = a.get(key, bv)
		if colour_keys.has(key):
			out[key] = _as_colour(av).lerp(_as_colour(bv), t)
		elif key in _ANGLE_KEYS and (av is float or av is int) and (bv is float or bv is int):
			out[key] = _lerp_degrees(float(av), float(bv), t)
		elif (av is float or av is int) and (bv is float or bv is int):
			out[key] = lerpf(float(av), float(bv), t)
		else:
			out[key] = bv if t >= 0.5 else av
	return out


## Shortest-path lerp between two headings in degrees, wrapping through
## +-180 rather than always sweeping in the direction of increasing value --
## see `_ANGLE_KEYS`'s own comment for why yaw_deg specifically needs this.
static func _lerp_degrees(a: float, b: float, t: float) -> float:
	var diff := fmod(b - a + 540.0, 360.0) - 180.0
	return a + diff * t


## A blended colour arrives as a real Color (Dictionary values from
## `_blend_dict` above); every other caller still passes art.json's own hex
## string. Centralised so `_apply_sun/_apply_sky/_apply_environment` never
## have to know which they were handed.
static func _as_colour(value: Variant, fallback: String = "#ffffff") -> Color:
	if value is Color:
		return value
	if value == null:
		return Color(fallback)
	return Color(str(value))


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
	sun.light_color = _as_colour(cfg.get("colour"), "#fff3e0")
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
	# PERF cross-lane request: the ROG Ally / handheld GPU class pays for
	# every PSSM cascade as a separate shadow-map render pass. 4 splits was
	# never justified by anything this project measured -- dropped to 2,
	# which halves that per-frame cost, after an in-engine visual check found
	# no legible quality loss at normal third-person play distance (see the
	# capture comparison recorded for this change; the far/soft edge of a
	# distant fourth cascade split was never the source of the terrain's
	# shadow detail at the ranges the player actually stands at).
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = float(cfg.get("shadow_max_distance", 220.0))
	# Normal bias fights the acne a heightmap terrain produces at grazing angles.
	# Raise it if the ground looks striped; lower it if small props stop casting.
	sun.shadow_normal_bias = float(cfg.get("shadow_normal_bias", 1.4))
	sun.shadow_bias = float(cfg.get("shadow_bias", 0.06))
	sun.shadow_blur = float(cfg.get("shadow_blur", 1.0))
	# VIS-WORLD. The overcast lever that actually reaches this renderer.
	#
	# Three independent blind critics named the same thing: weather changes
	# particles but not light -- "sun shadows stay identically sharp and long
	# under clear, cloudy, fog and rain", and "overcast with crisp directional
	# shadows is a contradiction the eye catches instantly". All three weather
	# presets were already ASKING for soft shadows: cloudy and rain set
	# angular_distance 3.0, fog 2.5. None of it did anything, because
	# light_angular_distance is one of the two properties this function's own
	# comment above records as a no-op under Compatibility -- which is the
	# renderer the game ships (RB4/D01). So the presets carried the right
	# intent through a property that cannot express it, and the defect
	# survived every round that looked at the config and saw a soft-shadow
	# number sitting there.
	#
	# shadow_opacity is not a filtering feature -- it scales how much the
	# shadow term darkens, so it works where blur and angular distance do
	# not. It is also the one that steps around R5.2's trap recorded above:
	# the shadow map still EXISTS, so Terrain3D never sees the missing-shadow
	# case that rendered the whole ground as fully occluded. A faint shadow
	# is what overcast actually looks like; no shadow blanks the terrain.
	sun.shadow_opacity = float(cfg.get("shadow_opacity", 1.0))


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
	# SKY-CLOUDS, and it takes precedence over both paths below. This function's
	# own header argued for an HDRI panorama as the answer to "there is no amount
	# of tuning that puts a cumulus in it", and a panorama is one answer -- but a
	# generated sky is the better fit for the same slot: no asset to source,
	# license and ship, it drifts on the wind, and every time of day drives it
	# from the same art.json block that drives the gradient. `shaders/
	# sky_clouds.gdshader` degrades to this function's own gradient when
	# `cloud_coverage` is 0, so turning it off lands on the sky it replaced
	# rather than on a different one.
	if float(cfg.get("cloud_coverage", 0.0)) > 0.0 \
			and ResourceLoader.exists(SKY_SHADER_PATH):
		_apply_cloud_sky(sky, cfg)
		return

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
	gradient.sky_top_color = _as_colour(cfg.get("top_colour"), "#3b6f93")
	gradient.sky_horizon_color = _as_colour(cfg.get("horizon_colour"), "#b9c8cf")
	gradient.ground_horizon_color = _as_colour(cfg.get("ground_horizon_colour"), "#b9c8cf")
	gradient.ground_bottom_color = _as_colour(cfg.get("ground_bottom_colour"), "#4a5648")
	gradient.sun_angle_max = float(cfg.get("sun_angle_max_deg", 24.0))
	gradient.sun_curve = float(cfg.get("sun_curve", 0.18))
	gradient.energy_multiplier = float(cfg.get("energy", 1.0))


## Drive `shaders/sky_clouds.gdshader` from the same time-of-day block the
## gradient uses, so a time of day that wants a heavier sky says so with one
## number rather than by naming a different asset.
func _apply_cloud_sky(sky: Sky, cfg: Dictionary) -> void:
	var mat := sky.sky_material as ShaderMaterial
	if mat == null or mat.shader == null or mat.shader.resource_path != SKY_SHADER_PATH:
		mat = ShaderMaterial.new()
		mat.shader = load(SKY_SHADER_PATH)
		sky.sky_material = mat
	mat.set_shader_parameter("top_colour", _as_colour(cfg.get("top_colour"), "#3b6f93"))
	mat.set_shader_parameter("horizon_colour", _as_colour(cfg.get("horizon_colour"), "#b9c8cf"))
	mat.set_shader_parameter("ground_horizon_colour",
			_as_colour(cfg.get("ground_horizon_colour"), "#b9c8cf"))
	mat.set_shader_parameter("ground_bottom_colour",
			_as_colour(cfg.get("ground_bottom_colour"), "#4a5648"))
	mat.set_shader_parameter("sky_energy", float(cfg.get("energy", 1.0)))
	mat.set_shader_parameter("coverage", float(cfg.get("cloud_coverage", 0.46)))
	for pair: Array in [
		["cloud_sharpness", "sharpness"], ["cloud_scale", "scale"],
		["cloud_height", "height"], ["cloud_sun_gain", "sun_gain"],
		["sun_size", "sun_size"], ["sun_glow", "sun_glow"],
		# T1-HALL-4: how hard the celestial body's rim is. See
		# `sky_clouds.gdshader`'s own note -- the night sky's "moon" was reading
		# as a lens bloom because the disc was two-thirds gradient.
		["sun_disc_edge", "disc_edge"],
		# The glow halo's falloff exponent -- see the `sun_glow_falloff`
		# uniform's own comment in sky_clouds.gdshader for the fixed-24.0
		# defect this replaces (a halo whose angular width could not be
		# tuned by any of the neighbouring sun keys above).
		["sun_glow_falloff", "sun_glow_falloff"],
		# Round 7: the disc's TRUE angular radius, in degrees. `sun_size` above
		# is now inert for the disc -- it was thresholded as `1 - sun_size` and
		# treated as a cosine, but its values were never derived from a real
		# angle, so day's 0.022 was acos(1-0.022) = 12.0 degrees of RADIUS, a
		# disc filling ~34% of frame height, and golden/dawn's 0.009 was ~22%.
		# Expressed in degrees the numbers are checkable: at the capture's 70
		# degree vertical FOV, 1.0 degree of radius is a 2.0 degree disc, 2.86%
		# of frame height. `sun_size` is still passed above because the uniform
		# is still declared; removing the pass-through would error.
		["sun_angular_radius_deg", "sun_angular_radius_deg"],
		# VP1: cumulus form, shell projection, cirrus layer, horizon haze.
		["cloud_edge_softness", "edge_softness"], ["cloud_altitude", "cloud_altitude"],
		["cloud_lit_contrast", "lit_contrast"],
		["cloud_high_coverage", "high_coverage"], ["cloud_high_scale", "high_scale"],
		["cloud_high_opacity", "high_opacity"],
		["horizon_haze_height", "haze_height"], ["horizon_haze_strength", "haze_strength"],
	]:
		if cfg.has(str(pair[0])):
			mat.set_shader_parameter(str(pair[1]), float(cfg[str(pair[0])]))
	for pair2: Array in [
		["cloud_lit", "cloud_lit"], ["cloud_shade", "cloud_shade"],
		["cloud_base", "cloud_base"],
		["sun_colour", "sun_colour"],
		# VP1 sky retune round 1: the horizon haze band no longer reuses
		# horizon_colour verbatim -- see sky_clouds.gdshader's own comment
		# on the `haze_colour` uniform.
		["horizon_haze_colour", "haze_colour"],
	]:
		if cfg.has(str(pair2[0])):
			mat.set_shader_parameter(str(pair2[1]), _as_colour(cfg.get(str(pair2[0])), "#ffffff"))
	if cfg.has("cloud_wind"):
		var w: Array = cfg["cloud_wind"]
		mat.set_shader_parameter("wind", Vector2(float(w[0]), float(w[1])))


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
	# T1-WORLD. The character emission floor is a lighting decision, so it
	# belongs on the same clock as every other one here rather than frozen at
	# whatever time of day the world booted at. `_blend_dict` blends this like
	# any other numeric key -- which is why `art.json`'s BASE environment block
	# carries an explicit 1.0 rather than leaving day/golden to inherit a
	# missing key; see that file's own `_comment_adjustment_defaults_t1_sky`
	# for the bug a missing base default causes (the blend snaps instead of
	# ramping, because `av = a.get(key, bv)` silently defaults the FROM side to
	# the TO side's value).
	CHARACTER_MODEL.set_emission_floor_scale(float(cfg.get("character_emission_floor", 1.0)))

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
	env.ambient_light_color = _as_colour(cfg.get("ambient_colour"), "#9fb4c6")
	env.ambient_light_sky_contribution = float(cfg.get("ambient_sky_contribution", 0.55))

	env.ssao_enabled = bool(cfg.get("ssao_enabled", true))
	env.ssao_intensity = float(cfg.get("ssao_intensity", 1.6))
	env.ssao_radius = float(cfg.get("ssao_radius", 1.2))

	env.fog_enabled = bool(cfg.get("fog_enabled", true))
	env.fog_light_color = _as_colour(cfg.get("fog_colour"), "#c4d2d8")
	env.fog_density = float(cfg.get("fog_density", 0.0016))
	# Sky affect at zero, deliberately. Fog that tints the sky produces the hard
	# grey band the critic found across `03-rise-overlook`, where the terrain rose
	# out of a white void.
	env.fog_sky_affect = float(cfg.get("fog_sky_affect", 0.0))
	env.fog_aerial_perspective = float(cfg.get("aerial_perspective", 0.4))

	# WORLD-ART aerial-fade pass, 2026-09-02. The terrain's OWN distance fade
	# (`terrain_playground.json`'s `shader.aerial_fade_colour`, a uniform on
	# `shaders/terrain_ground.gdshader`, wholly separate from the fog above)
	# used to be read once at scene setup and never again, while the sky's
	# fog/horizon colours already varied every hour -- measured consequence at
	# midnight: a distant vista read 25.7/76.6/113.8, BRIGHTER than its own
	# foreground at 13.4/22.3/28.2, because far terrain kept fading toward a
	# constant tuned for a bright daytime sky. `cfg.has(...)` guards this so a
	# time-of-day preset that does not opt in changes nothing on this path --
	# the terrain keeps whatever `terrain_playground.json` gave it at scene
	# setup, exactly as before. Reached through PLAYGROUND_WORLD's static
	# setter (same pattern as CHARACTER_MODEL's emission floor above) because
	# this node has no reference to the scene's terrain; the setter itself is
	# a safe no-op if no terrain has been built yet, or if this Terrain3D
	# build's shader has no such uniform. This one function is called from
	# BOTH `apply_time()` (a pinned capture frame) and `_apply_blended()` (the
	# live clock), so both paths reach the terrain without duplicating the
	# call at each of those two sites.
	if cfg.has("aerial_fade_colour"):
		PLAYGROUND_WORLD.set_aerial_fade_colour(_as_colour(cfg.get("aerial_fade_colour")))

	# NIGHT-LIGHT. Colour-grade adjustment, off (no-op defaults) unless a
	# preset asks for it. Exists because raising a night preset's own light
	# energies enough to make the ground legible also reveals the terrain's
	# true daytime-green albedo -- light x albedo has no separate "this is
	# night" filter the way a human eye's scotopic vision does, so a bright
	# enough moon reads as a dim DAY, not a distinct night mood, exactly the
	# failure a blind critic named after the first legibility fix landed.
	# `adjustment_saturation` is Godot's equivalent of that missing filter.
	env.adjustment_enabled = bool(cfg.get("adjustment_enabled", false))
	env.adjustment_brightness = float(cfg.get("adjustment_brightness", 1.0))
	env.adjustment_contrast = float(cfg.get("adjustment_contrast", 1.0))
	env.adjustment_saturation = float(cfg.get("adjustment_saturation", 1.0))

extends Node3D

## The clock, the weather, and the rain. M10.
##
## `scripts/world/world_look.gd` could already move sun, sky, tonemap, fog and
## ambient together from a named preset, and the game called it exactly once, at
## boot. So the hard part — one place that owns the whole look — was already
## built and idle. This node is what finally drives it: a clock that advances an
## hour, a state machine that decides what the weather is doing, and one call
## per frame into `apply_moment()`.
##
## It owns NO look values. Every colour, energy and density is in
## data/config/art.json and is read by world_look; everything here is a
## duration, a probability or a particle count, and lives in
## data/config/weather.json. That split is deliberate and is the thing to keep:
## the person who says "it rains too much" and the person who says "the rain is
## too grey" should be editing different files.
##
## It also owns no spawning. §24 wants creatures gated on habitat, time and
## weather; `scripts/combat/encounter_director.gd` owns spawning and is not
## touched. What this node offers instead is a readable surface —
## `phase()`, `weather()`, `spawn_weight()`, `allows_spawn()` and a
## `conditions_changed` signal — which the director can ask or connect to.
## Building a second spawner here would be the worst available answer.

const CONFIG_PATH := "res://data/config/weather.json"

const DEFAULT_WEATHER := "clear"
## Hours in a day. Not a tunable: it is what "17:00" means.
const HOURS_PER_DAY := 24.0

## The phase or the weather changed — the two things a spawn condition can read.
## One signal for both, because a listener that cares about either cares about
## the pair, and two signals is two places to forget one.
signal conditions_changed(phase: String, weather: String)
signal phase_changed(phase: String, hour: float)
signal weather_changed(weather: String, previous: String)
## A lightning strike, at the moment it fires. For a thunderclap later.
signal lightning_struck()

@export var look_path: NodePath

var _config: Dictionary = {}
var _look: Node = null

var _hour: float = 12.0
var _hours_per_second: float = 1.0
var _paused: bool = false

var _phase: String = "day"
var _current: String = DEFAULT_WEATHER
var _next: String = DEFAULT_WEATHER
var _blend: float = 0.0
var _blend_seconds: float = 1.0
var _hold_left: float = 0.0
## Non-empty while something has pinned the weather for testing. The state
## machine keeps its clock but stops choosing.
var _forced: String = ""

var _rng := RandomNumberGenerator.new()

var _flash: float = 0.0
var _flash_rising: bool = false
var _second_strike_in: float = -1.0

var _rain: CPUParticles3D = null
var _rain_amount: int = 0
var _rain_alpha: float = 0.4

## What the last frame reported, so a change can be announced once rather than
## every frame. Edge-triggered for `Switchboard`'s reason: a signal that fires
## sixty times a second is not an event, it is a noise.
var _announced_phase: String = ""
var _announced_weather: String = ""


func _ready() -> void:
	_config = _load()
	_look = get_node_or_null(look_path)
	if _look == null:
		push_error("sky_cycle has no WorldLook to drive; the sky will not move")
		set_process(false)
		return

	var clock: Dictionary = _config.get("clock", {})
	var minutes := maxf(0.1, float(clock.get("minutes_per_day", 24.0)))
	_hours_per_second = HOURS_PER_DAY / (minutes * 60.0)
	_hour = fposmod(float(clock.get("start_hour", 12.0)), HOURS_PER_DAY)
	_paused = bool(clock.get("paused", false))

	_rng.seed = int(_config.get("schedule", {}).get("seed", 20250810))
	_phase = phase_at(_config.get("phases", {}), _hour)
	_current = DEFAULT_WEATHER
	_next = DEFAULT_WEATHER
	_hold_left = _roll_hold(_current)

	_build_rain()
	_announce()
	_push()
	# Printed at boot for the same reason `_report_population()` prints the
	# creature census: a clock nobody can see is indistinguishable from a clock
	# that is not running, and an evidence session should be able to say what
	# hour a frame was taken at.
	print("[sky] %s — a day is %.0f real minutes" % [describe(), minutes])
	weather_changed.connect(func(now: String, was: String) -> void:
		print("[sky] %s -> %s at %s" % [was, now, describe()]))


func _process(delta: float) -> void:
	# Something posed a named hour and wants to keep it — `tools/survey.gd` does
	# exactly this, five times in a row. Advancing the clock underneath it would
	# hand the critic five frames of whatever the clock had drifted to.
	if _look == null or bool(_look.call("is_manually_posed")):
		if _rain != null:
			_rain.emitting = false
		return

	if not _paused:
		_hour = fposmod(_hour + delta * _hours_per_second, HOURS_PER_DAY)

	_tick_weather(delta)
	_tick_flash(delta)
	_follow_rain()
	_announce()
	_push()


## --- the clock -------------------------------------------------------------


func hour() -> float:
	return _hour


## 0 at midnight, 1 at the next midnight. What a clock face would draw.
func day_fraction() -> float:
	return _hour / HOURS_PER_DAY


func phase() -> String:
	return _phase


func is_night() -> bool:
	return _phase == "night"


func set_hour(at: float) -> void:
	_hour = fposmod(at, HOURS_PER_DAY)
	if _look != null:
		_look.call("release")
	_announce()
	_push()


## Jump the clock forward. Negative runs it back.
func advance_hours(by: float) -> void:
	set_hour(_hour + by)


func set_paused(paused: bool) -> void:
	_paused = paused


func is_paused() -> bool:
	return _paused


## --- the weather -----------------------------------------------------------


## The weather in force RIGHT NOW, which during a cross-fade is whichever of the
## two states is more than half applied.
##
## Spawn conditions read this rather than the target, so a creature does not
## appear the instant the sky begins to close over — it appears when it is
## actually raining.
func weather() -> String:
	return _next if _blend >= 0.5 else _current


## What it is turning into. Equal to `weather()` when nothing is changing.
func weather_target() -> String:
	return _next


func weather_blend() -> float:
	return _blend


## Pin the weather, for testing and for the preview tool. Returns false for a
## state that data/config/weather.json does not define, rather than silently
## pinning nothing.
func force_weather(id: String) -> bool:
	if not (_config.get("states", {}) as Dictionary).has(id):
		push_warning("no weather state called '%s' in weather.json" % id)
		return false
	_forced = id
	_current = id
	_next = id
	_blend = 0.0
	_hold_left = _roll_hold(id)
	if _look != null:
		_look.call("release")
	_reset_rain()
	_announce()
	_push()
	return true


## Hand the weather back to the state machine.
func release_weather() -> void:
	_forced = ""
	_hold_left = _roll_hold(weather())


func weather_forced() -> bool:
	return not _forced.is_empty()


func states_available() -> Array:
	var found: Array = []
	for key: String in (_config.get("states", {}) as Dictionary).keys():
		if not key.begins_with("_"):
			found.append(key)
	return found


func _tick_weather(delta: float) -> void:
	if _blend > 0.0 or _next != _current:
		_blend = minf(1.0, _blend + delta / maxf(0.05, _blend_seconds))
		if _blend >= 1.0:
			_current = _next
			_blend = 0.0
			_hold_left = _roll_hold(_current)
		return

	if not _forced.is_empty():
		return

	_hold_left -= delta
	if _hold_left > 0.0:
		return
	var chosen := _choose(_phase, _current)
	if chosen == _current:
		# Nothing else was available. Wait rather than re-rolling every frame.
		_hold_left = _roll_hold(_current)
		return
	_begin_transition(chosen)


func _begin_transition(to: String) -> void:
	_next = to
	_blend = 0.0001
	_blend_seconds = maxf(0.05, float(_state(to).get("blend_seconds", 10.0)))
	_reset_rain()


## A weighted roll over the states, using the weights for this phase, with the
## state we are already in removed.
##
## Static and taking its table so `tests/test_weather.gd` can prove both rules
## that matter: that a phase with a zero weight never produces that state, and
## that the current state can never be chosen again. A re-roll into the same
## weather is indistinguishable from the timer not working, which is exactly the
## class of bug that survives a milestone.
static func choose_from(weights: Dictionary, current: String, roll: float) -> String:
	var total := 0.0
	for key: String in weights.keys():
		if key.begins_with("_") or key == current:
			continue
		total += maxf(0.0, float(weights[key]))
	if total <= 0.0:
		return current
	var at := clampf(roll, 0.0, 0.9999) * total
	for key: String in weights.keys():
		var weight := maxf(0.0, float(weights[key]))
		# A zero weight is skipped rather than subtracted. Subtracting it leaves
		# `at` unchanged, and a roll of exactly 0 then satisfies `at <= 0` on the
		# first entry it meets — which is how a state with weight 0 gets chosen.
		if weight <= 0.0 or key.begins_with("_") or key == current:
			continue
		at -= weight
		if at <= 0.0:
			return key
	return current


func _choose(for_phase: String, current: String) -> String:
	var table: Dictionary = _config.get("schedule", {}).get("weights", {})
	var weights: Dictionary = table.get(for_phase, table.get("day", {}))
	return choose_from(weights, current, _rng.randf())


func _state(id: String) -> Dictionary:
	return (_config.get("states", {}) as Dictionary).get(id, {}) as Dictionary


func _roll_hold(id: String) -> float:
	var span: Array = _state(id).get("hold_seconds", [60.0, 120.0])
	if span.size() < 2:
		return 60.0
	return _rng.randf_range(float(span[0]), float(span[1]))


## --- lightning -------------------------------------------------------------


func _tick_flash(delta: float) -> void:
	var cfg: Dictionary = _config.get("lightning", {})

	if _second_strike_in > 0.0:
		_second_strike_in -= delta
		if _second_strike_in <= 0.0:
			_strike(false)

	if _flash_rising:
		_flash = minf(1.0, _flash + delta / maxf(0.001, float(cfg.get("rise_seconds", 0.04))))
		if _flash >= 1.0:
			_flash_rising = false
	elif _flash > 0.0:
		_flash = maxf(0.0, _flash - delta / maxf(0.001, float(cfg.get("fall_seconds", 0.4))))

	var per_minute := float(_state(weather()).get("lightning_per_minute", 0.0))
	if per_minute <= 0.0:
		return
	if _rng.randf() < per_minute / 60.0 * delta:
		_strike(true)


func _strike(allow_double: bool) -> void:
	_flash = 0.0
	_flash_rising = true
	lightning_struck.emit()
	var cfg: Dictionary = _config.get("lightning", {})
	if allow_double and _rng.randf() < float(cfg.get("double_chance", 0.0)):
		_second_strike_in = float(cfg.get("fall_seconds", 0.4)) * 0.8


## Fire a strike now. For `tools/preview_weather.gd`, which has to photograph a
## flash and cannot wait for a 7-per-minute roll to land on the shutter.
func strike_lightning() -> void:
	_strike(false)


func flash() -> float:
	return _flash * float(_config.get("lightning", {}).get("strength", 0.75))


## --- rain ------------------------------------------------------------------
##
## CPUParticles3D, not GPU. The previews and the survey are forced onto the
## Compatibility renderer (D06) and CPU particles render identically in both
## pipelines, so what a critic judges is what ships. It also keeps rain away
## from everything D06 rules out: no depth read, no screen-space pass, no
## collision against the depth buffer, and therefore no splashes — which is
## recorded as absent rather than faked.


func _build_rain() -> void:
	# Nothing to draw and nothing to pay for when there is no display. The
	# headless smokes simulate tens of thousands of physics frames; a particle
	# system integrating 900 drops through all of them is pure cost.
	if DisplayServer.get_name() == "headless":
		return
	var cfg: Dictionary = _config.get("rain", {})
	var box: Array = cfg.get("box", [36.0, 3.0, 36.0])

	_rain = CPUParticles3D.new()
	_rain.name = "Rain"
	_rain.emitting = false
	_rain.visible = false
	# World space, so moving the emitter over the camera does not drag the drops
	# already in the air sideways with it.
	_rain.local_coords = false
	_rain.lifetime = float(cfg.get("lifetime", 1.1))
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(
		float(box[0]) * 0.5, float(box[1]) * 0.5, float(box[2]) * 0.5)
	_rain.direction = Vector3(0.0, -1.0, 0.0)
	# A few degrees of spread so the sheet is not a perfectly vertical comb.
	_rain.spread = float(cfg.get("spread_speed", 3.0))
	_rain.gravity = Vector3.ZERO
	_rain.initial_velocity_min = float(cfg.get("fall_speed", 27.0)) * 0.9
	_rain.initial_velocity_max = float(cfg.get("fall_speed", 27.0)) * 1.1

	var quad := QuadMesh.new()
	quad.size = Vector2(float(cfg.get("drop_width", 0.035)), float(cfg.get("drop_length", 0.62)))
	_rain.mesh = quad

	var colour := Color(str(cfg.get("colour", "#c6d8ea")))
	_rain_alpha = clampf(float(cfg.get("alpha", 0.42)), 0.0, 1.0)
	colour.a = _rain_alpha
	_rain.color = colour

	var material := StandardMaterial3D.new()
	# Unshaded, because a rain drop lit by a directional light in a rainstorm is
	# lit by nothing — and because shading 900 alpha quads is the one part of
	# this that would actually cost something on the handheld.
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	# The particle's own colour is what fades the sheet in and out, so it has to
	# reach the albedo.
	material.vertex_color_use_as_albedo = true
	material.albedo_color = colour
	material.disable_receive_shadows = true
	quad.material = material

	add_child(_rain)
	_reset_rain()


## How hard it is raining right now, 0..1-ish, blended across a weather change.
func rain_strength() -> float:
	var from := float(_state(_current).get("rain", 0.0))
	var to := float(_state(_next).get("rain", 0.0))
	return lerpf(from, to, clampf(_blend, 0.0, 1.0))


## Set the particle COUNT once per transition and fade with ALPHA in between.
##
## Writing `amount` restarts a CPUParticles3D, so ramping the count would
## restart the system every frame of a fade and produce a sheet of rain that
## flickers instead of one that arrives. The count is set to the heaviest of the
## two states involved and the fade is done in the colour, which costs nothing.
func _reset_rain() -> void:
	if _rain == null:
		return
	var cfg: Dictionary = _config.get("rain", {})
	var heaviest := maxf(
		float(_state(_current).get("rain", 0.0)), float(_state(_next).get("rain", 0.0)))
	var wanted := int(round(float(cfg.get("particles", 900)) * heaviest))
	if wanted == _rain_amount:
		return
	_rain_amount = wanted
	if wanted <= 0:
		_rain.emitting = false
		_rain.visible = false
		return
	_rain.amount = wanted
	_rain.visible = true
	_rain.emitting = true
	_rain.restart()


## Keep the emitter over whatever camera is current — the player's, the fight's,
## or a survey camera. Following the camera rather than the player is what keeps
## rain in frame during combat, when the camera is on the pal.
func _follow_rain() -> void:
	if _rain == null:
		return
	var strength := rain_strength()
	if strength <= 0.0:
		if _rain_amount != 0:
			_reset_rain()
		return
	if _rain_amount <= 0:
		_reset_rain()

	var camera := get_viewport().get_camera_3d()
	if camera != null:
		_rain.global_position = camera.global_position + Vector3(
			0.0, float(_config.get("rain", {}).get("height", 13.0)), 0.0)
	var colour: Color = _rain.color
	var heaviest := maxf(0.0001, float(_rain_amount) / maxf(1.0, float(
		_config.get("rain", {}).get("particles", 900))))
	colour.a = _rain_alpha * clampf(strength / heaviest, 0.0, 1.0)
	_rain.color = colour


## --- spawn conditions ------------------------------------------------------
##
## The whole of this node's contribution to §24's "rare pals can depend on
## habitat, time and weather". Habitat is already data/pals/spawns.json's
## distance bands; this is the other two axes, and it is a QUESTION a spawner
## can ask rather than an action taken here.


## 1.0 when this species' conditions are met, its `elsewhere` weight when they
## are not, and 1.0 for any species with no conditions at all.
func spawn_weight(species_id: String) -> float:
	var table: Dictionary = _config.get("spawn_conditions", {})
	if not table.has(species_id):
		return 1.0
	return weight_for(table[species_id] as Dictionary, phase(), weather())


## Would this species be in the world right now at all?
func allows_spawn(species_id: String) -> bool:
	return spawn_weight(species_id) > 0.0


## Every species whose conditions are met right now. For a log line, and for a
## spawner that would rather ask once than per species.
func species_in_season() -> Array:
	var found: Array = []
	for id: String in (_config.get("spawn_conditions", {}) as Dictionary).keys():
		if id.begins_with("_"):
			continue
		if spawn_weight(id) >= 1.0:
			found.append(id)
	return found


## The rule, as a pure function of a condition block and the two axes.
##
## Static so `tests/test_weather.gd` can prove the AND: the Palehorn declares
## both a phase list and a weather list, and a clear night and a rainy noon must
## both fail it. That is the case a table-driven check would most easily get
## wrong, and it is the one §24 actually asks for.
static func weight_for(condition: Dictionary, at_phase: String, in_weather: String) -> float:
	var met := true
	if condition.has("phases") and not (condition["phases"] as Array).has(at_phase):
		met = false
	if condition.has("weather") and not (condition["weather"] as Array).has(in_weather):
		met = false
	if met:
		return 1.0
	return maxf(0.0, float(condition.get("elsewhere", 0.0)))


## --- phases ----------------------------------------------------------------


## Which named stretch of the clock an hour falls in.
##
## Static, and handling the wrap explicitly, because exactly one phase crosses
## midnight and it is the one the nocturnal creatures depend on. A range check
## written as `from <= hour and hour < to` is correct for three of the four and
## silently empty for `night`.
static func phase_at(phases: Dictionary, at: float) -> String:
	at = fposmod(at, HOURS_PER_DAY)
	for name: String in phases.keys():
		if name.begins_with("_"):
			continue
		var span: Dictionary = phases[name]
		var from := float(span.get("from", 0.0))
		var to := float(span.get("to", 24.0))
		if from <= to:
			if at >= from and at < to:
				return name
		elif at >= from or at < to:
			return name
	return "day"


## --- driving the look ------------------------------------------------------


func _push() -> void:
	if _look == null:
		return
	_look.call("apply_moment", _hour, _current, _next, _blend, flash())


func _announce() -> void:
	var now_phase := phase_at(_config.get("phases", {}), _hour)
	var now_weather := weather()
	if now_phase == _announced_phase and now_weather == _announced_weather:
		return
	var was_weather := _announced_weather
	_phase = now_phase
	if now_phase != _announced_phase:
		_announced_phase = now_phase
		phase_changed.emit(now_phase, _hour)
	if now_weather != _announced_weather:
		_announced_weather = now_weather
		weather_changed.emit(now_weather, was_weather)
	conditions_changed.emit(now_phase, now_weather)


func _load() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("no weather config at %s; the sky will not move" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## One line, for a boot log or an evidence session.
func describe() -> String:
	return "%02d:%02d  %s  %s%s" % [
		int(_hour), int(fposmod(_hour, 1.0) * 60.0), _phase, weather(),
		"  (forced)" if weather_forced() else ""
	]

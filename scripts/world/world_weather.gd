extends Node

## M10 / R5.2: weather variants -- rain, fog, an overcast "cloudy" look, and
## "clear" (no override) -- layered on top of whatever world_look.gd's active
## time-of-day preset already set. See data/config/weather.json for the
## tunable numbers and docs/GAME_DESIGN.md §24 for the full weather list this
## slice draws from (thunderstorms are explicitly out of scope here).
##
## Kept as its own node rather than folded into world_look.gd: weather is an
## independent axis from time of day (a rainy noon and a clear noon share the
## same sun angle), and world_look.gd already owns the merge/apply mechanism
## this reuses through its set_weather() entry point rather than duplicating
## it.
##
## Cycles on a randomised real-time timer so the meadow does not sit in one
## weather state forever -- R5.3 (spawn conditions) reads `weather()` through
## GROUP below to gate wild spawns on the active state.

const CONFIG_PATH := "res://data/config/weather.json"

## Reachable by group, not NodePath -- the same decoupled pattern
## world_look.gd's GROUP ("day_cycle") already uses, so encounter_director.gd
## can read the active weather without the scene wiring a path to this node.
const GROUP := "weather"

## Metres above the player the rain emitter is centred, and its shape: a RING
## in the XZ plane, not a box. A first render (R5.2's own required blind pass)
## put rain in a box centred on the player with the camera sitting well
## inside it -- `camera_rig.gd`'s spring arm holds the camera only ~5.8m from
## the player (spring_length 5.2 + margin 0.6), so the nearest raindrops
## could spawn less than a metre from the lens and blow up to fill the frame
## in perspective, one of them reading as "drawn at the wrong depth" straight
## through the trainer. `RAIN_INNER_RADIUS` keeps the whole emission volume
## outside the camera's normal orbit instead, the same fix most third-person
## rain rigs use. TUNABLE.
const RAIN_HEIGHT_OFFSET := 6.0
const RAIN_INNER_RADIUS := 6.5
const RAIN_OUTER_RADIUS := 13.0
const RAIN_RING_HEIGHT := 14.0
const RAIN_AMOUNT := 500
const RAIN_LIFETIME := 1.4
const RAIN_FALL_SPEED := 13.0
const RAIN_COLOUR := Color(0.75, 0.82, 0.88, 0.4)

@export var look_path: NodePath
@export var player_path: NodePath

var _config: Dictionary = {}
var _presets: Dictionary = {}
var _order: Array = []
var _weather: String = "clear"
var _rng := RandomNumberGenerator.new()
var _cycle_timer: float = 0.0
var _next_change_at: float = 60.0
var _rain: GPUParticles3D = null

## OP21-21: how many weather cycles in a row have landed away from "clear".
## Reset to 0 whenever "clear" is picked or forced. See
## `max_consecutive_non_clear` in weather.json and `_pick_next()` below.
var _consecutive_non_clear: int = 0


func _ready() -> void:
	add_to_group(GROUP)
	_config = _load()
	_presets = _config.get("presets", {})
	for key: String in _presets.keys():
		if not key.begins_with("_"):
			_order.append(key)
	if _presets.is_empty():
		push_warning("weather.json missing or unreadable; weather stays clear")
		return

	_rain = _build_rain()
	add_child(_rain)

	_rng.randomize()
	_queue_next_change()
	set_weather("clear" if _presets.has("clear") else _order[0])


func _process(delta: float) -> void:
	_follow_player()

	if _order.size() <= 1:
		return
	_cycle_timer += delta
	if _cycle_timer < _next_change_at:
		return
	_cycle_timer = 0.0
	_queue_next_change()
	set_weather(_pick_next())


func weather() -> String:
	return _weather


## Also callable directly -- tools/capture_weather.gd (the blind-pass capture
## harness) and any future debug toggle both want a named state on demand,
## not just the random cycle.
func set_weather(name: String) -> void:
	if not _presets.has(name):
		name = "clear"
	_weather = name
	var preset: Dictionary = _presets.get(name, {})

	# OP21-21: track how many cycles in a row have NOT been clear, so
	# _pick_next() can force a return to clear before a run of grey-ish
	# presets (fog, then rain, then cloudy, ...) reads as sustained rather
	# than as weather. Tracked here rather than only in _pick_next() so it
	# stays correct no matter who calls set_weather() -- the random cycle,
	# survey.gd/capture_weather.gd forcing a named preset, or a future debug
	# toggle.
	if name == "clear":
		_consecutive_non_clear = 0
	else:
		_consecutive_non_clear += 1

	var look: Node = get_node_or_null(look_path)
	if look != null and look.has_method("set_weather"):
		look.call("set_weather", preset)

	if _rain != null:
		var raining := bool(preset.get("rain", false))
		_rain.emitting = raining
		_rain.visible = raining


## OP21-21: a weighted roll (weather.json's per-preset `weight`, default 1.0)
## instead of the old uniform pick across all four presets -- a uniform roll
## put a washed-out preset on screen 75% of the time. Also enforces
## `max_consecutive_non_clear`: once that many cycles in a row have landed
## away from "clear", the next roll is forced back to "clear" regardless of
## weight, so a bad-luck run of grey-ish presets cannot chain indefinitely.
func _pick_next() -> String:
	var cap := int(_config.get("max_consecutive_non_clear", 2))
	if cap > 0 and _consecutive_non_clear >= cap and _presets.has("clear"):
		return "clear"

	var total := 0.0
	for key: String in _order:
		total += maxf(0.0, float(_presets.get(key, {}).get("weight", 1.0)))
	if total <= 0.0:
		return _order[_rng.randi_range(0, _order.size() - 1)]

	var roll := _rng.randf_range(0.0, total)
	var acc := 0.0
	for key: String in _order:
		acc += maxf(0.0, float(_presets.get(key, {}).get("weight", 1.0)))
		if roll <= acc:
			return key
	return _order[_order.size() - 1]


func _queue_next_change() -> void:
	var lo := float(_config.get("cycle_seconds_min", 240.0))
	var hi := maxf(lo, float(_config.get("cycle_seconds_max", 480.0)))
	_next_change_at = _rng.randf_range(lo, hi)


## Only translation follows the player, never rotation -- the box's local
## axes have to stay aligned with world axes or "straight down" stops meaning
## straight down. A snap rather than a smooth chase: rain has no reason to
## lag behind the player the way a physical follower would.
func _follow_player() -> void:
	if _rain == null:
		return
	var player: Node3D = get_node_or_null(player_path) as Node3D
	if player == null:
		return
	_rain.global_position = player.global_position + Vector3(0.0, RAIN_HEIGHT_OFFSET, 0.0)


## Straight-down streaks in a box around the player, same procedural-material
## pattern vegetation_harvest_point.gd already uses for its sparkle motes --
## no new texture asset, everything built in code. `local_coords = true` so
## the ring's own position (re-snapped to the player every frame in
## _follow_player) IS the simulation space; already-falling drops shift with
## it, which is the standard cheap approximation for camera-following rain
## and imperceptible at this emitter size against one frame of player
## movement.
func _build_rain() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Rain"
	particles.amount = RAIN_AMOUNT
	particles.lifetime = RAIN_LIFETIME
	particles.preprocess = RAIN_LIFETIME
	particles.local_coords = true
	particles.emitting = false
	particles.visible = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Own AABB, generous enough for the ring's own outer radius plus the
	# streak mesh's extent -- without this, culling can drop the whole
	# emitter the moment its origin (the player's head height) leaves the
	# camera frustum, even though most of the ring is still on screen.
	var reach := RAIN_OUTER_RADIUS + 1.0
	particles.visibility_aabb = AABB(
		Vector3(-reach, -RAIN_RING_HEIGHT * 0.5 - 1.0, -reach),
		Vector3(reach, RAIN_RING_HEIGHT + 2.0, reach) * 2.0
	)

	var process_material := ParticleProcessMaterial.new()
	# A ring, not a box: excludes a cylinder around the emitter's own origin
	# (which _follow_player keeps centred on the player, and the gameplay
	# camera never sits more than ~5.8m from) so no raindrop can ever spawn
	# close enough to the lens to blow up to frame-filling size in
	# perspective. R5.2's own required blind pass caught exactly that with
	# the old box shape -- see this function's header.
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	process_material.emission_ring_axis = Vector3.UP
	process_material.emission_ring_height = RAIN_RING_HEIGHT
	process_material.emission_ring_radius = RAIN_OUTER_RADIUS
	process_material.emission_ring_inner_radius = RAIN_INNER_RADIUS
	process_material.direction = Vector3(0.0, -1.0, 0.0)
	process_material.spread = 2.0
	process_material.gravity = Vector3.ZERO
	process_material.initial_velocity_min = RAIN_FALL_SPEED * 0.9
	process_material.initial_velocity_max = RAIN_FALL_SPEED * 1.1
	process_material.scale_min = 0.85
	process_material.scale_max = 1.0
	process_material.color = RAIN_COLOUR
	particles.process_material = process_material

	# A thin vertical box rather than a flat quad: BILLBOARD_ENABLED would
	# always face the camera, which reads as falling snow, not rain -- a
	# streak has to keep its own orientation (aligned to the fall direction)
	# regardless of where the camera is. Ordinary alpha blend rather than
	# additive: the first render's blind pass read additive's glow-through
	# look as a rendering bug rather than water -- real rain streaks are a
	# faint, mostly-transparent line, not a light source.
	var streak := BoxMesh.new()
	streak.size = Vector3(0.015, 0.4, 0.015)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.vertex_color_use_as_albedo = true
	material.albedo_color = RAIN_COLOUR
	streak.material = material
	particles.draw_pass_1 = streak

	return particles


func _load() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

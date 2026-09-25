extends "res://scripts/world/world_weather.gd"

## Realm-scoped WorldWeather extension. Only the host advances the persistent
## cycle; Session carries snapshots across scene changes and to late joiners.
##
## F10 phase readability (WORLD §5.2, ART_DIRECTION §3.3/§4): Calm, Building,
## Break and Fading must be nameable from light and motion without HUD text,
## and the Long Storm aftermath must open the sky. Every per-phase value lives
## in data/config/stormwood_surge.json `presentation`; this node only applies
## it: the WorldLook weather layer (sun, sky gradient, fog, ambient), its own
## rain emitter, a realm-local storm ceiling dome and Break's flash rhythm.
const RULES := preload("res://scripts/world/stormwood_surge_rules.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const LONG_STORM_ENDED := "stormwood:long_storm_ended"

## The overcast ceiling. A dome rather than the shared sky shader because
## WorldLook's weather layer can recolour the sky gradient but not its clouds,
## and the painted day cumulus stays white and sunlit under any gradient. The
## dome sits between the sky and the world, follows the camera, fades to
## nothing at the horizon and is fully transparent in the aftermath's Calm, so
## the art.json sky it covers is exactly the "restored sky".
const CEILING_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, fog_disabled, shadows_disabled;
uniform vec3 ceiling_colour : source_color = vec3(0.4);
uniform float opacity = 0.0;
uniform float cloud_time = 0.0;
uniform float contrast = 0.3;
uniform float breakup = 0.0;
uniform float flash = 0.0;
uniform vec3 flash_colour : source_color = vec3(0.9, 0.86, 1.0);
varying vec3 dir;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 5; k++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
void vertex() { dir = normalize(VERTEX); }
void fragment() {
	float up = clamp(dir.y, 0.0, 1.0);
	vec2 uv = dir.xz / (up + 0.18) * 1.4;
	// cloud_time is accumulated by the script (speed x delta), so speed
	// changes cross-fade smoothly and there is no periodic wrap jump.
	float t = cloud_time;
	float n = fbm(uv + vec2(t, t * 0.35));
	float m = fbm(uv * 2.2 - vec2(t * 1.6, t * 0.2));
	float body = clamp(n * 0.75 + m * 0.35, 0.0, 1.0);
	vec3 colour = ceiling_colour * mix(1.0 - contrast, 1.0 + contrast * 0.6, body);
	colour += flash_colour * flash * (0.35 + 0.9 * body);
	ALBEDO = colour;
	// Opaque almost down to eye level: the art.json sky's lit cumulus band
	// must not show under a storm ceiling.
	// `breakup` opens gaps where the cloud body is thin (Fading's clearing).
	float gaps = breakup > 0.0 ? smoothstep(breakup - 0.12, breakup + 0.12, body) : 1.0;
	ALPHA = opacity * smoothstep(0.0, 0.07, dir.y) * mix(0.88, 1.0, body) * gaps;
}
"""

var rules := RULES.new()
var world: Node3D
var phase := "calm"
var sheltered := false
var _glyph: Label
var _local := false
var _last_phase := ""
var _shelter_check_left := 0.0

var _aftermath := false
var _ceiling: MeshInstance3D
var _ceiling_material: ShaderMaterial
var _flash_light: DirectionalLight3D
## Cross-fade between presentations. `_to` is the target row as authored
## (daylight colours); `_from` is the FINAL on-screen values (already night
## scaled) captured when the target changed; `_blend` runs 0..1 over
## `transition_seconds`. See _current().
var _from: Dictionary = {}
var _to: Dictionary = {}
var _blend := 1.0
var _reapply_left := 0.0
var _last_night_scale := -1.0
var _last_base: Dictionary = {"night_scale": 1.0}
var _dirty := true
var _cloud_time := 0.0
var _rain_far: GPUParticles3D
var _flash := 0.0
var _flash_next := 0.0
var _flash_echo := -1.0
var _flash_rng := RandomNumberGenerator.new()

func _ready() -> void:
	world = get_parent() as Node3D
	_local = not bool(world.get("simulation_only"))
	player_path = NodePath("../Player")
	look_path = NodePath("../WorldLook")
	add_to_group(GROUP)
	if _local:
		_rain = _build_rain()
		_style_rain()
		add_child(_rain)
		_rain.emitting = true
		_build_ceiling()
		_build_flash_light()
		_flash_rng.randomize()
		var layer := CanvasLayer.new()
		layer.name = "SurgeStatus"
		add_child(layer)
		_glyph = Label.new()
		_glyph.position = Vector2(24, 150)
		_glyph.add_theme_color_override("font_color", Color("c3ddff"))
		_glyph.add_theme_color_override("font_outline_color", Color("14202a"))
		_glyph.add_theme_constant_override("outline_size", 5)
		layer.add_child(_glyph)

func _process(delta: float) -> void:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	var state: Dictionary = game.get("realm_environment")
	var saved: Variant = state.get("stormwood", {})
	var storm: Dictionary = saved.duplicate(true) if saved is Dictionary else {}
	var raw: Variant = storm.get("elapsed", 0.0)
	var elapsed := float(raw) if (raw is float or raw is int) and is_finite(float(raw)) else 0.0
	var session := get_node_or_null("/root/Game/Session")
	if session == null or bool(session.call("is_host")):
		elapsed = maxf(0.0, elapsed) + delta
		storm["elapsed"] = elapsed
		storm["schema_version"] = 1
		state["stormwood"] = storm
		game.set("realm_environment", state)
	if not _local:
		return
	_follow_player()
	var player := world.get_node("Player") as Node3D
	var region := region_at(player.global_position)
	var flags: RefCounted = game.get("progression")
	phase = phase_at_position(player.global_position)
	_aftermath = flags.has(LONG_STORM_ENDED)
	var lightning := world.get_node_or_null("StormwoodLightning")
	_shelter_check_left -= delta
	if _shelter_check_left <= 0.0:
		_shelter_check_left = 0.25
		sheltered = lightning.sheltered(player.global_position, player) if lightning != null else rules.sheltered(player.global_position, region, false)
	_glyph.text = "⚡ %s%s" % [phase.capitalize(), " · Sheltered" if sheltered else ""]
	var key := presentation_key()
	if key != _last_phase:
		_last_phase = key
		_begin_transition()
	_advance_presentation(delta)
	_advance_flash(delta)
	if phase == "break" and sheltered and region == "cinder_verge":
		var chapter := world.get_node_or_null("StormwoodChapter")
		if chapter != null and not flags.has("stormwood:first_break_witnessed"):
			chapter.call("emit_event", "surge:tutorial_break")

func region_at(at: Vector3) -> String:
	# Crown overlaps the Conductor Run in Z, so test the island first.
	if Vector2(at.x - 700, at.z - 2700).length() < 245 and at.y > 50:
		return "hollow_crown"
	for region: Dictionary in world.call("config_data").get("regions", []):
		var bounds: Dictionary = region.bounds
		if at.x >= float(bounds.min_x) and at.x <= float(bounds.max_x) and at.z >= float(bounds.min_z) and at.z <= float(bounds.max_z):
			return str(region.id)
	return "cinder_verge"

func weather() -> String:
	return "storm" if phase == "break" else "rain"

func charged_nodes_open() -> bool:
	return rules.charged_nodes_open(phase)

## Queries use the shared host clock and the target's region, including when
## this node is a simulation shell with no local player presentation.
func phase_at_position(at: Vector3) -> String:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return "calm"
	var environment: Dictionary = game.get("realm_environment")
	var saved: Variant = environment.get("stormwood", {})
	var raw: Variant = saved.get("elapsed", 0.0) if saved is Dictionary else 0.0
	var elapsed := maxf(0.0, float(raw)) if (raw is float or raw is int) and is_finite(float(raw)) else 0.0
	var region := region_at(at)
	var flags: RefCounted = game.get("progression")
	var rod_flag := str(rules.config.regions.get(region, {}).get("rod_flag", ""))
	return str(rules.phase_at(elapsed, region, not rod_flag.is_empty() and flags.has(rod_flag), flags.has(LONG_STORM_ENDED)).phase)

func charged_nodes_open_at(at: Vector3) -> bool:
	return rules.charged_nodes_open(phase_at_position(at))

# ------------------------------------------------------------ presentation

func presentation_key() -> String:
	return ("aftermath:" if _aftermath else "") + phase

func _pres_cfg() -> Dictionary:
	return rules.config.get("presentation", {})

## One phase's presentation row: `presentation.phases[phase]`, with
## `presentation.aftermath[phase]` merged over it once the Long Storm has
## ended. `shadow_opacity` stays in its own authored block.
func presentation_for(for_phase: String, aftermath: bool = false) -> Dictionary:
	var block := _pres_cfg()
	var row: Dictionary = (block.get("phases", {}).get(for_phase, {}) as Dictionary).duplicate(true)
	if aftermath:
		var over: Dictionary = block.get("aftermath", {}).get(for_phase, {})
		for key: String in over:
			row[key] = over[key]
	row["shadow_opacity"] = float(block.get("shadow_opacity", {}).get(for_phase, 1.0))
	return row

## The WorldLook weather delta for a phase against a time-of-day `base` (as
## _base_look() returns it; the default is plain daylight). A row with no
## `sky_top` (the aftermath's Calm) leaves the art.json sky untouched.
func light_delta_for_phase(for_phase: String, aftermath: bool = false, base: Dictionary = {}) -> Dictionary:
	var b := base if not base.is_empty() else {"night_scale": 1.0}
	return _delta_from(_final(_resolved(presentation_for(for_phase, aftermath)), b))

const _COLOUR_KEYS := ["ambient_colour", "sky_top", "sky_horizon", "sky_ground_horizon", "ceiling_colour"]
const _NUMBER_KEYS := ["sun_energy_mult", "shadow_opacity", "ambient_energy_mult", "fog_density_add",
	"ceiling_opacity", "ceiling_speed", "ceiling_contrast", "ceiling_breakup", "rain_amount"]

## Authored row → typed values, still in authored (daylight) colours.
func _resolved(row: Dictionary) -> Dictionary:
	var defaults := {"sun_energy_mult": 1.0, "shadow_opacity": 1.0, "ambient_energy_mult": 1.0,
		"ceiling_contrast": 0.3}
	var out := {}
	for key: String in _NUMBER_KEYS:
		out[key] = float(row.get(key, defaults.get(key, 0.0)))
	out["rain_visible"] = bool(row.get("rain_visible", false))
	out["flashes"] = bool(row.get("flashes", false))
	for key: String in _COLOUR_KEYS:
		if row.has(key) and row[key] != null:
			out[key] = Color(str(row[key]))
	return out

## Authored colours → on-screen colours for this time of day. Applied ONCE,
## to authored storm colours only, before any cross-fade, so a fade that
## passes through the native (base) sky never scales that base a second time.
##
## - sky_* and ceiling: × night_scale (the live sky top's luminance over the
##   day preset's), so a daylight storm sky never glows over the night.
## - ambient: the storm hue at no more than the native ambient's value for
##   this hour. A storm never adds fill light over clear weather, so night
##   ground ambient never rises above art.json's own (SYSTEMS §9: no blanket
##   night brightening; art.json: the sky sits above the land in value).
func _final(p: Dictionary, base: Dictionary) -> Dictionary:
	var out := p.duplicate()
	var k := clampf(float(base.get("night_scale", 1.0)), 0.0, 1.0)
	for key: String in ["sky_top", "sky_horizon", "sky_ground_horizon", "ceiling_colour"]:
		if out.has(key):
			var c: Color = out[key]
			out[key] = Color(c.r * k, c.g * k, c.b * k)
	# Night readability (ART_DIRECTION: night keeps the trainer and route
	# readable) is art.json's night tuning; a storm neither lifts nor sinks
	# it, so the phase's ambient- and sun-energy cuts release toward 1.0 as
	# night falls (squared, so they hold through dusk). At night the phases
	# read from sky, ceiling, rain and flash instead.
	var floor_k := float(_pres_cfg().get("night_scale_floor", 0.12))
	var day_t := clampf((k - floor_k) / maxf(0.001, 1.0 - floor_k), 0.0, 1.0)
	out["ambient_energy_mult"] = lerpf(1.0, float(out.get("ambient_energy_mult", 1.0)), day_t * day_t)
	# Same for the key light: at night it is art.json's moonlight, which
	# carries the trainer/route read; the storm's daytime sun cut releases.
	out["sun_energy_mult"] = lerpf(1.0, float(out.get("sun_energy_mult", 1.0)), day_t * day_t)
	out["night_scale"] = k
	if out.has("ambient_colour") and base.has("ambient_colour"):
		var storm: Color = out.ambient_colour
		var native: Color = base.ambient_colour
		var dim := minf(1.0, native.get_luminance() / maxf(0.001, storm.get_luminance()))
		out["ambient_colour"] = Color(storm.r * dim, storm.g * dim, storm.b * dim)
	return out

## WorldLook delta from on-screen values. No scaling happens here.
func _delta_from(p: Dictionary) -> Dictionary:
	var delta := {
		"sun": {"energy_mult": p.sun_energy_mult, "shadow_opacity": p.shadow_opacity},
		"environment": {
			"ambient_energy_mult": p.ambient_energy_mult,
			"fog_density_add": p.fog_density_add,
		},
	}
	if p.has("ambient_colour"):
		delta.environment["ambient_colour"] = "#" + (p.ambient_colour as Color).to_html(false)
	if p.has("sky_top"):
		var sky := {}
		for pair: Array in [["sky_top", "top_colour"], ["sky_horizon", "horizon_colour"], ["sky_ground_horizon", "ground_horizon_colour"]]:
			if p.has(pair[0]):
				sky[pair[1]] = "#" + (p[pair[0]] as Color).to_html(false)
		delta["sky"] = sky
		# art.json's CRITICAL rule: with fog_sky_affect 0, fog must equal the
		# horizon colour or distant terrain seams against the sky.
		if sky.has("horizon_colour"):
			delta.environment["fog_colour"] = sky.horizon_colour
	return delta

## Blend two on-screen rows. A colour present on only one side (the storm sky
## against the aftermath's untouched sky) cross-fades through the native
## `base` colour, which is already on-screen and is not scaled again.
func _mix(a: Dictionary, b: Dictionary, t: float, base: Dictionary) -> Dictionary:
	if t >= 1.0:
		return b
	var out := {}
	for key: String in _NUMBER_KEYS:
		out[key] = lerpf(float(a.get(key, 0.0)), float(b.get(key, 0.0)), t)
	out["rain_visible"] = bool(a.get("rain_visible", false)) or bool(b.get("rain_visible", false))
	out["flashes"] = bool(b.get("flashes", false))
	out["night_scale"] = float(b.get("night_scale", a.get("night_scale", 1.0)))
	for key: String in _COLOUR_KEYS:
		if not a.has(key) and not b.has(key):
			continue
		var ca: Color = a.get(key, base.get(key, b.get(key, Color.GRAY)))
		var cb: Color = b.get(key, base.get(key, a.get(key, Color.GRAY)))
		out[key] = ca.lerp(cb, t)
	return out

## What is on screen now for `base`.
func _current(base: Dictionary) -> Dictionary:
	var target := _final(_to, base)
	return target if _blend >= 1.0 else _mix(_from, target, _blend, base)

## The current time-of-day sky/ambient from WorldLook (read-only), used as
## the fade-through colour and to derive `night_scale`.
func _base_look() -> Dictionary:
	var look := world.get_node_or_null("WorldLook") if world != null else null
	if look == null:
		return {"night_scale": 1.0}
	var config: Variant = look.get("_config")
	var cycle: Variant = look.get("_cycle")
	if not config is Dictionary or (config as Dictionary).is_empty() or cycle == null:
		return {"night_scale": 1.0}
	return base_look_at(config, cycle, float(look.call("hour")))

## `_base_look()` for an explicit art config, day cycle and hour (tests use
## the real art.json and day_cycle.gd at night/dusk/dawn hours).
func base_look_at(config: Dictionary, cycle: RefCounted, hour: float) -> Dictionary:
	var now: Dictionary = WORLD_LOOK.blended_config_at(config, cycle, hour)
	var day_sky: Dictionary = WORLD_LOOK._merged_from(config, "sky", WORLD_LOOK._preset_over(config, "day"))
	var sky_now: Dictionary = now.get("sky", {})
	var env_now: Dictionary = now.get("environment", {})
	var top_now := _colour(sky_now.get("top_colour"), "#3b6f93")
	var top_day := _colour(day_sky.get("top_colour"), "#3b6f93")
	var floor_scale := float(_pres_cfg().get("night_scale_floor", 0.12))
	return {
		"night_scale": clampf(top_now.get_luminance() / maxf(0.001, top_day.get_luminance()), floor_scale, 1.0),
		"sky_top": top_now,
		"sky_horizon": _colour(sky_now.get("horizon_colour"), "#a6bccb"),
		"sky_ground_horizon": _colour(sky_now.get("ground_horizon_colour"), "#b9c8cf"),
		"ambient_colour": _colour(env_now.get("ambient_colour"), "#9db3c6"),
		"ceiling_colour": top_now,
	}

## WorldLook's blended config carries Color values; art.json carries hex.
static func _colour(value: Variant, fallback: String) -> Color:
	if value is Color:
		return value
	return Color.from_string(str(value), Color(fallback)) if value != null else Color(fallback)

func _begin_transition() -> void:
	var target := _resolved(presentation_for(phase, _aftermath))
	if _to.is_empty():
		_to = target
		_blend = 1.0
	else:
		_from = _current(_last_base)
		_to = target
		_blend = 0.0
	_reapply_left = 0.0
	_dirty = true

## Snap to the current phase's look with no cross-fade (capture tools and
## tests; also what a first frame after a scene load does anyway).
func settle_presentation() -> void:
	_to = _resolved(presentation_for(phase, _aftermath))
	_blend = 1.0
	_last_phase = presentation_key()
	_last_night_scale = -1.0
	_apply_current(true)

func _advance_presentation(delta: float) -> void:
	if _to.is_empty():
		return
	var cfg := _pres_cfg()
	var seconds := float(cfg.get("transition_seconds", 6.0))
	var blending := _blend < 1.0
	if blending:
		_blend = minf(1.0, _blend + delta / maxf(0.01, seconds))
		_dirty = true
	var shown := _current(_last_base)
	_cloud_time += delta * float(shown.get("ceiling_speed", 0.0))
	_reapply_left -= delta
	if _reapply_left > 0.0:
		_update_ceiling(shown)
		return
	# The WorldLook layer re-merges its whole look per call, so it is paced.
	_reapply_left = float(cfg.get("reapply_fading_seconds", 0.2)) if blending else float(cfg.get("reapply_steady_seconds", 2.0))
	_apply_current(_dirty)

func _apply_current(force: bool) -> void:
	var base := _base_look()
	_last_base = base
	var scale := float(base.night_scale)
	var current := _current(base)
	_update_ceiling(current)
	if not force and absf(scale - _last_night_scale) < 0.01:
		return
	_last_night_scale = scale
	_dirty = false
	var look := world.get_node_or_null("WorldLook") if world != null else null
	if look != null:
		look.call("set_weather", _delta_from(current))
	_update_rain(current)

## Apply the current phase immediately (kept for existing callers/tests).
func _apply_phase_light() -> void:
	_to = _resolved(presentation_for(phase, _aftermath))
	_blend = 1.0
	_last_night_scale = -1.0
	_apply_current(true)

func _update_rain(p: Dictionary) -> void:
	if _rain == null:
		return
	# world_weather.gd builds its emitter hidden; Stormwood owns its own
	# instance and must show it whenever the phase rains.
	_rain.visible = bool(p.rain_visible) and float(p.rain_amount) > 0.0
	_rain.emitting = _rain.visible
	_rain.amount_ratio = clampf(float(p.rain_amount), 0.0, 1.0)
	if _rain_far != null:
		_rain_far.emitting = _rain.visible
		_rain_far.amount_ratio = _rain.amount_ratio
	# The streaks are unshaded, so they would glow on a dark night: their
	# tint follows the night factor down to presentation.rain.night_floor.
	var cfg: Dictionary = _pres_cfg().get("rain", {})
	var shade := maxf(float(cfg.get("night_floor", 0.3)), float(p.get("night_scale", 1.0)))
	_tint_emitter(_rain, cfg, shade)
	if _rain_far != null:
		var far_cfg := cfg.duplicate()
		for key: String in cfg.get("far_layer", {}):
			far_cfg[key] = cfg.far_layer[key]
		_tint_emitter(_rain_far, far_cfg, shade)

func _tint_emitter(emitter: GPUParticles3D, cfg: Dictionary, shade: float) -> void:
	var process := emitter.process_material as ParticleProcessMaterial
	if process == null or cfg.is_empty():
		return
	var colour := Color(str(cfg.get("colour", "#c0ccd6")))
	process.color = Color(colour.r * shade, colour.g * shade, colour.b * shade, float(cfg.get("alpha", 0.4)))

## Stormwood's rain is heavier than the Meadows preset it shares a builder
## with. Streak size, tint and per-drop variation (J3: size and alpha
## randomness) of this realm's own emitter come from presentation.rain, plus
## a cheap second, farther and fainter layer so streaks are not one uniform
## length and depth. world_weather.gd's constants stay the Meadows look.
func _style_rain() -> void:
	var cfg: Dictionary = _pres_cfg().get("rain", {})
	if _rain == null or cfg.is_empty():
		return
	_style_emitter(_rain, cfg)
	var far: Dictionary = cfg.get("far_layer", {})
	if not far.is_empty():
		_rain_far = _build_rain()
		_rain_far.name = "RainFar"
		var merged := cfg.duplicate()
		for key: String in far:
			merged[key] = far[key]
		_style_emitter(_rain_far, merged)
		var ring := _rain_far.process_material as ParticleProcessMaterial
		if ring != null:
			ring.emission_ring_inner_radius = float(far.get("inner_radius_m", 13.0))
			ring.emission_ring_radius = float(far.get("outer_radius_m", 26.0))
			var reach := ring.emission_ring_radius + 1.0
			_rain_far.visibility_aabb = AABB(Vector3(-reach, -RAIN_RING_HEIGHT * 0.5 - 1.0, -reach),
				Vector3(reach, RAIN_RING_HEIGHT + 2.0, reach) * 2.0)
		_rain_far.visible = true
		_rain.add_child(_rain_far)

func _style_emitter(emitter: GPUParticles3D, cfg: Dictionary) -> void:
	var colour := Color(str(cfg.get("colour", "#c0ccd6")))
	colour.a = float(cfg.get("alpha", 0.4))
	var streak := emitter.draw_pass_1 as BoxMesh
	if streak != null:
		var width := float(cfg.get("streak_width_m", 0.015))
		streak.size = Vector3(width, float(cfg.get("streak_length_m", 0.4)), width)
		var material := streak.material as StandardMaterial3D
		if material != null:
			# Tint and alpha come from the particle colour alone, so the
			# per-drop alpha ramp below is not multiplied twice.
			material.albedo_color = Color.WHITE
	var process := emitter.process_material as ParticleProcessMaterial
	if process != null:
		process.color = colour
		process.scale_min = float(cfg.get("scale_min", 0.85))
		process.scale_max = float(cfg.get("scale_max", 1.0))
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, float(cfg.get("alpha_min_fraction", 1.0))))
		gradient.set_color(1, Color.WHITE)
		var ramp := GradientTexture1D.new()
		ramp.gradient = gradient
		process.color_initial_ramp = ramp
	emitter.amount = int(cfg.get("max_drops", emitter.amount))

func _update_ceiling(p: Dictionary) -> void:
	if _ceiling_material == null:
		return
	var colour: Color = p.get("ceiling_colour", _last_base.get("ceiling_colour", Color.GRAY))
	_ceiling_material.set_shader_parameter("ceiling_colour", colour)
	_ceiling_material.set_shader_parameter("opacity", float(p.get("ceiling_opacity", 0.0)))
	_ceiling_material.set_shader_parameter("cloud_time", _cloud_time)
	_ceiling_material.set_shader_parameter("contrast", float(p.get("ceiling_contrast", 0.3)))
	_ceiling_material.set_shader_parameter("breakup", float(p.get("ceiling_breakup", 0.0)))
	_ceiling.visible = float(p.get("ceiling_opacity", 0.0)) > 0.001

func _build_ceiling() -> void:
	var cfg: Dictionary = _pres_cfg().get("ceiling", {})
	var shader := Shader.new()
	shader.code = CEILING_SHADER
	_ceiling_material = ShaderMaterial.new()
	_ceiling_material.shader = shader
	# Drawn before every other transparent (rain, telegraph rings), so it
	# can never be blended over something nearer.
	_ceiling_material.render_priority = Material.RENDER_PRIORITY_MIN
	var flash: Dictionary = _pres_cfg().get("flash", {})
	_ceiling_material.set_shader_parameter("flash_colour", Color(str(flash.get("colour", "#e6dcff"))))
	var radius := float(cfg.get("radius_m", 2400.0))
	var dome := SphereMesh.new()
	dome.radius = radius
	dome.height = radius
	dome.is_hemisphere = true
	dome.radial_segments = 32
	dome.rings = 12
	_ceiling = MeshInstance3D.new()
	_ceiling.name = "StormCeiling"
	_ceiling.mesh = dome
	_ceiling.material_override = _ceiling_material
	_ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ceiling.extra_cull_margin = 16384.0
	_ceiling.visible = false
	add_child(_ceiling)

func _build_flash_light() -> void:
	var flash: Dictionary = _pres_cfg().get("flash", {})
	var angle: Array = flash.get("light_rotation_deg", [-72.0, 30.0])
	_flash_light = DirectionalLight3D.new()
	_flash_light.name = "StormFlash"
	_flash_light.light_color = Color(str(flash.get("colour", "#e6dcff")))
	_flash_light.light_energy = 0.0
	_flash_light.shadow_enabled = false
	_flash_light.rotation_degrees = Vector3(float(angle[0]), float(angle[1]), 0.0)
	_flash_light.visible = false
	add_child(_flash_light)

## Rain follows the player; the ceiling follows the camera so its horizon
## fade stays level with the eye.
func _follow_player() -> void:
	super._follow_player()
	if _ceiling != null:
		var camera := get_viewport().get_camera_3d()
		if camera != null:
			_ceiling.global_position = camera.global_position

# ------------------------------------------------------------ flash rhythm

## Current flash intensity 0..1 (capture tools read it).
func flash_level() -> float:
	return _flash

## A white-violet sky flash of `strength` 0..1.
func flash(strength: float = 1.0) -> void:
	_flash = maxf(_flash, clampf(strength, 0.0, 1.0))

## B1: how much whole-sky flash a strike impact at `at` earns for THIS peer.
## The host broadcasts every impact to every Stormwood peer, and glass-sink
## strikes happen in any phase, so an impact alone must not flash the sky:
## - the local presentation is Break (it `flashes`): full strength;
## - otherwise: fades linearly with distance from the local player to zero
##   at `presentation.flash.strike_sky_range_m`, so only a strike you are
##   standing near lights your sky.
func sky_flash_for_strike(at: Vector3) -> float:
	if not _to.is_empty() and bool(_to.get("flashes", false)):
		return 1.0
	var range_m := float(_pres_cfg().get("flash", {}).get("strike_sky_range_m", 40.0))
	var player := world.get_node_or_null("Player") as Node3D if world != null else null
	if player == null or range_m <= 0.0:
		return 0.0
	var from := player.global_position if player.is_inside_tree() else player.position
	return clampf(1.0 - from.distance_to(at) / range_m, 0.0, 1.0)

func _advance_flash(delta: float) -> void:
	var cfg: Dictionary = _pres_cfg().get("flash", {})
	var active := not _to.is_empty() and bool(_to.get("flashes", false)) and _blend >= 1.0
	if active:
		_flash_next -= delta
		if _flash_next <= 0.0:
			_flash_next = _flash_rng.randf_range(float(cfg.get("interval_min", 4.0)), float(cfg.get("interval_max", 8.0)))
			flash(_flash_rng.randf_range(float(cfg.get("distant_strength_min", 0.55)), 1.0))
			if _flash_rng.randf() < float(cfg.get("double_chance", 0.5)):
				_flash_echo = float(cfg.get("double_gap_seconds", 0.14))
	else:
		_flash_next = minf(_flash_next, 1.5)
	if _flash_echo >= 0.0:
		_flash_echo -= delta
		if _flash_echo < 0.0:
			flash(float(cfg.get("double_strength", 0.8)))
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta / maxf(0.01, float(cfg.get("decay_seconds", 0.35))))
	if _flash_light != null:
		_flash_light.visible = _flash > 0.0
		_flash_light.light_energy = _flash * float(cfg.get("light_energy", 2.2))
	if _ceiling_material != null:
		_ceiling_material.set_shader_parameter("flash", _flash * float(cfg.get("sky_strength", 1.0)))

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
uniform float speed = 0.01;
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
	float t = mod(TIME, 2000.0) * speed;
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
const CEILING_RADIUS := 2400.0

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
## Cross-fade between presentations: `_from` is what was on screen when the
## target changed, `_blend` runs 0..1 over `transition_seconds`.
var _from: Dictionary = {}
var _to: Dictionary = {}
var _blend := 1.0
var _reapply_left := 0.0
var _last_night_scale := -1.0
var _dirty := true
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

## One phase's presentation row: `presentation.phases[phase]`, with
## `presentation.aftermath[phase]` merged over it once the Long Storm has
## ended. `shadow_opacity` stays in its own authored block.
func presentation_for(for_phase: String, aftermath: bool = false) -> Dictionary:
	var block: Dictionary = rules.config.get("presentation", {})
	var row: Dictionary = (block.get("phases", {}).get(for_phase, {}) as Dictionary).duplicate(true)
	if aftermath:
		var over: Dictionary = block.get("aftermath", {}).get(for_phase, {})
		for key: String in over:
			row[key] = over[key]
	row["shadow_opacity"] = float(block.get("shadow_opacity", {}).get(for_phase, 1.0))
	return row

## The WorldLook weather delta for a phase. Sky and fog colours are the
## authored daylight values scaled by `night_scale` (1.0 by day), so a storm
## sky never glows brighter than the night it replaces. A row with no
## `sky_top` (the aftermath's Calm) leaves the art.json sky untouched.
func light_delta_for_phase(for_phase: String, aftermath: bool = false, night_scale: float = 1.0) -> Dictionary:
	return _delta_from(_resolved(presentation_for(for_phase, aftermath)), night_scale)

func _resolved(row: Dictionary) -> Dictionary:
	var out := {
		"sun_energy_mult": float(row.get("sun_energy_mult", 1.0)),
		"shadow_opacity": float(row.get("shadow_opacity", 1.0)),
		"ambient_energy_mult": float(row.get("ambient_energy_mult", 1.0)),
		"fog_density_add": float(row.get("fog_density_add", 0.0)),
		"ceiling_opacity": float(row.get("ceiling_opacity", 0.0)),
		"ceiling_speed": float(row.get("ceiling_speed", 0.0)),
		"ceiling_contrast": float(row.get("ceiling_contrast", 0.3)),
		"ceiling_breakup": float(row.get("ceiling_breakup", 0.0)),
		"rain_visible": bool(row.get("rain_visible", false)),
		"rain_amount": float(row.get("rain_amount", 0.0)),
		"flashes": bool(row.get("flashes", false)),
		"storm_sky": row.get("sky_top") != null,
	}
	for key: String in ["ambient_colour", "sky_top", "sky_horizon", "sky_ground_horizon", "ceiling_colour"]:
		if row.has(key) and row[key] != null:
			out[key] = Color(str(row[key]))
	return out

func _delta_from(p: Dictionary, night_scale: float) -> Dictionary:
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
		var k := clampf(night_scale, 0.0, 1.0)
		var sky := {}
		for pair: Array in [["sky_top", "top_colour"], ["sky_horizon", "horizon_colour"], ["sky_ground_horizon", "ground_horizon_colour"]]:
			if p.has(pair[0]):
				sky[pair[1]] = "#" + ((p[pair[0]] as Color) * k).to_html(false)
		delta["sky"] = sky
		# art.json's CRITICAL rule: with fog_sky_affect 0, fog must equal the
		# horizon colour or distant terrain seams against the sky.
		if sky.has("horizon_colour"):
			delta.environment["fog_colour"] = sky.horizon_colour
	return delta

## Blend two resolved rows. A colour present on only one side (the storm sky
## against the aftermath's untouched sky) cross-fades through `base`.
func _mix(a: Dictionary, b: Dictionary, t: float, base: Dictionary) -> Dictionary:
	if t >= 1.0:
		return b
	var out := {}
	for key: String in ["sun_energy_mult", "shadow_opacity", "ambient_energy_mult", "fog_density_add", "ceiling_opacity", "ceiling_speed", "ceiling_contrast", "ceiling_breakup", "rain_amount"]:
		out[key] = lerpf(float(a.get(key, 0.0)), float(b.get(key, 0.0)), t)
	out["rain_visible"] = bool(a.rain_visible) or bool(b.rain_visible)
	out["flashes"] = bool(b.flashes)
	out["storm_sky"] = bool(a.storm_sky) or bool(b.storm_sky)
	for key: String in ["ambient_colour", "sky_top", "sky_horizon", "sky_ground_horizon", "ceiling_colour"]:
		if not a.has(key) and not b.has(key):
			continue
		var ca: Color = a.get(key, base.get(key, b.get(key, Color.GRAY)))
		var cb: Color = b.get(key, base.get(key, a.get(key, Color.GRAY)))
		out[key] = ca.lerp(cb, t)
	if not out.has("ceiling_colour"):
		out["ceiling_colour"] = Color.GRAY
	return out

## The current time-of-day sky/ambient from WorldLook, used both as the
## fade-through colour and to derive `night_scale`: the live sky top's
## luminance over the day preset's, so storm colours authored for daylight
## dim with dusk and night instead of lighting the dark.
func _base_look() -> Dictionary:
	var look := world.get_node_or_null("WorldLook") if world != null else null
	if look == null:
		return {"night_scale": 1.0}
	var config: Variant = look.get("_config")
	var cycle: Variant = look.get("_cycle")
	if not config is Dictionary or (config as Dictionary).is_empty() or cycle == null:
		return {"night_scale": 1.0}
	var now: Dictionary = WORLD_LOOK.blended_config_at(config, cycle, float(look.call("hour")))
	var day_sky: Dictionary = WORLD_LOOK._merged_from(config, "sky", WORLD_LOOK._preset_over(config, "day"))
	var sky_now: Dictionary = now.get("sky", {})
	var env_now: Dictionary = now.get("environment", {})
	var top_now := _colour(sky_now.get("top_colour"), "#3b6f93")
	var top_day := _colour(day_sky.get("top_colour"), "#3b6f93")
	var floor_scale := float(rules.config.get("presentation", {}).get("night_scale_floor", 0.12))
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
		_from = target
		_blend = 1.0
	else:
		_from = _mix(_from, _to, _blend, _base_look())
		_blend = 0.0
	_to = target
	_reapply_left = 0.0
	_dirty = true

## Snap to the current phase's look with no cross-fade (capture tools and
## tests; also what a first frame after a scene load does anyway).
func settle_presentation() -> void:
	_to = _resolved(presentation_for(phase, _aftermath))
	_from = _to
	_blend = 1.0
	_last_phase = presentation_key()
	_apply_current(true)

func _advance_presentation(delta: float) -> void:
	if _to.is_empty():
		return
	var seconds := float(rules.config.get("presentation", {}).get("transition_seconds", 6.0))
	var blending := _blend < 1.0
	if blending:
		_blend = minf(1.0, _blend + delta / maxf(0.01, seconds))
		_dirty = true
	_reapply_left -= delta
	if _reapply_left > 0.0:
		_update_ceiling(_mix(_from, _to, _blend, {}))
		return
	# The WorldLook layer re-merges its whole look per call, so it is paced:
	# every 0.2 s while fading, every 2 s otherwise (to follow the day clock).
	_reapply_left = 0.2 if blending else 2.0
	_apply_current(_dirty)

func _apply_current(force: bool) -> void:
	var base := _base_look()
	var scale := float(base.night_scale)
	var current := _mix(_from, _to, _blend, base)
	_update_ceiling(current, scale)
	if not force and absf(scale - _last_night_scale) < 0.01:
		return
	_last_night_scale = scale
	_dirty = false
	var look := world.get_node_or_null("WorldLook") if world != null else null
	if look != null:
		look.call("set_weather", _delta_from(current, scale))
	_update_rain(current)

## Apply the current phase immediately (kept for existing callers/tests).
func _apply_phase_light() -> void:
	_to = _resolved(presentation_for(phase, _aftermath))
	_from = _to
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

## Stormwood's rain is heavier than the Meadows preset it shares a builder
## with: the streak size and tint of this realm's own emitter come from
## presentation.rain (world_weather.gd's constants stay the Meadows look).
func _style_rain() -> void:
	var cfg: Dictionary = rules.config.get("presentation", {}).get("rain", {})
	if _rain == null or cfg.is_empty():
		return
	var colour := Color(str(cfg.get("colour", "#c0ccd6")))
	colour.a = float(cfg.get("alpha", 0.4))
	var streak := _rain.draw_pass_1 as BoxMesh
	if streak != null:
		var width := float(cfg.get("streak_width_m", 0.015))
		streak.size = Vector3(width, float(cfg.get("streak_length_m", 0.4)), width)
		var material := streak.material as StandardMaterial3D
		if material != null:
			material.albedo_color = colour
	var process := _rain.process_material as ParticleProcessMaterial
	if process != null:
		process.color = colour
	_rain.amount = int(cfg.get("max_drops", _rain.amount))

func _update_ceiling(p: Dictionary, night_scale: float = -1.0) -> void:
	if _ceiling_material == null:
		return
	var scale := night_scale if night_scale >= 0.0 else maxf(0.0, _last_night_scale)
	if night_scale < 0.0 and _last_night_scale < 0.0:
		scale = 1.0
	var colour: Color = p.get("ceiling_colour", Color.GRAY)
	_ceiling_material.set_shader_parameter("ceiling_colour", colour * scale)
	_ceiling_material.set_shader_parameter("opacity", float(p.get("ceiling_opacity", 0.0)))
	_ceiling_material.set_shader_parameter("speed", float(p.get("ceiling_speed", 0.0)))
	_ceiling_material.set_shader_parameter("contrast", float(p.get("ceiling_contrast", 0.3)))
	_ceiling_material.set_shader_parameter("breakup", float(p.get("ceiling_breakup", 0.0)))
	_ceiling.visible = float(p.get("ceiling_opacity", 0.0)) > 0.001

func _build_ceiling() -> void:
	var shader := Shader.new()
	shader.code = CEILING_SHADER
	_ceiling_material = ShaderMaterial.new()
	_ceiling_material.shader = shader
	# Drawn before every other transparent (rain, telegraph rings), so it
	# can never be blended over something nearer.
	_ceiling_material.render_priority = Material.RENDER_PRIORITY_MIN
	var flash: Dictionary = rules.config.get("presentation", {}).get("flash", {})
	_ceiling_material.set_shader_parameter("flash_colour", Color(str(flash.get("colour", "#e6dcff"))))
	var dome := SphereMesh.new()
	dome.radius = CEILING_RADIUS
	dome.height = CEILING_RADIUS
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
	var flash: Dictionary = rules.config.get("presentation", {}).get("flash", {})
	_flash_light = DirectionalLight3D.new()
	_flash_light.name = "StormFlash"
	_flash_light.light_color = Color(str(flash.get("colour", "#e6dcff")))
	_flash_light.light_energy = 0.0
	_flash_light.shadow_enabled = false
	_flash_light.rotation_degrees = Vector3(-72.0, 30.0, 0.0)
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

## A white-violet sky flash. Break schedules its own distant ones; a real
## strike impact (stormwood_lightning.gd) calls this at full strength.
func flash(strength: float = 1.0) -> void:
	_flash = maxf(_flash, clampf(strength, 0.0, 1.0))

func _advance_flash(delta: float) -> void:
	var cfg: Dictionary = rules.config.get("presentation", {}).get("flash", {})
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
			flash(0.8)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta / maxf(0.01, float(cfg.get("decay_seconds", 0.35))))
	if _flash_light != null:
		_flash_light.visible = _flash > 0.0
		_flash_light.light_energy = _flash * float(cfg.get("light_energy", 2.2))
	if _ceiling_material != null:
		_ceiling_material.set_shader_parameter("flash", _flash * float(cfg.get("sky_strength", 1.0)))

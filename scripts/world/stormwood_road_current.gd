extends Node3D

## Owner direction on WO-F09-04: "Can you make the path and roads electrified
## with yellow electricity flowing through them somehow in the ground."
##
## Every Stormwood road (not the pocket spurs; see carries_current) gets
## terrain-conforming ribbon chunks lying
## in its painted dirt lane (stormwood_road_surface.json), drawn by
## shaders/stormwood_road_current.gdshader: broken yellow-gold veins with
## charge pulses flowing toward the Dynamo. Presentation only: nothing is built
## on a simulation_only world, there are no colliders, and the animation runs
## in the shader on TIME. The only script work after build is a low-cadence
## timer that eases `storm_intensity` to the Surge phase and follows the
## reduced-motion setting. All chunks share one ShaderMaterial.
const CONFIG_PATH := "res://data/config/stormwood_road_current.json"
const SURFACE_PATH := "res://data/config/stormwood_road_surface.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const SHADER := preload("res://shaders/stormwood_road_current.gdshader")
const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")

var material: ShaderMaterial
var _config: Dictionary = {}
var _world: Node3D
var _phase := ""
var _reduced := false
var _intensity := -1.0
var _tween: Tween


static func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH)) as Dictionary


## `route.points` as Vector2s ordered so the current flows toward the Dynamo:
## an open route runs from its end farther from `dynamo_xz` to the nearer one;
## a closed loop (first point equals last) keeps its polyline order.
static func flow_points(route: Dictionary, cfg: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for raw: Array in route.get("points", []):
		out.append(Vector2(float(raw[0]), float(raw[1])))
	if out.size() < 2 or out[0].distance_to(out[out.size() - 1]) < 0.01:
		return out
	var dynamo := Vector2(float(cfg.dynamo_xz[0]), float(cfg.dynamo_xz[1]))
	if out[0].distance_to(dynamo) < out[out.size() - 1].distance_to(dynamo):
		out.reverse()
	return out


## Ribbon half-width for a route kind: width_fraction of its painted lane.
static func ribbon_half_width(kind: String, cfg: Dictionary, surface: Dictionary) -> float:
	return float(surface.lane_half_width_m.get(kind, 0.0)) * float(cfg.width_fraction)


## WO-F09-05 round 3: the current is road language. A route whose kind is in
## config `excluded_kinds` (the pocket spurs) carries none; it stays a plain
## painted dirt trail.
static func carries_current(route: Dictionary, cfg: Dictionary) -> bool:
	return not (cfg.get("excluded_kinds", []) as Array).has(str(route.get("kind", "")))


## storm_intensity for a Surge phase id (unknown phases read as calm).
static func phase_intensity(phase: String, cfg: Dictionary) -> float:
	var table: Dictionary = cfg.storm_intensity
	return clampf(float(table.get(phase, table.calm)), 0.0, 1.0)


## {flow_speed, flicker} for the current motion setting.
static func motion_values(reduced: bool, cfg: Dictionary) -> Dictionary:
	if reduced:
		return {"flow_speed": float(cfg.reduced_motion.flow_speed_mps), "flicker": float(cfg.reduced_motion.flicker)}
	return {"flow_speed": float(cfg.flow_speed_mps), "flicker": float(cfg.flicker)}


## Builds every chunk. `height_at` is (x, z) -> ground y; the world passes
## its live Terrain3D surface so the ribbon lies on exactly what is drawn.
func build(world: Node3D, height_at: Callable = Callable()) -> void:
	_world = world
	if bool(world.get("simulation_only")):
		return
	_config = config()
	var surface: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SURFACE_PATH))
	var routes: Array = (JSON.parse_string(FileAccess.get_file_as_string(WORLD_PATH)) as Dictionary).routes
	if not height_at.is_valid():
		height_at = func(x: float, z: float) -> float: return float(world.call("ground_height_at", x, z))
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("colour_core", Color(str(_config.colour_core)))
	material.set_shader_parameter("colour_edge", Color(str(_config.colour_edge)))
	for key: String in ["core_energy", "edge_energy", "vein_scale", "vein_width", "vein_breakup", "pulse_sharpness", "depth_pull"]:
		material.set_shader_parameter(key, float(_config[key]))
	material.set_shader_parameter("pulse_spacing", float(_config.pulse_spacing_m))
	material.set_shader_parameter("fade_end", float(_config.draw_distance_m))
	material.set_shader_parameter("fade_length", float(_config.draw_fade_m))
	_apply_motion(MOTION_PREFS.reduced_motion())
	set_storm_intensity(phase_intensity("calm", _config))
	for route: Dictionary in routes:
		if not carries_current(route, _config):
			continue
		var half := ribbon_half_width(str(route.kind), _config, surface)
		if half <= 0.0:
			continue
		_build_route(route, flow_points(route, _config), half, height_at)
	var timer := Timer.new()
	timer.name = "StormPoll"
	timer.wait_time = float(_config.storm_intensity.poll_s)
	timer.autostart = true
	timer.timeout.connect(_poll)
	add_child(timer)


## The one intensity hook: 0..1, stored on the shared material.
func set_storm_intensity(value: float) -> void:
	_intensity = clampf(value, 0.0, 1.0)
	if material != null:
		material.set_shader_parameter("storm_intensity", _intensity)


func storm_intensity() -> float:
	return _intensity


func _apply_motion(reduced: bool) -> void:
	_reduced = reduced
	var values := motion_values(reduced, _config)
	material.set_shader_parameter("flow_speed", float(values.flow_speed))
	material.set_shader_parameter("flicker", float(values.flicker))


## Low cadence: follow the Surge phase (StormwoodSurge.phase, read-only; the
## surge exposes no phase signal) and the reduced-motion setting. No
## per-frame work.
func _poll() -> void:
	if material == null:
		return
	if MOTION_PREFS.reduced_motion() != _reduced:
		_apply_motion(MOTION_PREFS.reduced_motion())
	var surge := _world.get_node_or_null("StormwoodSurge") if _world != null else null
	var phase := str(surge.get("phase")) if surge != null and surge.get("phase") != null else "calm"
	# The Long Storm's end is a progression flag (the one stormwood_surge.gd
	# itself reads); after it only a faint residual current remains.
	var game := get_node_or_null("/root/Game")
	var flags: Variant = game.get("progression") if game != null else null
	if flags is Object and bool((flags as Object).call("has", str(_config.storm_intensity.aftermath_flag))):
		phase = "aftermath"
	if phase == _phase:
		return
	_phase = phase
	var target := phase_intensity(phase, _config)
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(set_storm_intensity, _intensity, target, float(_config.storm_intensity.ease_s))


func _build_route(route: Dictionary, points: Array[Vector2], half: float, height_at: Callable) -> void:
	var chunk_m := float(_config.chunk_m)
	var row_m := float(_config.row_spacing_m)
	var columns := maxi(2, int(_config.columns))
	var lift := float(_config.lift_m)
	var run := 0.0
	var index := 0
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var length := a.distance_to(b)
		if length < 0.01:
			continue
		var dir := (b - a) / length
		var side := dir.orthogonal()
		var pieces := maxi(1, ceili(length / chunk_m))
		for piece in pieces:
			var s0 := length * piece / pieces
			var s1 := length * (piece + 1) / pieces
			var rows := maxi(1, ceili((s1 - s0) / row_m))
			var verts := PackedVector3Array()
			var uvs := PackedVector2Array()
			var indices := PackedInt32Array()
			var origin := a + dir * (s0 + s1) * 0.5
			var origin_y := float(height_at.call(origin.x, origin.y))
			for r in rows + 1:
				var s := lerpf(s0, s1, float(r) / rows)
				for c in columns:
					var across := lerpf(-1.0, 1.0, float(c) / (columns - 1))
					var at := a + dir * s + side * across * half
					var y := float(height_at.call(at.x, at.y)) + lift
					verts.append(Vector3(at.x - origin.x, y - origin_y, at.y - origin.y))
					uvs.append(Vector2(run + s, across))
			for r in rows:
				for c in columns - 1:
					var i0 := r * columns + c
					var i1 := i0 + columns
					indices.append_array(PackedInt32Array([i0, i1, i0 + 1, i0 + 1, i1, i1 + 1]))
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = verts
			arrays[Mesh.ARRAY_TEX_UV] = uvs
			arrays[Mesh.ARRAY_INDEX] = indices
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var chunk := MeshInstance3D.new()
			chunk.name = "%s_%03d" % [str(route.id), index]
			chunk.mesh = mesh
			chunk.material_override = material
			chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			chunk.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			chunk.visibility_range_end = float(_config.draw_distance_m)
			# The shader fades the current out over draw_fade_m before this cut.
			chunk.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			chunk.position = Vector3(origin.x, origin_y, origin.y)
			chunk.set_meta("route", str(route.id))
			chunk.set_meta("length_m", s1 - s0)
			add_child(chunk)
			index += 1
		run += length

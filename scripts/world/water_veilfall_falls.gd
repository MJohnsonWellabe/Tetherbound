extends Node3D

## Veilfall white falls (F13#5). The owner board's mountain is crowned by broad
## white falls with mist at their feet; the single gate curtain alone vanished
## at the First Shore sightline. This drapes a few foam ribbons down the real
## baked mountain face and puts camera-facing spray puffs at each plunge point.
## Presentation only: no collision, no gameplay state. Everything is two
## meshes (one ribbon surface for all columns, one quad set for all spray), so
## the whole pass costs two draw calls. Tunables: water_veilfall.json::falls.
const FALL_SHADER := preload("res://shaders/water_veilfall_fall.gdshader")
const SPRAY_SHADER := preload("res://shaders/water_veilfall_spray.gdshader")
const WET_SHADER := preload("res://shaders/water_veilfall_wet.gdshader")
const POOL_SHADER := preload("res://shaders/water_veilfall_pool.gdshader")
const MIST_SHELL_SHADER := preload("res://shaders/water_veilfall_mist_shell.gdshader")
const VISUAL_CONFIG := "res://data/config/water_veilfall_falls_visual.json"
const VISUAL_UNIFORMS := ["visual_far_core_floor", "visual_far_edge_floor",
	"visual_far_start_m", "visual_far_end_m", "continuous_core_floor",
	"presentation_pull_start_m", "presentation_pull_end_m", "min_angular_width",
	"lip_feather_m", "foot_feather_m"]

var column_receipt: Array[Dictionary] = []
var materials: Array[ShaderMaterial] = []
var _world: Node3D
var _geometry: Dictionary = {}


func build(world: Node3D, config: Dictionary, centre_xz: Vector2) -> void:
	_world = world
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VISUAL_CONFIG))
	var visual: Dictionary = parsed if parsed is Dictionary else {}
	var geometry: Dictionary = visual.get("geometry", {}) if bool(visual.get("enabled", false)) else {}
	_geometry = geometry
	var step := maxf(1.0, float(geometry.get("sample_step_m", config.get("sample_step_m", 6.0))))
	var standoff := float(geometry.get("standoff_m", config.get("standoff_m", 2.5)))
	var ribbons := SurfaceTool.new()
	ribbons.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spray: Array[Dictionary] = []
	# `falls.rebuild` (F39#31, OFF until judged): layered strands, a wet rock
	# apron, a plunge pool with foam rings and a mist shell at each foot.
	var rebuild: Dictionary = config.get("rebuild", {})
	var rebuild_on := bool(rebuild.get("enabled", false))
	var wet := SurfaceTool.new()
	wet.begin(Mesh.PRIMITIVE_TRIANGLES)
	var plunges: Array[Dictionary] = []
	for column: Dictionary in config.get("columns", []):
		var path := _fall_line(column, centre_xz, step)
		if path.size() < 2:
			push_error("Veilfall fall column found no face to drape: " + str(column.get("id", "")))
			continue
		_ribbon(ribbons, path, float(column.get("width_m", 20.0)), standoff, float(column.get("taper", 0.8)),
			float(column.get("opacity", 1.0)))
		if rebuild_on:
			_rebuild_column(ribbons, wet, plunges, path, column, standoff, rebuild)
		var foot: Vector3 = path[path.size() - 1]
		var bearing := deg_to_rad(float(column.get("bearing_deg", 0.0)))
		var outward := Vector3(cos(bearing), 0.0, sin(bearing))
		var lateral := Vector3(-outward.z, 0.0, outward.x)
		for puff: Dictionary in column.get("spray", []):
			# Offsets are [across, up, outward] relative to the foot (or at_fraction point).
			var offset := _vector(puff.get("offset", [0, 0, 0]))
			# at_fraction places a mid-cascade puff along the fall instead of at its foot.
			var anchor: Vector3 = foot
			if puff.has("at_fraction"):
				anchor = path[clampi(roundi(float(puff.at_fraction) * float(path.size() - 1)), 0, path.size() - 1)]
			spray.append({"at": anchor + lateral * offset.x + Vector3.UP * offset.y + outward * offset.z,
				"radius_m": float(puff.get("radius_m", 12.0))})
		column_receipt.append({"id": str(column.get("id", "")), "top": path[0], "foot": foot,
			"samples": path.size()})
	var ribbon_mesh := MeshInstance3D.new()
	ribbon_mesh.name = "VeilfallFallColumns"
	ribbon_mesh.mesh = ribbons.commit()
	ribbon_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var column_params: Dictionary = (config.get("column_shader", {}) as Dictionary).duplicate()
	if rebuild_on:
		column_params.merge(rebuild.get("column_shader", {}), true)
	ribbon_mesh.material_override = _material(_fall_shader(bool(config.get("unshadowed", false))), column_params)
	apply_visual_settings(ribbon_mesh.material_override as ShaderMaterial, visual)
	(ribbon_mesh.material_override as ShaderMaterial).set_shader_parameter("centre_xz", centre_xz)
	materials.append(ribbon_mesh.material_override)
	# The depth pull and minimum width move vertices outside the authored
	# bounds; a generous AABB margin keeps frustum culling from popping it.
	ribbon_mesh.extra_cull_margin = 200.0
	add_child(ribbon_mesh)
	if rebuild_on:
		_build_rebuild_meshes(wet, plunges, rebuild, centre_xz)
	if not spray.is_empty():
		var puffs := MeshInstance3D.new()
		puffs.name = "VeilfallFallSpray"
		puffs.mesh = _spray_mesh(spray)
		puffs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puffs.material_override = _material(SPRAY_SHADER, config.get("spray_shader", {}))
		(puffs.material_override as ShaderMaterial).set_shader_parameter("centre_xz", centre_xz)
		materials.append(puffs.material_override)
		puffs.extra_cull_margin = 400.0
		add_child(puffs)


## Allowlisted local uniforms only. Reapplying false restores the original
## fragment path; shared mesh, fog registration and physical samples stay intact.
static func apply_visual_settings(material: ShaderMaterial, settings: Dictionary) -> void:
	if material == null:
		return
	var enabled := bool(settings.get("enabled", false))
	material.set_shader_parameter("visual_far_core_enabled", enabled)
	if enabled:
		var values: Dictionary = settings.get("shader", {})
		for key: String in VISUAL_UNIFORMS:
			if values.has(key):
				material.set_shader_parameter(key, float(values[key]))


## Walks outward from the island centre along the column's bearing and keeps
## the stretch of real terrain between its lip and foot heights.
func _fall_line(column: Dictionary, centre_xz: Vector2, step: float) -> Array[Vector3]:
	var bearing := deg_to_rad(float(column.get("bearing_deg", 0.0)))
	var direction := Vector2(cos(bearing), sin(bearing))
	var top_y := float(column.get("top_y_m", 400.0))
	var foot_y := float(column.get("foot_y_m", 0.0))
	var max_radius := float(column.get("max_radius_m", 420.0))
	var out: Array[Vector3] = []
	var radius := 0.0
	while radius <= max_radius:
		var xz := centre_xz + direction * radius
		var y := float(_world.call("ground_height_at", xz.x, xz.y))
		radius += step
		if not is_finite(y) or y > top_y:
			continue
		out.append(Vector3(xz.x, maxf(y, foot_y), xz.y))
		if y <= foot_y:
			break
	return out


func _ribbon(surface: SurfaceTool, path: Array[Vector3], width: float, standoff: float, taper: float,
		opacity: float, lateral_offset: float = 0.0, speed_factor: float = 0.0) -> void:
	var lateral_xz := Vector2(path[path.size() - 1].x - path[0].x, path[path.size() - 1].z - path[0].z).normalized()
	var lateral := Vector3(-lateral_xz.y, 0.0, lateral_xz.x)
	var outward := Vector3(lateral_xz.x, 0.0, lateral_xz.y)
	var colour := Color(lateral.x * 0.5 + 0.5, clampf(opacity, 0.0, 1.0) * 0.5, lateral.z * 0.5 + 0.5, width / 100.0)
	var rows: Array = []
	# Broad strips must follow the rock between strands too. Six-metre chords
	# cut through curved shoulders despite clear vertices, breaking the fall
	# into isolated streaks. Keep metre-scale samples across the entire fan.
	var cross_step := maxf(0.5, float(_geometry.get("cross_sample_step_m", 1.5)))
	var cross_segments := clampi(ceili(width / cross_step), 2, 128)
	var relief := maxf(0.0, float(_geometry.get("stream_relief_m", 0.0)))
	var stream_spacing := maxf(1.0, float(_geometry.get("stream_spacing_m", 2.8)))
	for index in path.size():
		var t := float(index) / float(path.size() - 1)
		var centre: Vector3 = path[index] + lateral * lateral_offset * lerpf(0.6, 1.0, t)
		# Falls widen as they drop: narrow lip, full width at the foot.
		var half := width * 0.5 * lerpf(taper, 1.0, t)
		var row: Array = []
		for across in cross_segments + 1:
			var u := float(across) / float(cross_segments)
			var side := u * 2.0 - 1.0
			var at := centre + lateral * side * half + outward * standoff
			var ground := float(_world.call("ground_height_at", at.x, at.z))
			# Reuse the grounded cross-strand repair from the 1b visual lane:
			# the outer water follows its own face, not the centre's higher row.
			# Shallow longitudinal stream ridges catch the existing lit material
			# at detail distance. Their phase follows each strand (u), so widening
			# does not cut diagonal bands across the fall. Relief only adds above
			# terrain clearance and fades at the lip/foot; it owns no collision.
			var phase := u * width / stream_spacing * TAU
			var ridge := 0.5 + 0.5 * sin(phase + sin(phase * 0.37) * 0.65 + sin(t * TAU) * 0.25)
			var end_fade := smoothstep(0.0, 0.06, t) * (1.0 - smoothstep(0.92, 1.0, t))
			var y := (ground if is_finite(ground) else centre.y) + standoff + relief * ridge * end_fade
			row.append({"at": Vector3(at.x, y, at.z),
				"uv": Vector2(u, 0.0)})
		rows.append(row)
	# Flow and plunge fading use each strand's actual length. A common centre
	# distance gave the sloping outer strands an artificial horizontal cutoff.
	for across in cross_segments + 1:
		var travelled := 0.0
		for index in rows.size():
			if index > 0:
				var previous: Vector3 = rows[index - 1][across].at
				travelled += previous.distance_to(rows[index][across].at)
			rows[index][across]["uv"] = Vector2(float(across) / cross_segments, travelled)
	# Shared vertex normals keep changes of slope continuous instead of
	# switching the lighting abruptly at every terrain sampling row.
	for index in rows.size():
		for across in cross_segments + 1:
			var down: Vector3 = rows[mini(index + 1, rows.size() - 1)][across].at \
				- rows[maxi(index - 1, 0)][across].at
			var right: Vector3 = rows[index][mini(across + 1, cross_segments)].at \
				- rows[index][maxi(across - 1, 0)].at
			var normal := down.cross(right).normalized()
			if normal.dot(outward + Vector3.UP * 0.2) < 0.0:
				normal = -normal
			rows[index][across]["normal"] = normal
	for index in range(1, rows.size()):
		for across in cross_segments:
			for key: Vector2i in [Vector2i(index - 1, across), Vector2i(index - 1, across + 1), Vector2i(index, across + 1),
					Vector2i(index - 1, across), Vector2i(index, across + 1), Vector2i(index, across)]:
				var corner: Dictionary = rows[key.x][key.y]
				var strand_end: Vector2 = rows[rows.size() - 1][key.y].uv
				surface.set_color(colour)
				surface.set_normal(corner.normal)
				surface.set_uv(corner.uv)
				surface.set_uv2(Vector2(speed_factor, strand_end.y - float(corner.uv.y)))
				surface.add_vertex(corner.at)


## `falls.rebuild` per column: extra strands (each offset across the fall,
## narrower, with its own speed and opacity) into the shared ribbon surface, a
## wider wet apron under the fall, and, where the fall lands low enough, a
## plunge pool and mist shell at its foot.
func _rebuild_column(ribbons: SurfaceTool, wet: SurfaceTool, plunges: Array[Dictionary], path: Array[Vector3],
		column: Dictionary, standoff: float, rebuild: Dictionary) -> void:
	var width := float(column.get("width_m", 20.0))
	var taper := float(column.get("taper", 0.8))
	var opacity := float(column.get("opacity", 1.0))
	var layer := 0
	for strand: Dictionary in rebuild.get("strands", []):
		layer += 1
		_ribbon(ribbons, path, width * float(strand.get("width_frac", 0.4)),
			standoff + float(rebuild.get("strand_lift_m", 0.35)) * layer, taper,
			opacity * float(strand.get("opacity", 0.8)),
			width * 0.5 * float(strand.get("offset_frac", 0.0)), float(strand.get("speed", 1.0)) - 1.0)
	var apron: Dictionary = rebuild.get("wet_apron", {})
	if bool(apron.get("enabled", true)):
		_ribbon(wet, path, width * float(apron.get("width_scale", 1.7)),
			standoff * float(apron.get("standoff_scale", 0.4)),
			minf(1.0, taper * float(apron.get("taper_scale", 1.4))), 1.0)
	var pool: Dictionary = rebuild.get("pool", {})
	var foot: Vector3 = path[path.size() - 1]
	if bool(pool.get("enabled", true)) and foot.y <= float(pool.get("max_foot_y_m", 8.0)):
		var bearing := deg_to_rad(float(column.get("bearing_deg", 0.0)))
		var outward := Vector3(cos(bearing), 0.0, sin(bearing))
		var radius := width * float(pool.get("radius_per_width", 0.7))
		plunges.append({"at": foot + outward * radius * float(pool.get("outward_frac", 0.45))
			+ Vector3.UP * float(pool.get("lift_m", 0.25)), "radius_m": radius})


func _build_rebuild_meshes(wet: SurfaceTool, plunges: Array[Dictionary], rebuild: Dictionary, _centre_xz: Vector2) -> void:
	var apron := MeshInstance3D.new()
	apron.name = "VeilfallWetApron"
	apron.mesh = wet.commit()
	apron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	apron.material_override = _material(WET_SHADER, (rebuild.get("wet_apron", {}) as Dictionary).get("shader", {}))
	apron.extra_cull_margin = 200.0
	add_child(apron)
	if plunges.is_empty():
		return
	var pool_cfg: Dictionary = rebuild.get("pool", {})
	var mist_cfg: Dictionary = rebuild.get("mist", {})
	var discs := SurfaceTool.new()
	discs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shells := SurfaceTool.new()
	shells.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := clampi(int(pool_cfg.get("segments", 48)), 12, 128)
	var rings := 6
	for plunge: Dictionary in plunges:
		var at: Vector3 = plunge.at
		var radius := float(plunge.radius_m)
		print("[veilfall] plunge pool at %s radius %.1f m" % [at, radius])
		for i in segments:
			var a0 := TAU * float(i) / float(segments)
			var a1 := TAU * float(i + 1) / float(segments)
			for corner: Vector2 in [Vector2.ZERO, Vector2(cos(a0), sin(a0)), Vector2(cos(a1), sin(a1))]:
				discs.set_normal(Vector3.UP)
				discs.set_uv(corner)
				discs.add_vertex(at + Vector3(corner.x, 0.0, corner.y) * radius)
		if not bool(mist_cfg.get("enabled", true)):
			continue
		var base_r := radius * float(mist_cfg.get("base_frac", 0.55))
		var top_r := radius * float(mist_cfg.get("top_frac", 1.25))
		var height := radius * float(mist_cfg.get("height_per_radius", 1.1))
		for i in segments:
			for j in rings:
				var quad: Array[Vector2] = [Vector2(i, j), Vector2(i + 1, j), Vector2(i + 1, j + 1),
					Vector2(i, j), Vector2(i + 1, j + 1), Vector2(i, j + 1)]
				for q: Vector2 in quad:
					var ang := TAU * q.x / float(segments)
					var v := q.y / float(rings)
					var dir := Vector3(cos(ang), 0.0, sin(ang))
					shells.set_normal(dir)
					shells.set_uv(Vector2(q.x / float(segments), v))
					shells.add_vertex(at + dir * lerpf(base_r, top_r, sqrt(v)) + Vector3.UP * (height * v))
	var pool_mesh := MeshInstance3D.new()
	pool_mesh.name = "VeilfallPlungePools"
	pool_mesh.mesh = discs.commit()
	pool_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pool_mesh.material_override = _material(POOL_SHADER, pool_cfg.get("shader", {}))
	materials.append(pool_mesh.material_override)
	add_child(pool_mesh)
	if bool(mist_cfg.get("enabled", true)):
		var shell_mesh := MeshInstance3D.new()
		shell_mesh.name = "VeilfallMistShells"
		shell_mesh.mesh = shells.commit()
		shell_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shell_mesh.material_override = _material(MIST_SHELL_SHADER, mist_cfg.get("shader", {}))
		materials.append(shell_mesh.material_override)
		add_child(shell_mesh)


func _spray_mesh(puffs: Array[Dictionary]) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for index in puffs.size():
		var puff: Dictionary = puffs[index]
		var colour := Color(fmod(float(index) * 0.37, 1.0), 0.0, 0.0, float(puff.radius_m) / 100.0)
		for corner: Vector2 in corners:
			surface.set_color(colour)
			surface.set_uv2(corner)
			surface.set_normal(Vector3.UP)
			surface.add_vertex(puff.at)
	return surface.commit()


## F39#31 (tb/vis-tidewake-1104, flag-off): falling water should not carry hard
## cast shadows (the r3 judges read a pine's shadow on the sheet as a dark tear).
## With `unshadowed` the column uses the same shader code with shadows_disabled.
static var _unshadowed_shader: Shader = null


static func _fall_shader(unshadowed: bool) -> Shader:
	if not unshadowed:
		return FALL_SHADER
	if _unshadowed_shader == null:
		_unshadowed_shader = Shader.new()
		_unshadowed_shader.code = FALL_SHADER.code.replace("render_mode blend_mix,", "render_mode blend_mix, shadows_disabled,")
	return _unshadowed_shader


func _material(shader: Shader, parameters: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	for key: String in parameters:
		if key.begins_with("_"):
			continue
		var value: Variant = parameters[key]
		material.set_shader_parameter(key, Color(str(value)) if value is String else value)
	return material


func _vector(raw: Variant) -> Vector3:
	var values: Array = raw if raw is Array else [0, 0, 0]
	return Vector3(float(values[0]), float(values[1]), float(values[2]))

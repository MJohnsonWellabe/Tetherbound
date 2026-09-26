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

var column_receipt: Array[Dictionary] = []
var materials: Array[ShaderMaterial] = []
var _world: Node3D


func build(world: Node3D, config: Dictionary, centre_xz: Vector2) -> void:
	_world = world
	var step := maxf(1.0, float(config.get("sample_step_m", 6.0)))
	var standoff := float(config.get("standoff_m", 2.5))
	var ribbons := SurfaceTool.new()
	ribbons.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spray: Array[Dictionary] = []
	for column: Dictionary in config.get("columns", []):
		var path := _fall_line(column, centre_xz, step)
		if path.size() < 2:
			push_error("Veilfall fall column found no face to drape: " + str(column.get("id", "")))
			continue
		_ribbon(ribbons, path, float(column.get("width_m", 20.0)), standoff, float(column.get("taper", 0.8)),
			float(column.get("opacity", 1.0)))
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
	ribbon_mesh.material_override = _material(FALL_SHADER, config.get("column_shader", {}))
	materials.append(ribbon_mesh.material_override)
	# The depth pull and minimum width move vertices outside the authored
	# bounds; a generous AABB margin keeps frustum culling from popping it.
	ribbon_mesh.extra_cull_margin = 200.0
	add_child(ribbon_mesh)
	if not spray.is_empty():
		var puffs := MeshInstance3D.new()
		puffs.name = "VeilfallFallSpray"
		puffs.mesh = _spray_mesh(spray)
		puffs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puffs.material_override = _material(SPRAY_SHADER, config.get("spray_shader", {}))
		materials.append(puffs.material_override)
		puffs.extra_cull_margin = 400.0
		add_child(puffs)


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
		opacity: float) -> void:
	var lateral_xz := Vector2(path[path.size() - 1].x - path[0].x, path[path.size() - 1].z - path[0].z).normalized()
	var lateral := Vector3(-lateral_xz.y, 0.0, lateral_xz.x)
	var outward := Vector3(lateral_xz.x, 0.0, lateral_xz.y)
	var colour := Color(lateral.x * 0.5 + 0.5, clampf(opacity, 0.0, 1.0) * 0.5, lateral.z * 0.5 + 0.5, width / 100.0)
	var travelled := 0.0
	var rows: Array = []
	for index in path.size():
		var centre: Vector3 = path[index]
		if index > 0:
			travelled += centre.distance_to(path[index - 1])
		var t := float(index) / float(path.size() - 1)
		# Falls widen as they drop: narrow lip, full width at the foot.
		var half := width * 0.5 * lerpf(taper, 1.0, t)
		var row: Array = []
		for side: float in [-1.0, 1.0]:
			var at := centre + lateral * side * half
			var ground := float(_world.call("ground_height_at", at.x, at.z))
			var y := maxf(centre.y, ground if is_finite(ground) else centre.y) + standoff
			row.append({"at": Vector3(at.x, y, at.z) + outward * standoff,
				"uv": Vector2(0.0 if side < 0.0 else 1.0, travelled)})
		rows.append(row)
	for index in range(1, rows.size()):
		var a: Array = rows[index - 1]
		var b: Array = rows[index]
		var a0: Vector3 = a[0].at
		var normal: Vector3 = (b[0].at - a0).cross(a[1].at - a0).normalized()
		if normal.dot(outward + Vector3.UP * 0.2) < 0.0:
			normal = -normal
		for corner: Dictionary in [a[0], a[1], b[1], a[0], b[1], b[0]]:
			surface.set_color(colour)
			surface.set_normal(normal)
			surface.set_uv(corner.uv)
			surface.add_vertex(corner.at)


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

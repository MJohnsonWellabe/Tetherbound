extends Node3D
## HOLD6116607118 r2 massing only. Independent OFF selector; prior candidates
## remain intact. Upper render crag and a single connected free-falling stream.
## No terrain, collision, transport, route, actor or camera changes.
const CONFIG := "res://data/config/water_veilfall_tiered_r2.json"
const FALL_SHADER := preload("res://shaders/water_veilfall_fall.gdshader")
const SPRAY_SHADER := preload("res://shaders/water_veilfall_spray.gdshader")
var _cfg: Dictionary

func build(world: Node3D, veilfall: Node3D) -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not bool(cfg.get("tiered_crag_r2_enabled", false)) or bool(world.get("simulation_only")):
		return
	_cfg = cfg
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = load(str(cfg.rock_texture)) as Texture2D
	stone.albedo_color = Color(str(cfg.rock_tint))
	stone.roughness = 1.0
	stone.uv1_triplanar = true
	stone.uv1_scale = Vector3.ONE * float(cfg.rock_texture_scale)
	for tier: Dictionary in cfg.tiers:
		_tier(tier, stone)
	var far := veilfall.get_node_or_null("VeilfallFarSilhouette")
	# Retire only the old render candidates. Their source and all physical
	# supports remain unchanged; the new masses enclose the upper terrain.
	for path: String in ["WaterfallPassage/VeilfallExteriorComposition", "VeilfallWhiteFalls", "VeilfallFarSilhouette"]:
		var previous := veilfall.get_node_or_null(path) as Node3D
		if previous != null:
			previous.visible = false
	var water := ShaderMaterial.new()
	water.shader = FALL_SHADER
	for key: String in cfg.water_shader:
		var value: Variant = cfg.water_shader[key]
		water.set_shader_parameter(key, Color(str(value)) if value is String else value)
	water.set_shader_parameter("centre_xz", Vector2(float(cfg.centre_xz[0]), float(cfg.centre_xz[1])))
	_stream(water)
	var mist := ShaderMaterial.new()
	mist.shader = SPRAY_SHADER
	for key: String in cfg.mist_shader:
		var value: Variant = cfg.mist_shader[key]
		mist.set_shader_parameter(key, Color(str(value)) if value is String else value)
	_spray(mist)
	if far != null:
		far.call("register_fogged", water)
		far.call("register_fogged", mist)

func _point(row: Array) -> Vector3:
	var u: Array = _cfg.across_xz
	var v: Array = _cfg.outward_xz
	return Vector3(float(_cfg.centre_xz[0]) + float(u[0]) * float(row[0]) + float(v[0]) * float(row[2]), float(row[1]), float(_cfg.centre_xz[1]) + float(u[1]) * float(row[0]) + float(v[1]) * float(row[2]))

func _tier(spec: Dictionary, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top: Array[Vector3] = []
	var bottom: Array[Vector3] = []
	var centre := Vector3.ZERO
	for i in spec.top_outline.size():
		var a: Array = spec.top_outline[i]
		var b: Array = spec.bottom_outline[i]
		var y := float(spec.top_y[i]) if spec.top_y is Array else float(spec.top_y)
		top.append(_point([a[0], y, a[1]]))
		bottom.append(_point([b[0], spec.bottom_y, b[1]]))
		centre += top[-1]
	centre /= float(top.size())
	var foot := Vector3(centre.x, float(spec.bottom_y), centre.z)
	for i in top.size():
		var next := (i + 1) % top.size()
		_triangle(surface, centre, top[i], top[next], Vector3.UP)
		_triangle(surface, foot, bottom[next], bottom[i], Vector3.DOWN)
		var outward := (top[i] + top[next]) * 0.5 - centre
		outward.y = 0.0
		_triangle(surface, top[i], bottom[i], bottom[next], outward)
		_triangle(surface, top[i], bottom[next], top[next], outward)
	_mesh(str(spec.id), surface, material)

func _stream(material: ShaderMaterial) -> void:
	var path: Array = _cfg.water_path
	var lengths: Array[float] = [0.0]
	for i in range(1, path.size()):
		lengths.append(lengths[-1] + _point(path[i].at).distance_to(_point(path[i - 1].at)))
	var across := Vector3(float(_cfg.across_xz[0]), 0.0, float(_cfg.across_xz[1]))
	var rings: Array = []
	for i in path.size():
		var centre := _point(path[i].at)
		var tangent := (_point(path[mini(i + 1, path.size() - 1)].at) - _point(path[maxi(0, i - 1)].at)).normalized()
		var depth := across.cross(tangent).normalized()
		var ring: Array = []
		for j in 12:
			var angle := TAU * float(j) / 12.0
			var side := cos(angle)
			ring.append({"at": centre + across * side * float(path[i].width_m) * 0.5 + depth * sin(angle) * float(_cfg.water_thickness_m) * 0.5, "uv": Vector2((side + 1.0) * 0.5, lengths[i]), "remaining": lengths[-1] - lengths[i]})
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, rings.size()):
		for j in 12:
			var next := (j + 1) % 12
			_water_triangle(surface, rings[i - 1][j], rings[i][j], rings[i][next], across, float(path[i].width_m))
			_water_triangle(surface, rings[i - 1][j], rings[i][next], rings[i - 1][next], across, float(path[i].width_m))
	_mesh("ConnectedLipLedgePlunge", surface, material)

func _water_triangle(surface: SurfaceTool, a: Dictionary, b: Dictionary, c: Dictionary, across: Vector3, width: float) -> void:
	var normal := (Vector3(b.at) - Vector3(a.at)).cross(Vector3(c.at) - Vector3(a.at)).normalized()
	for point: Dictionary in [a, b, c]:
		surface.set_color(Color(across.x * 0.5 + 0.5, 0.5, across.z * 0.5 + 0.5, width / 100.0))
		surface.set_normal(normal)
		surface.set_uv(point.uv)
		surface.set_uv2(Vector2(0.0, float(point.remaining)))
		surface.add_vertex(point.at)

func _spray(material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for spec: Dictionary in _cfg.spray:
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			surface.set_color(Color(0.3, 0.0, 0.0, float(spec.radius_m) / 100.0))
			surface.set_uv2(corner)
			surface.set_normal(Vector3.UP)
			surface.add_vertex(_point(spec.at))
	_mesh("LedgeAndSeaImpactMist", surface, material)

func _mesh(label: String, surface: SurfaceTool, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = surface.commit()
	mesh.material_override = material
	add_child(mesh)

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, direction: Vector3) -> void:
	var normal := (b - a).cross(c - a)
	if normal.dot(direction) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	for point: Vector3 in [a, b, c]:
		surface.set_normal(normal.normalized())
		surface.set_uv(Vector2(point.x, point.z))
		surface.add_vertex(point)

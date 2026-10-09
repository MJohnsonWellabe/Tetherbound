extends Node3D

## Presentation layer for Realm Gate Crag. The structural gate and its supporting
## mesa remain owned by cloudreach_world.gd; this layer gives the normal arrival
## view a ceremonial silhouette, human-scale detail and night wayfinding without
## placing any new collision in the route aperture.

const CONFIG_PATH := "res://data/config/cloudreach_realm_gate_crag_visual.json"
const CASTLE_TOWER := preload("res://assets/buildings/quaternius_castle/SmallSquareTowerBricks.obj")

var _built := false


func build(materials: Dictionary, ground_sampler: Callable = Callable()) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Realm Gate Crag visual config is invalid")
		return
	var cfg := parsed as Dictionary
	for index in (cfg.get("approach_pavers", []) as Array).size():
		var spec := (cfg.approach_pavers as Array)[index] as Dictionary
		var paver := _add_box("ArrivalPaver%02d" % (index + 1), _v3(spec.position), _v3(spec.size),
			_material(materials, "path"), "approach_paver")
		if ground_sampler.is_valid():
			_conform_paver(paver, ground_sampler, cfg.get("ground_contact", {}))
	for index in (cfg.get("outer_buttresses", []) as Array).size():
		var spec := (cfg.outer_buttresses as Array)[index] as Dictionary
		_add_scaled_mesh("CragButtress%02d" % (index + 1), CASTLE_TOWER,
			_v3(spec.position), _v3(spec.size),
			_material(materials, "masonry"), "outer_buttress")
		_add_box("CragButtressCap%02d" % (index + 1),
			_v3(spec.position) + Vector3.UP * (float((spec.size as Array)[1]) * 0.5 + 0.38),
			Vector3(float((spec.size as Array)[0]) + 0.8, 0.75,
				float((spec.size as Array)[2]) + 0.8),
			_material(materials, "masonry_trim"), "outer_buttress_cap")
	_add_banners(cfg.get("banner", {}) as Dictionary, materials)
	_add_emblem(cfg.get("heart_emblem", {}) as Dictionary, materials)
	for index in (cfg.get("arrival_beacons", []) as Array).size():
		_add_beacon(index, (cfg.arrival_beacons as Array)[index] as Dictionary,
			cfg.get("beacon_light", {}) as Dictionary, materials,
			float(cfg.get("beacon_scale", 1.0)))


## The existing bottom-face boundary defines each footing; the installed upper
## masonry and its open aperture remain untouched. This is presentation only.
static func add_masonry_footing(instance: MeshInstance3D, sampler: Callable, cfg: Dictionary) -> void:
	var faces := instance.mesh.get_faces()
	var bottom := instance.mesh.get_aabb().position.y
	var points: Array[Vector3] = []
	var point_ids := {}
	var bottom_faces: Array[Vector3i] = []
	var edges := {}
	for offset in range(0, faces.size() - 2, 3):
		var ids: Array[int] = []
		for index in range(offset, offset + 3):
			if absf(faces[index].y - bottom) > 0.0002:
				break
			if not point_ids.has(faces[index]):
				point_ids[faces[index]] = points.size()
				points.append(faces[index])
			ids.append(int(point_ids[faces[index]]))
		if ids.size() != 3:
			continue
		bottom_faces.append(Vector3i(ids[0], ids[1], ids[2]))
		for index in 3:
			var a := ids[index]
			var b := ids[(index + 1) % 3]
			var key := Vector2i(mini(a, b), maxi(a, b))
			var edge: Dictionary = edges.get(key, {"a": a, "b": b, "count": 0})
			edge["count"] = int(edge["count"]) + 1
			edges[key] = edge
	if bottom_faces.is_empty():
		push_warning("Gate footing has no source bottom faces: %s" % instance.name)
		return
	var lower: Array[Vector3] = []
	for point: Vector3 in points:
		var world := instance.to_global(point)
		var height: float = sampler.call(world)
		if not is_finite(height):
			push_warning("Gate footing lacks rendered support: %s" % instance.name)
			return
		world.y = height - float(cfg.get("embed_m", 0.06))
		lower.append(instance.to_local(world))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Vector3i in bottom_faces:
		_contact_triangle(tool, lower[face.x], lower[face.y], lower[face.z])
	for edge: Dictionary in edges.values():
		if int(edge["count"]) != 1:
			continue
		var a := int(edge["a"])
		var b := int(edge["b"])
		_contact_triangle(tool, points[a], points[b], lower[b])
		_contact_triangle(tool, points[a], lower[b], lower[a])
	tool.generate_normals()
	tool.generate_tangents()
	var footing := MeshInstance3D.new()
	footing.name = "RenderedGroundFooting"
	footing.mesh = tool.commit()
	footing.material_override = instance.material_override
	footing.set_meta("gate_role", "grounded_masonry_footing")
	instance.add_child(footing)


func _conform_paver(paver: MeshInstance3D, sampler: Callable, cfg: Dictionary) -> void:
	var box := (paver.mesh as BoxMesh).duplicate() as BoxMesh
	var step := maxf(0.25, float(cfg.get("paver_step_m", 0.5)))
	box.subdivide_width = maxi(0, ceili(box.size.x / step) - 1)
	box.subdivide_depth = maxi(0, ceili(box.size.z / step) - 1)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arrays := box.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var heights := {}
	for index in (indices.size() if not indices.is_empty() else vertices.size()):
		var vertex_index := int(indices[index]) if not indices.is_empty() else index
		var point := vertices[vertex_index]
		var key := Vector2(point.x, point.z)
		if not heights.has(key):
			var foot := paver.to_global(Vector3(point.x, -box.size.y * 0.5, point.z))
			var sampled: float = sampler.call(foot)
			if not is_finite(sampled):
				push_warning("Gate paving lacks rendered support: %s" % paver.name)
				return
			heights[key] = sampled
		var height := float(heights[key])
		var world := paver.to_global(point)
		world.y = height + (float(cfg.get("paver_clearance_m", 0.03)) if point.y > 0.0 else -float(cfg.get("embed_m", 0.06)))
		tool.set_uv(uvs[vertex_index])
		tool.add_vertex(paver.to_local(world))
	tool.generate_normals()
	tool.generate_tangents()
	paver.mesh = tool.commit()


static func _contact_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).abs()
	for point: Vector3 in [a, b, c]:
		var uv := Vector2(point.x, point.y)
		if normal.y >= normal.x and normal.y >= normal.z:
			uv = Vector2(point.x, point.z)
		elif normal.x >= normal.z:
			uv = Vector2(point.z, point.y)
		tool.set_uv(uv)
		tool.add_vertex(point)


func _add_banners(cfg: Dictionary, materials: Dictionary) -> void:
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(str(cfg.get("cloth_colour", "#315f6c")))
	cloth.roughness = 0.82
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color(str(cfg.get("trim_colour", "#d7b75b")))
	trim.metallic = 0.35
	trim.roughness = 0.48
	var size := _v2(cfg.get("size_m", [3.4, 7.8]))
	for side: float in [-1.0, 1.0]:
		var banner := MeshInstance3D.new()
		banner.name = "CloudreachGateBanner%s" % ("West" if side < 0.0 else "East")
		var plane := PlaneMesh.new()
		plane.orientation = PlaneMesh.FACE_Z
		plane.size = size
		plane.subdivide_width = 2
		plane.subdivide_depth = 5
		banner.mesh = plane
		banner.material_override = cloth
		banner.position = Vector3(side * float(cfg.get("side_x_m", 11.7)),
			float(cfg.get("height_m", 19.2)), float(cfg.get("forward_z_m", -1.25)))
		banner.set_meta("gate_role", "realm_banner")
		add_child(banner)
		_add_box("BannerTopTrim", banner.position + Vector3(0.0, size.y * 0.5 - 0.18, -0.03),
			Vector3(size.x + 0.35, 0.28, 0.18), trim, "banner_trim")
		_add_box("BannerSigilStem", banner.position + Vector3(0.0, 0.2, -0.04),
			Vector3(0.32, size.y * 0.56, 0.14), trim, "banner_sigil")
		var sigil := _add_box("BannerSigilWing", banner.position + Vector3(0.0, 0.7, -0.045),
			Vector3(size.x * 0.52, 0.32, 0.15), trim, "banner_sigil")
		sigil.rotation.z = deg_to_rad(18.0 * side)


func _add_emblem(cfg: Dictionary, materials: Dictionary) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "MeadowsHeartRealmEmblem"
	var torus := TorusMesh.new()
	torus.outer_radius = float(cfg.get("outer_radius_m", 2.7))
	torus.inner_radius = float(cfg.get("inner_radius_m", 2.15))
	torus.rings = 32
	torus.ring_segments = 12
	ring.mesh = torus
	ring.material_override = _material(materials, "bronze")
	ring.position = _v3(cfg.get("position", [0.0, 20.0, -1.55]))
	ring.rotation.x = PI * 0.5
	ring.set_meta("gate_role", "realm_emblem")
	add_child(ring)
	var core := _add_box("RealmEmblemCore", ring.position + Vector3(0.0, 0.0, -0.06),
		Vector3(1.35, 1.35, 0.20), _material(materials, "key_glow"), "realm_emblem_core")
	core.rotation.z = PI * 0.25


func _add_beacon(index: int, spec: Dictionary, light_cfg: Dictionary,
		materials: Dictionary, k: float = 1.0) -> void:
	var at := _v3(spec.get("position", [0.0, 0.0, 0.0]))
	_add_cylinder("ArrivalBeaconPlinth%02d" % (index + 1), at + Vector3.UP * 0.65 * k,
		1.15 * k, 1.3 * k, _material(materials, "masonry_trim"), "beacon_plinth")
	_add_cylinder("ArrivalBeaconBowl%02d" % (index + 1), at + Vector3.UP * 1.65 * k,
		0.82 * k, 0.35 * k, _material(materials, "bronze"), "beacon_bowl")
	var flame := MeshInstance3D.new()
	flame.name = "ArrivalBeaconFlame%02d" % (index + 1)
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.66
	flame_mesh.height = 1.7
	flame.mesh = flame_mesh
	flame.material_override = _material(materials, "key_glow")
	flame.position = at + Vector3.UP * 2.55 * k
	flame.scale = Vector3(0.72, 1.0, 0.72) * k
	flame.set_meta("gate_role", "arrival_flame")
	add_child(flame)
	var light := OmniLight3D.new()
	light.name = "ArrivalBeaconLight%02d" % (index + 1)
	light.light_color = Color(str(light_cfg.get("colour", "#72dcdb")))
	light.light_energy = float(light_cfg.get("energy", 2.4))
	light.omni_range = float(light_cfg.get("range_m", 23.0))
	light.shadow_enabled = bool(light_cfg.get("shadow_enabled", false))
	light.position = at + Vector3.UP * 3.0 * k
	light.set_meta("gate_role", "arrival_light")
	add_child(light)


func _add_box(label: String, at: Vector3, size: Vector3, material: Material,
		role: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = at
	mesh_instance.set_meta("gate_role", role)
	add_child(mesh_instance)
	return mesh_instance


func _add_scaled_mesh(label: String, mesh: Mesh, at: Vector3, size: Vector3,
		material: Material, role: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	var bounds := mesh.get_aabb()
	mesh_instance.scale = size / bounds.size
	mesh_instance.position = at - bounds.get_center() * mesh_instance.scale
	mesh_instance.set_meta("gate_role", role)
	add_child(mesh_instance)
	return mesh_instance


func _add_cylinder(label: String, at: Vector3, radius: float, height: float,
		material: Material, role: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.82
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = at
	mesh_instance.set_meta("gate_role", role)
	add_child(mesh_instance)
	return mesh_instance


func _material(materials: Dictionary, key: String) -> Material:
	var value: Variant = materials.get(key)
	if value is Material:
		return value as Material
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color("#8a8f82")
	fallback.roughness = 0.8
	return fallback


static func route_clear_half_width(cfg: Dictionary) -> float:
	return float(cfg.get("route_clear_half_width_m", 4.8))


static func _v2(raw: Variant) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
	return Vector2.ZERO


static func _v3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float((raw as Array)[0]), float((raw as Array)[1]),
			float((raw as Array)[2]))
	return Vector3.ZERO

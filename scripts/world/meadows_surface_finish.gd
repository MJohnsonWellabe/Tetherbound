extends Node

## Local, OFF-by-default F38 surface family. Retains source albedo, normal,
## alpha cutouts, wind shaders and authored occupation colours. No mesh edits.
const CONFIG := "res://data/config/meadows_look.json"
static var _settings: Dictionary = {}
static var _loaded := false
static var _normal: NoiseTexture2D
static var _detail: NoiseTexture2D
static var _toon_shaders: Dictionary = {}
var _world: Node
var _materials: Dictionary = {}
var _pending: PackedInt64Array = PackedInt64Array()
var _flush_queued := false


static func settings() -> Dictionary:
	if not _loaded:
		_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		if parsed is Dictionary:
			_settings = parsed.get("look_candidate", {})
	return _settings


static func finish_standard(source: BaseMaterial3D) -> BaseMaterial3D:
	if not bool(settings().get("enabled", false)) or source.has_meta("meadows_finish"):
		return source
	# Do not erase authored terms, emissive objects, glass, or actor skins.
	if source.emission_enabled or source.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		return source
	var texture_path := source.albedo_texture.resource_path if source.albedo_texture != null else ""
	if "/creatures/" in texture_path or "/characters/" in texture_path:
		return source
	if source.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
		return source
	var surface: Dictionary = settings().get("surface", {})
	var rim_strength := clampf(float(surface.get("rim_strength", 0.16)), 0.0, 1.0)
	var add_rim := bool(surface.get("rim_enabled", true)) and not source.rim_enabled and rim_strength > 0.0
	var add_toon := bool(surface.get("toon_enabled", false)) and source.diffuse_mode != BaseMaterial3D.DIFFUSE_TOON
	# StandardMaterial mixes normals with detail-albedo alpha. Our opaque
	# detail would replace an authored base normal, not layer onto it. UV2
	# triplanar also cannot take over the UVs of an authored AO map.
	var add_detail := not source.detail_enabled and not source.normal_enabled \
			and not (source.ao_enabled and source.ao_on_uv2)
	if not add_detail and not add_rim and not add_toon:
		return source
	var result := source.duplicate() as BaseMaterial3D
	result.set_meta("meadows_finish", true)
	if add_toon:
		result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	if add_detail:
		_ensure_textures()
		result.detail_enabled = true
		result.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		result.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
		result.uv2_triplanar = true
		result.uv2_world_triplanar = true
		result.uv2_scale = Vector3.ONE * float(surface.get("detail_scale", 2.0))
		result.detail_albedo = _detail
		result.detail_normal = _normal
	if add_rim:
		result.rim_enabled = true
		result.rim = rim_strength
		result.rim_tint = clampf(float(surface.get("rim_tint", 0.7)), 0.0, 1.0)
	return result


static func finish_shader(source: Shader) -> Shader:
	if source == null or not bool(settings().get("enabled", false)) \
			or not bool(settings().get("surface", {}).get("toon_enabled", false)):
		return source
	# Only explicitly opted-in environment shaders have this compile-time arm.
	# Keep the original resource intact, including for other realms using it.
	if source.has_meta("meadows_toon") or not source.code.contains("#ifdef MEADOWS_TOON"):
		return source
	if _toon_shaders.has(source):
		return _toon_shaders[source]
	var result := Shader.new()
	result.code = "#define MEADOWS_TOON\n" + source.code
	result.set_meta("meadows_toon", true)
	_toon_shaders[source] = result
	return result


static func _apply_toon_shader(material: ShaderMaterial) -> void:
	var original := material.shader
	var replacement := finish_shader(original)
	if replacement == original:
		return
	# Preserve all live writer inputs when selecting the variant. The material
	# identity stays fixed so later streaming/wind/terrain updates still land.
	var parameters := {}
	var terrain_maps := {}
	for uniform: Dictionary in original.get_shader_uniform_list():
		var key := str(uniform.name)
		parameters[key] = material.get_shader_parameter(key)
		# grass_field binds Terrain3D's texture RIDs directly to RenderingServer.
		# ShaderMaterial's parameter cache does not contain those bindings;
		# restoring its null below would detach cover from the terrain maps.
		if key in ["_height_maps", "_control_maps", "_color_maps"]:
			var binding: Variant = RenderingServer.material_get_param(material.get_rid(), key)
			if binding is RID and binding.is_valid():
				terrain_maps[key] = binding
	material.shader = replacement
	for key: String in parameters:
		material.set_shader_parameter(key, parameters[key])
	for key: String in terrain_maps:
		RenderingServer.material_set_param(material.get_rid(), key, terrain_maps[key])


static func _ensure_textures() -> void:
	if _normal != null:
		return
	var surface: Dictionary = settings().get("surface", {})
	var noise := FastNoiseLite.new()
	noise.seed = 38013
	noise.frequency = 0.04
	noise.fractal_octaves = 3
	_normal = NoiseTexture2D.new()
	_normal.width = 128
	_normal.height = 128
	_normal.seamless = true
	_normal.generate_mipmaps = true
	_normal.as_normal_map = true
	_normal.bump_strength = float(surface.get("normal_strength", 0.18))
	_normal.noise = noise
	_detail = NoiseTexture2D.new()
	_detail.width = 128
	_detail.height = 128
	_detail.seamless = true
	_detail.generate_mipmaps = true
	var ramp := Gradient.new()
	var strength := float(surface.get("detail_strength", 0.08))
	ramp.colors = PackedColorArray([Color(1.0 - strength, 1.0 - strength, 1.0 - strength), Color.WHITE])
	_detail.color_ramp = ramp
	_detail.noise = noise


static func shader_parameters() -> Dictionary:
	var surface: Dictionary = settings().get("surface", {})
	return {
		"meadows_finish_enabled": bool(settings().get("enabled", false)),
		"meadows_detail_scale": float(surface.get("detail_scale", 2.0)),
		"meadows_detail_strength": float(surface.get("detail_strength", 0.08)),
		"meadows_normal_strength": float(surface.get("normal_strength", 0.18)),
		"meadows_detail_distance": float(surface.get("detail_distance_m", 35.0)),
		"meadows_rim_enabled": bool(settings().get("enabled", false)) and bool(surface.get("rim_enabled", true)),
		"meadows_rim_strength": clampf(float(surface.get("rim_strength", 0.16)), 0.0, 1.0),
		"meadows_rim_tint": clampf(float(surface.get("rim_tint", 0.7)), 0.0, 1.0),
	}


static func apply_terrain(material: Object) -> void:
	if not material.has_method("set_shader_param"):
		return
	for key: String in shader_parameters():
		material.call("set_shader_param", key, shader_parameters()[key])


func watch(world: Node) -> void:
	_world = world
	get_tree().node_added.connect(_node_added)
	_visit.call_deferred(world)


func _node_added(node: Node) -> void:
	# Builders assign materials after add_child. As in detail_cull, batch IDs
	# behind one deferred call: a whole realm can overflow the message queue
	# with one callback per node. IDs also let freed nodes disappear safely.
	if not node is GeometryInstance3D:
		return
	if is_instance_valid(_world) and _world.is_ancestor_of(node):
		_pending.append(node.get_instance_id())
		if not _flush_queued:
			_flush_queued = true
			_flush_pending.call_deferred()


func _flush_pending() -> void:
	_flush_queued = false
	var ids := _pending
	_pending = PackedInt64Array()
	for id: int in ids:
		var node := instance_from_id(id) as GeometryInstance3D
		if node != null:
			_finish_node(node)


func _visit(node: Node) -> void:
	if not is_instance_valid(node):
		return
	_finish_node(node)
	for child in node.get_children():
		_visit(child)


func _finish_node(node: Node) -> void:
	if not is_instance_valid(node) or not is_instance_valid(_world):
		return
	if node != _world and not _world.is_ancestor_of(node):
		return
	var ancestor := node
	while ancestor != _world and ancestor != null:
		if ancestor is CharacterBody3D or ancestor is Skeleton3D:
			return
		var script := ancestor.get_script() as Script
		if script != null and ("/creatures/" in script.resource_path or "/characters/" in script.resource_path):
			return
		ancestor = ancestor.get_parent()
	if node is GeometryInstance3D:
		var geometry := node as GeometryInstance3D
		if geometry.has_meta("meadows_finish"):
			return
		geometry.set_meta("meadows_finish", true)
		if geometry.material_override != null:
			geometry.material_override = _finish(geometry.material_override)
		elif node is MeshInstance3D and node.mesh != null:
			for index in node.mesh.get_surface_count():
				node.set_surface_override_material(index, _finish(node.get_active_material(index)))
		elif node is MultiMeshInstance3D and node.multimesh != null and node.multimesh.mesh != null:
			node.multimesh = _finish_multimesh(node.multimesh)


func _finish_multimesh(source: MultiMesh) -> MultiMesh:
	if source.mesh == null or source.mesh.has_meta("meadows_finish"):
		return source
	var materials: Array[Material] = []
	var changed := false
	for index in source.mesh.get_surface_count():
		var before := source.mesh.surface_get_material(index)
		var after := _finish(before)
		changed = changed or before != after
		materials.append(after)
	if not changed:
		return source
	# Keep the live instance buffer that the builder/streamer owns. Only the
	# mesh's material slots need a private copy. Loaded MultiMesh resources are
	# shared assets; runtime ones belong to this world's builder and stay live.
	var finished := source if source.resource_path.is_empty() else source.duplicate() as MultiMesh
	var mesh := source.mesh.duplicate() as Mesh
	for index in materials.size():
		mesh.surface_set_material(index, materials[index])
	mesh.set_meta("meadows_finish", true)
	finished.mesh = mesh
	return finished


func _finish(source: Material) -> Material:
	if source == null:
		return source
	if _materials.has(source):
		return _materials[source]
	var result := source
	if source is BaseMaterial3D:
		result = finish_standard(source)
	elif source is ShaderMaterial and source.shader != null:
		for uniform: Dictionary in source.shader.get_shader_uniform_list():
			if str(uniform.name) == "meadows_finish_enabled":
				# Runtime grass/cover builders retain this very material to drive
				# terrain textures, streaming coordinates and wind. Replacing it
				# would disconnect those updates. Loaded assets still need a copy.
				result = source if source.resource_path.is_empty() else source.duplicate()
				_apply_toon_shader(result as ShaderMaterial)
				for key: String in shader_parameters():
					(result as ShaderMaterial).set_shader_parameter(key, shader_parameters()[key])
				break
	_materials[source] = result
	_materials[result] = result
	return result

extends Node

## F41 presentation candidate, owned entirely by the Stormwood scene. The same
## profile supplies the pinned rig and every environment material adapter.
## Resources are duplicated/cached per scene; nothing mutates imported assets.
const CONFIG_PATH := "res://data/config/stormwood_look.json"
const DETAIL_INCLUDE := "#include \"res://shaders/stormwood_surface_detail.gdshaderinc\"\n"
const DETAIL_CALL := "\n\tsw_surface_detail(ALBEDO, NORMAL, ROUGHNESS, (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz, mat3(VIEW_MATRIX));\n"
## Set only by the committed capture harness before the production world mounts.
## This process-local preview never writes a config or a save.
static var capture_preview := false
## Set only by tests that need the profile off while the shipped config is ON.
static var test_disabled := false
var config: Dictionary = {}
var _materials: Dictionary = {}
var _meshes: Dictionary = {}
var _shaders: Dictionary = {}
var _detail_colour: NoiseTexture2D
var _detail_normal: NoiseTexture2D
var _pending: Array[Node] = []
var _queued: Dictionary = {}


static func read_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		return {}
	if capture_preview:
		parsed["enabled"] = true
	if test_disabled:
		parsed["enabled"] = false
	return parsed


static func rig_overrides(base: Dictionary, profile: Dictionary) -> Dictionary:
	if not bool(profile.get("enabled", false)):
		return base
	var out := base.duplicate(true)
	var overrides: Dictionary = out.get("overrides", {}).duplicate(true)
	for section: String in profile.get("rig", {}):
		var values: Dictionary = overrides.get(section, {}).duplicate(true)
		values.merge(profile.rig[section], true)
		overrides[section] = values
	# r26 storm light (OFF until judged): its environment keys ride on the rig.
	var storm: Dictionary = profile.get("storm_light", {})
	if bool(storm.get("enabled", false)):
		var environment: Dictionary = overrides.get("environment", {}).duplicate(true)
		environment.merge(storm.get("environment", {}), true)
		overrides["environment"] = environment
	out["overrides"] = overrides
	# Stormwood never acquires a day/night presentation, even in aftermath.
	out["pin_time_of_day"] = true
	return out


func _ready() -> void:
	set_process(false)
	if config.is_empty():
		config = read_config()
	if not bool(config.get("enabled", false)):
		return
	_build_detail_textures()
	_add_storm_rim.call_deferred()


## r26 (GPU R verdict, path item 2: "lift the single dark mid-tone with
## storm-light key and rim light"): a cool, low, shadowless back light from
## the side opposite the sun, so trunks, creatures and the trainer pick up a
## lit edge against the storm. Presentation only.
func _add_storm_rim() -> void:
	var storm: Dictionary = config.get("storm_light", {})
	if not bool(storm.get("enabled", false)) or get_parent() == null:
		return
	var rim := DirectionalLight3D.new()
	rim.name = "StormRimLight"
	rim.light_color = Color(str(storm.get("rim_colour", "#93a8ff")))
	rim.light_energy = float(storm.get("rim_energy", 0.55))
	rim.shadow_enabled = false
	rim.light_specular = float(storm.get("rim_specular", 0.6))
	var angle: Array = storm.get("rim_rotation_deg", [-14.0, 320.0])
	rim.rotation_degrees = Vector3(float(angle[0]), float(angle[1]), 0.0)
	get_parent().add_child(rim)


func begin_world_walk() -> void:
	if not bool(config.get("enabled", false)):
		return
	# Builders yield while attaching geometry. Start only after their initial
	# build finishes so a node cannot be consumed before its mesh is assigned.
	get_tree().node_added.connect(_node_added)
	_queue(get_parent())
	set_process(true)


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_node_added):
		get_tree().node_added.disconnect(_node_added)


func _node_added(node: Node) -> void:
	if get_parent().is_ancestor_of(node):
		_queue(node)


func _queue(node: Node) -> void:
	var id := node.get_instance_id()
	if not _queued.has(id):
		_queued[id] = true
		_pending.append(node)


func _process(_delta: float) -> void:
	# Bounded traversal, including streamed vegetation and later camp pieces.
	# node_added can arrive before a builder assigns the mesh; processing occurs
	# after the builder returns rather than changing a half-built material.
	for _step in mini(_pending.size(), 128):
		# Streaming can free a queued node first; check before typing it.
		var popped: Variant = _pending.pop_back()
		if not is_instance_valid(popped):
			continue
		var node: Node = popped
		_queued.erase(node.get_instance_id())
		for child: Node in node.get_children():
			_queue(child)
		if eligible(node):
			_apply_geometry(node)


func eligible(node: Node) -> bool:
	if not (node is MeshInstance3D or node is MultiMeshInstance3D):
		return false
	var cursor := node
	var admitted := false
	var roots: Array = config.get("materials", {}).get("world_roots", [])
	var groups: Array = config.get("materials", {}).get("world_groups", [])
	while cursor != null and cursor != get_parent():
		# A creature/NPC nested inside an environmental root stays untouched.
		if cursor is CharacterBody3D or cursor.is_in_group("local_player"):
			return false
		var script := cursor.get_script() as Script
		if script != null and (script.resource_path.begins_with("res://scripts/characters/") \
				or script.resource_path.begins_with("res://scripts/npc/") \
				or script.resource_path.begins_with("res://scripts/creatures/")):
			return false
		if str(cursor.name) in roots:
			admitted = true
		# BuildPlacer attaches committed pieces to the world, not to itself.
		# Its group is assigned before the queued walk runs; ghosts lack it.
		for group: String in groups:
			if cursor.is_in_group(group):
				admitted = true
		cursor = cursor.get_parent()
	return admitted and cursor == get_parent()


func _build_detail_textures() -> void:
	var cfg: Dictionary = config.materials
	var noise := FastNoiseLite.new()
	noise.seed = int(cfg.noise_seed)
	noise.frequency = float(cfg.noise_frequency)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(str(cfg.detail_low)))
	ramp.set_color(1, Color(str(cfg.detail_high)))
	_detail_colour = NoiseTexture2D.new()
	_detail_colour.width = int(cfg.detail_size)
	_detail_colour.height = int(cfg.detail_size)
	_detail_colour.seamless = true
	_detail_colour.noise = noise
	_detail_colour.color_ramp = ramp
	_detail_normal = NoiseTexture2D.new()
	_detail_normal.width = int(cfg.detail_size)
	_detail_normal.height = int(cfg.detail_size)
	_detail_normal.seamless = true
	_detail_normal.noise = noise
	_detail_normal.as_normal_map = true
	_detail_normal.bump_strength = float(cfg.normal_bump_strength)


func _apply_geometry(node: GeometryInstance3D) -> void:
	if node.material_override != null:
		node.material_override = adapt_material(node.material_override)
		return
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			return
		for surface in mesh_node.mesh.get_surface_count():
			var original := mesh_node.get_active_material(surface)
			var adapted := adapt_material(original)
			if adapted != original:
				mesh_node.set_surface_override_material(surface, adapted)
	elif node is MultiMeshInstance3D:
		var multi_node := node as MultiMeshInstance3D
		if multi_node.multimesh == null or multi_node.multimesh.mesh == null:
			return
		if multi_node.has_meta(&"stormwood_look_adapted"):
			return
		# Vegetation owns each runtime MultiMesh. Keep its instance buffer and
		# streaming/harvest references intact; only copy the mesh resource.
		var multi := multi_node.multimesh
		multi.mesh = adapt_mesh(multi.mesh)
		multi_node.multimesh = multi
		multi_node.set_meta(&"stormwood_look_adapted", true)


func adapt_mesh(source: Mesh) -> Mesh:
	if source == null or source.has_meta(&"stormwood_look_adapted"):
		return source
	var key := source.get_instance_id()
	if _meshes.has(key):
		return _meshes[key]
	# The vegetation builder calls this before packing Terrain3D's scene_file.
	# Its render-server-owned instances do not appear in the scene-node walk.
	var result := source.duplicate() as Mesh
	for surface in result.get_surface_count():
		result.surface_set_material(surface, adapt_material(result.surface_get_material(surface)))
	result.set_meta(&"stormwood_look_adapted", true)
	_meshes[key] = result
	return result


func adapt_material(source: Material) -> Material:
	if source == null or source.has_meta(&"stormwood_look_adapted"):
		return source
	var key := source.get_instance_id()
	if _materials.has(key):
		return _materials[key]
	var cfg: Dictionary = config.materials
	var result: Material = source
	if source is StandardMaterial3D:
		var original := source as StandardMaterial3D
		# Preserve lamps, cores, glass, water and other semantic/emissive effects.
		if original.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL \
				or original.emission_enabled or original.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
			return source
		var material := original.duplicate() as StandardMaterial3D
		material.detail_enabled = true
		material.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		material.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
		material.uv2_triplanar = true
		material.uv2_world_triplanar = true
		material.uv2_scale = Vector3.ONE * float(cfg.detail_uv_scale)
		material.detail_albedo = _detail_colour
		material.detail_normal = _detail_normal
		material.roughness = maxf(float(cfg.roughness_floor), original.roughness * float(cfg.roughness_scale))
		material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		material.metallic_specular = float(cfg.foliage_specular) \
			if original.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR else float(cfg.solid_specular)
		result = material
	elif source is ShaderMaterial:
		var original := source as ShaderMaterial
		if original.shader == null or not original.shader.resource_path in cfg.shader_paths:
			return source
		var path := original.shader.resource_path
		if not _shaders.has(path):
			var code := detail_shader_code(original.shader.code)
			if code.is_empty():
				push_error("Stormwood look: missing fragment anchor in " + path)
				return source
			var shader := Shader.new()
			shader.code = code
			_shaders[path] = shader
		# Whitelisted shaders are constructed by realm-local builders. Keep the
		# material object so their wind/terrain/camera uniform updates still reach
		# it; only the shader is replaced. No shared imported resource is edited.
		var material := original
		var parameters: Dictionary = {}
		for uniform: Dictionary in original.shader.get_shader_uniform_list():
			var value: Variant = original.get_shader_parameter(uniform.name)
			if value != null:
				parameters[uniform.name] = value
		material.shader = _shaders[path]
		for parameter: String in parameters:
			material.set_shader_parameter(parameter, parameters[parameter])
		material.set_shader_parameter("sw_normal_strength", float(cfg.shader_normal_strength))
		material.set_shader_parameter("sw_detail_strength", float(cfg.shader_detail_strength))
		material.set_shader_parameter("sw_detail_frequency", float(cfg.shader_detail_frequency))
		material.set_shader_parameter("sw_roughness_scale", float(cfg.shader_roughness_scale))
		result = material
	if result != source or source is ShaderMaterial:
		result.set_meta(&"stormwood_look_adapted", true)
	_materials[key] = result
	return result


static func detail_shader_code(source: String) -> String:
	# All admitted field/canopy/deck shaders end in fragment(). Refuse a changed
	# layout rather than silently insert into a later light() or helper function.
	var start := source.find("void fragment()")
	var tail := source.rfind("}")
	if start < 0 or tail < start:
		return ""
	var fragment := source.substr(start)
	var comments := RegEx.new()
	comments.compile("(?s)/\\*.*?\\*/|//[^\\n]*")
	var clean := comments.sub(fragment, "", true)
	var depth := 0
	for i in clean.length():
		if clean[i] == "{":
			depth += 1
		elif clean[i] == "}":
			depth -= 1
			if depth == 0 and not clean.substr(i + 1).strip_edges().is_empty():
				return ""
	if depth != 0:
		return ""
	return source.substr(0, start) + DETAIL_INCLUDE + source.substr(start, tail - start) + DETAIL_CALL + source.substr(tail)

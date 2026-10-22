extends RefCounted

## F10#2 candidate: add a dither corridor to supported StandardMaterial surfaces.
## Unknown non-default features and custom shaders retain their original material.
## No instance removal/restoration, harvest mutation, collider or scale change.
const STANDARD := preload("res://scripts/world/foliage_standard_shader.gd")
const DECLARATIONS := """
uniform vec3 tb_fight_eye = vec3(0.0);
uniform vec3 tb_fight_target = vec3(0.0);
uniform vec3 tb_fight_target_b = vec3(0.0);
uniform float tb_fight_strength = 0.0;
uniform float tb_fight_radius = 1.5;
uniform float tb_fight_feather = 0.65;
uniform float tb_fight_visibility = 0.08;
uniform float tb_fight_lens_near = 0.0;
uniform float tb_fight_lens_far = 0.0;
"""
const FRAGMENT := """
    // VERTEX is already in view space; this works for MultiMesh instances too.
    if (tb_fight_strength > 0.0) {
        vec3 tb_world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
        float tb_cover = 0.0;
        // Two sight lines: the eye to each fighter (the same point twice when
        // only the arena centre is published).
        for (int tb_i = 0; tb_i < 2; tb_i++) {
            vec3 tb_line = (tb_i == 0 ? tb_fight_target : tb_fight_target_b) - tb_fight_eye;
            float tb_length_sq = dot(tb_line, tb_line);
            if (tb_length_sq > 0.01) {
                float tb_t = dot(tb_world - tb_fight_eye, tb_line) / tb_length_sq;
                if (tb_t > 0.0 && tb_t < 0.92) {
                    float tb_gap = distance(tb_world, tb_fight_eye + tb_line * tb_t);
                    tb_cover = max(tb_cover, 1.0 - smoothstep(tb_fight_radius,
                        tb_fight_radius + tb_fight_feather, tb_gap));
                }
            }
        }
        float tb_alpha = mix(1.0, tb_fight_visibility, tb_cover * tb_fight_strength);
        // The fight's own near-lens band (exploration keeps the baked band):
        // pixels this close to the lens dither out only while a fight runs.
        if (tb_fight_lens_far > tb_fight_lens_near) {
            float tb_lens = smoothstep(tb_fight_lens_near, tb_fight_lens_far, length(VERTEX));
            tb_alpha = min(tb_alpha, mix(1.0, tb_lens, tb_fight_strength));
        }
        float tb_threshold = fract(52.9829189 * fract(dot(floor(FRAGCOORD.xy),
            vec2(0.06711056, 0.00583715))));
        if (tb_alpha < tb_threshold) { discard; }
    }
"""
var _materials: Array[ShaderMaterial] = []
var _owners: Dictionary = {}
var _config: Dictionary = {}
var _strength := 0.0


func has_materials() -> bool:
	return not _materials.is_empty()


## `enabled` turns the fade on for every listed realm; `enabled_realms` turns it
## on for only those realms (F22#4: the Meadows Riverwatch draw on its own).
static func configured(realm: String, config: Dictionary) -> bool:
	var on: bool = bool(config.get("enabled", false)) or realm in config.get("enabled_realms", [])
	return on and realm in config.get("realms", []) and not config.get("models", []).is_empty()


static func eligible(model: String, realm: String, config: Dictionary) -> bool:
	return configured(realm, config) and model in config.get("models", [])


## Refuse unknown generated layouts instead of silently losing source features.
static func inject(source: String) -> String:
	if not source.contains("shader_type spatial;") or source.contains("tb_fight_strength"):
		return ""
	var pattern := RegEx.new()
	pattern.compile("void\\s+fragment\\s*\\(\\s*\\)\\s*\\{")
	var matches := pattern.search_all(source)
	if matches.size() != 1:
		return ""
	var at := matches[0].get_end()
	var result := source.substr(0, at) + FRAGMENT + source.substr(at)
	# Godot requires shader/render directives before uniform declarations.
	var directives := RegEx.new()
	directives.compile("\\brender_mode\\s+[^;]+;")
	var declaration_at := result.find("shader_type spatial;") + "shader_type spatial;".length()
	for directive in directives.search_all(result):
		declaration_at = maxi(declaration_at, directive.get_end())
	return result.substr(0, declaration_at) + "\n" + DECLARATIONS + result.substr(declaration_at)


func apply(mesh: Mesh, model: String, realm: String, config: Dictionary) -> Mesh:
	if mesh == null or not eligible(model, realm, config):
		return mesh
	_config = config.duplicate(true)
	var result := mesh.duplicate(false) as Mesh
	for surface in mesh.get_surface_count():
		var source := mesh.surface_get_material(surface) as BaseMaterial3D
		# Custom look shaders need their own reviewed hook; never replace them.
		if source == null or source.next_pass != null:
			continue
		var code := inject(STANDARD.code(source))
		if code.is_empty():
			continue
		var shader := Shader.new()
		shader.code = code
		var material := ShaderMaterial.new()
		material.shader = shader
		# get_rid() initializes the source's native shader/parameters. Its RID
		# getter is script-callable; get_shader_rid() is C++-only in Godot 4.7.
		var material_rid: RID = source.get_rid()
		for parameter: Dictionary in shader.get_shader_uniform_list():
			if str(parameter.name).begins_with("tb_fight_"): continue
			var value: Variant = RenderingServer.material_get_param(material_rid, parameter.name)
			material.set_shader_parameter(parameter.name, value)
		material.render_priority = source.render_priority
		material.resource_local_to_scene = source.resource_local_to_scene
		material.set_meta("fight_fade_source", source) # Retain source textures/RIDs.
		material.set_shader_parameter("tb_fight_radius", maxf(0.0, float(config.get("clear_radius_m", 1.5))))
		material.set_shader_parameter("tb_fight_feather", maxf(0.01, float(config.get("feather_m", 0.65))))
		material.set_shader_parameter("tb_fight_visibility", clampf(float(config.get("minimum_visibility", 0.08)), 0.0, 1.0))
		if config.has("near_lens_opaque_above_m"):
			var lens_near := maxf(0.0, float(config.get("near_lens_invisible_below_m", 0.0)))
			material.set_shader_parameter("tb_fight_lens_near", lens_near)
			material.set_shader_parameter("tb_fight_lens_far", maxf(lens_near + 0.1, float(config.near_lens_opaque_above_m)))
		_materials.append(material)
		result.surface_set_material(surface, material)
	return result


func clear() -> void:
	# Terrain/queued nodes can still retain the old materials for a frame.
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter("tb_fight_strength", 0.0)
	_materials.clear()
	_owners.clear()
	_strength = 0.0


func target(owner_id: int, position: Vector3, second: Vector3 = Vector3.INF) -> void:
	if position.is_finite():
		_owners[owner_id] = [position, second if second.is_finite() else position]
	else:
		_owners.erase(owner_id)
	if _owners.is_empty():
		_strength = 0.0
		for material: ShaderMaterial in _materials:
			material.set_shader_parameter("tb_fight_strength", 0.0)


func update(eye: Vector3, delta: float) -> void:
	if _materials.is_empty():
		return
	var nearest := Vector3.INF
	var nearest_b := Vector3.INF
	var distance := INF
	if eye.is_finite():
		for pair: Array in _owners.values():
			var position: Vector3 = pair[0]
			var gap := eye.distance_squared_to(position)
			if gap < distance:
				distance = gap
				nearest = position
				nearest_b = pair[1]
	var goal := 1.0 if nearest.is_finite() else 0.0
	var seconds := maxf(0.01, float(_config.get("transition_seconds", 0.2)))
	_strength = move_toward(_strength, goal, maxf(0.0, delta) / seconds)
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter("tb_fight_strength", _strength if nearest.is_finite() else 0.0)
		if nearest.is_finite():
			material.set_shader_parameter("tb_fight_eye", eye)
			material.set_shader_parameter("tb_fight_target", nearest)
			material.set_shader_parameter("tb_fight_target_b", nearest_b)

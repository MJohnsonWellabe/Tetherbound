extends RefCounted

## P2-033 sight line: the Meadows gate potion reads from the approach. Its
## decorative cover is cleared in a ring at the flask and one offset toward
## the approach stand, its cap takes a warm ivory/amber tint over the green
## flask, and a small depth-tested glint above the cap holds its screen size
## out to mid distance with a slow twinkle. Presentation only; independent
## OFF flag; runs after meadows_potion_presentation.
const CONFIG := "res://data/config/meadows_potion_sightline.json"
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
static var _settings: Dictionary = {}


static func settings() -> Dictionary:
	if _settings.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		if parsed is Dictionary:
			_settings = parsed
	return _settings


static func enabled() -> bool:
	return bool(settings().get("potion_sightline_enabled", false))


static func _centres() -> Array:
	var cfg := settings()
	var at := Vector2(float(cfg.authored_xz[0]), float(cfg.authored_xz[1]))
	var offset := Vector2(float(cfg.clear_offset_xz[0]), float(cfg.clear_offset_xz[1]))
	return [[at, float(cfg.clear_radius_m)], [at + offset, float(cfg.clear_offset_radius_m)]]


## Decorative draw instances only (called after harvest identities exist).
static func suppress_cover(layer: String, placement: Dictionary) -> bool:
	if not enabled() or not settings().get("decorative_cover_layers", []).has(layer):
		return false
	if placement.has("harvest_item") or bool(placement.get("collide", false)):
		return false
	var at: Vector3 = placement.get("position", Vector3.ZERO)
	for circle: Array in _centres():
		if Vector2(at.x, at.z).distance_to(circle[0]) < float(circle[1]):
			return true
	return false


static func apply(pickup: Node3D) -> void:
	var cfg := settings()
	if not enabled() or str(pickup.get("_placement_id")) != str(cfg.placement_id) \
			or str(pickup.get("_item_id")) != str(cfg.item_id) or str(pickup.get("_realm_id")) != "meadows" \
			or bool(pickup.get("_taken")) or pickup.has_meta("p2_033_sightline"):
		return
	var visual := pickup.get("_visual") as Node3D
	if visual == null:
		return
	var bounds: AABB = visual.transform * BOUNDS.measure(visual)
	if bounds.size.y <= 0.0:
		return
	# Grass-field clearings: the flask itself and one toward the approach.
	var centres := _centres()
	for index in centres.size():
		var marker := Node3D.new()
		marker.name = "PotionSightlineClearing%d" % index
		pickup.add_child(marker)
		var xz: Vector2 = centres[index][0]
		marker.global_position = Vector3(xz.x, pickup.global_position.y, xz.y)
		marker.set_meta(GRASS_FIELD.CLEAR_RADIUS_META, float(centres[index][1]))
		marker.add_to_group(GRASS_FIELD.CLEAR_GROUP)
	GRASS_FIELD.clearings_dirty = true
	pickup.tree_exiting.connect(func() -> void: GRASS_FIELD.clearings_dirty = true)
	# Cap tint: an overlay that paints the top of the flask warm ivory/amber.
	var cap: Dictionary = cfg.cap
	var overlay := ShaderMaterial.new()
	overlay.shader = _cap_shader()
	overlay.set_shader_parameter("cap_colour", Color(str(cap.colour)))
	overlay.set_shader_parameter("cap_from_y", pickup.global_position.y + bounds.end.y - bounds.size.y * float(cap.from_top_fraction))
	overlay.set_shader_parameter("mix_amount", float(cap.mix))
	for mesh: Node in visual.find_children("*", "GeometryInstance3D", true, false):
		(mesh as GeometryInstance3D).material_overlay = overlay
	# Glint above the cap.
	var look: Dictionary = cfg.glint
	var glint := MeshInstance3D.new()
	glint.name = "PotionSightlineGlint"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * float(look.size_m)
	glint.mesh = quad
	var material := ShaderMaterial.new()
	material.shader = _glint_shader()
	material.set_shader_parameter("glint_colour", Color(str(look.colour)))
	for key: String in ["reference_distance_m", "max_scale", "fade_out_from_m", "fade_out_to_m", "strength", "twinkle_hz"]:
		material.set_shader_parameter(key, float(look[key]))
	glint.material_override = material
	glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glint.position = Vector3(bounds.get_center().x, bounds.end.y + float(look.above_top_m), bounds.get_center().z)
	pickup.add_child(glint)
	pickup.set_meta("p2_033_sightline", {"clearings": centres.size(), "item_height_m": bounds.size.y})


static func _cap_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode blend_mix, depth_draw_never, depth_test_default, cull_back;
uniform vec4 cap_colour : source_color;
uniform float cap_from_y = 0.0;
uniform float mix_amount = 0.85;
varying float world_y;
void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}
void fragment() {
	float cap = smoothstep(cap_from_y - 0.01, cap_from_y + 0.01, world_y);
	ALBEDO = cap_colour.rgb;
	ROUGHNESS = 0.55;
	ALPHA = cap * mix_amount;
}
"""
	return shader


static func _glint_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 glint_colour : source_color;
uniform float reference_distance_m = 6.0;
uniform float max_scale = 6.0;
uniform float fade_out_from_m = 34.0;
uniform float fade_out_to_m = 42.0;
uniform float strength = 1.6;
uniform float twinkle_hz = 0.6;
varying float fade;
void vertex() {
	vec3 centre = MODEL_MATRIX[3].xyz;
	float d = length(centre - CAMERA_POSITION_WORLD);
	// Hold screen size past the reference distance (capped), then fade out.
	float grow = clamp(d / reference_distance_m, 1.0, max_scale);
	fade = 1.0 - smoothstep(fade_out_from_m, fade_out_to_m, d);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * grow, INV_VIEW_MATRIX[1] * grow, INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	// Four-point star: two thin crossed rays plus a soft core.
	float rays = max(exp(-abs(p.x) * 18.0) * (1.0 - abs(p.y)), exp(-abs(p.y) * 18.0) * (1.0 - abs(p.x)));
	float core = exp(-dot(p, p) * 9.0);
	float twinkle = 0.75 + 0.25 * sin(TIME * 6.2831 * twinkle_hz);
	float a = clamp((rays * 0.8 + core) * strength * twinkle * fade, 0.0, 1.0);
	ALBEDO = glint_colour.rgb * a;
	ALPHA = a;
}
"""
	return shader

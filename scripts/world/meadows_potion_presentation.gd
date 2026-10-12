extends RefCounted

## One named Meadows find; no inventory, save, RPC or harvest mutation.
const CONFIG := "res://data/config/meadows_potion_presentation.json"
const GLOW_SHADER := preload("res://shaders/meadows_potion_glow.gdshader")
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const PLACEMENT := "b1_potion_gate_meadow"
const ITEM := "potion_small"
static var _settings: Dictionary = {}
static var _active := -1


static func settings() -> Dictionary:
	if _settings.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		if parsed is Dictionary:
			_settings = parsed
	return _settings


static func enabled() -> bool:
	if _active < 0:
		var args := OS.get_cmdline_user_args()
		_active = 1 if not args.has("--p2-033-baseline") and \
				(bool(settings().get("enabled", false)) or args.has("--p2-033-candidate")) else 0
	return _active == 1


static func suppress_cover(layer: String, placement: Dictionary) -> bool:
	if not enabled() or not settings().get("decorative_cover_layers", []).has(layer):
		return false
	# Called after harvest identities are assigned; never remove those draws.
	if placement.has("harvest_item") or bool(placement.get("collide", false)):
		return false
	var at: Vector3 = placement.get("position", Vector3.ZERO)
	var authored: Array = settings().get("authored_xz", [])
	if authored.size() != 2:
		return false
	return Vector2(at.x, at.z).distance_to(Vector2(float(authored[0]), float(authored[1]))) \
			< float(settings().get("grass_clear_radius_m", 0.0))


static func apply(pickup: Node3D) -> void:
	if not enabled() or str(pickup.get("_placement_id")) != PLACEMENT \
			or str(pickup.get("_item_id")) != ITEM or str(pickup.get("_realm_id")) != "meadows" \
			or bool(pickup.get("_taken")) or pickup.has_meta("p2_033_presentation"):
		return
	var visual := pickup.get("_visual") as Node3D
	if visual == null or visual.name != "ItemIdentity":
		return
	visual.scale *= float(settings().get("visual_scale", 1.0))
	# Measure only the installed item before adding its halo. Preserve its foot.
	var bounds: AABB = visual.transform * BOUNDS.measure(visual)
	if bounds.size.y <= 0.0:
		return
	var radius := float(settings().get("grass_clear_radius_m", 0.0))
	pickup.set_meta(GRASS_FIELD.CLEAR_RADIUS_META, radius)
	pickup.add_to_group(GRASS_FIELD.CLEAR_GROUP)
	GRASS_FIELD.clearings_dirty = true
	pickup.tree_exiting.connect(_clearings_changed)
	var look: Dictionary = settings().get("glow", {})
	var diameter := bounds.size.y * float(look.get("diameter_to_item_height", 1.5))
	var material := ShaderMaterial.new()
	material.shader = GLOW_SHADER
	material.set_shader_parameter("glow_colour", Color(str(look.get("colour", "#fff0cf"))))
	for key: String in ["strength", "falloff_power", "ground_feather_m", "far_fade_start_m", "far_fade_end_m"]:
		material.set_shader_parameter(key, float(look[key]))
	material.set_shader_parameter("behind_m", maxf(bounds.size.x, bounds.size.z) * 0.5 + float(look.get("behind_margin_m", 0.025)))
	material.set_shader_parameter("foot_y", pickup.global_position.y + bounds.position.y)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * diameter
	var halo := MeshInstance3D.new()
	halo.name = "MeadowsPotionSoftGlow"
	halo.mesh = quad
	halo.material_override = material
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = bounds.get_center()
	pickup.add_child(halo)
	# The named pickup alone leaves the common field. Candy and other potions
	# retain that field's exact registration, shader and distance compensation.
	PICKUP_GLOW.detach(pickup)
	pickup.set_meta("p2_033_presentation", {
		"placement_id": PLACEMENT, "item_height_m": bounds.size.y,
		"halo_diameter_m": diameter, "grass_clear_radius_m": radius,
		"authored_xz": settings().get("authored_xz", []),
	})


static func _clearings_changed() -> void:
	GRASS_FIELD.clearings_dirty = true

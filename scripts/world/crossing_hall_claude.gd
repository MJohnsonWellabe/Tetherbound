extends RefCounted

## F17#6 claude-r1 Hall interiors (presentation only; independent OFF flag).
## 1. Night lantern pools: Compatibility caps lights per object and the Hall
##    shell is one batched mesh, so real omni pools never land reliably.
##    Each interior lantern gets an additive warm floor pool and wall wash
##    (unshaded radial quads) shown only while WorldLook is dark.
## 2. Sealed arches gain depth: the brick infill sits back in a stone reveal
##    with jambs, a curved soffit, a voussoir ring and a keystone.
## 3. Signage: larger arch plaques and a standing painted signboard beside
##    each arch at eye height, clear of the top-right HUD panel.
## No collision, route, portal state or persistent state changes.
const CONFIG := "res://data/config/crossing_hall_claude.json"
const STONE_TEXTURE := "res://assets/buildings/quaternius_medieval/T_RockTrim_BaseColor.png"
const WOOD_TEXTURE := "res://assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png"


static func config() -> Dictionary:
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return cfg if cfg is Dictionary and bool(cfg.get("hall_interiors_claude_enabled", false)) else {}


static func build(hall: Node3D, hall_config: Dictionary, arches: Dictionary, lights: Array) -> Array[Node3D]:
	var cfg := config()
	var pools: Array[Node3D] = []
	if cfg.is_empty():
		return pools
	pools = _pools(hall, cfg.pools, lights)
	for entry: Dictionary in hall_config.arches:
		var slot: Node3D = arches.get(str(entry.id))
		if slot == null:
			continue
		if str(entry.kind) == "sealed":
			_sealed_reveal(slot, cfg.sealed_reveal)
		_signage(slot, cfg.signage, cfg.sealed_reveal)
	return pools


static func set_night(pools: Array, dark: bool) -> void:
	for pool: Node3D in pools:
		if is_instance_valid(pool):
			pool.visible = dark


static func _glow_material(colour: Color, strength: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, fog_disabled;
uniform vec4 glow : source_color;
uniform float strength = 0.5;
uniform float falloff = 2.2;
uniform bool billboard = false;
void vertex() {
	if (billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
}
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float a = pow(clamp(1.0 - r, 0.0, 1.0), falloff) * strength;
	ALBEDO = glow.rgb * a;
	ALPHA = a;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("glow", colour)
	material.set_shader_parameter("strength", strength)
	return material


static func _pools(hall: Node3D, cfg: Dictionary, lights: Array) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var floor_mat := _glow_material(Color(str(cfg.colour)), float(cfg.floor_strength))
	var wall_mat := _glow_material(Color(str(cfg.colour)), float(cfg.wall_strength))
	for raw: Variant in lights:
		var light := raw as OmniLight3D
		if light == null:
			continue
		var root := Node3D.new()
		root.name = "LanternNightPool"
		hall.add_child(root)
		root.position = light.position
		# The lantern hangs out from its wall: the wall is behind the flame,
		# the room in front. Direction = from wall toward room, flattened.
		var forward := _lantern_forward(hall, light, cfg)
		# Hanging (ceiling) lanterns have no wall: a pool straight below only.
		var hanging := light.position.y > float(cfg.hanging_above_y) or forward.length_squared() < 0.5
		if hanging:
			forward = Vector3.ZERO
		var floor_quad := MeshInstance3D.new()
		floor_quad.name = "FloorPool"
		var plane := QuadMesh.new()
		plane.size = Vector2.ONE * float(cfg.floor_radius_m) * 2.0
		floor_quad.mesh = plane
		floor_quad.material_override = floor_mat
		floor_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		floor_quad.rotation.x = -PI * 0.5
		floor_quad.position = Vector3(forward.x, 0.0, forward.z) * float(cfg.floor_offset_m) + Vector3(0, float(cfg.floor_y) - light.position.y, 0)
		root.add_child(floor_quad)
		# A soft night halo round the flame, so each pool has a lit source.
		var halo := MeshInstance3D.new()
		halo.name = "FlameHalo"
		var halo_quad := QuadMesh.new()
		halo_quad.size = Vector2.ONE * float(cfg.halo_radius_m) * 2.0
		halo.mesh = halo_quad
		var halo_mat := _glow_material(Color(str(cfg.colour)), float(cfg.halo_strength))
		halo_mat.set_shader_parameter("billboard", true)
		halo.material_override = halo_mat
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(halo)
		if hanging or not bool(cfg.get("wall_wash", true)):
			root.visible = false
			out.append(root)
			continue
		var wall_quad := MeshInstance3D.new()
		wall_quad.name = "WallWash"
		var wall_plane := QuadMesh.new()
		wall_plane.size = Vector2(float(cfg.wall_radius_m) * 2.0, float(cfg.wall_radius_m) * 2.4)
		wall_quad.mesh = wall_plane
		wall_quad.material_override = wall_mat
		wall_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wall_quad.position = -forward * float(cfg.wall_back_m) + Vector3(0, float(cfg.wall_drop_m), 0)
		wall_quad.basis = Basis.looking_at(-forward, Vector3.UP)
		root.add_child(wall_quad)
		root.visible = false
		out.append(root)
	return out


static func _lantern_forward(hall: Node3D, light: OmniLight3D, cfg: Dictionary) -> Vector3:
	# Lanterns face the nave/shrine interior: point toward the room centre
	# along the axis of the nearest wall (largest local component).
	var centre := Vector3(float(cfg.room_centre[0]), light.position.y, float(cfg.room_centre[1]))
	if light.position.x > float(cfg.shrine_x_from):
		centre = Vector3(float(cfg.shrine_centre[0]), light.position.y, float(cfg.shrine_centre[1]))
	var to_room := centre - light.position
	to_room.y = 0.0
	if absf(to_room.x) > absf(to_room.z):
		return Vector3(signf(to_room.x), 0, 0)
	return Vector3(0, 0, signf(to_room.z))


static func _stone(tint: String, uv_per_m: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(STONE_TEXTURE) as Texture2D
	material.albedo_color = Color(tint)
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * uv_per_m
	material.roughness = 0.9
	return material


static func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	return mesh


## Arch local frame: opening |x| < half, round head springing at spring_y,
## nave side is +z. The infill moves back by `depth` into a stone reveal.
static func _sealed_reveal(slot: Node3D, cfg: Dictionary) -> void:
	var half := float(cfg.half_width_m)
	var spring := float(cfg.spring_y_m)
	var depth := float(cfg.depth_m)
	var face := float(cfg.face_z_m)
	var stone := _stone(str(cfg.stone_tint), float(cfg.uv_per_m))
	var trim := _stone(str(cfg.trim_tint), float(cfg.uv_per_m))
	var infill := slot.get_node_or_null("PortalSurface") as Node3D
	if infill != null:
		infill.position.z = face - depth
	for side: float in [-1.0, 1.0]:
		_box(slot, "SealedRevealJamb", Vector3(0.08, spring, depth), Vector3(side * (half + 0.04), spring * 0.5, face - depth * 0.5), stone)
	# Curved soffit and a voussoir ring on the face.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := SurfaceTool.new()
	ring.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 14
	var outer := half + float(cfg.ring_width_m)
	for i in steps:
		var a := PI * float(i) / steps
		var b := PI * float(i + 1) / steps
		var pa := Vector3(cos(a) * half, spring + sin(a) * half, 0)
		var pb := Vector3(cos(b) * half, spring + sin(b) * half, 0)
		for tri: Array in [[pa + Vector3(0, 0, face), pb + Vector3(0, 0, face), pb + Vector3(0, 0, face - depth)],
				[pa + Vector3(0, 0, face), pb + Vector3(0, 0, face - depth), pa + Vector3(0, 0, face - depth)]]:
			for v: Vector3 in tri:
				surface.set_normal(-Vector3(v.x, v.y - spring, 0).normalized())
				surface.add_vertex(v)
		# Voussoirs: alternate stones with a hairline joint between them.
		var pad := 0.012
		var a2 := a + pad
		var b2 := b - pad
		var ia := Vector3(cos(a2) * half, spring + sin(a2) * half, face + 0.03)
		var ib := Vector3(cos(b2) * half, spring + sin(b2) * half, face + 0.03)
		var oa := Vector3(cos(a2) * outer, spring + sin(a2) * outer, face + 0.03)
		var ob := Vector3(cos(b2) * outer, spring + sin(b2) * outer, face + 0.03)
		for v: Vector3 in [ia, oa, ob, ia, ob, ib]:
			ring.set_normal(Vector3.BACK)
			ring.add_vertex(v)
	var soffit := MeshInstance3D.new()
	soffit.name = "SealedRevealSoffit"
	soffit.mesh = surface.commit()
	soffit.material_override = stone
	slot.add_child(soffit)
	var voussoirs := MeshInstance3D.new()
	voussoirs.name = "SealedVoussoirRing"
	voussoirs.mesh = ring.commit()
	trim.cull_mode = BaseMaterial3D.CULL_DISABLED
	voussoirs.material_override = trim
	slot.add_child(voussoirs)


## One sign per arch. A closed arch (sealed or locked) carries its plaque at
## eye level inside the opening, fixed to the recessed infill or the door:
## lower in frame it stays clear of the top-right HUD panel, and a sign on the
## blocking surface itself says "closed". An open arch keeps the canonical
## plaque above its opening so nothing hangs across the portal. Both grow and
## gain an outline. The state can change at runtime, so placement is redone
## by place_signs from the Hall's apply_display.
static func _signage(slot: Node3D, cfg: Dictionary, reveal: Dictionary) -> void:
	var plaque := slot.get_node_or_null("Plaque") as MeshInstance3D
	var biome := slot.get_node_or_null("BiomeSign") as Label3D
	var state := slot.get_node_or_null("StateSign") as Label3D
	if plaque == null or biome == null or state == null:
		return
	var rest := {"plaque": plaque.position, "biome": biome.position, "state": state.position,
		"biome_px": biome.pixel_size, "state_px": state.pixel_size, "cfg": cfg,
		"sealed_z": float(reveal.face_z_m) - float(reveal.depth_m)}
	slot.set_meta("claude_sign", rest)
	for label: Label3D in [biome, state]:
		label.outline_size = int(cfg.text_outline_size)
		label.outline_modulate = Color(str(cfg.text_outline_colour))
	_place(slot)


static func place_signs(arches: Dictionary) -> void:
	for slot: Node3D in arches.values():
		if slot.has_meta("claude_sign"):
			_place(slot)


static func _place(slot: Node3D) -> void:
	var rest: Dictionary = slot.get_meta("claude_sign")
	var cfg: Dictionary = rest.cfg
	var plaque := slot.get_node("Plaque") as MeshInstance3D
	var biome := slot.get_node("BiomeSign") as Label3D
	var state := slot.get_node("StateSign") as Label3D
	var origin: Vector3 = rest.plaque
	var text := state.text.strip_edges().to_lower()
	var closed := text == "sealed" or text == "locked"
	var scale := float(cfg.closed_plaque_scale if closed else cfg.open_plaque_scale)
	var target := origin
	if closed:
		var z := float(rest.sealed_z) + float(cfg.sealed_plaque_gap_m) if text == "sealed" else float(cfg.locked_plaque_z_m)
		target = Vector3(0, float(cfg.closed_plaque_y_m), z)
	plaque.position = target
	plaque.scale = Vector3(scale, scale, 1)
	for pair: Array in [[biome, "biome"], [state, "state"]]:
		var label: Label3D = pair[0]
		var local: Vector3 = rest[pair[1]] - origin
		label.position = target + Vector3(local.x * scale, local.y * scale, local.z)
		label.pixel_size = float(rest[pair[1] + "_px"]) * scale

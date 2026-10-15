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
	# Plaques sit on their own render layer that the lanterns do not light, so
	# a sign inside a sealed recess is never brighter at night than by day.
	var plaque_bit := 1 << (int(cfg.signage.plaque_layer) - 1)
	var ambient: Dictionary = hall_config.get("interior_ambient", {})
	var occlusion := Image.create(1, 1, false, Image.FORMAT_L8)
	occlusion.fill(Color.from_hsv(0, 0, clampf(float(ambient.get("night_ambient", 1.0)), 0.0, 1.0)))
	cfg.signage["_occlusion"] = ImageTexture.create_from_image(occlusion)
	var materials: Array = []
	cfg.signage["_materials"] = materials
	hall.set_meta("claude_plaque_materials", materials)
	for raw: Variant in lights:
		if raw is Light3D:
			(raw as Light3D).light_cull_mask &= ~plaque_bit
	for entry: Dictionary in hall_config.arches:
		var slot: Node3D = arches.get(str(entry.id))
		# The fitted hero surround already owns its measured reveal and infill.
		# Legacy kit transforms would stretch that new fan beyond its opening.
		if slot == null or bool(slot.get_meta("hero_portal_frame", false)):
			continue
		if str(entry.kind) == "sealed":
			_sealed_reveal(slot, cfg.sealed_reveal, hall_config.get("membrane", {}))
		# Signage is held behind its own sub-flag (judge: PARTIAL) so the
		# pools and the sealed reveal can ship without it.
		if bool(cfg.signage.get("enabled", false)):
			_signage(slot, cfg.signage, cfg.sealed_reveal)
	return pools


static func set_night(hall: Node3D, pools: Array, dark: bool) -> void:
	for pool: Node3D in pools:
		if is_instance_valid(pool):
			pool.visible = dark
	# The plaques skip the Hall's night pass (no emissive floor) but keep its
	# ambient occlusion, so the night sky does not tint them blue.
	for material: BaseMaterial3D in hall.get_meta("claude_plaque_materials", []):
		material.ao_enabled = dark


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


## Arch local frame: opening |x| < half, round head springing at spring_y,
## nave side is +z. One continuous reveal (two square jambs and the curved
## soffit, a darker stone than the face) runs `depth` into the wall; the
## voussoir ring sits on the face. The brick infill moves to the back of the
## reveal and is stretched to its outline in _place, so no wall shows round it.
static func _sealed_reveal(slot: Node3D, cfg: Dictionary, membrane: Dictionary) -> void:
	var half := float(cfg.half_width_m)
	var spring := float(cfg.spring_y_m)
	var depth := float(cfg.depth_m)
	var face := float(cfg.face_z_m)
	var stone := _stone(str(cfg.stone_tint), float(cfg.uv_per_m))
	stone.cull_mode = BaseMaterial3D.CULL_DISABLED
	var trim := _stone(str(cfg.trim_tint), float(cfg.uv_per_m))
	var back := face - depth
	var infill := slot.get_node_or_null("PortalSurface") as Node3D
	if infill != null and membrane.has("half_width_m"):
		slot.set_meta("claude_infill", {"sealed_z": back, "rest_z": infill.position.z,
			"scale": Vector3(half / float(membrane.half_width_m), (spring + half) / float(membrane.height_m), float(cfg.infill_flatten))})
		_place_infill(slot)
	# Reveal profile: up the left jamb, over the head, down the right jamb.
	var profile: Array[Vector3] = [Vector3(-half, 0, 0)]
	var steps := 14
	for i in steps + 1:
		var a := PI - PI * float(i) / steps
		profile.append(Vector3(cos(a) * half, spring + sin(a) * half, 0))
	profile.append(Vector3(half, 0, 0))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var run := 0.0
	for i in profile.size() - 1:
		var p := profile[i]
		var q := profile[i + 1]
		var seg := p.distance_to(q)
		var quad := [[p, face, run], [q, face, run + seg], [q, back, run + seg], [p, back, run]]
		for k: int in [0, 1, 2, 0, 2, 3]:
			var row: Array = quad[k]
			var v: Vector3 = row[0]
			var inward := -Vector3(v.x, v.y - spring, 0).normalized() if v.y > spring else Vector3(-signf(v.x), 0, 0)
			surface.set_normal(inward)
			surface.set_uv(Vector2(float(row[2]), float(row[1]) - face))
			surface.add_vertex(Vector3(v.x, v.y, float(row[1])))
		run += seg
	var reveal := MeshInstance3D.new()
	reveal.name = "SealedReveal"
	reveal.mesh = surface.commit()
	reveal.material_override = stone
	slot.add_child(reveal)
	# Voussoirs: alternate stones with a hairline joint between them.
	var ring := SurfaceTool.new()
	ring.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer := half + float(cfg.ring_width_m)
	# Set just behind the timber frame's face: where the frame covers the
	# ring, the frame wins; no pale wedge outside the posts.
	var ring_z := float(cfg.ring_z_m)
	var pad := 0.012
	for i in steps:
		var a2 := PI * float(i) / steps + pad
		var b2 := PI * float(i + 1) / steps - pad
		var ia := Vector3(cos(a2) * half, spring + sin(a2) * half, face + ring_z)
		var ib := Vector3(cos(b2) * half, spring + sin(b2) * half, face + ring_z)
		var oa := Vector3(cos(a2) * outer, spring + sin(a2) * outer, face + ring_z)
		var ob := Vector3(cos(b2) * outer, spring + sin(b2) * outer, face + ring_z)
		for v: Vector3 in [ia, oa, ob, ia, ob, ib]:
			ring.set_normal(Vector3.BACK)
			ring.add_vertex(v)
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
		"sealed_z": float(reveal.face_z_m) - float(reveal.depth_m),
		"modulate": state.modulate, "outline": int(cfg.text_outline_size)}
	slot.set_meta("claude_sign", rest)
	for label: Label3D in [biome, state]:
		label.outline_size = int(cfg.text_outline_size)
		label.outline_modulate = Color(str(cfg.text_outline_colour))
	plaque.layers = 1 << (int(cfg.plaque_layer) - 1)
	# The painted lettering shares its board's light: on the same layer it is
	# never lit by a lantern its board ignores, so it cannot glow at night.
	biome.layers = plaque.layers
	state.layers = plaque.layers
	# The Hall's night pass gives every plain material an emissive "night
	# floor" from its own texture; a sign inside a sealed recess would then
	# outshine the infill it hangs on. A material that already carries an AO
	# map is left out of that pass, so give the plaque its own with the Hall's
	# night occlusion level (set_night turns it on after dark only).
	var wood := plaque.material_override as BaseMaterial3D
	if wood != null:
		wood = wood.duplicate() as BaseMaterial3D
		wood.ao_texture = cfg._occlusion
		wood.ao_light_affect = 0.0
		wood.ao_enabled = false
		cfg._materials.append(wood)
		plaque.material_override = wood
	rest["wood"] = wood
	# A sealed arch's sign is a pale carved stone tablet, not the wooden
	# board the doors and open arches carry: a shape and colour cue as well
	# as the word. Same AO opt-out as the wood.
	var tablet := _stone(str(cfg.tablet_tint), float(reveal.uv_per_m))
	tablet.ao_texture = cfg._occlusion
	tablet.ao_light_affect = 0.0
	cfg._materials.append(tablet)
	rest["tablet"] = tablet
	_place(slot)


static func place_signs(arches: Dictionary) -> void:
	for slot: Node3D in arches.values():
		_place_infill(slot)
		if slot.has_meta("claude_sign"):
			_place(slot)


## apply_display resets the infill each refresh; a sealed one sits at the
## back of the reveal, stretched (and flattened) to the reveal outline.
static func _place_infill(slot: Node3D) -> void:
	if not slot.has_meta("claude_infill"):
		return
	var rest: Dictionary = slot.get_meta("claude_infill")
	var infill := slot.get_node_or_null("PortalSurface") as Node3D
	var state := slot.get_node_or_null("StateSign") as Label3D
	if infill == null or state == null:
		return
	var sealed := state.text.strip_edges().to_lower() == "sealed"
	infill.position.z = float(rest.sealed_z) if sealed else float(rest.rest_z)
	infill.scale = rest.scale if sealed else Vector3(infill.scale.x, 1, 1)


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
	var sealed_tablet := text == "sealed"
	if sealed_tablet:
		target = Vector3(0, float(cfg.tablet_y_m), float(rest.sealed_z) + float(cfg.sealed_plaque_gap_m))
	elif closed:
		target = Vector3(0, float(cfg.closed_plaque_y_m), float(cfg.locked_plaque_z_m))
	plaque.position = target
	plaque.scale = _vec(cfg.tablet_scale) if sealed_tablet else Vector3(scale, scale, 1)
	plaque.material_override = rest.tablet if sealed_tablet else rest.wood
	# The pale stone tablet takes the lantern light (a lit sign, warm at
	# night); the dark wooden boards stay off the lanterns' layer.
	var layer := 1 if sealed_tablet else 1 << (int(cfg.plaque_layer) - 1)
	plaque.layers = layer
	biome.layers = layer
	state.layers = layer
	for pair: Array in [[biome, "biome"], [state, "state"]]:
		var label: Label3D = pair[0]
		var local: Vector3 = rest[pair[1]] - origin
		label.position = target + Vector3(local.x * scale, local.y * scale, local.z)
		label.pixel_size = float(rest[pair[1] + "_px"]) * scale
		label.modulate = rest.modulate
		label.outline_size = int(rest.outline)
	if sealed_tablet:
		# Carved lettering filling the tablet: dark, no outline. A reserved
		# biome shows one word; a named one gets its name above the state.
		# Every arch keeps both signs visible (smoke_net_crossing_hall_agreement);
		# a reserved biome named "Sealed" sets both labels on the one line.
		var front := target.z + float(cfg.tablet_text_front_m)
		var single := biome.text.strip_edges() == state.text.strip_edges()
		var lines: Array = [biome, state]
		for index in lines.size():
			var label: Label3D = lines[index]
			var row := 0.0 if single else (0.09 if index == 0 else -0.09)
			label.position = Vector3(0, target.y + row, front)
			label.pixel_size = float(rest[("biome" if label == biome and not single else "state") + "_px"]) * float(cfg.tablet_text_scale) / (1 if single else 2)
			label.modulate = Color(str(cfg.tablet_text_colour))
			label.outline_size = 0


static func _vec(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))

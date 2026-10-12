extends RefCounted

## P2-022 claude-r1: the Aviary as a layered stone sanctuary. The existing
## 9 m drum is the base storey; above it a solid masonry clerestory storey
## with warm-lit arched windows hides the lattice dome's skirt, a cornice and
## a balustraded parapet terrace step back, and the dome becomes the crown.
## Night reads from window glow, lanterns at the entries and a warm interior
## fill. Everything sits above the 9 m drum top or inside existing walls/
## arches: no collision, floor, route, spawn or persistent state.
## Independent OFF flag; all earlier Aviary candidates untouched.
const PARTS := preload("res://scripts/world/cloudreach_aviary.gd")
const LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")


static func build(root: Node3D, spec: Dictionary, materials: Dictionary, drum: Dictionary) -> void:
	if not bool(spec.get("aviary_claude_enabled", false)):
		return
	if root.has_node("AviaryClaudeSanctuary"):
		return
	var site := Node3D.new()
	site.name = "AviaryClaudeSanctuary"
	root.add_child(site)
	var base_top := float(drum.get("height_m", 9.0))
	var storey: Dictionary = spec.storey
	var radius := float(storey.radius_m)
	var thickness := float(storey.thickness_m)
	var height := float(storey.height_m)
	var stone: Material = materials["stone"]
	var trim: Material = materials["masonry"]
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(str(spec.window_colour))
	glow.emission_enabled = true
	glow.emission = Color(str(spec.window_colour))
	glow.emission_energy_multiplier = float(spec.window_energy)
	glow.roughness = 0.6
	var piers: Array = drum.get("pier_angles_deg", [])
	var windows := int(storey.window_count)
	var window_half := float(storey.window_width_m) * 0.5
	var window_low := base_top + float(storey.sill_m)
	var window_high := window_low + float(storey.window_height_m)
	var segments := int(storey.segment_count)
	# Solid storey: wall segments, with window bays cut where a window falls.
	for i in segments:
		var a := TAU * float(i) / segments
		var b := TAU * float(i + 1) / segments
		var mid := (a + b) * 0.5
		var chord := 2.0 * radius * sin((b - a) * 0.5) + 0.05
		var outward := Vector3(cos(mid), 0.0, sin(mid))
		var basis := Basis(outward.cross(Vector3.UP).normalized(), Vector3.UP, outward)
		var bay := _window_at(mid, windows, piers, float(storey.pier_clear_deg))
		if bay < 0.0:
			PARTS._box(site, "ClerestoryWall", outward * radius + Vector3.UP * (base_top + height * 0.5), Vector3(chord, height, thickness), stone, false, basis)
		else:
			# Under the sill, over the head, and the jambs either side.
			PARTS._box(site, "ClerestorySill", outward * radius + Vector3.UP * (base_top + (window_low - base_top) * 0.5), Vector3(chord, window_low - base_top, thickness), stone, false, basis)
			PARTS._box(site, "ClerestoryHead", outward * radius + Vector3.UP * (window_high + (base_top + height - window_high) * 0.5), Vector3(chord, base_top + height - window_high, thickness), stone, false, basis)
			var jamb := (chord - window_half * 2.0) * 0.5
			if jamb > 0.05:
				for side: float in [-1.0, 1.0]:
					var offset := basis.x * side * (window_half + jamb * 0.5)
					PARTS._box(site, "ClerestoryJamb", outward * radius + offset + Vector3.UP * (window_low + window_high) * 0.5, Vector3(jamb, window_high - window_low, thickness), stone, false, basis)
			# Recessed glowing pane, a pale arched head and a projecting sill.
			PARTS._box(site, "ClerestoryWindowGlow", outward * (radius - thickness * 0.25) + Vector3.UP * (window_low + window_high) * 0.5, Vector3(window_half * 2.0, window_high - window_low, 0.12), glow, false, basis)
			var arch := MeshInstance3D.new()
			arch.name = "ClerestoryWindowArch"
			arch.mesh = PARTS._stone_arch_mesh(window_half, float(storey.window_arch_rise_m), 0.38, thickness + 0.3, 9, 0.02)
			arch.material_override = trim
			arch.transform = Transform3D(basis, outward * (radius + 0.05) + Vector3.UP * (window_high - float(storey.window_arch_rise_m)))
			site.add_child(arch)
			PARTS._box(site, "ClerestoryWindowSill", outward * (radius + thickness * 0.5) + Vector3.UP * (window_low - 0.12), Vector3(window_half * 2.0 + 0.6, 0.24, 0.5), trim, false, basis)
	# String course at the drum top, cornice and parapet terrace at the crown.
	_ring(site, "SanctuaryStringCourse", radius - thickness * 0.5, radius + thickness * 0.5 + 0.22, base_top - 0.1, 0.5, trim, segments)
	var cornice_y := base_top + height
	_ring(site, "SanctuaryCornice", radius - thickness * 0.5 - 0.3, radius + thickness * 0.5 + float(storey.cornice_projection_m), cornice_y, 0.55, trim, segments)
	var parapet: Dictionary = spec.parapet
	_ring(site, "ParapetTerraceWalk", radius - thickness * 0.5 - float(parapet.walk_inset_m), radius + thickness * 0.5, cornice_y + 0.55, 0.2, stone, segments)
	var post_count := int(parapet.post_count)
	for i in post_count:
		var angle := TAU * float(i) / post_count
		var at := Vector3(cos(angle), 0.0, sin(angle)) * (radius + thickness * 0.5 - 0.25)
		PARTS._box(site, "ParapetPost", at + Vector3.UP * (cornice_y + 0.75 + float(parapet.height_m) * 0.5), Vector3(0.45, float(parapet.height_m), 0.45), trim, false, Basis(Vector3.UP, -angle))
	_ring(site, "ParapetRail", radius + thickness * 0.5 - 0.5, radius + thickness * 0.5, cornice_y + 0.75 + float(parapet.height_m), 0.22, trim, segments)
	# Night: lanterns at the entries, an interior warm fill and entry pools.
	var lights: Dictionary = spec.lights
	for entry: Dictionary in lights.entries:
		var angle := deg_to_rad(float(entry.angle_deg))
		var outward := Vector3(cos(angle), 0.0, sin(angle))
		var across := outward.cross(Vector3.UP).normalized()
		for side: float in [-1.0, 1.0]:
			var lamp := LANTERN.instantiate() as Node3D
			lamp.name = "SanctuaryEntryLantern"
			site.add_child(lamp)
			lamp.position = outward * (float(entry.radius_m)) + across * side * float(entry.lantern_spread_m) + Vector3.UP * float(entry.lantern_height_m)
			lamp.rotation.y = -angle + PI * 0.5
			lamp.scale = Vector3.ONE * float(entry.lantern_scale)
		var pool := OmniLight3D.new()
		pool.name = "SanctuaryEntryLight"
		pool.light_color = Color(str(lights.colour))
		pool.light_energy = float(entry.energy)
		pool.omni_range = float(entry.range_m)
		pool.shadow_enabled = false
		pool.position = outward * (float(entry.radius_m) + 1.5) + Vector3.UP * float(entry.light_height_m)
		site.add_child(pool)
	var fill := OmniLight3D.new()
	fill.name = "SanctuaryInteriorFill"
	fill.light_color = Color(str(lights.colour))
	fill.light_energy = float(lights.interior_energy)
	fill.omni_range = float(lights.interior_range_m)
	fill.shadow_enabled = false
	fill.position = Vector3.UP * float(lights.interior_height_m)
	site.add_child(fill)
	for link: Dictionary in spec.get("court_link", []):
		var size := Vector3(float(link.size[0]), float(link.size[1]), float(link.size[2]))
		var at := Vector3(float(link.at[0]), float(link.at[1]), float(link.at[2]))
		PARTS._box(site, str(link.id), at + Vector3.UP * size.y * 0.5, size, trim if bool(link.get("trim", false)) else stone, false, Basis(Vector3.UP, deg_to_rad(float(link.get("yaw_deg", 0.0)))))


## Window centre angle for this segment, or -1 when the segment is solid.
static func _window_at(mid: float, windows: int, piers: Array, pier_clear_deg: float) -> float:
	var step := TAU / windows
	var nearest := roundf((mid - step * 0.5) / step) * step + step * 0.5
	if absf(angle_difference(mid, nearest)) > step * 0.25:
		return -1.0
	for pier: Variant in piers:
		if absf(rad_to_deg(angle_difference(nearest, deg_to_rad(float(pier))))) < pier_clear_deg:
			return -1.0
	return nearest


static func _ring(parent: Node3D, label: String, inner: float, outer: float, y: float, height: float, material: Material, segments: int) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		var a := TAU * float(i) / segments
		var b := TAU * float(i + 1) / segments
		var ia := Vector3(cos(a) * inner, 0.0, sin(a) * inner)
		var ib := Vector3(cos(b) * inner, 0.0, sin(b) * inner)
		var oa := Vector3(cos(a) * outer, 0.0, sin(a) * outer)
		var ob := Vector3(cos(b) * outer, 0.0, sin(b) * outer)
		var up := Vector3.UP * height
		var mid := Vector3(cos((a + b) * 0.5), 0.0, sin((a + b) * 0.5))
		PARTS._arch_quad(surface, ia + up, oa + up, ob + up, ib + up, Vector3.UP)
		PARTS._arch_quad(surface, ia, ib, ob, oa, Vector3.DOWN)
		PARTS._arch_quad(surface, oa, ob, ob + up, oa + up, mid)
		PARTS._arch_quad(surface, ia, ia + up, ib + up, ib, -mid)
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = surface.commit()
	mesh.material_override = material
	mesh.position = Vector3.UP * y
	parent.add_child(mesh)

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
	glow.albedo_color = Color(str(spec.window_glass_colour))
	glow.emission_enabled = true
	glow.emission = Color(str(spec.window_colour))
	glow.emission_energy_multiplier = float(spec.window_energy_day)
	glow.roughness = 0.35
	var driver := WindowGlowDriver.new()
	driver.name = "SanctuaryWindowGlowDriver"
	driver.material = glow
	driver.day_energy = float(spec.window_energy_day)
	driver.night_energy = float(spec.window_energy_night)
	driver.sun_full_day = float(spec.sun_energy_full_day)
	driver.sun_night = float(spec.sun_energy_night)
	site.add_child(driver)
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
	_colonnade(site, spec.get("court_colonnade", {}), stone, trim, glow, lights)
	_ground_storey(site, spec.get("ground_storey", {}), stone, trim, base_top)
	_night_pools(site, spec.get("night_pools", {}), spec, driver)


## Open colonnade along both edges of the existing paved approach to the
## arena court, so drum and court read as one site. Pillars stand off the
## paving; gaps between them stay open. Lanterns light the walk at night.
static func _colonnade(site: Node3D, spec: Dictionary, stone: Material, trim: Material, glow: Material, lights: Dictionary) -> void:
	if spec.is_empty():
		return
	var z0 := float(spec.from_z_m)
	var z1 := float(spec.to_z_m)
	var bays := int(spec.bays)
	var height := float(spec.pillar_height_m)
	var pillar := float(spec.pillar_width_m)
	for side: float in [-1.0, 1.0]:
		var x := side * float(spec.half_spacing_m)
		for i in bays + 1:
			var z := lerpf(z0, z1, float(i) / bays)
			PARTS._box(site, "ColonnadePlinth", Vector3(x, 0.3, z), Vector3(pillar + 0.5, 0.6, pillar + 0.5), trim, false)
			PARTS._box(site, "ColonnadePillar", Vector3(x, height * 0.5, z), Vector3(pillar, height, pillar), stone, false)
			PARTS._box(site, "ColonnadeCapital", Vector3(x, height + 0.2, z), Vector3(pillar + 0.4, 0.4, pillar + 0.4), trim, false)
			if i < bays and i % 2 == 0:
				var lamp := LANTERN.instantiate() as Node3D
				lamp.name = "ColonnadeLantern"
				site.add_child(lamp)
				lamp.position = Vector3(x - side * 0.6, height - 0.9, lerpf(z0, z1, (float(i) + 0.5) / bays))
				lamp.rotation.y = -side * PI * 0.5
				lamp.scale = Vector3.ONE * float(spec.lantern_scale)
		PARTS._box(site, "ColonnadeLintel", Vector3(x, height + 0.75, (z0 + z1) * 0.5), Vector3(pillar + 0.2, 0.7, z1 - z0 + pillar), trim, false)
		PARTS._box(site, "ColonnadeCoping", Vector3(x, height + 1.25, (z0 + z1) * 0.5), Vector3(pillar + 0.6, 0.3, z1 - z0 + pillar + 0.4), stone, false)
	var walk := OmniLight3D.new()
	walk.name = "ColonnadeWalkLight"
	walk.light_color = Color(str(lights.colour))
	walk.light_energy = float(spec.light_energy)
	walk.omni_range = (z1 - z0) * 0.6
	walk.shadow_enabled = false
	walk.position = Vector3(0.0, height - 0.5, (z0 + z1) * 0.5)
	site.add_child(walk)


## r2 (coordinator judge): the clerestory overhung a recessed ground storey,
## reading as a dark undercroft. A render-only masonry facing brings the
## ground storey flush under the string course, leaving the drum's arch
## openings clear, and a broad low step runs round its foot.
static func _ground_storey(site: Node3D, spec: Dictionary, stone: Material, trim: Material, base_top: float) -> void:
	if spec.is_empty():
		return
	var gaps: Array = spec.openings_deg
	var segments := int(spec.segment_count)
	var inner := float(spec.inner_radius_m)
	var outer := float(spec.outer_radius_m)
	_ring(site, "GroundStoreyFacing", inner, outer, 0.0, base_top - 0.1, stone, segments, gaps)
	_ring(site, "GroundStoreyPlinthStep", outer - 0.1, outer + float(spec.step_width_m), 0.0, float(spec.step_height_m), trim, segments, gaps)
	_ring(site, "GroundStoreyBaseCourse", outer - 0.05, outer + 0.18, float(spec.step_height_m), float(spec.base_course_height_m), trim, segments, gaps)


## Night pools: additive unshaded floor glows under the entry lanterns, inside
## the drum and along the colonnade, faded out by day with the window glow.
## Compatibility's per-object light cap leaves the omni lights barely pooling
## on terrain and paving; these read from the approach.
static func _night_pools(site: Node3D, spec: Dictionary, root_spec: Dictionary, driver: WindowGlowDriver) -> void:
	if spec.is_empty():
		return
	driver.pool_strength = float(spec.strength)
	var colour := Color(str(spec.colour))
	var spots: Array = []
	for entry: Dictionary in root_spec.lights.entries:
		var angle := deg_to_rad(float(entry.angle_deg))
		var outward := Vector3(cos(angle), 0.0, sin(angle))
		spots.append([outward * (float(entry.radius_m) + float(spec.entry_out_m)), float(spec.entry_radius_m)])
		spots.append([outward * float(spec.inner_from_centre_m), float(spec.inner_radius_m)])
	var colonnade: Dictionary = root_spec.get("court_colonnade", {})
	if not colonnade.is_empty():
		var bays := int(colonnade.bays)
		for side: float in [-1.0, 1.0]:
			for i in bays:
				if i % 2 == 0:
					var z := lerpf(float(colonnade.from_z_m), float(colonnade.to_z_m), (float(i) + 0.5) / bays)
					spots.append([Vector3(side * (float(colonnade.half_spacing_m) - float(spec.colonnade_in_m)), 0.0, z), float(spec.colonnade_radius_m)])
	for spot: Array in spots:
		var material := _glow_material(colour)
		driver.pools.append(material)
		var quad := MeshInstance3D.new()
		quad.name = "SanctuaryNightPool"
		var plane := QuadMesh.new()
		plane.size = Vector2.ONE * float(spot[1]) * 2.0
		quad.mesh = plane
		quad.material_override = material
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		quad.rotation.x = -PI * 0.5
		quad.position = (spot[0] as Vector3) + Vector3.UP * float(spec.floor_y)
		site.add_child(quad)
	# A warm lit hall behind each entry: a soft upright glow inside the drum
	# facing out through the opening, so the arches read as lit doorways at
	# night instead of a dark undercroft.
	for entry: Dictionary in root_spec.lights.entries:
		var angle := deg_to_rad(float(entry.angle_deg))
		var outward := Vector3(cos(angle), 0.0, sin(angle))
		var material := _glow_material(colour)
		material.set_meta("strength_scale", float(spec.hall_glow_strength) / float(spec.strength))
		driver.pools.append(material)
		var glow := MeshInstance3D.new()
		glow.name = "SanctuaryEntryHallGlow"
		var plane := QuadMesh.new()
		plane.size = Vector2(float(spec.hall_glow_width_m), float(spec.hall_glow_height_m))
		glow.mesh = plane
		glow.material_override = material
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		glow.basis = Basis(outward.cross(Vector3.UP).normalized() * -1.0, Vector3.UP, outward)
		glow.position = outward * float(spec.hall_glow_radius_m) + Vector3.UP * float(spec.hall_glow_height_m) * float(spec.hall_glow_centre)
		site.add_child(glow)
	driver.call_deferred("_update")


static func _glow_material(colour: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 glow : source_color;
uniform float strength = 0.0;
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float a = pow(clamp(1.0 - r, 0.0, 1.0), 2.0) * strength;
	ALBEDO = glow.rgb * a;
	ALPHA = a;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("glow", colour)
	return material


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


static func _ring(parent: Node3D, label: String, inner: float, outer: float, y: float, height: float, material: Material, segments: int, gaps: Array = []) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		var a := TAU * float(i) / segments
		var b := TAU * float(i + 1) / segments
		var open := false
		for gap: Array in gaps:
			# A segment is left out when any part of it falls in the opening.
			var centre := deg_to_rad(float(gap[0]))
			var half := deg_to_rad(float(gap[1]))
			if absf(angle_difference(a, centre)) < half or absf(angle_difference(b, centre)) < half:
				open = true
		if open:
			continue
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


## Window glass reads as dark warm glass by day and glows at dusk/night: the
## emission follows the live Sun's energy (presentation only, polled).
class WindowGlowDriver extends Node:
	var material: StandardMaterial3D
	var day_energy := 0.3
	var night_energy := 4.0
	var sun_full_day := 1.0
	var sun_night := 0.55
	var pools: Array[ShaderMaterial] = []
	var pool_strength := 1.0
	var _poll := 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_update()

	func _process(delta: float) -> void:
		_poll -= delta
		if _poll <= 0.0:
			_poll = 0.5
			_update()

	func _update() -> void:
		var sun: DirectionalLight3D = null
		var node: Node = get_parent()
		while node != null and sun == null:
			sun = node.get_node_or_null("Sun") as DirectionalLight3D
			node = node.get_parent()
		if sun == null or material == null:
			return
		var daylight := smoothstep(sun_night, sun_full_day, sun.light_energy) if sun.visible else 0.0
		material.emission_energy_multiplier = lerpf(night_energy, day_energy, daylight)
		for pool: ShaderMaterial in pools:
			pool.set_shader_parameter("strength", pool_strength * float(pool.get_meta("strength_scale", 1.0)) * (1.0 - daylight))


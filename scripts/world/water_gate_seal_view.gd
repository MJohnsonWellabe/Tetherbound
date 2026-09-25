extends Node3D

## Visible side of the closed-gate tide races (water_gate_seals.gd). Each sealed
## landform wears a white-water ring from its waterline out to the race's edge,
## streaming outward like the physics beneath it. A swimmer thrown back by a
## race is told which dock opens it. It also keeps this peer's Fly restrictions
## equal to the sealed discs, so gliding cannot bypass a dock either. The
## current field owns the physical swim gate; this node never decides access.

const SEALS := preload("res://scripts/world/water_gate_seals.gd")
const STATE := preload("res://scripts/player/swim_state.gd")
const TILE_M := 8.0
const SURFACE_LIFT_M := 0.08

var _world: Node3D
var _game: Node
var _seals: Array[Dictionary] = []
var _rules: Dictionary = {}
var _rings: Dictionary = {}
var _material: StandardMaterial3D
var _crest_material: StandardMaterial3D
var _trough_material: StandardMaterial3D
var _spray_texture: Texture2D
var _dock_names: Dictionary = {}
var _last_revision := -1
var _message_cooldown := 0.0
## Last explanation shown to this peer's swimmer; read by the runtime smoke.
var last_message := ""
## Fly restrictions currently registered for this peer's trainer.
var flight_restrictions := 0
var _rig_id := 0
var _spray_check := 0.0


func build(world: Node3D, config: Dictionary, seals: Array[Dictionary], rules: Dictionary) -> void:
	_world = world
	_game = get_node("/root/Game")
	_seals = seals
	_rules = rules
	var island_names: Dictionary = {}
	for island: Dictionary in config.get("islands", []):
		island_names[str(island.id)] = str(island.get("name", island.id))
	for dock: Dictionary in config.get("docks", []):
		_dock_names[str(dock.id)] = str(island_names.get(str(dock.island_id), dock.island_id))
	_material = _foam_material()
	_crest_material = _wave_material()
	_trough_material = _trough()
	_spray_texture = _spray_sprite()
	var sea := float(config.get("terrain", {}).get("sea_level_m", 0.0))
	for seal: Dictionary in _seals:
		var ring := MeshInstance3D.new()
		ring.name = "TideRace_" + str(seal.id)
		ring.mesh = _annulus(float(seal.shore_radius_m), SEALS.outer_radius(seal, _rules),
				float(_rules.get("edge_blend_m", 0.0)))
		ring.material_override = _material
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var centre: Vector2 = seal.centre
		ring.position = Vector3(centre.x, sea + SURFACE_LIFT_M, centre.y)
		add_child(ring)
		# A dark churned trough under the foam gives the white water the value
		# contrast calm pale cyan cannot; outside the race the sea stays calm.
		var trough := MeshInstance3D.new()
		trough.name = "Trough"
		trough.mesh = ring.mesh
		trough.material_override = _trough_material
		trough.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		trough.position.y = -SURFACE_LIFT_M * 0.5
		ring.add_child(trough)
		ring.add_child(_spray(float(seal.shore_radius_m), SEALS.outer_radius(seal, _rules)))
		# Breaking waves with real height read at the swimmer's grazing eye
		# level, where a flat ring collapses to a hairline at the horizon.
		var seed := int(hash(str(seal.id)))
		for raw: Variant in _rules.get("crests", []):
			var crest_spec: Array = raw
			var crest := MeshInstance3D.new()
			crest.name = "Crest_%d" % int(float(crest_spec[0]))
			crest.mesh = _wave(float(seal.shore_radius_m) + float(crest_spec[0]), float(crest_spec[1]), seed)
			crest.material_override = _crest_material
			crest.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			ring.add_child(crest)
			seed += 7919
		# Far races are sub-pixel; cull the ring and everything on it.
		var cull_m := float(_rules.get("visibility_range_m", 700.0))
		for part: Node in [ring] + ring.get_children():
			if part is GeometryInstance3D:
				(part as GeometryInstance3D).visibility_range_end = SEALS.outer_radius(seal, _rules) + cull_m
		_rings[str(seal.id)] = ring
	_refresh()


func is_race_visible(seal_id: String) -> bool:
	var ring: Node3D = _rings.get(seal_id)
	return ring != null and ring.visible


func _refresh() -> void:
	_last_revision = int(_game.world.flags.revision)
	for seal: Dictionary in _seals:
		var ring: Node3D = _rings[str(seal.id)]
		ring.visible = SEALS.is_sealed(seal, _game.world.flags)
	var player: Node = _world.local_rig()
	_rig_id = player.get_instance_id() if player != null else 0
	var fly: Node = player.get_node_or_null("FlyController") if player != null else null
	flight_restrictions = SEALS.sync_flight(fly, _seals, _rules, _game.world.flags, _dock_names)
	_gate_spray()


## Spray simulates only for a visible race within its draw range of the
## active camera; far or opened races neither draw nor simulate particles.
func _gate_spray() -> void:
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	var cull_m := float(_rules.get("visibility_range_m", 700.0))
	for seal: Dictionary in _seals:
		var ring: Node3D = _rings[str(seal.id)]
		var spray := ring.get_node_or_null("Spray") as GPUParticles3D
		if spray == null:
			continue
		var near := camera == null
		if camera != null:
			var centre: Vector2 = seal.centre
			var at := Vector2(camera.global_position.x, camera.global_position.z)
			near = at.distance_to(centre) < SEALS.outer_radius(seal, _rules) + cull_m
		spray.emitting = ring.visible and near


func _process(delta: float) -> void:
	if _game == null:
		return
	# A flag change or a rebuilt local trainer (co-op rejoin, respawned rig)
	# both re-sync rings and this trainer's Fly restrictions.
	var rig: Node = _world.local_rig()
	var rig_id := rig.get_instance_id() if rig != null else 0
	if int(_game.world.flags.revision) != _last_revision or rig_id != _rig_id:
		_refresh()
	_spray_check -= delta
	if _spray_check <= 0.0:
		_spray_check = 0.25
		_gate_spray()
	# Offset decreasing moves the pattern toward larger radius: outward flow.
	_material.uv1_offset.y = wrapf(_material.uv1_offset.y - float(_rules.get("foam_flow_m_s", 3.0)) * delta / TILE_M, 0.0, 1.0)
	_message_cooldown = maxf(0.0, _message_cooldown - delta)
	if _message_cooldown > 0.0:
		return
	var player := _world.local_rig() as CharacterBody3D
	if player == null:
		return
	var swim: Node = player.get("swim_controller")
	# Combat pause zeroes the flow, so nothing is throwing the swimmer back.
	if swim == null or int(swim.state.mode) in [STATE.Mode.LAND, STATE.Mode.COMBAT_PAUSED]:
		return
	var sample: Dictionary = _world.currents.sample(player.global_position)
	var seal_id := str(sample.get("seal", ""))
	if seal_id.is_empty():
		return
	for seal: Dictionary in _seals:
		if str(seal.id) != seal_id:
			continue
		var dock := SEALS.first_closed_dock(seal, _game.world.flags)
		var label := str(seal.label)
		last_message = str(_rules.get("message", "%s throws you back. Clear the %s dock first.")) % [
			label.substr(0, 1).to_upper() + label.substr(1), str(_dock_names.get(dock, dock))]
		_game.push_world_message(last_message)
		_message_cooldown = float(_rules.get("message_interval_s", 12.0))
		return


func _annulus(inner: float, outer: float, blend: float) -> ArrayMesh:
	# Three radii: waterline, start of the outer blend, and the race's edge
	# where the foam fades to open water with the same smooth falloff as flow.
	var radii := [inner, maxf(inner, outer - blend), outer]
	var alphas := [1.0, 1.0, 0.0]
	var segments := maxi(48, ceili(TAU * outer / 4.0))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var circumference_tiles := maxf(1.0, roundf(TAU * inner / TILE_M))
	var edge_noise := _ring_noise(int(hash(str(inner))) + 3, 0.35)
	var wobble := minf(float(_rules.get("outline_wobble_m", 2.5)), float(_rules.get("edge_blend_m", 4.0)) * 0.5)
	for index in segments:
		for band in 2:
			var a0 := TAU * float(index) / float(segments)
			var a1 := TAU * float(index + 1) / float(segments)
			var quad := [
				[a0, band], [a1, band], [a1, band + 1],
				[a0, band], [a1, band + 1], [a0, band + 1],
			]
			for corner: Array in quad:
				var angle: float = corner[0]
				var ring: int = corner[1]
				var radius: float = radii[ring]
				if ring > 0:
					# The race's visible edge wanders like water, not a decal.
					var probe := Vector2(cos(angle), sin(angle)) * inner / TAU * 2.0
					radius += wobble * edge_noise.get_noise_2d(probe.x, probe.y)
				tool.set_color(Color(1, 1, 1, alphas[ring]))
				tool.set_normal(Vector3.UP)
				tool.set_uv(Vector2(angle / TAU * circumference_tiles, (radius - inner) / TILE_M))
				tool.add_vertex(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
	return tool.commit()


func _spray(inner: float, outer: float) -> GPUParticles3D:
	# Spray bursting up through the race breaks the horizon line at swimming
	# eye height, where flat foam collapses to a sliver.
	var particles := GPUParticles3D.new()
	particles.name = "Spray"
	var circumference := TAU * (inner + outer) * 0.5
	particles.amount = clampi(int(circumference / float(_rules.get("spray_spacing_m", 2.5))), 24, 1600)
	particles.lifetime = float(_rules.get("spray_lifetime_s", 1.4))
	particles.preprocess = particles.lifetime
	particles.visibility_aabb = AABB(Vector3(-outer - 4.0, -1.0, -outer - 4.0), Vector3(outer * 2.0 + 8.0, 8.0, outer * 2.0 + 8.0))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	process.emission_ring_axis = Vector3.UP
	process.emission_ring_radius = outer - float(_rules.get("edge_blend_m", 4.0))
	process.emission_ring_inner_radius = inner + 2.0
	process.emission_ring_height = 0.2
	process.direction = Vector3.UP
	process.spread = 25.0
	process.initial_velocity_min = float(_rules.get("spray_speed_min_m_s", 2.0))
	process.initial_velocity_max = float(_rules.get("spray_speed_max_m_s", 4.0))
	process.gravity = Vector3(0, -float(_rules.get("spray_gravity_m_s2", 5.0)), 0)
	process.scale_min = 0.8
	process.scale_max = 1.8
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.0))
	fade.add_point(0.2, Color(1, 1, 1, 0.9))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	particles.process_material = process
	var quad := QuadMesh.new()
	var size := float(_rules.get("spray_size_m", 2.4))
	quad.size = Vector2(size, size)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = _spray_texture
	material.emission_enabled = true
	material.emission = Color(0.55, 0.6, 0.62)
	material.emission_energy_multiplier = float(_rules.get("spray_emission_energy", 0.35))
	material.render_priority = 1
	quad.material = material
	particles.draw_pass_1 = quad
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


func _spray_sprite() -> Texture2D:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length() / 31.5
			image.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 1.5))
	return ImageTexture.create_from_image(image)


func _trough() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(str(_rules.get("trough_colour", "#27514f"))) * Color(1, 1, 1, float(_rules.get("trough_alpha", 0.55)))
	material.roughness = 0.6
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Above the translucent sea, beneath the foam and breakers.
	material.render_priority = 1
	return material


## Noise in [-1, 1] around the ring, continuous across the seam.
func _ring_noise(seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	return noise


func _wave(radius: float, height: float, seed: int) -> ArrayMesh:
	# One closed breaker around the landform. Its cross-section curls outward
	# with the flow: dark teal face, white crest, falling lip fading to spray.
	# Height and radius wander so the ring breaks up instead of a bullseye.
	# The drawn edge may wander only within the race's own outer blend, so it
	# never strays past the physical boundary or under the shoreline.
	var wobble := minf(float(_rules.get("outline_wobble_m", 2.5)), float(_rules.get("edge_blend_m", 4.0)) * 0.5)
	var height_noise := _ring_noise(seed, float(_rules.get("wave_height_frequency", 0.22)))
	var radius_noise := _ring_noise(seed + 1, 0.35)
	var face := Color(str(_rules.get("wave_face_colour", "#2f6f6c")))
	var crest := Color(0.95, 0.98, 1.0)
	# (outward m, height fraction, colour, alpha)
	var profile := [
		[0.0, -0.05, face, 0.85],
		[0.35, 0.55, face.lerp(crest, 0.45), 0.95],
		[0.95, 0.95, crest, 1.0],
		[1.6, 0.8, crest, 0.75],
		[2.4, 0.25, crest, 0.0],
	]
	var segments := maxi(64, ceili(TAU * radius / float(_rules.get("wave_segment_m", 2.5))))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = []
	for index in segments + 1:
		var angle := TAU * float(index % segments) / float(segments)
		var direction := Vector2(cos(angle), sin(angle))
		# Sampling on a circle keeps the noise seamless where the ring closes.
		var sample := direction * radius / TAU * 2.0
		var local_height := height * clampf(0.55 + 0.9 * (height_noise.get_noise_2d(sample.x, sample.y) * 0.5 + 0.5), 0.35, 1.45)
		var local_radius := radius + wobble * radius_noise.get_noise_2d(sample.x, sample.y)
		var row: Array = []
		for point: Array in profile:
			var r := local_radius + float(point[0])
			row.append([Vector3(direction.x * r, -SURFACE_LIFT_M + local_height * float(point[1]), direction.y * r),
				Color(point[2].r, point[2].g, point[2].b, float(point[3]))])
		rows.append(row)
	for index in segments:
		var a: Array = rows[index]
		var b: Array = rows[index + 1]
		for k in profile.size() - 1:
			for corner: Array in [[a, k], [b, k], [b, k + 1], [a, k], [b, k + 1], [a, k + 1]]:
				var vertex: Array = corner[0][corner[1]]
				tool.set_color(vertex[1])
				tool.add_vertex(vertex[0])
	tool.index()
	tool.generate_normals()
	return tool.commit()


func _wave_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.45
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = Color(0.6, 0.64, 0.66)
	material.emission_energy_multiplier = float(_rules.get("foam_emission_energy", 0.2))
	# Overlapping translucent breakers sort per mesh, not per triangle; writing
	# depth keeps the nearer wave from showing jagged slivers of the farther.
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	material.render_priority = 2
	return material


func _foam_material(low: float = 0.28, high: float = 0.62) -> StandardMaterial3D:
	# White water whose coverage, not brightness, varies: the noise drives
	# alpha so broken foam reads over the water instead of a grey band.
	var noise := FastNoiseLite.new()
	noise.seed = 31
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	var grey := noise.get_seamless_image(256, 256)
	var foam := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in 256:
		for x in 256:
			var value := smoothstep(low, high, grey.get_pixel(x, y).r)
			foam.set_pixel(x, y, Color(1, 1, 1, value))
	var material := StandardMaterial3D.new()
	# Lit like the sea it churns, with a little self-light so daylight white
	# holds against the bright horizon without glowing at night.
	material.emission_enabled = true
	material.emission = Color(0.6, 0.64, 0.66)
	material.emission_energy_multiplier = float(_rules.get("foam_emission_energy", 0.35))
	material.roughness = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(0.94, 0.98, 1.0, float(_rules.get("foam_alpha", 0.62)))
	material.albedo_texture = ImageTexture.create_from_image(foam)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Draw after the translucent sea surface it lies on.
	material.render_priority = 2
	return material

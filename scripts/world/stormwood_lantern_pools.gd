extends RefCounted

## GPU F41#0 (Lantern Pools 4.70, 25 Oct: "no pools read; it's one carpet").
## Client presentation only: still black pools with a glowmoss lip, a few
## installed rim stones and one lantern post each, at authored candidate
## spots, each kept only where the ground under it is flat enough for a level
## water surface. Never changes terrain, save or network state. Scatter inside
## each kept pool is cleared on EVERY shell (vegetation.gd clear_area, the
## village boundary's own call), so host and clients agree on every body; the
## water, stones and lantern posts are visual only, on clients.
const CONFIG := "res://data/config/stormwood_lantern_pools.json"
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")
const WATER_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform vec3 deep : source_color = vec3(0.03, 0.08, 0.09);
uniform vec3 lip : source_color = vec3(0.35, 0.85, 0.65);
uniform float lip_energy = 0.9;
uniform float radius = 3.0;
varying vec2 local_xz;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { local_xz = VERTEX.xz; }
void fragment() {
	float angle = atan(local_xz.y, local_xz.x);
	float edge = radius * (0.86 + 0.14 * noise(vec2(angle * 2.2, 3.0)));
	float d = length(local_xz);
	float inside = 1.0 - smoothstep(edge - 0.18, edge, d);
	float lip_band = smoothstep(edge - 0.55, edge - 0.15, d) * inside;
	float specks = step(0.82, noise(local_xz * 3.1)) * lip_band;
	ALBEDO = mix(deep, lip * 0.4, lip_band * 0.6);
	EMISSION = lip * lip_energy * (lip_band * 0.35 + specks * 0.9);
	// Black still water: a low specular keeps it from mirroring the pale
	// storm sky into a grey puddle.
	ROUGHNESS = mix(0.12, 0.6, lip_band);
	SPECULAR = 0.3;
	METALLIC = 0.0;
	ALPHA = inside * mix(0.94, 0.75, lip_band);
}
"""


static func install(world: Node3D) -> void:
	var simulation_only := bool(world.get("simulation_only"))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary or not bool((parsed as Dictionary).get("enabled", false)):
		return
	var cfg: Dictionary = parsed
	var shader := Shader.new()
	shader.code = WATER_SHADER
	var root := Node3D.new()
	root.name = "LanternPools"
	world.add_child(root)
	var vegetation := world.get_node_or_null("Vegetation")
	var flat_limit := float(cfg.get("max_relief_m", 0.3))
	var placed := 0
	for entry: Variant in cfg.get("pools", []):
		var pool: Dictionary = entry
		var at: Array = pool.get("at", [])
		var radius := float(pool.get("radius_m", 3.0))
		var centre := Vector2(float(at[0]), float(at[1]))
		var low := INF
		var high := -INF
		for ring in [0.0, 0.5, 1.0]:
			for k in 12:
				var a := TAU * float(k) / 12.0
				var p := centre + Vector2(cos(a), sin(a)) * radius * float(ring)
				var h := float(world.call("ground_height_at", p.x, p.y))
				low = minf(low, h)
				high = maxf(high, h)
		if high - low > flat_limit:
			continue
		# Level at mid-relief: the low rim sits a few centimetres proud, the
		# high rim's ground covers the disc (filling only the hollow hid the
		# pools under the terrain in the first CPU round).
		var level := low + float(cfg.get("surface_lift_m", 0.06)) + (high - low) * 0.5
		if vegetation != null and vegetation.has_method("clear_area"):
			vegetation.call("clear_area", Vector3(centre.x, level, centre.y), radius)
		placed += 1
		if simulation_only:
			continue
		var basin: Dictionary = cfg.get("basin", {})
		if bool(basin.get("enabled", false)) and ResourceLoader.exists(str(basin.get("model", ""))) \
				and _build_basin(world, root, Vector3(centre.x, level, centre.y), radius, basin):
			_glow_fungi(world, root, centre, radius * float(basin.get("radius_scale", 1.25)), cfg.get("glow_fungi", {}))
		else:
			_build_pool(root, shader, Vector3(centre.x, level, centre.y), radius, cfg)
			_rim_stones(world, root, centre, radius, pool, cfg)
		if bool(pool.get("lantern", true)):
			_lantern_post(world, root, centre, radius, pool, cfg)
	root.set_meta("pools_placed", placed)
	_grove(world, root, cfg.get("grove", {}), simulation_only)


## The Meshy root-rimmed pool basin (tb/meshy-1024 ae67083ec) in place of the
## flat disc and loose stones. The GLB is a raised ring of roots and stones
## round dark water on a thin square slab (slab top at `slab_top_norm`, the
## water at `water_norm`, both in the unit model's height). Only the slab is
## sunk (its top `slab_sink_m` under the lowest ground of the footprint) so the
## root lip stands up as a raised spring; when the ground inside the ring
## would cover the water, the basin lifts until the water clears it, by at most
## `max_lift_m`, and otherwise this pool keeps its flat disc (returns false).
## The first two CPU tries seated the ring's TOP near the ground and buried it.
static func _build_basin(world: Node3D, root: Node3D, low_at: Vector3, radius: float, cfg: Dictionary) -> bool:
	var model := HERO_PROP.load_model(str(cfg.model))
	var bounds := BOUNDS.measure(model)
	var across := radius * 2.0 * float(cfg.get("radius_scale", 1.25))
	var factor := across / maxf(0.01, maxf(bounds.size.x, bounds.size.z))
	var flat := factor * float(cfg.get("height_scale", 1.0))
	var centre := Vector2(low_at.x, low_at.z)
	var low := INF
	var inner_high := -INF
	for ring: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		for k in 16:
			var a := TAU * float(k) / 16.0
			var p := centre + Vector2(cos(a), sin(a)) * across * 0.5 * ring
			var h := float(world.call("ground_height_at", p.x, p.y))
			low = minf(low, h)
			if ring <= 0.5:
				inner_high = maxf(inner_high, h)
	var slab_top := low - float(cfg.get("slab_sink_m", 0.05))
	var water_above := (float(cfg.get("water_norm", -0.066)) - float(cfg.get("slab_top_norm", -0.11))) * flat
	var lift := maxf(0.0, inner_high + float(cfg.get("water_clear_m", 0.03)) - (slab_top + water_above))
	if lift > float(cfg.get("max_lift_m", 0.25)):
		model.free()
		return false
	model.scale = Vector3(factor, flat, factor)
	model.position = Vector3(-bounds.get_center().x * factor, -float(cfg.get("slab_top_norm", -0.11)) * flat,
		-bounds.get_center().z * factor)
	var holder := Node3D.new()
	holder.name = "Basin%d" % root.get_child_count()
	holder.position = Vector3(centre.x, slab_top + lift, centre.y)
	holder.rotation.y = fposmod(low_at.x * 0.37 + low_at.z * 0.11, TAU)
	holder.set_meta(GRASS_FIELD.CLEAR_RADIUS_META, across * 0.5)
	holder.add_to_group(GRASS_FIELD.CLEAR_GROUP)
	root.add_child(holder)
	holder.add_child(model)
	return true


## Glowmoss Hollows' bioluminescent fungi (installed Meshy storm_fungi, the
## storm_mushroom layer's own model) in small clumps on a basin's rim.
## Natural glow: the region's own living light. Visual only.
static func _glow_fungi(world: Node3D, root: Node3D, centre: Vector2, radius: float, cfg: Dictionary) -> void:
	if not bool(cfg.get("enabled", false)):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(centre.x * 13.0 + centre.y * 7.0)
	var scales: Array = cfg.get("scale", [0.8, 1.4])
	for k in int(cfg.get("per_pool", 4)):
		var model := HERO_PROP.load_model(str(cfg.get("model", "")))
		if model == null:
			return
		HERO_PROP.glow(model, Color(str(cfg.get("glow_colour", "#5ad8a6"))), float(cfg.get("glow_energy", 1.2)))
		var a := TAU * (float(k) + rng.randf_range(-0.3, 0.3)) / float(cfg.get("per_pool", 4))
		var p := centre + Vector2(cos(a), sin(a)) * radius * rng.randf_range(0.95, 1.2)
		HERO_PROP.fit_height(model, rng.randf_range(float(scales[0]), float(scales[1])), 0.05)
		var seat := Node3D.new()
		seat.name = "GlowFungi"
		seat.position = Vector3(p.x, float(world.call("ground_height_at", p.x, p.y)), p.y)
		seat.rotation.y = rng.randf_range(0.0, TAU)
		root.add_child(seat)
		seat.add_child(model)


## GPU R (Lantern Pools 5.62 / 5.37, "no change"; every judge: an open carpet,
## "groves and clearings"): a ring of the Ash Road's storm-canopy trees round
## the hollow at authored spots (`trees`: [x, z, scale, yaw_deg, model index],
## generated clear of every route, seat, arch, camp, shelter and pool; checked
## by tests/test_stormwood_lantern_pools_grove.gd). Their trunk colliders are
## built on EVERY shell so host and clients agree; only clients draw them.
## Not harvestable (authored dressing, like the landmark trees).
static func _grove(world: Node3D, root: Node3D, cfg: Dictionary, simulation_only: bool) -> void:
	if not bool(cfg.get("enabled", false)):
		return
	var layer: Dictionary = {}
	var veg: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(cfg.get("vegetation", "res://data/config/stormwood_vegetation.json"))))
	if veg is Dictionary:
		layer = ((veg as Dictionary).get("layers", {}) as Dictionary).get(str(cfg.get("layer", "storm_canopy")), {})
	var models: Array = layer.get("models", [])
	if models.is_empty():
		return
	var radius := float(layer.get("collision_radius", 0.62))
	var holder := Node3D.new()
	holder.name = "HollowGrove"
	root.add_child(holder)
	var body := StaticBody3D.new()
	body.name = "HollowGroveTrunks"
	holder.add_child(body)
	var scenes: Array[PackedScene] = []
	if not simulation_only:
		for path: Variant in models:
			scenes.append(load(str(path)) as PackedScene)
	for raw: Variant in cfg.get("trees", []):
		var tree: Array = raw
		var at := Vector3(float(tree[0]), 0.0, float(tree[1]))
		at.y = float(world.call("ground_height_at", at.x, at.z))
		var scale := float(tree[2])
		var shape := CylinderShape3D.new()
		shape.radius = radius * scale
		shape.height = float(cfg.get("collider_height_m", 6.0))
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.position = at + Vector3.UP * shape.height * 0.5
		body.add_child(collider)
		if simulation_only:
			continue
		var scene := scenes[int(tree[4]) % scenes.size()]
		if scene == null:
			continue
		var visual := scene.instantiate() as Node3D
		_retint(visual, layer.get("retint", {}), layer.get("retexture", {}))
		visual.position = at
		visual.rotation.y = deg_to_rad(float(tree[3]))
		visual.scale = Vector3.ONE * scale
		holder.add_child(visual)


## The vegetation layer's own retint/retexture by material name, so the grove
## matches the scattered storm canopy.
static func _retint(node: Node, retint: Dictionary, retexture: Dictionary) -> void:
	if node is MeshInstance3D:
		var visual := node as MeshInstance3D
		for surface in visual.mesh.get_surface_count():
			var source := visual.get_active_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var name := source.resource_name
			if not retint.has(name) and not retexture.has(name):
				continue
			var tinted := source.duplicate() as BaseMaterial3D
			if retint.has(name):
				tinted.albedo_color = Color(str(retint[name]))
			if retexture.has(name) and ResourceLoader.exists(str(retexture[name])):
				tinted.albedo_texture = load(str(retexture[name]))
			visual.set_surface_override_material(surface, tinted)
	for child in node.get_children():
		_retint(child, retint, retexture)


static func _build_pool(root: Node3D, shader: Shader, at: Vector3, radius: float, cfg: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "Pool%d" % root.get_child_count()
	holder.position = at
	root.add_child(holder)
	var water := MeshInstance3D.new()
	water.name = "Water"
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.0, radius * 2.0)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	water.mesh = plane
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("radius", radius)
	material.set_shader_parameter("deep", Color(str(cfg.get("deep_colour", "#081517"))))
	material.set_shader_parameter("lip", Color(str(cfg.get("lip_colour", "#5ad8a6"))))
	material.set_shader_parameter("lip_energy", float(cfg.get("lip_energy", 0.9)))
	water.material_override = material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(water)
	# Ground cover (grass_field.gd tiers) keeps out of the water.
	holder.set_meta(GRASS_FIELD.CLEAR_RADIUS_META, radius * 0.95)
	holder.add_to_group(GRASS_FIELD.CLEAR_GROUP)


static func _rim_stones(world: Node3D, root: Node3D, centre: Vector2, radius: float, pool: Dictionary, cfg: Dictionary) -> void:
	var count := int(pool.get("stones", 4))
	var models: Array = cfg.get("stone_models", ["Rock_Medium_1"])
	for index in count:
		var a := TAU * (float(index) + 0.37 * sin(float(index) * 2.9 + centre.x)) / float(count)
		var p := centre + Vector2(cos(a), sin(a)) * radius * 0.98
		var rock := (load("res://assets/environment/stylized_nature/%s.gltf" % str(models[index % models.size()])) as PackedScene).instantiate() as Node3D
		var bounds := BOUNDS.measure(rock)
		var height := 0.35 + 0.25 * fposmod(sin(float(index) * 7.1 + centre.y), 1.0)
		var factor := height / maxf(0.1, bounds.size.y)
		rock.scale = Vector3.ONE * factor
		rock.position = Vector3(p.x, float(world.call("ground_height_at", p.x, p.y)) - bounds.position.y * factor - 0.1, p.y)
		rock.rotation.y = a * 1.7
		root.add_child(rock)


static func _lantern_post(world: Node3D, root: Node3D, centre: Vector2, radius: float, pool: Dictionary, cfg: Dictionary) -> void:
	var side := float(pool.get("lantern_angle_deg", 40.0))
	var a := deg_to_rad(side)
	var p := centre + Vector2(cos(a), sin(a)) * (radius + 0.7)
	var ground := float(world.call("ground_height_at", p.x, p.y))
	var post_height := float(cfg.get("post_height_m", 2.4))
	var body := Node3D.new()
	body.name = "LanternPost"
	body.position = Vector3(p.x, ground, p.y)
	body.rotation.y = atan2(centre.x - p.x, centre.y - p.y)
	root.add_child(body)
	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.22, post_height, 0.22)
	post.mesh = post_mesh
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(str(cfg.get("post_colour", "#5b4a3a")))
	wood.albedo_texture = load("res://assets/environment/stylized_nature/Bark_TwistedTree.png")
	wood.roughness = 0.9
	post.material_override = wood
	post.position.y = post_height * 0.5
	body.add_child(post)
	# A short arm toward the water and a hanging cage lantern, simple
	# parts that read at survey distance (the kit wall lantern did not).
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color("2b2d33")
	iron.metallic = 0.6
	iron.roughness = 0.5
	var arm := MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.1, 0.1, 0.8)
	arm.mesh = arm_mesh
	arm.material_override = wood
	arm.position = Vector3(0.0, post_height - 0.12, 0.36)
	body.add_child(arm)
	var cage := MeshInstance3D.new()
	var cage_mesh := BoxMesh.new()
	cage_mesh.size = Vector3(0.3, 0.4, 0.3)
	cage.mesh = cage_mesh
	cage.material_override = iron
	cage.position = Vector3(0.0, post_height - 0.5, 0.7)
	body.add_child(cage)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("ffd38a")
	glow.emission_enabled = true
	glow.emission = Color(str(cfg.get("flame_colour", "#ffb85c")))
	glow.emission_energy_multiplier = 4.0
	var flame := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.17
	sphere.height = 0.34
	flame.mesh = sphere
	flame.material_override = glow
	flame.position = cage.position + Vector3(0.0, 0.0, 0.0)
	body.add_child(flame)
	var light := OmniLight3D.new()
	light.light_color = Color(str(cfg.get("light_colour", "#ffc77a")))
	light.light_energy = float(cfg.get("light_energy", 1.6))
	light.omni_range = float(cfg.get("light_range_m", 9.0))
	light.position = flame.position + Vector3(0.0, -0.1, 0.0)
	body.add_child(light)

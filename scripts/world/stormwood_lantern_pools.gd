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
		if bool(basin.get("enabled", false)) and ResourceLoader.exists(str(basin.get("model", ""))):
			_build_basin(root, Vector3(centre.x, level, centre.y), radius, basin)
		else:
			_build_pool(root, shader, Vector3(centre.x, level, centre.y), radius, cfg)
			_rim_stones(world, root, centre, radius, pool, cfg)
		if bool(pool.get("lantern", true)):
			_lantern_post(world, root, centre, radius, pool, cfg)
	root.set_meta("pools_placed", placed)


## The Meshy root-rimmed pool basin (tb/meshy-1024 ae67083ec) in place of the
## flat disc and loose stones. Its square ground slab sits below the lowest
## ground; the model is flattened (`height_scale`) so only the root lip and
## water show, `rim_lift_m` above the lowest ground.
static func _build_basin(root: Node3D, low_at: Vector3, radius: float, cfg: Dictionary) -> void:
	# `low_at` is the disc's own mid-relief water level (first CPU try seated
	# it on the lowest ground and the terrain buried the whole basin).
	var model := HERO_PROP.load_model(str(cfg.model))
	var bounds := BOUNDS.measure(model)
	var across := radius * 2.0 * float(cfg.get("radius_scale", 1.25))
	var factor := across / maxf(0.01, maxf(bounds.size.x, bounds.size.z))
	var flat := factor * float(cfg.get("height_scale", 0.45))
	model.scale = Vector3(factor, flat, factor)
	model.position.y = float(cfg.get("rim_lift_m", 0.2)) - bounds.end.y * flat
	var holder := Node3D.new()
	holder.name = "Basin%d" % root.get_child_count()
	holder.position = low_at
	holder.rotation.y = fposmod(low_at.x * 0.37 + low_at.z * 0.11, TAU)
	holder.set_meta(GRASS_FIELD.CLEAR_RADIUS_META, across * 0.5)
	holder.add_to_group(GRASS_FIELD.CLEAR_GROUP)
	root.add_child(holder)
	holder.add_child(model)


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

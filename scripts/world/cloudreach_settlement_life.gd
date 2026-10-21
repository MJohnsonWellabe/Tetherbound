extends Node3D

## F08#3 settlement life candidate: lamp-lit approaches, a working market edge
## and edge trees for Galefoot and Cliffhold, plus the spire/visual overlay the
## judges asked for. Local presentation only: no collision, save field, RPC or
## route change. OFF unless enabled or a capture opts in with the preview arg.
const PATH := "res://data/config/cloudreach_settlement_life.json"
## F40 item candidates (P2-022 aviary entries etc.) reuse the same dressing
## vocabulary behind their own flag and file.
const ITEMS_PATH := "res://data/config/cloudreach_f40_items.json"
const LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const BONFIRE := preload("res://assets/props/quaternius_survival/Bonfire.obj")
const BONFIRE_FIRE := preload("res://assets/props/quaternius_survival/Bonfire_Fire.obj")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const LIGHTING := preload("res://scripts/world/cloudreach_landmark_lighting.gd")
const PROPS := {
	"cart": "res://assets/props/quaternius_fantasy/Stall_Cart_Empty.gltf",
	"stall": "res://assets/props/quaternius_fantasy/Stall_Empty.gltf",
	"apple_barrel": "res://assets/props/quaternius_fantasy/Barrel_Apples.gltf",
	"apple_crate": "res://assets/props/quaternius_fantasy/FarmCrate_Apple.gltf",
	"empty_crate": "res://assets/props/quaternius_fantasy/FarmCrate_Empty.gltf",
	"barrel": "res://assets/props/quaternius_fantasy/Barrel.gltf",
	"crate": "res://assets/props/quaternius_fantasy/Crate_Wooden.gltf",
	"bench": "res://assets/props/quaternius_fantasy/Bench.gltf",
	"pot": "res://assets/props/quaternius_fantasy/Pot_1.gltf",
	"wagon": "res://assets/buildings/quaternius_medieval/Prop_Wagon.gltf",
	"banner": "res://assets/props/quaternius_fantasy/Banner_1_Cloth.gltf",
	"tree_1": "res://assets/environment/stylized_nature/CommonTree_1.gltf",
	"tree_3": "res://assets/environment/stylized_nature/CommonTree_3.gltf",
	"tree_4": "res://assets/environment/stylized_nature/CommonTree_4.gltf",
	"twisted_tree": "res://assets/environment/stylized_nature/TwistedTree_2.gltf",
	"bush": "res://assets/environment/stylized_nature/Bush_Common_Flowers.gltf",
}
const MESHY := "res://assets/props/meshy-1020/cloudreach_%s/cloudreach_%s.glb"
static var _items_loaded := false
static var _items: Dictionary = {}
static var _loaded := false
static var _active: Dictionary = {}
var _clock: Node
var _lamps: Array[Dictionary] = []
var _last_weight := -1.0
var _clouds: Array[Dictionary] = []


static func config() -> Dictionary:
	if _loaded:
		return _active
	_loaded = true
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if raw is Dictionary and (bool(raw.get("enabled", false))
			or OS.get_cmdline_user_args().has(str(raw.get("preview_arg", "--none")))):
		_active = raw
	return _active


static func items_config() -> Dictionary:
	if _items_loaded:
		return _items
	_items_loaded = true
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ITEMS_PATH))
	if raw is Dictionary and (bool(raw.get("enabled", false))
			or OS.get_cmdline_user_args().has(str(raw.get("preview_arg", "--none")))):
		_items = raw
	return _items


## F08#3 terrace candidate: route-shoulder stations within `radius_m` of a
## settlement centre narrow toward `half_width_m` (blended over `blend_m`), so
## the shoulder's existing outer-edge drop shows beside the approach road. The
## render, walkable rows and collider share these station vertices.
static func shoulder_scale(at: Vector3, half_width: float) -> float:
	var narrow: Dictionary = config().get("narrow_shoulders", {})
	if narrow.is_empty() or half_width <= 0.0:
		return 1.0
	var radius := float(narrow.get("radius_m", 140.0))
	var blend := float(narrow.get("blend_m", 40.0))
	var target := minf(1.0, float(narrow.get("half_width_m", 9.0)) / half_width)
	var scale := 1.0
	for raw: Variant in narrow.get("centres", []):
		var d := Vector2(at.x, at.z).distance_to(Vector2(float(raw[0]), float(raw[1])))
		scale = minf(scale, lerpf(target, 1.0, smoothstep(radius - blend, radius, d)))
	return scale


static func merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key: Variant in overlay:
		if result.get(key) is Dictionary and overlay[key] is Dictionary:
			result[key] = merge(result[key], overlay[key])
		else:
			result[key] = overlay[key]
	return result


static func apply(base: Dictionary, section: String) -> Dictionary:
	var spec := config()
	return base if spec.is_empty() else merge(base, spec.get(section, {}))


## Reference-backed spire for a distant/settlement rock mass, or null when the
## candidate (or its spire swap) is off. Tall masses take the single stack,
## broad ones the conjoined cluster.
static func spire_scene(size: Vector3) -> PackedScene:
	if not bool(config().get("replace_spires", false)):
		return null
	var tall := size.y / maxf(maxf(size.x, size.z), 0.01) >= float(config().get("cluster_below_aspect", 1.4))
	var asset := "strata_spire_tall" if tall else "strata_spire_cluster"
	return load(MESHY % [asset, asset]) as PackedScene


## Height is authored; footprint follows the mass but never stretches the
## strata more than the configured ratio away from uniform.
static func spire_scale(size: Vector3, source: Vector3) -> Vector3:
	var y := size.y / maxf(source.y, 0.01)
	# A broad mass keeps a stack's proportions by growing taller (up to the
	# configured factor) rather than squashing into a drum.
	var footprint := maxf(size.x / maxf(source.x, 0.01), size.z / maxf(source.z, 0.01))
	y = clampf(footprint * float(config().get("spire_min_aspect_scale", 0.0)), y,
		y * float(config().get("spire_max_rise", 1.0)))
	var limit := float(config().get("spire_max_stretch", 1.6))
	return Vector3(clampf(size.x / maxf(source.x, 0.01), y / limit, y), y,
		clampf(size.z / maxf(source.z, 0.01), y / limit, y))


## The baked Meshy limestone is light enough to bleach under the Cloudreach
## sun and turn ice-blue under the moon; a per-instance albedo tint keeps the
## warm grey of the board without touching the shared imported material.
static func tint_rock(node: Node) -> void:
	var tint := Color(str(config().get("rock_tint", "#ffffff")))
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var stone := source.duplicate() as StandardMaterial3D
			stone.albedo_color = source.albedo_color * tint
			stone.roughness = 0.95
			mesh.set_surface_override_material(surface, stone)


func dress(world: Node3D, materials: Dictionary) -> void:
	name = "SettlementLife"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_clock = world.get_tree().get_first_node_in_group("day_cycle")
	var timber: Material = materials.get("weathered_timber", materials.get("wood"))
	if not items_config().is_empty():
		_dress_sites(world, items_config(), timber)
	var spec := config()
	if spec.is_empty():
		_process(0.0)
		return
	_dress_sites(world, spec, timber)
	_dress_vista(world, spec)
	_process(0.0)


func _dress_sites(world: Node3D, spec: Dictionary, timber: Material) -> void:
	for landmark_name: String in (spec.get("settlements", {}) as Dictionary):
		var site: Dictionary = spec.settlements[landmark_name]
		var root := world.get_node_or_null(NodePath("Landmarks/" + landmark_name)) as Node3D
		if root == null:
			push_error("Settlement life: missing landmark " + landmark_name)
			continue
		var holder := Node3D.new()
		holder.name = "SettlementLife"
		root.add_child(holder)
		for post: Dictionary in site.get("lamp_posts", []):
			_lamp_post(world, holder, post, spec.get("lamp", {}), timber)
		for prop: Dictionary in site.get("props", []):
			var at := _ground(world, holder, _v3(prop.at))
			if at != Vector3.INF:
				var model := _scene(holder, load(str(PROPS[prop.asset])) as PackedScene, at,
					float(prop.height), float(prop.get("yaw", 0.0)))
				if str(prop.asset).contains("tree") or prop.asset == "bush":
					# Same Cloudreach foliage/bark palette as the realm's own trees.
					world.call("_apply_tree_palette", model, holder.get_child_count())
		for fire: Dictionary in site.get("fires", []):
			_fire(world, holder, fire, timber)
		var swap: Dictionary = site.get("replace_kit_houses", {})
		if not swap.is_empty():
			# Same footprint, position and yaw as each Meadows-kit cottage; the
			# cottage keeps its authored colliders, doorway lane and NPC clearances.
			for child: Node in root.get_children():
				if not str(child.name).begins_with("Terrace_cottage"):
					continue
				var kit := child as Node3D
				for mesh: GeometryInstance3D in kit.find_children("*", "GeometryInstance3D", true, false):
					mesh.visible = false
				var at := holder.to_local(kit.global_position)
				var house := _scene(holder, load(MESHY % [swap.asset, swap.asset]) as PackedScene, at,
					float(swap.height), rad_to_deg(kit.global_rotation.y) + float(swap.get("yaw_offset", 0.0)))
				if house != null:
					_dress_building(house, str(swap.asset))
					_set_visibility(house, 900.0)
		for building: Dictionary in site.get("buildings", []):
			var at := _ground(world, holder, _v3(building.at))
			if at != Vector3.INF:
				_building(holder, building, at)
		for light: Dictionary in site.get("lights", []):
			var omni := OmniLight3D.new()
			omni.position = _v3(light.at)
			omni.light_color = Color(str(light.get("colour", "#ffb060")))
			omni.omni_range = float(light.get("range_m", 14.0))
			omni.omni_attenuation = float(light.get("attenuation", 1.2))
			holder.add_child(omni)
			var core := StandardMaterial3D.new()
			core.emission_enabled = true
			_lamps.append({"light": omni, "material": core, "energy": float(light.get("energy", 3.0)),
				"glow": 0.0, "day_glow": 0.0, "day_energy": float(light.get("day_energy", 0.0))})


func _dress_vista(world: Node3D, spec: Dictionary) -> void:
	# Vista pieces (cliff shelves, islets, spires) sit at authored world
	# positions in the open sky/cloud sea: no ground to snap to.
	var vista := Node3D.new()
	vista.name = "SettlementLifeVista"
	world.add_child(vista)
	for piece: Dictionary in spec.get("vista", []):
		var model := _scene(vista, load(MESHY % [piece.asset, piece.asset]) as PackedScene,
			_v3(piece.at), float(piece.height), float(piece.get("yaw", 0.0)))
		if model != null:
			tint_rock(model)
			_set_visibility(model, float(spec.get("vista_range_m", 3000.0)))
	var ring: Dictionary = spec.get("cloud_ring", {})
	if not ring.is_empty():
		_cloud_ring(vista, ring)


func _lamp_post(world: Node3D, parent: Node3D, post: Dictionary, lamp: Dictionary, timber: Material) -> void:
	var foot := _ground(world, parent, _v3(post.at))
	if foot == Vector3.INF:
		return
	var height := float(lamp.get("post_height_m", 3.4))
	var arm := float(lamp.get("arm_m", 0.9))
	var yaw := deg_to_rad(float(post.get("yaw", 0.0)))
	var pole := Node3D.new()
	pole.name = "SettlementLampPost"
	pole.position = foot
	pole.rotation.y = yaw
	parent.add_child(pole)
	_box(pole, Vector3(0, height * 0.5, 0), Vector3(0.2, height, 0.2), timber)
	_box(pole, Vector3(0, height - 0.1, arm * 0.5), Vector3(0.12, 0.12, arm + 0.1), timber)
	_box(pole, Vector3(0, 0.12, 0), Vector3(0.5, 0.24, 0.5), timber)
	var colour := Color(str(lamp.get("colour", "#ffc17d")))
	var lantern := LANTERN.instantiate() as Node3D
	var bounds: AABB = BOUNDS.measure(lantern)
	var lantern_h := float(lamp.get("lantern_height_m", 0.75))
	var factor := lantern_h / maxf(bounds.size.y, 0.01)
	lantern.scale = Vector3.ONE * factor
	lantern.position = Vector3(0, height - 0.2 - lantern_h, arm) \
		- Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	pole.add_child(lantern)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = colour
	glow.emission_enabled = true
	glow.emission = colour
	var core := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = float(lamp.get("core_radius_m", 0.16))
	sphere.height = sphere.radius * 2.0
	core.mesh = sphere
	core.material_override = glow
	core.position = Vector3(0, height - 0.2 - lantern_h * 0.55, arm)
	pole.add_child(core)
	var light := OmniLight3D.new()
	light.light_color = colour
	light.omni_range = float(lamp.get("range_m", 14.0))
	light.omni_attenuation = float(lamp.get("attenuation", 1.2))
	light.position = core.position
	pole.add_child(light)
	_lamps.append({"light": light, "material": glow, "energy": float(lamp.get("energy", 3.0)),
		"glow": float(lamp.get("glow", 4.0)), "day_glow": 0.3})


func _building(parent: Node3D, spec: Dictionary, at: Vector3) -> void:
	var model := _scene(parent, load(MESHY % [spec.asset, spec.asset]) as PackedScene, at,
		float(spec.height), float(spec.get("yaw", 0.0)))
	if model == null:
		return
	_dress_building(model, str(spec.asset))
	var placement := model.get_parent() as Node3D
	var bounds: AABB = BOUNDS.measure(model)
	var size := bounds.size * (float(spec.height) / maxf(bounds.size.y, 0.01))
	# Walls are solid: one box over the measured footprint, like the prefabs.
	# A piece fronting existing collision (the terrace wall) passes 0.
	if float(spec.get("collision_fraction", 0.8)) > 0.0:
		_collide(placement, size, float(spec.get("collision_fraction", 0.8)))
	_set_visibility(model, 900.0)
	if spec.has("door_light"):
		# A contained warm pool at the door: the night read the judges asked for.
		var light := OmniLight3D.new()
		var door: Array = spec.door_light
		light.position = Vector3(float(door[0]), float(door[1]), float(door[2]))
		light.light_color = Color(str(config().get("lamp", {}).get("colour", "#ffb060")))
		light.omni_range = 9.0
		placement.add_child(light)
		var glow := StandardMaterial3D.new()
		glow.albedo_color = light.light_color
		glow.emission_enabled = true
		glow.emission = light.light_color
		var pane := MeshInstance3D.new()
		var quad := SphereMesh.new()
		quad.radius = 0.18
		quad.height = 0.36
		pane.mesh = quad
		pane.material_override = glow
		pane.position = light.position
		placement.add_child(pane)
		_lamps.append({"light": light, "material": glow, "energy": 3.0, "glow": 6.0, "day_glow": 0.2})


## Weathered stone tint for the clean Meshy facades, and night window glow
## where the asset ships a mask of its baked amber panes.
func _dress_building(model: Node3D, asset: String) -> void:
	var spec := config() if not config().is_empty() else items_config()
	var tint := Color(str(spec.get("building_tint", "#ffffff")))
	var mask_path := (MESHY % [asset, asset]).trim_suffix(".glb") + "_window_mask.png"
	var mask: Texture2D = load(mask_path) as Texture2D if ResourceLoader.exists(mask_path) else null
	var glow := Color(str(spec.get("window_colour", "#ffa04a")))
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var finish := source.duplicate() as StandardMaterial3D
			finish.albedo_color = source.albedo_color * tint
			# Meshy exports can carry an alpha channel; masonry must be opaque.
			finish.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			if mask != null:
				finish.emission_enabled = true
				finish.emission = glow
				finish.emission_texture = mask
				finish.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
				finish.emission_energy_multiplier = 0.0
				_lamps.append({"light": null, "material": finish,
					"glow": float(spec.get("window_night_energy", 2.5)), "day_glow": 0.0})
			mesh.set_surface_override_material(surface, finish)


func _collide(placement: Node3D, size: Vector3, fraction: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x * fraction, size.y, size.z * fraction)
	shape.shape = box
	shape.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(shape)
	placement.add_child(body)


## A bank of installed cumulus cards wrapping each settlement just below its
## rim, so the horizon past the plateau reads as a cloud sea, not open water.
## Lit cards: the moon turns them night-blue with the rest of the scene.
func _cloud_ring(parent: Node3D, ring: Dictionary) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/environment/cloudreach/cloud_bank_v1.png") as Texture2D
	material.albedo_color = Color(str(ring.get("tint", "#e8ecf2")))
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	_clouds.append({"material": material, "day": material.albedo_color,
		"night": Color(str(ring.get("night_tint", "#3e4a66")))})
	var rng := RandomNumberGenerator.new()
	rng.seed = int(ring.get("seed", 1020))
	var radius: Array = ring.get("radius_m", [260.0, 520.0])
	var drop: Array = ring.get("drop_m", [25.0, 70.0])
	var width: Array = ring.get("width_m", [180.0, 280.0])
	var count := int(ring.get("count", 14))
	for raw: Variant in ring.get("centres", []):
		var centre := _v3(raw)
		for index in count:
			var angle := TAU * (float(index) + rng.randf_range(-0.3, 0.3)) / float(count)
			var w := rng.randf_range(float(width[0]), float(width[1]))
			var card := MeshInstance3D.new()
			var quad := QuadMesh.new()
			quad.size = Vector2(w, w * 0.5)
			card.mesh = quad
			card.material_override = material
			card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var r := rng.randf_range(float(radius[0]), float(radius[1]))
			card.position = centre + Vector3(sin(angle) * r,
				-rng.randf_range(float(drop[0]), float(drop[1])), cos(angle) * r)
			card.visibility_range_end = float(ring.get("visible_m", 2500.0))
			parent.add_child(card)


func _set_visibility(node: Node, distance: float) -> void:
	for mesh: GeometryInstance3D in node.find_children("*", "GeometryInstance3D", true, false):
		mesh.visibility_range_end = distance


func _fire(world: Node3D, parent: Node3D, fire: Dictionary, timber: Material) -> void:
	var at := _ground(world, parent, _v3(fire.at))
	if at == Vector3.INF:
		return
	var width := float(fire.get("width_m", 2.6))
	_mesh(parent, BONFIRE, at, width, timber, true)
	var flame := StandardMaterial3D.new()
	flame.albedo_color = Color("#ff9f45")
	flame.emission_enabled = true
	flame.emission = Color("#ff8a32")
	flame.emission_energy_multiplier = 2.2
	_mesh(parent, BONFIRE_FIRE, at + Vector3.UP * 0.25, width * 0.7, flame, false)
	var light := OmniLight3D.new()
	light.light_color = Color("#ffb568")
	light.omni_range = float(fire.get("range_m", 18.0))
	light.position = at + Vector3.UP * 1.8
	parent.add_child(light)
	_lamps.append({"light": light, "material": flame, "energy": float(fire.get("energy", 4.0)),
		"glow": 2.6, "day_glow": 1.6, "day_energy": 0.6})


func _process(_delta: float) -> void:
	if not is_instance_valid(_clock):
		return
	var weight := LIGHTING.night_weight(float(_clock.call("hour")), {})
	if is_equal_approx(weight, _last_weight):
		return
	_last_weight = weight
	for cloud: Dictionary in _clouds:
		(cloud.material as StandardMaterial3D).albedo_color = (cloud.day as Color).lerp(cloud.night, weight)
	for lamp: Dictionary in _lamps:
		if lamp.light != null:
			(lamp.light as OmniLight3D).light_energy = lerpf(float(lamp.get("day_energy", 0.0)), float(lamp.energy), weight)
		(lamp.material as StandardMaterial3D).emission_energy_multiplier = lerpf(
			float(lamp.day_glow), float(lamp.glow), weight)


func _ground(world: Node3D, parent: Node3D, local: Vector3) -> Vector3:
	var global := parent.to_global(local)
	var height := float(world.call("ground_height_near", global + Vector3.UP * 2.0))
	if is_nan(height) or absf(height - global.y) > 12.0:
		# Open terrain beyond the landmark crown has collision, not an
		# authored surface record: take the first solid hit below.
		height = NAN
		var space := world.get_world_3d().direct_space_state if world.get_world_3d() != null else null
		if space != null:
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(
				global + Vector3.UP * 30.0, global + Vector3.DOWN * 30.0))
			if not hit.is_empty():
				height = (hit.position as Vector3).y
	if is_nan(height):
		push_warning("Settlement life: no ground at " + str(global))
		return Vector3.INF
	print("SETTLEMENT_LIFE placed %s y=%.2f" % [str(global), height])
	return parent.to_local(Vector3(global.x, height, global.z))


func _scene(parent: Node3D, packed: PackedScene, at: Vector3, height: float, yaw: float) -> Node3D:
	if packed == null:
		return null
	var model := packed.instantiate() as Node3D
	var bounds: AABB = BOUNDS.measure(model)
	var factor := height / maxf(bounds.size.y, 0.01)
	var placement := Node3D.new()
	placement.position = at
	placement.rotation.y = deg_to_rad(yaw)
	parent.add_child(placement)
	model.scale = Vector3.ONE * factor
	model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	placement.add_child(model)
	return model


func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, target: float, material: Material, by_width: bool) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	var bounds := mesh.get_aabb()
	var factor := target / maxf(maxf(bounds.size.x, bounds.size.z) if by_width else bounds.size.y, 0.01)
	instance.scale = Vector3.ONE * factor
	instance.position = at - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	parent.add_child(instance)


func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.material_override = material
	box.position = at
	parent.add_child(box)


static func _v3(raw: Variant) -> Vector3:
	var values := raw as Array
	return Vector3(float(values[0]), float(values[1]), float(values[2]))

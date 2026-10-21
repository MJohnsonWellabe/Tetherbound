extends Node3D

## F08#3 settlement life candidate: lamp-lit approaches, a working market edge
## and edge trees for Galefoot and Cliffhold, plus the spire/visual overlay the
## judges asked for. Local presentation only: no collision, save field, RPC or
## route change. OFF unless enabled or a capture opts in with the preview arg.
const PATH := "res://data/config/cloudreach_settlement_life.json"
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
static var _loaded := false
static var _active: Dictionary = {}
var _clock: Node
var _lamps: Array[Dictionary] = []
var _last_weight := -1.0


static func config() -> Dictionary:
	if _loaded:
		return _active
	_loaded = true
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if raw is Dictionary and (bool(raw.get("enabled", false))
			or OS.get_cmdline_user_args().has(str(raw.get("preview_arg", "--none")))):
		_active = raw
	return _active


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


func dress(world: Node3D, materials: Dictionary) -> void:
	var spec := config()
	if spec.is_empty():
		return
	name = "SettlementLife"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_clock = world.get_tree().get_first_node_in_group("day_cycle")
	var timber: Material = materials.get("weathered_timber", materials.get("wood"))
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
				_scene(holder, load(str(PROPS[prop.asset])) as PackedScene, at,
					float(prop.height), float(prop.get("yaw", 0.0)))
		for fire: Dictionary in site.get("fires", []):
			_fire(world, holder, fire, timber)
	_process(0.0)


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
	for lamp: Dictionary in _lamps:
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


func _scene(parent: Node3D, packed: PackedScene, at: Vector3, height: float, yaw: float) -> void:
	if packed == null:
		return
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

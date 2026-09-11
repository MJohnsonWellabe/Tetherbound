extends Node3D

## Visual-only identity layer for the storm-blasted Glass Field approach.
## The route, named alpha, Ember Bivouac and Dynamo gameplay remain owned by
## their existing runtimes. Everything built here is non-colliding dressing.

const CONFIG_PATH := "res://data/config/stormwood_glass_field.json"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const DEAD_TREES := {
	"dead_1": preload("res://assets/environment/stylized_nature/DeadTree_1.gltf"),
	"dead_2": preload("res://assets/environment/stylized_nature/DeadTree_2.gltf"),
	"dead_3": preload("res://assets/environment/stylized_nature/DeadTree_3.gltf"),
}
const TETHER_BANNER := preload("res://assets/environment/team_tether/hall/team_tether_banner_rig.glb")
const GLASS_BLUE := Color("#57c8d5")
const GLASS_CORE := Color("#b8f4f0")
const FUSED_GROUND := Color("#182d31")

var config: Dictionary = {}
var _world: Node3D
var _origin_xz := Vector2.ZERO
var _forward := Vector2.UP
var _right := Vector2.RIGHT
var _origin_ground := 0.0


func build(world: Node3D, simulation_only: bool = false) -> void:
	if get_child_count() > 0:
		return
	_world = world
	config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	_origin_xz = _vec2(config.origin)
	var heading := _vec2(config.heading_to)
	_forward = (heading - _origin_xz).normalized()
	_right = Vector2(_forward.y, -_forward.x)
	_origin_ground = float(world.call("ground_height_at", _origin_xz.x, _origin_xz.y))
	position = Vector3(_origin_xz.x, _origin_ground, _origin_xz.y)
	rotation.y = atan2(_forward.x, _forward.y)
	if simulation_only:
		return
	for raw: Dictionary in config.get("clusters", []):
		_build_cluster(raw)
	for raw: Dictionary in config.get("blasted_trees", []):
		_build_blasted_tree(raw)
	for raw: Dictionary in config.get("tether_standards", []):
		_build_standard(raw)


func _build_cluster(spec: Dictionary) -> void:
	var centre := _vec2(spec.at)
	var root := Node3D.new()
	root.name = "StormglassCluster_%s" % str(spec.id)
	add_child(root)
	var scar := MeshInstance3D.new()
	scar.name = "FusedStrikeScar"
	var scar_mesh := CylinderMesh.new()
	scar_mesh.top_radius = float(spec.scar_radius_m)
	scar_mesh.bottom_radius = float(spec.scar_radius_m) * 1.08
	scar_mesh.height = 0.10
	scar_mesh.radial_segments = 11
	scar.mesh = scar_mesh
	scar.material_override = _fused_material()
	scar.position = _local_grounded(centre, 0.07)
	scar.rotation.y = deg_to_rad(float(str(spec.id).hash() % 37))
	root.add_child(scar)
	var count := int(spec.shards)
	var spread := float(config.shard_spread_m)
	for index in count:
		var angle := TAU * float(index) / float(count) + float(str(spec.id).hash() % 19) * 0.07
		var radius := spread * (0.38 + 0.58 * float((index * 7) % count) / maxf(1.0, float(count - 1)))
		var local := centre + Vector2(cos(angle), sin(angle)) * radius
		var height := float(spec.height_m) * (0.48 + 0.52 * float((index * 5 + 2) % count) / maxf(1.0, float(count - 1)))
		_add_shard(root, "%02d" % index, local, height, angle)
	_add_fissures(root, centre, float(spec.scar_radius_m), str(spec.id).hash())
	if bool(spec.get("night_light", false)):
		var light := OmniLight3D.new()
		light.name = "ResidualStrikeGlow"
		light.position = _local_grounded(centre, 3.2)
		light.light_color = GLASS_BLUE
		# Keep a small numeric margin below the declared budget: Godot stores
		# these properties as float32, so an authored 0.85 can round just above
		# a strict <= 0.85 acceptance check.
		light.light_energy = 0.84
		light.omni_range = 17.8
		light.shadow_enabled = false
		root.add_child(light)


func _add_shard(parent: Node3D, suffix: String, local: Vector2, height: float, angle: float) -> void:
	var shard := MeshInstance3D.new()
	shard.name = "GlassShard%s" % suffix
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.04
	mesh.bottom_radius = clampf(height * 0.105, 0.42, 1.15)
	mesh.height = height
	mesh.radial_segments = 5
	mesh.rings = 1
	shard.mesh = mesh
	shard.material_override = _glass_material()
	shard.position = _local_grounded(local, height * 0.48)
	shard.rotation.y = angle * 1.7
	shard.rotation.x = deg_to_rad(sin(angle * 2.0) * 5.5)
	shard.rotation.z = deg_to_rad(cos(angle * 1.3) * 4.5)
	parent.add_child(shard)


func _add_fissures(parent: Node3D, centre: Vector2, radius: float, seed_value: int) -> void:
	for index in 3:
		var angle := float(seed_value % 31) * 0.09 + TAU * float(index) / 3.0
		var start := centre + Vector2(cos(angle), sin(angle)) * radius * 0.18
		var finish := centre + Vector2(cos(angle + 0.18), sin(angle + 0.18)) * radius * 1.15
		var a := _local_grounded(start, 0.16)
		var b := _local_grounded(finish, 0.16)
		var segment := MeshInstance3D.new()
		segment.name = "GlassFissure%d" % index
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.07
		mesh.bottom_radius = 0.13
		mesh.height = a.distance_to(b)
		mesh.radial_segments = 5
		segment.mesh = mesh
		segment.position = (a + b) * 0.5
		segment.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
		segment.material_override = _glow_material()
		parent.add_child(segment)


func _build_blasted_tree(spec: Dictionary) -> void:
	var packed := DEAD_TREES.get(str(spec.model)) as PackedScene
	if packed == null:
		return
	var tree := packed.instantiate() as Node3D
	tree.name = "BlastedTree_%s" % str(spec.id)
	var bounds := BOUNDS.measure(tree)
	var factor := float(spec.height_m) / maxf(0.1, bounds.size.y)
	tree.scale = Vector3.ONE * factor
	var local := _vec2(spec.at)
	tree.position = _local_grounded(local, -bounds.position.y * factor)
	tree.rotation.y = deg_to_rad(float(spec.yaw_deg))
	add_child(tree)


func _build_standard(spec: Dictionary) -> void:
	var standard := TETHER_BANNER.instantiate() as Node3D
	standard.name = "TetherWarningStandard_%s" % str(spec.id)
	var bounds := BOUNDS.measure(standard)
	var factor := float(spec.height_m) / maxf(0.1, bounds.size.y)
	standard.scale = Vector3.ONE * factor
	var local := _vec2(spec.at)
	standard.position = _local_grounded(local, -bounds.position.y * factor)
	standard.rotation.y = deg_to_rad(float(spec.yaw_deg))
	add_child(standard)


func _local_grounded(local: Vector2, lift: float) -> Vector3:
	var world_xz := _origin_xz + _right * local.x + _forward * local.y
	var ground := float(_world.call("ground_height_at", world_xz.x, world_xz.y))
	return Vector3(local.x, ground - _origin_ground + lift, local.y)


func _vec2(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))


func _glass_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(GLASS_BLUE, 0.72)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.38
	material.roughness = 0.18
	material.emission_enabled = true
	material.emission = GLASS_BLUE.darkened(0.28)
	material.emission_energy_multiplier = 0.24
	return material


func _fused_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = FUSED_GROUND
	material.metallic = 0.48
	material.roughness = 0.32
	return material


func _glow_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = GLASS_CORE.darkened(0.36)
	material.emission_enabled = true
	material.emission = GLASS_CORE
	material.emission_energy_multiplier = 1.25
	return material

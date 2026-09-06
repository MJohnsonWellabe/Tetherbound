extends Node3D

## Water realm shell: fixed baked Terrain3D residency supports peers on
## different islands. Gameplay services are installed separately from terrain.
const CONFIG_PATH := "res://data/config/water_world.json"
const VISUAL_PATH := "res://data/config/water_visual.json"
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const CURRENTS := preload("res://scripts/world/water_current_field.gd")
const SWIM := preload("res://scripts/player/swim_controller.gd")
const SURFACE := preload("res://scripts/world/water_surface.gd")

@export var simulation_only: bool = false
@export var shell_realm: String = "water"
var _shell_ready: bool = false
var terrain: Node3D
var field: RefCounted
var currents: RefCounted
var config: Dictionary
var _visual: Dictionary


func _ready() -> void:
	if simulation_only:
		_strip_local_presentation()
	config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	_visual = JSON.parse_string(FileAccess.get_file_as_string(VISUAL_PATH))
	field = FIELD.new(config)
	currents = CURRENTS.new(config)
	if not ClassDB.class_exists("Terrain3D"):
		push_error("Water requires Terrain3D")
		return
	terrain = ClassDB.instantiate("Terrain3D")
	terrain.name = "Terrain"
	terrain.set("free_editor_textures", false)
	add_child(terrain)
	await get_tree().process_frame
	terrain.set("region_size", int(config.terrain.region_size))
	terrain.set("vertex_spacing", float(config.terrain.vertex_spacing))
	if int(terrain.get("region_size")) != int(config.terrain.region_size):
		push_error("Water terrain region size was not accepted")
		return
	terrain.set("data_directory", str(config.terrain.data_directory))
	var camera := local_camera_rig()
	if camera != null:
		var eye := camera.get_node_or_null("Camera3D") as Camera3D
		if eye != null:
			eye.far = float(_visual.view.camera_far_m)
			terrain.call("set_camera", eye)
	# FULL_GAME supports the union of occupied islands independently of camera.
	terrain.set("collision_mode", int(config.terrain.collision_mode))
	if int(terrain.get("collision_mode")) != int(config.terrain.collision_mode):
		push_error("Water full-world collision was not accepted")
		return
	if not simulation_only:
		_build_materials()
		var surface := SURFACE.new()
		surface.name = "WaterSurface"
		add_child(surface)
		surface.build(config, _visual)
	var player := local_rig()
	if player != null and not simulation_only:
		player.global_position = entry_anchor("from_stormwood")
		var swimming := SWIM.new()
		swimming.name = "SwimController"
		player.add_child(swimming)
		swimming.setup(player, self, local_camera_rig())
		player.set("swim_controller", swimming)
	_shell_ready = true


func shell_build_complete() -> bool:
	return _shell_ready


func _strip_local_presentation() -> void:
	for path: String in ["WorldEnvironment", "Sun", "WorldLook", "PlaygroundHUD"]:
		var node := get_node_or_null(NodePath(path))
		if node != null:
			remove_child(node)
			node.queue_free()
	var camera := get_node_or_null("CameraRig/Camera3D") as Camera3D
	if camera != null:
		camera.current = false
	var rig := local_rig()
	if rig != null:
		rig.process_mode = Node.PROCESS_MODE_DISABLED
		rig.visible = false
		rig.collision_layer = 0
		rig.collision_mask = 0


func world_realm() -> String:
	return "water"


func local_rig() -> CharacterBody3D:
	return get_node_or_null("Player") as CharacterBody3D


func local_camera_rig() -> Node3D:
	return get_node_or_null("CameraRig") as Node3D


func ground_height_at(x: float, z: float) -> float:
	if terrain == null:
		return NAN
	var data: Object = terrain.get("data")
	return float(data.call("get_height", Vector3(x, 0, z))) if data != null else NAN


func ground_height_near(x: float, z: float, _reference_y: float = 0.0) -> float:
	return ground_height_at(x, z)


func water_depth_at(position: Vector3) -> float:
	return maxf(0.0, field.water_level() - field.height_at(position.x, position.z))


func current_at(position: Vector3, liberated: bool = false) -> Vector3:
	return currents.sample(position, liberated).velocity


func entry_anchor(_entry_id: String = "from_stormwood") -> Vector3:
	# The authored First Shore arrival; height always comes from baked terrain.
	var point := Vector3(0, 0, 0)
	var entry: Variant = config.get("entry_anchors", {}).get("from_stormwood", {})
	if entry is Dictionary:
		var raw: Array = entry.get("position", [0, 0, 0])
		point = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	var height := ground_height_at(point.x, point.z)
	if is_finite(height):
		point.y = height + 0.15
	return point


func _build_materials() -> void:
	var assets: Object = ClassDB.instantiate("Terrain3DAssets")
	var index := 0
	for spec: Dictionary in _visual.terrain.textures:
		var texture: Object = ClassDB.instantiate("Terrain3DTextureAsset")
		texture.set("name", str(spec.name))
		texture.set("id", index)
		texture.set("albedo_texture", load(str(spec.albedo)))
		texture.set("normal_texture", load(str(spec.normal)))
		texture.set("normal_depth", float(spec.normal_depth))
		texture.set("uv_scale", float(spec.uv_scale))
		texture.set("albedo_color", Color(str(spec.tint)))
		assets.call("set_texture", index, texture)
		index += 1
	terrain.set("assets", assets)
	var material: Object = terrain.get("material")
	material.set("show_checkered", false)
	material.set("show_colormap", false)
	material.set("auto_shader", false)

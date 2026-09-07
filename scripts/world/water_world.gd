extends Node3D

## Water realm shell: fixed baked Terrain3D residency supports peers on
## different islands. Gameplay services are installed separately from terrain.
const CONFIG_PATH := "res://data/config/water_world.json"
const VISUAL_PATH := "res://data/config/water_visual.json"
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const CURRENTS := preload("res://scripts/world/water_current_field.gd")
const SWIM := preload("res://scripts/player/swim_controller.gd")
const SURFACE := preload("res://scripts/world/water_surface.gd")
const CHAPTER := preload("res://scripts/world/water_chapter.gd")
const PICKUPS := preload("res://scripts/world/water_scene_pickups.gd")
const DEATH := preload("res://scripts/world/water_player_death.gd")
const ENCOUNTERS := preload("res://scripts/world/water_scene_encounters.gd")
const DOCKS := preload("res://scripts/world/water_dock_actions.gd")
const RIDING := preload("res://scripts/world/water_riding_controller.gd")
const MOUNTED_SWIM := preload("res://scripts/world/water_mounted_swim.gd")
const CAMPS := preload("res://scripts/world/water_camps.gd")

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
	var current_config := config.duplicate(true)
	var traversal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
	for current: Dictionary in current_config.currents:
		for dock: Dictionary in config.docks:
			if str(current.route_id).begins_with(str(dock.outbound_edge) + "_") and not str(dock.unlock_flag).is_empty():
				current.required_unlock_flag = dock.unlock_flag
				current.closed_strength_m_s = float(traversal.docks.closed_current_strength_m_s)
	var game := get_node("/root/Game")
	currents = CURRENTS.new(current_config, game.world.flags)
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
		var recovery := DEATH.new()
		recovery.name = "PlayerDeath"
		add_child(recovery)
		recovery.build(self, player, entry_anchor("from_stormwood"))
	var chapter := CHAPTER.new()
	chapter.name = "WaterChapter"
	add_child(chapter)
	chapter.build(self)
	var camps := CAMPS.new()
	camps.name = "WaterCamps"
	add_child(camps)
	camps.build(self)
	var docks := DOCKS.new()
	docks.name = "WaterDocks"
	add_child(docks)
	docks.build(self)
	var director := ENCOUNTERS.build(self, chapter.npc_bodies)
	if not simulation_only:
		var riding := RIDING.new()
		riding.name = "RidingController"
		riding.water_world = self
		riding.player_path = ^"../Player"
		riding.camera_rig_path = ^"../CameraRig"
		riding.encounter_path = ^"../EncounterDirector"
		riding.manager_path = ^"../CombatManager"
		add_child(riding)
		get_node("PlayerDeath").configure_riding(riding)
		var swimming_mount := MOUNTED_SWIM.new()
		swimming_mount.name = "MountedSwimming"
		add_child(swimming_mount)
		swimming_mount.setup(self, riding, director)
	var pickups := PICKUPS.new()
	pickups.name = "WaterPickups"
	pickups.build(self)
	_shell_ready = true
	if not simulation_only:
		if str(game.pending_entry_for("water")).is_empty():
			game.apply_loaded_player_pose()
		else:
			_finish_entry.call_deferred(game)


func _finish_entry(game: Node) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if is_instance_valid(game):
		game.complete_realm_entry("water")


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


func ground_height_near(x: Variant, z: float = 0.0, _reference_y: float = 0.0) -> float:
	# Existing realm combat surfaces pass an XYZ point; terrain samplers pass
	# X/Z scalars. Water has one terrain stratum, shared by both callers.
	return ground_height_at(x.x, x.z) if x is Vector3 else ground_height_at(float(x), z)


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

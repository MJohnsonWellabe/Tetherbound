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
const REALM_GATE := preload("res://scripts/world/realm_gate.gd")
const FIRST_SHORE_GATE_SITE := preload("res://scripts/world/water_first_shore_gate_site.gd")
const FIRST_SHORE_WELCOME_SITE := preload("res://scripts/world/water_first_shore_welcome_site.gd")
const FIRST_SHORE_HORIZON_STONES := preload("res://scripts/world/water_first_shore_horizon_stones.gd")
const GULL_REST_SIGNAL_SITE := preload("res://scripts/world/water_gull_rest_signal_site.gd")
const WATER_VEGETATION := preload("res://scripts/world/water_vegetation.gd")
const GROUND_COVER := preload("res://scripts/world/grass_field.gd")
const GROUND_COVER_PATH := "res://data/config/water_ground_cover.json"

@export var simulation_only: bool = false
@export var shell_realm: String = "water"
var _shell_ready: bool = false
var terrain: Node3D
var field: RefCounted
var currents: RefCounted
var config: Dictionary
var _visual: Dictionary
var veilfall: Node3D


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
		var vegetation := WATER_VEGETATION.new()
		vegetation.name = "WaterVegetation"
		add_child(vegetation)
		vegetation.build(config, field)
		_stand_up_ground_cover()
		var surface := SURFACE.new()
		surface.name = "WaterSurface"
		add_child(surface)
		surface.build(config, _visual)
		var gull_signal := GULL_REST_SIGNAL_SITE.new()
		gull_signal.name = "GullRestSignalSpire"
		add_child(gull_signal)
		gull_signal.build(self)
		var first_shore_welcome := FIRST_SHORE_WELCOME_SITE.new()
		first_shore_welcome.name = "FirstShoreWelcomeBeacon"
		add_child(first_shore_welcome)
		first_shore_welcome.build(self)
		var horizon_stones := FIRST_SHORE_HORIZON_STONES.new()
		horizon_stones.name = "FirstShoreHorizonStones"
		add_child(horizon_stones)
		horizon_stones.build(self)
	_build_return_gate()
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
	var alpha := preload("res://scripts/combat/water_alpha.gd").new()
	alpha.name = "WaterAlpha"
	add_child(alpha)
	alpha.build(self, director)
	veilfall = preload("res://scripts/world/water_veilfall.gd").new()
	veilfall.name = "WaterVeilfall"
	add_child(veilfall)
	veilfall.build(self)
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
	if veilfall != null:
		var built: float = veilfall.built_floor_height_at(x, z)
		if is_finite(built):
			return built
	if terrain == null:
		return NAN
	var data: Object = terrain.get("data")
	return float(data.call("get_height", Vector3(x, 0, z))) if data != null else NAN


func ground_height_near(x: Variant, z: float = 0.0, _reference_y: float = 0.0) -> float:
	# Existing realm combat surfaces pass an XYZ point; terrain samplers pass
	# X/Z scalars. Water has one terrain stratum, shared by both callers.
	return ground_height_at(x.x, x.z) if x is Vector3 else ground_height_at(float(x), z)


func water_depth_at(position: Vector3) -> float:
	if veilfall != null and veilfall.contains_interior(position):
		var built: float = veilfall.built_floor_height_at(position.x, position.z)
		if is_finite(built):
			return maxf(0.0, veilfall.interior.position.y - 0.4 - built)
	return maxf(0.0, field.water_level() - field.height_at(position.x, position.z))


func current_at(position: Vector3, liberated: bool = false) -> Vector3:
	if veilfall != null and veilfall.contains_interior(position):
		return Vector3.ZERO
	var restored: bool = get_node("/root/Game").world.flags.has("water_currents_restored")
	return currents.sample(position, liberated or restored).velocity


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


## The Stormwood -> Water key was consumed when the durable Water gate opened.
## Returning through the same connection therefore reads only that WORLD unlock;
## an empty key flag keeps RealmGate out of its unlockable/key-writing branch.
## Game remains the realm router and resolves this authored Stormwood entry id.
func _build_return_gate() -> void:
	var raw: Variant = config.get("entry_anchors", {}).get("return_to_stormwood", {})
	if not raw is Dictionary:
		push_error("Water return connection is missing entry_anchors.return_to_stormwood")
		return
	var spec := raw as Dictionary
	var position_raw: Variant = spec.get("position", [])
	if not position_raw is Array or (position_raw as Array).size() < 3:
		push_error("Water return connection has no authored position")
		return
	var values := position_raw as Array
	var point := Vector3(float(values[0]), float(values[1]), float(values[2]))
	var height := ground_height_at(point.x, point.z)
	if is_finite(height):
		point.y = height
	var destination_entry_id := str(spec.get("peer_anchor_id", ""))
	if destination_entry_id.is_empty():
		push_error("Water return connection has no authored Stormwood peer anchor")
		return
	var gate: Node3D = REALM_GATE.new()
	gate.name = "StormwoodReturnRealmGate"
	gate.origin_realm = "water"
	gate.position = point
	gate.rotation.y = deg_to_rad(float(spec.get("facing_yaw_deg", 0.0)))
	gate.call("setup", "stormwood", destination_entry_id, "Stormwood", "",
		"realm_gate_water_unlocked")
	add_child(gate)
	if not simulation_only:
		var site := FIRST_SHORE_GATE_SITE.new()
		site.name = "FirstShoreGateSite"
		add_child(site)
		site.build(self, point.y)


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
		texture.set("detiling_rotation", float(spec.get("detiling_rotation", 0.25)))
		texture.set("detiling_shift", float(spec.get("detiling_shift", 0.30)))
		texture.set("albedo_color", Color(str(spec.tint)))
		assets.call("set_texture", index, texture)
		index += 1
	terrain.set("assets", assets)
	var material: Object = terrain.get("material")
	# Terrain3D's default FLAT world background sits at sea level outside the
	# baked regions. Water supplies its own horizon surface, so disable that
	# coplanar terrain continuation rather than rendering two competing planes.
	material.set("world_background", int(Terrain3DMaterial.WorldBackground.NONE))
	material.set("show_checkered", false)
	material.set("show_colormap", false)
	material.set("auto_shader", false)


func _stand_up_ground_cover() -> void:
	var profile: Variant = JSON.parse_string(FileAccess.get_file_as_string(GROUND_COVER_PATH))
	if not profile is Dictionary or not bool((profile as Dictionary).get("enabled", false)):
		return
	var texture_names: Array = []
	for spec: Dictionary in _visual.terrain.textures:
		texture_names.append(str(spec.name))
	var camera := local_camera_rig()
	if camera == null:
		push_error("Water ground cover needs the gameplay camera rig")
		return
	var eye := camera.get_node_or_null("Camera3D") as Camera3D
	if eye == null:
		push_error("Water ground cover needs the gameplay Camera3D")
		return
	var cover := GROUND_COVER.new()
	cover.name = "WaterGroundCover"
	cover.configure_profile(profile as Dictionary, texture_names,
			_ground_cover_clearances(profile as Dictionary))
	add_child(cover)
	cover.bind(terrain, eye)


func _ground_cover_clearances(profile: Dictionary = {}) -> PackedVector3Array:
	var out := PackedVector3Array()
	var anchor_radius := float(profile.get("anchor_clear_radius_m", 3.5))
	var camp_radius := float(profile.get("camp_clear_radius_m", 5.0))
	for anchor: Dictionary in config.get("anchors", []):
		var at: Array = anchor.get("safe_position", [])
		# Static vegetation needs a broad approach radius; short ground cover only
		# needs to leave the actual arrival/service footprint readable.
		if at.size() >= 3 and anchor_radius > 0.0:
			out.append(Vector3(float(at[0]), float(at[2]),
					anchor_radius))
	var camps: Variant = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/config/water_camps.json"))
	if camps is Dictionary:
		for camp: Dictionary in (camps as Dictionary).get("camps", []):
			var at: Array = camp.get("at", [])
			if at.size() >= 2:
				out.append(Vector3(float(at[0]), float(at[1]), camp_radius))
	return out

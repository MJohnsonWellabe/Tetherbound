extends Node3D

const REALM_ID := "stormwood"
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")
const VEGETATION := preload("res://scripts/world/vegetation.gd")
const GATE := preload("res://scripts/world/realm_gate.gd")
const SHELL_BUILD := preload("res://scripts/world/shell_build_budget.gd")
const DROPS := preload("res://scripts/world/dropped_item_spawner.gd")
const FALL_RECOVERY := preload("res://scripts/world/fall_recovery.gd")
var simulation_only := false
var shell_realm := ""
var _ready_complete := false
var _field := FIELD.new()
var _config: Dictionary = {}
var _terrain: Node3D
var _map: RefCounted
var _vegetation: Node3D
var _rootgate: StaticBody3D
var _revision := -1

func world_realm() -> String:
	return REALM_ID

func local_rig() -> Node3D:
	return get_node_or_null("Player")

func local_camera_rig() -> Node3D:
	return get_node_or_null("CameraRig")

func shell_build_complete() -> bool:
	return _ready_complete

func config_data() -> Dictionary:
	return _config.duplicate(true)

func ground_height_at(x: float,z: float,_preferred_y: float = NAN) -> float:
	return _field.height_at(x,z)

func ground_height_near(at: Vector3) -> float:
	return ground_height_at(at.x,at.z,at.y)

func entry_anchor(id: String) -> Dictionary:
	for entry: Dictionary in _config.get("transition_points",{}).values():
		if str(entry.id)==id:
			return entry.duplicate(true)
	return {}

func _ready() -> void:
	_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_world.json"))
	var player := local_rig() as CharacterBody3D
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if simulation_only:
		for path: String in ["WorldEnvironment","Sun","PlaygroundHUD"]:
			var node := get_node_or_null(NodePath(path))
			if node != null:
				remove_child(node)
				node.queue_free()
		player.visible = false
		player.collision_layer = 0
		player.collision_mask = 0
		get_node("CameraRig").process_mode = Node.PROCESS_MODE_DISABLED
		get_node("CameraRig/Camera3D").current = false
	var budget := SHELL_BUILD.new()
	budget.call("begin",self,true)
	_terrain = ClassDB.instantiate("Terrain3D")
	_terrain.name = "Terrain"
	_terrain.set("region_size",256)
	_terrain.set("vertex_spacing",2.0)
	add_child(_terrain)
	await get_tree().process_frame
	_terrain.set("data_directory","res://data/terrain/stormwood")
	_terrain.set("collision_mode",3)
	_apply_ground_materials()
	await budget.call("step","terrain")
	_vegetation = VEGETATION.new()
	_vegetation.name = "Vegetation"
	_vegetation.set("realm",REALM_ID)
	_vegetation.set("simulation_only",simulation_only)
	_vegetation.call("configure_realm_scatter",SCATTER.config(),_field,"stormwood",SCATTER.fingerprint())
	add_child(_vegetation)
	await _vegetation.call("build",6144.0,_terrain,budget)
	_vegetation.call("restore_from_game",get_node("/root/Game"))
	_build_landmark_masses()
	_build_return_gate()
	_build_rootgate()
	DROPS.attach(self,REALM_ID)
	if not simulation_only:
		var game := get_node("/root/Game")
		var pending := str(game.call("pending_entry_for",REALM_ID))
		var anchor := entry_anchor(pending)
		if anchor.is_empty():
			anchor = _config.transition_points.cloudreach_entry
		var p: Array = anchor.position
		player.position = Vector3(float(p[0]),ground_height_at(float(p[0]),float(p[2]))+0.3,float(p[2]))
		if pending.is_empty():
			game.call("apply_loaded_player_pose")
		get_node("CameraRig").call("set_target",player)
		get_node("CameraRig").set("yaw",deg_to_rad(float(anchor.get("facing_yaw_deg",180))))
		_map = game.call("bind_realm_map",REALM_ID,player.global_position)
		var recovery := FALL_RECOVERY.new()
		recovery.name = "FallRecovery"
		add_child(recovery)
		recovery.setup(local_rig,-45.0,_config.realm.world_bounds,Callable(),player.position)
		var fly := player.get_node_or_null("FlyController")
		if fly != null:
			fly.call("register_restriction","stormwood_canopy",AABB(Vector3(-2560,-1000,0),Vector3(4608,3000,6144)),"stormwood:canopy_flight_forbidden")
		await get_tree().physics_frame
		await get_tree().physics_frame
		player.process_mode = Node.PROCESS_MODE_INHERIT
		if not pending.is_empty():
			game.call("complete_realm_entry",REALM_ID)
	_ready_complete = true
	add_to_group("progression_restore")
	print("STORMWOOD READY realm=",REALM_ID," shell=",simulation_only," terrain_regions=",_terrain.get("data").call("get_region_count"))

func _process(_delta: float) -> void:
	if not _ready_complete:
		return
	var game := get_node("/root/Game")
	var flags: RefCounted = game.get("progression")
	if int(flags.get("revision")) != _revision:
		restore_progression_from_game(game)

func restore_progression_from_game(game: Node) -> void:
	var flags: RefCounted = game.get("progression")
	_revision = int(flags.get("revision"))
	if _rootgate != null:
		var opened := bool(flags.call("has","stormwood:rootgate_released"))
		_rootgate.visible = not opened
		_rootgate.get_node("CollisionShape3D").set_deferred("disabled",opened)

func map_terrain_texture() -> Texture2D:
	return _map.call("bake_terrain",self) as Texture2D if _map != null else null

func _build_return_gate() -> void:
	var point: Array = _config.transition_points.cloudreach_return.position
	var gate := GATE.new()
	gate.name = "CloudreachReturnRealmGate"
	gate.origin_realm = REALM_ID
	gate.position = Vector3(float(point[0]),ground_height_at(float(point[0]),float(point[2])),float(point[2]))
	gate.call("setup","cloudreach","cloudreach_return_from_stormwood","Cloudreach Cliffs","realm_key_stormwood","realm_gate_stormwood_unlocked")
	add_child(gate)

func _build_rootgate() -> void:
	_rootgate = StaticBody3D.new()
	_rootgate.name = "Rootgate"
	_rootgate.position = Vector3(-650,ground_height_at(-650,3550)+15,3550)
	add_child(_rootgate)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(90,40,15)
	collision.shape = shape
	_rootgate.add_child(collision)
	for i in 6:
		_model(_rootgate,"res://assets/environment/stylized_nature/DeadTree_3.gltf",Vector3(-40+i*16,-15,0),3.8,PI*0.1*i)

func _build_landmark_masses() -> void:
	var base := Vector3(-100,ground_height_at(-100,5470),5470)
	var tree := Node3D.new()
	tree.name = "StormheartTree"
	tree.position = base
	add_child(tree)
	_model(tree,"res://assets/environment/stylized_nature/TwistedTree_2.gltf",Vector3(-24,0,0),8.8,-0.2)
	_model(tree,"res://assets/environment/stylized_nature/TwistedTree_4.gltf",Vector3(24,0,0),8.8,0.5)
	if not simulation_only:
		for y in [25,65,110,155]:
			var light := OmniLight3D.new()
			light.position = Vector3(0,y,0)
			light.light_color = Color("72c6ff")
			light.light_energy = 3
			light.omni_range = 60
			tree.add_child(light)
	var sentinel := Vector3(-320,ground_height_at(-320,240),240)
	_model(self,"res://assets/environment/stylized_nature/DeadTree_1.gltf",sentinel,5.0,0.2)

func _model(parent: Node3D,path: String,at: Vector3,scale_factor: float,yaw: float) -> void:
	if simulation_only:
		return
	var model := (load(path) as PackedScene).instantiate() as Node3D
	model.position = at
	model.scale = Vector3.ONE*scale_factor
	model.rotation.y = yaw
	parent.add_child(model)

func _apply_ground_materials() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	var assets: Object = ClassDB.instantiate("Terrain3DAssets")
	var i := 0
	for entry: Dictionary in source.textures:
		var texture: Object = ClassDB.instantiate("Terrain3DTextureAsset")
		texture.set("id",i)
		texture.set("name",str(entry.name))
		texture.set("albedo_texture",load(str(entry.albedo)))
		texture.set("normal_texture",load(str(entry.normal)))
		texture.set("normal_depth",0.25)
		texture.set("uv_scale",float(entry.get("uv_scale",0.1)))
		texture.set("albedo_color",Color("63887b") if i==0 else Color("737080"))
		assets.call("set_texture",i,texture)
		i += 1
	_terrain.set("assets",assets)
	var material: Object = _terrain.get("material")
	material.set("show_checkered",false)
	material.set("auto_shader",true)

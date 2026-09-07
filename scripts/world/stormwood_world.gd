extends Node3D

const REALM_ID := "stormwood"
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")
const VEGETATION := preload("res://scripts/world/vegetation.gd")
const GATE := preload("res://scripts/world/realm_gate.gd")
const SHELL_BUILD := preload("res://scripts/world/shell_build_budget.gd")
const DROPS := preload("res://scripts/world/dropped_item_spawner.gd")
const FALL_RECOVERY := preload("res://scripts/world/fall_recovery.gd")
const STORMHEART := preload("res://scripts/world/stormheart_tree.gd")
const SETTLEMENTS := preload("res://scripts/world/village.gd")
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
var _build_started_ms := 0

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
	_build_started_ms = Time.get_ticks_msec()
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
	budget.call("begin",self,simulation_only)
	_terrain = ClassDB.instantiate("Terrain3D")
	_terrain.name = "Terrain"
	_terrain.set("region_size",256)
	_terrain.set("vertex_spacing",2.0)
	add_child(_terrain)
	await get_tree().process_frame
	_build_note("terrain attached")
	_terrain.set("data_directory","res://data/terrain/stormwood")
	_build_note("terrain regions loaded")
	_terrain.set("collision_mode",3)
	_build_note("collision configured")
	await _apply_ground_materials(budget)
	_build_note("materials configured")
	await budget.call("step","terrain")
	_build_note("terrain physics settled")
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
	var settlements := SETTLEMENTS.new()
	settlements.name = "RodfolkSettlements"
	settlements.config_path = "res://data/config/stormwood_settlements.json"
	settlements.visible = not simulation_only
	add_child(settlements)
	await settlements.build(budget)
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
	var chapter := preload("res://scripts/world/stormwood_chapter.gd").new()
	chapter.name = "StormwoodChapter"
	add_child(chapter)
	chapter.mount(self)
	var combat := preload("res://scripts/world/stormwood_combat_runtime.gd").new()
	combat.name = "StormwoodCombatRuntime"
	add_child(combat)
	combat.mount(self)
	var pickups := preload("res://scripts/world/stormwood_pickup_runtime.gd").new()
	pickups.name = "StormwoodPickups"
	add_child(pickups)
	pickups.mount(self)
	var camps := preload("res://scripts/world/stormwood_camps.gd").new()
	camps.name = "StormwoodCampsRuntime"
	add_child(camps)
	camps.mount(self)
	if not simulation_only:
		get_node("PlayerDeath").configure_recovery(camps.recovery_camps(self), Callable(self, "ground_height_near"))
	if not simulation_only:
		var look := preload("res://scripts/world/world_look.gd").new()
		look.name = "WorldLook"
		look.sun_path = NodePath("../Sun")
		look.environment_path = NodePath("../WorldEnvironment")
		add_child(look)
	var surge := preload("res://scripts/world/stormwood_surge.gd").new()
	surge.name = "StormwoodSurge"
	add_child(surge)
	var lightning := preload("res://scripts/world/stormwood_lightning.gd").new()
	lightning.name = "StormwoodLightning"
	add_child(lightning)
	var arches := preload("res://scripts/world/stormwood_arch_runtime.gd").new()
	arches.name = "StormglassArches"
	add_child(arches)
	arches.mount(self)
	var harvests := preload("res://scripts/world/stormwood_harvest_runtime.gd").new()
	harvests.name = "StormwoodHarvests"
	add_child(harvests)
	harvests.mount(self)
	var rods := preload("res://scripts/world/stormwood_rod_stations.gd").new()
	rods.name = "StormwoodRodStations"
	add_child(rods)
	rods.mount(self)
	_ready_complete = true
	add_to_group("progression_restore")
	print("STORMWOOD BUILD ",budget.call("summary"))
	print("STORMWOOD READY realm=",REALM_ID," shell=",simulation_only," terrain_regions=",_terrain.get("data").call("get_region_count"))


func _build_note(label: String) -> void:
	print("STORMWOOD BUILD shell=",simulation_only," elapsed_ms=",Time.get_ticks_msec()-_build_started_ms," ",label)

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
	var tree := STORMHEART.new()
	tree.name = "StormheartTree"
	tree.position = base
	tree.simulation_only = simulation_only
	add_child(tree)
	tree.build()
	tree.add_approach(Vector3(-100,ground_height_at(-100,5350)+0.2,5350))
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

func _apply_ground_materials(budget: RefCounted) -> void:
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
		_build_note("texture %d"%i)
		await budget.call("breathe")
	_build_note("assigning terrain assets")
	_terrain.set("assets",assets)
	_build_note("terrain assets assigned")
	await budget.call("breathe")
	var material: Object = _terrain.get("material")
	material.set("show_checkered",false)
	material.set("auto_shader",true)

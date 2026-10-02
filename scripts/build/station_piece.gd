extends Node3D

## Actual F31 scene piece and ordinary prompt. Geometry is authored here;
## durable actions are delegated to the existing authenticated producer.
const RULES := preload("res://scripts/build/station_rules.gd")
const PROMPT := preload("res://scripts/world/interactable.gd")
const PANEL := preload("res://scripts/ui/craft_panel.gd")
const NEXT := preload("res://scripts/build/station_next_upgrade.gd")
const FORGE_PATH := "res://scripts/build/station_forge.gd"
const DEN_PATH := "res://scripts/build/station_den.gd"
var _id := ""
var _cfg: Dictionary
var _ghost := false
var _panel: CanvasLayer
var _prompt: Node3D
var _producer: Node
var _materials: Array[StandardMaterial3D] = []
var _registered := false
var _manual_actor: Node3D
var _poll_left := 0.0

func build(id: String, ghost: bool = false) -> void:
	_id = id
	_ghost = ghost
	_cfg = RULES.config()
	if _cfg.is_empty(): return
	var attachment := RULES.attachment(_cfg,id)
	if not attachment.is_empty():
		if attachment.get("status") != "live" or attachment.get("registered") != true: return
		_build_attachment(attachment)
	else:
		match id:
			"workbench": _table(2.0,1.2); _box(Vector3(1.6,0.18,0.16),Vector3(0,1.2,-0.4),Color("8c6b46"))
			"forge":
				_box(Vector3(1.8,1.4,1.4),Vector3(0,0.7,0),Color("6a6d72"))
				_box(Vector3(0.55,1.4,0.6),Vector3(0.6,2.1,-0.4),Color("81868b"))
				_box(Vector3(0.7,0.5,0.05),Vector3(0,0.7,0.72),Color("242b31"))
				_box(Vector3(0.9,0.16,0.7),Vector3(-0.45,1.48,0.2),Color("a8aeb5"))
			"kitchen":
				_table(2.4,1.4)
				_box(Vector3(2.4,0.16,0.2),Vector3(0,1.9,-0.55),Color("99744c"))
				for x: float in [-1.05,1.05]: _box(Vector3(0.12,1.0,0.12),Vector3(x,1.5,-0.55),Color("99744c"))
				_cylinder(0.33,0.45,Vector3(0,1.28,0),Color("596d78"))
			"altar":
				_cylinder(0.3,1.0,Vector3(0,0.5,0),Color("7a8290"))
				_box(Vector3(0.51,0.15,0.51),Vector3(0,1.08,0),Color("c3b892"))
				_cylinder(0.18,0.23,Vector3(0,1.27,0),Color("85c9c3"))
			"den":
				for x: float in [-2.0,2.0]:
					for z: float in [-1.4,1.4]: _box(Vector3(0.16,2.2,0.16),Vector3(x,1.1,z),Color("785a3c"))
				_box(Vector3(4.4,0.18,3.2),Vector3(0,2.3,0),Color("8b9272"))
				for i: int in 5: _cylinder(0.48,0.15,Vector3(-1.65+i*0.82,0.1,0.65),Color("c5b77c"))
			"farm":
				_box(Vector3(1.4,0.14,1.4),Vector3(0,0.07,0),Color("584430"))
				for x: float in [-0.7,0.7]: _box(Vector3(0.1,0.22,1.4),Vector3(x,0.11,0),Color("90704b"))
				for z: float in [-0.7,0.7]: _box(Vector3(1.4,0.22,0.1),Vector3(0,0.11,z),Color("90704b"))
				for x: float in [-0.4,0.0,0.4]: _box(Vector3(0.12,0.06,1.1),Vector3(x,0.16,0),Color("75604c"))
			"greenhouse":
				_box(Vector3(3.2,0.18,2.6),Vector3(0,0.09,0),Color("77634d"))
				for x: float in [-1.5,1.5]:
					for z: float in [-1.2,1.2]: _box(Vector3(0.12,2.6,0.12),Vector3(x,1.3,z),Color("b4a17b"))
				_box(Vector3(3.2,0.12,2.6),Vector3(0,2.65,0),Color(0.63,0.8,0.77,0.48))
	if not ghost:
		var size: Array = attachment.get("size_m",_cfg.pieces.get(id,{}).get("size_m",[1,1,1]))
		var body := StaticBody3D.new()
		# Layer 2 is selectable by the existing all-layer dismantle ray,
		# while trainer/camera layer-1 masks can walk through these pieces.
		body.collision_layer=2 if id in ["den","farm"] else 1
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(size[0],size[1],size[2])
		collision.shape = shape
		collision.position.y = float(size[1])*0.5
		body.add_child(collision)
		add_child(body)
		set_meta("station_piece",true)
		set_process(_cfg.get("runtime_enabled") == true)
		call_deferred("mount_interaction")

func mount_interaction() -> void:
	if _ghost or not is_inside_tree() or _cfg.get("runtime_enabled") != true \
			or not RULES.station(_cfg,_id) or _prompt != null: return
	var game := get_node_or_null(^"/root/Game")
	if game == null: return
	_producer = game.get("session") as Node
	if _producer == null or not _producer.has_method("homestead_station_available") \
			or not _producer.has_method("_register_homestead_station_node"): return
	_registered=_producer.call("_register_homestead_station_node",source_key(),self) == true
	if not _registered: return
	_prompt = PROMPT.new()
	# The Workbench prompt is the same Craft prompt the legacy bench and the
	# campfire carry, so it keeps that one name; other stations are their own.
	_prompt.name = "CraftInteractable" if _id == "workbench" else "StationInteractable"
	var p: Array = _cfg.pieces[_id].prompt_offset
	_prompt.position = Vector3(p[0],p[1],p[2])
	_prompt.call("configure","Use "+_id.capitalize(),float(_cfg.interaction_radius_m),true)
	_prompt.connect("activated",_open)
	add_child(_prompt)
	_mount_manual_actor()

func _process(delta: float) -> void:
	if _ghost: return
	# The producer's availability read is a full admitted-character check.
	# Poll it at the configured rate and only near the local trainer, so a
	# yard of stations never costs that check every frame.
	_poll_left -= delta
	if _poll_left > 0.0: return
	_poll_left = float(_cfg.get("availability_poll_seconds", 0.25))
	if _prompt == null:
		mount_interaction()
		return
	var game := get_node_or_null(^"/root/Game")
	var trainer: Node3D = game.call("find_player") as Node3D if game != null and game.has_method("find_player") else null
	if trainer != null and trainer.global_position.distance_to(interaction_origin()) \
			> float(_cfg.get("availability_poll_radius_m", 6.0)):
		_prompt.set("actionable",false)
		return
	var available: bool = is_instance_valid(_producer) and _registered \
		and _producer.call("homestead_station_available",source_key()) == true
	_prompt.set("actionable",available)
	_prompt.set("label","Use "+_id.capitalize() if available else _id.capitalize()+" is waiting for its saved transaction")

func _mount_manual_actor() -> void:
	if _manual_actor != null or not is_instance_valid(_producer) or _id not in ["forge","den"]: return
	var world := get_parent() as Node3D
	var path := FORGE_PATH if _id == "forge" else DEN_PATH
	if not ResourceLoader.exists(path): return
	var script: Script = load(path)
	if script == null: return
	if _id == "forge" and (not _producer.has_method("homestead_actor_context") \
		or not _producer.has_method("homestead_commit_refine_unit")): return
	_manual_actor=script.new()
	_manual_actor.name="ManualForge" if _id == "forge" else "ManualDen"
	add_child(_manual_actor)
	# Child origin and basis exactly match the committed paid station root.
	_manual_actor.transform=Transform3D.IDENTITY
	if _id == "den":
		# Groom uses the panel's one authenticated Foundation action. The Den
		# child observes ordinary rest only; no competing grooming callback.
		_manual_actor.call("configure_rest_observer", world, str(get_meta("building_uid", "")))
		return
	_manual_actor.call("configure",world,str(get_meta("building_uid","")),
		Callable(_producer,"homestead_actor_context"),Callable(_producer,"homestead_commit_refine_unit"))

func source_key() -> String:
	return "%s:meadows:%s" % [_id,str(get_meta("building_uid",""))]

func station_id() -> String: return _id

func interaction_origin() -> Vector3:
	var p: Array = _cfg.pieces[_id].prompt_offset
	return to_global(Vector3(p[0],p[1],p[2]))

func interaction_radius() -> float: return float(_cfg.interaction_radius_m)

func _open() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open_station",self)

func next_upgrade(personal: Dictionary) -> Dictionary:
	var game := get_node_or_null(^"/root/Game")
	if game == null: return {}
	var tier := RULES.effective_tier(_cfg,game.get("placed_buildings"),str(get_meta("building_uid","")))
	if tier.get("ok") != true: return {}
	# Compatibility projection for existing strict NEXT helper, derived from
	# this canonical host-world station. No cached/global tier is trusted.
	var world_state: RefCounted = game.get("world")
	var world := {"world_id":str(world_state.get("world_id")),"redesign_world":{"station_tiers":{_id:tier.effective_tier}}} if world_state != null else {}
	var blueprint := {}
	for row: Dictionary in _cfg.attachments:
		if row.station_id == _id and int(row.tier) == int(tier.effective_tier)+1: blueprint=row
	return NEXT.describe(_id,world,personal,blueprint)

func _table(width: float, depth: float) -> void:
	_box(Vector3(width,0.18,depth),Vector3(0,0.95,0),Color("ad8557"))
	for x: float in [-width*0.4,width*0.4]:
		for z: float in [-depth*0.35,depth*0.35]: _box(Vector3(0.15,0.9,0.15),Vector3(x,0.45,z),Color("735637"))

func _build_attachment(def: Dictionary) -> void:
	var palette: Array[Color] = [Color("c5b583"),Color("6fadb2"),Color("a1c4d8"),Color("88a9ba")]
	var color: Color = palette[int(def.tier)-1]
	match def.station_id:
		"forge": _cylinder(0.5,1.1,Vector3(0,0.55,0),color); _box(Vector3(0.85,0.16,0.6),Vector3(0,1.2,0),Color("666f76"))
		"kitchen": _table(1.1,1.1); _box(Vector3(0.8,0.3,0.25),Vector3(0,1.17,-0.3),color)
		"altar": _cylinder(0.35,0.8,Vector3(0,0.4,0),Color("7a8290")); _cylinder(0.42,0.15,Vector3(0,0.88,0),color)
		"den": _cylinder(0.53,0.18,Vector3(0,0.1,0),color); _box(Vector3(0.15,1.1,0.15),Vector3(0,0.65,-0.4),Color("8c7751"))

func _box(size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size=size
	_shape(mesh,at,color)

func _cylinder(radius: float, height: float, at: Vector3, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=16
	_shape(mesh,at,color)

func _shape(mesh: Mesh, at: Vector3, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.86
	if _ghost or color.a < 1.0: material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	var instance := MeshInstance3D.new()
	instance.mesh=mesh
	instance.position=at
	instance.material_override=material
	add_child(instance)
	_materials.append(material)

func tint_ghost(valid: bool) -> void:
	for material: StandardMaterial3D in _materials:
		material.albedo_color=Color(0.28,0.85,0.65,0.45) if valid else Color(0.95,0.4,0.36,0.45)

func _exit_tree() -> void:
	if _registered and is_instance_valid(_producer) and _producer.has_method("_unregister_homestead_station_node"):
		_producer.call("_unregister_homestead_station_node",source_key(),self)
	if is_instance_valid(_panel) and _panel.call("station_source_departed", self) != true: _panel.queue_free()

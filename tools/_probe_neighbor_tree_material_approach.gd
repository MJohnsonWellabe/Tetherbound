extends SceneTree

## Synthetic two-tree native diagnostic. No campaign harvest receipt.
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const VEG := preload("res://scripts/world/vegetation.gd")
const FIELD := preload("res://scripts/world/playground_heightfield.gd")
const PLAYER := preload("res://scenes/player/player.tscn")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const TARGET := Vector3(78.98997,-2.175245,-44.09865)
const START := Vector3(72.02149,-2.080176,-50.99673)
var _player: CharacterBody3D
var _prompts: Array[Node3D] = []
var _arbiter: Node

class CameraBasis extends Node3D:
	func planar_basis() -> Basis: return Basis.IDENTITY

class LocalWorld extends Node3D:
	var field := FIELD.new()
	func ground_height_at(x: float,z: float) -> float: return field.height_at(x,z)

class ObservedMaterial extends "res://tests/helpers/meadows_earned_material_segment.gd":
	var snapshot: Callable
	var wanted: Node3D
	var _win_frames:=0
	var _held:=0
	var _longest_hold:=0
	var _first_win:=Vector3.INF
	func _observe_win() -> void:
		if _arbiter.winning_provider()==wanted:
			_win_frames+=1
			_held+=1
			_longest_hold=maxi(_longest_hold,_held)
			if not _first_win.is_finite(): _first_win=_player.global_position
		else:
			_held=0
	func _walk_to(at: Vector3,tolerance: float,budget: int) -> bool:
		var begin := Engine.get_physics_frames()
		_win_frames=0
		_held=0
		_longest_hold=0
		_first_win=Vector3.INF
		_tree.physics_frame.connect(_observe_win)
		print("NATIVE actual helper walk begin target=",at," tolerance=",tolerance," budget=",budget)
		var reached: bool = await super._walk_to(at,tolerance,budget)
		_tree.physics_frame.disconnect(_observe_win)
		print("NATIVE actual helper walk end reached=",reached," frames=",Engine.get_physics_frames()-begin,
			" resets=",_nav.confined_resets()," target_winning_frames=",_win_frames,
			" longest_target_hold=",_longest_hold," first_target_win=",_first_win," state=",snapshot.call())
		return reached

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var data := {}
	BAKE._read_region(FileAccess.open("res://data/scatter/playground/region_0_-1.bin",FileAccess.READ),data,{})
	var selected: Array[Dictionary] = [{},{}]
	for layer: String in data:
		for record: Dictionary in data[layer]:
			var at: Vector3 = record.placement.position
			var index := -1
			if at.distance_to(TARGET)<0.01: index=0
			elif Vector2(at.x,at.z).distance_to(Vector2(80.4,-43.9))<0.2: index=1
			if index<0: continue
			var placement: Dictionary = record.placement.duplicate(true)
			placement.harvest_layer=layer
			placement.harvest_index=int(record.order)
			placement.harvest_item="wood"
			placement.harvest_amount=3
			selected[index]=placement
	if selected[0].is_empty() or selected[1].is_empty():
		print("FAIL exact target/neighbor absent ",selected)
		quit(1)
		return
	var world := LocalWorld.new()
	root.add_child(world)
	current_scene=world
	var camera := CameraBasis.new()
	camera.name="CameraRig"
	world.add_child(camera)
	_build_floor(world)
	_player=PLAYER.instantiate()
	_player.name="Player"
	_player.camera_rig_path=NodePath("../CameraRig")
	_player.position=START
	_player.position.y=world.ground_height_at(START.x,START.z)+0.2
	world.add_child(_player)
	_arbiter=ARBITER.new()
	_arbiter.name="InteractionArbiter"
	_arbiter.player_path=NodePath("../Player")
	world.add_child(_arbiter)
	var veg:=VEG.new()
	world.add_child(veg)
	veg._field=world.field
	var mine_control:=OS.get_cmdline_user_args().has("--mine-control")
	if mine_control:
		veg.simulation_only=true
		for layer: String in data:
			var count:=0
			for record: Dictionary in data[layer]: count=maxi(count,int(record.order)+1)
			veg._harvest_layer_counts[layer]=count
			veg._harvested[layer]=veg._new_bitset(count)
		var game:=root.get_node("Game")
		for tool: String in ["axe","pickaxe","knife"]:
			game.inventory.add(tool,1)
		game.autofill_hotbar()
		print("SYNTHETIC MINING CONTROL: native local world, prepared tools/hotbar; no campaign receipt claimed")
	# The fresh log already harvested the previous tree at this position.
	# Keep every OTHER local shipped collider; trees alone omit the rock
	# occupying the target's base and do not reproduce this approach.
	for layer_name: String in data:
		for record: Dictionary in data[layer_name]:
			var at: Vector3=record.placement.position
			if Vector2(at.x-TARGET.x,at.z-TARGET.z).length()>12.0: continue
			if at.distance_to(TARGET)<0.01 or Vector2(at.x,at.z).distance_to(Vector2(80.4,-43.9))<0.2: continue
			if at.distance_to(Vector3(73.17308,-1.875435,-51.2081))<0.01: continue
			var config: Dictionary=veg._layer_for(str(record.placement.model))
			if not bool(config.get("collides",false)): continue
			var placement: Dictionary=record.placement.duplicate(true)
			placement.harvest_layer=layer_name
			placement.harvest_index=int(record.order)
			placement.harvest_item=str(config.get("harvest_item",""))
			placement.harvest_amount=int(config.get("harvest_amount",2))
			selected.append(placement)
	for index in selected.size():
		if OS.get_cmdline_user_args().has("--remove-rock714") and str(selected[index].harvest_layer)=="rocks" and int(selected[index].harvest_index)==714:
			print("FIXTURE CONTROL omitting only rocks#714 collider and prompt; NOT earned mining")
			continue
		var placement:=selected[index]
		var layer: Dictionary=veg._layer_for(str(placement.model))
		print("NATIVE exact index=",index," placement=",placement,
			" scaled_radius=",float(layer.collision_radius)*float(placement.scale))
		veg._mesh_ids[str(placement.model)]=0
		if not str(placement.harvest_item).is_empty():
			veg._spawn_harvest_point(placement)
			var point: Node3D=veg._harvest_nodes["%s#%d"%[placement.harvest_layer,placement.harvest_index]]
			var prompt: Node3D=point.get_node("Interactable")
			if not mine_control: prompt.activated.disconnect(point._on_gathered)
			_prompts.append(prompt)
		if mine_control:
			veg._add_collision(str(placement.model),[placement])
			continue
		var collider:=StaticBody3D.new()
		collider.name="TargetTree" if index==0 else ("NeighborTree" if index==1 else "%s_%d"%[placement.harvest_layer,placement.harvest_index])
		world.add_child(collider)
		collider.add_child(veg._make_collision_shape(placement,float(layer.collision_radius)))
	if mine_control: veg.update_collision_streaming(START)
	if mine_control:
		var hud:=preload("res://scenes/ui/playground_hud.tscn").instantiate()
		hud.player_path=NodePath("../Player")
		world.add_child(hud)
	for frame in 30: await physics_frame
	var helper:=ObservedMaterial.new()
	helper._tree=self
	helper._world=world
	helper._game=root.get_node("Game")
	helper._player=_player
	helper._rig=camera
	helper._arbiter=_arbiter
	helper.snapshot=_snapshot
	helper.wanted=_prompts[0]
	if not helper._resolve_move_bindings():
		print("FAIL bindings")
		quit(1)
		return
	helper._nav=helper.NAVIGATOR.new(self,_player,camera,helper._send_stick)
	print("NATIVE INITIAL ",_snapshot())
	if mine_control:
		var mined:=true
		var rocks: Array=[716,718,719] if OS.get_cmdline_user_args().has("--mine-approach") else [716]
		for index: int in rocks:
			var rock: Node3D=veg._harvest_nodes["rocks#%d"%index]
			print("MINE CONTROL ordinary original helper at rocks#",index," ",rock.global_position)
			await helper._walk_to(rock.global_position,1.65,helper._travel_budget(rock.global_position))
			mined=await helper._harvest_node(rock,"stone",false)
			print("MINE STEP index=",index," mined=",mined," stone=",helper._count("stone")," solid=",veg._solid)
			if not mined: break
		if mined and OS.get_cmdline_user_args().has("--mine-approach"):
			print("MINE CONTROL now ORIGINAL trees#892; neighbor trees#889 retained")
			var tree_node: Node3D=veg._harvest_nodes["trees#892"]
			await helper._walk_to(TARGET,1.65,helper._travel_budget(TARGET))
			mined=await helper._harvest_node(tree_node,"wood",false)
			print("MINE ORIGINAL TREE result=",mined," wood=",helper._count("wood")," neighbor_alive=",veg._harvest_nodes.has("trees#889"))
		print("MINE CONTROL RESULT mined=",mined," stone=",helper._count("stone")," solid=",veg._solid,
			" felled=",veg._felled," transcript=",helper.transcript," failures=",helper.failures)
		helper._release_move()
		world.queue_free()
		await process_frame
		quit(0 if mined else 1)
		return
	if OS.get_cmdline_user_args().has("--scan-poses"):
		var candidate:=_scan_grounded_poses(world)
		if candidate.is_empty():
			print("SCAN RESULT no sampled capsule-free target-winning grounded stance")
			world.queue_free()
			await process_frame
			quit(1)
			return
		var reached: bool=await helper._walk_to(candidate.at,0.6,300)
		var pressed: bool=await helper._press_and_confirm(_prompts[0]) if _arbiter.winning_provider()==_prompts[0] else false
		print("SCAN WALK RESULT reached=",reached," pressed=",pressed," candidate=",candidate," actual=",_snapshot())
		world.queue_free()
		await process_frame
		quit(0 if pressed else 1)
		return
	var walk: bool=await helper._walk_to(TARGET,1.65,helper._travel_budget(TARGET))
	var stand: bool=await helper._stand_where_it_wins(_prompts[0],TARGET)
	var pressed: bool=await helper._press_and_confirm(_prompts[0])
	print("NATIVE RESULT initial_walk=",walk," stand=",stand," pressed=",pressed,
		" target_alive=",is_instance_valid(_prompts[0])," neighbor_alive=",is_instance_valid(_prompts[1]),
		" state=",_snapshot()," transcript=",helper.transcript," failures=",helper.failures)
	helper._release_move()
	world.queue_free()
	await process_frame
	quit(0 if pressed else 1)

func _scan_grounded_poses(world: LocalWorld) -> Dictionary:
	# This is a read-only fixture-space search, not more gameplay attempts.
	# Range comes from the actual prompt sphere; the 1-degree / 5-cm lattice
	# is diagnostic resolution, not a new accepted reach or driver ring.
	var space:=world.get_world_3d().direct_space_state
	var floor_body:=world.get_node("CanonicalTerrainPatch") as StaticBody3D
	var collision:=_player.get_node("Collision") as CollisionShape3D
	var capsule:=collision.shape as CapsuleShape3D
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule
	query.margin=_player.safe_margin
	query.collision_mask=_player.collision_mask
	query.exclude=[_player.get_rid(),floor_body.get_rid()]
	var found:Array[Dictionary]=[]
	var tested:=0
	var blocked:=0
	var in_range:=0
	for degrees in 360:
		var angle:=deg_to_rad(float(degrees))
		var r:=capsule.radius
		while r<=float(_prompts[0].radius):
			var at:=TARGET+Vector3(cos(angle),0,sin(angle))*r
			at.y=world.ground_height_at(at.x,at.z)+_player.safe_margin
			r+=0.05
			if at.distance_to(_prompts[0].global_position)>float(_prompts[0].radius): continue
			in_range+=1
			query.transform=Transform3D(collision.global_basis,at+collision.position)
			tested+=1
			if not space.intersect_shape(query,32).is_empty():
				blocked+=1
				continue
			var offers:=[]
			for prompt: Node3D in _prompts: offers.append(prompt.interaction_offer(at))
			var choice:=preload("res://scripts/world/prompt_arbiter.gd").choose_index(offers)
			if choice!=0: continue
			var margin:=INF
			for index in range(1,offers.size()):
				if not offers[index].is_empty(): margin=minf(margin,float(offers[index].distance)-float(offers[0].distance))
			found.append({"at":at,"target_distance":offers[0].distance,"winning_margin":margin})
	found.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.winning_margin)>float(b.winning_margin))
	print("SCAN actual capsule radius=",capsule.radius," height=",capsule.height," safe_margin=",_player.safe_margin,
		" prompt_radius=",_prompts[0].radius," within_sphere=",in_range," tested=",tested,
		" occupied=",blocked," target_winning_free=",found.size()," best=",found.slice(0,5))
	return found[0] if not found.is_empty() else {}

func _snapshot() -> Dictionary:
	var candidates:=[]
	for prompt: Node3D in _prompts:
		if not is_instance_valid(prompt): continue
		candidates.append({"at":prompt.global_position,"distance":_player.global_position.distance_to(prompt.global_position),
			"offer":prompt.interaction_offer(_player.global_position),"los":prompt._has_line_of_sight(_player.global_position)})
	var contacts:=[]
	for index in _player.get_slide_collision_count():
		var hit:=_player.get_slide_collision(index)
		contacts.append({"body":str(hit.get_collider().name),"normal":hit.get_normal()})
	return {"player":_player.global_position,"grounded":_player.is_on_floor(),"prompts":candidates,
		"winner":_arbiter.winner(),"winner_index":_prompts.find(_arbiter.winning_provider()),
		"contacts":contacts,"unsticks":_player.get("_unstick_count")}

func _build_floor(world: LocalWorld) -> void:
	var faces:=PackedVector3Array()
	for x in range(-12,12):
		for z in range(-12,12):
			var points:Array[Vector3]=[]
			for offset in [Vector2(x,z),Vector2(x+1,z),Vector2(x,z+1),Vector2(x+1,z+1)]:
				var at:=Vector3(TARGET.x+offset.x,0,TARGET.z+offset.y)
				at.y=world.ground_height_at(at.x,at.z)
				points.append(at)
			for index in [0,1,2,1,3,2]: faces.append(points[index])
	var body:=StaticBody3D.new()
	body.name="CanonicalTerrainPatch"
	var shape:=ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision:=CollisionShape3D.new()
	collision.shape=shape
	body.add_child(collision)
	world.add_child(body)

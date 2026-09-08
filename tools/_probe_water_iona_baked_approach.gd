extends SceneTree

## Diagnostic only: reads two shipped height maps, builds a small collision
## patch, drives the real Player. No full Water world, save load, progression,
## grants, terrain/cache writes or milestone acceptance.
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const MIN_X := 677
const MIN_Z := 1521
const WIDTH := 50
const DEPTH := 50
var maps: Dictionary = {}

class CameraBasis extends Node3D:
	func planar_basis() -> Basis:
		return Basis.IDENTITY

func _initialize() -> void:
	_run.call_deferred()

func _height(x: int, z: int) -> float:
	var location := Vector2i(floori(float(x) / 512.0), floori(float(z) / 512.0))
	if not maps.has(location):
		var path := "res://data/terrain/water/terrain3d_%02d_%02d.res" % [location.x, location.y]
		var region: Resource = load(path)
		maps[location] = region.get("height_map") as Image
		print("READ existing region ", path, " location=", region.get("location"))
	return (maps[location] as Image).get_pixel(posmod(x, 512), posmod(z, 512)).r

func _sample(point: Vector2) -> float:
	var x := floori(point.x)
	var z := floori(point.y)
	return lerpf(lerpf(_height(x,z), _height(x+1,z), point.x-x),
		lerpf(_height(x,z+1), _height(x+1,z+1), point.x-x), point.y-z)

func _run() -> void:
	var from := Vector2(703.540405273438, 1541.11340332031)
	var iona := Vector2(691,1553)
	var target := Vector2(693.5,1553)
	print("BAKED heights saved_xz=", _sample(from), " Iona=", _sample(iona), " stance=", _sample(target))
	var steepest := 0.0
	for step in 21:
		var point := from.lerp(target, float(step)/20.0)
		var gradient := Vector2((_sample(point+Vector2(0.25,0))-_sample(point-Vector2(0.25,0)))/0.5,
			(_sample(point+Vector2(0,0.25))-_sample(point-Vector2(0,0.25)))/0.5)
		var slope := rad_to_deg(atan(gradient.length()))
		steepest = maxf(steepest, slope)
		print("BAKED point=",point," height=",_sample(point)," slope=",slope)
	print("BAKED steepest sampled slope=", steepest)
	var world := Node3D.new()
	world.name = "IonaDiagnosticPatch"
	root.add_child(world)
	var rig := CameraBasis.new()
	rig.name = "CameraRig"
	world.add_child(rig)
	var floor_body := StaticBody3D.new()
	floor_body.name = "ShippedHeightPatch"
	var shape := HeightMapShape3D.new()
	shape.map_width = WIDTH
	shape.map_depth = DEPTH
	var data := PackedFloat32Array()
	for z in DEPTH:
		for x in WIDTH:
			data.append(_height(MIN_X+x, MIN_Z+z))
	shape.map_data = data
	var collision := CollisionShape3D.new()
	collision.shape = shape
	floor_body.add_child(collision)
	world.add_child(floor_body)
	floor_body.position = Vector3(MIN_X+(WIDTH-1)*0.5, 0, MIN_Z+(DEPTH-1)*0.5)
	if OS.get_cmdline_user_args().has("--placed-only"):
		var passed := await _placed_case(world, rig, from)
		world.queue_free()
		await process_frame
		quit(0 if passed else 1)
		return
	# Source-equivalent NPC capsule; no conversation or progression service.
	var npc := StaticBody3D.new()
	npc.name = "IonaSourceCapsule"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	var npc_collision := CollisionShape3D.new()
	npc_collision.shape = capsule
	npc_collision.position.y = 0.9
	npc.add_child(npc_collision)
	world.add_child(npc)
	npc.position = Vector3(iona.x,_sample(iona),iona.y)
	if not OS.get_cmdline_user_args().has("--control-only"):
		await _walk_case(world, rig, from, target, "Iona original stance")
	# Exact authored-road projection, not a point merely near the road.
	var road_a := Vector2(601.574,1389.434)
	var road_b := Vector2(793.952,1664.177)
	var t := (1550.0-road_a.y)/(road_b.y-road_a.y)
	var control := road_a.lerp(road_b,t)
	var proposed_npc := control-Vector2(2.5,0)
	print("PROPOSED Iona xz=",proposed_npc," baked_height=",_sample(proposed_npc),
		" first_stance=",control," stance_height=",_sample(control))
	await _walk_case(world, rig, from, control, "authored road center positive control")
	world.queue_free()
	await process_frame
	quit(0)

func _walk_case(world: Node3D, rig: Node3D, from: Vector2, target: Vector2, label: String) -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as CharacterBody3D
	player.camera_rig_path = NodePath("../CameraRig")
	world.add_child(player)
	player.position = Vector3(from.x, _sample(from)+0.1, from.y)
	for frame in 30:
		await physics_frame
	var start := player.global_position
	var destination := Vector3(target.x,_sample(target)+0.1,target.y)
	var nav := NAV.new(self,player,rig,_stick)
	var arrived: bool = await nav.walk_to(destination,1200,1.0)
	_stick(0,0)
	var contacts := []
	for index in player.get_slide_collision_count():
		var hit := player.get_slide_collision(index)
		contacts.append({"body":str(hit.get_collider().name),"normal":str(hit.get_normal())})
	print("PHYSICAL ",label," arrived=",arrived," start=",start," end=",player.global_position,
		" target=",destination," grounded=",player.is_on_floor()," floor_limit=",rad_to_deg(player.floor_max_angle),
		" confined_resets=",nav.confined_resets()," contacts=",contacts)
	player.queue_free()
	await process_frame

func _stick(x: float, z: float) -> void:
	for action in ["move_left","move_right","move_forward","move_back"]:
		Input.action_release(action)
	if x<0: Input.action_press("move_left",-x)
	if x>0: Input.action_press("move_right",x)
	if z<0: Input.action_press("move_forward",-z)
	if z>0: Input.action_press("move_back",z)

func _placed_case(world: Node3D, rig: Node3D, from: Vector2) -> bool:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as CharacterBody3D
	player.camera_rig_path = NodePath("../CameraRig")
	world.add_child(player)
	player.position = Vector3(from.x,_sample(from)+0.1,from.y)
	var arbiter := preload("res://scripts/world/interaction_arbiter.gd").new()
	arbiter.name = "InteractionArbiter"
	arbiter.player_path = NodePath("../Player")
	world.add_child(arbiter)
	var cast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	var spec: Dictionary = {}
	for row: Dictionary in cast.npcs:
		if row.id == "water_iona": spec = row
	if spec.is_empty(): return false
	var npc := preload("res://scripts/npc/npc_body.gd").new()
	npc.name = "water_iona"
	world.add_child(npc)
	var model: Dictionary = preload("res://scripts/characters/character_model.gd").config_for(str(spec.body_profile))
	if not npc.setup_from_config(model,player): return false
	var point := Vector2(700+float(spec.island_local_offset[0]),1530+float(spec.island_local_offset[2]))
	npc.position = Vector3(point.x,_sample(point),point.y)
	var prompt: Node3D = npc.add_prompt("Greet " + str(spec.display_name))
	var receipt := {"activated":false}
	prompt.activated.connect(func() -> void: receipt.activated=true)
	for frame in 30: await physics_frame
	var target := npc.position+Vector3(2.5,0,0)
	target.y = _sample(Vector2(target.x,target.z))+0.1
	var nav := NAV.new(self,player,rig,_stick)
	var arrived: bool = await nav.walk_to(target,1200,1.0)
	_stick(0,0)
	for frame in 8: await physics_frame
	var won: bool = arbiter.winning_provider()==prompt
	if won:
		Input.action_press("interact")
		for frame in 3: await process_frame
		Input.action_release("interact")
		for frame in 5: await process_frame
	var npc_shape := npc.get_node("Body").get_child(0) as CollisionShape3D
	print("PLACED actualIona=",npc.global_position," height=",npc.height()," capsule_radius=",npc_shape.shape.radius,
		" prompt_radius=",prompt.radius," target=",target," player=",player.global_position,
		" arrived=",arrived," exact_provider=",won," actual_interact=",receipt.activated)
	return arrived and won and bool(receipt.activated)

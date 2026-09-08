extends SceneTree

## One strict geometry-only execution of the actual Waterward descent helper.
## Initial core pose is an explicit fixture matching its post-offer stance,
## NOT a campaign arrival. No terrain, campaign grants or saved-game loading.
const TREE := preload("res://scripts/world/stormheart_tree.gd")
const PLAYER := preload("res://scenes/player/player.tscn")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const HELPER := preload("res://tests/helpers/stormwood_earned_waterward_handoff.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")

class GeometryWorld extends Node3D:
	var field := FIELD.new()
	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x,z)

class CameraBasis extends Node3D:
	var yaw := 0.0
	var pitch := 0.0
	func planar_basis() -> Basis: return Basis.IDENTITY

class NoCombat extends Node:
	func is_fighting() -> bool: return false
	func trainer_battle_active() -> bool: return false

var _observed_player: CharacterBody3D
var _observe_from := 0
var _first_wall: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var world := GeometryWorld.new()
	world.name = "WaterwardDescentGeometryFixture"
	root.add_child(world)
	var rig := CameraBasis.new()
	rig.name = "CameraRig"
	world.add_child(rig)
	var trunk := TREE.new()
	trunk.name = "StormheartTree"
	trunk.simulation_only = true
	trunk.position = Vector3(-100,world.ground_height_at(-100,5470),5470)
	world.add_child(trunk)
	trunk.build()
	var foot := Vector3(-100,world.ground_height_at(-100,5350)+0.2,5350)
	trunk.add_approach(foot)
	var player := PLAYER.instantiate() as CharacterBody3D
	player.camera_rig_path = NodePath("../CameraRig")
	world.add_child(player)
	# Ending offer is local Z10.5, handoff's preferred stance adds Z2.
	# Its underlying physical core deck is local Y150.
	player.position = trunk.to_global(Vector3(0,150.2,12.5))
	for frame in 30: await physics_frame
	var capsule := (player.get_node("Collision") as CollisionShape3D).shape as CapsuleShape3D
	print("FIXTURE post-offer core stance player=",player.global_position,
		" floor=",player.is_on_floor()," capsule_radius=",capsule.radius," capsule_height=",capsule.height,
		" floor_limit=",rad_to_deg(player.floor_max_angle)," foot=",foot," contacts=",_contacts(player))
	if not player.is_on_floor():
		print("FAIL: initial actual core deck support absent")
		quit(1)
		return
	var no_combat := NoCombat.new()
	world.add_child(no_combat)
	var helper := HELPER.new()
	helper._tree = self
	helper._world = world
	helper._player = player
	helper._camera = rig
	helper._manager = no_combat
	helper._director = no_combat
	helper._navigator = NAV.new(self,player,rig,helper._drive_stick)
	_observed_player = player
	_observe_from = Engine.get_physics_frames()
	physics_frame.connect(_observe)
	var began_ms := Time.get_ticks_msec()
	var scale_before := Engine.time_scale
	var hz_before := Engine.physics_ticks_per_second
	var passed: bool = await helper._descend_core()
	physics_frame.disconnect(_observe)
	var arrived := player.is_on_floor() and player.global_position.distance_to(foot) < HELPER.CORE_TOLERANCE
	var restored := Engine.time_scale == scale_before and Engine.physics_ticks_per_second == hz_before
	print("RESULT actual helper descent passed=",passed," grounded_foot=",arrived,
		" elapsed_ms=",Time.get_ticks_msec()-began_ms," observed_frames=",Engine.get_physics_frames()-_observe_from,
		" player=",player.global_position," foot_distance=",player.global_position.distance_to(foot),
		" first_wall=",_first_wall," final_contacts=",_contacts(player),
		" unstick_count=",player.get("_unstick_count")," clock_restored=",restored," failures=",helper.failures)
	world.queue_free()
	await process_frame
	quit(0 if passed and arrived and restored and helper.failures.is_empty() else 1)

func _contacts(player: CharacterBody3D) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for index in player.get_slide_collision_count():
		var hit := player.get_slide_collision(index)
		var collider := hit.get_collider() as Node
		rows.append({"body":str(collider.name) if collider != null else "<none>","normal":hit.get_normal()})
	return rows

func _observe() -> void:
	if not is_instance_valid(_observed_player): return
	var frame := Engine.get_physics_frames()-_observe_from
	var contacts := _contacts(_observed_player)
	if _first_wall.is_empty():
		for row: Dictionary in contacts:
			if absf((row.normal as Vector3).y) < 0.5:
				_first_wall = {"frame":frame,"player":_observed_player.global_position,"contact":row}
				print("FIRST WALL ",_first_wall)
				break
	if frame % 450 == 0:
		print("DESCENT frame=",frame," player=",_observed_player.global_position,
			" grounded=",_observed_player.is_on_floor()," contacts=",contacts)

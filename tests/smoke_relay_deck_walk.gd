extends SceneTree

## Native collision regression, not an earned chapter claim. One initial
## fixture pose before the authored ramp; every subsequent move is controller
## input through the production player. Builds only actual decks/ramps and a
## small sampled heightfield patch, without loading the full playground.
const RELAY := preload("res://scripts/world/tether_relay.gd")
const WORKS := preload("res://scripts/world/severed_spokes.gd")
const FIELD := preload("res://scripts/world/playground_heightfield.gd")
const PLAYER := preload("res://scripts/player/player_controller.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")

class Ground extends Node3D:
	var field := FIELD.new()
	func ground_height_at(x: float,z: float) -> float:
		return field.height_at(x,z)

class Rig extends Node3D:
	func planar_basis() -> Basis:
		return Basis.IDENTITY

class Walker extends PLAYER:
	func _ready() -> void:
		_load_config()
		_camera_rig = get_parent().get_node("CameraRig")

var walker: CharacterBody3D
var world: Node3D
var rig: Node3D
var relay: Node3D

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	world = Ground.new()
	root.add_child(world)
	rig = Rig.new()
	rig.name = "CameraRig"
	world.add_child(rig)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/tether_relay.json"))
	relay = RELAY.new()
	world.add_child(relay)
	relay._config = config
	relay._world = world
	relay._centre = Vector2(config.site.centre[0],config.site.centre[1])
	relay._u = Vector2(0.565,-0.826).normalized()
	relay._p = Vector2(-relay._u.y,relay._u.x)
	relay._works = WORKS.new()
	relay.add_child(relay._works)
	relay._build_decks()
	relay._build_ramps()
	var decks: Node3D = relay.get_node("Decks")
	for body in decks.get_children():
		if not body is StaticBody3D:
			continue
		var shape: BoxShape3D = body.get_child(0).shape
		var centre: Vector2 = relay.local_of(Vector2(body.global_position.x,body.global_position.z))
		if absf(body.global_position.y -9.8)<0.01:
			var corners:=[]
			for x in [-1,1]:
				for z in [-1,1]:
					var p:Vector3=body.global_transform * Vector3(x*shape.size.x/2,0,z*shape.size.z/2)
					corners.append(relay.local_of(Vector2(p.x,p.z)))
			print("ACTUAL DECK ",centre," corners=",corners)
	var terrain := StaticBody3D.new()
	world.add_child(terrain)
	terrain.position = Vector3(350,0,3760)
	terrain.scale = Vector3(2,1,2)
	var height:=HeightMapShape3D.new()
	height.map_width=41
	height.map_depth=41
	var values:=PackedFloat32Array()
	for z in range(3720,3801,2):
		for x in range(310,391,2):
			values.append(world.ground_height_at(x,z))
	height.map_data=values
	var shape:=CollisionShape3D.new()
	shape.shape=height
	terrain.add_child(shape)
	var ramp:Dictionary=config.ramps[0]
	var foot_local:=Vector2(ramp.from[0],ramp.from[1])
	var head_local:=Vector2(ramp.to[0],ramp.to[1])
	var before:Vector2=relay.world_of(foot_local+(foot_local-head_local).normalized()*2)
	walker=Walker.new()
	walker.name="Player"
	walker.floor_max_angle=0.7854
	walker.floor_snap_length=0.4
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.4
	capsule.height=1.8
	var collision:=CollisionShape3D.new()
	collision.shape=capsule
	collision.position.y=0.9
	walker.add_child(collision)
	world.add_child(walker)
	walker.position=Vector3(before.x,world.ground_height_at(before.x,before.y)+0.1,before.y)
	for frame in 30:
		await physics_frame
	var nav:=NAV.new(self,walker,rig,_stick)
	var route:Array[Vector3]=[]
	var foot:Vector2=relay.world_of(foot_local)
	route.append(Vector3(foot.x,world.ground_height_at(foot.x,foot.y),foot.y))
	for at:Vector2 in [head_local,Vector2(-2,-11),Vector2(2,-11),Vector2(3,-11)]:
		var pos:Vector2=relay.world_of(at)
		route.append(Vector3(pos.x,10,pos.y))
	var passed:=true
	for leg in route.size():
		nav.reset()
		var reached:=false
		var low:=INF
		for frame in 600:
			low=minf(low,walker.global_position.y)
			if walker.global_position.distance_to(route[leg])<=0.6 and walker.is_on_floor():
				reached=true
				print("REACHED leg=",leg," frame=",frame," player=",walker.global_position," low=",low)
				break
			nav.step(route[leg])
			await physics_frame
		_stick(0,0)
		if not reached or (leg>=2 and low<9.4):
			print("FAIL leg=",leg," player=",walker.global_position," target=",route[leg]," low=",low," reached=",reached)
			passed=false
			break
	print("RELAY DECK CONTINUOUS INPUT ",passed)
	world.queue_free()
	quit(0 if passed else 1)

func _stick(x:float,z:float)->void:
	for pair in [[JOY_AXIS_LEFT_X,x],[JOY_AXIS_LEFT_Y,z]]:
		var e:=InputEventJoypadMotion.new()
		e.device=0
		e.axis=pair[0]
		e.axis_value=pair[1]
		Input.parse_input_event(e)

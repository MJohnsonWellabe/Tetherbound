extends Node3D

## Optional arrival-road observations. These do not dispatch story events,
## create objectives, grant rewards or alter the authored progression order.
const PROMPT := preload("res://scripts/world/interactable.gd")
var _description := ""


func build(world: Node3D, data: Dictionary) -> void:
	var raw: Array=data.get("ruin_position",[-40,117.5,-110])
	var at:=Vector3(raw[0],raw[1],raw[2])
	var ground:=float(world.call("ground_height_near",at))
	if is_nan(ground) or absf(ground-at.y)>4.0:
		push_error("Arrival observation has no supporting road")
		return
	global_position=Vector3(at.x,ground,at.z)
	_description=str(data.get("description","The weathered masonry overlooks the sheltered road toward Galefoot Waycamp."))
	world.call("_place_local_prop",self,"rock",Vector3(-2.0,-0.12,0.8),1.6,32.0)
	world.call("_place_local_prop",self,"rock_low",Vector3(-2.6,-0.12,-0.5),0.8,-12.0)
	world.call("_place_local_prop",self,"flowers",Vector3(-2.5,0.03,1.8),0.5,20.0)
	var ruin:=MeshInstance3D.new()
	ruin.name="WeatheredRouteMasonry"
	ruin.mesh=preload("res://assets/buildings/quaternius_castle/TallWallBricks.obj")
	var bounds:=ruin.mesh.get_aabb()
	var factor:=1.9/maxf(bounds.size.y,0.01)
	ruin.scale=Vector3.ONE*factor
	ruin.position=Vector3(-1.8,0,0)-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
	ruin.material_override=(world.get("_materials") as Dictionary).stone
	add_child(ruin)
	var prompt:=PROMPT.new()
	prompt.name="InspectArrivalRuin"
	prompt.position=Vector3(-0.5,1.0,0)
	prompt.configure("Inspect the weathered route marker",4.2,true)
	prompt.activated.connect(_inspect)
	add_child(prompt)


func _inspect() -> void:
	var game:=get_node("/root/Game")
	if str(game.get("current_realm"))=="cloudreach":
		game.call("push_world_message",_description)

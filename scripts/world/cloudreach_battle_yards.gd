extends Node3D

## Small route-connected clearings. They provide room for production creature
## staging without placing trainers in cottage entrances or the walking lane.
const DATA_PATH:="res://data/config/cloudreach_scene_runtime.json"
var trainer_positions: Dictionary={}


func build(world: Node3D) -> void:
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	var materials: Dictionary=world.get("_materials")
	var radius:=float(config.get("yard_radius_m",16.5))
	for spec: Dictionary in config.get("battle_yards",[]):
		var raw: Array=spec.road_position
		var road: Vector3=world.call("_resource_position",Vector3(raw[0],raw[1],raw[2]))
		var axis: Array=spec.outward
		var outward:=Vector3(axis[0],0,axis[2]).normalized()
		var centre:=road+outward*float(config.get("yard_offset_m",25.0))+Vector3.UP*0.06
		var yard:=Node3D.new()
		yard.name=str(spec.id)+"_yard"
		yard.position=centre
		add_child(yard)
		world.call("_mesa",yard,"RootedClearingShoulder",Vector3(0,-14,0),Vector3(radius*2.5,28,radius*2.5),materials.cliff,materials.upland,false,absi(str(spec.id).hash()))
		var floor_mesh:=world.call("_cylinder",yard,"ClearBattleFloor",Vector3(0,-0.4,0),radius,0.8,materials.upland) as MeshInstance3D
		floor_mesh.material_override=preload("res://scripts/world/cloudreach_environment_materials.gd").worn_ground(centre,radius)
		var body:=StaticBody3D.new()
		var shape:=CollisionShape3D.new()
		var cylinder:=CylinderShape3D.new()
		cylinder.radius=radius
		cylinder.height=0.8
		shape.shape=cylinder
		body.add_child(shape)
		floor_mesh.add_child(body)
		world.call("register_runtime_surface",{"kind":"ellipse","centre":Vector2(centre.x,centre.z),"half":Vector2.ONE*radius,"height":centre.y})
		var entry:=centre-outward*(radius-2.0)
		world.call("_segment_box",self,str(spec.id)+"_yard_entry",road,entry,5.0,0.45,materials.upland,true)
		world.call("_path_ribbon",self,str(spec.id)+"_worn_entry",road,centre,4.5,absi(str(spec.id).hash()))
		world.call("register_runtime_surface",{"kind":"segment","a":road,"b":entry,"half_width":2.5})
		(world.get("_cover_exclusions") as Array).append({"kind":"ellipse","centre":centre,"half":Vector2.ONE*14.0,"rotation":0.0})
		(world.get("_cover_patches") as Array).append({"kind":"ellipse","centre":centre,"half":Vector2.ONE*18.0,"inner_clear_fraction":0.79,"seed":absi(str(spec.id).hash()),"dry":false})
		for rim_index in 7:
			var angle:=float(rim_index)*TAU/7.0+0.3
			var rim:=Vector3(cos(angle),0,sin(angle))
			if rim.dot(-outward)>0.45:
				continue
			world.call("_place_local_prop",yard,"rock_low",rim*15.8+Vector3(0,-0.13,0),0.65+0.15*(rim_index%2),rad_to_deg(angle))
			world.call("_place_local_prop",yard,"flowers",rim*15.0,0.52,rad_to_deg(angle)+31.0)
			if rim_index%2==0:
				world.call("_place_local_prop",yard,"fence",rim*16.0,0.95,rad_to_deg(angle))
		# Existing landing trees must frame, not visually plug, the new entrance.
		# Retain their installed assets/counts and root them on the supported rim.
		var relocated:=0
		for tree: Node3D in world.find_children("LandingTree*","Node3D",true,false):
			var tree_at:=Vector2(tree.global_position.x,tree.global_position.z)
			var closest:=Geometry2D.get_closest_point_to_segment(tree_at,Vector2(road.x,road.z),Vector2(centre.x,centre.z))
			if tree_at.distance_to(closest)>4.0 and tree_at.distance_to(Vector2(centre.x,centre.z))>14.0:
				continue
			var tangent:=Vector3(outward.z,0,-outward.x)
			tree.global_position=centre+tangent*(radius-1.0)*(1.0 if relocated%2==0 else -1.0)-Vector3.UP*0.12
			relocated+=1
		# Visible equipment remains outside the clear 28m fighting diameter.
		world.call("_place_local_prop",yard,"crate",outward*15.2+Vector3(0,0.02,0),0.75,25.0)
		world.call("_place_local_prop",yard,"barrel",-outward*2.0+Vector3(outward.z,0,-outward.x)*15.0,0.95,8.0)
		trainer_positions[str(spec.id)]=centre+outward*3.0
		yard.set_meta("clear_radius_m",float(config.get("yard_clear_radius_m",14.0)))
		yard.set_meta("road_entry",road)

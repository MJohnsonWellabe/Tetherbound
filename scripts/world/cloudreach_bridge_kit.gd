extends RefCounted

## Existing village floor modules retain authored UVs/materials at a 2m pitch.
## Collision remains the separately tested continuous deck owned by the world.
const FLOOR:=preload("res://assets/buildings/quaternius_medieval/Floor_WoodDark.gltf")
const BOUNDS:=preload("res://scripts/world/building_prefabs.gd")

static func build_deck(parent: Node3D, a: Vector3, b: Vector3, width: float) -> void:
	var source:=FLOOR.instantiate() as Node3D
	var bounds: AABB=BOUNDS.new().combined_aabb(source)
	var parts: Array[Dictionary]=[]
	_collect(source,Transform3D.IDENTITY,parts)
	var along:=maxi(1,ceili(a.distance_to(b)/2.0))
	var across:=maxi(1,ceili(width/2.0))
	var forward:=(b-a).normalized()
	var right:=Vector3.UP.cross(forward).normalized()
	var up:=forward.cross(right).normalized()
	var deck_basis:=Basis(right,up,forward)
	var module_scale:=Vector3(width/across/bounds.size.x,1.0,a.distance_to(b)/along/bounds.size.z)
	var centred:=Transform3D(Basis.IDENTITY,-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z))
	for part: Dictionary in parts:
		var multimesh:=MultiMesh.new()
		multimesh.transform_format=MultiMesh.TRANSFORM_3D
		multimesh.mesh=part.mesh
		multimesh.instance_count=along*across
		var index:=0
		for row in along:
			for column in across:
				var at:=a.lerp(b,(float(row)+0.5)/along)+right*((float(column)+0.5)*width/across-width*0.5)+up*0.025
				multimesh.set_instance_transform(index,Transform3D(deck_basis,at)*Transform3D(Basis.from_scale(module_scale),Vector3.ZERO)*centred*part.transform)
				index+=1
		var batch:=MultiMeshInstance3D.new()
		batch.name="VillageTimberDeckModules"
		batch.multimesh=multimesh
		parent.add_child(batch)
	source.free()

static func _collect(node: Node, pose: Transform3D, parts: Array[Dictionary]) -> void:
	if node is Node3D:
		pose=pose*(node as Node3D).transform
	if node is MeshInstance3D:
		parts.append({"mesh":(node as MeshInstance3D).mesh,"transform":pose})
	for child in node.get_children():
		_collect(child,pose,parts)

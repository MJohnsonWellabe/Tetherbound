extends Node3D

## The board's split tree, Outer Works and hollow-trunk ascent. Static realm
## geometry is identical in the host shell and client scene; only art is omitted
## from the shell. This foundation does not award victories or chapter flags.
const CORE_HEIGHT := 150.0
const RAMP_RADIUS := 26.0
const RAMP_WIDTH := 8.0
const RAMP_TURNS := 4.0
const RAMP_SEGMENTS := 384
var simulation_only := false
var _wood: StandardMaterial3D
var _metal: StandardMaterial3D

func build() -> void:
	_wood = StandardMaterial3D.new()
	_wood.albedo_color = Color("927448")
	_wood.albedo_texture = load("res://assets/environment/stylized_nature/Bark_TwistedTree.png")
	_wood.uv1_scale = Vector3(0.35,0.35,1)
	_wood.roughness = 0.88
	_wood.cull_mode = BaseMaterial3D.CULL_DISABLED
	_metal = StandardMaterial3D.new()
	_metal.albedo_color = Color("3d4752")
	_metal.metallic = 0.65
	_metal.roughness = 0.55
	_ring("OuterWorks",18,44,6)
	_ring("DynamoCore",9,44,CORE_HEIGHT)
	_ring("CrownChamber",7,18,CORE_HEIGHT+24)
	_ascent()
	_ramp("CoreLanding",ascent_point(1)-Vector3.RIGHT*0.8,ascent_point(1)+Vector3.RIGHT*4,8)
	# The upper chamber is reached from the arena along the inside east trunk.
	_ramp("CrownStair",Vector3(34,CORE_HEIGHT,0),Vector3(-16,CORE_HEIGHT+24,0),6)
	if simulation_only:
		return
	_fit_tree("LeftSplitTrunk","DeadTree_3.gltf",Vector3(-33,0,8),232,-0.55)
	_fit_tree("RightSplitTrunk","DeadTree_3.gltf",Vector3(33,0,8),250,2.65)
	_fit_tree("LeftCrown","TwistedTree_2.gltf",Vector3(-45,75,15),170,-0.3)
	_fit_tree("RightCrown","TwistedTree_4.gltf",Vector3(45,85,20),175,0.7)
	_energy_seam()

func core_anchor() -> Vector3:
	return global_position+Vector3(0,CORE_HEIGHT+0.2,-25)

func add_approach(start: Vector3) -> void:
	_ramp("OuterWorksApproach",to_local(start),Vector3(0,6,-40),10)

func ascent_point(fraction: float) -> Vector3:
	var t := clampf(fraction,0,1)
	var angle := -PI*0.5+t*TAU*RAMP_TURNS
	return Vector3(cos(angle)*RAMP_RADIUS,lerpf(6,CORE_HEIGHT,t),sin(angle)*RAMP_RADIUS)

func _ring(id: String,inner: float,outer: float,height: float) -> void:
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	for i in 64:
		# Leave headroom where the final ramp rises through the arena floor.
		# A complete disk above the ascending body becomes a ceiling trap.
		if id == "DynamoCore" and i >= 43 and i < 48:
			continue
		var a := float(i)*TAU/64
		var b := float(i+1)*TAU/64
		_quad(vertices,uv,Vector3(cos(a)*inner,height,sin(a)*inner),
			Vector3(cos(a)*outer,height,sin(a)*outer),
			Vector3(cos(b)*outer,height,sin(b)*outer),
			Vector3(cos(b)*inner,height,sin(b)*inner))
		_quad(vertices,uv,Vector3(cos(a)*outer,height,sin(a)*outer),
			Vector3(cos(a)*outer,height-1.2,sin(a)*outer),
			Vector3(cos(b)*outer,height-1.2,sin(b)*outer),
			Vector3(cos(b)*outer,height,sin(b)*outer))
	_surface(id,vertices,uv)

func _ascent() -> void:
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	for i in RAMP_SEGMENTS:
		var t0 := float(i)/RAMP_SEGMENTS
		var t1 := float(i+1)/RAMP_SEGMENTS
		var p := ascent_point(t0)
		var q := ascent_point(t1)
		var radial_p := Vector3(p.x,0,p.z).normalized()*RAMP_WIDTH*0.5
		var radial_q := Vector3(q.x,0,q.z).normalized()*RAMP_WIDTH*0.5
		_quad(vertices,uv,p-radial_p,p+radial_p,q+radial_q,q-radial_q)
	_surface("HollowTrunkAscent",vertices,uv)
	# Both edges are physical rails. They remain present on simulation shells.
	for edge in [-1.0,1.0]:
		var body := StaticBody3D.new()
		body.name = "AscentRailInner" if edge<0 else "AscentRailOuter"
		add_child(body)
		var rails: Array[Transform3D] = []
		for i in RAMP_SEGMENTS:
			var p := ascent_point(float(i)/RAMP_SEGMENTS)
			var q := ascent_point(float(i+1)/RAMP_SEGMENTS)
			p += Vector3(p.x,0,p.z).normalized()*RAMP_WIDTH*0.5*edge
			q += Vector3(q.x,0,q.z).normalized()*RAMP_WIDTH*0.5*edge
			var length := p.distance_to(q)
			var pose := Transform3D(Basis.looking_at((q-p).normalized()),(p+q)*0.5+Vector3.UP*0.7)
			var shape := BoxShape3D.new()
			shape.size = Vector3(0.22,1.4,length+0.1)
			var collider := CollisionShape3D.new()
			collider.shape = shape
			collider.transform = pose
			body.add_child(collider)
			pose.basis = pose.basis.scaled(Vector3(0.18,0.15,length+0.1))
			pose.origin.y += 0.55
			rails.append(pose)
		if not simulation_only:
			_instances(body,rails,_metal)

func _ramp(id: String,start: Vector3,end: Vector3,width: float) -> void:
	var side := Vector3(end.z-start.z,0,start.x-end.x).normalized()*width*0.5
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	_quad(vertices,uv,start-side,start+side,end+side,end-side)
	_surface(id,vertices,uv)

func _quad(vertices: PackedVector3Array,uv: PackedVector2Array,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	# Godot front faces are clockwise from above for this ring ordering.
	for p in [a,b,c,a,c,d]:
		vertices.append(p)
		uv.append(Vector2(p.x,p.z))

func _surface(id: String,vertices: PackedVector3Array,uv: PackedVector2Array) -> void:
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var normals := PackedVector3Array()
	for i in range(0,vertices.size(),3):
		var n := (vertices[i+2]-vertices[i]).cross(vertices[i+1]-vertices[i]).normalized()
		for unused in 3:
			normals.append(n)
	arrays[Mesh.ARRAY_NORMAL] = normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var body := StaticBody3D.new()
	body.name = id
	add_child(body)
	var collider := CollisionShape3D.new()
	collider.shape = mesh.create_trimesh_shape()
	body.add_child(collider)
	if not simulation_only:
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _wood
		body.add_child(visual)

func _instances(parent: Node3D,poses: Array[Transform3D],material: Material) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = poses.size()
	for i in poses.size():
		mm.set_instance_transform(i,poses[i])
	var visual := MultiMeshInstance3D.new()
	visual.multimesh = mm
	visual.material_override = material
	parent.add_child(visual)

func _fit_tree(id: String,file: String,at: Vector3,height: float,yaw: float) -> void:
	var model := (load("res://assets/environment/stylized_nature/"+file) as PackedScene).instantiate() as Node3D
	var bounds: Array[AABB] = []
	_mesh_bounds(model,Transform3D.IDENTITY,bounds)
	if bounds.is_empty():
		model.free()
		return
	var box := bounds[0]
	for other in bounds.slice(1):
		box = box.merge(other)
	var factor := height/maxf(box.size.y,0.01)
	var pivot := Node3D.new()
	pivot.name = id
	pivot.position = at
	pivot.rotation.y = yaw
	add_child(pivot)
	model.scale *= factor
	model.position -= Vector3(box.get_center().x,box.position.y,box.get_center().z)*factor
	_green_canopy(model)
	pivot.add_child(model)

func _green_canopy(node: Node) -> void:
	if node is MeshInstance3D:
		var visual := node as MeshInstance3D
		for i in visual.mesh.get_surface_count():
			var source := visual.mesh.surface_get_material(i) as StandardMaterial3D
			if source != null and source.resource_name == "Leaves_TwistedTree":
				var green := source.duplicate() as StandardMaterial3D
				green.albedo_texture = load("res://assets/environment/stylized_nature/derived/Leaves_NormalTree_C_desat55.png")
				green.albedo_color = Color("a6c4a3")
				visual.set_surface_override_material(i,green)
	for child in node.get_children():
		_green_canopy(child)

func _mesh_bounds(node: Node,pose: Transform3D,result: Array[AABB]) -> void:
	if node is Node3D:
		pose *= (node as Node3D).transform
	if node is MeshInstance3D:
		result.append(pose*(node as MeshInstance3D).get_aabb())
	for child in node.get_children():
		_mesh_bounds(child,pose,result)

func _energy_seam() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("76cfff")
	material.emission_enabled = true
	material.emission = Color("5c9dff")
	material.emission_energy_multiplier = 4
	var poses: Array[Transform3D] = []
	for i in 32:
		var p := Vector3(sin(i*1.9)*3,8+i*7,5)
		var q := Vector3(sin((i+1)*1.9)*3,15+i*7,5)
		poses.append(Transform3D(Basis.looking_at((q-p).normalized()).scaled(Vector3(2.4,2.4,p.distance_to(q))), (p+q)*0.5))
	_instances(self,poses,material)
	for y in [12,75,150,200]:
		var light := OmniLight3D.new()
		light.position = Vector3(0,y,0)
		light.light_color = Color("72bfff")
		light.light_energy = 4
		light.omni_range = 75
		add_child(light)

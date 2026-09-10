extends Node3D

## The board's split tree, Outer Works and hollow-trunk ascent. Static realm
## geometry is identical in the host shell and client scene; only art is omitted
## from the shell. This foundation does not award victories or chapter flags.
const CORE_HEIGHT := 150.0
const OUTER_WORKS_OUTER_RADIUS := 44.0
const RAMP_RADIUS := 26.0
const RAMP_WIDTH := 8.0
const RAMP_TURNS := 4.0
const RAMP_SEGMENTS := 384
const WALL_LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
var simulation_only := false
var _wood: StandardMaterial3D
var _metal: StandardMaterial3D
var _bark: StandardMaterial3D

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
	_ring("OuterWorks",18,OUTER_WORKS_OUTER_RADIUS,6)
	_ring("DynamoCore",9,44,CORE_HEIGHT)
	_ring("CrownChamber",7,18,CORE_HEIGHT+24)
	_ascent()
	_ramp("CoreLanding",ascent_point(1)-Vector3.RIGHT*0.8,ascent_point(1)+Vector3.RIGHT*4,8)
	# The upper chamber is reached from the arena along the inside east trunk.
	_ramp("CrownStair",Vector3(34,CORE_HEIGHT,0),Vector3(-16,CORE_HEIGHT+24,0),6)
	if simulation_only:
		return
	_bark = _wood.duplicate() as StandardMaterial3D
	_bark.albedo_color = Color("bca58a")
	_bark.uv1_scale = Vector3.ONE
	_split_bark_shell()
	_buttress_roots()
	_living_crown()
	_ascent_dressing()
	_ascent_wayfinding()
	_energy_seam()

func core_anchor() -> Vector3:
	return global_position+Vector3(0,CORE_HEIGHT+0.2,-25)

func add_approach(start: Vector3) -> void:
	# Meet the deck at its outer edge: ending farther inside leaves the
	# rising ramp below the ring's vertical fascia at first contact.
	_ramp("OuterWorksApproach",to_local(start),Vector3(0,6,-OUTER_WORKS_OUTER_RADIUS),10)

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

func _fit_tree(id: String,file: String,at: Vector3,height: float,yaw: float,leaves_only: bool = false) -> void:
	var model := (load("res://assets/environment/stylized_nature/"+file) as PackedScene).instantiate() as Node3D
	if leaves_only:
		_leaf_surfaces(model)
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


## The ascent's physical rings/rails remain the traversal contract. This bark
## is a visual hollow tree around them: its inner radius stays outside the
## full 44 m arena/deck, while the southern split frames the charged heart from the
## authored approach. Separate curved lobes replace four inflated stock trunks.
func _split_bark_shell() -> void:
	var heights := [0.0,12.0,35.0,70.0,110.0,150.0,185.0,220.0,250.0]
	for side in 2:
		var vertices := PackedVector3Array()
		var normals := PackedVector3Array()
		var uvs := PackedVector2Array()
		var start := -PI*0.5+0.27 if side == 0 else PI*0.5+0.14
		var end := PI*0.5-0.14 if side == 0 else PI*1.5-0.27
		for band in heights.size()-1:
			for panel in 40:
				var a := lerpf(start,end,float(panel)/40)
				var b := lerpf(start,end,float(panel+1)/40)
				for inner in [false,true]:
					var p := _trunk_point(a,heights[band],inner)
					var q := _trunk_point(b,heights[band],inner)
					var r := _trunk_point(b,heights[band+1],inner)
					var s := _trunk_point(a,heights[band+1],inner)
					_bark_quad(vertices,normals,uvs,p,q,r,s,inner)
			# Rough exposed wood along both lightning-split lips gives the tree
			# thickness when viewed from the entry, not a paper cylinder edge.
			for angle in [start,end]:
				_bark_quad(vertices,normals,uvs,
					_trunk_point(angle,heights[band],false),_trunk_point(angle,heights[band],true),
					_trunk_point(angle,heights[band+1],true),_trunk_point(angle,heights[band+1],false))
		_bark_visual("EastLivingTrunk" if side == 0 else "WestLivingTrunk",vertices,normals,uvs)


func _trunk_point(angle: float,height: float,inner: bool) -> Vector3:
	var taper := smoothstep(185,250,height)
	var radius := lerpf(46.0,13.0,taper) if inner else lerpf(58.0,24.0,taper)
	if not inner:
		radius += 9.0*exp(-height/19.0)
		radius += sin(angle*7.0+height*0.018)*2.1+cos(angle*11.0-height*0.027)*1.0
	# Preserve the lower ramp corridor; the broad leaning crown begins above it.
	var lean := smoothstep(185,250,height)
	return Vector3(cos(angle)*radius+lean*9.0,height,sin(angle)*radius+lean*6.0)


func _bark_quad(vertices: PackedVector3Array,normals: PackedVector3Array,uvs: PackedVector2Array,
		a: Vector3,b: Vector3,c: Vector3,d: Vector3,reverse: bool = false) -> void:
	var order: Array[Vector3] = []
	order.assign([a,c,b,a,d,c] if reverse else [a,b,c,a,c,d])
	var n: Vector3 = (order[2]-order[0]).cross(order[1]-order[0]).normalized()
	for p: Vector3 in order:
		vertices.append(p)
		normals.append(n)
		uvs.append(Vector2(atan2(p.z,p.x)*6.0,p.y/11.0))


func _bark_visual(id: String,vertices: PackedVector3Array,normals: PackedVector3Array,uvs: PackedVector2Array) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var visual := MeshInstance3D.new()
	visual.name = id
	visual.mesh = mesh
	visual.material_override = _bark
	add_child(visual)


func _wood_limb(id: String,points: Array[Vector3],radii: Array[float]) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for section in points.size()-1:
		var direction := (points[section+1]-points[section]).normalized()
		var axis := direction.cross(Vector3.UP).normalized()
		if axis.length_squared()<0.01:
			axis = Vector3.RIGHT
		var up := axis.cross(direction).normalized()
		for face in 12:
			var a := TAU*float(face)/12
			var b := TAU*float(face+1)/12
			var r := axis*cos(a)+up*sin(a)
			var s := axis*cos(b)+up*sin(b)
			_bark_quad(vertices,normals,uvs,points[section]+r*radii[section],
				points[section]+s*radii[section],points[section+1]+s*radii[section+1],points[section+1]+r*radii[section+1])
	_bark_visual(id,vertices,normals,uvs)


func _buttress_roots() -> void:
	for index in 9:
		var angle := float(index)*TAU/9+0.1
		# Keep the southern 10 m approach and eastern Water exit visible/clear.
		if sin(angle)<-0.85 or cos(angle)>0.93:
			continue
		var ray := Vector3(cos(angle),0,sin(angle))
		var bend := Vector3(-ray.z,0,ray.x)*(5.0 if index%2 else -7.0)
		var middle := ray*77+bend
		var tip := ray*91+bend
		middle.y = _root_ground(middle)+1.5
		tip.y = _root_ground(tip)-1.5
		_wood_limb("ButtressRoot%d"%index,[ray*40+Vector3.UP*23,ray*56+Vector3.UP*8,
			middle,tip],[12.0,9.0,3.7,0.6])


func _root_ground(at: Vector3) -> float:
	var world := get_parent()
	if world != null and world.has_method("ground_height_at"):
		return float(world.call("ground_height_at",position.x+at.x,position.z+at.z))-position.y
	return 0.0


func _living_crown() -> void:
	var tips: Array[Vector3] = [Vector3(-69,163,3),Vector3(77,188,15),Vector3(-62,222,33),
		Vector3(58,235,-9),Vector3(2,267,23),Vector3(-20,209,-43)]
	for i in tips.size():
		var tip := tips[i]
		var root := Vector3(signf(tip.x)*36,tip.y-54,tip.z*0.2)
		_wood_limb("CrownBough%d"%i,[root,root.lerp(tip,0.48)-Vector3.UP*10,tip],[10.0,7.0,2.4])
		_fit_tree("LivingCanopy%d"%i,"TwistedTree_2.gltf" if i%2 else "TwistedTree_4.gltf",
			tip-Vector3.UP*8,43.0+float(i%3)*7.0,float(i)*1.7,true)


func _leaf_surfaces(node: Node) -> void:
	if node is MeshInstance3D:
		var visual := node as MeshInstance3D
		var leaves := ArrayMesh.new()
		for i in visual.mesh.get_surface_count():
			var material := visual.mesh.surface_get_material(i)
			if material != null and material.resource_name.begins_with("Leaves_"):
				leaves.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,visual.mesh.surface_get_arrays(i))
				leaves.surface_set_material(leaves.get_surface_count()-1,material)
		visual.mesh = leaves
	for child in node.get_children():
		_leaf_surfaces(child)


func _ascent_dressing() -> void:
	var posts: Array[Transform3D] = []
	var braces: Array[Transform3D] = []
	for step in 48:
		var at := ascent_point(float(step)/48)
		var radial := Vector3(at.x,0,at.z).normalized()
		var edge := at+radial*(RAMP_WIDTH*0.5)
		posts.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.65,3.2,0.65)),edge+Vector3.UP*1.2))
		var anchor := radial*48+Vector3(0,at.y-6,0)
		var vector := edge-anchor
		braces.append(Transform3D(Basis.looking_at(vector.normalized()).scaled(Vector3(0.8,0.8,vector.length())),(anchor+edge)*0.5))
	_instances(self,posts,_wood)
	_instances(self,braces,_wood)


## The approved Stormheart interior is an inhabited ascent, with a legible base
## threshold and a warm chain of lamps marking the route around the cold core.
## The original continuous ramp had rails and braces, but from the gameplay
## camera those repeated thin members collapsed into one black ribbon. These are
## presentation-only landmarks: the existing ring, ramp, rails and their
## collision remain the complete traversal contract.
func _ascent_wayfinding() -> void:
	var root := Node3D.new()
	root.name = "AscentWayfinding"
	add_child(root)
	_ascent_plank_rhythm(root)

	# A broad timber portal where the southern approach meets the hollow. It
	# frames rather than closes the ten-metre route and gives the first turn an
	# unmistakable start at human scale.
	var portal_z := -39.0
	for side in 2:
		var x := -5.6 if side == 0 else 5.6
		_visual_box(root, "ThresholdPostWest" if side == 0 else "ThresholdPostEast", Vector3(x, 9.4, portal_z),
			Vector3(0.75, 6.8, 0.75), _wood)
	_visual_box(root, "ThresholdTie", Vector3(0.0, 12.35, portal_z),
		Vector3(11.8, 0.38, 0.6), _wood)
	_visual_beam(root, "ThresholdCrownWest", Vector3(-5.6, 12.45, portal_z),
		Vector3(0.0, 15.5, portal_z), 0.72, _wood)
	_visual_beam(root, "ThresholdCrownEast", Vector3(5.6, 12.45, portal_z),
		Vector3(0.0, 15.5, portal_z), 0.72, _wood)

	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("ffbd62")
	glow.emission_enabled = true
	glow.emission = Color("ff9a3d")
	glow.emission_energy_multiplier = 3.2
	glow.roughness = 0.45

	# Two lights identify the threshold; two lamps at the southern reveal of
	# each full turn form a vertical progress chain that is visible from the
	# entrance. Their route-side alternation keeps the playable eight-metre ramp
	# open while making each completed revolution readable from below.
	_add_wayfinding_lamp(root, Vector3(-4.45, 10.2, portal_z - 0.15), glow, "ThresholdLampWest")
	_add_wayfinding_lamp(root, Vector3(4.45, 10.2, portal_z - 0.15), glow, "ThresholdLampEast")
	for index in 8:
		var turn := index / 2
		var phase := 0.03 if index % 2 == 0 else 0.16
		var t := (float(turn) + phase) / RAMP_TURNS
		var p := ascent_point(t)
		var radial := Vector3(p.x, 0.0, p.z).normalized()
		var side := -1.0 if index % 2 == 0 else 1.0
		var at := p + radial * (RAMP_WIDTH * 0.5 * side) + Vector3.UP * 2.25
		_add_wayfinding_lamp(root, at, glow, "SpiralLamp%02d" % (index + 1))


## Short cross-planks give the enormous ramp a repeatable human construction
## scale. They sit 4 cm above the existing visual surface, follow its slope, and
## have no collision; the uninterrupted physical ramp underneath is unchanged.
func _ascent_plank_rhythm(parent: Node3D) -> void:
	var trim := _wood.duplicate() as StandardMaterial3D
	trim.albedo_color = Color("c4a069")
	trim.uv1_scale = Vector3(0.7, 0.7, 1.0)
	var slats: Array[Transform3D] = []
	for index in 48:
		var t := (float(index) + 0.5) / 48.0
		var p := ascent_point(t)
		var q := ascent_point(minf(t + 1.0 / float(RAMP_SEGMENTS), 1.0))
		var across := Vector3(p.x, 0.0, p.z).normalized()
		var forward := (q - p).normalized()
		var normal := forward.cross(across).normalized()
		var basis := Basis(across * (RAMP_WIDTH - 0.35), normal * 0.10, forward * 0.34)
		slats.append(Transform3D(basis, p + normal * 0.04))
	var rhythm := Node3D.new()
	rhythm.name = "SpiralPlankRhythm"
	parent.add_child(rhythm)
	_instances(rhythm, slats, trim)


func _visual_box(parent: Node3D, id: String, at: Vector3, size: Vector3,
		material: Material) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = id
	var box := BoxMesh.new()
	box.size = size
	visual.mesh = box
	visual.material_override = material
	visual.position = at
	parent.add_child(visual)
	return visual


func _visual_beam(parent: Node3D, id: String, start: Vector3, finish: Vector3,
		thickness: float, material: Material) -> MeshInstance3D:
	var vector := finish - start
	var visual := _visual_box(parent, id, (start + finish) * 0.5,
		Vector3(thickness, thickness, vector.length()), material)
	visual.basis = Basis.looking_at(vector.normalized())
	return visual


func _add_wayfinding_lamp(parent: Node3D, at: Vector3, glow: Material, id: String) -> void:
	var holder := Node3D.new()
	holder.name = id
	holder.position = at
	holder.rotation.y = atan2(-at.x, -at.z)
	parent.add_child(holder)
	var lantern := WALL_LANTERN.instantiate() as Node3D
	lantern.name = "AuthoredLantern"
	lantern.scale = Vector3.ONE * 0.85
	holder.add_child(lantern)
	var bulb := MeshInstance3D.new()
	bulb.name = "AmberFlame"
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.26
	bulb.mesh = sphere
	bulb.material_override = glow
	bulb.position = Vector3(0.0, 0.72, 0.62)
	holder.add_child(bulb)
	var light := OmniLight3D.new()
	light.name = "WarmRouteLight"
	light.position = Vector3(0.0, 0.72, 0.9)
	light.light_color = Color("ffb15c")
	light.light_energy = 2.1
	light.omni_range = 22.0
	light.shadow_enabled = false
	holder.add_child(light)

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
	if node is MeshInstance3D and (node as MeshInstance3D).mesh.get_surface_count() > 0:
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

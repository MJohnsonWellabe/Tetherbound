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
## Half-widths (radians) of the trunk's open splits at +Z and -Z.
const SPLIT_NORTH_HALF_WIDTH := 0.14
const SPLIT_SOUTH_HALF_WIDTH := 0.27
const SPLIT_BRACE_MARGIN := 0.05
## Spiral lamps sit 2.25 m above the ramp; their post runs from it to the bracket.
const LAMP_POST_TOP_M := 1.0
const LAMP_POST_HEIGHT_M := 3.25
const WALL_LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const PRESENTATION_PATH := "res://data/config/stormheart_presentation.json"
const CANOPY_SHADER := preload("res://scripts/world/stormheart_canopy.gdshader")
const CUT_WOOD_SHADER := preload("res://scripts/world/stormheart_cut_wood.gdshader")
var simulation_only := false
var _presentation: Dictionary = {}
var _wood: StandardMaterial3D
var _metal: StandardMaterial3D
var _bark: StandardMaterial3D
var _cut_wood: ShaderMaterial
var _core_material: StandardMaterial3D
var _core_lights: Array[OmniLight3D] = []
var _core_revision := -1
var _core_flags_id := 0
var _core_released := false

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
		set_process(false)
		return
	_presentation = _read_presentation()
	_bark = _wood.duplicate() as StandardMaterial3D
	_bark.albedo_color = Color("bca58a")
	_bark.uv1_scale = Vector3.ONE
	if _presentation_enabled("ancient_trunk"):
		var finish: Dictionary = _presentation.get("ancient_trunk", {})
		_bark.albedo_color = Color(str(finish.get("bark_tint", "#bca58a")))
		_bark.normal_enabled = true
		_bark.normal_texture = load("res://assets/environment/stylized_nature/Bark_TwistedTree_Normal.png")
		_bark.normal_scale = clampf(float(finish.get("normal_depth", 0.65)), 0.0, 1.0)
		_bark.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_split_bark_shell()
	_buttress_roots()
	_living_crown()
	_ascent_dressing()
	_ascent_wayfinding()
	_energy_seam()
	set_process(_core_material != null)
	if _presentation_enabled("built_detail"):
		_built_detail()


func _presentation_enabled(key: String) -> bool:
	var settings: Dictionary = _presentation.get(key, {})
	return bool(_presentation.get("enabled", false)) and bool(settings.get("enabled", false))


func _read_presentation() -> Dictionary:
	var presentation: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH))
	return presentation if presentation is Dictionary else {}

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
			rails.append(_rail_visual_pose(pose, length))
		if not simulation_only:
			_instances(body,rails,_metal)

## Pure visual transform shared by the real rail batch and headless contract
## checks. The collider pose is a value; its physical seat/shape never changes.
func _rail_visual_pose(collider_pose: Transform3D, segment_length: float) -> Transform3D:
	var pose := collider_pose
	pose.basis = pose.basis.scaled_local(Vector3(0.18, 0.15, segment_length + 0.1))
	pose.origin.y += 0.55
	return pose


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
		visual.material_override = _cut_wood if _cut_wood != null else _wood
		body.add_child(visual)

func _instances(parent: Node3D,poses: Array[Transform3D],material: Material,mesh: Mesh = null) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh if mesh != null else BoxMesh.new()
	mm.instance_count = poses.size()
	for i in poses.size():
		mm.set_instance_transform(i,poses[i])
	var visual := MultiMeshInstance3D.new()
	visual.multimesh = mm
	visual.material_override = material
	parent.add_child(visual)

func _fit_tree(id: String,file: String,at: Vector3,height: float,yaw: float,leaves_only: bool = false,
		shape: Vector3 = Vector3.ONE) -> void:
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
	model.scale *= factor * shape
	model.position -= Vector3(box.get_center().x,box.position.y,box.get_center().z)*factor*shape
	_green_canopy(model)
	pivot.add_child(model)


## The ascent's physical rings/rails remain the traversal contract. This bark
## is a visual hollow tree around them: its inner radius stays outside the
## full 44 m arena/deck, while the southern split frames the charged heart from the
## authored approach. Separate curved lobes replace four inflated stock trunks.
func _split_bark_shell() -> void:
	if _presentation_enabled("ancient_trunk"):
		_ancient_bark_shell()
		return
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


## The inner wall retains its physical-route clearance. The outside has broad
## twisting buttresses and a tapering waist, rather than a constant cylinder.
## Dense longitudinal rings and smooth surface normals carry the ridges across
## old band boundaries; the angular UV coordinate never wraps at atan2's seam.
func _ancient_bark_shell() -> void:
	var settings: Dictionary = _presentation.get("ancient_trunk", {})
	var repeat_m := maxf(0.5, float(settings.get("bark_repeat_m", 4.0)))
	for side in 2:
		var vertices := PackedVector3Array()
		var normals := PackedVector3Array()
		var uvs := PackedVector2Array()
		var start := -PI*0.5+0.27 if side == 0 else PI*0.5+0.14
		var end := PI*0.5-0.14 if side == 0 else PI*1.5-0.27
		for band in 50:
			var low := float(band)*5.0
			var high := float(band+1)*5.0
			for panel in 64:
				var a := lerpf(start,end,float(panel)/64.0)
				var b := lerpf(start,end,float(panel+1)/64.0)
				for inner in [false,true]:
					var corners: Array[Vector2] = [Vector2(a,low),Vector2(b,low),Vector2(b,high),Vector2(a,high)]
					var order := [0,2,1,0,3,2] if inner else [0,1,2,0,2,3]
					for index: int in order:
						var coordinate := corners[index]
						vertices.append(_ancient_trunk_point(coordinate.x,coordinate.y,inner))
						var across := _ancient_trunk_point(coordinate.x+0.001,coordinate.y,inner)-_ancient_trunk_point(coordinate.x-0.001,coordinate.y,inner)
						var up := _ancient_trunk_point(coordinate.x,coordinate.y+0.02,inner)-_ancient_trunk_point(coordinate.x,coordinate.y-0.02,inner)
						var normal := up.cross(across).normalized()
						normals.append(-normal if inner else normal)
						uvs.append(Vector2(coordinate.x*58.0/repeat_m,coordinate.y/repeat_m))
			for angle in [start,end]:
				_bark_quad(vertices,normals,uvs,_ancient_trunk_point(angle,low,false),
					_ancient_trunk_point(angle,low,true),_ancient_trunk_point(angle,high,true),
					_ancient_trunk_point(angle,high,false),angle == end)
		_bark_visual("EastLivingTrunk" if side == 0 else "WestLivingTrunk",vertices,normals,uvs)


func _ancient_trunk_point(angle: float,height: float,inner: bool) -> Vector3:
	# Below the upper crown this is exactly the existing inner clearance.
	if inner:
		var inside := _trunk_point(angle,height,true)
		inside.y += smoothstep(185.0,250.0,height)*(sin(angle*3.0+0.8)*8.0+sin(angle*7.0)*4.0)
		return inside
	var settings: Dictionary = _presentation.get("ancient_trunk", {})
	var depth := clampf(float(settings.get("lobe_depth_m",8.0)),0.0,12.0)
	var taper := smoothstep(185.0,250.0,height)
	var radius := lerpf(60.0-8.0*smoothstep(30.0,170.0,height),24.0,taper)
	var roots := 16.0*exp(-maxf(height,0.0)/24.0)
	var ridges := sin(angle*3.0+height*0.009)+0.45*sin(angle*7.0-height*0.015)
	# Outer geometry never crosses the protected inner skin.
	radius = maxf(radius+roots+ridges*depth*(1.0-taper*0.4),lerpf(51.0,19.0,taper))
	var point := Vector3(cos(angle)*radius+taper*9.0,height,sin(angle)*radius+taper*6.0)
	point.y += taper*(sin(angle*3.0+0.8)*8.0+sin(angle*7.0)*4.0)
	if height == 0.0 and bool(_presentation.get("ground_shell_base",false)):
		point.y = minf(point.y,_root_ground(point)-maxf(0.0,float(_presentation.get("bark_embed_m",0.5))))
	return point


func _trunk_point(angle: float,height: float,inner: bool) -> Vector3:
	var taper := smoothstep(185,250,height)
	var radius := lerpf(46.0,13.0,taper) if inner else lerpf(58.0,24.0,taper)
	if not inner:
		radius += 9.0*exp(-height/19.0)
		radius += sin(angle*7.0+height*0.018)*2.1+cos(angle*11.0-height*0.027)*1.0
	# Preserve the lower ramp corridor; the broad leaning crown begins above it.
	var lean := smoothstep(185,250,height)
	var point := Vector3(cos(angle)*radius+lean*9.0,height,sin(angle)*radius+lean*6.0)
	# Only the visual skirt extends down to the existing terrain. Keep its
	# upper bands and the full southern entrance split exactly as authored.
	if height == 0.0 and bool(_presentation.get("enabled", false)) \
			and bool(_presentation.get("ground_shell_base", false)):
		var embed := maxf(0.0, float(_presentation.get("bark_embed_m", 0.5)))
		point.y = minf(point.y, _root_ground(point) - embed)
	return point


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
	if _bark.normal_enabled:
		var surface := SurfaceTool.new()
		surface.create_from(mesh, 0)
		surface.generate_tangents()
		visual.mesh = surface.commit()
	else:
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
	var visible := _presentation_enabled("visible_roots")
	var settings: Dictionary = _presentation.get("visible_roots", {})
	for index in 9:
		var angle := float(index)*TAU/9+0.1
		# Keep the southern 10 m approach and eastern Water exit visible/clear.
		if sin(angle)<-0.85 or cos(angle)>0.93:
			continue
		var ray := Vector3(cos(angle),0,sin(angle))
		var bend := Vector3(-ray.z,0,ray.x)*(5.0 if index%2 else -7.0)
		if visible:
			# Anchor into the actual outside bark, rather than hiding almost all
			# of the root inside the much wider candidate trunk. These meshes
			# add no collision or new floor; the south/east openings stay clear.
			var reach := clampf(float(settings.get("reach_m", 132.0)), 110.0, 145.0)
			var anchor := _ancient_trunk_point(angle, 23.0, false) \
				if _presentation_enabled("ancient_trunk") else _trunk_point(angle, 23.0, false)
			var shoulder := ray * (Vector2(anchor.x, anchor.z).length() + 12.0) + bend * 0.35
			var middle_visible := ray * (reach * 0.82) + bend
			var tip_visible := ray * reach + bend
			shoulder.y = maxf(_root_ground(shoulder) + 7.0, anchor.y * 0.5)
			middle_visible.y = _root_ground(middle_visible) + 2.5
			tip_visible.y = _root_ground(tip_visible) - 1.5
			_wood_limb("ButtressRoot%d" % index,
				[anchor - ray * 5.0, shoulder, middle_visible, tip_visible], [15.0, 10.0, 4.8, 0.6])
			continue
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
	var branching: Dictionary = _presentation.get("branching_crown", {})
	if bool(_presentation.get("enabled", false)) and bool(branching.get("enabled", false)):
		_branching_crown(branching)
		return
	var tips: Array[Vector3] = [Vector3(-69,163,3),Vector3(77,188,15),Vector3(-62,222,33),
		Vector3(58,235,-9),Vector3(2,267,23),Vector3(-20,209,-43)]
	for i in tips.size():
		var tip := tips[i]
		var root := Vector3(signf(tip.x)*36,tip.y-54,tip.z*0.2)
		_wood_limb("CrownBough%d"%i,[root,root.lerp(tip,0.48)-Vector3.UP*10,tip],[10.0,7.0,2.4])
		_fit_tree("LivingCanopy%d"%i,"TwistedTree_2.gltf" if i%2 else "TwistedTree_4.gltf",
			tip-Vector3.UP*8,43.0+float(i%3)*7.0,float(i)*1.7,true)


## Board A/B: branches carry overlapping crown masses at several heights.
## These visual limbs remain outside the playable lower trunk; their installed
## leaf surfaces add no bodies, routes, harvest points or collision.
func _branching_crown(settings: Dictionary) -> void:
	var shape_data: Array = settings.get("leaf_shape", [1.35, 0.85, 1.25])
	var shape := Vector3(float(shape_data[0]), float(shape_data[1]), float(shape_data[2]))
	var repeat_m := maxf(0.5, float(settings.get("bark_repeat_m", 6.0)))
	var index := 0
	for branch: Dictionary in settings.get("branches", []):
		var points: Array[Vector3] = []
		var radii: Array[float] = []
		for point: Array in branch.points:
			points.append(Vector3(float(point[0]), float(point[1]), float(point[2])))
		for radius: float in branch.radii:
			radii.append(radius)
		var id := str(branch.id)
		_crown_limb("BranchCrown" + id, points, radii, repeat_m)
		for leaf_index in branch.leaves.size():
			var leaf: Dictionary = branch.leaves[leaf_index]
			var at := Vector3(float(leaf.at[0]), float(leaf.at[1]), float(leaf.at[2]))
			if leaf_index > 0:
				var fork := points[points.size() - 2]
				var tip := at + Vector3.UP * 12.0
				_crown_limb("BranchFork" + id + str(leaf_index),
					[fork, fork.lerp(tip, 0.5) - Vector3.UP * 3.0, tip], [5.0, 3.0, 0.9], repeat_m)
			_fit_tree("BranchLeaves" + id + str(leaf_index),
				"TwistedTree_2.gltf" if index % 2 else "TwistedTree_4.gltf",
				at, float(leaf.height), float(leaf.yaw), true, shape)
			index += 1


## Continuous rings follow a curved centreline, avoiding the open joints of
## independently oriented straight segments. UVs follow the limb in metres.
func _crown_limb(id: String, controls: Array[Vector3], radii: Array[float], repeat_m: float) -> void:
	var centres: Array[Vector3] = []
	var widths: Array[float] = []
	for segment in controls.size() - 1:
		for step in 8:
			var t := float(step) / 8.0
			centres.append(controls[segment].cubic_interpolate(controls[segment + 1],
				controls[maxi(0, segment - 1)], controls[mini(controls.size() - 1, segment + 2)], t))
			widths.append(lerpf(radii[segment], radii[segment + 1], smoothstep(0.0, 1.0, t)))
	centres.append(controls.back())
	widths.append(radii.back())
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var rings: Array[PackedVector3Array] = []
	var radial_normals: Array[PackedVector3Array] = []
	var lengths: Array[float] = [0.0]
	var previous_side := Vector3.ZERO
	for ring in centres.size():
		var tangent := (centres[mini(ring + 1, centres.size() - 1)] - centres[maxi(0, ring - 1)]).normalized()
		# Carry the prior frame through vertical bends instead of flipping it
		# when a branch changes which side of world-up its tangent lies on.
		var side := (previous_side - tangent * previous_side.dot(tangent)).normalized()
		if side.length_squared() < 0.01:
			side = tangent.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.01:
			side = Vector3.RIGHT
		previous_side = side
		var up := side.cross(tangent).normalized()
		var positions := PackedVector3Array()
		var directions := PackedVector3Array()
		for face in 13:
			var angle := TAU * float(face) / 12.0
			var direction := side * cos(angle) + up * sin(angle)
			positions.append(centres[ring] + direction * widths[ring])
			directions.append(direction)
		rings.append(positions)
		radial_normals.append(directions)
		if ring > 0:
			lengths.append(lengths.back() + centres[ring].distance_to(centres[ring - 1]))
	for ring in centres.size() - 1:
		for face in 12:
			for corner: Vector2i in [Vector2i(ring, face), Vector2i(ring, face + 1), Vector2i(ring + 1, face + 1),
					Vector2i(ring, face), Vector2i(ring + 1, face + 1), Vector2i(ring + 1, face)]:
				vertices.append(rings[corner.x][corner.y])
				normals.append(radial_normals[corner.x][corner.y])
				uvs.append(Vector2(float(corner.y) / 12.0 * TAU * widths[corner.x] / repeat_m,
					lengths[corner.x] / repeat_m))
	_bark_visual(id, vertices, normals, uvs)


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
		# A brace seated in the bark has nothing to seat in across the open
		# split: there it ended in mid-air against the sky slot.
		if not in_trunk_split(atan2(at.z,at.x),SPLIT_BRACE_MARGIN):
			braces.append(Transform3D(Basis.looking_at(vector.normalized()).scaled_local(Vector3(0.8,0.8,vector.length())),(anchor+edge)*0.5))
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


## All construction here dresses existing floors/rails. Braces hang below the
## decks, pickets lie inside the existing rail collision, and cloth hangs on
## the outside of the spiral. It adds no platform or physical blocker.
func _built_detail() -> void:
	var settings: Dictionary = _presentation.get("built_detail", {})
	var wood := ShaderMaterial.new()
	wood.shader = CUT_WOOD_SHADER
	wood.set_shader_parameter("wood_atlas",load("res://assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png"))
	wood.set_shader_parameter("wood_tint",Color(str(settings.get("wood_tint","#c4aa87"))))
	_cut_wood = wood
	for visual: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		if visual.material_override == _wood:
			visual.material_override = wood
	for visual: MultiMeshInstance3D in find_children("*","MultiMeshInstance3D",true,false):
		if visual.material_override == _wood:
			visual.material_override = wood
	var detail := Node3D.new()
	detail.name = "BuiltDetail"
	add_child(detail)
	var fascia: Array[Transform3D] = []
	var brackets: Array[Transform3D] = []
	for tier: Vector2 in [Vector2(6.0,44.0),Vector2(CORE_HEIGHT,44.0),Vector2(CORE_HEIGHT+24.0,18.0)]:
		for index in 64:
			# Same opening as the physical core floor, no trim across its ramp.
			if tier.x == CORE_HEIGHT and index >= 43 and index < 48:
				continue
			var a := float(index)*TAU/64.0
			var b := float(index+1)*TAU/64.0
			var p := Vector3(cos(a)*tier.y,tier.x-0.25,sin(a)*tier.y)
			var q := Vector3(cos(b)*tier.y,tier.x-0.25,sin(b)*tier.y)
			fascia.append(_beam_pose(p,q,0.35,0.45))
		brackets.append_array(_deck_brace_poses(tier))
	_instances(detail,fascia,wood)
	_instances(detail,brackets,wood)
	var pickets: Array[Transform3D] = []
	for index in 192:
		var at := ascent_point(float(index)/192.0)
		var radial := Vector3(at.x,0,at.z).normalized()
		for side in [-1.0,1.0]:
			pickets.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.14,1.18,0.14)),
				at+radial*(RAMP_WIDTH*0.5*side)+Vector3.UP*0.59))
	_instances(detail,pickets,wood)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(str(settings.get("banner_colour","#183e65")))
	cloth.roughness = 0.96
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color(str(settings.get("banner_trim","#d5b466")))
	trim.roughness = 0.72
	for index in 8:
		var at := ascent_point((float(index)/2.0+0.16)/RAMP_TURNS)
		var radial := Vector3(at.x,0,at.z).normalized()
		_hanging_banner(detail,at+radial*6.2-Vector3.UP*0.35,cloth,trim,index)


## Use the same open north/south trunk split for both upper deck tiers.
## Crown supports descend to the core floor: their two axial braces used to
## bisect the existing encounter/approach view despite having valid seats.
func _deck_brace_poses(tier: Vector2) -> Array[Transform3D]:
	var poses: Array[Transform3D] = []
	for index in range(0,64,4):
		# Preserve the physical core ascent opening and its existing trim rule.
		if tier.x == CORE_HEIGHT and index >= 43 and index < 48:
			continue
		var a := float(index)*TAU/64.0
		if tier.x >= CORE_HEIGHT and absf(cos(a)) < 0.27:
			continue
		if in_trunk_split(a,SPLIT_BRACE_MARGIN):
			continue
		var ray := Vector3(cos(a),0,sin(a))
		var low := CORE_HEIGHT if tier.x > CORE_HEIGHT else maxf(0.0,tier.x-8.0)
		poses.append(_beam_pose(ray*(tier.y+2.0)+Vector3.UP*low,
			ray*(tier.y-1.0)+Vector3.UP*(tier.x-1.4),0.7,0.7))
	return poses


## True where `angle` (tree-local, atan2(z, x)) faces one of the trunk's two
## open lightning splits (see _split_bark_shell), widened by `margin` radians.
static func in_trunk_split(angle: float,margin: float) -> bool:
	var north := absf(angle_difference(angle,PI*0.5))
	var south := absf(angle_difference(angle,-PI*0.5))
	return north < SPLIT_NORTH_HALF_WIDTH+margin or south < SPLIT_SOUTH_HALF_WIDTH+margin


func _beam_pose(start: Vector3,finish: Vector3,width: float,height: float) -> Transform3D:
	var vector := finish-start
	return Transform3D(Basis.looking_at(vector.normalized()).scaled_local(Vector3(width,height,vector.length())),(start+finish)*0.5)


func _banner_point(u: float,v: float) -> Vector3:
	return Vector3((u-0.5)*3.2,-v*(6.6-absf(u-0.5)*2.0),
		sin(u*PI)*0.12+sin(v*5.0+u*2.0)*0.08*v)


func _hanging_banner(parent: Node3D,at: Vector3,cloth: Material,trim: Material,index: int) -> void:
	var holder := Node3D.new()
	holder.name = "HangingBanner%02d"%index
	holder.position = at
	holder.rotation.y = atan2(at.x,at.z)
	parent.add_child(holder)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 16:
		for column in 8:
			for corner: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var uv := Vector2(float(column+corner.x)/8.0,float(row+corner.y)/16.0)
				surface.set_uv(uv)
				surface.add_vertex(_banner_point(uv.x,uv.y))
	surface.generate_normals()
	var visual := MeshInstance3D.new()
	visual.name = "ShapedCloth"
	visual.mesh = surface.commit()
	visual.material_override = cloth
	holder.add_child(visual)
	_visual_box(holder,"ClothRod",Vector3(0,0.12,0),Vector3(3.65,0.16,0.16),_metal)
	for side in [-1.0,1.0]:
		_visual_beam(holder,"RodBracket",Vector3(side*1.1,0.35,-2.2),Vector3(side*1.1,0.12,0),0.16,_metal)
	var trim_poses: Array[Transform3D] = []
	for edge in [0.04,0.96]:
		for row in 16:
			trim_poses.append(_beam_pose(_banner_point(edge,float(row)/16.0),
				_banner_point(edge,float(row+1)/16.0),0.075,0.075))
	# A raised lightning embroidery follows the cloth's curve on both sides.
	var lightning: Array[Vector2] = [Vector2(0.65,0.22),Vector2(0.38,0.48),Vector2(0.62,0.46),Vector2(0.38,0.75)]
	for side in [-1.0,1.0]:
		for segment in lightning.size()-1:
			var a := lightning[segment]
			var b := lightning[segment+1]
			trim_poses.append(_beam_pose(_banner_point(a.x,a.y)+Vector3.FORWARD*0.055*side,
				_banner_point(b.x,b.y)+Vector3.FORWARD*0.055*side,0.14,0.14))
	_instances(holder,trim_poses,trim)


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
	# Route lamps on the open ramp hang from a short timber post seated on the
	# ramp; without it the flame floated against the sky slot. Visual only.
	if id.begins_with("SpiralLamp"):
		var post := MeshInstance3D.new()
		post.name = "LampPost"
		var box := BoxMesh.new()
		box.size = Vector3(0.24, LAMP_POST_HEIGHT_M, 0.24)
		post.mesh = box
		post.material_override = _wood
		# The holder faces the axis (+Z inward). An outer-edge lamp's post
		# steps inward and an inner-edge lamp's outward, so both seat on the ramp.
		var inward := 1.0 if Vector2(at.x, at.z).length() > RAMP_RADIUS else -1.0
		post.position = Vector3(0.0, LAMP_POST_TOP_M - LAMP_POST_HEIGHT_M*0.5, 0.2*inward)
		holder.add_child(post)
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
				var canopy: Dictionary = _presentation.get("canopy_atlas", {})
				if bool(_presentation.get("enabled", false)) and bool(canopy.get("enabled", false)):
					# Keep the atlas authored for these leaf UVs. Multiplication cannot
					# turn its red leaves green; swapping another tree's alpha mask
					# cuts through the original leaves and fills different regions.
					var corrected := ShaderMaterial.new()
					corrected.shader = CANOPY_SHADER
					corrected.set_shader_parameter("leaf_atlas", source.albedo_texture)
					corrected.set_shader_parameter("leaf_colour", Color(str(canopy.get("leaf_colour", "#75924d"))))
					corrected.set_shader_parameter("alpha_cutoff", source.alpha_scissor_threshold)
					corrected.set_shader_parameter("leaf_roughness", float(canopy.get("roughness", 0.91)))
					visual.set_surface_override_material(i, corrected)
					continue
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
	if _presentation_enabled("core_finish"):
		_finished_energy_seam()
		return
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
		poses.append(Transform3D(Basis.looking_at((q-p).normalized()).scaled_local(Vector3(2.4,2.4,p.distance_to(q))), (p+q)*0.5))
	_instances(self,poses,material)
	for y in [12,75,150,200]:
		var light := OmniLight3D.new()
		light.position = Vector3(0,y,0)
		light.light_color = Color("72bfff")
		light.light_energy = 4
		light.omni_range = 75
		add_child(light)


## Presentation reads the existing authoritative world flag. No local award,
## durable write, RNG consumption or shell geometry is introduced here.
func _finished_energy_seam() -> void:
	var settings: Dictionary = _presentation.core_finish
	_core_material = StandardMaterial3D.new()
	_core_material.albedo_color = Color(str(settings.colour))
	_core_material.emission_enabled = true
	_core_material.emission = Color(str(settings.emission))
	_core_material.emission_energy_multiplier = float(settings.energy)
	_core_material.roughness = 0.62
	var root := Node3D.new()
	root.name = "ForkedHeartCharge"
	add_child(root)
	var poses: Array[Transform3D] = []
	for index in 32:
		var p := Vector3(sin(index * 1.9) * 3.0, 8.0 + index * 7.0, 5.0)
		var q := Vector3(sin((index + 1) * 1.9) * 3.0, 15.0 + index * 7.0, 5.0)
		var width := float(settings.width_m)
		poses.append(_charge_pose(p,q,width))
		if index % 5 == 2:
			var tip := q + Vector3(-6.0 if index % 2 else 6.0, 5.0, 2.0)
			var branch_width := float(settings.branch_width_m)
			# A branch that would meet a real floor is left out: trimmed, its
			# end showed through the floor's well edge as a bright chip.
			if _charge_branch_tip(q,tip,branch_width).is_equal_approx(tip):
				poses.append(_charge_pose(q,tip,branch_width))
	_instances(root, poses, _core_material,_charge_mesh())
	for y in [12.0, 75.0, 150.0, 200.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(0.0, y, 5.0)
		light.light_color = Color(str(settings.emission))
		light.light_energy = float(settings.light_energy)
		light.omni_range = float(settings.light_range_m)
		light.shadow_enabled = false
		root.add_child(light)
		_core_lights.append(light)
	_refresh_core_state()


## Unit-height round charge sections end at their anchors. The configured
## width is the diameter, instead of being doubled by a default BoxMesh.
func _charge_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.5
	mesh.bottom_radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 1
	return mesh


func _charge_pose(start: Vector3,finish: Vector3,width: float) -> Transform3D:
	var axis := (finish-start).normalized()
	var side := axis.cross(Vector3.FORWARD).normalized()
	if side.length_squared() < 0.000001:
		side = Vector3.RIGHT
	var basis := Basis(side,axis,side.cross(axis).normalized())
	return Transform3D(basis.scaled_local(Vector3(width,start.distance_to(finish),width)),(start+finish)*0.5)


## The six visual branches query existing CPU floor faces once at build.
## This trims floor contact without changing any physical face or hazard.
func _charge_branch_tip(start: Vector3,finish: Vector3,width: float) -> Vector3:
	var crown := get_node_or_null("CrownChamber") as StaticBody3D
	if crown == null:
		return finish
	var axis := (finish-start).normalized()
	var reach := start.distance_to(finish)
	for child: Node in crown.get_children():
		if not child is CollisionShape3D:
			continue
		var collider := child as CollisionShape3D
		if not collider.shape is ConcavePolygonShape3D:
			continue
		var pose: Transform3D = crown.transform*collider.transform
		var faces := (collider.shape as ConcavePolygonShape3D).get_faces()
		for index in range(0,faces.size(),3):
			var a: Vector3 = pose*faces[index]
			var b: Vector3 = pose*faces[index+1]
			var c: Vector3 = pose*faces[index+2]
			var hit: Variant = Geometry3D.segment_intersects_triangle(start,finish,a,b,c)
			if not hit is Vector3:
				continue
			var point: Vector3 = hit
			var normal := (b-a).cross(c-a).normalized()
			var clearance := width*0.5/maxf(0.000001,absf(normal.dot(axis)))+0.001
			reach = minf(reach,maxf(0.0,start.distance_to(point)-clearance))
	return start+axis*reach


func _process(_delta: float) -> void:
	if _core_material != null:
		_refresh_core_state()
		_refresh_charge_visibility()


## The live charge is storm weather: it shows only while this client's local
## Surge is Building or Breaking. The cooled scar after release stays.
func _refresh_charge_visibility() -> void:
	var root := get_node_or_null("ForkedHeartCharge") as Node3D
	if root == null:
		return
	var surge := get_parent().get_node_or_null("StormwoodSurge") if get_parent() != null else null
	var phase := str(surge.get("phase")) if surge != null else "break"
	root.visible = charge_visible_for(phase, _core_released)


static func charge_visible_for(phase: String, released: bool) -> bool:
	return released or phase in ["building", "break"]


## Tree-local inner clearance of the hollow trunk (see _trunk_point), for the
## Surge rain mask: radius below/above the crown taper, taper heights, the
## crown's lean and the trunk top.
static func hollow_rain_volume() -> Dictionary:
	return {"radius_taper": Vector4(46.0, 13.0, 185.0, 250.0), "lean_top": Vector3(9.0, 6.0, 250.0)}


func _refresh_core_state() -> void:
	if not is_inside_tree():
		return
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	var flags: RefCounted = game.get("progression")
	if flags == null:
		return
	if flags.get_instance_id() == _core_flags_id and int(flags.get("revision")) == _core_revision:
		return
	_core_flags_id = flags.get_instance_id()
	_core_revision = int(flags.get("revision"))
	set_core_released(bool(flags.call("has", "stormwood:long_storm_ended")))


func set_core_released(released: bool) -> void:
	_core_released = released
	if _core_material == null:
		return
	var settings: Dictionary = _presentation.core_finish
	_core_material.albedo_color = Color(str(settings.cooled_colour if released else settings.colour))
	_core_material.emission_energy_multiplier = float(settings.cooled_energy if released else settings.energy)
	for light: OmniLight3D in _core_lights:
		light.visible = not released

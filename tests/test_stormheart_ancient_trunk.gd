extends "res://tests/test_case.gd"

const TREE := preload("res://scripts/world/stormheart_tree.gd")

class CandidateTree:
	extends "res://scripts/world/stormheart_tree.gd"
	var presentation_enabled := true
	func _read_presentation() -> Dictionary:
		var config := super._read_presentation()
		config.enabled = presentation_enabled
		for key: String in ["ancient_trunk","built_detail","branching_crown","canopy_atlas","visible_roots"]:
			config[key].enabled = true
		return config


func test_integrated_candidate_preserves_every_physical_shape() -> void:
	var baseline := CandidateTree.new()
	baseline.presentation_enabled = false
	baseline.build()
	var candidate := CandidateTree.new()
	candidate.build()
	assert_eq(_physics_signature(candidate),_physics_signature(baseline),
		"all floor, ramp and rail collision shapes/transforms must be byte-identical")
	assert_true(candidate.has_node("BuiltDetail"),"execute the enabled production dressing path")
	assert_false(baseline.has_node("BuiltDetail"),"explicit flag-off baseline preserves the original dressing path")
	assert_true(candidate.has_node("BranchCrownWestLow"),"exercise integrated crown and articulated trunk")
	var root_visual := candidate.get_node("ButtressRoot1") as MeshInstance3D
	var root_vertices: PackedVector3Array = root_visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var outer_reach := 0.0
	for vertex: Vector3 in root_vertices:
		assert_true(vertex.is_finite(), "visible root surface stays finite")
		outer_reach = maxf(outer_reach, Vector2(vertex.x, vertex.z).length())
	assert_true(outer_reach > 110.0, "candidate root visibly extends beyond the wide trunk")
	assert_eq(root_visual.find_children("*", "CollisionObject3D", true, false).size(), 0,
		"visible roots add no physical route or barrier")
	assert_eq(candidate.get_node("BuiltDetail").find_children("*","CollisionObject3D",true,false).size(),0,
		"detail must not introduce another physical route/barrier")
	_free_visuals(baseline)
	_free_visuals(candidate)


func test_articulated_bark_is_finite_and_preserves_full_upper_floor_clearance() -> void:
	var tree := CandidateTree.new()
	tree._presentation = tree._read_presentation()
	tree._bark = StandardMaterial3D.new()
	tree._bark.normal_enabled = true
	tree._split_bark_shell()
	var finite := true
	var tangent_stream_valid := true
	var winding := 0
	var smallest_radius := INF
	for name: String in ["EastLivingTrunk","WestLivingTrunk"]:
		var mesh := (tree.get_node(name) as MeshInstance3D).mesh
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
		assert_eq(tangents.size(), vertices.size() * 4, "normal-enabled bark supplies every vertex tangent")
		for vertex in vertices.size():
			var offset := vertex * 4
			var tangent := Vector3(tangents[offset], tangents[offset + 1], tangents[offset + 2])
			tangent_stream_valid = tangent_stream_valid and tangent.is_finite() \
				and absf(tangent.length() - 1.0) < 0.002 \
				and absf(normals[vertex].dot(tangent)) < 0.002 \
				and absf(tangents[offset + 3]) == 1.0
		for index in range(0,vertices.size(),3):
			var face := (vertices[index+2]-vertices[index]).cross(vertices[index+1]-vertices[index])
			for corner in 3:
				finite = finite and vertices[index+corner].is_finite() and normals[index+corner].is_finite()
				if face.length_squared()<0.000001 or face.dot(normals[index+corner])<=0.0:
					winding += 1
			var triangle: Array[Vector3] = [vertices[index],vertices[index+1],vertices[index+2]]
			var clipped := _clip_height(_clip_height(triangle,145.0,true),179.0,false)
			var polygon := PackedVector2Array()
			for at in clipped:
				polygon.append(Vector2(at.x,at.z))
			if polygon.size()<2:
				continue
			if polygon.size()>2 and Geometry2D.is_point_in_polygon(Vector2.ZERO,polygon):
				smallest_radius = 0.0
			for edge in polygon.size():
				var nearest := Geometry2D.get_closest_point_to_segment(Vector2.ZERO,polygon[edge],polygon[(edge+1)%polygon.size()])
				smallest_radius = minf(smallest_radius,nearest.length())
	assert_true(finite,"all generated bark vertices and smooth normals are finite")
	assert_true(tangent_stream_valid, "bark normal-map tangents stay finite, unit, perpendicular and signed")
	assert_eq(winding,0,"triangle winding must agree with every corner normal")
	assert_true(smallest_radius>=45.8,"complete bark triangles, clipped to the upper-floor slab, retain the44m arena clearance")
	_free_visuals(tree)


func test_nested_detail_and_trunk_flags_cannot_override_disabled_master() -> void:
	var tree := CandidateTree.new()
	tree._presentation = tree._read_presentation()
	tree._presentation.enabled = false
	assert_false(tree._presentation_enabled("ancient_trunk"),"master gates trunk geometry")
	assert_false(tree._presentation_enabled("built_detail"),"master gates architectural dressing")
	_free_visuals(tree)


func test_oblique_supports_reach_both_endpoints_without_skew() -> void:
	var tree := TREE.new()
	for direction: Vector3 in [Vector3(8,3,1),Vector3(-2,9,5),Vector3(5,0,-7)]:
		var start := Vector3(4,7,-2)
		var finish := start+direction
		var pose: Transform3D = tree._beam_pose(start,finish,0.35,0.7)
		assert_true((pose*Vector3(0,0,0.5)).distance_to(start)<0.00001,"box rear meets support anchor")
		assert_true((pose*Vector3(0,0,-0.5)).distance_to(finish)<0.00001,"box front meets deck anchor")
		assert_true(absf(pose.basis.x.dot(pose.basis.z))<0.00001,"support axes stay orthogonal")
		assert_true(is_equal_approx(pose.basis.y.length(),0.7),"support section height is independent of heading")
	tree.free()


func _clip_height(points: Array[Vector3],height: float,keep_above: bool) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for i in points.size():
		var a := points[i]
		var b := points[(i+1)%points.size()]
		var a_in := a.y>=height if keep_above else a.y<=height
		var b_in := b.y>=height if keep_above else b.y<=height
		if a_in:
			result.append(a)
		if a_in != b_in:
			result.append(a.lerp(b,(height-a.y)/(b.y-a.y)))
	return result


func _physics_signature(tree: Node) -> String:
	var shapes: Array = []
	for node: CollisionShape3D in tree.find_children("*","CollisionShape3D",true,false):
		var shape := node.shape
		var geometry: Variant = shape.get_faces() if shape is ConcavePolygonShape3D else (shape as BoxShape3D).size
		# Unnamed shape-node names contain per-instance Godot counters; compare
		# their stable parent path and child order, never that runtime identity.
		shapes.append([str(tree.get_path_to(node.get_parent())),node.get_index(),node.transform,node.get_parent().transform,geometry])
	return var_to_bytes(shapes).hex_encode().sha256_text()


func _free_visuals(tree: Node) -> void:
	var retained: Array[Material] = []
	for visual: MeshInstance3D in tree.find_children("*","MeshInstance3D",true,false):
		for surface in visual.get_surface_override_material_count():
			var material := visual.get_surface_override_material(surface)
			if material != null:
				retained.append(material)
				visual.set_surface_override_material(surface,null)
	tree.free()

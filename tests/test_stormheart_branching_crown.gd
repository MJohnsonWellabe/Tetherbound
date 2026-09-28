extends "res://tests/test_case.gd"

const TREE := preload("res://scripts/world/stormheart_tree.gd")
const PRESENTATION := "res://data/config/stormheart_presentation.json"


func test_branching_candidate_keeps_visuals_outside_playable_upper_floors() -> void:
	var tree := TREE.new()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION))
	config.enabled = true
	config.branching_crown.enabled = true
	config.canopy_atlas.enabled = true
	tree._presentation = config
	tree._bark = StandardMaterial3D.new()
	tree._living_crown()
	assert_true(tree.has_node("BranchCrownWestLow"), "exercise the enabled production crown path")
	assert_false(tree.has_node("CrownBough0"), "the candidate replaces rather than stacks the legacy crown")
	assert_eq(tree.find_children("*", "CollisionObject3D", true, false).size(), 0,
		"visual crown must not add collision or an implied physical route")
	var result := {"vertices": 0, "nonfinite": 0, "floor_intrusions": 0, "bad_winding": 0, "bad_faces": []}
	_check_geometry(tree, Transform3D.IDENTITY, result)
	assert_true(int(result.vertices) > 0, "audit actual installed leaf and generated branch surfaces")
	assert_eq(result.nonfinite, 0, "generated geometry must remain finite")
	assert_eq(result.floor_intrusions, 0, "no crown vertex enters the 46m protected cylinder at core/chamber height")
	assert_eq(result.bad_winding, 0, "branch triangle winding must agree with its outward normals: " + str(result.bad_faces))
	_free_visuals(tree)


func test_branching_flag_cannot_override_disabled_master() -> void:
	var tree := TREE.new()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION))
	config.enabled = false
	config.branching_crown.enabled = true
	tree._presentation = config
	tree._bark = StandardMaterial3D.new()
	tree._living_crown()
	assert_true(tree.has_node("CrownBough0"), "master disabled retains the legacy production crown")
	assert_false(tree.has_node("BranchCrownWestLow"), "nested flag alone cannot activate the new geometry")
	_free_visuals(tree)


func _check_geometry(node: Node, pose: Transform3D, result: Dictionary) -> void:
	if node is Node3D:
		pose *= (node as Node3D).transform
	if node is MeshInstance3D:
		var visual := node as MeshInstance3D
		for surface in visual.mesh.get_surface_count():
			var arrays := visual.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			result.vertices += vertices.size()
			for vertex in vertices:
				var at := pose * vertex
				if not at.is_finite():
					result.nonfinite += 1
				if at.y >= 145.0 and at.y <= 179.0 and Vector2(at.x, at.z).length() < 46.0:
					result.floor_intrusions += 1
			if str(node.name).begins_with("BranchCrown") or str(node.name).begins_with("BranchFork"):
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				for index in range(0, vertices.size(), 3):
					var face := (vertices[index + 2] - vertices[index]).cross(vertices[index + 1] - vertices[index])
					if face.length_squared() < 0.000001 or face.dot(normals[index]) <= 0.0:
						result.bad_winding += 1
						if result.bad_faces.size() < 5:
							result.bad_faces.append(str(node.name) + ":" + str(index / 3))
	for child in node.get_children():
		_check_geometry(child, pose, result)


func _free_visuals(tree: Node) -> void:
	# Match the existing dummy-renderer cleanup workaround for imported leaves.
	var retained: Array[Material] = []
	for visual: MeshInstance3D in tree.find_children("*", "MeshInstance3D", true, false):
		for surface in visual.get_surface_override_material_count():
			var material := visual.get_surface_override_material(surface)
			if material != null:
				retained.append(material)
				visual.set_surface_override_material(surface, null)
	tree.free()

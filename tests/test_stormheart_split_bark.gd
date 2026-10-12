extends "res://tests/test_case.gd"

const TREE := preload("res://scripts/world/stormheart_tree.gd")
const FINISH := preload("res://scripts/world/stormheart_split_bark.gd")
const EXISTING := preload("res://tests/test_stormheart_ancient_trunk.gd")


class SplitTree:
	extends "res://scripts/world/stormheart_tree.gd"
	var candidate := false
	func _read_presentation() -> Dictionary:
		var config := super._read_presentation()
		config.split_bark_finish.enabled = candidate
		return config


func test_split_finish_preserves_shipping_physics_and_original_wall_when_off() -> void:
	var baseline := SplitTree.new()
	baseline.build()
	var candidate := SplitTree.new()
	candidate.candidate = true
	candidate.build()
	var existing := EXISTING.new()
	assert_eq(existing._physics_signature(candidate), existing._physics_signature(baseline),
		"candidate preserves every shipping floor/ramp/rail shape and transform")
	assert_false(baseline.has_node("EastLivingTrunkExposedSplit"), "shipping disabled path has no candidate cap")
	assert_true(candidate.has_node("EastLivingTrunkExposedSplit"), "execute real candidate split geometry")
	assert_eq(candidate.get_node("EastLivingTrunkExposedSplit").find_children("*", "CollisionObject3D", true, false).size(), 0,
		"exposed wood cannot introduce physical support")
	existing._free_visuals(baseline)
	existing._free_visuals(candidate)


func test_split_mesh_is_finite_wound_and_retains_upper_floor_clearance() -> void:
	var tree := SplitTree.new()
	tree.candidate = true
	tree._presentation = tree._read_presentation()
	var settings: Dictionary = tree._presentation.split_bark_finish
	var invalid := 0
	var bad_winding := 0
	var intrusion := 0
	var cap_area := 0.0
	for side in 2:
		var surfaces := FINISH.build_surfaces(tree, side, 16.0, settings)
		for kind: String in ["wall", "lips"]:
			var surface: Dictionary = surfaces[kind]
			for index in range(0, surface.vertices.size(), 3):
				var a: Vector3 = surface.vertices[index]
				var b: Vector3 = surface.vertices[index + 1]
				var c: Vector3 = surface.vertices[index + 2]
				var face := (c - a).cross(b - a)
				for corner in 3:
					var at: Vector3 = surface.vertices[index + corner]
					var normal: Vector3 = surface.normals[index + corner]
					var uv: Vector2 = surface.uvs[index + corner]
					if not at.is_finite() or not normal.is_finite() or not uv.is_finite():
						invalid += 1
					if face.length_squared() < 0.000001 or face.dot(normal) <= 0.0:
						bad_winding += 1
					if at.y >= 145.0 and at.y <= 179.0 and Vector2(at.x, at.z).length() < 46.0:
						intrusion += 1
				if kind == "lips":
					var ua: Vector2 = surface.uvs[index]
					var ub: Vector2 = surface.uvs[index + 1]
					var uc: Vector2 = surface.uvs[index + 2]
					cap_area += absf((ub - ua).cross(uc - ua))
	assert_eq(invalid, 0, "no invalid geometry, normal or UV reaches native capture")
	assert_eq(bad_winding, 0, "all actual candidate triangles face their declared normals")
	assert_eq(intrusion, 0, "candidate does not grow into the existing inner46m upper-floor clearance")
	assert_true(cap_area > 1.0, "radial lip UVs expose real width instead of a collapsed bark column")
	tree.free()


func test_lip_boundaries_join_wall_without_narrowing_original_openings() -> void:
	var tree := SplitTree.new()
	tree.candidate = true
	tree._presentation = tree._read_presentation()
	var settings: Dictionary = tree._presentation.split_bark_finish
	var endpoint_error := 0.0
	var narrowed := 0
	for side in 2:
		var start := -PI * 0.5 + 0.27 if side == 0 else PI * 0.5 + 0.14
		var end := PI * 0.5 - 0.14 if side == 0 else PI * 1.5 - 0.27
		for height in range(5, 185, 5):
			for edge in 2:
				var angle := start if edge == 0 else end
				for inner in [false, true]:
					var wall := FINISH.wall_point(tree, angle, float(height), inner, start, end, side, settings)
					var cap := FINISH.lip_point(tree, 1.0 if inner else 0.0, float(height), edge, start, end, side, settings)
					endpoint_error = maxf(endpoint_error, wall.distance_to(cap))
					var delta := wrapf(atan2(wall.z, wall.x) - angle, -PI, PI)
					if (edge == 0 and delta < -0.00001) or (edge == 1 and delta > 0.00001):
						narrowed += 1
	assert_true(endpoint_error < 0.0001, "cap boundaries share exact wall endpoints; no detached skin")
	assert_eq(narrowed, 0, "both splits only recede into existing bark and never close the openings")
	tree.free()

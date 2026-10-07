extends "res://tests/test_case.gd"

## PERF (2026-10-05): a wild creature re-aims its ground telegraph every physics
## tick of its tell. aim() samples each distinct ground point once and skips a
## rebuild whose inputs are unchanged; the mesh it draws is unchanged.

const TELEGRAPH := preload("res://scripts/combat/enemy_pattern_telegraph.gd")


class CountingBody extends Node3D:
	var calls := 0
	func _ground_height(x: float, z: float) -> float:
		calls += 1
		return sin(x * 0.7) + cos(z * 0.3)


func _cue(shape: String) -> Array:
	var root := Node3D.new()
	var body := CountingBody.new()
	root.add_child(body)
	var profile := {"telegraph_shape": shape, "range": 6.0, "inner_radius_m": 1.5, "cone_degrees": 70.0}
	var cue: Node3D = TELEGRAPH.begin(body, profile, Vector3(1.0, 0.0, 2.0), Vector3(0.0, 0.0, 1.0),
		Vector3(1.0, 0.0, 6.0), {"segments": 48, "ground_lift_m": 0.09}, Color.RED)
	return [root, body, cue]


func _vertices(cue: Node3D) -> PackedVector3Array:
	var mesh: Mesh = cue.get("_mesh")
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func test_every_vertex_sits_on_the_measured_ground() -> void:
	for shape: String in ["ring", "cone"]:
		var made := _cue(shape)
		var verts := _vertices(made[2])
		assert_true(verts.size() > 0, shape + " drew geometry")
		var supports: Array[bool] = []
		var base_present := false
		var raised_present := false
		var outer_present := false
		var inner_present := false
		var left_present := false
		var right_present := false
		for v: Vector3 in verts:
			var ground := sin(v.x * 0.7) + cos(v.z * 0.3) + 0.09
			var elevation: float = v.y - ground
			var base := absf(elevation) <= 0.0001
			if base:
				assert_almost_eq(v.y, ground, 0.0001, "the skirt meets its own measured terrain point exactly")
				base_present = true
			else:
				assert_between(elevation, 0.001, 0.09 + 0.0001, "only a bounded crest may rise above its measured support")
				raised_present = true
			supports.append(base)
			var offset := Vector2(v.x - 1.0, v.z - 2.0)
			var radius := offset.length()
			# The existing 0.12 m border straddles the authored edge by 0.06 m.
			# Raised presentation cannot turn it into additional attack reach.
			assert_between(radius, 1.5 - 0.06 - 0.0001 if shape == "ring" else 0.0, 6.0 + 0.06 + 0.0001)
			outer_present = outer_present or (not base and absf(radius - 6.0) <= 0.0001)
			if shape == "ring":
				inner_present = inner_present or (not base and absf(radius - 1.5) <= 0.0001)
			else:
				var half_angle := deg_to_rad(35.0)
				var right_distance := offset.x * cos(half_angle) - offset.y * sin(half_angle)
				var left_distance := -offset.x * cos(half_angle) - offset.y * sin(half_angle)
				assert_true(right_distance <= 0.06 + 0.0001 and left_distance <= 0.06 + 0.0001,
					"the 70-degree cone keeps its authored sides and original border width")
				if not base and radius > 1.0:
					left_present = left_present or absf(left_distance) <= 0.0001
					right_present = right_present or absf(right_distance) <= 0.0001
		assert_true(base_present and raised_present, "both ground support and raised geometry must be present")
		assert_true(outer_present and (inner_present if shape == "ring" else left_present and right_present),
			"every authored strike boundary remains visibly represented")
		assert_eq(verts.size() % 3, 0)
		for first: int in range(0, verts.size() - 2, 3):
			assert_true(supports[first] or supports[first + 1] or supports[first + 2], "every raised face reaches a ground skirt")
			assert_false(supports[first] and supports[first + 1] and supports[first + 2], "no broad flat fill remains")
		(made[0] as Node).free()


func test_each_ground_point_is_sampled_once_per_aim() -> void:
	var made := _cue("ring")
	var verts := _vertices(made[2])
	var distinct := {}
	for v: Vector3 in verts:
		distinct[Vector2(v.x, v.z)] = true
	assert_true(int((made[1] as CountingBody).calls) <= distinct.size(),
		"%d samples for %d distinct points" % [(made[1] as CountingBody).calls, distinct.size()])
	(made[0] as Node).free()


func test_an_unchanged_aim_rebuilds_nothing() -> void:
	var made := _cue("cone")
	var body: CountingBody = made[1]
	var before := _vertices(made[2])
	var calls := body.calls
	(made[2] as Node3D).call("aim", Vector3(1.0, 0.0, 2.0), Vector3(0.0, 0.0, 1.0), Vector3(1.0, 0.0, 6.0))
	assert_eq(body.calls, calls, "identical inputs sample nothing")
	assert_eq(_vertices(made[2]), before, "and leave the same mesh")
	(made[2] as Node3D).call("aim", Vector3(1.0, 0.0, 2.0), Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, 6.0))
	assert_true(body.calls > calls, "a new heading re-samples")
	assert_true(_vertices(made[2]) != before, "and redraws")
	(made[0] as Node).free()

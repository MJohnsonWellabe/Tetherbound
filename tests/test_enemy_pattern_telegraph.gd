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
		for v: Vector3 in verts:
			assert_between(v.y, sin(v.x * 0.7) + cos(v.z * 0.3) + 0.09 - 0.0001,
				sin(v.x * 0.7) + cos(v.z * 0.3) + 0.09 + 0.0001)
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

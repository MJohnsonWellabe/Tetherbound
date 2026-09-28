extends SceneTree

## Scene-dependent companion to the pure geometry suite. The unit runner runs
## in _init, before Engine.get_main_loop exists; add_approach needs a mounted
## Node3D to convert its world-space endpoint into the tree's local space.
const CHECKS := preload("res://tests/test_stormheart_ancient_trunk.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var checks := CHECKS.new()
	var baseline := checks.TREE.new()
	var candidate := checks.CandidateTree.new()
	for tree: Node3D in [baseline,candidate]:
		root.add_child(tree)
		tree.position = Vector3(12,9,-30)
		tree.build()
		tree.add_approach(Vector3(0,-5,-120))
	checks.assert_eq(checks._physics_signature(candidate),checks._physics_signature(baseline),
		"mounted complete tree and world-space approach preserve every physical shape")
	var approach := candidate.get_node("OuterWorksApproach") as Node3D
	var visual := approach.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
	checks.assert_true(visual.material_override is ShaderMaterial,
		"approach created after build receives cut wood")
	var vertices: PackedVector3Array = visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	checks.assert_true(approach.to_global((vertices[0]+vertices[1])*0.5).distance_to(Vector3(0,-5,-120))<0.0001,
		"approach starts at requested world endpoint despite translated tree")
	checks.assert_true(approach.to_global((vertices[2]+vertices[5])*0.5).distance_to(candidate.to_global(Vector3(0,6,-44)))<0.0001,
		"approach ends at the existing outer deck edge")
	checks._free_visuals(baseline)
	checks._free_visuals(candidate)
	if checks.assertion_count != 4:
		checks.failures.append("expected exactly four scene assertions")
	for failure: String in checks.failures:
		push_error(failure)
	print("Stormheart mounted approach: %d assertions, %d failed"%[checks.assertion_count,checks.failures.size()])
	quit(0 if checks.failures.is_empty() else 1)

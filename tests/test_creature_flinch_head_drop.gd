extends "res://tests/test_case.gd"

# P2-016 G4 fallback (GPU, 25 Oct): from the high grunt camera and under the
# contact disc a few-pixel head dip did not read. The hit recoil now drops the
# head about a third of the body's height, pitched about the hindquarters,
# pushes away from the blow and squashes briefly on contact. Visual only: the
# art moves, the body and its collider do not.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const RUNS_IN_INITIALIZED_TREE := true

var _root: Node3D = null


func before_each() -> void:
	super.before_each()
	_root = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_root)


func after_each() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null
	super.after_each()


func test_the_recoil_drops_the_head_a_third_of_the_body_and_keeps_the_collider() -> void:
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(BODY)
	body.set("species_id", "mudsnout")
	_root.add_child(body)
	await _frames(3)
	var collider := _first_collider(body)
	var collider_before: Transform3D = collider.transform if collider != null else Transform3D()
	body.call("play_combat_flinch", -body.call("facing"))
	var art: Node3D = body.get("_combat_flinch_target")
	assert_true(art != null, "the recoil has an art node to move")
	if art == null:
		return
	var rest := art.transform  # the tween has not stepped yet
	var parent := art.get_parent() as Node3D
	var forward: Vector3 = parent.global_basis.inverse() * body.call("facing")
	forward.y = 0.0
	forward = forward.normalized()
	var half := float(body.call("_combat_flinch_body_length")) * 0.5
	var nose_rest := rest.origin + forward * half
	var hips_rest := rest.origin - forward * half
	await _frames(int(ceil(BODY.FLINCH_OUT_S * Engine.physics_ticks_per_second)))
	assert_true(art.transform.basis.y.length() < rest.basis.y.length() * 0.95,
		"the contact squashes the art down")
	await _frames(int(ceil(BODY.FLINCH_SQUASH_S * Engine.physics_ticks_per_second)) + 2)
	var moved := art.transform * (rest.affine_inverse() * nose_rest)
	var hips := art.transform * (rest.affine_inverse() * hips_rest)
	var height := float(body.call("body_height"))
	assert_true(nose_rest.y - moved.y >= 0.25 * height,
		"the head end drops %.2f m of a %.2f m body" % [nose_rest.y - moved.y, height])
	assert_almost_eq(hips.y, hips_rest.y, 0.02, "the hindquarters stay at their height")
	if collider != null:
		assert_true(collider.transform.is_equal_approx(collider_before), "the collider never moves on the body")
	await _frames(int(ceil((BODY.FLINCH_HOLD_S - BODY.FLINCH_SQUASH_S + BODY.FLINCH_BACK_S) * Engine.physics_ticks_per_second)) + 4)
	assert_true(art.transform.is_equal_approx(rest), "the art returns to its rest pose")


func _first_collider(node: Node) -> Node3D:
	for child in node.get_children():
		if child is CollisionShape3D:
			return child
	return null


func _frames(count: int) -> void:
	for _i in count:
		await (Engine.get_main_loop() as SceneTree).physics_frame

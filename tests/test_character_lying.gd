extends "res://tests/test_case.gd"

## OF8: the wake beat's fake lying pose (`character_model.gd::set_lying`).
##
## Neither human rig has a lie-down clip — confirmed against
## `tools/art_pipeline/blender/animate_humanoid.py`'s `CLIPS` dict, which
## bakes exactly idle/walk/sprint/jump/throw onto the trainer/Grandpa rig —
## and there is no owner-supplied reference board to generate a sixth
## against (CLAUDE.md: no Meshy generation without one). `set_lying` fakes
## the pose with a rotation on the loaded art instead, so what is worth
## pinning down here is the geometry contract, not a look: does the pose
## actually land the character flat, head toward the pillow end, face up
## rather than into the mattress — and does letting go put them back on
## their feet.
##
## D02's scope is "pure logic, not scenes, not rendering" — this instantiates
## a bare `character_model.gd` node off-tree and reads its transform, the
## same shape `smoke_art.gd` uses for the trainer's animation player, just
## without booting the whole meadows scene the way that file does. Whether
## the pose reads as convincing in a screenshot is a `tests/smoke_opening.gd`
## and (for anything visual) `visual-judge` question, not this file's.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")


func _build_trainer() -> Node3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	model.call("build", "trainer")
	return model


func test_starts_standing() -> void:
	var model := _build_trainer()
	assert_false(bool(model.call("is_lying")), "a freshly built body should not default to lying")
	var head: Vector3 = (model.call("art_transform") as Transform3D).basis * Vector3.UP
	assert_almost_eq(head.y, 1.0, 0.01, "standing: the head end should point straight up")
	model.free()


func test_set_lying_true_tips_the_body_flat() -> void:
	var model := _build_trainer()
	model.call("set_lying", true)
	assert_true(bool(model.call("is_lying")))

	var basis: Basis = (model.call("art_transform") as Transform3D).basis
	var head := basis * Vector3.UP
	var face := basis * Vector3(0.0, 0.0, -1.0)

	# Flat: the head end is no longer pointing up at all.
	assert_almost_eq(head.y, 0.0, 0.01, "lying: the head end should be horizontal, not still pointing up")
	# Toward the headboard/pillow end (-Z), the same end BedPrompt sits over —
	# see set_lying()'s own comment for how that was checked, not assumed.
	assert_almost_eq(head.z, -1.0, 0.01, "lying: the head end should point toward -Z (the pillow end)")
	# Face up at the ceiling, not down into the mattress.
	assert_almost_eq(face.y, 1.0, 0.01, "lying: the face should point up, not down into the mattress")
	model.free()


func test_set_lying_false_stands_the_body_back_up() -> void:
	var model := _build_trainer()
	model.call("set_lying", true)
	model.call("set_lying", false)
	assert_false(bool(model.call("is_lying")))

	var head: Vector3 = (model.call("art_transform") as Transform3D).basis * Vector3.UP
	assert_almost_eq(head.y, 1.0, 0.01, "getting up should restore the standing orientation exactly")
	model.free()


func test_set_lying_is_a_no_op_when_already_in_that_state() -> void:
	# Guards against a test (and a caller) that only ever calls set_lying(true)
	# once and would not notice a version that silently re-applies the
	# rotation, drifting it, on every repeated call.
	var model := _build_trainer()
	model.call("set_lying", true)
	var first: Transform3D = model.call("art_transform")
	model.call("set_lying", true)
	var second: Transform3D = model.call("art_transform")
	assert_almost_eq(first.origin.distance_to(second.origin), 0.0, 0.0001)
	assert_true(first.basis.is_equal_approx(second.basis), "calling set_lying(true) twice should not re-rotate the body")
	model.free()

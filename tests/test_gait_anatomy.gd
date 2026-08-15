extends "res://tests/test_case.gd"

## MQ1A's replacement for test_gait_arm_taming.gd, which pinned a load-time
## hack (`_tame_gait_arm_swing`) that halved the baked arm swing toward the
## clip's frame-0 pose. The hack is gone — the pose it preserved carried the
## actual owner-reported defect, a permanently backward-hyperextended elbow,
## keyed on the wrong sign of this rig's forearm axis — and the clips are now
## authored on render-verified axes (animate_humanoid.py's AXES table).
##
## What is worth pinning now is ANATOMY, not amplitude: the axis conventions
## this rig actually has (verified by tools/_probe_pose_axes.gd renders) are
##   forearm X: negative = elbow flexion, positive = impossible backward bend
##   shin    X: positive = knee flexion,  negative = impossible forward bend
## measured in the bone's own pose space (rest-relative). A re-bake that gets
## a sign wrong reads as "unnatural" in renders in a way nobody spots for
## months — that is exactly what happened — so these tests fail loudly on the
## sign itself, straight off the baked keys, no render needed.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")

## Degrees of slack for numeric noise in rest-relative decomposition. Real
## violations are tens of degrees; this only forgives quantisation.
const EPSILON_DEG := 1.0

var _model: Node3D = null
var _anim: AnimationPlayer = null
var _skeleton: Skeleton3D = null


func before_each() -> void:
	_model = Node3D.new()
	_model.set_script(CHARACTER_MODEL)
	assert_true(bool(_model.call("build", "trainer")), "trainer failed to build")
	_anim = _model.call("animation_player")
	_skeleton = _find_skeleton(_model)
	assert_true(_skeleton != null, "trainer has no skeleton")


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


## The pose-space X rotation (degrees) of every key on the named bone's
## rotation track: the baked key is rest * pose, so pose comes back out as
## rest^-1 * key. Only X is authored on limb bones, so the euler read is
## unambiguous.
func _pose_x_degrees(animation: Animation, bone_name: String) -> Array[float]:
	var idx := _skeleton.find_bone(bone_name)
	if idx < 0:
		return []
	var rest := Quaternion(_skeleton.get_bone_rest(idx).basis)
	var values: Array[float] = []
	for track_idx in animation.get_track_count():
		if animation.track_get_type(track_idx) != Animation.TYPE_ROTATION_3D:
			continue
		if not str(animation.track_get_path(track_idx)).ends_with(bone_name):
			continue
		for k in animation.track_get_key_count(track_idx):
			var key_value: Quaternion = animation.track_get_key_value(track_idx, k)
			values.append(rad_to_deg((rest.inverse() * key_value).get_euler().x))
	return values


func _clip(name: String) -> Animation:
	var animation := _anim.get_animation(name)
	assert_true(animation != null, "trainer has no %s clip" % name)
	return animation


func test_elbows_never_hyperextend_in_any_clip() -> void:
	# Positive pose X on a forearm bends the elbow BACKWARD, which no human
	# elbow does. The pre-MQ1A clips held +50..+68 through the whole gait.
	for clip_name in ["walk", "sprint", "jump", "throw", "idle"]:
		var animation := _clip(clip_name)
		if animation == null:
			continue
		for bone in ["LeftForeArm", "RightForeArm"]:
			for x in _pose_x_degrees(animation, bone):
				assert_true(x <= EPSILON_DEG,
					"%s keys %s at %+.1f deg — a backward-hyperextended elbow" % [clip_name, bone, x])


func test_knees_never_bend_forward_in_the_gaits() -> void:
	# Negative pose X on a shin folds the knee FORWARD. The pre-MQ1A gait
	# keyed its whole swing-leg fold negative, which read as a straight
	# recovery leg skimming the ground.
	for clip_name in ["walk", "sprint"]:
		var animation := _clip(clip_name)
		if animation == null:
			continue
		for bone in ["LeftLeg", "RightLeg"]:
			for x in _pose_x_degrees(animation, bone):
				assert_true(x >= -EPSILON_DEG,
					"%s keys %s at %+.1f deg — a forward-bent knee" % [clip_name, bone, x])


func test_the_gait_arms_actually_swing() -> void:
	# The zombie guard, inverted from the old taming test: nothing at load
	# time may shrink the authored swing back toward a mannequin carry. The
	# authored jog swings the shoulder through ~44 degrees; assert well under
	# that so retunes have room, but a re-tame (0.45x) or a freeze fails.
	var animation := _clip("walk")
	if animation == null:
		return
	for bone in ["LeftArm", "RightArm"]:
		var xs := _pose_x_degrees(animation, bone)
		assert_true(not xs.is_empty(), "walk has no %s keys" % bone)
		var spread: float = xs.max() - xs.min()
		assert_true(spread >= 20.0,
			"walk %s only swings %.1f deg — arms are frozen or re-tamed" % [bone, spread])


func test_the_gaits_flex_the_stance_knee() -> void:
	# Weight is what the loading flexion sells: the old gait held the stance
	# knee at a constant 6 deg and read as a pogo. Both gaits must bend the
	# knee meaningfully somewhere in the cycle (jog loads ~32, sprint ~44,
	# swing folds far past that).
	for clip_name in ["walk", "sprint"]:
		var animation := _clip(clip_name)
		if animation == null:
			continue
		for bone in ["LeftLeg", "RightLeg"]:
			var xs := _pose_x_degrees(animation, bone)
			assert_true(not xs.is_empty(), "%s has no %s keys" % [clip_name, bone])
			assert_true(xs.max() >= 30.0,
				"%s %s peaks at %.1f deg — the knee never really folds" % [clip_name, bone, xs.max()])

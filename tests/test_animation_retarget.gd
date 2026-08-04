extends "res://tests/test_case.gd"

## The retarget maths, on two skeletons built here rather than on the knight.
##
## Every one of these asserts about a DIRECTION IN SPACE — where a bone ends up
## pointing once the whole chain is composed — because that is the only thing
## the eye reads and the only thing that was ever wrong. Asserting on the
## quaternion a formula happens to emit would have passed just as happily with
## the arms behind the character's back, which is how that shipped.
##
## The two rigs here are deliberately the same shape as the real ones: the
## source is a T-POSE with its arm along +X, the target is an A-POSE with its
## arm 45° down, the target has an extra unmapped `shoulder` link the source
## does not have, and the two arm bones' local frames are rolled 90° apart.
## Those are the three things that broke it.

const RETARGET := preload("res://scripts/player/animation_retarget.gd")

const TARGET_PATH := "Armature/Skeleton3D"
const ARM := ["upperarm", "forearm"]
const MAP := {"chest": "chest", "upperarm": "upper_arm", "forearm": "forearm"}

## Direction tolerance. Generous by degree standards and still far tighter than
## any error that reaches the screen: the shipped bug was 95°, the A-pose
## double-count 52°.
const TOLERANCE := 0.5


# --- the rigs -------------------------------------------------------------


## The source: `chest` -> `upperarm` -> `forearm`, arm straight out along +X.
##
## Its arm bones' local X points along world +Z, which is the KayKit convention
## and 90° of roll away from the target's.
func _source() -> Skeleton3D:
	var skeleton := Skeleton3D.new()
	_bone(skeleton, "chest", -1, Quaternion.IDENTITY, Vector3(0.0, 1.0, 0.0))
	# +Y turned onto +X: the T-pose.
	_bone(skeleton, "upperarm", 0, _aim(Vector3(1.0, 0.0, 0.0), 0.0), Vector3(0.1, 0.2, 0.0))
	_bone(skeleton, "forearm", 1, Quaternion.IDENTITY, Vector3(0.0, 0.3, 0.0))
	return skeleton


## The target: an extra unmapped `shoulder`, an A-pose 45° down, and its arm
## bones rolled 90° about their own axis relative to the source's.
func _target() -> Skeleton3D:
	var skeleton := Skeleton3D.new()
	_bone(skeleton, "chest", -1, Quaternion.IDENTITY, Vector3(0.0, 1.0, 0.0))
	_bone(skeleton, "shoulder", 0, Quaternion.IDENTITY, Vector3(0.1, 0.2, 0.0))
	var down := Vector3(1.0, -1.0, 0.0).normalized()
	_bone(skeleton, "upper_arm", 1, _aim(down, PI * 0.5), Vector3.ZERO)
	_bone(skeleton, "forearm", 2, Quaternion.IDENTITY, Vector3(0.0, 0.3, 0.0))
	return skeleton


func _bone(
	skeleton: Skeleton3D, name: String, parent: int, rotation: Quaternion, origin: Vector3
) -> void:
	skeleton.add_bone(name)
	var index := skeleton.find_bone(name)
	if parent >= 0:
		skeleton.set_bone_parent(index, parent)
	skeleton.set_bone_rest(index, Transform3D(Basis(rotation), origin))


## A rotation that points the bone's local +Y along `direction`, then rolls it
## `roll` radians about itself. The roll is what makes two rigs disagree about
## which way "bend the elbow" is without disagreeing about where the arm points.
func _aim(direction: Vector3, roll: float) -> Quaternion:
	var to := direction.normalized()
	var axis := Vector3.UP.cross(to)
	var swing := (
		Quaternion.IDENTITY if axis.length() < 0.0001
		else Quaternion(axis.normalized(), Vector3.UP.angle_to(to))
	)
	return (swing * Quaternion(Vector3.UP, roll)).normalized()


# --- driving them ---------------------------------------------------------


## A one-key clip holding each named bone at a rotation, on tracks shaped the
## way the real libraries' tracks are shaped.
##
## A bone with no track of its own is not retargeted at all — it holds its rest
## and follows its parent. That is a real case, and it is also the reason this
## takes a dictionary: a chain test that animates only the parent never gives
## the child a track, so the child's own maths is never run and a bug in it
## passes. That is exactly what happened here.
func _clip(rotations: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	for bone: String in rotations.keys():
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Rig/Skeleton3D:%s" % bone))
		animation.rotation_track_insert_key(track, 0.0, (rotations[bone] as Quaternion).normalized())
	return animation


## `bone`'s orientation in skeleton space, with `poses` applied.
##
## Composed by hand down the chain rather than read off a live Skeleton3D, so
## the assertion covers the maths rather than the engine's node lifecycle — and
## so unmapped links like `shoulder` contribute their rest, which is exactly
## what they do in the game.
func _frame(skeleton: Skeleton3D, bone: String, poses: Dictionary) -> Basis:
	var chain: Array[int] = []
	var walk := skeleton.find_bone(bone)
	while walk != -1:
		chain.push_front(walk)
		walk = skeleton.get_bone_parent(walk)
	var global := Transform3D.IDENTITY
	for i: int in chain:
		var rest := skeleton.get_bone_rest(i)
		var rotation: Quaternion = poses.get(
			skeleton.get_bone_name(i), rest.basis.get_rotation_quaternion()
		)
		global = global * Transform3D(Basis(rotation), rest.origin)
	return global.basis.orthonormalized()


## Where `bone` ends up pointing — its own axis, which on both rigs is local +Y.
func _direction(skeleton: Skeleton3D, bone: String, poses: Dictionary) -> Vector3:
	return _frame(skeleton, bone, poses).y


## The local rotation that means "this bone is exactly at its rest pose".
##
## Not `IDENTITY`. A rotation key holds the bone's LOCAL rotation, and a bone
## whose rest is a T-pose aim has a rest key of that aim — feeding identity
## instead asks for a 90° rotation away from rest and gets one.
func _rest_key(skeleton: Skeleton3D, bone: String) -> Quaternion:
	return skeleton.get_bone_rest(skeleton.find_bone(bone)).basis.get_rotation_quaternion()


## Run source rotations through the retargeter and read back what the target
## bones were told to do.
func _run(rotations: Dictionary, align: PackedStringArray) -> Dictionary:
	var source := _source()
	var target := _target()
	var out: Dictionary = RETARGET.retarget(
		{"clip": _clip(rotations)},
		source,
		target,
		MAP,
		NodePath(TARGET_PATH),
		1.0,
		align
	)
	var poses: Dictionary = {}
	var animation: Animation = out.get("clip", null)
	if animation != null:
		for track in animation.get_track_count():
			var path := animation.track_get_path(track)
			poses[str(path.get_subname(0))] = animation.track_get_key_value(track, 0)
	source.free()
	target.free()
	return poses


func _degrees(a: Vector3, b: Vector3) -> float:
	return rad_to_deg(a.angle_to(b))


# --- the plane the motion happens in --------------------------------------


func test_a_swing_moves_the_target_arm_the_same_way_in_space() -> void:
	# THE SHIPPED BUG. The source's arm bone has its local X along world +Z, the
	# target's has it across the chest, so a key that says "swing about local X"
	# used to arrive as a swing about a different world axis entirely — the arm
	# flapped sideways instead of forward and sat behind the body.
	#
	# Swing the source's upper arm about its own local X and check the target's
	# arm moved to the same place in the world, not merely by the same angle.
	var swing := Quaternion(Vector3.RIGHT, deg_to_rad(40.0))
	var poses := _run({"upperarm": swing}, PackedStringArray(ARM))
	var source := _source()
	var target := _target()
	var want := _direction(source, "upperarm", {"upperarm": swing})
	var got := _direction(target, "upper_arm", poses)
	assert_true(
		_degrees(want, got) < TOLERANCE,
		"aligned arm should point where the source points: want %s got %s (%.1f deg apart)"
			% [want, got, _degrees(want, got)]
	)
	source.free()
	target.free()


func test_the_rest_pose_difference_does_not_leak_into_the_motion() -> void:
	# The amount a bone MOVES BY has to survive the rests disagreeing, or every
	# clip plays at the wrong amplitude. Measured as the rotation in WORLD space
	# between two poses, which is the invariant a retarget actually preserves —
	# the swept angle of the bone's own axis is not, because how far a given
	# axis travels under a rotation depends on where that axis started.
	var a := Quaternion(Vector3.RIGHT, deg_to_rad(10.0))
	var b := Quaternion(Vector3.RIGHT, deg_to_rad(50.0))
	var source := _source()
	var target := _target()
	var source_travel := _turn(
		_frame(source, "upperarm", {"upperarm": a}),
		_frame(source, "upperarm", {"upperarm": b})
	)
	for align: PackedStringArray in [PackedStringArray(), PackedStringArray(ARM)]:
		var target_travel := _turn(
			_frame(target, "upper_arm", _run({"upperarm": a}, align)),
			_frame(target, "upper_arm", _run({"upperarm": b}, align))
		)
		assert_almost_eq(
			target_travel, source_travel, TOLERANCE,
			"the target must turn by the source's angle (aligned: %s)" % [not align.is_empty()]
		)
	assert_true(source_travel > 1.0, "the fixture must actually move the arm")
	source.free()
	target.free()


## Degrees of rotation between two orientations.
func _turn(a: Basis, b: Basis) -> float:
	var between := (b * a.inverse()).get_rotation_quaternion().normalized()
	return rad_to_deg(2.0 * acos(clampf(absf(between.w), 0.0, 1.0)))


# --- T-pose against A-pose ------------------------------------------------


func test_an_unaligned_bone_keeps_its_own_rest_pose() -> void:
	# The default: the target holds ITS rest and receives the delta. With a
	# delta of nothing it must sit exactly in its own A-pose, NOT be dragged
	# into the source's T-pose.
	var source := _source()
	var target := _target()
	var poses := _run({"upperarm": _rest_key(source, "upperarm")}, PackedStringArray())
	var rest := _direction(target, "upper_arm", {})
	var got := _direction(target, "upper_arm", poses)
	assert_true(
		_degrees(rest, got) < TOLERANCE,
		"an unaligned bone at the source's rest must sit at its own rest, %.1f deg off"
			% _degrees(rest, got)
	)
	source.free()


func test_an_aligned_bone_is_aimed_by_the_clip_instead() -> void:
	# The A-pose fix. The knight rests 52° lower than the rig the clips are
	# authored on, so adding the clip's "lower the arm from T-pose" to his
	# already-lowered rest put his hands across his groin. Listed bones take
	# their AIM from the source instead.
	var source := _source()
	var target := _target()
	var poses := _run({"upperarm": _rest_key(source, "upperarm")}, PackedStringArray(ARM))
	var want := _direction(source, "upperarm", {})
	var got := _direction(target, "upper_arm", poses)
	var rest := _direction(target, "upper_arm", {})
	assert_true(
		_degrees(want, got) < TOLERANCE,
		"an aligned bone must take the source's aim, %.1f deg off" % _degrees(want, got)
	)
	assert_true(
		_degrees(rest, got) > 10.0,
		"this rig's rests differ by 45 deg, so alignment must visibly move the arm"
	)
	source.free()
	target.free()


# --- the chain ------------------------------------------------------------


func test_a_child_of_an_aligned_bone_is_not_dragged_off_by_it() -> void:
	# Re-aiming a parent moves its children with it, and each child's own maths
	# has to undo the parent's NEW orientation rather than the one its rest pose
	# describes. Skipping that left the upper arms exactly right, the forearms
	# 18° out and the hands 55° out — visibly wrong, silently.
	#
	# BOTH bones are driven. The forearm needs a track of its own or its maths
	# never runs: with only the parent animated it inherits the parent's frame
	# and lands in the right place however wrong the child code is.
	var source := _source()
	var target := _target()
	var driven := {
		"upperarm": Quaternion(Vector3.RIGHT, deg_to_rad(35.0)),
		"forearm": _rest_key(source, "forearm") * Quaternion(Vector3.RIGHT, deg_to_rad(50.0)),
	}
	var poses := _run(driven, PackedStringArray(ARM))
	var want := _direction(source, "forearm", driven)
	var got := _direction(target, "forearm", poses)
	assert_true(
		_degrees(want, got) < TOLERANCE,
		"the forearm must follow its re-aimed parent: %.1f deg off" % _degrees(want, got)
	)
	source.free()
	target.free()


func test_an_unmapped_link_between_two_mapped_bones_is_accounted_for() -> void:
	# The target has a `shoulder` the source rig does not have at all. It holds
	# its rest and its contribution is already inside the global rests, so the
	# arm must land in the right place regardless of it — this is the case that
	# makes local rests alone insufficient.
	var target := _target()
	assert_eq(
		target.get_bone_name(target.get_bone_parent(target.find_bone("upper_arm"))),
		"shoulder",
		"the fixture must actually have the unmapped link this is about"
	)
	var swing := Quaternion(Vector3.RIGHT, deg_to_rad(25.0))
	var source := _source()
	var want := _direction(source, "upperarm", {"upperarm": swing})
	var got := _direction(target, "upper_arm", _run({"upperarm": swing}, PackedStringArray(ARM)))
	assert_true(
		_degrees(want, got) < TOLERANCE,
		"an unmapped intermediate must not displace the arm: %.1f deg off" % _degrees(want, got)
	)
	source.free()
	target.free()


# --- the silent no-ops ----------------------------------------------------


func test_tracks_address_a_bone_on_a_node_and_not_a_property() -> void:
	# `node_path:bone` drives a bone. A bare `:bone` is a PROPERTY lookup on the
	# animation root: it finds nothing, animates nothing, and reports nothing.
	# This has been the failure here once already.
	var poses := _run({"upperarm": Quaternion(Vector3.RIGHT, 0.4)}, PackedStringArray(ARM))
	assert_true(poses.has("upper_arm"), "the upper arm must have been given a track")

	var source := _source()
	var target := _target()
	var out: Dictionary = RETARGET.retarget(
		{"clip": _clip({"upperarm": Quaternion(Vector3.RIGHT, 0.4)})},
		source, target, MAP, NodePath(TARGET_PATH), 1.0, PackedStringArray()
	)
	var animation: Animation = out["clip"]
	var path := str(animation.track_get_path(0))
	assert_eq(path, "%s:upper_arm" % TARGET_PATH, "a bone track needs its node path")
	source.free()
	target.free()


func test_a_clip_touching_no_mapped_bone_is_refused_rather_than_added() -> void:
	# A clip with no usable track plays the bind pose while reporting success.
	# Returning nothing is what lets the caller say so.
	var source := _source()
	var target := _target()
	var out: Dictionary = RETARGET.retarget(
		{"clip": _clip({"tail": Quaternion(Vector3.RIGHT, 0.4)})},
		source, target, MAP, NodePath(TARGET_PATH), 1.0, PackedStringArray()
	)
	assert_false(out.has("clip"), "a clip that drives nothing must not be handed back")
	source.free()
	target.free()


func test_a_map_naming_a_bone_nobody_has_is_reported() -> void:
	var source := _source()
	var target := _target()
	var problems := RETARGET.unmapped(source, target, {"upperarm": "no_such_bone"})
	assert_eq(problems.size(), 1, "one bad target name, one complaint")
	assert_true(
		str(problems[0]).contains("no_such_bone"), "the complaint must name the bone"
	)
	assert_eq(
		RETARGET.unmapped(source, target, MAP).size(), 0, "the real map must be clean"
	)
	source.free()
	target.free()


func test_a_map_that_inverts_two_bones_ancestry_is_reported() -> void:
	# The chain maths asks the source who a bone's parent is and then undoes
	# that bone's correction on the target. A map that reverses the relationship
	# between the two rigs breaks that assumption quietly.
	var source := _source()
	var target := _target()
	var inverted := {"chest": "forearm", "upperarm": "chest"}
	var problems := RETARGET.unmapped(source, target, inverted)
	assert_true(
		problems.size() > 0, "an inverted ancestry must be reported, not absorbed"
	)
	source.free()
	target.free()

extends RefCounted

## Replay one skeleton's animation on a different skeleton.
##
## The trainer's clips live on a 23-bone rig (`hips`, `chest`, `upperarm.l`) and
## the character we want to wear them is a 176-bone Rigify skeleton whose bones
## are called `DEF-spine`, `DEF-upper_arm.L`. They share no names at all, so
## merging a library across produces a character that stands in its bind pose
## while an AnimationPlayer reports twenty-five clips playing perfectly.
##
## What this does, per bone, is the only part worth understanding:
##
##     D  = source_rest⁻¹ * source_local        # the clip's delta from its rest
##     Q  = source_global_rest⁻¹ * target_global_rest
##     target_local = target_rest * (Q⁻¹ * D * Q)
##
## The source clip's rotation is turned into a DELTA FROM ITS OWN REST POSE, and
## that delta is applied to the target's rest pose. Copying the raw rotation
## instead is the classic retarget failure: the two rigs hold their arms at
## different angles at rest, so an "arms down" pose authored on one becomes
## "arms out sideways" on the other, and every clip is wrong by a constant.
##
## `Q` is the part that is easy to leave out, and leaving it out is what put the
## trainer's arms behind his back for the whole of M0–M7.
##
## A delta is a rotation OF SO MANY DEGREES ABOUT AN AXIS, and that axis is
## written in the bone's own local frame. Applying `D` directly assumes the two
## rigs agree about where that frame points. They do not, and there is no reason
## they should: KayKit rests its arms in a T-pose with the bone's local X along
## world +Z, Rigify rests them in a 52° A-pose with local X across the chest —
## a residual roll of ~95° about the arm itself once the A-pose is discounted.
## So `upperarm.l`'s "swing 30° forward about local X" arrived on the knight as
## "swing 30° OUTWARD", and his walk became a hands-on-hips strut with both arms
## trailing behind the hips. The legs, whose two rigs agree to within 8°, were
## fine throughout — which is exactly why this reads as "the arms are weird"
## rather than as "the retarget is broken".
##
## `Q` is the rotation from the source bone's rest frame to the target bone's,
## both measured in their own skeleton's space. Conjugating by it re-expresses
## the delta's AXIS in the target's frame while leaving its ANGLE alone, so the
## motion happens in the plane the animator drew it in. When the two rigs share
## a frame `Q` is identity and this collapses to the old expression.
##
## ── The second half: rests that are different POSES, not different conventions
##
## Transferring the delta perfectly still leaves the character wrong by whatever
## its rest pose disagrees with the source's, because "delta from rest" only
## means the same thing on both bodies if both rests mean the same thing.
##
## They do not here. KayKit rests its arms in a T-POSE, straight out sideways,
## so every clip's arm track carries ~78° of "lower the arm to the side" before
## it carries any swing. The knight already rests in a 52° A-POSE. Adding one to
## the other lowered his arms 130° and crossed his hands in front of his groin —
## the delta transfer measurably exact, the pose measurably 52° wrong, at every
## frame of every clip by the same amount.
##
## So for those bones the target is driven to the direction the SOURCE bone
## points, rather than to its own rest plus a delta. `C` becomes the part of `Q`
## that spins about the bone's own axis, which is the part that carries the roll
## convention; the part that would have re-aimed the bone is dropped, and the
## aim comes from the clip instead.
##
## This is NOT applied everywhere, and the difference matters. The spine's rests
## disagree too — 14.5° at the pelvis — but that is Rigify modelling a spinal
## curve where KayKit stacks four straight bones, which is the knight's build
## and not a pose to be overwritten; forcing it flat would straighten a back
## the mesh was skinned around. Legs disagree by 5°, which is nothing. Which
## bones are which is a fact about two art packs, so it is named in data
## (`retarget_align_rest`) rather than inferred from a threshold that would only
## ever have been tuned to make these two rigs work.
##
## Only ROTATION is retargeted. Bone positions are skeleton geometry — copying
## them stretches the target's limbs to the source's proportions — with one
## exception: the ROOT's position carries the clip's travel and its vertical
## bob. That one is treated exactly like the rotations, as a delta from its own
## rest position, scaled by the height ratio and added to the target's rest.
## An absolute copy would drop the character through its own hips by however
## much the two rigs disagree about where a pelvis sits.
##
## This cannot be verified by a test that asserts the clip exists. Every failure
## mode here — a twisted forearm, sliding hips, one bone mapped to its mirror —
## produces a clip that exists, plays, and is wrong. It is checked by rendering
## the character in each pose and looking (`tools/preview_trainer.gd`).

## Track types worth moving. Scale is deliberately excluded: a source rig that
## animates bone scale is squashing its own proportions, which will not
## translate to a body of different proportions.
const ROTATION := Animation.TYPE_ROTATION_3D
const POSITION := Animation.TYPE_POSITION_3D


## Build retargeted copies of `clips` for `target`, mapping bones by `bone_map`.
##
## `bone_map` is `{source_bone: target_bone}` and lives in data, because which
## bone is which is a fact about two art packs and not about this algorithm.
##
## `align_rest` holds the SOURCE names of the bones whose two rest poses are
## different poses rather than different conventions — see the header. Those are
## aimed by the clip; everything else keeps its own rest and is given the delta.
##
## `target_path` is the path from the AnimationPlayer's root to the target
## Skeleton3D — `Armature/Skeleton3D`, not the bone. Godot resolves a bone track
## by taking everything before the colon as a NODE and everything after it as a
## bone on that node, so a path of `:DEF-spine` addresses a property called
## `DEF-spine` on the root node, finds none, and animates nothing at all while
## reporting no error. That is the same silent no-op this whole file exists to
## prevent, one layer up.
static func retarget(
	clips: Dictionary,
	source: Skeleton3D,
	target: Skeleton3D,
	bone_map: Dictionary,
	target_path: NodePath,
	height_ratio: float = 1.0,
	align_rest: PackedStringArray = PackedStringArray()
) -> Dictionary:
	var out: Dictionary = {}
	if source == null or target == null or bone_map.is_empty():
		return out

	for name: String in clips.keys():
		var animation: Animation = clips[name]
		if animation == null:
			continue
		var moved := _retarget_one(
			animation, source, target, bone_map, target_path, height_ratio, align_rest
		)
		if moved != null:
			out[name] = moved
	return out


static func _retarget_one(
	animation: Animation,
	source: Skeleton3D,
	target: Skeleton3D,
	bone_map: Dictionary,
	target_path: NodePath,
	height_ratio: float,
	align_rest: PackedStringArray
) -> Animation:
	var out := Animation.new()
	out.length = animation.length
	out.loop_mode = animation.loop_mode
	out.step = animation.step

	var prefix := str(target_path)
	var kept := 0
	for track in animation.get_track_count():
		var type := animation.track_get_type(track)
		if type != ROTATION and type != POSITION:
			continue

		# Track paths look like `Rig_Medium/Skeleton3D:hips`. Only the bone matters.
		var path := animation.track_get_path(track)
		var bone := str(path.get_subname(0) if path.get_subname_count() > 0 else "")
		if bone == "" or not bone_map.has(bone):
			continue

		var target_bone := str(bone_map[bone])
		var target_index := target.find_bone(target_bone)
		var source_index := source.find_bone(bone)
		if target_index < 0 or source_index < 0:
			continue

		# Position tracks are dropped for every bone except the root, where they
		# carry the clip's travel rather than the skeleton's shape.
		var is_root: bool = target.get_bone_parent(target_index) == -1
		if type == POSITION and not is_root:
			continue

		var new_track := out.add_track(type)
		out.track_set_path(new_track, NodePath("%s:%s" % [prefix, target_bone]))

		if type == ROTATION:
			# Both halves are per-bone constants, so they are built once here
			# rather than once per key.
			var source_rest := _rotation(source.get_bone_rest(source_index))
			var before := _before(source, target, bone_map, align_rest, bone, source_index, target_index)
			var after := _correction(source, target, bone_map, align_rest, bone)
			for key in animation.track_get_key_count(track):
				var time := animation.track_get_key_time(track, key)
				var value: Quaternion = animation.track_get_key_value(track, key)
				var delta := source_rest.inverse() * value
				out.rotation_track_insert_key(
					new_track, time, (before * delta * after).normalized()
				)
		else:
			# No frame change here. A position key is written in the PARENT's
			# frame, and this branch only ever runs for a bone whose target has no
			# parent — so the frame on both sides is the skeleton's own, and the
			# two skeletons already agree about which way is up and which is
			# forward. A bone track would need the parents' global rests; a root
			# track does not, and inventing the general case would be untested
			# code on a path nothing takes.
			var source_origin: Vector3 = source.get_bone_rest(source_index).origin
			var target_origin: Vector3 = target.get_bone_rest(target_index).origin
			for key in animation.track_get_key_count(track):
				var time := animation.track_get_key_time(track, key)
				var value: Vector3 = animation.track_get_key_value(track, key)
				out.position_track_insert_key(
					new_track, time, target_origin + (value - source_origin) * height_ratio
				)
		kept += 1

	# A clip with no mapped tracks is a clip that will play as a bind pose. Say
	# so rather than adding it — a silent no-op here is exactly the failure this
	# whole file exists to avoid.
	if kept == 0:
		return null
	return out


## `C` for one bone: what its animated orientation is offset by, relative to the
## source bone's.
##
## `Q` — the whole frame change — leaves the target sitting at its own rest when
## the source sits at its own rest, so the target keeps its rest pose and merely
## receives the motion. `Q`'s twist re-aims it: the twist cannot turn the bone's
## axis (that is what makes it a twist), so the axis has nowhere to come from
## but the clip, and the target ends up pointing exactly where the source points
## while still rolling by the rests' convention difference.
static func _correction(
	source: Skeleton3D,
	target: Skeleton3D,
	bone_map: Dictionary,
	align_rest: PackedStringArray,
	bone: String
) -> Quaternion:
	var source_index := source.find_bone(bone)
	var target_index := target.find_bone(str(bone_map.get(bone, "")))
	if source_index < 0 or target_index < 0:
		return Quaternion.IDENTITY
	# From the GLOBAL rests — the local rests describe a bone relative to its
	# parent, and the two rigs do not share parents. The knight's arm hangs off
	# `DEF-shoulder.L`, which the 23-bone rig does not have at all; only the
	# global rests put both bones in a space where their frames can be compared.
	var frame := (
		_rotation(source.get_bone_global_rest(source_index)).inverse()
		* _rotation(target.get_bone_global_rest(target_index))
	).normalized()
	return _twist(frame) if bone in align_rest else frame


## Everything that multiplies onto the LEFT of a bone's delta.
##
##     before = target_rest * B⁻¹ * (B_parent * C_parent⁻¹ * A_parent⁻¹) * A
##
## The bracket is the part that is easy to miss, and it is identity for every
## bone whose parent was not re-aimed — which is why the first version of this,
## written as `target_rest * Q⁻¹`, put the upper arms exactly right and left the
## forearms 18° and the hands 55° out.
##
## A child's local rotation is measured against its parent. Re-aiming a parent
## by 52° moves the child with it, and the child's own maths then has to undo
## the parent's NEW orientation rather than the one its rest pose describes. The
## bracket is exactly that undo: it cancels when `C_parent` is `Q_parent` and
## contributes the parent's re-aim when it is not.
##
## `parent` here means the nearest mapped ANCESTOR, not the immediate parent —
## the target rig puts `DEF-upper_arm.L.001` between forearm and upper arm, and
## bones like that are unmapped, hold their rest, and are already accounted for
## in the global rests either side.
static func _before(
	source: Skeleton3D,
	target: Skeleton3D,
	bone_map: Dictionary,
	align_rest: PackedStringArray,
	bone: String,
	source_index: int,
	target_index: int
) -> Quaternion:
	var target_rest := _rotation(target.get_bone_rest(target_index))
	var a := _rotation(source.get_bone_global_rest(source_index))
	var b := _rotation(target.get_bone_global_rest(target_index))

	var bracket := Quaternion.IDENTITY
	var parent := _mapped_ancestor(source, bone_map, source_index)
	if parent != "":
		var parent_source := source.find_bone(parent)
		var parent_target := target.find_bone(str(bone_map[parent]))
		if parent_source >= 0 and parent_target >= 0:
			bracket = (
				_rotation(target.get_bone_global_rest(parent_target))
				* _correction(source, target, bone_map, align_rest, parent).inverse()
				* _rotation(source.get_bone_global_rest(parent_source)).inverse()
			)
	return (target_rest * b.inverse() * bracket * a).normalized()


## The nearest ancestor of `index` that the map names, or "" if it has none.
static func _mapped_ancestor(source: Skeleton3D, bone_map: Dictionary, index: int) -> String:
	var walk := source.get_bone_parent(index)
	while walk != -1:
		var name := source.get_bone_name(walk)
		if bone_map.has(name):
			return name
		walk = source.get_bone_parent(walk)
	return ""


## The part of `rotation` that spins about the bone's own axis.
##
## Bones point along their local +Y on both of these rigs — every bone's child
## rests at `(0, length, 0)` — so a rotation about Y is exactly the one that
## leaves the bone AIMED where it was and only rolls it. Extracting it is one
## line: zero the components about the other two axes and re-normalise.
##
## Used to build a correction that cannot re-aim the target bone, so its aim has
## to come from the clip. The degenerate case is a frame difference of 180°
## about an axis square to the bone, where no roll is recoverable; identity is
## the honest answer there rather than a normalised zero.
static func _twist(rotation: Quaternion) -> Quaternion:
	var length := sqrt(rotation.y * rotation.y + rotation.w * rotation.w)
	if length < 0.0001:
		return Quaternion.IDENTITY
	return Quaternion(0.0, rotation.y / length, 0.0, rotation.w / length)


## A transform's rotation alone, with any scale in it discarded.
##
## `Basis.get_rotation_quaternion()` on a scaled basis is not a rotation, and a
## rest pose with non-uniform scale in it is common enough in exported rigs to
## be worth one call rather than one debugging session.
static func _rotation(pose: Transform3D) -> Quaternion:
	return pose.basis.orthonormalized().get_rotation_quaternion()


## Bones in `bone_map` that do not exist on both skeletons.
##
## Reported rather than skipped quietly, because a mapping typo removes one limb
## from every clip at once and leaves everything else working — which reads as
## "the animation is a bit odd" rather than as a bug with a name.
static func unmapped(source: Skeleton3D, target: Skeleton3D, bone_map: Dictionary) -> Array[String]:
	var missing: Array[String] = []
	for from: String in bone_map.keys():
		if source != null and source.find_bone(from) < 0:
			missing.append("source has no bone '%s'" % from)
		var to := str(bone_map[from])
		if target != null and target.find_bone(to) < 0:
			missing.append("target has no bone '%s'" % to)
	if source != null and target != null:
		missing.append_array(_crossed(source, target, bone_map))
	return missing


## Mappings where the two skeletons disagree about who is whose ancestor.
##
## `_before` undoes the parent's correction, and "the parent" means the nearest
## mapped ancestor on the SOURCE side. That is only the same bone on the target
## side if the map preserves ancestry. It does here — the knight's extra
## `DEF-shoulder.L` and `DEF-upper_arm.L.001` are unmapped links INSIDE the same
## chain — but a future map that sent `chest` below `upperarm.l` on one rig and
## above it on the other would produce a character that animates, looks subtly
## wrong, and reports nothing. Cheap to check, so it is checked.
static func _crossed(source: Skeleton3D, target: Skeleton3D, bone_map: Dictionary) -> Array[String]:
	var crossed: Array[String] = []
	for from: String in bone_map.keys():
		var source_index := source.find_bone(from)
		var target_index := target.find_bone(str(bone_map[from]))
		if source_index < 0 or target_index < 0:
			continue
		var ancestor := _mapped_ancestor(source, bone_map, source_index)
		if ancestor == "":
			continue
		var expected := target.find_bone(str(bone_map[ancestor]))
		if expected < 0:
			continue
		var walk := target.get_bone_parent(target_index)
		while walk != -1 and walk != expected:
			walk = target.get_bone_parent(walk)
		if walk != expected:
			crossed.append(
				"'%s' sits under '%s' on the source rig but '%s' is not above '%s' on the target"
				% [from, ancestor, bone_map[ancestor], bone_map[from]]
			)
	return crossed

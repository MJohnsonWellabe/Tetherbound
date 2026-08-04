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
##     target_local = target_rest * (source_rest⁻¹ * source_local)
##
## The source clip's rotation is turned into a DELTA FROM ITS OWN REST POSE, and
## that delta is applied to the target's rest pose. Copying the raw rotation
## instead is the classic retarget failure: the two rigs hold their arms at
## different angles at rest, so an "arms down" pose authored on one becomes
## "arms out sideways" on the other, and every clip is wrong by a constant.
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
	height_ratio: float = 1.0
) -> Dictionary:
	var out: Dictionary = {}
	if source == null or target == null or bone_map.is_empty():
		return out

	for name: String in clips.keys():
		var animation: Animation = clips[name]
		if animation == null:
			continue
		var moved := _retarget_one(animation, source, target, bone_map, target_path, height_ratio)
		if moved != null:
			out[name] = moved
	return out


static func _retarget_one(
	animation: Animation,
	source: Skeleton3D,
	target: Skeleton3D,
	bone_map: Dictionary,
	target_path: NodePath,
	height_ratio: float
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
			# The rest-pose delta, computed once per bone rather than per key.
			var source_rest: Quaternion = source.get_bone_rest(source_index).basis.get_rotation_quaternion()
			var target_rest: Quaternion = target.get_bone_rest(target_index).basis.get_rotation_quaternion()
			var to_target := target_rest * source_rest.inverse()
			for key in animation.track_get_key_count(track):
				var time := animation.track_get_key_time(track, key)
				var value: Quaternion = animation.track_get_key_value(track, key)
				out.rotation_track_insert_key(new_track, time, (to_target * value).normalized())
		else:
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
	return missing

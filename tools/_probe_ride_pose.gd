extends SceneTree

## Throwaway measurement for W14-RIDING: which LOCAL axis, and which sign, is
## flexion on the trainer rig once Godot has imported it?
##
##   godot --headless --path . --script tools/_probe_ride_pose.gd
##
## `animate_humanoid.py`'s AXES table is stated in BLENDER pose-euler terms and
## cannot be trusted verbatim after glTF's axis conversion. The authored walk
## and jump clips are the ground truth that survived the conversion, so this
## reads the delta rotation between each clip's own extreme poses and the rest
## pose and prints it as axis-angle in the bone's local frame. Whatever axis
## the knee swings on in `walk` is the axis a seated knee has to bend on.

const MODEL := "res://assets/characters/trainer/trainer_lod0.glb"
const BONES := ["Hips", "Spine", "Spine02", "LeftUpLeg", "LeftLeg", "LeftFoot",
	"RightUpLeg", "RightLeg", "RightFoot", "LeftArm", "LeftForeArm",
	"RightArm", "RightForeArm"]


func _init() -> void:
	var packed: PackedScene = load(MODEL) as PackedScene
	var art: Node3D = packed.instantiate()
	root.add_child(art)
	var skeleton := _skeleton(art)
	if skeleton == null:
		print("no Skeleton3D")
		quit(1)
		return
	print("bones: ", skeleton.get_bone_count())
	var names: Array = []
	for i in skeleton.get_bone_count():
		names.append(skeleton.get_bone_name(i))
	print("names: ", names)

	var anim := _player(art)
	if anim == null:
		print("no AnimationPlayer")
		quit(1)
		return
	print("clips: ", anim.get_animation_list())

	for clip in ["walk", "jump"]:
		if not anim.has_animation(clip):
			continue
		var animation := anim.get_animation(clip)
		print("\n=== %s (%.2fs) ===" % [clip, animation.length])
		for bone_name in BONES:
			var index := skeleton.find_bone(bone_name)
			if index < 0:
				continue
			var rest: Quaternion = skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
			var extreme_angle := 0.0
			var extreme_axis := Vector3.ZERO
			var extreme_at := 0.0
			var samples := 24
			for s in samples:
				var t := animation.length * float(s) / float(samples)
				anim.play(clip)
				anim.seek(t, true)
				var pose: Quaternion = skeleton.get_bone_pose_rotation(index)
				var delta := rest.inverse() * pose
				if delta.w < 0.0:
					delta = -delta
				var angle := delta.get_angle()
				if absf(angle) > absf(extreme_angle):
					extreme_angle = angle
					extreme_axis = delta.get_axis()
					extreme_at = t
			print("  %-14s max %6.1f deg about (%5.2f, %5.2f, %5.2f) at t=%.2f"
				% [bone_name, rad_to_deg(extreme_angle), extreme_axis.x,
					extreme_axis.y, extreme_axis.z, extreme_at])
	quit(0)


func _skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _skeleton(child)
		if found != null:
			return found
	return null


func _player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _player(child)
		if found != null:
			return found
	return null

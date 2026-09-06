extends SceneTree
## Which sign of a local-X pitch on 'neck'/'head' raises the burrowback's head?
func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var packed: PackedScene = load("res://assets/creatures/tetherbound/burrowback/models/creature_burrowback_lod0.glb")
	var node: Node = packed.instantiate()
	root.add_child(node)
	await process_frame
	var sk: Skeleton3D = node.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = node.find_children("*", "AnimationPlayer", true, false)[0]
	ap.play("idle")
	ap.advance(0.5)
	await process_frame
	var head := sk.find_bone("head")
	var neck := sk.find_bone("neck")
	var spine := sk.find_bone("spine")
	print("idle head y=%.3f z=%.3f neck y=%.3f spine y=%.3f pelvis y=%.3f" % [
		sk.get_bone_global_pose(head).origin.y, sk.get_bone_global_pose(head).origin.z,
		sk.get_bone_global_pose(neck).origin.y, sk.get_bone_global_pose(spine).origin.y,
		sk.get_bone_global_pose(sk.find_bone("pelvis")).origin.y])
	for axis_name in ["x", "z"]:
		for sgn in [1.0, -1.0]:
			ap.stop()
			ap.play("idle")
			ap.advance(0.5)
			var axis := Vector3.RIGHT if axis_name == "x" else Vector3.BACK
			var q := sk.get_bone_pose_rotation(neck)
			sk.set_bone_pose_rotation(neck, q * Quaternion(axis, deg_to_rad(30.0 * sgn)))
			sk.force_update_all_bone_transforms()
			print("neck %s %+.0f -> head y=%.3f z=%.3f" % [axis_name, sgn * 30.0,
				sk.get_bone_global_pose(head).origin.y, sk.get_bone_global_pose(head).origin.z])
			sk.set_bone_pose_rotation(neck, q)
	print("skeleton path=%s motion_scale=%.3f" % [str(sk.get_path()), sk.motion_scale])
	quit(0)

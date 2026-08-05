extends SceneTree
## Where is the trainer's hip, as a fraction of his fitted 1.8m?
func _init() -> void:
	await process_frame
	var world := Node3D.new()
	root.add_child(world)
	var player: CharacterBody3D = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	await process_frame
	await process_frame
	var to_body := player.global_transform.affine_inverse()
	for node in player.find_children("*", "Skeleton3D", true, false):
		var skel: Skeleton3D = node
		for i in skel.get_bone_count():
			var name := skel.get_bone_name(i)
			if name in ["DEF-spine", "DEF-spine.001", "DEF-spine.003", "DEF-spine.006",
					"DEF-thigh.L", "DEF-shin.L", "DEF-foot.L"]:
				var p: Vector3 = (to_body * (skel.global_transform * skel.get_bone_global_pose(i))).origin
				print("  %-16s y %.3f  z %.3f" % [name, p.y, p.z])
	quit(0)

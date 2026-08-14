extends SceneTree

## What does the player actually see, and how big is the trainer really?
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/diag_player_view.gd
##
## Boots the real game scene, lets it settle, then reports the trainer's
## measured world-space size, the camera's distance from the player, and every
## creature's position — and saves the frame from the PLAYER's camera.
##
## `tools/survey.gd` captures fixed viewpoints for judging composition; it
## cannot answer "why does the character fill the screen", because it never
## looks through the camera the player looks through.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/diag"
const SETTLE_FRAMES := 150


func _init() -> void:
	_run()


func _world_size(node: Node3D) -> AABB:
	# Render-space: the node-chain AABB is blind to a skin's scale, which is
	# exactly the bug this diagnostic exists to see. See render_bounds.gd.
	const RB := preload("res://scripts/characters/render_bounds.gd")
	return node.global_transform * (RB.measure(node) as AABB)


func _meshes(node: Node) -> Array:
	var found: Array = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null and (node as MeshInstance3D).visible:
		found.append(node)
	for child in node.get_children():
		found.append_array(_meshes(child))
	return found


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await process_frame

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	var camera: Camera3D = null
	if rig != null:
		for child in rig.get_children():
			if child is Camera3D:
				camera = child as Camera3D

	print("\n================ PLAYER VIEW DIAGNOSTIC ================")
	if player != null:
		print("player at      %s" % str(player.global_position))
		var model: Node3D = player.get_node_or_null(^"Model") as Node3D
		if model != null:
			var box := _world_size(model)
			print("trainer visible box  size=(%.2f, %.2f, %.2f)  bottom y=%.2f" % [
				box.size.x, box.size.y, box.size.z, box.position.y])
			for child in model.get_children():
				var n: Node3D = child as Node3D
				if n != null:
					print("   child %-18s visible=%s scale=%s" % [
						n.name, str(n.visible), str(n.scale)])
	if camera != null:
		print("camera at      %s" % str(camera.global_position))
		if player != null:
			print("camera is %.2fm from the player, %.2fm above him" % [
				camera.global_position.distance_to(player.global_position),
				camera.global_position.y - player.global_position.y])

	var director: Node = world.get_node_or_null(^"EncounterDirector")
	if director != null and director.has_method("wild_creatures"):
		var creatures: Array = director.call("wild_creatures")
		print("wild creatures: %d" % creatures.size())
		for p in creatures:
			var body: Node3D = p as Node3D
			if body != null:
				var b := _world_size(body)
				print("   %-12s at %s  visible box height %.2fm  dist %.1fm" % [
					body.name, str(body.global_position), b.size.y,
					body.global_position.distance_to(player.global_position) if player else -1.0])

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var image := root.get_texture().get_image()
	var path := "%s/player_view.png" % OUT
	image.save_png(path)
	print("frame -> %s" % path)
	print("=======================================================")
	quit()

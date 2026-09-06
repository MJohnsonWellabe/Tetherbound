## CLOUDREACH-DRESS-0906 scratch probe. The summit frame shows pale salmon
## shapes inside and around the aviary. `_recolour_bird` is in the tree and is
## called, so either it is not reaching the songbird's surfaces or the shapes
## are not the birds. Ask the scene which.
##   godot --headless --path . --script tools/_probe_cloudreach_aviary_birds.gd
extends SceneTree

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game != null and game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
		game.set("current_realm", "cloudreach")
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _f in 8:
		await process_frame

	var interior := world.find_child("AviaryInterior", true, false)
	if interior == null:
		print("NO AviaryInterior")
		quit(1)
		return
	var birds := 0
	var reported := 0
	for child: Node in interior.get_children():
		var anchor := child as Node3D
		if anchor == null:
			continue
		# Birds are the anchors holding a songbird model; identify by the mesh
		# count rather than the name, since Godot renames colliding siblings.
		var meshes: Array[Node] = anchor.find_children("*", "MeshInstance3D", true, false)
		var is_bird := false
		for m: Node in meshes:
			if str((m as MeshInstance3D).mesh.resource_path).contains("ollie") \
					or str(m.name).to_lower().contains("ollie"):
				is_bird = true
		if str(anchor.name).contains("Bird"):
			is_bird = true
		if not is_bird:
			continue
		birds += 1
		if reported >= 3:
			continue
		reported += 1
		print("BIRD %s at %s  meshes=%d" % [anchor.name, anchor.global_position, meshes.size()])
		for m: Node in meshes:
			var mi := m as MeshInstance3D
			if mi.mesh == null:
				continue
			for surface in mi.mesh.get_surface_count():
				var over := mi.get_surface_override_material(surface)
				var act := mi.get_active_material(surface)
				var over_desc := "none"
				if over is StandardMaterial3D:
					over_desc = "override albedo=%s" % str((over as StandardMaterial3D).albedo_color)
				var act_desc := "?"
				if act is StandardMaterial3D:
					var std := act as StandardMaterial3D
					act_desc = "active albedo=%s tex=%s" % [str(std.albedo_color),
						"yes" if std.albedo_texture != null else "no"]
				print("    %s surf%d  %s | %s" % [mi.name, surface, over_desc, act_desc])
	print("total bird anchors in AviaryInterior: %d" % birds)
	quit(0)

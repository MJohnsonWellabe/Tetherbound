extends "res://tools/_capture_creature_roster.gd"

func _run() -> void:
	await process_frame
	_world = Node3D.new()
	root.add_child(_world)
	_build_environment()
	for i in BOOT_FRAMES:
		await physics_frame
	var out := "res://ralph/reports/VISUAL/galecrest-rebuild/variants-r2"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var checks: Array[Dictionary] = []
	for variant: String in ["vivid", "shiny", "alpha"]:
		for yaw: float in [0.0, 135.0]:
			var body := _spawn_creature("galecrest", variant == "shiny", PAIR_CREATURE_POS, yaw)
			if variant == "alpha":
				body.call("set_alpha", true)
			for i in SETTLE_FRAMES:
				await physics_frame
			var textures: Array[String] = []
			for child in body.find_children("*", "MeshInstance3D", true, false):
				var mesh := child as MeshInstance3D
				if mesh.mesh == null:
					continue
				for surface in mesh.mesh.get_surface_count():
					var mat := mesh.get_active_material(surface) as StandardMaterial3D
					if mat != null and mat.albedo_texture != null:
						textures.append(mat.albedo_texture.resource_path)
			var expected := "galecrest_extracted_base_color_%s.png" % variant
			var routed := false
			for path: String in textures:
				if path.ends_with(expected):
					routed = true
			checks.append({"variant": variant, "yaw": yaw, "textures": textures, "correct_uv_texture": routed})
			if not routed:
				push_error("wrong texture routing for " + variant)
			await _capture("%s/%s-%03d.png" % [out, variant, int(yaw)])
			body.queue_free()
			await process_frame
	var file := FileAccess.open(out + "/routing.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(checks, "\t"))
	quit(0)

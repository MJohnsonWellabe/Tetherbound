extends SceneTree

## Does DirectionalLight3D.shadow_opacity actually reach the Compatibility
## renderer? Minimal scene, no project content: a lit plane, a box casting a
## shadow onto it, and two renders differing ONLY in shadow_opacity.
## If the mean luminance of the shadowed region is identical, the property is
## a no-op here and VIS-WORLD's weather claim is wrong.

func _init() -> void:
	var vp := root
	vp.transparent_bg = false
	var world := Node3D.new()
	vp.add_child(world)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.4, 0.5, 0.7)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.45)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	plane.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 0.6)
	plane.material_override = mat
	world.add_child(plane)

	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3, 3, 3)
	box.mesh = bm
	box.position = Vector3(0, 1.5, 0)
	world.add_child(box)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(-35.0), 0.0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	world.add_child(sun)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 7, 12)
	cam.look_at(Vector3(2, 0, -2), Vector3.UP)
	world.add_child(cam)
	cam.current = true

	for pass_i in 2:
		sun.shadow_opacity = 1.0 if pass_i == 0 else 0.0
		for i in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.save_png("res://shots/_so_%s.png" % ("full" if pass_i == 0 else "zero"))
		print("wrote shadow_opacity=%.1f" % sun.shadow_opacity)
	quit(0)

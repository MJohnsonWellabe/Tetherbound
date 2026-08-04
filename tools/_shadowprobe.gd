extends SceneTree

## Does a SKINNED mesh cast a directional shadow under the Compatibility
## renderer?
##
## Round 4 reported that no character casts a shadow while trees beside them do.
## Every mesh involved has cast_shadow=1, and the only structural difference is
## that trees render through a MultiMesh and characters through a Skeleton3D.
## If Compatibility simply does not put skinned meshes in the shadow map, that
## finding is an artefact of the survey harness (D06) and not a defect in the
## game — and "fixing" it would fix nothing.
##
## So: one skinned character and one static box, same light, same ground. Count
## dark pixels under each.

const KNIGHT := "res://assets/characters/knight.glb"


func _init() -> void:
	_run()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.3, 0.4, 0.6)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.5)
	e.ambient_light_energy = 0.6
	env.environment = e
	world.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(-30.0), 0.0)
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	world.add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	ground.mesh = plane
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.9, 0.9, 0.9)
	ground.material_override = white
	world.add_child(ground)

	# The skinned one.
	var knight: Node3D = (load(KNIGHT) as PackedScene).instantiate()
	world.add_child(knight)
	knight.position = Vector3(-2.5, 0.0, 0.0)

	# The static control, deliberately the same rough size.
	var box := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(0.6, 1.9, 0.4)
	box.mesh = cube
	world.add_child(box)
	box.position = Vector3(2.5, 0.95, 0.0)

	var camera := Camera3D.new()
	camera.fov = 50.0
	world.add_child(camera)
	camera.make_current()
	camera.position = Vector3(0.0, 6.5, 8.0)
	camera.look_at(Vector3(0.0, 0.4, 0.0), Vector3.UP)

	for i in 60:
		await physics_frame
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("no image")
		quit(1)
		return
	image.save_png("res://shots/_diag/shadowprobe.png")

	# Ground is 0.9 albedo under a 2.0 sun; anything meaningfully darker than the
	# lit plane and not the subject itself is a shadow.
	var w := image.get_width()
	var h := image.get_height()
	print("skinned side: %d shadow px" % _dark(image, 0, int(w * 0.5), int(h * 0.55), h))
	print("static  side: %d shadow px" % _dark(image, int(w * 0.5), w, int(h * 0.55), h))
	quit(0)


func _dark(image: Image, x0: int, x1: int, y0: int, y1: int) -> int:
	var count := 0
	for y in range(y0, y1, 2):
		for x in range(x0, x1, 2):
			var c := image.get_pixel(x, y)
			var v: float = maxf(c.r, maxf(c.g, c.b))
			# Below the lit ground, above black: a shadow on a white plane.
			if v > 0.20 and v < 0.72:
				count += 1
	return count

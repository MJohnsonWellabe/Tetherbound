extends SceneTree
## ROUND-4-0906 diagnostic render: does `world.ground_height_at()` agree with
## the terrain Terrain3D actually draws in front of the Warrens' mouth? Drops a
## grid of small bright spheres at ground_height_at()+0.05 across the threshold
## and photographs it from above the mouth looking out, plus the 03 stand.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/_probe_warrens_threshold_render.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/warrens_threshold_probe"

func _init() -> void:
	_run()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 200:
		await physics_frame
	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
	if look != null:
		look.set_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var park := Vector2(-373.0, 2476.0) + Vector2(600.0, 600.0)
		var park_y := float(world.call("ground_height_at", park.x, park.y))
		player.global_position = Vector3(park.x, park_y + 0.2, park.y)
		player.visible = false
		player.set_physics_process(false)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.0, 1.0)
	mat.emission_energy_multiplier = 2.0
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	var x := -8.0
	while x <= 8.0:
		var z := -20.0
		while z <= -6.0:
			var g := warrens.to_global(Vector3(x, 0.0, z))
			var ground := float(world.call("ground_height_at", g.x, g.z))
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.material_override = mat
			mi.global_position = Vector3(g.x, ground + 0.05, g.z)
			world.add_child(mi)
			z += 2.0
		x += 2.0
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var stands := [
		{"name": "above-looking-out", "eye": Vector3(0.0, 9.0, -4.0), "target": Vector3(0.0, 0.0, -16.0)},
		{"name": "side-low", "eye": Vector3(-11.0, 2.5, -12.0), "target": Vector3(2.0, 0.5, -10.0)},
	]
	for stand: Dictionary in stands:
		var eye_local: Vector3 = stand["eye"]
		var g := warrens.to_global(Vector3(eye_local.x, 0.0, eye_local.z))
		var ground := float(world.call("ground_height_at", g.x, g.z))
		camera.global_position = Vector3(g.x, ground + eye_local.y, g.z)
		var t_local: Vector3 = stand["target"]
		var t := warrens.to_global(Vector3(t_local.x, 0.0, t_local.z))
		var tg := float(world.call("ground_height_at", t.x, t.z))
		camera.look_at(Vector3(t.x, tg + t_local.y, t.z), Vector3.UP)
		for i in 20:
			await physics_frame
		if look != null:
			look.call("apply_time", "day")
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT_DIR, stand["name"]])
		print("  wrote %s" % stand["name"])
	print("PROBE RENDER DONE")
	quit(0)

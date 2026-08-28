extends SceneTree
## Render the TM orb pickup as the game builds it, at a few type colours.
const PICKUP := preload("res://scripts/world/tm_pickup.gd")
func _init() -> void:
	var root := get_root()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.18, 0.20, 0.16)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.57, 0.6)
	e.ambient_light_energy = 1.0
	env.environment = e
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-44.0), deg_to_rad(140.0), 0.0)
	sun.light_energy = 1.35
	root.add_child(sun)
	var cam := Camera3D.new()
	cam.current = true
	root.add_child(cam)
	# look_at() requires the node to be IN the tree; calling it before
	# add_child silently leaves the camera pointing down -Z at nothing.
	cam.look_at_from_position(Vector3(0.0, 0.16, 0.42), Vector3(0.0, 0.10, 0.0), Vector3.UP)
	var colours := {"nature": Color(0.42,0.72,0.30), "fire": Color(0.88,0.28,0.18), "water": Color(0.22,0.55,0.92)}
	var out := "shots/tm_orb"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + out))
	for name in colours:
		for c in root.get_children():
			if c is MeshInstance3D: c.queue_free()
		await process_frame
		var n := Node3D.new(); n.set_script(PICKUP)
		root.add_child(n)
		# drive the private builder with a known colour
		var mat: StandardMaterial3D = n.call("_orb_material", colours[name])
		var packed: PackedScene = load("res://assets/props/tm_orb/tm_orb.glb")
		var mi: Node3D = packed.instantiate()
		for ch in mi.get_children():
			if ch is MeshInstance3D: (ch as MeshInstance3D).material_override = mat
		mi.scale = Vector3.ONE * (0.20 / 1.899)
		mi.position = Vector3(0.0, 0.10, 0.0)
		root.add_child(mi)
		for i in 30: await process_frame
		var img := root.get_texture().get_image()
		img.save_png("res://%s/%s.png" % [out, name])
		print("wrote ", name)
		mi.queue_free(); n.queue_free()
	quit()

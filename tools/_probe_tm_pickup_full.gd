extends SceneTree
## The whole pickup as the game builds it -- plinth, orb, light, spin.
const PICKUP := preload("res://scripts/world/tm_pickup.gd")
func _init() -> void:
	var root := get_root()
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.16,0.18,0.14)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.42,0.45,0.48); e.ambient_light_energy = 0.75
	env.environment = e; root.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation = Vector3(deg_to_rad(-44),deg_to_rad(140),0); sun.light_energy=1.1
	root.add_child(sun)
	var cam := Camera3D.new(); cam.current = true; root.add_child(cam)
	cam.look_at_from_position(Vector3(0.0,0.62,1.05), Vector3(0.0,0.30,0.0), Vector3.UP)
	var n := Node3D.new(); n.set_script(PICKUP)
	root.add_child(n)
	# The visual is built by setup(), NOT by _ready(). Setting _tm_id and
	# adding the node builds nothing at all.
	n.call("setup", "tm_stone_rush")
	for i in 40: await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/tm_orb"))
	root.get_texture().get_image().save_png("res://shots/tm_orb/pickup_full.png")
	print("wrote pickup_full")
	quit()

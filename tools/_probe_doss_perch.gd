extends SceneTree

## Diagnostic only (never evidence): boots the Meadows, freezes the clock at
## morning and frames Doss's bank perch and its debris from three stands, so a
## debris layout change can be checked without the full lure walk.
##
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/_probe_doss_perch.gd -- --out=/abs/dir

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const STANDS := [Vector3(0.0, 3.2, 6.5), Vector3(6.0, 3.0, 2.0), Vector3(-5.5, 3.0, 4.0)]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame
	var look := get_first_node_in_group(&"day_cycle")
	if look != null:
		look.call("reset_to_morning")
		look.call("set_clock_frozen", true)
	var nest := world.get_node_or_null(^"RiverNestClear")
	var perch := nest.get_node_or_null(^"BankPerch") as Node3D if nest != null else null
	if perch == null:
		print("PROBE no perch")
		quit(1)
		return
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.fov = 60.0
	var basis := Basis(Vector3.UP, perch.rotation.y)
	for i in STANDS.size():
		var at: Vector3 = perch.global_position + basis * (STANDS[i] as Vector3)
		cam.global_position = at
		cam.look_at(perch.global_position + Vector3.UP * 0.4, Vector3.UP)
		cam.current = true
		for f in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(out.path_join("perch_%d.png" % i))
	for id: String in (nest.call("debris_nodes") as Dictionary):
		var holder := (nest.call("debris_nodes") as Dictionary)[id] as Node3D
		var mesh := holder.get_node_or_null(^"Mesh") as Node3D
		print("PROBE debris %s mesh=%s at=%s" % [id, str(mesh != null), str(mesh.global_position if mesh != null else Vector3.INF)])
	quit(0)

extends SceneTree

## VIS-MEADOWS F38#41 probe (inert, not a test): list the rendered meshes near
## a point, flat ones (a judge's "dark slab") first. Moves the player there and
## settles before scanning.
##
##   godot --headless --path . --script tests/probe_flat_slabs.gd -- --at=403,1795 [--radius=10]

const SCENE := "res://scenes/world/meadows_playground.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var at := Vector2(403.0, 1795.0)
	var radius := 10.0
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var p := a.trim_prefix("--at=").split(",")
			at = Vector2(float(p[0]), float(p[1]))
		elif a.begins_with("--radius="):
			radius = float(a.trim_prefix("--radius="))
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _i in 120:
		await physics_frame
	for p: Node in world.find_children("*", "CharacterBody3D", true, false):
		if p.name.to_lower().contains("player"):
			(p as Node3D).global_position = Vector3(at.x, 30.0, at.y)
			break
	for _i in 360:
		await physics_frame
	var rows: Array = []
	for g: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var box := gi.global_transform * gi.get_aabb()
		if box.size.x > 200.0 or box.size.z > 200.0:
			continue
		var c := box.get_center()
		var d := Vector2(c.x, c.z).distance_to(at)
		if d > radius:
			continue
		var flat := box.size.y < 0.35 and maxf(box.size.x, box.size.z) > 1.0
		rows.append([0 if flat else 1, d, "PROBE %s d=%.1f size=%s centre=%s %s" % ["FLAT" if flat else "    ", d, box.size, c, gi.get_path()]])
	if OS.get_cmdline_user_args().has("--big"):
		# Rank by AABB volume (largest first) so a big distant mass is not cut by the 60-row cap.
		for r: Array in rows:
			var m := RegEx.create_from_string("size=\\(([-0-9.e]+), ([-0-9.e]+), ([-0-9.e]+)\\)").search(r[2])
			r[1] = -float(m.get_string(1)) * float(m.get_string(2)) * float(m.get_string(3)) if m else 0.0
			r[0] = 0
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	for r: Array in rows.slice(0, 60):
		print(r[2])
	quit(0)

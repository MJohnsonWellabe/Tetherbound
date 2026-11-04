extends SceneTree

## VIS-MEADOWS F38#30 probe (inert, not a test): which rendered geometry hangs
## over the Burrow Warrens walk stands. Teleports the player near the stands,
## settles, then lists every GeometryInstance3D whose global AABB covers a
## stand's XZ column, with its AABB y-range and the terrain height there.
##
##   godot --headless --path . --script tests/probe_warrens_float.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const STANDS := [Vector2(-329.4, 2620.6), Vector2(-352.5, 2635.8), Vector2(-324.3, 2597.5)]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _i in 120:
		await physics_frame
	var players := world.find_children("*", "CharacterBody3D", true, false)
	for p: Node in players:
		if p.name.to_lower().contains("player"):
			(p as Node3D).global_position = Vector3(-340.0, 20.0, 2625.0)
			print("PROBE moved ", p.get_path())
			break
	for _i in 360:
		await physics_frame
	var space := world.get_world_3d().direct_space_state
	for s: Vector2 in STANDS:
		var q := PhysicsRayQueryParameters3D.create(Vector3(s.x, 200.0, s.y), Vector3(s.x, -50.0, s.y))
		var hit := space.intersect_ray(q)
		print("PROBE stand %s first collider hit from above: %s y=%s" % [s, hit.get("collider", null), (hit.get("position", Vector3.ZERO) as Vector3).y])
		for g: Node in world.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if not gi.is_visible_in_tree():
				continue
			var box := gi.global_transform * gi.get_aabb()
			if box.size.x > 400.0 or box.size.z > 400.0:
				continue
			if s.x >= box.position.x and s.x <= box.end.x and s.y >= box.position.z and s.y <= box.end.z:
				print("PROBE   over %s: %s  y %.1f..%.1f  xz %.1f..%.1f / %.1f..%.1f" % [s, gi.get_path(), box.position.y, box.end.y, box.position.x, box.end.x, box.position.z, box.end.z])
	quit(0)

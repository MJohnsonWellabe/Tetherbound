extends SceneTree

## LANE-LAND-MT F38#30 probe (inert, not a test): which small visible props sit
## on or above the Burrow Warrens hill shell's top surface (the crest shards).
##   godot --headless --path . --script tests/probe_warrens_crest_props.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CELL := 2.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _i in 60:
		await physics_frame
	var players := world.find_children("*", "CharacterBody3D", true, false)
	for p: Node in players:
		if p.name.to_lower().contains("player"):
			(p as Node3D).global_position = Vector3(-340.0, 20.0, 2625.0)
			break
	for _i in 300:
		await physics_frame
	var shells := world.find_children("HillShell", "Node3D", true, false)
	if shells.is_empty():
		print("PROBE no HillShell"); quit(1); return
	var shell := shells[0] as Node3D
	var top := {}
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for raw: Node in shell.find_children("*", "MeshInstance3D", true, false):
		var mi := raw as MeshInstance3D
		if mi.mesh == null or mi.get_parent().name.begins_with("HillShellCover") or mi.get_parent().name.begins_with("HillShellEdge"):
			continue
		var xf := mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v: Vector3 in verts:
				var w := xf * v
				var k := Vector2i(floori(w.x / CELL), floori(w.z / CELL))
				top[k] = maxf(float(top.get(k, -INF)), w.y)
				lo = Vector2(minf(lo.x, w.x), minf(lo.y, w.z))
				hi = Vector2(maxf(hi.x, w.x), maxf(hi.y, w.z))
	print("PROBE shell xz %s..%s cells %d" % [lo, hi, top.size()])
	var groups := {}
	for g: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if not gi.is_visible_in_tree() or shell.is_ancestor_of(gi) and not (gi.get_path() as NodePath).get_concatenated_names().contains("HillShellCover") and not (gi.get_path() as NodePath).get_concatenated_names().contains("HillShellEdge"):
			continue
		var box := gi.global_transform * gi.get_aabb()
		if box.size.x < 15.0 and box.size.z < 15.0 or box.size.x > 300.0:
			continue
		var c := box.get_center()
		if box.end.x < lo.x or box.position.x > hi.x or box.end.z < lo.y or box.position.z > hi.y:
			continue
		var k := Vector2i(floori(c.x / CELL), floori(c.z / CELL))
		# large mesh: count shell cells under it where its top pokes out
		var poke := 0
		for cx in range(floori(box.position.x / CELL), floori(box.end.x / CELL) + 1):
			for cz in range(floori(box.position.z / CELL), floori(box.end.z / CELL) + 1):
				if top.has(Vector2i(cx, cz)) and box.end.y > float(top[Vector2i(cx, cz)]) + 0.5:
					poke += 1
		if poke == 0:
			continue
		var surf := float(top[k]) if top.has(k) else 0.0
		var path := str(gi.get_path())
		var re := RegEx.create_from_string("[0-9]+")
		var key := re.sub(path, "#", true)
		if not groups.has(key):
			groups[key] = [0, box.size.length(), box.end.y - surf, path + " poke cells %d" % poke]
		groups[key][0] += 1
	var keys := groups.keys()
	keys.sort_custom(func(a, b): return groups[a][0] > groups[b][0])
	for key: Variant in keys:
		var e: Array = groups[key]
		print("PROBE %4d  %s  (size %.1f m, base %.1f m vs shell top; e.g. %s)" % [e[0], key, e[1], e[2], e[3]])
	quit(0)

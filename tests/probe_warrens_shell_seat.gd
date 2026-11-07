extends SceneTree

## F38#30 probe (inert, not a test): how the Burrow Warrens hill shell meets
## the ground. Prints the shell's and the procedural Bank's bounds in warrens
## space, then walks the shell's rim (vertices within 8 m of the ground) and
## reports how far above the terrain they hang, per 30-degree sector.
##
##   godot --headless --path . --script tests/probe_warrens_shell_seat.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"


func _init() -> void:
	call_deferred("_run")


func _bounds(w: Node3D, root: Node) -> AABB:
	var out := AABB()
	var have := false
	for raw: Node in [root] + root.find_children("*", "MeshInstance3D", true, false):
		var mi := raw as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box := w.global_transform.affine_inverse() * mi.global_transform * mi.mesh.get_aabb()
		out = box if not have else out.merge(box)
		have = true
	return out


func _run() -> void:
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _i in 240:
		await physics_frame
	var w := world.find_child("BurrowWarrens", true, false) as Node3D
	if w == null:
		print("PROBE no warrens")
		quit(1)
		return
	print("PROBE warrens at %s yaw %.1f floor_y %s" % [w.global_position, w.rotation_degrees.y, w.get("_floor_y")])
	for name: String in ["HillShell", "Bank", "BankCap"]:
		var n := w.get_node_or_null(NodePath(name))
		if n != null:
			print("PROBE %s visible=%s local AABB %s" % [name, (n as Node3D).visible, _bounds(w, n)])
	var shell := w.get_node_or_null("HillShell")
	if shell == null:
		quit(0)
		return
	var sectors := {}
	for raw: Node in shell.find_children("*", "MeshInstance3D", true, false):
		var mi := raw as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var verts: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var step := maxi(1, verts.size() / 60000)
		for i in range(0, verts.size(), step):
			var g := mi.global_transform * verts[i]
			var ground := float(world.call("ground_height_at", g.x, g.z))
			if not is_finite(ground) or g.y - ground > 8.0:
				continue
			var l := w.to_local(g)
			var sector := int(floor(fposmod(rad_to_deg(atan2(l.x, l.z - 50.0)), 360.0) / 30.0))
			var s: Dictionary = sectors.get(sector, {"n": 0, "above": 0, "max_gap": -99.0, "min_gap": 99.0, "r": 0.0})
			var gap := g.y - ground
			s.n += 1
			s.r += Vector2(l.x, l.z - 50.0).length()
			if gap > 0.4:
				s.above += 1
			s.max_gap = maxf(s.max_gap, gap)
			s.min_gap = minf(s.min_gap, gap)
			sectors[sector] = s
	for k: int in range(12):
		if sectors.has(k):
			var s: Dictionary = sectors[k]
			print("PROBE rim sector %3d deg: %d verts, %d hang >0.4 m, gap %.1f..%.1f, mean r %.0f m" % [k * 30, s.n, s.above, s.min_gap, s.max_gap, s.r / maxf(1, s.n)])
	# Lowest shell vertex above ground per 15-degree bin round the shell's
	# own centre: how far its base edge hangs (negative = buried).
	var bins := {}
	var tops := {}
	var stands := [Vector2(-329.4, 2620.6), Vector2(-352.5, 2635.8), Vector2(-324.3, 2597.5)]
	for name: String in ["HillShell", "Bank"]:
		var node := w.get_node_or_null(NodePath(name))
		if node == null:
			continue
		for raw: Node in node.find_children("*", "MeshInstance3D", true, false) + [node]:
			var mi := raw as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			for surf in mi.mesh.get_surface_count():
				var verts: PackedVector3Array = mi.mesh.surface_get_arrays(surf)[Mesh.ARRAY_VERTEX]
				var step := maxi(1, verts.size() / 80000)
				for i in range(0, verts.size(), step):
					var g := mi.global_transform * verts[i]
					for si in stands.size():
						if Vector2(g.x, g.z).distance_to(stands[si]) < 3.0:
							var key := "%s %d" % [name, si]
							tops[key] = maxf(float(tops.get(key, -99.0)), g.y)
					if name != "HillShell":
						continue
					var ground := float(world.call("ground_height_at", g.x, g.z))
					if not is_finite(ground):
						continue
					var l := w.to_local(g)
					var b := int(floor(fposmod(rad_to_deg(atan2(l.x, l.z - 54.0)), 360.0) / 15.0))
					var gap := g.y - ground
					if not bins.has(b) or gap < float(bins[b][0]):
						bins[b] = [gap, Vector2(l.x, l.z).length(), ground]
	for b: int in range(24):
		if bins.has(b):
			print("PROBE base bin %3d deg: lowest vertex %.2f m above ground (ground %.2f, r %.0f)" % [b * 15, bins[b][0], bins[b][2], bins[b][1]])
	for si in stands.size():
		var p: Vector2 = stands[si]
		var l := w.to_local(Vector3(p.x, 0, p.y))
		print("PROBE stand %s local (%.1f, %.1f) ground %.2f shell top %.1f bank top %.1f" % [p, l.x, l.z, float(world.call("ground_height_at", p.x, p.y)), float(tops.get("HillShell %d" % si, -99.0)), float(tops.get("Bank %d" % si, -99.0))])
	quit(0)

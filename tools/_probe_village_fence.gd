extends SceneTree
## N05-WORLD-DRESSING-0905. Headless measurement of the village boundary fence
## as village_boundary.gd actually lays it: for every FencePanel_* the ground
## height under each END of the panel against the height the panel sits at
## (how far a post floats or is buried), and for every consecutive pair on one
## edge the gap or overlap between the two panels' ends. Numbers, decided before
## any render, for the W08-DIALOGUE-CAMERA-0904 fence finding
## ("a post floats clear of the terrain", "a rail ends in mid-air", "a post
## passes through another run's rails").
##
##   godot --headless --path . --script tools/_probe_village_fence.gd [-- --near=x,z --radius=r]

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 60
const PANEL_HALF := 3.075   # building_prefabs.json fence_run collider 6.15 / 2


func _init() -> void:
	_run()


func _run() -> void:
	var near := Vector2(23.5, 11.5)   # Halda's stand, village_npcs.json
	var radius := 40.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--near="):
			var parts := a.substr(7).split(",")
			near = Vector2(float(parts[0]), float(parts[1]))
		elif a.begins_with("--radius="):
			radius = float(a.substr(9))
	var packed: PackedScene = load(SCENE)
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var boundary: Node3D = null
	for node in root.find_children("*", "Node3D", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("village_boundary.gd"):
			boundary = node as Node3D
			break
	if boundary == null:
		push_error("no village_boundary.gd node in the world")
		quit(1)
		return
	var panels: Array[Node3D] = []
	for child in boundary.get_children():
		if str(child.name).begins_with("FencePanel_") and child is Node3D:
			panels.append(child as Node3D)
	print("[fence] %d panels; reporting those within %.0f m of (%.1f, %.1f)" % [panels.size(), radius, near.x, near.y])
	var worst_float := 0.0
	var worst_bury := 0.0
	var floats := 0
	var ends: Array = []   # [panel, start_xz, end_xz]
	for panel in panels:
		var p := panel.global_position
		if Vector2(p.x, p.z).distance_to(near) > radius:
			continue
		# `to_global` already applies the panel's own stretch (`scale.x`), so the
		# prefab's half-length in LOCAL metres is the end post.
		var a := panel.to_global(Vector3(-PANEL_HALF, 0.0, 0.0))
		var b := panel.to_global(Vector3(PANEL_HALF, 0.0, 0.0))
		var ga := float(world.call("ground_height_at", a.x, a.z))
		var gb := float(world.call("ground_height_at", b.x, b.z))
		# Positive = the post's foot is above the ground (floating); the fence
		# module's own feet are at local y 0, so the panel's own y IS the foot.
		var fa := a.y - ga
		var fb := b.y - gb
		worst_float = maxf(worst_float, maxf(fa, fb))
		worst_bury = maxf(worst_bury, maxf(-fa, -fb))
		if fa > 0.05 or fb > 0.05:
			floats += 1
		ends.append([panel, Vector2(a.x, a.z), Vector2(b.x, b.z)])
		print("  %s at (%.2f, %.2f, %.2f) yaw %.1f scale.x %.3f pitch %.2f | foot A %+.3f m, foot B %+.3f m" % [
			panel.name, p.x, p.y, p.z, panel.rotation_degrees.y, panel.scale.x, panel.rotation_degrees.z, fa, fb])
	# Joins: for every panel end, the nearest other panel end in the flat.
	var gaps: Array[float] = []
	for i in ends.size():
		for which in [1, 2]:
			var e: Vector2 = ends[i][which]
			var best := INF
			for j in ends.size():
				if i == j:
					continue
				for w2 in [1, 2]:
					best = minf(best, e.distance_to(ends[j][w2]))
			if best < 4.0:
				gaps.append(best)
	gaps.sort()
	var worst_gap := gaps[gaps.size() - 1] if not gaps.is_empty() else 0.0
	var median_gap := gaps[gaps.size() / 2] if not gaps.is_empty() else 0.0
	print("[fence] SUMMARY near (%.1f, %.1f): panels %d, floating posts on %d panels, worst float %.3f m, worst bury %.3f m, end-to-end join distance median %.3f m worst %.3f m" % [
		near.x, near.y, ends.size(), floats, worst_float, worst_bury, median_gap, worst_gap])
	quit(0)

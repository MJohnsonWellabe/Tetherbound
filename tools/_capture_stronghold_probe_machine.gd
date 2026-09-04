extends SceneTree
## W06-FINALE-0904 (CL-O8). Measures the installed Tether Machine mesh the way
## `stronghold.gd::_fit_to_height` fits it (visual bounds, walked up the node
## chain, scaled to `machine.height`), then prints a vertical profile of the
## fitted mesh: per height band, how close the geometry comes to the machine's
## own axis and how wide it spans. A band where nothing comes near the axis is
## the hollow the board draws the prisoner in -- the volume the legendary is
## staged into, by measurement rather than by transform guess (D49's lesson).
##
##   godot --headless --path . --script tools/_capture_stronghold_probe_machine.gd

const MODEL := "res://assets/environment/team_tether/tether_machine.glb"
const HEIGHT := 15.0
const BAND := 0.5


func _init() -> void:
	var scene := load(MODEL) as PackedScene
	if scene == null:
		print("no machine mesh at %s" % MODEL)
		quit(1)
		return
	var instance := scene.instantiate() as Node3D
	var bounds := _visual_bounds(instance)
	var scale_to := HEIGHT / bounds.size.y
	var offset := Vector3(-bounds.get_center().x * scale_to, -bounds.position.y * scale_to,
		-bounds.get_center().z * scale_to)
	print("raw bounds %s size %s -> scale %.4f offset %s" % [bounds.position, bounds.size, scale_to, offset])
	print("fitted bounds: x %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f" % [
		bounds.position.x * scale_to + offset.x, bounds.end.x * scale_to + offset.x,
		bounds.position.y * scale_to + offset.y, bounds.end.y * scale_to + offset.y,
		bounds.position.z * scale_to + offset.z, bounds.end.z * scale_to + offset.z])

	var bands: Dictionary = {}
	var total := 0
	for child in instance.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		var here := Transform3D.IDENTITY
		var step: Node = mi
		while step != null and step != instance:
			if step is Node3D:
				here = (step as Node3D).transform * here
			step = step.get_parent()
		var box := here * mi.get_aabb()
		print("mesh '%s': fitted aabb x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % [mi.name,
			box.position.x * scale_to + offset.x, box.end.x * scale_to + offset.x,
			box.position.y * scale_to + offset.y, box.end.y * scale_to + offset.y,
			box.position.z * scale_to + offset.z, box.end.z * scale_to + offset.z])
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for v in verts:
				var p: Vector3 = here * v * scale_to + offset
				total += 1
				var key := int(floor(p.y / BAND))
				if not bands.has(key):
					bands[key] = {"n": 0, "rmin": 1e9, "xmin": 1e9, "xmax": -1e9, "zmin": 1e9, "zmax": -1e9,
						"near_axis": 0}
				var b: Dictionary = bands[key]
				b["n"] = int(b["n"]) + 1
				var r := Vector2(p.x, p.z).length()
				b["rmin"] = minf(float(b["rmin"]), r)
				if r < 2.5:
					b["near_axis"] = int(b["near_axis"]) + 1
				b["xmin"] = minf(float(b["xmin"]), p.x)
				b["xmax"] = maxf(float(b["xmax"]), p.x)
				b["zmin"] = minf(float(b["zmin"]), p.z)
				b["zmax"] = maxf(float(b["zmax"]), p.z)
	print("%d vertices" % total)
	# Fine pass: the dais top (highest geometry near the axis in the lower half)
	# and the crown underside (lowest geometry near the axis above it), plus the
	# ring's inner half-width at cage height -- the numbers the staging uses.
	var dais_top := -1.0
	var crown_under := 1e9
	var inner_x := 1e9
	for child in instance.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		var here := Transform3D.IDENTITY
		var step: Node = mi
		while step != null and step != instance:
			if step is Node3D:
				here = (step as Node3D).transform * here
			step = step.get_parent()
		for s in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v in verts:
				var p: Vector3 = here * v * scale_to + offset
				var r := Vector2(p.x, p.z).length()
				if r < 1.0 and p.y < HEIGHT * 0.5:
					dais_top = maxf(dais_top, p.y)
				if r < 1.0 and p.y > HEIGHT * 0.5 - 2.0:
					crown_under = minf(crown_under, p.y)
	for child in instance.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		var here := Transform3D.IDENTITY
		var step: Node = mi
		while step != null and step != instance:
			if step is Node3D:
				here = (step as Node3D).transform * here
			step = step.get_parent()
		for s in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v in verts:
				var p: Vector3 = here * v * scale_to + offset
				if p.y > dais_top + 0.6 and p.y < crown_under - 0.3 and absf(p.z) < 1.0 and absf(p.x) > 0.3:
					inner_x = minf(inner_x, absf(p.x))
	print("dais top y=%.2f  crown underside y=%.2f  cage void %.2f m tall  inner half-width %.2f m" % [
		dais_top, crown_under, crown_under - dais_top, inner_x])
	var keys := bands.keys()
	keys.sort()
	print("band(y)     n   rmin  near<2.5   x range          z range")
	for key in keys:
		var b: Dictionary = bands[key]
		print("%5.1f-%5.1f %6d %6.2f %6d   %6.2f..%6.2f   %6.2f..%6.2f" % [
			float(key) * BAND, float(key + 1) * BAND, int(b["n"]), float(b["rmin"]), int(b["near_axis"]),
			float(b["xmin"]), float(b["xmax"]), float(b["zmin"]), float(b["zmax"])])
	quit(0)


func _visual_bounds(node: Node) -> AABB:
	var total := AABB()
	var seeded := false
	for child in node.find_children("*", "VisualInstance3D", true, false):
		var visual := child as VisualInstance3D
		var box := visual.get_aabb()
		var here := Transform3D.IDENTITY
		var step: Node = visual
		while step != null and step != node:
			if step is Node3D:
				here = (step as Node3D).transform * here
			step = step.get_parent()
		box = here * box
		total = box if not seeded else total.merge(box)
		seeded = true
	return total

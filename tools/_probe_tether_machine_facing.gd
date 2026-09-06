extends SceneTree
## OP-0905-16. "You can't see the legendary when you enter the chamber. The
## machine needs to be turned." `tools/_capture_stronghold_probe_machine.gd`
## already measures the installed Tether Machine mesh VERTICALLY (dais/crown/
## void); this probe measures it HORIZONTALLY, at the same void height band,
## to find which yaw direction is the open cage side (the arch the board
## draws the bound legendary standing in) and which is the solid back.
##
## Method: walk every MeshInstance3D's raw vertices (same fit-to-height
## transform `stronghold.gd::_fit_to_height` applies), keep only the ones
## inside the measured cage void's height band and within a radius band that
## excludes the core column (so the core's own geometry, which IS
## rotationally near-symmetric, does not wash out the ring's asymmetry), and
## bucket the rest by yaw angle (atan2(z,x)) into 16 slices. The slice(s)
## with the fewest vertices are the open side; the slice diametrically
## opposite is the solid back. Reports the density-weighted "facing" — the
## direction with the LEAST material — as a `facing_deg` in the same
## convention `stronghold.gd` already uses for `facing_deg` elsewhere
## (0 = the model's own +z axis, degrees are a `rotation.y` in `deg_to_rad`,
## so a positive `facing_deg` turns the model's +z axis toward world +x
## following Godot's Y-up right-handed rotation).
##
##   godot --headless --path . --script tools/_probe_tether_machine_facing.gd

const MODEL := "res://assets/environment/team_tether/tether_machine.glb"
const HEIGHT := 15.0
const SLICES := 16
const CORE_EXCLUDE_R := 2.2 ## the core column's own footprint (core_radius*1.5 crown ~2.85 fitted; stay clear of it so the core's near-symmetric geometry cannot mask the ring's asymmetry)


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

	# Re-derive the cage void's height band exactly as
	# `_capture_stronghold_probe_machine.gd` does (highest near-axis geometry
	# below mid-height is the dais, lowest above it is the crown), so this
	# probe stays correct if the mesh is ever regenerated.
	var dais_top := -1.0
	var crown_under := 1e9
	for child in instance.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		var here := _world_of(mi, instance)
		for s in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v in verts:
				var p: Vector3 = here * v * scale_to + offset
				var r := Vector2(p.x, p.z).length()
				if r < 1.0 and p.y < HEIGHT * 0.5:
					dais_top = maxf(dais_top, p.y)
				if r < 1.0 and p.y > HEIGHT * 0.5 - 2.0:
					crown_under = minf(crown_under, p.y)
	print("cage void band: y %.2f..%.2f" % [dais_top, crown_under])

	var slice_counts := []
	slice_counts.resize(SLICES)
	slice_counts.fill(0)
	var total_in_band := 0
	for child in instance.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		var here := _world_of(mi, instance)
		for s in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v in verts:
				var p: Vector3 = here * v * scale_to + offset
				if p.y < dais_top + 0.3 or p.y > crown_under - 0.3:
					continue
				var r := Vector2(p.x, p.z).length()
				if r < CORE_EXCLUDE_R:
					continue
				total_in_band += 1
				var ang := atan2(p.z, p.x) # radians, [-PI, PI]
				var slice := int(floor(fposmod(ang, TAU) / TAU * SLICES)) % SLICES
				slice_counts[slice] = int(slice_counts[slice]) + 1

	print("%d ring vertices in the void band (r >= %.2f), by %d-slice yaw bucket:" % [
		total_in_band, CORE_EXCLUDE_R, SLICES])
	var min_count := 1 << 30
	var min_slice := 0
	for i in SLICES:
		var deg := float(i) * 360.0 / float(SLICES)
		var n: int = slice_counts[i]
		print("  slice %2d  yaw %6.1f..%6.1f deg  n=%4d" % [i, deg, deg + 360.0 / SLICES, n])
		if n < min_count:
			min_count = n
			min_slice = i

	# The open side is the slice (and its neighbours, since an archway is
	# usually a few slices wide) with the least material. Report the emptiest
	# CONTIGUOUS run rather than a single slice, since a lone empty slice next
	# to two full ones is noise, not an archway.
	var best_run_start := 0
	var best_run_len := 0
	var best_run_count := 1 << 30
	for start in SLICES:
		for length in range(1, SLICES / 2 + 1):
			var sum := 0
			for k in length:
				sum += int(slice_counts[(start + k) % SLICES])
			var avg := float(sum) / float(length)
			if avg < best_run_count or (is_equal_approx(avg, best_run_count) and length > best_run_len):
				best_run_count = avg
				best_run_start = start
				best_run_len = length

	var open_centre_slice := fposmod(float(best_run_start) + float(best_run_len - 1) * 0.5, float(SLICES))
	var open_deg := open_centre_slice * 360.0 / float(SLICES)
	print("emptiest slice: %d (n=%d)" % [min_slice, min_count])
	print("open side centre: yaw %.1f deg (model's own +x axis measured counter-clockwise from +x toward +z)" % open_deg)
	print("model's own open-side unit vector: (%.3f, %.3f) in (x,z)" % [cos(deg_to_rad(open_deg)), sin(deg_to_rad(open_deg))])
	print("")
	print("To face the open side toward the chamber doorway (+x, world/local frame, since the doorway is the legendary_chamber's +x wall):")
	# stronghold.gd's own facing_deg convention (confirmed against its
	# documented cases, e.g. "both current entries face 0.0 (local -Z ...")
	# is `rotation.y = deg_to_rad(facing_deg)` with Godot's standard Y-rotation
	# matrix (new_x = x*cos(phi) + z*sin(phi); new_z = -x*sin(phi) + z*cos(phi)).
	# Solving that for "the model's own open-side vector (cos(open_deg),
	# sin(open_deg)) in (x,z) maps to world (1,0)" gives phi = open_deg exactly
	# (cos(open_deg-phi)=1, sin(open_deg-phi)=0 => phi=open_deg).
	var facing_deg := wrapf(open_deg, -180.0, 180.0)
	print("  facing_deg = %.1f" % facing_deg)
	print("  (rotation.y = deg_to_rad(facing_deg) turns the model's own open-side vector from yaw %.1f to yaw 0, i.e. onto +x)" % open_deg)
	quit(0)


func _world_of(mi: MeshInstance3D, root: Node) -> Transform3D:
	var here := Transform3D.IDENTITY
	var step: Node = mi
	while step != null and step != root:
		if step is Node3D:
			here = (step as Node3D).transform * here
		step = step.get_parent()
	return here


func _visual_bounds(node: Node) -> AABB:
	var total := AABB()
	var seeded := false
	for child in node.find_children("*", "VisualInstance3D", true, false):
		var visual := child as VisualInstance3D
		var box := visual.get_aabb()
		var here := _world_of(visual, node)
		box = here * box
		total = box if not seeded else total.merge(box)
		seeded = true
	return total

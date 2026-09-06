extends SceneTree
## HALL-ART-0906. WHICH NODE IS THAT PIXEL?
##
## Two of the blind judge's findings on the Hall interiors are "there is a
## bright/flat thing here and I cannot tell what it is": a hard-edged white V
## in T-03's top-left corner and a flat unlit maroon plane filling the left of
## T-02. Both had already survived one round of guessing, and guessing at a
## render costs 6 minutes a stand. This answers the question directly instead.
##
##   godot --headless --path . --script tools/_probe_hall_frame_geometry.gd -- \
##     --px=T-02:20,450 --px=T-03:24,88
##
## Headless on purpose: it renders nothing. It rebuilds the SAME camera stands
## `tools/_capture_stronghold_climax.gd` shoots T-01..T-03 from (same eye, same
## aim, same 70 deg vertical FOV, same 1280x720 aspect), casts a ray through the
## named pixel, and reports every MeshInstance3D whose world AABB that ray
## enters, nearest first, with its node path, its size and its material. The
## AABB is coarse, so read the list as "these are the candidates in depth
## order", not as a triangle hit.
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 90
const FOV := 70.0
const WIDTH := 1280.0
const HEIGHT := 720.0

var _wanted: Array = []   # [[stand, x, y], ...]


func _init() -> void:
	_run()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--px="):
			continue
		var body := a.substr("--px=".length())
		var parts := body.split(":", false)
		if parts.size() != 2:
			continue
		var xy := parts[1].split(",", false)
		if xy.size() != 2:
			continue
		_wanted.append([parts[0].strip_edges(), float(xy[0]), float(xy[1])])
	if _wanted.is_empty():
		_wanted = [["T-01", 20.0, 360.0], ["T-02", 20.0, 450.0], ["T-03", 24.0, 88.0]]

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var hold: Node3D = world.find_child("Stronghold", true, false) as Node3D
	if hold == null:
		push_error("no Stronghold in the world")
		quit(1)
		return

	var stands := _stands(hold)
	var meshes: Array[MeshInstance3D] = []
	for node in world.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node as MeshInstance3D)
	print("probing %d MeshInstance3D(s) in the world\n" % meshes.size())

	for want: Array in _wanted:
		var name_value := str(want[0])
		if not stands.has(name_value):
			print("unknown stand '%s' (have %s)" % [name_value, str(stands.keys())])
			continue
		var stand: Array = stands[name_value]
		var eye: Vector3 = stand[0]
		var aim: Vector3 = stand[1]
		var dir := _ray(eye, aim, float(want[1]), float(want[2]))
		print("=== %s pixel (%d,%d)  eye %s  dir %s" % [
			name_value, int(want[1]), int(want[2]), str(eye), str(dir)])
		var hits: Array = []
		for mesh in meshes:
			if not mesh.visible or mesh.mesh == null:
				continue
			var t := _ray_aabb(mesh, eye, dir)
			if t < 0.0:
				continue
			hits.append([t, mesh])
		hits.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		var shown := 0
		for hit: Array in hits:
			if shown >= 12:
				break
			var mesh: MeshInstance3D = hit[1]
			var aabb := mesh.get_aabb()
			var material := mesh.material_override
			var label := "material_override=null"
			if material != null:
				label = "override=%s" % material.get_class()
				if material is ShaderMaterial:
					var shader: Shader = (material as ShaderMaterial).shader
					label += "(%s)" % (shader.resource_path.get_file() if shader != null else "?")
				elif material is StandardMaterial3D:
					var std := material as StandardMaterial3D
					label += "(albedo=%s emission=%s)" % [
						std.albedo_color.to_html(false),
						("%s x%.2f" % [std.emission.to_html(false), std.emission_energy_multiplier]) \
							if std.emission_enabled else "off"]
			print("  %6.2f m  %-58s size %5.2f x %5.2f x %5.2f  %s" % [
				float(hit[0]), str(world.get_path_to(mesh)).right(58),
				aabb.size.x * mesh.global_transform.basis.get_scale().x,
				aabb.size.y * mesh.global_transform.basis.get_scale().y,
				aabb.size.z * mesh.global_transform.basis.get_scale().z, label])
			shown += 1
		if hits.is_empty():
			print("  (nothing)")
		print("")
	quit(0)


## The three interior stands, derived exactly as
## `tools/_capture_stronghold_climax.gd` derives them, through the hold's own
## `marker()`/`chamber_size()` rather than by re-typing metres.
func _stands(hold: Node3D) -> Dictionary:
	var basis := hold.global_transform.basis
	var local_x := basis.x.normalized()
	var local_z := basis.z.normalized()

	var ta_centre: Vector3 = hold.call("marker", "tether_approach")
	var ta_size: Vector3 = hold.call("chamber_size", "tether_approach")
	var ta_near := ta_centre + local_z * (-ta_size.y * 0.5 + 2.0)
	var ta_far := ta_centre + local_z * (ta_size.y * 0.5)

	var wa_centre: Vector3 = hold.call("marker", "warden_arena")
	var wa_size: Vector3 = hold.call("chamber_size", "warden_arena")
	var wa_near := wa_centre + local_z * (-wa_size.y * 0.5 + 2.0)
	var wa_door := wa_centre + local_x * (-wa_size.x * 0.5)

	var chamber: Vector3 = hold.call("marker", "legendary_chamber")
	var lc_size: Vector3 = hold.call("chamber_size", "legendary_chamber")
	var lc_in := chamber + local_x * (lc_size.x * 0.5 - 4.0)
	var stand_t03 := Vector3(lc_in.x, chamber.y + 1.7, lc_in.z)
	var turned := (-local_x) * cos(deg_to_rad(60.0)) + (-local_z) * sin(deg_to_rad(60.0))

	return {
		"T-01": [Vector3(ta_near.x, ta_centre.y + 1.7, ta_near.z),
			Vector3(ta_far.x, ta_centre.y + 1.7, ta_far.z)],
		"T-02": [Vector3(wa_near.x, wa_centre.y + 1.7, wa_near.z),
			Vector3(wa_door.x, wa_centre.y + 1.7, wa_door.z)],
		"T-03": [stand_t03, stand_t03 + turned * 15.0],
	}


## A ray through one pixel of the same 1280x720 / 70 deg vertical frustum the
## capture shoots. Godot's Camera3D keeps the VERTICAL fov by default, so the
## horizontal half-angle is the vertical one times the aspect.
func _ray(eye: Vector3, aim: Vector3, px: float, py: float) -> Vector3:
	var forward := (aim - eye).normalized()
	var up_hint := Vector3.UP
	if absf(forward.dot(up_hint)) > 0.999:
		up_hint = Vector3.FORWARD
	var right := forward.cross(up_hint).normalized()
	var up := right.cross(forward).normalized()
	var tan_v := tan(deg_to_rad(FOV) * 0.5)
	var tan_h := tan_v * (WIDTH / HEIGHT)
	var ndc_x := (px + 0.5) / WIDTH * 2.0 - 1.0
	var ndc_y := 1.0 - (py + 0.5) / HEIGHT * 2.0
	return (forward + right * ndc_x * tan_h + up * ndc_y * tan_v).normalized()


## Slab test in the mesh's OWN space, so a rotated node is tested against its
## real oriented box rather than against a world-axis-aligned envelope of it.
## Returns the entry distance in world metres, or -1.
func _ray_aabb(mesh: MeshInstance3D, eye: Vector3, dir: Vector3) -> float:
	var inv := mesh.global_transform.affine_inverse()
	var o := inv * eye
	var d := inv.basis * dir
	var box := mesh.get_aabb()
	var lo := box.position
	var hi := box.end
	var t_min := -1e20
	var t_max := 1e20
	for axis in 3:
		if absf(d[axis]) < 1e-9:
			if o[axis] < lo[axis] or o[axis] > hi[axis]:
				return -1.0
			continue
		var t1 := (lo[axis] - o[axis]) / d[axis]
		var t2 := (hi[axis] - o[axis]) / d[axis]
		if t1 > t2:
			var swap := t1
			t1 = t2
			t2 = swap
		t_min = maxf(t_min, t1)
		t_max = minf(t_max, t2)
	if t_max < maxf(t_min, 0.0):
		return -1.0
	var t := maxf(t_min, 0.0)
	# Back to world metres: the local direction was not normalised.
	return t * d.length()

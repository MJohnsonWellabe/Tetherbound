extends SceneTree

## VIS-MEADOWS probe (inert, not a test): name the rendered mesh under given
## pixels of a captured frame. Rebuilds the frame's camera from its manifest
## `camera_transform`, casts a ray through each pixel and intersects every
## visible mesh's triangles (visual meshes, collider or not); prints the
## nearest hits.
##
##   godot --path . --script tests/probe_camera_pixel.gd -- \
##     --manifest=res://.artifacts/vm/q41c/manifest.json [--frame=0] \
##     --px=0.5,0.95;0.9,0.3 [--fov=70] [--aspect=1.7778] [--hits=3]
## Pixels are fractions of width,height from the top-left.

const SCENE := "res://scenes/world/meadows_playground.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest_path := ""
	var frame_index := 0
	var fov := 70.0
	var aspect := 16.0 / 9.0
	var hits_per_px := 3
	var pixels: Array[Vector2] = []
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--manifest="):
			manifest_path = a.trim_prefix("--manifest=")
		elif a.begins_with("--frame="):
			frame_index = int(a.trim_prefix("--frame="))
		elif a.begins_with("--fov="):
			fov = float(a.trim_prefix("--fov="))
		elif a.begins_with("--aspect="):
			aspect = float(a.trim_prefix("--aspect="))
		elif a.begins_with("--hits="):
			hits_per_px = int(a.trim_prefix("--hits="))
		elif a.begins_with("--px="):
			for pair: String in a.trim_prefix("--px=").split(";"):
				var p := pair.split(",")
				pixels.append(Vector2(float(p[0]), float(p[1])))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var frames: Array = []
	if parsed is Dictionary:
		frames = (parsed as Dictionary).get("frames", [parsed])
	elif parsed is Array:
		frames = parsed
	if frames.size() <= frame_index:
		push_error("no frame %d in %s" % [frame_index, manifest_path])
		quit(1)
		return
	var frame := frames[frame_index] as Dictionary
	var ct := frame.get("camera_transform", {}) as Dictionary
	var basis := Basis(_v(ct.get("basis_x")), _v(ct.get("basis_y")), _v(ct.get("basis_z")))
	var cam := Transform3D(basis, _v(ct.get("origin")))
	var player_xz := frame.get("position_xz", [cam.origin.x, cam.origin.z]) as Array

	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _i in 120:
		await physics_frame
	for p: Node in world.find_children("*", "CharacterBody3D", true, false):
		if p.name.to_lower().contains("player"):
			(p as Node3D).global_position = Vector3(float(player_xz[0]), 30.0, float(player_xz[1]))
			break
	for _i in 360:
		await physics_frame

	var tan_v := tan(deg_to_rad(fov) * 0.5)
	var tan_h := tan_v * aspect
	var geoms: Array = []
	for g: Node in world.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh != null and mi.is_visible_in_tree():
			geoms.append(mi)
	print("PROBE camera %s fov %.1f, %d meshes" % [cam.origin, fov, geoms.size()])
	for px: Vector2 in pixels:
		var dir_cam := Vector3((px.x * 2.0 - 1.0) * tan_h, (1.0 - px.y * 2.0) * tan_v, -1.0)
		var dir := (cam.basis * dir_cam).normalized()
		var from := cam.origin
		var found: Array = []
		for mi: MeshInstance3D in geoms:
			var inv := mi.global_transform.affine_inverse()
			var lf := inv * from
			var ld := (inv.basis * dir).normalized()
			var box := mi.get_aabb().grow(0.05)
			if box.intersects_ray(lf, ld) == null:
				continue
			var tri := mi.mesh.generate_triangle_mesh()
			if tri == null:
				continue
			var hit: Dictionary = tri.intersect_ray(lf, ld)
			if hit.is_empty():
				continue
			var world_hit: Vector3 = mi.global_transform * (hit["position"] as Vector3)
			found.append([from.distance_to(world_hit), mi, world_hit])
		found.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		print("PROBE px=(%.3f,%.3f) %d hits" % [px.x, px.y, found.size()])
		for row: Array in found.slice(0, hits_per_px):
			var mi := row[1] as MeshInstance3D
			print("PROBE   d=%.1f at=%s aabb=%s %s" % [row[0], row[2],
				(mi.global_transform * mi.get_aabb()).size, mi.get_path()])
	quit(0)


func _v(raw: Variant) -> Vector3:
	var a := raw as Array
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

extends SceneTree

## Throwaway probe: where is a creature's back, in ITS OWN body-local metres,
## once pal_body has fitted the art to the species' gameplay size?
##
##   godot --headless --path . --script <this> -- species_id [species_id...]
##
## Measures BONE POSES under the idle clip, never `Mesh.get_aabb()`.

const BODY := preload("res://scenes/pals/pal.tscn")
const SPECIES := preload("res://scripts/pals/pal_species.gd")


func _init() -> void:
	await process_frame
	var ids: Array = []
	for arg in OS.get_cmdline_user_args():
		ids.append(arg)
	if ids.is_empty():
		ids = SPECIES.ids()
	var world := Node3D.new()
	root.add_child(world)
	for id: String in ids:
		await _probe(world, id)
	quit(0)


func _probe(world: Node3D, id: String) -> void:
	var body: CharacterBody3D = BODY.instantiate()
	body.set_script(load("res://scripts/pals/pal_body.gd"))
	world.add_child(body)
	body.call("setup", id)
	body.global_position = Vector3.ZERO
	await process_frame

	var players: Array[Node] = body.find_children("*", "AnimationPlayer", true, false)
	var clips: Dictionary = SPECIES.placeholder(id).get("animations", {})
	var idle := str(clips.get("idle", ""))
	if not players.is_empty() and idle != "":
		var ap: AnimationPlayer = players[0]
		if ap.has_animation(idle):
			ap.play(idle)
			ap.seek(0.0, true)
			ap.advance(0.0)
	await process_frame

	print("\n== %s  (%s)  gameplay height %.2fm radius %.2fm" % [
		id, SPECIES.display_name(id), SPECIES.body_height(id),
		float(SPECIES.placeholder(id).get("radius", 0.0))])

	var skeletons: Array[Node] = body.find_children("*", "Skeleton3D", true, false)
	var to_body := body.global_transform.affine_inverse()
	for node in skeletons:
		var skel: Skeleton3D = node
		for i in skel.get_bone_count():
			var world_pose: Transform3D = skel.global_transform * skel.get_bone_global_pose(i)
			var local := to_body * world_pose
			print("   %-22s  x %6.3f  y %6.3f  z %6.3f" % [
				skel.get_bone_name(i), local.origin.x, local.origin.y, local.origin.z])

	# The mesh box as it renders, for comparison only.
	var box := AABB()
	var started := false
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mesh
		if m.mesh == null or not m.visible:
			continue
		var b: AABB = (to_body * m.global_transform) * m.get_aabb()
		box = b if not started else box.merge(b)
		started = true
	print("   [skinned aabb, padded, DO NOT TRUST] y %.2f..%.2f  z %.2f..%.2f" % [
		box.position.y, box.position.y + box.size.y,
		box.position.z, box.position.z + box.size.z])
	for band: Array in [[-0.45, -0.25], [-0.25, -0.05], [-0.05, 0.15], [0.15, 0.35]]:
		var r := _rest_top(body, band[0], band[1])
		print("   rest surface z %5.2f..%5.2f  top y %.3f at z %.3f      (rest z span %.2f..%.2f)" % [
			band[0], band[1], r["top"], (r["at"] as Vector3).z, r["z_lo"], r["z_hi"]])

	world.remove_child(body)
	body.queue_free()


func _rest_top(body: Node3D, z_lo: float, z_hi: float) -> Dictionary:
	var to_body := body.global_transform.affine_inverse()
	var top := -INF
	var at := Vector3.ZERO
	var lo := INF
	var hi := -INF
	for node in body.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = node
		if m.mesh == null or not m.visible:
			continue
		var x := to_body * m.global_transform
		for s in m.mesh.get_surface_count():
			var arrays: Array = m.mesh.surface_get_arrays(s)
			for v: Vector3 in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var p := x * v
				lo = minf(lo, p.z)
				hi = maxf(hi, p.z)
				if p.z >= z_lo and p.z <= z_hi and absf(p.x) < 0.25 and p.y > top:
					top = p.y
					at = p
	return {"top": top, "at": at, "z_lo": lo, "z_hi": hi}

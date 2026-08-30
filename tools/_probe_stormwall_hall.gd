extends SceneTree

## T1-STORMWALL (2026-08-30). Measures the actual distance from the Meadows
## Hall's own site centre to each `rift_collapse.gd` StormWall slab, and the
## angle off the slabs' own forward bearing -- the numbers `rift_collapse.gd`'s
## own `_slab_material` comment cites. Answers "is this a visibility/lifecycle
## bug (too close) or a materials bug (right distance, wrong dressing)" with a
## real boot rather than the config arithmetic alone.
##
##   godot --headless --path . --script tools/_probe_stormwall_hall.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"

func _init() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in 90:
		await physics_frame

	var rift: Node = world.get_node_or_null(^"RiftCollapse")
	var stronghold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	if rift == null or stronghold == null:
		push_error("RiftCollapse=%s Stronghold=%s -- world did not build both" % [rift, stronghold])
		quit(1)
		return

	var hall_at := Vector2(stronghold.global_position.x, stronghold.global_position.z)
	var horizon: Dictionary = rift.call("horizon")
	var origin: Vector2 = horizon.get("origin", Vector2.ZERO)
	var seam: Vector2 = rift.call("seam")
	print("Hall site (world XZ): %s" % hall_at)
	print("StormWall origin: %s  seam (spoke road end): %s" % [origin, seam])
	print("Hall -> origin: %.1fm   Hall -> seam: %.1fm" % [
		hall_at.distance_to(origin), hall_at.distance_to(seam)])

	var meshes: Array = rift.call("meshes")
	for mesh: MeshInstance3D in meshes:
		if mesh == null or not is_instance_valid(mesh) or not mesh.name.begins_with("StormWall"):
			continue
		var pos := Vector2(mesh.global_position.x, mesh.global_position.z)
		var dist := hall_at.distance_to(pos)
		# The slab's own forward bearing is its rotation.y's inverse (it faces
		# BACK at the seam); the Hall-to-slab bearing compared to the
		# seam-to-slab bearing gives the off-axis angle.
		var seam_to_slab := (pos - seam).normalized()
		var hall_to_slab := (pos - hall_at).normalized()
		var off_axis_deg := rad_to_deg(seam_to_slab.angle_to(hall_to_slab))
		print("%s: pos=%s dist_from_hall=%.1fm off_axis_vs_seam=%.1fdeg" % [
			mesh.name, pos, dist, off_axis_deg])

	quit(0)

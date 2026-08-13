extends SceneTree

## EV7-clusters-fix scratch probe: real ground-truth numbers for the
## trainer_camp/bridge_repair_site placement fix, after a genuine blind
## critic failed trainer_camp and found real composition defects in
## bridge_repair_site on the shipped state (same pattern as EV6-remainder's
## _probe_ground.gd and EV7-remainder's own _probe_ev7r.gd). Loads the real
## playground scene so heights come from actual baked Terrain3D data and
## structure transforms come from the actual placed footbridge/mill, not
## hand-computed geometry or the pure heightfield function.
##
##   godot --headless --path . --script tools/_probe_ev7fix.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PROPS_DIR := "res://assets/props/quaternius_fantasy"


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 5:
		await process_frame

	var mill: Node3D = _find_by_name_prefix(world, "mill_") as Node3D
	var bridge: Node3D = _find_by_name_prefix(world, "footbridge_") as Node3D
	print("mill global_position: ", mill.global_position)
	print("footbridge global_position: ", bridge.global_position, " yaw(rad): ", bridge.rotation.y)

	print("-- trainer_camp: crate corner-height range by heading, real footprint (0.426 x 0.454 half-extent) --")
	print("   (found the -25deg heading EV7-remainder shipped had 0.226m of corner spread across the crate's")
	print("    own footprint on this meadow's real slope here; 165deg is the least-cant heading found)")
	var crate_half := Vector2(0.426, 0.454)
	for yd in [0.0, -25.0, 90.0, 165.0]:
		print("  yaw=%.0f range=%.3f" % [yd, _corner_range(world, Vector2(26.4, -28.9), crate_half, yd)])

	print("-- bridge_repair_site: local bridge-frame coords for the new anchor, off the deck/rail collider --")
	print("   (deck+landing collider half-extent: local x 6.1, z 1.05 -- building_prefabs.json 'footbridge')")
	for lc: Vector2 in [Vector2(-5.3, 1.4), Vector2(-4.5, 1.4), Vector2(-4.6, 1.75), Vector2(-5.7, 1.75)]:
		var wp: Vector3 = bridge.global_transform * Vector3(lc.x, 0.0, lc.y)
		print("  local %s -> world (%.3f,%.3f) ground_h=%.3f" % [lc, wp.x, wp.z, _ground_height(world, wp.x, wp.z)])

	print("-- Axe_Bronze: confirm it is authored vertical regardless of yaw (baked -90deg Z node rotation) --")
	for yd in [0.0, -110.0]:
		var b := _world_aabb(world, "Axe_Bronze", Vector3.ZERO, yd, 0.0, 0.0)
		print("  yaw=%.0f pitch=0 -> y range %.3f..%.3f (same span at any yaw confirms it, doesn't rotate flat)" % [yd, b.position.y, b.position.y + b.size.y])

	print("-- Axe_Bronze leaning against the crate: contact check at the shipped pitch_deg/yaw_deg/position --")
	var crate_aabb := _world_aabb(world, "Crate_Wooden", Vector3(-141.7, -20.7, 113.93), 20.0, 0.0, 0.0, 0.08)
	var axe_aabb := _world_aabb(world, "Axe_Bronze", Vector3(-140.9, -20.7, 114.0), -90.0, 38.0, 0.0)
	print("  crate x %.3f..%.3f" % [crate_aabb.position.x, crate_aabb.position.x + crate_aabb.size.x])
	print("  axe   x %.3f..%.3f (overlap with crate's east face = real contact, not just adjacent)" % [axe_aabb.position.x, axe_aabb.position.x + axe_aabb.size.x])
	print("  axe   y %.3f..%.3f vs ground -20.700 (low end embeds like a planted tool, same language as work_area's Pickaxe_Bronze)" % [axe_aabb.position.y, axe_aabb.position.y + axe_aabb.size.y])

	quit(0)


func _find_by_name_prefix(n: Node, prefix: String) -> Node:
	if str(n.name).begins_with(prefix):
		return n
	for c in n.get_children():
		var r := _find_by_name_prefix(c, prefix)
		if r != null:
			return r
	return null


func _find_with_method(n: Node, m: String) -> Node:
	if n.has_method(m):
		return n
	for c in n.get_children():
		var r := _find_with_method(c, m)
		if r != null:
			return r
	return null


func _ground_height(world: Node, x: float, z: float) -> float:
	var found := _find_with_method(world, "ground_height_at")
	if found == null:
		return NAN
	return float(found.call("ground_height_at", x, z))


func _corner_range(world: Node, anchor: Vector2, half: Vector2, yaw_deg: float) -> float:
	var yr := deg_to_rad(yaw_deg)
	var hs := []
	for c: Vector2 in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(-half.x, half.y), Vector2(half.x, half.y)]:
		var rc: Vector2 = c.rotated(yr)
		hs.append(_ground_height(world, anchor.x + rc.x, anchor.y + rc.y))
	var mn: float = hs[0]
	var mx: float = hs[0]
	for h in hs:
		mn = minf(mn, h)
		mx = maxf(mx, h)
	return mx - mn


## Mirrors props.gd::_place()'s transform exactly (position at anchor+sink,
## rotation Vector3(pitch,yaw,roll)) and returns the resulting WORLD-space
## combined mesh AABB, so a candidate placement can be checked against real
## ground height and a neighbouring prop's real position without a render.
func _world_aabb(world: Node, model: String, anchor: Vector3, yaw_deg: float, pitch_deg: float, roll_deg: float, sink: float = 0.0) -> AABB:
	var inst: Node3D = (load("%s/%s.gltf" % [PROPS_DIR, model]) as PackedScene).instantiate()
	world.add_child(inst)
	inst.position = anchor + Vector3(0.0, -sink, 0.0)
	inst.rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), deg_to_rad(roll_deg))

	var meshes: Array[MeshInstance3D] = []
	_collect(inst, meshes)
	var aabb := AABB()
	if not meshes.is_empty():
		aabb = meshes[0].global_transform * meshes[0].get_aabb()
		for i in range(1, meshes.size()):
			aabb = aabb.merge(meshes[i].global_transform * meshes[i].get_aabb())
	inst.queue_free()
	return aabb


func _collect(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for c in n.get_children():
		_collect(c, out)

extends SceneTree

## GATE-F-LEG-S10CDE follow-up. Terrain height alone (see
## _probe_s10c_stall.gd) shows no cliff near (13.47, -0.08, 7416.99) -- the
## stall must be a physics collider stick_navigator.gd's _free_space rays hit.
## Boots the real world, places a probe body-equivalent (just raw rays, no
## player needed) at the stall point, and fires horizontal rays in a full
## circle at the same three heights the navigator itself uses, to find what is
## actually standing there.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const STALL := Vector3(13.47, -0.08, 7416.99)
const HEIGHTS: Array[float] = [0.45, 0.95, 1.55]
const REACH := 12.0

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 90:
		await physics_frame

	var space: PhysicsDirectSpaceState3D = (world as Node3D).get_world_3d().direct_space_state
	print("=== rays from stall point %s, reach %.1fm ===" % [STALL, REACH])
	for height: float in HEIGHTS:
		print("-- height %.2f --" % height)
		for deg in range(0, 360, 15):
			var rad := deg_to_rad(float(deg))
			var dir := Vector3(sin(rad), 0.0, cos(rad))
			var from: Vector3 = STALL + Vector3.UP * height
			var query := PhysicsRayQueryParameters3D.create(from, from + dir * REACH)
			query.collide_with_areas = false
			query.hit_from_inside = true
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				print("  deg=%3d dir=%s : clear to %.1fm" % [deg, dir, REACH])
			else:
				var collider: Object = hit.get("collider")
				var pos: Vector3 = hit.get("position")
				var dist: float = from.distance_to(pos)
				var name := "?"
				var path := ""
				if collider is Node:
					name = (collider as Node).name
					path = str((collider as Node).get_path())
				print("  deg=%3d dir=%s : HIT %s at %.2fm, pos=%s, path=%s" % [
					deg, dir, name, dist, pos, path])

	# What's the nearest node (any type) to the stall point, brute force over
	# everything in the tree with a global_position, so a small/thin collider
	# with a body radius the rays might skim past still shows up.
	print("")
	print("=== nearest Node3Ds to the stall point (within 15m) ===")
	var candidates: Array = []
	_collect(world, candidates)
	candidates.sort_custom(func(a, b): return (a[1] as Vector3).distance_to(STALL) < (b[1] as Vector3).distance_to(STALL))
	var shown := 0
	for entry: Array in candidates:
		var node: Node3D = entry[0]
		var pos: Vector3 = entry[1]
		var d: float = pos.distance_to(STALL)
		if d > 15.0:
			continue
		print("  %.2fm  %s  %s  class=%s" % [d, node.get_path(), pos, node.get_class()])
		shown += 1
		if shown >= 40:
			break
	if shown == 0:
		print("  (nothing within 15m)")
	quit(0)


func _collect(node: Node, out: Array) -> void:
	if node is Node3D and (node is CollisionObject3D or node is StaticBody3D or node is Area3D):
		out.append([node, (node as Node3D).global_position])
	for child in node.get_children():
		_collect(child, out)

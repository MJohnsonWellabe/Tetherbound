extends SceneTree

## What is the player catching on at (53, -65)? `smoke_traversal.gd`'s move_back
## leg wedges there: grounded, input held, under 0.5m of travel for a second.
##
## Asked of the PHYSICS SERVER rather than the scene tree. A first pass walked
## the tree comparing each CollisionObject3D's global_position to the spot and
## found nothing within six metres -- which proves only that no collider's
## ORIGIN is nearby. Scattered vegetation and the terrain itself are single
## nodes carrying many far-flung shapes, so their origins sit elsewhere and a
## position comparison cannot see them at all.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const AT := Vector2(53.0, -65.0)

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame

	var space := root.world_3d.direct_space_state
	print("=== ground profile around (%.0f, %.0f) ===" % [AT.x, AT.y])
	var z := AT.y - 3.0
	while z <= AT.y + 3.001:
		var row := "  z=%+7.1f " % z
		var x := AT.x - 3.0
		while x <= AT.x + 3.001:
			var g: float = float(world.call("ground_height_at", x, z))
			row += ("  NaN " if is_nan(g) else "%6.2f" % g)
			x += 1.0
		print(row)
		z += 1.0

	print("=== what the physics server has near the spot ===")
	var z2 := AT.y - 3.0
	while z2 <= AT.y + 3.001:
		var x2 := AT.x - 3.0
		while x2 <= AT.x + 3.001:
			var g: float = float(world.call("ground_height_at", x2, z2))
			if is_nan(g):
				x2 += 1.0
				continue
			# A capsule the size of a standing player, one metre up: exactly
			# what would have to be clear for them to walk through here.
			var shape := CapsuleShape3D.new()
			shape.radius = 0.4
			shape.height = 1.8
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = shape
			q.transform = Transform3D(Basis(), Vector3(x2, g + 1.0, z2))
			q.collide_with_areas = false
			q.collide_with_bodies = true
			var hits := space.intersect_shape(q, 16)
			for h in hits:
				var col: Object = h.get("collider")
				if col == null:
					continue
				var n := col as Node
				print("  (%.0f, %.0f) blocked by %s  (%s)" % [
					x2, z2, (n.get_path() if n != null else str(col)),
					(n.get_class() if n != null else "?")])
			x2 += 1.0
		z2 += 1.0
	print("=== done ===")
	quit(0)

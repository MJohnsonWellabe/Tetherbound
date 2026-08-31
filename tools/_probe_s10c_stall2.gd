extends SceneTree

## GATE-F-LEG-S10CDE. S10c AND S10d both got permanently wedged at
## approximately (-4..-10, -5, 7352), with continuous runaway-velocity clamp
## warnings every physics frame and literally zero net displacement -- unlike
## the first stall (13.47,7417), this one never releases. The horizontal
## _free_space-style ray probe already found nothing within 15m at this spot
## (see _probe_s10c_stall_collision.gd), which rules out a wall. This checks
## the vertical axis instead: does the player's actual resting Y match the
## analytic heightfield, or is the body slightly EMBEDDED in the baked
## collision mesh (which would explain continuous depenetration pressure
## reading as runaway velocity with no net movement)?

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPOT := Vector3(-7.0, 20.0, 7352.0)

func _init() -> void:
	_run()

func _run() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	print("=== analytic heightfield near the pin point ===")
	for dz in range(-6, 7, 2):
		var row := ""
		for dx in range(-6, 7, 2):
			var h: float = field.height_at(SPOT.x + dx, SPOT.z + dz)
			row += "%8.3f" % h
		print("z=%7.1f : %s" % [SPOT.z + dz, row])
	var analytic: float = field.height_at(SPOT.x, SPOT.z)
	print("analytic height at (%.1f,%.1f): %.4f" % [SPOT.x, SPOT.z, analytic])

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 90:
		await physics_frame

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player == null:
		print("no Player node")
		quit(1)
		return
	player.global_position = SPOT
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO

	print("")
	print("=== settling from y=20 at the exact pin point ===")
	for i in 300:
		await physics_frame
		if i % 5 == 0:
			var cb := player as CharacterBody3D
			print("f=%3d y=%.4f on_floor=%s vel=%s floor_normal=%s" % [
				i, player.global_position.y, cb.is_on_floor(), cb.velocity,
				cb.get_floor_normal() if cb.is_on_floor() else Vector3.ZERO])
			if i > 0 and i % 50 == 0:
				print("  (x,z) drift: %s" % Vector2(player.global_position.x - SPOT.x, player.global_position.z - SPOT.z))

	print("")
	print("final position: %s" % player.global_position)
	print("analytic height was: %.4f -- delta from final Y: %.4f" % [
		analytic, player.global_position.y - analytic])

	# Direct downward+upward probes from well above/below to see exactly
	# where the collision surface actually is, independent of the character
	# controller's own resolution.
	var space: PhysicsDirectSpaceState3D = (world as Node3D).get_world_3d().direct_space_state
	var down_query := PhysicsRayQueryParameters3D.create(
		SPOT + Vector3.UP * 30.0, SPOT + Vector3.DOWN * 30.0)
	down_query.collide_with_areas = false
	var hit := space.intersect_ray(down_query)
	if hit.is_empty():
		print("straight-down ray from y=+30 to y=-10 at this (x,z): NO HIT")
	else:
		print("straight-down ray hit at y=%.4f (collider %s)" % [
			(hit["position"] as Vector3).y, (hit.get("collider") as Node).name if hit.get("collider") is Node else "?"])
	quit(0)

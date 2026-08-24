extends SceneTree

## GATEB-COORD diagnostic. What is actually in the way at the point
## `tools/_probe_walk_leg.gd` oscillates around?
##
##   godot --headless --path . --script tools/_probe_stuck_point.gd
##
## The walk probe showed the player orbiting (-24, -18) and dropping from y=5
## to y=1 on the way, which reads like a body starting INSIDE the opening
## bedroom and failing to get out of it. This says so or rules it out: it casts
## the navigator's own hip-height ray in sixteen directions and names every
## collider it finds, at the spawn point and at the stall point.
##
## A probe, not evidence.

const SCENE := "res://scenes/world/meadows_playground.tscn"


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for _i in 300:
		await physics_frame
	var player := _find(world, "locomotion_enabled") as Node3D
	if player == null:
		print("PROBE: no player")
		quit(1)
		return
	print("PROBE spawn %s" % str(player.global_position))
	_sweep(player, player.global_position, "SPAWN")
	_sweep(player, Vector3(-24.0, 1.0, -18.0), "STALL POINT (-24, 1, -18)")
	_sweep(player, Vector3(-26.0, 5.0, -18.0), "FIRST WALL (-26, 5, -18)")

	var terrain := get_first_node_in_group(&"terrain")
	if terrain != null and terrain.has_method("ground_height_at"):
		print("\nPROBE ground height: spawn=%.2f stall=%.2f target=%.2f" % [
			float(terrain.call("ground_height_at", -25.0, -16.0)),
			float(terrain.call("ground_height_at", -24.0, -18.0)),
			float(terrain.call("ground_height_at", -56.0, -51.0))])
	quit(0)


func _sweep(player: Node3D, at: Vector3, what: String) -> void:
	print("\n=== %s ===" % what)
	var space := player.get_world_3d().direct_space_state
	for i in 16:
		var angle := TAU * float(i) / 16.0
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var from := at + Vector3.UP * 1.0
		var query := PhysicsRayQueryParameters3D.create(from, from + dir * 6.0)
		query.collide_with_areas = false
		if player is CollisionObject3D:
			query.exclude = [(player as CollisionObject3D).get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var collider: Variant = hit.get("collider")
		var name := str((collider as Node).name) if collider is Node else "<?>"
		var owner_path := ""
		if collider is Node and (collider as Node).get_parent() != null:
			owner_path = str((collider as Node).get_parent().name)
		print("  %3d deg  %5.2fm  %s / %s" % [
			int(rad_to_deg(angle)), from.distance_to(hit.get("position") as Vector3),
			owner_path, name])


func _find(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child: Node in node.get_children():
		var found := _find(child, method)
		if found != null:
			return found
	return null

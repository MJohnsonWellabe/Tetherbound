extends SceneTree

## T2-GATEF-RUN4: what physical collider is actually sitting at the S03-60
## stuck point (18.76, -3.18), where tools/gate_f/probe_oskar_walk_trace.gd
## shows the walker pinned regardless of which direction it is sent.
##
##   godot --headless --path . --script tools/gate_f/probe_oskar_stuck_geometry.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240


func _init() -> void:
	_run()


func _run() -> void:
	var world := (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var points := [
		Vector3(18.75923, 0.9, -3.184831),
		Vector3(18.37083, 0.9, -3.572382),
		Vector3(15.34967, 0.9, -2.7071),
		Vector3(17.2929, 0.9, -4.650322),
		Vector3(18.0, 0.9, -2.0),
	]
	for p in points:
		var query := PhysicsShapeQueryParameters3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.6
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY, p)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hits: Array = space.intersect_shape(query, 8)
		print("--- near %s ---" % str(p))
		for hit: Dictionary in hits:
			var collider: Object = hit.get("collider")
			var owner_node: Node = collider as Node
			var path := str(owner_node.get_path()) if owner_node != null else "?"
			print("  hit: %s  (%s)" % [path, collider])

	quit(0)

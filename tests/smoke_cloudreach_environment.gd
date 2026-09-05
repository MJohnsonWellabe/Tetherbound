extends SceneTree

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	var world := SCENE.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8:
		await physics_frame
	var failures: Array[String] = []
	var resources := world.get_node("CloudreachResources")
	if resources.get_child_count() != 10:
		failures.append("Expected ten gatherable resources")
	for resource: Node3D in resources.get_children():
		var at := resource.global_position
		if resource.name == "cr_node_sunleaf_shrine" and (at.x < 700.0 or at.z > 3500.0):
			failures.append("Sunleaf escaped its Fly-only High Roost region")
		if resource.name in ["cr_node_cloudberry_waycamp","cr_node_gale_fiber_gate"] and at.z>400:
			failures.append("Arrival resource beat escaped the pre-camp road")
		var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.3, at - Vector3.UP * 0.5)
		var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			failures.append("%s has no real floor at %s" % [resource.name, at])
		print("CLOUDREACH RESOURCE PLACED %s at %s authored=%s" % [resource.name, at, resource.get_meta("authored_position")])
	var cover := world.get_node("ProceduralGroundCover")
	if world.get_node_or_null("ArrivalRoadObservation/InspectArrivalRuin")==null:
		failures.append("Optional arrival observation is absent")
	if not bool(cover.call("_excluded", Vector3(-281.5, 180.05, 509.5))):
		failures.append("Candy courtyard did not exclude outdoor cover")
	if world.get_node("DistantHighlandRanges").get_child_count() != 10:
		failures.append("Layered horizon ranges are absent")
	if failures.is_empty():
		print("CLOUDREACH ENVIRONMENT OK ten resources have physical supporting floors, courtyard clear, horizon ranges present")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

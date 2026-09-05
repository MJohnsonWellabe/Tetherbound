extends SceneTree

## Real-scene Phase 2 foundation smoke. This intentionally instances the same
## scene the realm registry enters, lets CharacterBody collision settle, and
## checks authored world output rather than testing the JSON alone.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 8:
		await physics_frame
	var failures: Array[String] = []
	_expect(int(world.call("region_count")) == 6, "world did not build all six regions", failures)
	_expect(int(world.call("landmark_count")) >= 12, "world did not build its landmark set", failures)
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	_expect(player != null, "production Player is absent", failures)
	if player != null:
		var ground := float(world.call("ground_height_at", player.global_position.x, player.global_position.z))
		_expect(not is_nan(ground), "entry anchor has no authored ground", failures)
		_expect(absf(player.global_position.y - ground) < 2.0,
			"Player did not settle on entry ground (player %.2f, ground %.2f)" % [player.global_position.y, ground], failures)
	var bridges := world.get_node_or_null(^"SuspendedBridges")
	_expect(bridges != null and bridges.get_child_count() == 5,
		"five authored bridges were not constructed", failures)
	var routes := world.get_node_or_null(^"AuthoredRoutes")
	_expect(routes != null and routes.get_child_count() > 20,
		"ground route geometry is missing", failures)
	var cover := world.get_node_or_null(^"ProceduralGroundCover")
	_expect(cover != null, "procedural grass/flower cover is absent", failures)
	if cover != null:
		_expect(int(cover.call("grass_instance_count")) >= 40000,
			"Cloudreach grass carpet is too sparse", failures)
		_expect(int(cover.call("flower_instance_count")) >= 1200,
			"Cloudreach flower drifts are too sparse", failures)
		_expect(int(cover.call("bush_instance_count")) >= 300,
			"Cloudreach understorey is too sparse", failures)
	_expect(world.find_children("*", "StaticBody3D", true, false).size() > 40,
		"foundation did not build solid collision", failures)
	if failures.is_empty():
		print("CLOUDREACH FOUNDATION OK regions=%d landmarks=%d bridges=%d player=%s" % [
			int(world.call("region_count")), int(world.call("landmark_count")),
			bridges.get_child_count(), str(player.global_position if player != null else Vector3.ZERO)])
		quit(0)
		return
	for failure: String in failures:
		push_error("CLOUDREACH FOUNDATION: %s" % failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)

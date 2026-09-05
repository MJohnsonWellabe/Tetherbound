extends SceneTree

## Continuous production-controller walk from the realm arrival to Aila.
## Time is accelerated with matching physics frequency, preserving the normal
## simulation step and movement speed. No position writes after scene entry.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
var _player: CharacterBody3D
var _world: Node3D
var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	var flags: RefCounted = game.get("progression")
	flags.call("set_flag", "realm_key_cloudreach")
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	for _frame in 20:
		await physics_frame
	var routes: Array = (_world.call("config_data") as Dictionary).get("routes", [])
	var points: Array[Vector3] = []
	for route: Dictionary in routes:
		if str(route["id"]) == "arrival_gate_road":
			for raw: Array in route["polyline"].slice(1):
				points.append(Vector3(float(raw[0]), float(raw[1]), float(raw[2])))
	# The final approach stays on the authored road until the camp terrace.
	points[points.size() - 1] = Vector3(-280, 180, 508)
	points.append(Vector3(-275, 180, 517.8))
	for at: Vector3 in points:
		if not await _walk_to(at):
			_failed = true
			break
	_release_move()
	for _frame in 20:
		await physics_frame
	if not bool(flags.call("has", "cloudreach_chapter_started")):
		_failed = true
		push_error("Continuous arrival did not reach Galefoot Waycamp")
	var arbiter := _world.get_node(^"InteractionArbiter")
	arbiter.call("_recompute")
	var chapter := _world.get_node(^"CloudreachChapter")
	var bodies: Dictionary = chapter.call("npc_bodies")
	var aila_prompt: Node = bodies["warden_aila"].get_node(^"Interactable")
	if arbiter.get("_winning_provider") != aila_prompt:
		_failed = true
		push_error("Continuous arrival did not reach Aila's offered interaction")
	if _world.find_children("Warden Aila", "", true, false).size() != 1:
		_failed = true
		push_error("Continuous arrival found duplicate Aila bodies")
	print("CLOUDREACH ARRIVAL WALK %s player=%s" % ["FAIL" if _failed else "OK", _player.global_position])
	quit(1 if _failed else 0)


func _walk_to(target: Vector3) -> bool:
	var camera := _world.get_node(^"CameraRig")
	var last_progress := _player.global_position
	var stalled := 0
	var last_wall := ""
	var walls_seen: Dictionary = {}
	for frame in 16000:
		var offset := target - _player.global_position
		offset.y = 0
		if offset.length() < 0.65:
			print("ARRIVAL WALK reached %s" % _player.global_position)
			return true
		var local: Vector3 = (camera.call("planar_basis") as Basis).inverse() * offset.normalized()
		Input.action_press("move_right", maxf(local.x, 0))
		Input.action_press("move_left", maxf(-local.x, 0))
		Input.action_press("move_back", maxf(local.z, 0))
		Input.action_press("move_forward", maxf(-local.z, 0))
		await physics_frame
		for collision_index in _player.get_slide_collision_count():
			var hit := _player.get_slide_collision(collision_index)
			if absf(hit.get_normal().y) < 0.5:
				last_wall = str(hit.get_collider().get_path())
				if not walls_seen.has(last_wall):
					walls_seen[last_wall] = true
					print("ARRIVAL WALK first contact %s at=%s normal=%s" % [last_wall, _player.global_position, hit.get_normal()])
		var ground: float = float(_world.call("ground_height_near", _player.global_position))
		if (not is_nan(ground) and _player.global_position.y < ground - 4.0) or _player.global_position.y < 90.0:
			push_error("Arrival walk left the road at %s; last wall=%s" % [_player.global_position, last_wall])
			return false
		if frame % 120 == 0:
			if _player.global_position.distance_to(last_progress) < 0.4:
				stalled += 1
			else:
				stalled = 0
			last_progress = _player.global_position
			if stalled >= 3:
				for collision_index in _player.get_slide_collision_count():
					var hit := _player.get_slide_collision(collision_index)
					print("ARRIVAL WALK collision %s normal=%s" % [hit.get_collider().get_path(), hit.get_normal()])
				push_error("Arrival walk stuck at %s toward %s" % [_player.global_position, target])
				return false
	push_error("Arrival walk timed out at %s toward %s" % [_player.global_position, target])
	return false


func _release_move() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)

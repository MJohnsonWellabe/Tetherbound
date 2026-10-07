extends "res://tests/capture_village_walk.gd"

## F17 integration witness: inherited production-camera look-stick and
## movement input, real collision, farmhouse doorway -> Main Street -> Hall.
## One disclosed initial post-opening fixture placement; no mid-route teleport,
## speed adjustment, collision removal, scene pruning or progression earning.
const VILLAGE_CONFIG := "res://data/config/village.json"
const SHELL_BUILD_WAIT_FRAMES := 9000 # 150 s at 60 Hz; the world-build allowance the net smokes use.
const TERRAIN_CACHE := preload("res://scripts/world/terrain_bake.gd")
const SCATTER_CACHE := preload("res://scripts/world/scatter_bake.gd")


func _run() -> void:
	_headless = DisplayServer.get_name() == "headless"
	_route_name = "hall-redesign"
	_capture_dir = ProjectSettings.globalize_path("user://f17-hall-walk")
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	_terrain = _json(TERRAIN_PATH)
	var authored_seed := int(_terrain.get("seed", -1))
	if not TERRAIN_CACHE.is_generation_usable() or not SCATTER_CACHE.is_usable("playground", authored_seed):
		_finish_failure("production regional terrain/scatter generation is not usable")
		return
	await process_frame
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_finish_failure("Game autoload missing")
		return
	var progression: RefCounted = _game.get("progression")
	for flag: String in OPENING_FLAGS:
		progression.call("set_flag", flag)
	var party: RefCounted = _game.get("party")
	if (party.call("members") as Array).is_empty():
		party.call("add", _game.call("make_creature", "terrapup"))
	var packed := load(SCENE) as PackedScene
	if packed == null:
		_finish_failure("production Meadows scene missing")
		return
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for _frame in SETTLE_FRAMES:
		await physics_frame
	# Forward+ (Medium/High) builds the world shell in time slices after boot
	# (~72 s on the render-service GPU, f17-1), so the fixed settle can end
	# before the house and Hall exist. Wait for the world's own completion
	# signal too, frame-bounded; every check below is unchanged.
	if _world.has_method("shell_build_complete"):
		for _frame in SHELL_BUILD_WAIT_FRAMES:
			if bool(_world.call("shell_build_complete")):
				break
			await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	var house := _world.get_node_or_null(^"GrandpaHouse") as Node3D
	var halls := get_nodes_in_group("crossing_halls")
	var terrain := _world.get_node_or_null(^"Terrain")
	if _player == null or _rig == null or house == null or halls.size() != 1 or terrain == null:
		_finish_failure("missing real player/camera/house/Hall/Terrain")
		return
	var sequence := _world.get_node_or_null(^"SequenceDirector")
	var door_gate := house.get("_door_gate_shape") as CollisionShape3D
	print("F17 opening binding: director_house_matches=%s beat=%s gate_disabled=%s" % [
		sequence != null and sequence.get("_house") == house,
		str(sequence.get("_beat")) if sequence != null else "missing",
		door_gate != null and door_gate.disabled])
	if sequence == null or sequence.get("_house") != house or door_gate == null or not door_gate.disabled:
		_finish_failure("actual post-opening director did not bind/open the mounted farmhouse door")
		return
	var terrain_data: Object = terrain.get("data")
	if terrain_data == null or int(terrain_data.call("get_region_count")) != 64:
		_finish_failure("production Terrain3D did not load all 64 mixed-generation regions")
		return
	var hall := halls[0] as Node3D
	if get_nodes_in_group("crossing_hall_arches").size() != 8:
		_finish_failure("actual Hall does not contain eight ordered arches")
		return
	var plan: Dictionary = _json(VILLAGE_CONFIG).get("road_plan", {})
	var road_start := _v(plan.get("road_start", []))
	var road_end := _v(plan.get("road_end", []))
	var home_door: Vector3 = house.call("marker", "door")
	if Vector2(home_door.x, home_door.z).distance_to(road_start) > 0.05:
		_finish_failure("actual farmhouse doorway does not match authored road start")
		return
	var hall_centre := _v(plan.get("hall_centre", []))
	if Vector2(hall.global_position.x, hall.global_position.z).distance_to(hall_centre) > 0.05:
		_finish_failure("actual Hall does not match authored destination")
		return
	var inside := road_start - Vector2(2.5, 0)
	_player.global_position = Vector3(inside.x, house.global_position.y + 0.8, inside.y)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", _yaw_toward(inside, road_start))
	for _frame in 30:
		await physics_frame
	if not _player.is_on_floor():
		_finish_failure("initial actual farmhouse floor has no player collision")
		return
	_path = PackedVector2Array([inside, road_start, road_end, hall_centre])
	_arcs = PackedFloat32Array([0.0])
	for index in range(1, _path.size()):
		_arcs.append(_arcs[index - 1] + _path[index - 1].distance_to(_path[index]))
	_road_from_arc = _arcs[1]
	_road_until_arc = _arcs[2]
	_painted_half = float(plan.get("width_m", 0)) * 0.5
	_events = [{"arc": _arcs[1], "label": "actual farmhouse doorway"},
		{"arc": _arcs[2], "label": "Main Street end / Hall approach"},
		{"arc": _arcs[3] - 0.5, "label": "inside Hall nave"}]
	print("F17 shortcuts: authored post-opening flags/starter; one initial farmhouse floor placement; inherited parsed joypad/camera inputs; renderer=%s; no earned tutorial/device/visual claim" % DisplayServer.get_name())
	print("F17 world: terrain64regions actualdoor=%s Hall=%s path=%s" % [home_door, hall.global_position, _path])
	await _walk()
	_release_all()
	if not _failed.is_empty():
		_finish_failure(_failed)
		return
	var local_arrival := hall.to_local(_player.global_position)
	if Vector2(_player.global_position.x, _player.global_position.z).distance_to(hall_centre) > 0.75 or not _player.is_on_floor():
		_finish_failure("actual body did not reach the Hall nave on collision: local=%s on_floor=%s" % [local_arrival, _player.is_on_floor()])
		return
	print("F17 actual farmhouse door -> straight Main Street -> Hall nave PASS: player=%s Halllocal=%s maximum_offroad=%.3f" % [_player.global_position, local_arrival, _max_off_road])
	if not await _after_hall_arrival(hall):
		_finish_failure(_failed)
		return
	quit(0)


func _after_hall_arrival(_hall: Node3D) -> bool:
	return true


func _finish_failure(reason: String) -> void:
	_release_all()
	print("F17 actual Hall walk FAIL: " + reason)
	quit(1)

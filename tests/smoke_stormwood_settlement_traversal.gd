extends SceneTree

## Production Stormwood settlement traversal proof.
##
##   godot --headless --path . --script tests/smoke_stormwood_settlement_traversal.gd
##
## The settlement-grounding unit test pins authored coordinates and analytic
## heights. This smoke answers the physical question that data cannot: can the
## production player's real 0.4m-radius capsule cross each baked approach,
## pass the actual door/arch collision, stand inside the real prefab, and then
## be stopped by its authored side wall? Closed door leaves are tested first,
## then opened through village_door.gd's production state change. Workshops
## have no leaf; their permanently open arch is traversed directly.

const GAME := preload("res://autoload/game_state.gd")
const STORMWOOD_SCENE := preload("res://scenes/world/stormwood.tscn")
const PREFABS := preload("res://scripts/world/building_prefabs.gd")

const SETTLEMENT_PATH := "res://data/config/stormwood_settlements.json"
const TERRAIN_PATH := "res://data/config/terrain_stormwood.json"
const BUILD_DEADLINE_MS := 180000
const WATCHDOG_SECONDS := 240.0
const PARK_FRAMES := 24
const OPEN_SETTLE_FRAMES := 4
const WALK_SPEED_MPS := 6.0
const GRAVITY_MPS2 := 26.0
const APPROACH_M := 3.0
const INTERIOR_M := 2.0
const WALK_FRAMES := 100
const CLOSED_WALK_FRAMES := 50
const WALL_WALK_FRAMES := 70
const FLOOR_RELIEF_LIMIT_M := 0.22

var _failures: Array[String] = []
var _finished := false
var _world: Node3D
var _player: CharacterBody3D
var _prefabs: RefCounted
var _only_id := ""
var _traversed := 0
var _expected := 9


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(WATCHDOG_SECONDS).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "%.0f second watchdog expired" % WATCHDOG_SECONDS)
			_finish())
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	game.call("reset_for_new_game")
	game.set("current_realm", "stormwood")
	game.call("announce_realm", "meadows", "stormwood")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			_only_id = argument.substr("--only=".length()).strip_edges()

	_world = STORMWOOD_SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	if not await _wait_for_shell():
		_expect(false, "production Stormwood did not finish building")
		_finish()
		return
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	var village := _world.get_node_or_null(^"RodfolkSettlements") as Node3D
	_expect(_player != null and village != null,
		"production Stormwood is missing its Player or RodfolkSettlements")
	if _player == null or village == null:
		_finish()
		return
	# Keep the production body, shape, masks, floor settings and move_and_slide;
	# only stop player_controller.gd from applying simultaneous input velocity.
	_player.set_physics_process(false)
	_prefabs = PREFABS.new()
	_expect(bool(_prefabs.call("load_recipes")), "building prefab recipes did not load")
	if not _failures.is_empty():
		_finish()
		return

	var settlements := _json(SETTLEMENT_PATH)
	var pads := _pads_by_id(_json(TERRAIN_PATH))
	_expected = 1 if not _only_id.is_empty() else 9
	for index in (settlements.get("structures", []) as Array).size():
		var raw: Variant = (settlements.get("structures", []) as Array)[index]
		if not raw is Dictionary:
			continue
		var structure := raw as Dictionary
		var id := str(structure.get("id", ""))
		if not pads.has(id):
			continue
		if not _only_id.is_empty() and id != _only_id:
			continue
		var building_name := "%s_%d" % [str(structure.get("prefab", "")), index]
		var building := village.get_node_or_null(NodePath(building_name)) as Node3D
		if building == null:
			_expect(false, "%s did not instantiate as %s" % [id, building_name])
			continue
		await _traverse(id, building, structure, pads[id] as Dictionary)
		_traversed += 1
	_expect(_traversed == _expected, "traversed %d settlement pads, expected %d" % [
		_traversed, _expected])
	_finish()


func _traverse(id: String, building: Node3D, structure: Dictionary, _pad: Dictionary) -> void:
	var prefab_name := str(structure.get("prefab", ""))
	var recipe: Dictionary = _prefabs.call("recipe", prefab_name)
	var door_spec: Dictionary = _prefabs.call("door_spec", prefab_name)
	var support := _support_rect(recipe)
	_expect(not support.is_empty(), "%s has no ground-touching collider support" % id)
	if support.is_empty():
		return
	var threshold_local := Vector3(0.0, 0.0, float(support.max_z))
	if not door_spec.is_empty():
		var door_at: Array = door_spec.get("at", [0.0, 0.0, 0.0])
		threshold_local = Vector3(float(door_at[0]), 0.0, float(door_at[2]))
	var outward := building.global_transform.basis.z
	outward.y = 0.0
	outward = outward.normalized()
	var threshold := building.to_global(threshold_local)
	var start_xz := threshold + outward * APPROACH_M
	var start := Vector3(start_xz.x,
		float(_world.call("ground_height_at", start_xz.x, start_xz.z)) + 0.10,
		start_xz.z)
	await _park(start)

	var collision := building.get_node_or_null(^"Collision") as StaticBody3D
	_expect(collision != null and collision.get_child_count() > 0,
		"%s has no instantiated authored collision" % id)
	var door := building.get_node_or_null(^"Door") as Node3D
	if not door_spec.is_empty():
		_expect(door != null, "%s recipe declares a door but built no Door" % id)
		_expect(building.get_node_or_null(^"Interior") != null,
			"%s opened shell has no instantiated Interior" % id)
		if door == null:
			return
		var gate_shape := door.get("_gate_shape") as CollisionShape3D
		if gate_shape == null:
			gate_shape = _door_gate_shape(door)
		_expect(gate_shape != null and not gate_shape.disabled,
			"%s closed door has no enabled blocking shape" % id)
		if gate_shape == null:
			return
		print("  %-27s door shape=%s open=%s disabled=%s" % [
			id, str(gate_shape.get_path()), str(door.call("is_open")), str(gate_shape.disabled)])
		var closed_start := _player.global_position
		var closed_motion := await _walk(-outward, CLOSED_WALK_FRAMES, INF, building)
		var closed_local := building.to_local(_player.global_position)
		var closed_progress := (_player.global_position - closed_start).dot(-outward)
		_expect(closed_progress > 0.7,
			"%s player never reached the closed door (%.2fm progress)" % [id, closed_progress])
		_expect(closed_local.z > threshold_local.z + 0.25,
			"%s player crossed the closed door (local z %.2f)" % [id, closed_local.z])
		_expect(float(closed_motion.get("relief", INF)) <= FLOOR_RELIEF_LIMIT_M,
			"%s approach varied %.2fm before its closed door" % [id, float(closed_motion.get("relief", INF))])
		door.call("force_open", true)
		await _frames(OPEN_SETTLE_FRAMES)
		_expect(bool(door.call("is_open")) and gate_shape.disabled,
			"%s door state opened without disabling its blocking shape" % id)
	else:
		_expect(prefab_name == "workshop",
			"%s has a pad but neither a door nor the authored open workshop arch" % id)
		var workshop_interior := building.get_node_or_null(^"Interior") as Node3D
		_expect(workshop_interior != null and workshop_interior.get_child_count() >= 7,
			"%s open workshop has no shared physical dressing" % id)
		_measure_workshop_depth(id, building, threshold, outward)

	var needed := maxf(0.0, (_player.global_position - threshold).dot(outward) + INTERIOR_M)
	var crossing := await _walk(-outward, WALK_FRAMES, needed, building)
	var inside_local := building.to_local(_player.global_position)
	var entered := inside_local.z <= threshold_local.z - INTERIOR_M + 0.35
	_expect(entered,
		"%s opening blocked: stopped at local z %.2f, threshold %.2f" % [
			id, inside_local.z, threshold_local.z])
	if not entered:
		_print_contacts(id, crossing.get("contacts", {}))
		return
	_expect(float(crossing.get("relief", INF)) <= FLOOR_RELIEF_LIMIT_M,
		"%s approach/room floor varied %.2fm during traversal" % [id, float(crossing.get("relief", INF))])
	_expect(_player.is_on_floor(), "%s player is not supported inside the room" % id)

	# A passage without containment would also be a broken building. Drive the
	# same body sideways into the nearest authored wall and prove it cannot
	# leave the support footprint through that solid run.
	var side_sign := 1.0 if inside_local.x >= 0.0 else -1.0
	var side := building.global_transform.basis.x * side_sign
	side.y = 0.0
	side = side.normalized()
	await _walk(side, WALL_WALK_FRAMES, INF, building)
	var wall_local := building.to_local(_player.global_position)
	var wall_limit := float(support.max_x) if side_sign > 0.0 else float(support.min_x)
	var contained := wall_local.x <= wall_limit - 0.20 if side_sign > 0.0 \
		else wall_local.x >= wall_limit + 0.20
	_expect(contained,
		"%s player passed through its side wall (local x %.2f, support %.2f)" % [
			id, wall_local.x, wall_limit])
	print("  %-27s OPEN floor_relief=%.3fm inside_z=%.2f wall_x=%.2f" % [
		id, float(crossing.get("relief", 0.0)), inside_local.z, wall_local.x])


func _measure_workshop_depth(id: String, building: Node3D, threshold: Vector3,
		outward: Vector3) -> void:
	# At eye/chest height the first solid behind the centre of the open arch
	# must be its real rear wall, about 8m behind the threshold. A near hit would
	# prove the new pale shape is an obstruction rather than visible depth.
	var from := threshold + outward * 0.7 + Vector3.UP * 1.15
	var query := PhysicsRayQueryParameters3D.create(from, from - outward * 10.0)
	query.collide_with_areas = false
	query.hit_from_inside = true
	query.exclude = [_player.get_rid()]
	query.collision_mask = _player.collision_mask
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(query)
	_expect(not hit.is_empty(), "%s arch ray found no rear wall" % id)
	if hit.is_empty():
		return
	var hit_position: Vector3 = hit.get("position", from)
	var depth := (hit_position - from).dot(-outward)
	var local_hit := building.to_local(hit_position)
	_expect(depth >= 7.7 and depth <= 9.1,
		"%s arch first hits at %.2fm/local z %.2f instead of the rear wall" % [
			id, depth, local_hit.z])
	print("  %-27s arch first solid depth=%.2fm local_z=%.2f" % [id, depth, local_hit.z])


func _door_gate_shape(door: Node3D) -> CollisionShape3D:
	var gate := door.get_node_or_null(^"Gate")
	if gate == null:
		return null
	for child: Node in gate.get_children():
		if child is CollisionShape3D:
			return child as CollisionShape3D
	return null


func _walk(direction: Vector3, frames: int, stop_after_m: float,
		building: Node3D = null) -> Dictionary:
	var start := _player.global_position
	var min_y := start.y
	var max_y := start.y
	var best := 0.0
	var contacts := {}
	for _frame in frames:
		_player.velocity.x = direction.x * WALK_SPEED_MPS
		_player.velocity.z = direction.z * WALK_SPEED_MPS
		_player.velocity.y = -0.5 if _player.is_on_floor() \
			else _player.velocity.y - GRAVITY_MPS2 / 60.0
		_player.move_and_slide()
		for index in _player.get_slide_collision_count():
			var collision := _player.get_slide_collision(index)
			var collider: Object = collision.get_collider()
			var collider_path := str(collider)
			var script_path := ""
			var collider_position := Vector3.ZERO
			if collider is Node:
				collider_path = str((collider as Node).get_path())
				var script: Variant = (collider as Node).get_script()
				if script is Script:
					script_path = str((script as Script).resource_path)
			if collider is Node3D:
				collider_position = (collider as Node3D).global_position
			var owner_path := ""
			if collider is CollisionObject3D:
				var object := collider as CollisionObject3D
				var owner_id := object.shape_find_owner(collision.get_collider_shape_index())
				if owner_id >= 0:
					var owner: Object = object.shape_owner_get_owner(owner_id)
					if owner is Node:
						owner_path = str((owner as Node).get_path())
			var contact_position: Vector3 = collision.get_position()
			var key := "%s#%d" % [collider_path, collision.get_collider_shape_index()]
			contacts[key] = {
				"collider": collider_path,
				"script": script_path,
				"shape_owner": owner_path,
				"collider_position": collider_position,
				"collider_local": building.to_local(collider_position) if building != null else Vector3.ZERO,
				"contact": contact_position,
				"contact_local": building.to_local(contact_position) if building != null else Vector3.ZERO,
				"normal": collision.get_normal(),
			}
		await physics_frame
		min_y = minf(min_y, _player.global_position.y)
		max_y = maxf(max_y, _player.global_position.y)
		best = maxf(best, (_player.global_position - start).dot(direction))
		if best >= stop_after_m:
			break
	return {"progress": best, "relief": max_y - min_y, "contacts": contacts}


func _print_contacts(id: String, contacts: Dictionary) -> void:
	if contacts.is_empty():
		print("  %-27s BLOCKED with no move_and_slide contacts" % id)
		return
	for key: Variant in contacts:
		var hit := contacts[key] as Dictionary
		print("  %-27s CONTACT collider=%s owner=%s script=%s collider_world=%s collider_local=%s point=%s point_local=%s normal=%s" % [
			id, str(hit.collider), str(hit.shape_owner), str(hit.script),
			str(hit.collider_position), str(hit.collider_local), str(hit.contact),
			str(hit.contact_local), str(hit.normal)])


func _park(at: Vector3) -> void:
	for _frame in PARK_FRAMES:
		_player.velocity = Vector3.ZERO
		_player.global_position = at
		await physics_frame


func _support_rect(recipe: Dictionary) -> Dictionary:
	var out := {"min_x": INF, "max_x": -INF, "min_z": INF, "max_z": -INF}
	for raw: Variant in recipe.get("colliders", []):
		if not raw is Dictionary:
			continue
		var collider := raw as Dictionary
		var at: Array = collider.get("at", [])
		var size: Array = collider.get("size", [])
		if at.size() < 3 or size.size() < 3:
			continue
		if float(at[1]) - float(size[1]) * 0.5 > 0.15:
			continue
		out.min_x = minf(float(out.min_x), float(at[0]) - float(size[0]) * 0.5)
		out.max_x = maxf(float(out.max_x), float(at[0]) + float(size[0]) * 0.5)
		out.min_z = minf(float(out.min_z), float(at[2]) - float(size[2]) * 0.5)
		out.max_z = maxf(float(out.max_z), float(at[2]) + float(size[2]) * 0.5)
	return {} if float(out.min_x) > float(out.max_x) else out


func _pads_by_id(config: Dictionary) -> Dictionary:
	var out := {}
	for raw: Variant in config.get("settlement_pads", []):
		if raw is Dictionary:
			out[str((raw as Dictionary).get("id", ""))] = raw
	return out


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _wait_for_shell() -> bool:
	var deadline := Time.get_ticks_msec() + BUILD_DEADLINE_MS
	while is_instance_valid(_world) and Time.get_ticks_msec() < deadline:
		if bool(_world.call("shell_build_complete")):
			return true
		await process_frame
	return false


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _failures.is_empty():
		print("STORMWOOD SETTLEMENT TRAVERSAL OK: %d/%d approaches, openings, rooms and walls" % [
			_traversed, _expected])
		quit(0)
		return
	for failure: String in _failures:
		push_error("STORMWOOD SETTLEMENT TRAVERSAL: %s" % failure)
	quit(1)

extends RefCounted

## Read-only scene observation plus bounded physical controller callbacks.
## step(kind, target) advances exactly ONE physics frame (walk uses the existing
## StickNavigator.step; face uses the mapped right stick; settle uses no input).
## press() is exactly one mapped build_place tap: TWO physics + TWO process waits.
## release() zeros both sticks synchronously and resets navigator state.
## read() must use observe() below in production. No callback changes game state
## except through mapped physical inputs. The one TOTAL budget includes tap waits.
const TENT := preload("res://scripts/build/camp_tent.gd")
const REALMS := preload("res://scripts/world/realm_world_records.gd")
const PLACE_AHEAD := 3.0 # build_placer.gd::PLACE_AHEAD
const STANCE_TOLERANCE := 0.18
const YAW_TOLERANCE := 2.0


static func budget(budget_frames: int = 1200) -> Dictionary:
	return {"physics_frames": maxi(0, budget_frames), "process_frames": 2}


## A record alone is not proof a live building exists. The caller also reads
## its real node's metadata/position; ghosts never enter the placed group.
static func canonical(record: Dictionary, id: String, node_realm: String,
		node_position: Vector3, realm: String) -> bool:
	if id not in ["tent", "bedroll"] or str(record.get("id", "")) != id:
		return false
	if node_realm != realm or not REALMS.belongs(record, realm) or bool(record.get("removed", false)):
		return false
	var pos: Array = record.get("position", [])
	return not str(record.get("uid", "")).is_empty() and pos.size() == 3 \
		and node_position.distance_to(Vector3(float(pos[0]), float(pos[1]), float(pos[2]))) < 0.05


static func observe(tree: SceneTree, game: Node, player: Node3D, rig: Node3D) -> Dictionary:
	var out := {"ok": false, "why": "placement scene unavailable"}
	if tree == null or game == null or not is_instance_valid(player) or not is_instance_valid(rig):
		return out
	var realm := REALMS.active(game)
	var records: Array = game.get("placed_buildings")
	var buildings: Array = []
	for node in tree.get_nodes_in_group("placed_building"):
		if not node is Node3D or not node.is_inside_tree() or node.is_queued_for_deletion():
			continue
		var index := int(node.get_meta("placed_index", -1))
		if index < 0 or index >= records.size() or not records[index] is Dictionary:
			continue
		var record: Dictionary = records[index]
		var id := str(node.get_meta("building_id", ""))
		if canonical(record, id, str(node.get_meta("realm", "")), node.global_position, realm):
			buildings.append({"uid": str(record.uid), "id": id, "realm": realm,
				"position": node.global_position, "yaw_deg": rad_to_deg(node.rotation.y)})
	var placer: Node = null
	for candidate in tree.get_nodes_in_group("build_placer"):
		if candidate.get("_player") == player:
			placer = candidate
			break
	if placer == null:
		out.why = "no build placer for this player"
		return out
	var ghost := placer.get("_ghost") as Node3D
	return {"ok": true, "realm": realm, "buildings": buildings,
		"player_position": player.global_position, "camera_yaw_deg": rad_to_deg(float(rig.get("yaw"))),
		"pending_build": str(game.get("pending_build")),
		"ghost_id": str(placer.get("_ghost_id")),
		"ghost_position": ghost.global_position if is_instance_valid(ghost) else Vector3.INF,
		"ghost_ok": is_instance_valid(ghost) and bool(placer.get("_ghost_ok")),
		"ghost_reason": str(placer.get("_ghost_reason"))}


static func _building(state: Dictionary, uid: String) -> Dictionary:
	for building: Dictionary in state.get("buildings", []):
		if str(building.uid) == uid and str(building.realm) == str(state.get("realm", "")):
			return building
	return {}


static func _flat_gap(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func execute(read: Callable, step: Callable, press: Callable, release: Callable,
		budget_frames: int = 1200, interrupted: Callable = Callable()) -> Dictionary:
	var result := await _execute(read, step, press, release, maxi(0, budget_frames), interrupted)
	release.call() # Also releases controls on failure/refusal/readback timeout.
	return result


static func _execute(read: Callable, step: Callable, press: Callable, release: Callable,
		limit: int, interrupted: Callable) -> Dictionary:
	var result := {"ok": false, "why": "bedroll placement budget exhausted", "stances": 0,
		"physics_frames": 0, "process_frames": 0, "placement_presses": 0,
		"tent_uid": "", "bedroll_uid": ""}
	var first: Dictionary = read.call()
	if not bool(first.get("ok", false)):
		result.why = str(first.get("why", "cannot observe placement"))
		return result
	var tent: Dictionary = {}
	var nearest := INF
	var old_beds: Array[String] = []
	for building: Dictionary in first.get("buildings", []):
		if str(building.realm) != str(first.realm):
			continue
		if str(building.id) == "bedroll":
			old_beds.append(str(building.uid))
		if str(building.id) == "tent":
			var distance := _flat_gap(first.player_position, building.position)
			if distance < nearest:
				tent = building
				nearest = distance
	if tent.is_empty():
		result.why = "no canonical placed tent in the current realm"
		return result
	result.tent_uid = str(tent.uid)
	var center: Vector3 = tent.position
	var approaches := [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]
	approaches.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return _flat_gap(first.player_position, center - a * PLACE_AHEAD) < _flat_gap(first.player_position, center - b * PLACE_AHEAD))
	# Reserve a quarter of the same total for committed placement readback,
	# and two physics frames for the single tap. Attempts share the remainder.
	var readback_budget := mini(120, maxi(1, limit / 4))
	var approach_budget := maxi(0, limit - readback_budget - 2)
	for attempt in 4:
		release.call()
		result.stances = attempt + 1
		var allowance := approach_budget / (4 - attempt)
		var used := 0
		var stance: Vector3 = center - (approaches[attempt] as Vector3) * PLACE_AHEAD
		var settled := false
		while used < allowance:
			if interrupted.is_valid() and bool(interrupted.call()):
				result.why = "bedroll placement interrupted by cost gate"
				return result
			var state: Dictionary = read.call()
			var live_tent := _building(state, str(tent.uid))
			if not bool(state.get("ok", false)) or live_tent.is_empty() \
					or (live_tent.position as Vector3).distance_to(center) > 0.05:
				result.why = "the canonical tent disappeared or moved"
				return result
			if str(state.get("pending_build", "")) != "bedroll":
				result.why = "the production catalogue has not armed bedroll"
				return result
			var kind := "walk"
			var target := stance
			if _flat_gap(state.player_position, stance) <= STANCE_TOLERANCE:
				var toward: Vector3 = center - (state.player_position as Vector3)
				var want_yaw := atan2(-toward.x, -toward.z)
				var yaw_gap := absf(rad_to_deg(angle_difference(deg_to_rad(float(state.camera_yaw_deg)), want_yaw)))
				kind = "face" if yaw_gap > YAW_TOLERANCE else "settle"
				target = center
				if kind == "settle" and settled:
					var inside := TENT.contains_point(live_tent.position, float(live_tent.yaw_deg), state.ghost_position)
					if str(state.get("ghost_id", "")) == "bedroll" and bool(state.get("ghost_ok", false)) and inside:
						return await _place_and_verify(read, step, press, interrupted, result, old_beds, live_tent, readback_budget)
					result.why = "bedroll ghost is not legal inside the tent: %s" % str(state.get("ghost_reason", "outside shelter"))
					break
			var advanced: Dictionary = await step.call(kind, target)
			result.physics_frames += 1
			used += 1
			approach_budget -= 1
			if not bool(advanced.get("ok", false)):
				result.why = str(advanced.get("why", "physical approach refused"))
				break
			settled = kind == "settle"
	return result


static func _place_and_verify(read: Callable, step: Callable, press: Callable,
		interrupted: Callable, result: Dictionary, old_beds: Array[String], tent: Dictionary,
		readback_budget: int) -> Dictionary:
	result.placement_presses = 1
	var sent: Dictionary = await press.call()
	result.physics_frames += 2
	result.process_frames += 2
	if not bool(sent.get("ok", false)):
		result.why = str(sent.get("why", "mapped build_place was refused"))
		return result
	for waited in readback_budget + 1:
		var state: Dictionary = read.call()
		var live_tent := _building(state, str(tent.uid))
		if not bool(state.get("ok", false)) or live_tent.is_empty():
			result.why = "tent disappeared during placement readback"
			return result
		for building: Dictionary in state.get("buildings", []):
			if str(building.id) == "bedroll" and str(building.realm) == str(state.realm) \
					and not old_beds.has(str(building.uid)) \
					and TENT.contains_point(live_tent.position, float(live_tent.yaw_deg), building.position):
				result.ok = true
				result.bedroll_uid = str(building.uid)
				result.why = "new canonical bedroll verified inside the live tent"
				return result
		if waited == readback_budget or (interrupted.is_valid() and bool(interrupted.call())):
			break
		var advanced: Dictionary = await step.call("settle", live_tent.position)
		result.physics_frames += 1
		if not bool(advanced.get("ok", false)):
			result.why = str(advanced.get("why", "placement readback interrupted"))
			return result
	result.why = "build_place was sent but no new bedroll was committed inside the tent"
	return result

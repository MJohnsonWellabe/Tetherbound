extends SceneTree

## HANDOFF WIP: parser-clean, but both recorded runs fail admission because the
## original site can enter sticky _site_failures before candidate installation.
## Next session must await population_ready and install candidates before Brine
## approach. Do not clear production failure flags or cite this as a passing smoke.
## See ralph/reports/FOUR-BIOME-BUILD/BRINE-ORDINARY-FOOTING.md.
##
## Fixture-disclosed production-world validation for replacement XZ positions
## at the two rejected Brine Steps ordinary wild sites. This does not edit the
## tracked encounter JSON or claim route continuity. It searches near each live
## grounded site for one exact coordinate which supports every legal table
## species at the production footprint margin, stays clear of the exploration
## spine even after Riptusk's roam, then uses ordinary player input to walk the
## affected spine segment past a real-size inert blocker. Finally, an in-memory
## duplicate of each site exercises the unchanged production admission loop.
const SAVE := preload("res://scripts/save/save_game.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const ENCOUNTER_BASE := preload("res://scripts/combat/cloudreach_encounter_director.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")

const TARGET_IDS: Array[String] = [
	"water_brine_steps_wild_010",
	"water_brine_steps_wild_011",
]
const SPECIES: Array[String] = ["riptusk", "cragclaw", "mangrove_monitor"]
const SPINE_ID := "brine_steps_exploration_spine"
const SEARCH_RADII: Array[float] = [4.0, 6.0, 8.0, 10.0, 12.0, 16.0, 20.0]
const SEARCH_BEARINGS := 32
const PLAYER_RADIUS := 0.4
const RIPTUSK_RADIUS := 1.4875
const SITE_ROAM_RADIUS := 2.5
const ROUTE_SAFETY_MARGIN := 0.6
const MIN_ROUTE_CLEARANCE := PLAYER_RADIUS + RIPTUSK_RADIUS + SITE_ROAM_RADIUS \
	+ ROUTE_SAFETY_MARGIN
const WATCHDOG_MSEC := 6 * 60 * 1000

var _failures: Array[String] = []
var _finished := false
var _world: Node3D
var _director: Node
var _player: CharacterBody3D
var _camera: Node3D
var _spine: Array[Vector3] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_watchdog.call_deferred()
	await process_frame
	var game := root.get_node("Game")
	game.save_system = SAVE.new("user://water_brine_candidate_footing_%d/" % Time.get_ticks_usec())
	game.reset_for_new_game()
	game.current_realm = "water"
	_world = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + 90000
	while not _world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not _world.shell_build_complete():
		_fail("production Water world did not build within 90 seconds")
		_finish()
		return
	_director = _world.get_node("EncounterDirector")
	_player = _world.local_rig()
	_camera = _world.get_node("CameraRig")
	# The inherited director defers its initial admission pass by one physics
	# frame. Let that pass complete while the player remains at First Shore;
	# otherwise the first diagnostic walk can expose an original rejected site
	# and poison its fail-closed ID before the candidate is installed in memory.
	await physics_frame
	await process_frame
	_director.set_process(false)
	for id: String in TARGET_IDS:
		if (_director.get("_site_spawned") as Dictionary).has(id) \
				or (_director.get("_site_failures") as Dictionary).has(id):
			_fail("target site was admitted before candidate fixture setup: " + id)
	if not _failures.is_empty():
		_finish()
		return
	_spine = _land_route(SPINE_ID)
	if _spine.size() != 7:
		_fail("Brine exploration spine no longer has seven points")
		_finish()
		return

	var sites := _target_sites()
	var selections: Dictionary = {}
	for id: String in TARGET_IDS:
		if not sites.has(id):
			_fail("production director lacks target site " + id)
			continue
		var result := _find_common_candidate(sites[id])
		if not bool(result.get("ok", false)):
			_fail("no route-clear common all-species candidate within 20m for " + id)
			continue
		selections[id] = result
		print("BRINE_COMMON_CANDIDATE ", JSON.stringify(result))
	if not _failures.is_empty():
		_finish()
		return

	for id: String in TARGET_IDS:
		if not await _walk_spine_past_blocker(id, selections[id]):
			_finish()
			return
	if not _exercise_in_memory_admission(sites, selections):
		_finish()
		return
	_finish()


func _find_common_candidate(site: Dictionary) -> Dictionary:
	var source := _vector3(site.position)
	for distance: float in SEARCH_RADII:
		for index in SEARCH_BEARINGS:
			var angle := TAU * float(index) / float(SEARCH_BEARINGS)
			var xz := Vector2(source.x, source.z) + Vector2(cos(angle), sin(angle)) * distance
			var clearance := _distance_to_spine(xz)
			if clearance < MIN_ROUTE_CLEARANCE:
				continue
			var ground := float(_world.ground_height_at(xz.x, xz.y))
			if not is_finite(ground) or ground <= float(_world.field.water_level()) + 0.2:
				continue
			var candidate := Vector3(xz.x, ground, xz.y)
			var species_rows: Array[Dictionary] = []
			var all_supported := true
			for species: String in SPECIES:
				var row := _support_at(species, candidate)
				species_rows.append(row)
				if not bool(row.get("direct", false)) or not bool(row.get("spawn", false)):
					all_supported = false
			if all_supported:
				return {
					"ok": true,
					"site": str(site.id),
					"source": str(source),
					"candidate": str(candidate),
					"move_m": distance,
					"bearing_index": index,
					"route_clearance_m": clearance,
					"species": species_rows,
				}
	return {"ok": false, "site": str(site.id)}


func _support_at(species: String, candidate: Vector3) -> Dictionary:
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(WILD)
	_world.add_child(body)
	body.call("populate", species, _player)
	body.global_position = candidate
	body.set_process(false)
	body.set_physics_process(false)
	var radius := float(body.call("body_radius")) + ENCOUNTER_BASE.WILD_FOOT_MARGIN
	var direct: Vector3 = _director._wild_support(candidate, radius, body)
	# `_find_wild_spawn` performs a much wider fallback search. Only call it
	# after this exact XZ has passed the stricter direct-footprint requirement.
	var spawned: Vector3 = _director._find_wild_spawn(body, candidate, candidate) \
		if direct.is_finite() else Vector3.INF
	var row := {"species": species, "radius": radius,
		"direct": direct.is_finite(), "direct_seat": str(direct),
		"spawn": spawned.is_finite(), "spawn_seat": str(spawned)}
	body.free()
	return row


func _walk_spine_past_blocker(id: String, selection: Dictionary) -> bool:
	var candidate := _parse_vector3(str(selection.get("candidate", "")))
	var segment := _nearest_spine_segment(Vector2(candidate.x, candidate.z))
	if segment < 0 or segment + 1 >= _spine.size():
		return _fail("no affected spine segment resolved for " + id)
	var blocker: Node3D = CREATURE_SCENE.instantiate()
	blocker.set_script(WILD)
	_world.add_child(blocker)
	blocker.call("populate", "riptusk", _player)
	blocker.global_position = candidate
	blocker.set_process(false)
	blocker.set_physics_process(false)
	var blocker_seat: Vector3 = _director._wild_support(candidate,
		float(blocker.call("body_radius")) + ENCOUNTER_BASE.WILD_FOOT_MARGIN, blocker)
	if not blocker_seat.is_finite():
		blocker.free()
		return _fail("selected candidate lost Riptusk support before route walk: " + id)
	blocker.global_position = blocker_seat

	var start := _spine[segment]
	var target := _spine[segment + 1]
	start.y = _world.ground_height_at(start.x, start.z) + 0.15
	target.y = _world.ground_height_at(target.x, target.z) + 0.15
	_player.global_position = start
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	for _frame in 30:
		await physics_frame
	var navigator := NAV.new(self, _player, _camera, _stick)
	var budget := maxi(2400, int(Vector2(start.x, start.z).distance_to(
		Vector2(target.x, target.z)) * 80.0))
	var arrived: bool = await navigator.walk_to(target, budget, 1.3)
	_stick(0.0, 0.0)
	var final_gap := Vector2(_player.global_position.x, _player.global_position.z).distance_to(
		Vector2(target.x, target.z))
	print("BRINE_COMMON_WALK ", JSON.stringify({"site": id, "segment": segment,
		"arrived": arrived, "final_gap_m": final_gap,
		"confined_resets": navigator.confined_resets(),
		"player": str(_player.global_position), "blocker": str(blocker_seat),
		"route_clearance_m": float(selection.get("route_clearance_m", -1.0))}))
	blocker.free()
	if not arrived:
		return _fail("ordinary spine walk was obstructed by %s candidate; gap=%.2f resets=%d" % [
			id, final_gap, navigator.confined_resets()])
	return true


func _exercise_in_memory_admission(sites: Dictionary, selections: Dictionary) -> bool:
	# Fixture only: mutate the director's duplicated runtime config, never the
	# tracked JSON or Game progression, then invoke the unchanged admission loop.
	for raw_site: Dictionary in _director.encounter_config.wild_sites:
		var id := str(raw_site.id)
		if not selections.has(id):
			continue
		var selected: Dictionary = selections[id]
		var candidate := _parse_vector3(str(selected.get("candidate", "")))
		raw_site["position"] = [candidate.x, candidate.y, candidate.z]
	for id: String in TARGET_IDS:
		var selected: Dictionary = selections[id]
		var candidate := _parse_vector3(str(selected.get("candidate", "")))
		_player.global_position = candidate + Vector3.UP * 2.0
		_director._spawn_available_sites()
		var members: Array = _director.get("_site_members").get(id, [])
		var spawned: Dictionary = _director.get("_site_spawned")
		var failures: Dictionary = _director.get("_site_failures")
		var ok := spawned.has(id) and not failures.has(id) and members.size() == 1
		print("BRINE_COMMON_ADMISSION ", JSON.stringify({"site": id, "ok": ok,
			"members": members.size(), "spawned": spawned.has(id),
			"failed": failures.has(id)}))
		if not ok:
			return _fail("in-memory production admission rejected candidate for " + id)
	return true


func _target_sites() -> Dictionary:
	var result: Dictionary = {}
	for site: Dictionary in _director.encounter_config.wild_sites:
		if str(site.id) in TARGET_IDS:
			result[str(site.id)] = site
	return result


func _land_route(id: String) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for route: Dictionary in _world.config.land_routes:
		if str(route.id) != id:
			continue
		for raw: Array in route.polyline:
			result.append(_vector3(raw))
	return result


func _distance_to_spine(point: Vector2) -> float:
	var best := INF
	for index in _spine.size() - 1:
		best = minf(best, _distance_to_segment(point,
			Vector2(_spine[index].x, _spine[index].z),
			Vector2(_spine[index + 1].x, _spine[index + 1].z)))
	return best


func _nearest_spine_segment(point: Vector2) -> int:
	var best := INF
	var chosen := -1
	for index in _spine.size() - 1:
		var distance := _distance_to_segment(point,
			Vector2(_spine[index].x, _spine[index].z),
			Vector2(_spine[index + 1].x, _spine[index + 1].z))
		if distance < best:
			best = distance
			chosen = index
	return chosen


static func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var delta := b - a
	if delta.length_squared() < 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
	return point.distance_to(a + delta * t)


static func _vector3(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


static func _parse_vector3(text: String) -> Vector3:
	var pieces := text.trim_prefix("(").trim_suffix(")").split(",")
	return Vector3(float(pieces[0]), float(pieces[1]), float(pieces[2]))


func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)


func _watchdog() -> void:
	var began := Time.get_ticks_msec()
	while not _finished and Time.get_ticks_msec() - began < WATCHDOG_MSEC:
		await process_frame
	if not _finished:
		_fail("Brine common-candidate smoke exceeded six minutes")
		_finish()


func _fail(message: String) -> bool:
	_failures.append(message)
	push_error("BRINE COMMON FOOTING: " + message)
	return false


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_stick(0.0, 0.0)
	if _failures.is_empty():
		print("BRINE COMMON FOOTING OK: all species, spine clearance/walks and production admission")
		quit(0)
	else:
		print("BRINE COMMON FOOTING FAILURES: ", _failures)
		quit(1)

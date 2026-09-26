extends "res://tests/smoke_cloudreach_continuous.gd"

## F07#2 walk witness for the Windscar floor loop and its return to the
## counterweight stair, on the production scene with the real controller.
##
## Fixture (declared): post-shrine flags are set before the scene is built and
## the player is placed once at the Windscar junction. Everything after that
## is stick input over collision, reusing the continuous harness's `_walk` /
## `_navigate` (stall = no 0.4 m progress in 3 x 120 frames; a fall 20 m below
## the authored segment also fails).
##
##   1. Outbound floor loop, as the Maela approach walks it: junction ->
##      chain bridge -> far side -> aerie. The recorded stall sat on this
##      bridge at (-397.5, 446.9, 2931.5) against the counterweight pass's
##      shoulder (`WindscarCounterweightPassCliffShoulders/Ridge001`).
##   2. The required return from the aerie dais to `counterweight_entered`,
##      shortest authored ground path as the continuous harness navigates it
##      (F07#2 cadence: via `windscar_counterweight_return`, no bridge
##      re-crossing). The walked vertices and metres are printed so the
##      before/after route shape is evidence, not an assumption.
##   3. Back down from `counterweight_entered` over the stair's second landing
##      and the return leg to the bridge's far landing, then across the
##      chain-bridge deck to the junction: the old stall point re-crossed in
##      the other direction.

const JUNCTION := Vector3(-100, 470, 2440)
const AERIE := Vector3(400, 610, 3250)
const COUNTERWEIGHT_ENTERED := Vector3(-720, 700, 3680)
const POST_SHRINE_FLAGS: Array[String] = ["warden_defeated", "realm_key_cloudreach",
	"realm_heart_meadows_earned", "realm_heart_meadows_placed", "realm_gate_cloudreach_unlocked",
	"fly_traversal_unlocked", "windscar_aerie_prepared", "sky_shrine_reached",
	"cloudreach_upper_route_unlocked"]

var _wild_prefixes: Array[String] = []


func _run() -> void:
	start_usec = Time.get_ticks_usec()
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	accelerated = true
	output_dir = "user://cloudreach_floor_loop_return"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = root.get_node("Game")
	game.reset_for_new_game()
	for flag: String in POST_SHRINE_FLAGS:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(25, PROGRESSION.config())
		game.party.add(member)
	game.current_realm = "cloudreach"
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	director = runtime.director
	manager = runtime.manager
	fly = player.fly_controller
	physics_frame.connect(_record_frame)
	await _frames(20)
	_remove_wild_bodies("boot")
	# Wild sites also spawn by proximity DURING the walk (the aerie roost, the
	# ravine sites beside the bridge); park each as it enters the tree, after
	# its own `_ready` has set its collision layers, so none can stand on the
	# road between the sweeps above and below.
	world.child_entered_tree.connect(func(child: Node) -> void:
		_park_if_wild.call_deferred(child, "spawned_mid_walk"))
	await _frames(2)
	player.global_position = JUNCTION + Vector3.UP * 1.2
	player.velocity = Vector3.ZERO
	await _frames(30)
	distance_m = 0.0
	var floor_loop := _route("windscar_floor_loop")
	stage = "outbound_floor_loop"
	var outbound_ok := true
	for raw: Array in (floor_loop.polyline as Array).slice(1):
		if not await _walk(_vec(raw)):
			outbound_ok = false
			break
	var outbound_m := distance_m
	var return_ok := false
	var return_m := 0.0
	var walked: Array[String] = []
	var bridge_ok := false
	var bridge_m := 0.0
	if outbound_ok:
		stage = "return_to_counterweight"
		# Wild sites near the aerie spawn on proximity during the outbound
		# walk (`ravine_wind_1` roosts on the aerie approach), so clear again.
		_remove_wild_bodies(stage)
		await _frames(2)
		var before := distance_m
		walked = _return_path_labels()
		return_ok = await _navigate(COUNTERWEIGHT_ENTERED)
		return_m = distance_m - before
	if return_ok:
		stage = "bridge_reverse_to_junction"
		_remove_wild_bodies(stage)
		await _frames(2)
		var before := distance_m
		bridge_ok = true
		var pass_line: Array = _route("windscar_counterweight_pass").polyline
		var return_leg: Array = _route("windscar_counterweight_return").polyline
		var loop_line: Array = _route("windscar_floor_loop").polyline
		# counterweight_entered (pass v4) -> v3 -> second landing (pass v2) ->
		# far landing (return leg v0 = floor-loop v2) -> bridge -> v1 -> junction.
		var legs: Array = [pass_line[3], pass_line[2], return_leg[0], loop_line[1], loop_line[0]]
		for raw: Array in legs:
			if not await _walk(_vec(raw)):
				bridge_ok = false
				break
		bridge_m = distance_m - before
	_release()
	var verdict := "PASS" if outbound_ok and return_ok and bridge_ok and not failed else "FAIL"
	print("CLOUDREACH FLOOR LOOP RETURN " + JSON.stringify({"verdict": verdict,
		"outbound_ok": outbound_ok, "outbound_walked_m": snappedf(outbound_m, 0.1),
		"return_ok": return_ok, "return_walked_m": snappedf(return_m, 0.1),
		"return_vertices": walked, "bridge_reverse_ok": bridge_ok,
		"bridge_reverse_walked_m": snappedf(bridge_m, 0.1),
		"player": str(player.global_position)}))
	quit(0 if verdict == "PASS" else 1)


## This witness is about static route geometry. Wild bodies roam onto the
## road (a `ravine_wind` flyer stands on the aerie approach) and the harness's
## mobile-blocker detour cannot always pass them on the narrow ledge; park
## them rather than read a creature as a collision defect. Parked, not freed:
## the encounter director keeps typed references to its wilds (freeing a
## gated one raises "previously freed instance" in `_sync_spawn_gates`).
func _remove_wild_bodies(when: String) -> void:
	var parked := 0
	for child: Node in world.get_children():
		if _park(child):
			parked += 1
	_log("fixture_wild_bodies_parked", {"count": parked, "when": when})


func _park_if_wild(child: Node, when: String) -> void:
	if is_instance_valid(child) and _park(child):
		_log("fixture_wild_body_parked", {"name": str(child.name), "when": when})


func _park(child: Node) -> bool:
	if _wild_prefixes.is_empty():
		for site: Dictionary in _json_dict("res://data/config/cloudreach_encounters.json").get("wild_sites", []):
			_wild_prefixes.append(str(site.id) + "_")
	for prefix: String in _wild_prefixes:
		if str(child.name).begins_with(prefix):
			child.process_mode = Node.PROCESS_MODE_DISABLED
			if child is CollisionObject3D:
				(child as CollisionObject3D).collision_layer = 0
				(child as CollisionObject3D).collision_mask = 0
			if child is Node3D:
				(child as Node3D).visible = false
			return true
	return false


## The authored vertices `_navigate` will take from the aerie end, read off the
## same graph (for the evidence line only; the walk itself is `_navigate`).
func _return_path_labels() -> Array[String]:
	var out: Array[String] = []
	for route: Dictionary in world.config_data().routes:
		if route.traversal_mode != "ground":
			continue
		var gate := str(route.get("requires_unlock", ""))
		if not gate.is_empty() and not _has(gate):
			continue
		if str(route.id) in ["windscar_floor_loop", "windscar_counterweight_pass", "windscar_counterweight_return"]:
			out.append("%s:%d" % [route.id, (route.polyline as Array).size()])
	return out


func _json_dict(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _finish() -> void:
	pass

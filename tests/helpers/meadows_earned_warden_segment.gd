extends "res://tests/helpers/meadows_earned_hall_segment.gd"

## Existing-world finale plus a separately callable ordinary aftermath tail.
## The chosen ending releases the pending legendary and keeps the earned five.
const CLIMAX_CONFIG := "res://data/config/stronghold_climax.json"
const NPC_CONFIG := "res://data/config/village_npcs.json"
const FREED_DIALOGUE := "res://data/dialogue/meadows_freed.json"
const CEREMONY := preload("res://tests/helpers/earned_roster_replacement_segment.gd")
const NPCS := preload("res://scripts/world/village_npcs.gd")
const SEQUENCE_FRAMES := 900  # Existing smoke_gate_e_finale story-stage bound.
const ARRIVAL_MSEC := 120000  # Production Game realm-scene readiness timeout.
var _climax: Node3D
var _rift: Node3D
var _ending_config: Dictionary
var _gui: RefCounted
var _finished_dialogues: Array[String] = []
var _connections: Array[Array] = []
var _rift_crossings := 0
var _rift_expected := false
var _released_id := 0
var _crossing_player_id := 0
var _source_world_id := 0


func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	return await _run_mode(tree, world, game, "all")


func run_finale(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	return await _run_mode(tree, world, game, "finale")


func run_after_finale(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	return await _run_mode(tree, world, game, "aftermath")


func _run_mode(tree: SceneTree, world: Node3D, game: Node, mode: String) -> Dictionary:
	if not _bind_ending(tree, world, game, mode == "aftermath"):
		return result()
	if mode == "aftermath":
		_completed = await _acknowledge_and_cross()
	else:
		_completed = await _finish_ending()
		if _completed and mode == "all":
			_completed = await _acknowledge_and_cross()
	_stick(0.0, 0.0)
	_disconnect_watches()
	return result()


func _disconnect_watches() -> void:
	for connection: Array in _connections:
		# Realm travel destroys the outgoing scene and its signal owners.
		if is_instance_valid(connection[0]):
			var source: Object = connection[0]
			if source.is_connected(connection[1], connection[2]):
				source.disconnect(connection[1], connection[2])
	_connections.clear()


func _bind_ending(tree: SceneTree, world: Node3D, game: Node, after: bool) -> bool:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		return _fail("Earned Warden needs the retained tree, world and Game")
	if tree.current_scene != world or str(game.get("current_realm")) != "meadows" or INPUT_OWNER.current(tree) != null:
		return _fail("The ending needs ordinary input in the retained Meadows")
	_source_world_id = world.get_instance_id()
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_hold = world.get_node_or_null("Stronghold") as Node3D
	_climax = world.get_node_or_null("StrongholdClimax") as Node3D
	_rift = world.get_node_or_null("RiftCrossing") as Node3D
	_panel = world.get_node_or_null("DialoguePanel")
	_director = world.get_node_or_null("EncounterDirector")
	_combat = world.get_node_or_null("CombatManager")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	if _player == null or _rig == null or _hold == null or _climax == null or _rift == null \
			or _panel == null or _director == null or _combat == null or _arbiter == null:
		return _fail("The live Hall, climax, Rift or input dependencies are missing")
	_initial_ids = _party_ids()
	if not retained_five(_initial_ids, _initial_ids) or _fighting() or game.get("pending_catch") != null \
			or not _has("hall_approach_open") or not _has("defeated_stronghold_elite") or _has("meadows_acknowledged"):
		return _fail("The ending must retain the earned five after Hall, before acknowledgement")
	_hall_config = _read(HALL_CONFIG)
	_ending_config = _read(CLIMAX_CONFIG)
	if after:
		if not _ending_ready() or str(_climax.get("_stage")) != "done":
			return _fail("The acknowledgement tail needs the actually settled completed machine sequence")
	else:
		for flag: String in ["defeated_warden", "legendary_freed", "legendary_settled", "legendary_joined", "learned_legendary_is_the_source", "realm_key_cloudreach", "realm_heart_meadows_earned"]:
			if _has(flag):
				return _fail("A next Warden reward or ending beat was already present: " + flag)
		if not bool(_hold.call("has_marker", "warden_arena")) \
				or _player.global_position.distance_to(_hold.call("marker", "warden_arena")) > 0.6 \
				or not shutter_receipt(_hold, "defeated_warden", false):
			return _fail("The actual player has not reached the preceding earned Hall arena boundary")
	_supported_y = (_hold.call("marker", "warden_arena") as Vector3).y
	_input = INPUTS.new()
	_input._tree = tree
	_gui = CEREMONY.new()
	_gui._tree = tree
	_nav = NAV.new(tree, _player, _rig, _stick)
	_watch(_combat, "entered", _on_entered)
	_watch(_combat, "hit_landed", _on_hit)
	_watch(_combat, "exited", _on_exit)
	_watch(_panel, "finished", _on_dialogue_finished)
	_watch(_arbiter, "activated", _on_activated)
	_watch(tree, "process_frame", _observe_retained_party)
	return true


func _finish_ending() -> bool:
	var reveal: Dictionary = _ending_config.get("reveal", {})
	if not await _talk(_climax.get_node_or_null("TetherReadout/ReadoutPrompt") as Node3D, str(reveal.get("conversation", ""))) \
			or not _has(str(reveal.get("flag", ""))):
		return _fail("The actual environmental readout did not deliver the reveal before the Warden")
	var id := str((_ending_config.get("warden", {}) as Dictionary).get("trainer", ""))
	var warden := _climax.call("warden_body") as Node3D
	if not is_instance_valid(warden) or not await _fight_named(warden, id):
		return false
	for flag: String in TRAINERS.reward_flags(TRAINERS.trainer(id)):
		if not _has(flag):
			return _fail("The real Warden victory omitted its configured reward flag: " + flag)
	for _frame in 120:
		if shutter_receipt(_hold, "defeated_warden", true):
			break
		await _tree.physics_frame
	if not shutter_receipt(_hold, "defeated_warden", true):
		return _fail("The actual Warden shutter did not open after victory")
	var crossing_start := Engine.get_physics_frames()
	if not await _walk_marker("warden_arena", ROOM_FRAMES) or not await _walk_final_door(crossing_start):
		return false
	var machine := _climax.get_node_or_null("MachineControl/MachinePrompt") as Node3D
	if machine == null or _has("legendary_freed") or _game.get("pending_catch") != null:
		return _fail("The actual machine control or untouched voluntary join seam is unavailable")
	var config: Dictionary = _ending_config.get("machine", {})
	var expected: Array[String] = [str(config.get("chamber_conversation", "")),
		str(config.get("free_conversation", "")), str(config.get("join_conversation", ""))]
	var first := _finished_dialogues.size()
	if not await _press_prompt(machine) or not await _drive_machine_to_ceremony(expected, first):
		return false
	if not await _keep_the_earned_five():
		return false
	first = _finished_dialogues.size()
	if not await _drive_failure(str(config.get("failure_conversation", "")), first):
		return false
	if not _ending_ready() or not retained_five(_initial_ids, _party_ids()):
		return _fail("The actual completed ending did not settle the unchanged earned five")
	var legendary := _climax.call("legendary_body") as Node3D
	if legendary == null or legendary.get_node_or_null("ContainmentVFX") != null \
			or not bool(_climax.call("legendary_is_freed")):
		return _fail("The completed machine sequence left the actual legendary constrained")
	_receipt("meadows_ending_settled", {"choice": "release_pending_legendary_keep_earned_five", "released_pending_id": _released_id,
		"party_ids": _party_ids(), "dialogues": _finished_dialogues.duplicate(), "legendary_joined": _has("legendary_joined")})
	return true


func _walk_final_door(start: int) -> bool:
	var door := _hold.get_node_or_null("BlastShutterBody_defeated_warden") as Node3D
	if door == null or not bool(_hold.call("has_marker", "machine_foot")):
		return _fail("The actual opened final passage or outside-plinth control marker is missing")
	var remaining := room_frames_remaining(Engine.get_physics_frames() - start)
	if remaining <= 0 or not await _walk(Vector3(door.global_position.x, _supported_y, door.global_position.z), 0.6, remaining):
		return _fail("The final passage exhausted its shared room budget before the doorway")
	remaining = room_frames_remaining(Engine.get_physics_frames() - start)
	# The chamber centre is INSIDE the machine plinth. Its actual control mark
	# lies outside that collider, on the doorway side; never walk at the centre.
	return (remaining > 0 and await _walk_marker("machine_foot", remaining) \
		and room_frames_remaining(Engine.get_physics_frames() - start) > 0) \
		or _fail("The ordinary final passage did not reach its outside-plinth control within the room budget")


func _drive_machine_to_ceremony(expected: Array[String], first: int) -> bool:
	var start := Engine.get_physics_frames()
	while Engine.get_physics_frames() - start < SEQUENCE_FRAMES:
		var observed: Array = _finished_dialogues.slice(first)
		if not dialogue_prefix(observed, expected) or not _failures.is_empty():
			return _fail("The machine's real conversations diverged from chamber/free/join order")
		if _game.get("pending_catch") != null:
			return observed == expected and _has("legendary_freed") \
				and str(_climax.get("_stage")) == "ceremony" \
				or _fail("The voluntary pending creature arrived before the complete authored join sequence")
		if bool(_panel.call("is_open")):
			if observed.size() >= expected.size() or _current_conversation() != expected[observed.size()]:
				return _fail("An unexpected live dialogue interrupted the machine sequence")
			await _input._tap("interact")
		else:
			await _tree.physics_frame
	return _fail("The machine never reached its real five-slot ceremony within the existing story budget")


func _keep_the_earned_five() -> bool:
	var pending: RefCounted = _game.get("pending_catch")
	var spec: Dictionary = _ending_config.get("legendary", {})
	if not opponent_matches(pending, spec) or _initial_ids.has(pending.get_instance_id()):
		return _fail("The voluntary pending creature does not match the actual authored legendary")
	_released_id = pending.get_instance_id()
	var menu: Node = _game.call("menu")
	if menu == null:
		return _fail("The voluntary pending legendary has no actual game menu")
	var tab: Node = null
	for index in (menu.get("_tabs") as Array).size():
		if str(menu.get("_tabs")[index].get("id", "")) == "creatures":
			tab = menu.get("_bodies")[index]
	if tab == null:
		return _fail("The real pending legendary has no production creatures tab")
	for _frame in CEREMONY.CEREMONY_FRAMES:
		if bool(menu.call("is_open")) and str(tab.get("_release_stage")) == "choose":
			break
		await _tree.process_frame
	if not bool(menu.call("is_open")) or str(tab.get("_release_stage")) != "choose" \
			or _tree.root.gui_get_focus_owner() != tab.get("_pending_button") \
			or not retained_five(_initial_ids, _party_ids()):
		return _fail("The real ceremony did not present the pending legendary beside the unchanged earned five")
	await _gui._ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "confirm" or int(tab.get("_release_target")) != 5 \
			or _tree.root.gui_get_focus_owner() != tab.get("_farewell_keep") \
			or _game.get("pending_catch") != pending or not retained_five(_initial_ids, _party_ids()):
		return _fail("The farewell question did not select only the pending legendary with Keep as default")
	await _gui._ceremony_tap("ui_down")
	if _tree.root.gui_get_focus_owner() != tab.get("_farewell_release"):
		return _fail("Ordinary Down did not reach the actual release confirmation")
	await _gui._ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "done" \
			or not declined_pending_receipt(_initial_ids, _party_ids(), _released_id, _game.get("pending_catch")) \
			or _tree.root.gui_get_focus_owner() != tab.get("_farewell_done"):
		return _fail("The confirmed pending release changed the earned five or left the pending seam unresolved")
	await _gui._ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "":
		return _fail("Back to belt did not end the real farewell ceremony")
	await _gui._ceremony_tap("menu_cancel")
	return (not bool(menu.call("is_open")) and not _tree.paused and _tree.current_scene == _world) \
		or _fail("The confirmed unchanged-five ceremony did not return current-world control")


func _drive_failure(expected: String, first: int) -> bool:
	var start := Engine.get_physics_frames()
	while Engine.get_physics_frames() - start < SEQUENCE_FRAMES:
		if not _failures.is_empty():
			return false
		var observed: Array = _finished_dialogues.slice(first)
		if not dialogue_prefix(observed, [expected]):
			return _fail("The post-ceremony machine-failure conversation was replaced or repeated")
		if str(_climax.get("_stage")) == "done":
			return observed == [expected] and _has("legendary_settled") \
				or _fail("The machinery completed without its actual final conversation and settled flag")
		if bool(_panel.call("is_open")):
			if _current_conversation() != expected:
				return _fail("An unexpected dialogue replaced the final machinery response")
			await _input._tap("interact")
		else:
			await _tree.physics_frame
	return _fail("The actual post-ceremony machinery response exceeded its existing story budget")


func _acknowledge_and_cross() -> bool:
	if not _ending_ready() or not await _exit_hall():
		return false
	var terrain := _read(TERRAIN)
	var gates := _open_crossings(terrain)
	var road := aftermath_road(terrain, gates)
	var kell := _world.get_node_or_null("VillageNPCs/Kell") as Node3D
	var kell_spec := acknowledgement_spec(_read(NPC_CONFIG), _read(FREED_DIALOGUE))
	if gates.size() != 3 or road.is_empty() or kell == null or kell_spec.is_empty():
		return _fail("The actual acknowledgement actor or reversible open-road route is unavailable")
	if NPCS.greeting_for(kell_spec, _game.get("progression")) != "spoke_traveller_storm_road":
		return _fail("The real acknowledgement actor is not offering its authored post-win branch")
	var points := road_points(road)
	var join := nearest_index(points, Vector2(_player.global_position.x, _player.global_position.z))
	_receipt("acknowledgement_backtrack_started", {"road_metres_one_way": road_length(points), "target": kell.global_position,
		"reason": "actual acknowledgement remains at the village; no earned fast travel exists"})
	for index in range(join, -1, -1):
		if not await _walk_road_entry(road[index]):
			return false
	if not await _talk(kell.get_node_or_null("Interactable") as Node3D, str(kell_spec.greeting)) \
			or not _has("meadows_acknowledged") or not retained_five(_initial_ids, _party_ids()):
		return _fail("The actual return greeting did not earn Meadows acknowledgement with the retained five")
	_receipt("meadows_acknowledged", {"actor": kell.name, "conversation": _dialogue_finished, "player": _player.global_position})
	var storm := storm_road(terrain)
	if storm.is_empty():
		return _fail("The actual rebuilt storm-road approach is missing")
	var storm_join := nearest_index(points, storm[0])
	for index in range(storm_join + 1):
		if not await _walk_road_entry(road[index]):
			return false
	for point: Vector2 in storm.slice(1):
		if not await _walk_ground(point):
			return false
	return await _cross_the_live_rift()


func _exit_hall() -> bool:
	var final_door := _hold.get_node_or_null("BlastShutterBody_defeated_warden") as Node3D
	if final_door == null or not shutter_receipt(_hold, "defeated_warden", true):
		return _fail("The actual final passage no longer supports the walk out")
	var final_start := Engine.get_physics_frames()
	if not await _walk(Vector3(final_door.global_position.x, _supported_y, final_door.global_position.z), 0.6, ROOM_FRAMES):
		return false
	var final_remaining := room_frames_remaining(Engine.get_physics_frames() - final_start)
	if final_remaining <= 0 or not await _walk_marker("warden_arena", final_remaining) \
			or room_frames_remaining(Engine.get_physics_frames() - final_start) <= 0:
		return _fail("The real final-room return crossing exceeded its shared room budget")
	var stages := gauntlet_path(_hall_config)
	for index in range(stages.size() - 1, -1, -1):
		var stage := stages[index]
		var door := _hold.get_node_or_null("BlastShutterBody_" + str(stage.flag)) as Node3D
		if door == null or not shutter_receipt(_hold, str(stage.flag), true):
			return _fail("The actual earned Hall return passage is closed")
		var start := Engine.get_physics_frames()
		if not await _walk(Vector3(door.global_position.x, _supported_y, door.global_position.z), 0.6, ROOM_FRAMES):
			return false
		var remaining := room_frames_remaining(Engine.get_physics_frames() - start)
		if remaining <= 0 or not await _walk_marker(str(stage.from), remaining) \
				or room_frames_remaining(Engine.get_physics_frames() - start) <= 0:
			return _fail("The real return passage exceeded its unchanged room budget")
	_supported_y = NAN  # The next legitimate surface descends the actual ramp.
	return await _walk_marker("entrance", ENTRANCE_FRAMES)


func _open_crossings(terrain: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for name: String in ["SouthBridge", "MillCrossing"]:
		var body := _world.get_node_or_null(name) as Node3D
		if not _gate_open(body):
			return []
		var config := INPUTS.crossing_config(terrain) if name == "SouthBridge" else mill_config(terrain)
		var carve: Dictionary = config.get("carve", config.get("channel", {}))
		var bank := float(carve.get("half_width", 0)) + float(carve.get("rim", 0)) + 3.0
		if carve.is_empty():
			return []
		rows.append({"gate": name, "near": body.call("near_point", bank), "far": body.call("far_point", bank)})
	var sigil := _world.get_node_or_null("SigilGate") as Node3D
	if not _gate_open(sigil):
		return []
	var band := trail_points(terrain, "bands", "band5_stronghold_approach")
	var at := nearest_index(band, Vector2(sigil.global_position.x, sigil.global_position.z))
	if at < 0 or at + 1 >= band.size():
		return []
	var crossing := gate_crossing_points(sigil.global_transform, band[at], band[at + 1])
	if crossing.size() != 2:
		return []
	rows.append({"gate": "SigilGate", "near": crossing[0], "far": crossing[1]})
	return rows


func _gate_open(body: Node3D) -> bool:
	if not is_instance_valid(body) or not bool(body.call("is_open")) or not _has(str(body.get("flag_id"))):
		return false
	var shape := body.get("_shape") as CollisionShape3D
	return shape != null and shape.disabled


func _walk_road_entry(entry: Dictionary) -> bool:
	var id := str(entry.get("gate", ""))
	if id != "" and not _gate_open(_world.get_node_or_null(id) as Node3D):
		return _fail("The actual earned bridge/gate is no longer open on the acknowledgement road: " + id)
	if not await _walk_ground(entry.at, 0.6 if id != "" else 1.5):
		return false
	return id == "" or _gate_open(_world.get_node_or_null(id) as Node3D) \
		or _fail("An actual crossing closed during the ordinary return walk")


func _cross_the_live_rift() -> bool:
	if not bool(_rift.call("span_ready")) or not _ending_ready() or not _has("meadows_acknowledged") \
			or not bool(_game.call("can_enter_realm", "cloudreach")):
		return _fail("The real Rift span or earned Cloudreach admission is not ready")
	var trigger := _rift.get_node_or_null("RiftCrossingTrigger") as Area3D
	var deck := _rift.get_node_or_null("DeckAnchor/CrossingDeckBody") as StaticBody3D
	if trigger == null or deck == null or not enabled_collision(deck):
		return _fail("The actual rebuilt Rift lacks its live deck collision or entry trigger")
	var near: Vector3 = _rift.call("near_anchor")
	var far: Vector3 = _rift.call("far_anchor")
	if not await _walk(near, 0.6) or not await _walk(far, 0.6, ROOM_FRAMES):
		return false
	_crossing_player_id = _player.get_instance_id()
	_rift_expected = true
	_watch(trigger, "body_entered", _on_rift_entered)
	var target := trigger.global_position
	target.y = float(_world.call("ground_height_at", target.x, target.z))
	_nav.reset()
	for _frame in ROOM_FRAMES:
		if _rift_crossings == 1:
			break
		if not is_instance_valid(_player) or not _failures.is_empty() or _fighting():
			return _fail("The actual Rift approach was interrupted before physical admission")
		_nav.step(target)
		await _tree.physics_frame
	_stick(0.0, 0.0)
	if _rift_crossings != 1:
		return _fail("The player did not physically enter the actual Rift trigger exactly once")
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < ARRIVAL_MSEC:
		if not _failures.is_empty():
			return false
		var scene := _tree.current_scene
		if str(_game.get("current_realm")) == "cloudreach" and scene != null and scene.get_instance_id() != _source_world_id \
				and str(_game.get("pending_realm_entry")).is_empty() \
				and bool(_game.call("_realm_scene_ready", scene, "cloudreach")) and INPUT_OWNER.current(_tree) == null:
			_world = scene as Node3D
			_player = scene.get_node_or_null("Player") as CharacterBody3D
			_rig = scene.get_node_or_null("CameraRig") as Node3D
			if _player == null or _rig == null or not retained_five(_initial_ids, _party_ids()) \
					or not _has("realm_gate_cloudreach_unlocked") or not _ending_ready():
				return _fail("Production Cloudreach arrival lost an earned identity or handoff fact")
			_receipt("cloudreach_arrived", {"party_ids": _party_ids(), "player": _player.global_position,
				"trigger_entries": _rift_crossings, "travel": "production Rift collision callback"})
			return true
		await _tree.process_frame
	return _fail("The actual Cloudreach scene did not complete production arrival within its existing timeout")


func _ending_ready() -> bool:
	return _has("defeated_warden") and _has("legendary_freed") and _has("legendary_settled") \
		and _has("realm_key_cloudreach") and _has("realm_heart_meadows_earned") and not _has("legendary_joined") \
		and _game.get("pending_catch") == null


func _current_conversation() -> String:
	return str((_panel.get("_runner") as RefCounted).call("conversation_id"))


func _on_dialogue_finished(id: String) -> void:
	super._on_dialogue_finished(id)
	_finished_dialogues.append(id)


func _observe_retained_party() -> void:
	if _failures.is_empty() and not retained_five(_initial_ids, _party_ids()):
		_fail("The observed ending/travel changed the earned five outside its explicitly declined pending offer")
	if _failures.is_empty() and not _rift_expected and _tree.current_scene != _world:
		_fail("The retained world changed before the actual Rift crossing")


func _on_rift_entered(body: Node3D) -> void:
	if is_instance_valid(body) and body.get_instance_id() == _crossing_player_id:
		_rift_crossings += 1


func _watch(source: Object, signal_name: String, callback: Callable) -> void:
	source.connect(signal_name, callback)
	_connections.append([source, signal_name, callback])


static func dialogue_prefix(observed: Array, expected: Array) -> bool:
	if observed.size() > expected.size() or expected.has(""):
		return false
	for index in observed.size():
		if observed[index] != expected[index]:
			return false
	return true


static func declined_pending_receipt(before: Array[int], after: Array[int], newcomer: int, pending: RefCounted) -> bool:
	return retained_five(before, after) and newcomer != 0 and not before.has(newcomer) and pending == null


static func acknowledgement_spec(config: Dictionary, dialogues: Dictionary) -> Dictionary:
	for spec: Dictionary in config.get("villagers", []):
		if str(spec.get("name", "")) != "Kell" or str(spec.get("greeting", "")) != "spoke_traveller_storm_road":
			continue
		var conversation: Dictionary = (dialogues.get("conversations", {}) as Dictionary).get(str(spec.greeting), {})
		for line: Variant in conversation.get("lines", []):
			if line is Dictionary and str(line.get("effect", "")) == "flag:meadows_acknowledged":
				return spec
	return {}


static func aftermath_road(terrain: Dictionary, gates: Array[Dictionary]) -> Array[Dictionary]:
	var spine: Array[Vector2] = []
	for id: String in ["band1_lower_meadows", "band2_stone_and_root", "band3_the_river_lock", "band4_upper_meadows_ironwood", "band5_stronghold_approach"]:
		var band := trail_points(terrain, "bands", id)
		if band.is_empty():
			return []
		if id == "band3_the_river_lock":
			var loop := trail_points(terrain, "loops", "relay_approach_loop")
			if loop.is_empty():
				return []
			var first := nearest_index(band, loop[0])
			var last := nearest_index(band, loop[-1])
			if first >= last:
				return []
			var around: Array[Vector2] = []
			around.append_array(band.slice(0, first))
			around.append_array(loop)
			around.append_array(band.slice(last + 1))
			band = around
		if spine.is_empty():
			# [8,90] is the first authored point outside the village boundary,
			# beside the approach to the actual outside-village witness Kell.
			spine.append_array(band.slice(2))
		else:
			if spine[-1] != band[0]:
				return []
			spine.append_array(band.slice(1))
	if gates.size() != 3:
		return []
	# Replace each gate-plane intersection, including an authored point on the
	# SouthBridge gully floor, with its actual safe near/far bank centreline.
	var output: Array[Dictionary] = []
	for point: Vector2 in spine:
		var inside := false
		for gate: Dictionary in gates:
			var near: Vector2 = gate.near
			var far: Vector2 = gate.far
			var along := (far - near).normalized()
			var depth := (point - near).dot(along)
			if depth > 0 and depth < near.distance_to(far):
				inside = true
		if inside:
			continue
		if not output.is_empty():
			var previous: Vector2 = output[-1].at
			for gate: Dictionary in gates:
				var near: Vector2 = gate.near
				var far: Vector2 = gate.far
				var along := (far - near).normalized()
				if (previous - near).dot(along) <= 0 and (point - far).dot(along) >= 0:
					output.append({"at": near, "gate": str(gate.gate)})
					output.append({"at": far, "gate": str(gate.gate)})
		output.append({"at": point})
	for gate: Dictionary in gates:
		var count := 0
		for entry: Dictionary in output:
			if str(entry.get("gate", "")) == str(gate.gate):
				count += 1
		if count != 2:
			return []
	return output


static func storm_road(terrain: Dictionary) -> Array[Vector2]:
	for spec: Dictionary in (terrain.get("spokes", {}) as Dictionary).get("routes", []):
		if str(spec.get("id", "")) == "storm_road":
			var out: Array[Vector2] = []
			for point: Array in spec.get("road", []):
				out.append(_v2(point))
			return out
	return []


static func road_points(entries: Array[Dictionary]) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for entry: Dictionary in entries:
		points.append(entry.at)
	return points


static func road_length(points: Array[Vector2]) -> float:
	var total := 0.0
	for index in range(1, points.size()):
		total += points[index - 1].distance_to(points[index])
	return total


static func enabled_collision(body: StaticBody3D) -> bool:
	if body == null or body.get_child_count() == 0:
		return false
	for child: Node in body.get_children():
		if child is CollisionShape3D and child.shape != null and not child.disabled:
			return true
	return false


func _receipt(beat: String, detail: Dictionary) -> void:
	detail["beat"] = beat
	_receipts.append(detail)
	print("EARNED WARDEN — ", detail)


func _fail(message: String) -> bool:
	_failures.append(message)
	print("EARNED WARDEN FAIL — ", message)
	return false

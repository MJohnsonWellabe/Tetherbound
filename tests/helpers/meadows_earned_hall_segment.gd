extends "res://tests/helpers/meadows_earned_relay_segment.gd"

## On-foot continuation after the earned Mill crossing. The Relay entrypoint
## is not called: only its physical prompt, care, walking and combat observers
## are reused. Warden combat, riding and the legendary choice are later work.
const HALL_CONFIG := "res://data/config/stronghold.json"
const CAPTAIN_IDS := ["captain_riverwatch", "captain_field", "captain_ridge"]
const SIGILS := ["field_sigil", "ridge_sigil", "river_sigil"]
const HALL_FLAGS := ["defeated_stronghold_patrol", "defeated_stronghold_courtyard", "defeated_stronghold_elite"]
const ROOM_FRAMES := 600  # smoke_stronghold's existing chamber-hop budget.
const ENTRANCE_FRAMES := 950  # Its separate authored 40m ramp budget.
var _hold: Node3D
var _sigil_gate: Node3D
var _hall_config: Dictionary
var _named_trainer := ""
var _observed_trainers: Array[String] = []


func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		_fail("Earned Hall needs the existing tree, world and Game")
		return result()
	if tree.current_scene != world or str(game.get("current_realm")) != "meadows" or INPUT_OWNER.current(tree) != null:
		_fail("Earned Hall requires ordinary world input in the retained Meadows")
		return result()
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_mill = world.get_node_or_null("MillCrossing") as Node3D
	_hold = world.get_node_or_null("Stronghold") as Node3D
	_sigil_gate = world.get_node_or_null("SigilGate") as Node3D
	_trainers = world.get_node_or_null("Trainers") as Node3D
	_panel = world.get_node_or_null("DialoguePanel")
	_director = world.get_node_or_null("EncounterDirector")
	_combat = world.get_node_or_null("CombatManager")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	if _player == null or _rig == null or _mill == null or _hold == null or _sigil_gate == null \
			or _trainers == null or _panel == null or _director == null or _combat == null or _arbiter == null:
		_fail("The actual Mill, Sigil Gate, Hall or input dependencies are missing")
		return result()
	_initial_ids = _party_ids()
	var terrain := _read(TERRAIN)
	var channel: Dictionary = mill_config(terrain).get("channel", {})
	var bank := float(channel.get("half_width", 0.0)) + float(channel.get("rim", 0.0)) + 3.0
	if not retained_five(_initial_ids, _initial_ids) or _fighting() or channel.is_empty() \
			or not _has("relay_disabled") or not _has("captive_rescued") or not _has("mill_crossing_restored") \
			or not bool(_mill.call("is_open")) or _count(GEAR) != 0 \
			or float(_mill.call("depth_past_crossing", Vector2(_player.global_position.x, _player.global_position.z))) < bank - 0.6:
		_fail("Hall must follow the actual paid Mill far-bank crossing with the same earned five")
		return result()
	for id: String in CAPTAIN_IDS:
		if _has(str(TRAINERS.trainer(id).get("defeat_flag", ""))):
			_fail("The next captain is already defeated: " + id)
			return result()
	for id: String in SIGILS:
		if _count(id) != 0:
			_fail("The next earned sigil is already carried: " + id)
			return result()
	if _has("hall_approach_open") or bool(_sigil_gate.call("is_open")) or _has("defeated_warden"):
		_fail("The Sigil/Hall route is already completed or bypassed")
		return result()
	_hall_config = _read(HALL_CONFIG)
	if gauntlet_path(_hall_config).size() != 3:
		_fail("The current authored three-guard passage chain is incomplete")
		return result()
	for flag: String in HALL_FLAGS + ["defeated_warden"]:
		if _has(flag) or not shutter_receipt(_hold, flag, false):
			_fail("The actual unopened Hall shutter is absent or already open: " + flag)
			return result()
	_input = INPUTS.new()
	_input._tree = tree
	_nav = NAV.new(tree, _player, _rig, _stick)
	_combat.connect("entered", _on_entered)
	_combat.connect("hit_landed", _on_hit)
	_combat.connect("exited", _on_exit)
	_panel.connect("finished", _on_dialogue_finished)
	_arbiter.connect("activated", _on_activated)
	_completed = await _travel()
	_stick(0.0, 0.0)
	_combat.disconnect("entered", _on_entered)
	_combat.disconnect("hit_landed", _on_hit)
	_combat.disconnect("exited", _on_exit)
	_panel.disconnect("finished", _on_dialogue_finished)
	_arbiter.disconnect("activated", _on_activated)
	return result()


func _travel() -> bool:
	var road := departure_spine(_read(TERRAIN))
	if road.is_empty() or not await _prepare():
		return _fail("The current on-foot departure spine or earned care is unavailable")
	var previous := 0
	for id: String in CAPTAIN_IDS:
		var body := _trainers.call("body_for", id) as Node3D
		if not is_instance_valid(body):
			return _fail("The actual Upper Meadows captain is absent: " + id)
		var join := nearest_index(road, Vector2(body.global_position.x, body.global_position.z))
		if join < previous:
			return _fail("The current captain positions no longer follow the authored road order")
		for index in range(previous, join + 1):
			if not await _walk_ground(road[index]):
				return false
		if not await _fight_named(body, id):
			return false
		# Return through the actual road junction before following its next leg.
		if not await _walk_ground(road[join]):
			return false
		previous = join + 1
	var gate_at := Vector2(_sigil_gate.global_position.x, _sigil_gate.global_position.z)
	var gate_join := nearest_index(road, gate_at)
	if gate_join < previous or gate_join + 1 >= road.size():
		return _fail("The current Sigil Gate does not lie after the three captains on the spine")
	for index in range(previous, gate_join + 1):
		if not await _walk_ground(road[index]):
			return false
	var crossing := gate_crossing_points(_sigil_gate.global_transform, road[gate_join], road[gate_join + 1])
	if crossing.size() != 2 or not await _walk_ground(crossing[0], 0.6):
		return _fail("The actual Sigil Gate near side could not be reached")
	var before := _sigil_stock()
	var actual_keys: Array = _sigil_gate.get("key_item_ids")
	if not keys_match(actual_keys) or not all_sigils(before, 1):
		return _fail("The actual gate lacks precisely the three earned captain sigils")
	if not await _talk(_sigil_gate.get_node_or_null("Interactable") as Node3D, str(_sigil_gate.get("unlocked_conversation"))):
		return false
	var shape := _sigil_gate.get("_shape") as CollisionShape3D
	if not sigil_paid_receipt(before, _sigil_stock(), _has("hall_approach_open"), bool(_sigil_gate.call("is_open")),
			shape != null and shape.disabled):
		return _fail("The exact gate input did not spend all three sigils and disable the real leaf")
	if not await _walk_ground(crossing[1], 0.6):
		return false
	var direction := (crossing[1] - crossing[0]).normalized()
	var depth := (Vector2(_player.global_position.x, _player.global_position.z) - gate_at).dot(direction)
	if depth < crossing[1].distance_to(gate_at) - 0.6:
		return _fail("The player has not physically crossed the actual Sigil Gate plane")
	_receipt("hall_approach_open", {"sigils_before": before, "sigils_after": _sigil_stock(), "depth": depth})
	# Stop the terrain spine before it enters the raised Hall footprint.
	var entrance := _hold.call("marker", "entrance") as Vector3
	if not bool(_hold.call("has_marker", "entrance")):
		return _fail("The actual Hall has no approach-ramp entrance marker")
	var entrance_join := nearest_index(road, Vector2(entrance.x, entrance.z))
	for index in range(gate_join + 1, entrance_join + 1):
		if not await _walk_ground(road[index]):
			return false
	if not await _walk(entrance, 0.6):
		return false
	var stages := gauntlet_path(_hall_config)
	var hall_trainers := _hold.call("trainers_node") as Node3D
	if hall_trainers == null or not await _walk_marker(str(stages[0].from), ENTRANCE_FRAMES):
		return _fail("The ordinary Hall ramp did not reach the outer works")
	_supported_y = (_hold.call("marker", str(stages[0].from)) as Vector3).y
	for stage: Dictionary in stages:
		var flag := str(stage.flag)
		if _has(flag) or not shutter_receipt(_hold, flag, false):
			return _fail("The next Hall passage was open before its own guard fell: " + flag)
		var body := hall_trainers.call("body_for", str(stage.trainer)) as Node3D
		if not is_instance_valid(body) or not await _fight_named(body, str(stage.trainer)):
			return false
		for _frame in 120:
			if shutter_receipt(_hold, flag, true):
				break
			await _tree.physics_frame
		if not _has(flag) or not shutter_receipt(_hold, flag, true):
			return _fail("The actual guard victory did not release its own physical shutter: " + flag)
		# Return to the room axis before the narrow passage, instead of drawing
		# a diagonal from the trainer's side alcove through a chamber wall.
		var crossing_start := Engine.get_physics_frames()
		if not await _walk_marker(str(stage.from), ROOM_FRAMES):
			return false
		var shutter := _hold.get_node("BlastShutterBody_" + flag) as Node3D
		var centre: Vector3 = _hold.call("marker", str(stage.from))
		var remaining := room_frames_remaining(Engine.get_physics_frames() - crossing_start)
		if remaining <= 0 or not await _walk(Vector3(shutter.global_position.x, centre.y, shutter.global_position.z), 0.6, remaining):
			return _fail("The actual Hall passage exceeded its unchanged chamber-hop budget")
		remaining = room_frames_remaining(Engine.get_physics_frames() - crossing_start)
		if remaining <= 0 or not await _walk_marker(str(stage.to), remaining):
			return false
		if room_frames_remaining(Engine.get_physics_frames() - crossing_start) <= 0:
			return _fail("Late arrival cannot complete the Hall passage")
		_receipt("hall_passage_crossed", {"trainer": stage.trainer, "flag": flag, "from": stage.from, "to": stage.to,
			"player": _player.global_position})
	if not retained_five(_initial_ids, _party_ids()) or _tree.current_scene != _world \
			or str(_game.get("current_realm")) != "meadows" or _fighting() or _has("defeated_warden") \
			or not shutter_receipt(_hold, "defeated_warden", false):
		return _fail("The retained five did not reach the arena with the Warden and final passage still ahead")
	_receipt("warden_arena_entered", {"party_ids": _party_ids(), "trainers": _observed_trainers.duplicate(),
		"player": _player.global_position, "marker": _hold.call("marker", "warden_arena"), "travel": "on_foot"})
	return true


func _walk_marker(id: String, budget: int) -> bool:
	if not bool(_hold.call("has_marker", id)):
		return _fail("The actual Hall route marker is missing: " + id)
	return await _walk(_hold.call("marker", id), 0.6, budget)


func _fight_named(body: Node3D, id: String) -> bool:
	_captain_spec = TRAINERS.trainer(id)
	var flag := str(_captain_spec.get("defeat_flag", ""))
	if _captain_spec.is_empty() or flag.is_empty() or _has(flag) or not await _prepare():
		return _fail("The exact unbeaten trainer or actual carried preparation is unavailable: " + id)
	var prompt := body.get_node_or_null("Interactable") as Node3D
	if not await _approach_prompt(prompt):
		return false
	var before_items := _captain_stock()
	var before_xp := _xp_snapshot()
	_captain_start = 0
	_captain_rounds = 0
	_captain_wins = 0
	_captain_hits = 0
	_captain_kills.clear()
	_expected_xp.clear()
	for member: int in before_xp:
		_expected_xp[member] = 0
	_named_trainer = id
	_captain_active = true
	if not await _talk(prompt, str(_captain_spec.get("challenge", ""))):
		return false
	if not bool(_director.call("trainer_battle_active")) or str(_director.call("trainer_battle_id")) != id:
		return _fail("Physical challenge input did not admit the exact required trainer: " + id)
	var pilot := LIVE.CampaignPilot.new(_tree, _combat, _director, _rig)
	pilot.use_switching = false
	pilot.switch_input = true
	while bool(_director.call("trainer_battle_active")) and captain_within_deadline(Engine.get_physics_frames() - _captain_start):
		if not _failures.is_empty():
			break
		if bool(_combat.call("is_fighting")):
			var ally := _director.call("ally_body") as Node3D
			var foe := _combat.call("enemy_body") as Node3D
			if is_instance_valid(ally) and is_instance_valid(foe):
				await pilot._act(ally, foe)
				pilot._move_toward(Vector3.ZERO)
			else:
				await _tree.physics_frame
		else:
			await _tree.physics_frame
	pilot._move_toward(Vector3.ZERO)
	_captain_active = false
	var team_size := TRAINERS.team_of(_captain_spec).size()
	if not captain_within_deadline(Engine.get_physics_frames() - _captain_start) or _fighting() \
			or not _failures.is_empty() or _captain_rounds != team_size or _captain_wins != team_size \
			or _captain_kills.size() != team_size or _captain_hits <= 0 or not _has(flag) \
			or not retained_five(_initial_ids, _party_ids()) \
			or not exact_item_reward(before_items, _captain_stock(), _captain_spec.get("reward", {})) \
			or not exact_captain_xp(before_xp, _xp_snapshot(), _expected_xp):
		return _fail("Required trainer lacks exact admitted opponents, killing hits, configured rewards/XP and retained-five receipts: " + id)
	_observed_trainers.append(id)
	_receipt("trainer_defeated", {"id": id, "rounds": _captain_rounds, "wins": _captain_wins, "hits": _captain_hits,
		"items_before": before_items, "items_after": _captain_stock(), "xp_before": before_xp,
		"xp_after": _xp_snapshot(), "expected_xp": _expected_xp.duplicate(), "frames": Engine.get_physics_frames() - _captain_start})
	for _frame in 120:
		if INPUT_OWNER.current(_tree) == null:
			return true
		await _tree.physics_frame
	return _fail("The actual trainer victory did not return ordinary world input: " + id)


func _on_entered() -> void:
	# Relay's observer fixes one captain ID; this route binds the exact current
	# named trainer while retaining its killing-hit XP and outcome observers.
	_fight_started = Engine.get_physics_frames()
	_fight_enemy = _combat.call("enemy")
	_fight_hits = 0
	if not _captain_active:
		return
	var team := TRAINERS.team_of(_captain_spec)
	if str(_director.call("trainer_battle_id")) != _named_trainer or _captain_rounds >= team.size() \
			or not opponent_matches(_fight_enemy, team[_captain_rounds]):
		_fail("The actual admission differs from the next named trainer/opponent")
		return
	if _captain_rounds == 0:
		_captain_start = Engine.get_physics_frames()
	_captain_rounds += 1


static func departure_spine(terrain: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for id: String in ["band3_the_river_lock", "band4_upper_meadows_ironwood", "band5_stronghold_approach"]:
		var band := trail_points(terrain, "bands", id)
		if band.is_empty():
			return []
		if out.is_empty():
			var crossing := mill_config(terrain)
			var road: Array = crossing.get("road", [])
			if road.is_empty():
				return []
			for index in range(nearest_index(band, _v2(road[-1])), band.size()):
				out.append(band[index])
		else:
			if out[-1] != band[0]:
				return []
			out.append_array(band.slice(1))
	return out


static func gauntlet_path(config: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var room := "outer_works"
	for flag: String in HALL_FLAGS:
		var edge: Dictionary = {}
		for passage: Dictionary in config.get("passages", []):
			if str(passage.get("from", "")) == room and str(passage.get("gated_by_flag", "")) == flag:
				edge = passage
		var trainer := ""
		for entry: Dictionary in config.get("gauntlet", []):
			if str(entry.get("chamber", "")) == room \
					and str(TRAINERS.trainer(str(entry.get("trainer", ""))).get("defeat_flag", "")) == flag:
				trainer = str(entry.trainer)
		if edge.is_empty() or trainer.is_empty() or float(edge.get("width", 0)) <= 0:
			return []
		out.append({"from": room, "to": str(edge.to), "flag": flag, "trainer": trainer})
		room = str(edge.to)
	return out if room == "warden_arena" else []


static func gate_crossing_points(at: Transform3D, before: Vector2, after: Vector2) -> Array[Vector2]:
	var centre := Vector2(at.origin.x, at.origin.z)
	var forward := Vector2(at.basis.z.x, at.basis.z.z).normalized()
	if forward.length() < 0.99:
		return []
	if forward.dot(after - before) < 0:
		forward = -forward
	if (before - centre).dot(forward) >= 0 or (after - centre).dot(forward) <= 0:
		return []
	# Same 4m live gate prompt radius, plus 2m clear of its leaf on both sides.
	return [centre - forward * 6.0, centre + forward * 6.0]


static func keys_match(keys: Array) -> bool:
	if keys.size() != SIGILS.size():
		return false
	for id: String in SIGILS:
		if not keys.has(id):
			return false
	return true


static func room_frames_remaining(elapsed: int) -> int:
	return maxi(0, ROOM_FRAMES - elapsed) if elapsed >= 0 else 0


static func all_sigils(stock: Dictionary, count: int) -> bool:
	if stock.size() != SIGILS.size():
		return false
	for id: String in SIGILS:
		if not stock.has(id) or int(stock[id]) != count:
			return false
	return true


static func sigil_paid_receipt(before: Dictionary, after: Dictionary, flag: bool, opened: bool, leaf_disabled: bool) -> bool:
	return all_sigils(before, 1) and all_sigils(after, 0) and flag and opened and leaf_disabled


static func shutter_receipt(hold: Node3D, flag: String, opened: bool) -> bool:
	if not is_instance_valid(hold):
		return false
	var body := hold.get_node_or_null("BlastShutterBody_" + flag) as StaticBody3D
	var mesh := hold.get_node_or_null("BlastShutter_" + flag) as MeshInstance3D
	if body == null or mesh == null or body.get_child_count() != 1:
		return false
	var shape := body.get_child(0) as CollisionShape3D
	return shape != null and shape.shape != null and shape.disabled == opened and mesh.visible != opened


func _sigil_stock() -> Dictionary:
	var stock := {}
	for id: String in SIGILS:
		stock[id] = _count(id)
	return stock


func _receipt(beat: String, detail: Dictionary) -> void:
	detail["beat"] = beat
	_receipts.append(detail)
	print("EARNED HALL — ", detail)


func _fail(message: String) -> bool:
	_failures.append(message)
	print("EARNED HALL FAIL — ", message)
	return false

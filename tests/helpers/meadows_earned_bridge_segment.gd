extends RefCounted

## One departure boundary in the existing world: the closed South Bridge,
## its actual guardian challenge, an earned key and the physical far bank.
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const LIVE := preload("res://tests/helpers/cloudreach_live_segment.gd")
const CARE := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TERRAIN := "res://data/config/terrain_playground.json"
const GUARDIAN := "south_bridge_grunt"
const KEY := "south_bridge_key"
const BATTLE_FRAMES := 9000
const PROMPT_FRAMES := 1800

var _tree: SceneTree
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _bridge: Node3D
var _director: Node
var _combat: Node
var _arbiter: Node
var _panel: Node
var _nav: RefCounted
var _failures: Array[String] = []
var _receipts: Array[Dictionary] = []
var _initial_ids: Array[int] = []
var _completed := false
var _guardian_active := false
var _guardian_hits := 0
var _guardian_wins := 0
var _dialogue_finished := ""


func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		_fail("Earned South Bridge needs the existing tree, world and Game")
		return result()
	if tree.current_scene != world or str(game.get("current_realm")) != "meadows" \
			or INPUT_OWNER.current(tree) != null:
		_fail("Earned South Bridge must start with world input in the live Meadows")
		return result()
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_bridge = world.get_node_or_null("SouthBridge") as Node3D
	_director = world.get_node_or_null("EncounterDirector")
	_combat = world.get_node_or_null("CombatManager")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	_panel = tree.get_first_node_in_group("dialogue_panel")
	if _player == null or _rig == null or _bridge == null or _director == null \
			or _combat == null or _arbiter == null or _panel == null:
		_fail("South Bridge is missing a live traversal, dialogue or combat dependency")
		return result()
	_initial_ids = _party_ids()
	if _initial_ids.size() != 5 or not _has("tournament_won") or not _has("road_gate_open") \
			or _has("defeated_south_bridge_grunt") or _has("south_bridge_open") \
			or bool(_bridge.call("is_open")) or _fighting() or _count(KEY) != 0:
		_fail("Bridge starts after the earned tournament with five retained creatures and its gate/key still unearned")
		return result()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN))
	var crossing := crossing_config(config)
	var route := approach_route(config)
	if crossing.is_empty() or route.is_empty():
		_fail("The current terrain has no continuous lower Meadows approach to South Bridge")
		return result()
	_nav = NAV.new(tree, _player, _rig, _stick)
	_combat.connect("hit_landed", _on_hit)
	_combat.connect("exited", _on_exit)
	_panel.connect("finished", _on_dialogue_finished)
	_completed = await _travel_and_cross(route, crossing)
	_stick(0.0, 0.0)
	_combat.disconnect("hit_landed", _on_hit)
	_combat.disconnect("exited", _on_exit)
	_panel.disconnect("finished", _on_dialogue_finished)
	return result()


func _travel_and_cross(route: Array[Vector2], crossing: Dictionary) -> bool:
	for point: Vector2 in route:
		if not await _walk(point):
			return false
	if not await _prepare_ally():
		return false
	var prompt := _bridge.get_node_or_null("Interactable") as Node3D
	if prompt == null:
		return _fail("The actual South Bridge gate has no interactable")
	var gate_offset := absf(float((crossing.get("bridge", {}) as Dictionary).get("gate_offset", 8.5)))
	if not await _walk(_bridge.call("near_point", gate_offset + 2.5), 0.6):
		return false
	var depth_before := _depth()
	if depth_before >= 0.0 or not await _press_gate(prompt):
		return _fail("The locked gate was not tried from the village side")
	# The production locked callback sends the guardian walking to the player.
	# Wait for that real arrival/dialogue; never call his challenge callback.
	for _frame in PROMPT_FRAMES:
		if bool(_panel.call("is_open")):
			break
		if _fighting():
			return _fail("A fight started before the South Bridge challenge dialogue")
		await _tree.physics_frame
	if not bool(_panel.call("is_open")):
		return _fail("Trying the gate produced no guardian challenge dialogue")
	_dialogue_finished = ""
	for _line in 64:
		if not bool(_panel.call("is_open")):
			break
		await _tap("interact")
	var spec := TRAINERS.trainer(GUARDIAN)
	if _dialogue_finished != str(spec.get("challenge", "")) \
			or not admitted_guardian(_director):
		return _fail("Gate dialogue did not admit the exact South Bridge guardian: " + _dialogue_finished)
	_guardian_active = true
	_receipt("guardian_admitted", {"trainer": GUARDIAN, "depth": depth_before})
	var start := Engine.get_physics_frames()
	var pilot := LIVE.CampaignPilot.new(_tree, _combat, _director, _rig)
	pilot.use_switching = false
	pilot.switch_input = true
	while bool(_director.call("trainer_battle_active")) \
			and Engine.get_physics_frames() - start < BATTLE_FRAMES:
		if not admitted_guardian(_director):
			return _fail("A different trainer replaced the admitted bridge guardian")
		if bool(_combat.call("is_fighting")):
			var ally := _director.call("ally_body") as Node3D
			var foe := _combat.call("enemy_body") as Node3D
			if not is_instance_valid(ally) or not is_instance_valid(foe):
				await _tree.physics_frame
				continue
			# Check the remaining real-physics budget between input decisions.
			# A whole base-pilot fight counts decisions instead and could keep
			# acting long after this guardian's unchanged deadline had expired.
			await pilot._act(ally, foe)
			pilot._move_toward(Vector3.ZERO)
		else:
			if str(_combat.call("outcome")) == "lost":
				return _fail("The earned party lost the actual bridge guardian fight")
			await _tree.physics_frame
	_guardian_active = false
	if not within_guardian_deadline(Engine.get_physics_frames() - start) or bool(_director.call("trainer_battle_active")) \
			or not battle_receipt(_guardian_wins, _guardian_hits,
			TRAINERS.team_of(spec).size(), _has("defeated_south_bridge_grunt")):
		return _fail("Guardian did not yield the exact real team victories, hits and durable defeat")
	# The nearby victory may auto-open through the same real key spend. If the
	# fight ended farther away, walk back and use the still-live gate prompt.
	for _frame in 120:
		if INPUT_OWNER.current(_tree) == null and not _fighting():
			break
		await _tree.physics_frame
	if INPUT_OWNER.current(_tree) != null or _fighting():
		return _fail("Guardian victory did not return normal world input")
	if not bool(_bridge.call("is_open")):
		if _count(KEY) != reward_key_count(spec):
			return _fail("The defeated guardian did not deliver the authored bridge key")
		if not await _walk(_bridge.call("near_point", gate_offset + 2.5), 0.6) \
				or not await _press_gate(prompt):
			return false
	for _frame in 120:
		if bool(_bridge.call("is_open")) and _has("south_bridge_open"):
			break
		await _tree.physics_frame
	# Start was closed with no key. Observed guardian victories plus the actual
	# key-gated opening and final stock prove the earned reward/spend equation,
	# including when the production auto-open consumes the key in one frame.
	if not unlock_receipt(_has("south_bridge_open"), bool(_bridge.call("is_open")),
			0, reward_key_count(spec), _count(KEY)):
		return _fail("Bridge lacks its real durable unlock and exact key spend")
	var carve: Dictionary = crossing.get("carve", {})
	var bank_distance := float(carve.get("half_width", 0.0)) + float(carve.get("rim", 0.0)) + 3.0
	if not await _walk(_bridge.call("near_point", bank_distance), 0.6) \
			or not await _walk(_bridge.call("far_point", bank_distance), 0.6):
		return false
	if not physical_receipt(depth_before, _depth(), bank_distance - 0.6,
			_initial_ids, _party_ids()) or _tree.current_scene != _world:
		return _fail("The same earned party did not physically reach the bridge's far bank")
	_receipt("south_bridge_crossed", {"trainer": GUARDIAN, "wins": _guardian_wins,
		"hits": _guardian_hits, "key_reward": reward_key_count(spec), "key_remaining": _count(KEY),
		"depth_before": depth_before, "depth_after": _depth(), "party_ids": _party_ids()})
	return true


func _walk(at: Vector2, radius: float = 1.5) -> bool:
	var target := Vector3(at.x, float(_world.call("ground_height_at", at.x, at.y)), at.y)
	var budget := maxi(1800, int(_player.global_position.distance_to(target) / 2.5 * 60.0) + 600)
	_nav.reset()
	for _frame in budget:
		if _fighting():
			_stick(0.0, 0.0)
			if bool(_director.call("trainer_battle_active")):
				return _fail("Unexpected trainer battle interrupted the road")
			if not await _win_fight():
				return false
			for _settle in 120:
				if INPUT_OWNER.current(_tree) == null and not _fighting():
					break
				await _tree.physics_frame
			_nav.reset()
		if INPUT_OWNER.current(_tree) != null:
			_stick(0.0, 0.0)
			return _fail("Unexpected modal interrupted the South Bridge road")
		if _player.global_position.distance_to(target) <= radius:
			_stick(0.0, 0.0)
			return true
		_nav.step(target)
		await _tree.physics_frame
	_stick(0.0, 0.0)
	return _fail("Ordinary road walk did not reach " + str(at))


func _prepare_ally() -> bool:
	var party: RefCounted = _game.get("party")
	var best := -1
	var score := -INF
	for index in int(party.call("size")):
		var member: RefCounted = party.call("at", index)
		if bool(member.get("fainted")) or bool(member.get("resting")) or float(member.get("hp")) <= 0.0:
			continue
		var value := float(member.get("hp"))
		if value > score:
			score = value
			best = index
	if best < 0:
		return _fail("The earned party needs actual recovery before challenging the bridge")
	var chosen: RefCounted = party.call("at", best)
	while float(chosen.get("hp")) < float(chosen.get("max_hp")) * 0.5:
		var cared: Dictionary = await CARE.new().care_existing(_tree, _world, _game, "potion_small", best)
		if not bool(cared.get("passed", false)):
			return _fail("Carried Satchel preparation failed: " + str(cared.get("failures", [])))
	for _press in int(party.call("size")):
		if party.call("active") == chosen:
			break
		await _tap("party_cycle")
	if party.call("active") != chosen:
		return _fail("Party-cycle input did not select the available bridge fighter")
	if _director.call("ally_body") == null:
		await _tap("creature_recall")
	for _frame in 180:
		if bool(_director.call("can_challenge", TRAINERS.trainer(GUARDIAN))):
			return true
		await _tree.physics_frame
	return _fail("Real deployment/party preparation did not make the guardian challenge available")


func _press_gate(prompt: Node3D) -> bool:
	if not bool(_arbiter.call("enabled")) or _arbiter.call("winning_provider") != prompt \
			or not bool(_arbiter.call("winner").get("actionable", false)):
		return _fail("The exact South Bridge gate does not own the actionable interact offer")
	await _tap("interact")
	return true


func _win_fight() -> bool:
	var pilot := LIVE.CampaignPilot.new(_tree, _combat, _director, _rig)
	pilot.use_switching = false
	pilot.switch_input = true
	var observed: Dictionary = await pilot.fight_to_the_end()
	pilot._move_toward(Vector3.ZERO)
	if bool(observed.get("timed_out", true)) or str(observed.get("outcome", "")) != "won":
		return _fail("Earned road combat did not win: " + str(observed))
	return true


static func crossing_config(config: Dictionary) -> Dictionary:
	for row: Dictionary in config.get("crossings", []):
		if str(row.get("id", "")) == "south_bridge":
			return row
	return {}


static func approach_route(config: Dictionary) -> Array[Vector2]:
	var result_points: Array[Vector2] = []
	var road: Array = crossing_config(config).get("road", [])
	if road.is_empty():
		return result_points
	var road_start := Vector2(float(road[0][0]), float(road[0][1]))
	for band: Dictionary in (config.get("trail", {}) as Dictionary).get("bands", []):
		if str(band.get("id", "")) != "band1_lower_meadows":
			continue
		var points: Array = band.get("points", [])
		var join_index := -1
		var closest := INF
		for index in points.size():
			var point := Vector2(float(points[index][0]), float(points[index][1]))
			if point.distance_to(road_start) < closest:
				closest = point.distance_to(road_start)
				join_index = index
		# The first point is inside the village; the next crosses TrailGate on
		# the authored spine. Stop where the real bridge approach takes over,
		# before the old spine's lateral bend and closed-gate centre.
		for index in range(1, join_index + 1):
			result_points.append(Vector2(float(points[index][0]), float(points[index][1])))
		var crossing := crossing_config(config)
		var carve: Dictionary = crossing.get("carve", {})
		var raw_centre: Array = carve.get("centre", [])
		if raw_centre.size() != 2:
			return []
		var centre := Vector2(float(raw_centre[0]), float(raw_centre[1]))
		var offset := absf(float((crossing.get("bridge", {}) as Dictionary).get("gate_offset", 8.5)))
		for raw: Array in road:
			var point := Vector2(float(raw[0]), float(raw[1]))
			if point.distance_to(centre) <= offset + 2.5:
				break
			result_points.append(point)
		break
	return result_points


static func admitted_guardian(director: Node) -> bool:
	return director != null and bool(director.call("trainer_battle_active")) \
		and str(director.call("trainer_battle_id")) == GUARDIAN


static func battle_receipt(wins: int, hits: int, expected: int, defeated: bool) -> bool:
	return expected > 0 and wins == expected and hits > 0 and defeated


static func within_guardian_deadline(elapsed: int) -> bool:
	return elapsed >= 0 and elapsed < BATTLE_FRAMES


static func reward_key_count(spec: Dictionary) -> int:
	var amount := 0
	for item: Dictionary in TRAINERS.reward_items(spec):
		if str(item.get("id", "")) == KEY:
			amount += int(item.get("count", 1))
	return amount


static func unlock_receipt(flag: bool, open: bool, before: int, reward: int, after: int) -> bool:
	return flag and open and before == 0 and reward == 1 and after == before + reward - 1


static func physical_receipt(before: float, after: float, bank: float,
		old_ids: Array[int], current_ids: Array[int]) -> bool:
	return before < 0.0 and bank > 0.0 and after >= bank \
		and old_ids.size() == 5 and old_ids == current_ids and _unique_ids(old_ids)


static func _unique_ids(ids: Array[int]) -> bool:
	var seen: Array[int] = []
	for id: int in ids:
		if seen.has(id):
			return false
		seen.append(id)
	return true


func _on_hit(on_enemy: bool, _amount: float) -> void:
	if _guardian_active and on_enemy:
		_guardian_hits += 1


func _on_exit(outcome: String) -> void:
	if _guardian_active and outcome == "won":
		_guardian_wins += 1


func _on_dialogue_finished(id: String) -> void:
	_dialogue_finished = id


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	for _frame in 3:
		await _tree.physics_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	for _frame in 5:
		await _tree.physics_frame


func _stick(x: float, z: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, z]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = int(pair[0])
		event.axis_value = float(pair[1])
		Input.parse_input_event(event)


func _party_ids() -> Array[int]:
	var ids: Array[int] = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		ids.append(member.get_instance_id())
	return ids


func _count(item: String) -> int:
	return int((_game.get("inventory") as RefCounted).call("count", item))


func _has(flag: String) -> bool:
	return bool((_game.get("progression") as RefCounted).call("has", flag))


func _depth() -> float:
	return float(_bridge.call("depth_past_crossing", Vector2(_player.global_position.x, _player.global_position.z)))


func _fighting() -> bool:
	return bool(_combat.call("is_fighting")) or bool(_director.call("trainer_battle_active"))


func _receipt(beat: String, detail: Dictionary) -> void:
	detail["beat"] = beat
	_receipts.append(detail)
	print("EARNED BRIDGE — ", detail)


func _fail(message: String) -> bool:
	_failures.append(message)
	print("EARNED BRIDGE FAIL — ", message)
	return false


func result() -> Dictionary:
	return {"passed": _completed and _failures.is_empty(), "completed": _completed,
		"failures": _failures.duplicate(), "receipts": _receipts.duplicate(true),
		"world": _world, "game": _game, "player": _player, "rig": _rig}

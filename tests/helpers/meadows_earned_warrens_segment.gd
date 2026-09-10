extends RefCounted

## Existing-world continuation from the earned South Bridge: the authored quarry,
## the live Warrens entrance/passages, an actual guardian victory, and walking out.
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const LIVE := preload("res://tests/helpers/cloudreach_live_segment.gd")
const CARE := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const INPUTS := preload("res://tests/helpers/meadows_earned_bridge_segment.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TERRAIN := "res://data/config/terrain_playground.json"
const HARVEST := "res://data/config/bands/band2_stone_and_root/harvest.json"
const WARRENS := "res://data/config/burrow_warrens.json"
const BATTLE_FRAMES := 7200  # tools/combat_pilot.gd's existing wild-fight limit.
const ENGAGE_FRAMES := 3600


class QuarryInput extends "res://tests/helpers/gate_a_material_route.gd":
	var walk: Callable

	func _equip(item_id: String) -> bool:
		# The original gather helper addresses tools by material; rootstone uses
		# the same real pickaxe/hotbar/visible-held-prop input path as stone.
		return await super._equip("stone" if item_id == "rootstone" else item_id)

	func _walk_to(target: Vector3, close_enough: float, budget: int) -> bool:
		return await walk.call(target, close_enough, budget)


var _tree: SceneTree
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _warrens: Node3D
var _guardian: Node3D
var _guardian_creature: RefCounted
var _director: Node
var _combat: Node
var _arbiter: Node
var _input: RefCounted
var _nav: RefCounted
var _config: Dictionary
var _initial_ids: Array[int] = []
var _failures: Array[String] = []
var _receipts: Array[Dictionary] = []
var _completed := false
var _allow_guardian := false
var _guardian_before: Dictionary = {}
var _kill_active := 0
var _kill_survivors: Array[int] = []
var _guardian_hits := 0
var _guardian_wins := 0
var _guardian_verified := false
var _fight_started := 0
var _fight_enemy: RefCounted
var _fight_hits := 0


func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		_fail("Earned Warrens needs the existing tree, world and Game")
		return result()
	if tree.current_scene != world or str(game.get("current_realm")) != "meadows" \
			or INPUT_OWNER.current(tree) != null:
		_fail("Earned Warrens requires ordinary world input in the retained Meadows")
		return result()
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_warrens = world.get_node_or_null("BurrowWarrens") as Node3D
	_director = world.get_node_or_null("EncounterDirector")
	_combat = world.get_node_or_null("CombatManager")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	if _player == null or _rig == null or _warrens == null or _director == null \
			or _combat == null or _arbiter == null or world.get_node_or_null("OldQuarry") == null:
		_fail("The live quarry/Warrens traversal or combat dependencies are missing")
		return result()
	_config = _read(WARRENS)
	_guardian = _warrens.call("guardian") as Node3D
	_initial_ids = _party_ids()
	if not retained_five(_initial_ids, _initial_ids) or not _has("south_bridge_open") \
			or not _has("defeated_south_bridge_grunt") or _has(_clear_flag()) \
			or bool(_warrens.call("is_cleared")) or _fighting() \
			or not is_instance_valid(_guardian) or not bool(_guardian.call("is_alive")):
		_fail("Warrens must start after the earned bridge with five retained creatures and a living uncleared guardian")
		return result()
	_guardian_creature = _guardian.get("instance")
	var bridge := world.get_node_or_null("SouthBridge")
	var crossing := INPUTS.crossing_config(_read(TERRAIN))
	var carve: Dictionary = crossing.get("carve", {})
	var far_bank := float(carve.get("half_width", 0.0)) + float(carve.get("rim", 0.0)) + 3.0 - 0.6
	if bridge == null or crossing.is_empty() or not bool(bridge.call("is_open")) \
			or float(bridge.call("depth_past_crossing", Vector2(_player.global_position.x, _player.global_position.z))) < far_bank:
		_fail("The live player has not physically completed the preceding earned South Bridge crossing")
		return result()
	var spec: Dictionary = _config.get("guardian", {})
	if _guardian_creature == null or str(_guardian_creature.get("species_id")) != str(spec.get("species", "")) \
			or int(_guardian_creature.get("level")) != int(spec.get("level", -1)):
		_fail("The actual guardian does not match the current authored encounter")
		return result()
	_input = INPUTS.new()
	_input._tree = tree
	_nav = NAV.new(tree, _player, _rig, _stick)
	_combat.connect("entered", _on_entered)
	_combat.connect("hit_landed", _on_hit)
	_combat.connect("exited", _on_exit)
	_completed = await _travel()
	_stick(0.0, 0.0)
	_combat.disconnect("entered", _on_entered)
	_combat.disconnect("hit_landed", _on_hit)
	_combat.disconnect("exited", _on_exit)
	return result()


func _travel() -> bool:
	var stops := rootstone_stops(_read(HARVEST))
	var terrain := _read(TERRAIN)
	var road := trail_points(terrain, "bands", "band2_stone_and_root")
	var undertrail := trail_points(terrain, "loops", "warren_undertrail")
	var chambers := passage_path(_config, "mouth", str((_config.get("guardian", {}) as Dictionary).get("chamber", "")))
	if stops.is_empty() or road.is_empty() or undertrail.is_empty() or chambers.is_empty():
		return _fail("Current authored quarry, Band2 trail or ungated guardian route is absent")
	var quarry_centre := Vector2.ZERO
	for row: Dictionary in stops:
		quarry_centre += _v2(row.at)
	quarry_centre /= float(stops.size())
	var quarry_join := nearest_index(road, quarry_centre)
	var warren_join := nearest_index(road, undertrail[0])
	if quarry_join < 0 or warren_join <= quarry_join:
		return _fail("The current trail no longer places the quarry before the Warrens approach")
	if not await _prepare():
		return false
	for index in range(quarry_join + 1):
		if not await _walk_ground(road[index]):
			return false
	var gather := QuarryInput.new()
	gather._tree = _tree
	gather._world = _world
	gather._game = _game
	gather._player = _player
	gather._rig = _rig
	gather._arbiter = _arbiter
	gather.walk = _walk
	if not gather._resolve_move_bindings():
		return _fail("The carried pickaxe route lacks its actual controller movement binding")
	gather._nav = NAV.new(_tree, _player, _rig, gather._send_stick)
	for row: Dictionary in stops:
		var at := _v2(row.at)
		if at.distance_to(Vector2(393.0, 1802.0)) < 0.1:
			# Foundation_0's long wall lies between the previous quarry node and
			# this authored node. Stay outside its west return, then round the
			# corner using the same real controller movement as every other leg.
			for clearance: Vector2 in [Vector2(394.1, 1809.0), Vector2(392.85, 1806.82)]:
				if not await _walk_ground(clearance, 1.5):
					return false
		# HarvestNode's production prompt is configured at 2.4m. Requiring a
		# 1.5m centre approach first adds a stricter, non-gameplay collision
		# gate; 2.2m gets the real prompt/arbiter check its intended turn.
		if not await _walk_ground(at, 2.2):
			return false
		var node := gather._authored_node_at(at, "rootstone")
		if node == null:
			return _fail("No unspent authored quarry rootstone at " + str(at))
		var node_id := node.get_instance_id()
		var amount := int(node.call("resource_amount"))
		if amount != int(row.amount):
			return _fail("The live rootstone node does not expose its configured remaining amount")
		var expected := int((_game.get("items") as RefCounted).call("harvest_yield", "rootstone", amount, true, false))
		var before := _count("rootstone")
		if not await gather._harvest_node(node, "rootstone", true):
			return _fail("Actual pickaxe/rootstone input failed: " + str(gather.failures))
		if expected <= 0 or _count("rootstone") - before != expected or not _failures.is_empty():
			return _fail("The actual quarry swing did not yield the configured carried rootstone amount")
		_receipt("quarry_rootstone", {"at": at, "node_id": node_id, "yield": expected,
			"before": before, "after": _count("rootstone")})
	for index in range(quarry_join + 1, warren_join + 1):
		if not await _walk_ground(road[index]):
			return false
	var available: Array = _warrens.call("chamber_ids")
	for chamber: String in chambers:
		if not available.has(chamber):
			return _fail("The loaded cave is missing authored chamber " + chamber)
	var entrance: Vector3 = _warrens.call("marker", "entrance")
	var mouth: Vector3 = _warrens.call("marker", "mouth")
	var outside := outside_approach(entrance, mouth, float((_config.get("site", {}) as Dictionary).get("apron_run_m", 0.0)))
	if outside == Vector3.INF:
		return _fail("The live entrance has no usable mouth direction or authored apron")
	for index in range(nearest_index(undertrail, Vector2(outside.x, outside.z)) + 1):
		if not await _walk_ground(undertrail[index]):
			return false
	if not await _walk_ground(Vector2(outside.x, outside.z)) or not await _prepare():
		return false
	_allow_guardian = true
	# Use marker Y underground. Terrain height there describes the bank above
	# the room, and projecting a chamber back to that surface would walk the roof.
	if not await _walk(entrance):
		return false
	for chamber: String in chambers:
		if not await _walk(_warrens.call("marker", chamber)):
			return false
	if _guardian_wins == 0:
		if not await _engage_guardian() or not await _fight():
			return false
	if not _guardian_verified:
		return _fail("The guardian victory never produced a complete immediate reward receipt")
	for index in range(chambers.size() - 2, -1, -1):
		if not await _walk(_warrens.call("marker", chambers[index])):
			return false
	if not await _walk(entrance) or not await _walk_ground(Vector2(outside.x, outside.z)):
		return false
	if not retained_five(_initial_ids, _party_ids()) or _tree.current_scene != _world \
			or str(_game.get("current_realm")) != "meadows" or _fighting():
		return _fail("The same five earned creatures did not leave the cave in the same world")
	_receipt("warrens_exited", {"player": _player.global_position, "entrance": entrance,
		"outside": outside, "party_ids": _party_ids()})
	return true


func _prepare() -> bool:
	# Bind only the existing care/selection seam, never the opening/team run.
	var care := CARE.new()
	care._tree = _tree
	care._world = _world
	care._game = _game
	care._menu = _game.call("menu")
	if not await care._prepare_pilot(false):
		return _fail("Earned Satchel preparation failed: " + str(care.result().failures))
	if _director.call("ally_body") == null:
		await _input._tap("creature_recall")
	for _frame in 180:
		if str(_director.call("usable_ally_blocker")).is_empty():
			return true
		await _tree.physics_frame
	return _fail("Actual care, party selection and deployment left no usable ally")


func _walk_ground(at: Vector2, radius: float = 1.5) -> bool:
	return await _walk(Vector3(at.x, float(_world.call("ground_height_at", at.x, at.y)), at.y), radius)


func _walk(target: Vector3, radius: float = 1.5, budget: int = -1) -> bool:
	if budget < 0:
		budget = maxi(1800, int(_player.global_position.distance_to(target) / 2.5 * 60.0) + 600)
	_nav.reset()
	for _frame in budget:
		if not _failures.is_empty():
			return false
		if _fighting():
			_stick(0.0, 0.0)
			if not await _fight():
				return false
			_nav.reset()
		if INPUT_OWNER.current(_tree) != null:
			_stick(0.0, 0.0)
			return _fail("Unexpected modal interrupted the real quarry/Warrens walk")
		if _player.global_position.distance_to(target) <= radius:
			_stick(0.0, 0.0)
			return true
		_nav.step(target)
		await _tree.physics_frame
	_stick(0.0, 0.0)
	return _fail("Ordinary quarry/Warrens movement did not reach %s; player=%s" % [target, _player.global_position])


func _engage_guardian() -> bool:
	_nav.reset()
	for _frame in ENGAGE_FRAMES:
		if _fighting():
			_stick(0.0, 0.0)
			return _combat.call("enemy") == _guardian_creature \
				or _fail("Another wild interrupted the guardian's explicit admission")
		if not is_instance_valid(_guardian) or not bool(_guardian.call("is_alive")):
			return _fail("The guardian went down without an observed fight")
		if _arbiter.call("winning_provider") == _director \
				and bool(_arbiter.call("winner").get("actionable", false)) \
				and _director.call("_engageable") == _guardian:
			_stick(0.0, 0.0)
			await _input._tap("interact")
			if _fighting():
				return _combat.call("enemy_body") == _guardian \
					or _fail("The actual admission replaced the exact offered guardian")
		_nav.step(_guardian.global_position)
		await _tree.physics_frame
	_stick(0.0, 0.0)
	return _fail("The exact living Warren Guardian never admitted an ordinary encounter")


func _fight() -> bool:
	if bool(_director.call("trainer_battle_active")) or _fight_enemy == null:
		return _fail("An unexpected trainer or unobserved encounter interrupted the Warrens route")
	var guardian_fight := _fight_enemy == _guardian_creature
	if guardian_fight and not _allow_guardian:
		return _fail("The guardian encounter began before the actual cave approach/preparation")
	var pilot := LIVE.CampaignPilot.new(_tree, _combat, _director, _rig)
	pilot.use_switching = false
	pilot.switch_input = true
	while _fighting() and within_battle_deadline(Engine.get_physics_frames() - _fight_started):
		if _combat.call("enemy") != _fight_enemy or bool(_director.call("trainer_battle_active")):
			pilot._move_toward(Vector3.ZERO)
			return _fail("The admitted wild identity changed during the input fight")
		var ally := _director.call("ally_body") as Node3D
		var foe := _combat.call("enemy_body") as Node3D
		if is_instance_valid(ally) and is_instance_valid(foe):
			await pilot._act(ally, foe)
			pilot._move_toward(Vector3.ZERO)
		else:
			await _tree.physics_frame
	pilot._move_toward(Vector3.ZERO)
	if not within_battle_deadline(Engine.get_physics_frames() - _fight_started) \
			or _fighting() or str(_combat.call("outcome")) != "won" or _fight_hits <= 0:
		return _fail("Real wild combat did not win with landed strikes inside its unchanged physics budget")
	_receipt("wild_victory", {"guardian": guardian_fight, "hits": _fight_hits,
		"enemy_id": _fight_enemy.get_instance_id(), "frames": Engine.get_physics_frames() - _fight_started})
	# Close the reward window before resuming walking: another actual wild on
	# the way to the den centre must not be counted as this guardian's XP.
	if guardian_fight:
		_guardian_verified = await _verify_guardian_reward()
		if not _guardian_verified:
			return false
	for _frame in 120:
		if INPUT_OWNER.current(_tree) == null:
			return true
		await _tree.physics_frame
	return _fail("The actual wild victory did not release world input")


func _on_entered() -> void:
	_fight_started = Engine.get_physics_frames()
	_fight_enemy = _combat.call("enemy")
	_fight_hits = 0
	if _fight_enemy == _guardian_creature:
		if not _guardian_before.is_empty() or _combat.call("enemy_body") != _guardian:
			_fail("The guardian was readmitted or its body did not match the actual site guardian")
		else:
			_guardian_before = {"items": _reward_stock(), "xp": _xp_snapshot()}
			_receipt("guardian_admitted", {"body_id": _guardian.get_instance_id(),
				"creature_id": _guardian_creature.get_instance_id(), "before": _guardian_before.duplicate(true)})


func _on_hit(on_enemy: bool, _amount: float) -> void:
	if not on_enemy or _combat.call("enemy") != _fight_enemy:
		return
	_fight_hits += 1
	if _fight_enemy != _guardian_creature:
		return
	_guardian_hits += 1
	# Production emits the killing hit before ordinary victory XP. Snapshot
	# instance identities here; last_xp_award is keyed by duplicate labels.
	if float(_guardian_creature.get("hp")) <= 0.0 and _kill_active == 0:
		var active: RefCounted = _combat.call("active_creature")
		_kill_active = active.get_instance_id()
		for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
			if not bool(member.get("fainted")):
				_kill_survivors.append(member.get_instance_id())


func _on_exit(outcome: String) -> void:
	if _fight_enemy == _guardian_creature and outcome == "won":
		_guardian_wins += 1


func _verify_guardian_reward() -> bool:
	for _frame in 120:
		if _has(_clear_flag()):
			break
		await _tree.physics_frame
	var reward: Dictionary = (_config.get("clear", {}) as Dictionary).get("reward", {})
	if _guardian_wins != 1 or _guardian_hits <= 0 or _guardian_before.is_empty() \
			or float(_guardian_creature.get("hp")) > 0.0 or not _has(_clear_flag()) \
			or not bool(_warrens.call("is_cleared")) or not retained_five(_initial_ids, _party_ids()) \
			or not exact_item_reward(_guardian_before.items, _reward_stock(), reward) \
			or not exact_xp_reward(_guardian_before.xp, _xp_snapshot(), _kill_active,
				_kill_survivors, int(_guardian_creature.get("level")), int(reward.get("xp_bonus", 0)), PROGRESSION.config()):
		return _fail("Guardian clear lacks exact observed victory, configured payout/XP and retained-five receipts; before=%s after_items=%s after_xp=%s" % [
			_guardian_before, _reward_stock(), _xp_snapshot()])
	_receipt("warrens_cleared", {"hits": _guardian_hits, "wins": _guardian_wins,
		"items_before": _guardian_before.items, "items_after": _reward_stock(),
		"xp_before": _guardian_before.xp, "xp_after": _xp_snapshot(), "kill_active": _kill_active,
		"survivors": _kill_survivors, "party_ids": _party_ids()})
	return true


static func rootstone_stops(config: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row: Dictionary in config.get("nodes", []):
		if str(row.get("item", "")) == "rootstone" and int(row.get("amount", 0)) > 0 \
				and (row.get("at", []) as Array).size() == 2:
			rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.order) < int(b.order))
	return rows


static func trail_points(config: Dictionary, collection: String, id: String) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for row: Dictionary in (config.get("trail", {}) as Dictionary).get(collection, []):
		if str(row.get("id", "")) == id:
			for raw: Array in row.get("points", []):
				points.append(_v2(raw))
	return points


static func nearest_index(points: Array[Vector2], target: Vector2) -> int:
	var index := -1
	var distance := INF
	for candidate in points.size():
		if points[candidate].distance_squared_to(target) < distance:
			distance = points[candidate].distance_squared_to(target)
			index = candidate
	return index


static func passage_path(config: Dictionary, start: String, goal: String) -> Array[String]:
	var queue: Array[Array] = [[start]]
	var visited: Array[String] = [start]
	while not queue.is_empty():
		var path: Array = queue.pop_front()
		var current := str(path[-1])
		if current == goal:
			var answer: Array[String] = []
			answer.assign(path)
			return answer
		for edge: Dictionary in config.get("passages", []):
			if bool(edge.get("gated", false)):
				continue
			var next := ""
			if str(edge.get("from", "")) == current:
				next = str(edge.get("to", ""))
			elif str(edge.get("to", "")) == current:
				next = str(edge.get("from", ""))
			if next.is_empty() or visited.has(next):
				continue
			visited.append(next)
			queue.append(path + [next])
	return []


static func outside_approach(entrance: Vector3, mouth: Vector3, apron: float) -> Vector3:
	var forward := mouth - entrance
	forward.y = 0.0
	if forward.length() < 0.01 or apron <= 0.0:
		return Vector3.INF
	return entrance - forward.normalized() * apron


static func reward_items(reward: Dictionary) -> Dictionary:
	var items := {"coin": int(reward.get("coins", 0))}
	for row: Dictionary in reward.get("items", []):
		var id := str(row.get("id", ""))
		items[id] = int(items.get(id, 0)) + int(row.get("count", 1))
	return items


static func exact_item_reward(before: Dictionary, after: Dictionary, reward: Dictionary) -> bool:
	var expected := reward_items(reward)
	if before.size() != expected.size() or after.size() != expected.size():
		return false
	for id: String in expected:
		if not before.has(id) or not after.has(id) or int(after[id]) - int(before[id]) != int(expected[id]):
			return false
	return true


static func total_xp(level: int, xp: int, cfg: Dictionary) -> int:
	var total := xp
	for completed_level in range(1, level):
		total += PROGRESSION.xp_to_next(completed_level, cfg)
	return total


static func exact_xp_reward(before: Dictionary, after: Dictionary, active: int,
		survivors: Array[int], enemy_level: int, bonus: int, cfg: Dictionary) -> bool:
	if before.size() != 5 or after.size() != 5 or not before.has(active) or not survivors.has(active):
		return false
	var award := PROGRESSION.xp_award_for(enemy_level, cfg)
	for id: int in before:
		if not after.has(id):
			return false
		var expected := 0
		if survivors.has(id):
			expected = bonus + (award if id == active else PROGRESSION.party_share(award, cfg))
		if int(after[id]) - int(before[id]) != expected:
			return false
	return true


static func retained_five(before: Array[int], after: Array[int]) -> bool:
	if before.size() != 5 or before != after:
		return false
	var unique := {}
	for id: int in before:
		unique[id] = true
	return unique.size() == 5


static func within_battle_deadline(elapsed: int) -> bool:
	return elapsed >= 0 and elapsed < BATTLE_FRAMES


static func _v2(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _reward_stock() -> Dictionary:
	var stock := {}
	for id: String in reward_items((_config.get("clear", {}) as Dictionary).get("reward", {})):
		stock[id] = _count(id)
	return stock


func _xp_snapshot() -> Dictionary:
	var snapshot := {}
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		snapshot[member.get_instance_id()] = total_xp(int(member.get("level")), int(member.get("xp")), PROGRESSION.config())
	return snapshot


func _party_ids() -> Array[int]:
	var ids: Array[int] = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		ids.append(member.get_instance_id())
	return ids


func _count(item: String) -> int:
	return int((_game.get("inventory") as RefCounted).call("count", item))


func _has(flag: String) -> bool:
	return bool((_game.get("progression") as RefCounted).call("has", flag))


func _clear_flag() -> String:
	return str((_config.get("clear", {}) as Dictionary).get("flag", "warrens_cleared"))


func _fighting() -> bool:
	return bool(_combat.call("is_fighting")) or bool(_director.call("trainer_battle_active"))


func _stick(x: float, z: float) -> void:
	_input._stick(x, z)


func _receipt(beat: String, detail: Dictionary) -> void:
	detail["beat"] = beat
	_receipts.append(detail)
	print("EARNED WARRENS — ", detail)


func _fail(message: String) -> bool:
	_failures.append(message)
	print("EARNED WARRENS FAIL — ", message)
	return false


func result() -> Dictionary:
	return {"passed": _completed and _failures.is_empty(), "completed": _completed,
		"failures": _failures.duplicate(), "receipts": _receipts.duplicate(true),
		"world": _world, "game": _game, "player": _player, "rig": _rig}

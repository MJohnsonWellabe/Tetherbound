extends "res://tests/helpers/meadows_earned_warrens_segment.gd"

## Retained-world continuation. Only the inherited walking, wild combat, care
## and controller seams are used; the Warrens run/setup is never entered.
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const RELAY_CONFIG := "res://data/config/tether_relay.json"
const CAPTAIN := "relay_captain"
const TRAINER_FRAMES := 9000  # Existing earned bridge/tournament round deadline.
const GEAR := "mill_bridge_gear"
var _relay: Node3D
var _mill: Node3D
var _trainers: Node3D
var _panel: Node
var _captain_spec: Dictionary
var _captain_active := false
var _captain_start := 0
var _captain_rounds := 0
var _captain_wins := 0
var _captain_hits := 0
var _captain_kills: Dictionary = {}
var _expected_xp: Dictionary = {}
var _dialogue_finished := ""
var _activated_id := 0
var _supported_y := NAN


func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		_fail("Earned Relay needs the existing tree, world and Game")
		return result()
	if tree.current_scene != world or str(game.get("current_realm")) != "meadows" or INPUT_OWNER.current(tree) != null:
		_fail("Earned Relay requires ordinary input in the retained Meadows")
		return result()
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_relay = world.get_node_or_null("TetherRelay") as Node3D
	_mill = world.get_node_or_null("MillCrossing") as Node3D
	_trainers = world.get_node_or_null("Trainers") as Node3D
	_warrens = world.get_node_or_null("BurrowWarrens") as Node3D
	_panel = world.get_node_or_null("DialoguePanel")
	_director = world.get_node_or_null("EncounterDirector")
	_combat = world.get_node_or_null("CombatManager")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	if _player == null or _rig == null or _relay == null or _mill == null or _trainers == null \
			or _warrens == null or _panel == null or _director == null or _combat == null or _arbiter == null:
		_fail("The live Relay/Mill route dependencies are missing")
		return result()
	_initial_ids = _party_ids()
	if not retained_five(_initial_ids, _initial_ids) or not _has("warrens_cleared") \
			or not bool(_warrens.call("is_cleared")) or _fighting() or _count(GEAR) != 0 \
			or bool(_relay.call("is_disabled")) or bool(_mill.call("is_open")):
		_fail("Relay requires the retained five after the earned Warrens, with no preowned gear or completed crossing")
		return result()
	for flag: String in ["relay_captain_defeated", "captive_rescued", "relay_disabled", "mill_crossing_restored"]:
		if _has(flag):
			_fail("The next earned departure fact was already present: " + flag)
			return result()
	_config = _read(RELAY_CONFIG)
	_captain_spec = TRAINERS.trainer(CAPTAIN)
	if TRAINERS.team_of(_captain_spec).is_empty():
		_fail("The actual relay captain catalogue entry is absent")
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
	var terrain := _read(TERRAIN)
	var gate := gate_path(_config)
	if gate.size() != 3:
		return _fail("The authored Relay arch has no supported route")
	var outside: Vector2 = _relay.call("world_of", gate[0])
	var approach := approach_path(terrain, Vector2(_player.global_position.x, _player.global_position.z), outside)
	if approach.is_empty() or not await _prepare():
		return _fail("The current Warrens-to-Relay trail or actual care is unavailable")
	for point: Vector2 in approach:
		if not await _walk_ground(point):
			return false
	for point: Vector2 in gate:
		if not await _walk_ground(_relay.call("world_of", point), 0.6):
			return false
	if not await _fight_captain():
		return false
	var sela := _world.get_node_or_null("RelayNPCs/Sela/Interactable") as Node3D
	if not await _talk(sela, "relay_captive_freed"):
		return false
	if not rescue_receipt(_has("relay_captain_defeated"), _has("captive_rescued"), _count(GEAR)):
		return _fail("Sela's actual completed rescue did not provide exactly one bridge gear")
	_receipt("captive_rescued", {"conversation": _dialogue_finished, "gear": _count(GEAR)})
	var deck_route := deck_path(_config)
	if deck_route.is_empty():
		return _fail("The authored ramp/gantry/pad connection is unavailable")
	for index in deck_route.size():
		var local := deck_route[index]
		var at: Vector2 = _relay.call("world_of", Vector2(local.x, local.z))
		var target := Vector3(at.x, local.y, at.y)
		if is_nan(local.y):
			target.y = float(_world.call("ground_height_at", at.x, at.y))
		if not await _walk(target, 0.6):
			return false
		if index > 0 and absf(_player.global_position.y - local.y) > 0.6:
			return _fail("The actual player did not reach the authored deck surface")
		if index == 1:
			_supported_y = local.y
	var lit := int(_relay.call("lit_conduit_count"))
	var console := _relay.get_node_or_null("ApparatusSeam/Console/Interactable") as Node3D
	if lit <= 0 or not await _press_prompt(console):
		return _fail("The live lit Relay console could not be activated by ordinary input")
	if not _has("relay_disabled") or not bool(_relay.call("is_disabled")) or int(_relay.call("lit_conduit_count")) != 0:
		return _fail("The exact console press did not disable the real relay and its conduits")
	_receipt("relay_disabled", {"lit_before": lit, "lit_after": 0, "player": _player.global_position})
	for index in range(deck_route.size() - 1, -1, -1):
		var local := deck_route[index]
		var at: Vector2 = _relay.call("world_of", Vector2(local.x, local.z))
		if is_nan(local.y):
			_supported_y = NAN
			if not await _walk_ground(at, 0.6):
				return false
		elif not await _walk(Vector3(at.x, local.y, at.y), 0.6):
			return false
	for index in range(gate.size() - 1, -1, -1):
		if not await _walk_ground(_relay.call("world_of", gate[index]), 0.6):
			return false
	var onward := mill_path(terrain, outside)
	if onward.is_empty():
		return _fail("The current Relay loop does not rejoin the Mill approach")
	for point: Vector2 in onward:
		if not await _walk_ground(point):
			return false
	var crossing := mill_config(terrain)
	var bridge: Dictionary = crossing.get("bridge", {})
	var channel: Dictionary = crossing.get("channel", {})
	var bank := float(channel.get("half_width", 0.0)) + float(channel.get("rim", 0.0)) + 3.0
	if channel.is_empty() or not await _walk_ground(_mill.call("near_point", float(bridge.get("gate_offset", 0.0)) + 2.5), 0.6):
		return _fail("The authored Mill near bank could not be reached")
	if _count(GEAR) != 1 or not await _press_prompt(_mill.get_node_or_null("Interactable") as Node3D):
		return _fail("The actual Mill gate did not receive its earned gear interaction")
	if not mill_paid_receipt(_count(GEAR), _has("mill_crossing_restored"), bool(_mill.call("is_open"))):
		return _fail("The Mill gate lacks its exact consumed gear and durable open receipt")
	if not await _walk_ground(_mill.call("far_point", bank), 0.6):
		return false
	var depth := float(_mill.call("depth_past_crossing", Vector2(_player.global_position.x, _player.global_position.z)))
	if depth < bank - 0.6 or not retained_five(_initial_ids, _party_ids()) \
			or _tree.current_scene != _world or str(_game.get("current_realm")) != "meadows" or _fighting():
		return _fail("The same earned five did not physically complete the Mill crossing")
	_receipt("mill_crossing_restored", {"gear_before": 1, "gear_after": _count(GEAR), "depth": depth, "party_ids": _party_ids()})
	return true


func _walk(target: Vector3, radius: float = 1.5, budget: int = -1) -> bool:
	if is_nan(_supported_y):
		return await super._walk(target, radius, budget)
	# Once on the gantry, a fall followed by recovery is not a supported deck
	# crossing. Keep the inherited minimum leg budget and watch every frame.
	if budget < 0:
		budget = maxi(1800, int(_player.global_position.distance_to(target) / 2.5 * 60.0) + 600)
	_nav.reset()
	for _frame in budget:
		if not _failures.is_empty() or _fighting() or INPUT_OWNER.current(_tree) != null \
				or _player.global_position.y < _supported_y - 0.6:
			_stick(0.0, 0.0)
			return _fail("The supported Relay deck walk was interrupted or fell below its surface")
		if _player.global_position.distance_to(target) <= radius and _player.is_on_floor():
			_stick(0.0, 0.0)
			return true
		_nav.step(target)
		await _tree.physics_frame
	_stick(0.0, 0.0)
	return _fail("Ordinary movement did not complete the supported Relay deck leg")


func _fight_captain() -> bool:
	var body := _trainers.call("body_for", CAPTAIN) as Node3D
	if not is_instance_valid(body) or not await _prepare():
		return _fail("The living captain or earned preparation is unavailable")
	# Walking can encounter ordinary wilds. Open the exact reward window only
	# after arriving at the real trainer's actionable prompt.
	var prompt := body.get_node_or_null("Interactable") as Node3D
	if not await _approach_prompt(prompt):
		return false
	var reward: Dictionary = _captain_spec.get("reward", {})
	var before_items := _captain_stock()
	var before_xp := _xp_snapshot()
	for id: int in before_xp:
		_expected_xp[id] = 0
	_captain_active = true
	if not await _talk(prompt, str(_captain_spec.get("challenge", ""))):
		return false
	if not bool(_director.call("trainer_battle_active")) or str(_director.call("trainer_battle_id")) != CAPTAIN:
		return _fail("The actual captain dialogue did not admit the exact trainer")
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
	if not captain_within_deadline(Engine.get_physics_frames() - _captain_start) \
			or _fighting() or not _failures.is_empty() or _captain_rounds != team_size or _captain_wins != team_size \
			or _captain_kills.size() != team_size or _captain_hits <= 0 or not _has("relay_captain_defeated") \
			or not retained_five(_initial_ids, _party_ids()) or _count(GEAR) != 0 \
			or not exact_item_reward(before_items, _captain_stock(), reward) \
			or not exact_captain_xp(before_xp, _xp_snapshot(), _expected_xp):
		return _fail("Captain victory lacks exact admitted opponents, landed kills, configured items/XP or retained-five receipts")
	_receipt("relay_captain_defeated", {"rounds": _captain_rounds, "wins": _captain_wins, "hits": _captain_hits,
		"items_before": before_items, "items_after": _captain_stock(), "xp_before": before_xp,
		"xp_after": _xp_snapshot(), "expected_xp": _expected_xp.duplicate(), "gear": _count(GEAR)})
	for _frame in 120:
		if INPUT_OWNER.current(_tree) == null:
			return true
		await _tree.physics_frame
	return _fail("The actual captain victory did not release world input")


func _approach_prompt(prompt: Node3D) -> bool:
	if not is_instance_valid(prompt):
		return _fail("The exact live interaction target is missing")
	_nav.reset()
	for _frame in 1800:
		if not is_nan(_supported_y) and _player.global_position.y < _supported_y - 0.6:
			_stick(0.0, 0.0)
			return _fail("The console approach fell below the actual supported deck surface")
		if _fighting():
			_stick(0.0, 0.0)
			if _captain_active or not await _fight():
				return _fail("Unexpected admission interrupted the exact prompt approach")
			_nav.reset()
		if not is_instance_valid(prompt) or not _failures.is_empty() or INPUT_OWNER.current(_tree) != null:
			return _fail("The target or ordinary input disappeared during the prompt approach")
		if bool(prompt.get("enabled")) and _arbiter.call("winning_provider") == prompt \
				and bool(_arbiter.call("winner").get("actionable", false)):
			_stick(0.0, 0.0)
			return true
		_nav.step(prompt.global_position)
		await _tree.physics_frame
	_stick(0.0, 0.0)
	return _fail("The exact live prompt never became actionable within its unchanged approach budget")


func _press_prompt(prompt: Node3D) -> bool:
	if not await _approach_prompt(prompt):
		return false
	var expected := prompt.get_instance_id()
	_activated_id = 0
	await _input._tap("interact")
	return _activated_id == expected or _fail("Physical Interact activated a different provider than the exact offered target")


func _talk(prompt: Node3D, expected: String) -> bool:
	_dialogue_finished = ""
	if expected.is_empty() or not await _press_prompt(prompt):
		return false
	for _frame in 90:
		if bool(_panel.call("is_open")):
			break
		await _tree.physics_frame
	if not bool(_panel.call("is_open")):
		return _fail("The exact interaction opened no authored dialogue")
	for _line in 64:
		if not bool(_panel.call("is_open")):
			break
		await _input._tap("interact")
		for _frame in 6:
			await _tree.physics_frame
	return (not bool(_panel.call("is_open")) and _dialogue_finished == expected) \
		or _fail("Dialogue input finished '%s', expected '%s'" % [_dialogue_finished, expected])


func _on_entered() -> void:
	super._on_entered()
	if not _captain_active:
		return
	var team := TRAINERS.team_of(_captain_spec)
	if str(_director.call("trainer_battle_id")) != CAPTAIN or _captain_rounds >= team.size() \
			or not opponent_matches(_fight_enemy, team[_captain_rounds]):
		_fail("Captain admission does not match the next actual authored opponent")
		return
	if _captain_rounds == 0:
		_captain_start = Engine.get_physics_frames()
	_captain_rounds += 1


func _on_hit(on_enemy: bool, amount: float) -> void:
	super._on_hit(on_enemy, amount)
	if not _captain_active or not on_enemy or _combat.call("enemy") != _fight_enemy:
		return
	_captain_hits += 1
	var id := _fight_enemy.get_instance_id()
	if float(_fight_enemy.get("hp")) > 0.0 or _captain_kills.has(id):
		return
	_captain_kills[id] = true
	var active: RefCounted = _combat.call("active_creature")
	var survivors: Array[int] = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		if not bool(member.get("fainted")):
			survivors.append(member.get_instance_id())
	accumulate_xp(_expected_xp, active.get_instance_id(), survivors, int(_fight_enemy.get("level")),
		TRAINERS.reward_xp_bonus(_captain_spec) if _captain_kills.size() == TRAINERS.team_of(_captain_spec).size() else 0, PROGRESSION.config())


func _on_exit(outcome: String) -> void:
	super._on_exit(outcome)
	if _captain_active:
		if outcome == "won":
			_captain_wins += 1
		else:
			_fail("The actual captain encounter ended without victory: " + outcome)


func _on_dialogue_finished(id: String) -> void:
	_dialogue_finished = id


func _on_activated(provider: Object) -> void:
	_activated_id = provider.get_instance_id() if is_instance_valid(provider) else 0


func _captain_stock() -> Dictionary:
	var stock := {}
	for id: String in reward_items(_captain_spec.get("reward", {})):
		stock[id] = _count(id)
	return stock


static func captain_within_deadline(elapsed: int) -> bool:
	return elapsed >= 0 and elapsed < TRAINER_FRAMES


static func opponent_matches(creature: RefCounted, row: Dictionary) -> bool:
	return creature != null and str(creature.get("species_id")) == str(row.get("species", "")) \
		and int(creature.get("level")) == int(row.get("level", -1))


static func accumulate_xp(expected: Dictionary, active: int, survivors: Array[int], level: int, bonus: int, cfg: Dictionary) -> void:
	var award := PROGRESSION.xp_award_for(level, cfg)
	for id: int in survivors:
		expected[id] = int(expected.get(id, 0)) + bonus + (award if id == active else PROGRESSION.party_share(award, cfg))


static func exact_captain_xp(before: Dictionary, after: Dictionary, expected: Dictionary) -> bool:
	if before.size() != 5 or after.size() != 5 or expected.size() != 5:
		return false
	for id: int in before:
		if not after.has(id) or not expected.has(id) or int(after[id]) - int(before[id]) != int(expected[id]):
			return false
	return true


static func rescue_receipt(captain_defeated: bool, rescued: bool, gear: int) -> bool:
	return captain_defeated and rescued and gear == 1


static func mill_paid_receipt(gear: int, restored: bool, opened: bool) -> bool:
	return gear == 0 and restored and opened


static func gate_path(config: Dictionary) -> Array[Vector2]:
	var gate: Dictionary = config.get("gate", {})
	if (gate.get("at", []) as Array).size() != 2 or float(gate.get("opening", 0)) <= 0 or float(gate.get("pier_depth", 0)) <= 0:
		return []
	var at := _v2(gate.at)
	var depth := float(gate.pier_depth)
	return [at - Vector2(depth + float(gate.opening), 0), at, at + Vector2(depth + 1.0, 0)]


static func deck_path(config: Dictionary) -> Array[Vector3]:
	var ramps: Array = config.get("ramps", [])
	var decks: Array = config.get("decks", [])
	if ramps.size() != 1 or decks.size() != 2:
		return []
	var ramp: Dictionary = ramps[0]
	var gantry: Dictionary = decks[0]
	var pad: Dictionary = decks[1]
	var start := _v2(ramp.from)
	var end := _v2(ramp.to)
	var g := _v2(gantry.at)
	var p := _v2(pad.at)
	var gs := _v2(gantry.size) * 0.5
	var ps := _v2(pad.size) * 0.5
	var y := float(gantry.deck_y)
	var seam := g.x + gs.x
	if not is_equal_approx(y, float(pad.deck_y)) or not is_equal_approx(y, float(ramp.deck_y)) \
			or not is_equal_approx(seam, p.x - ps.x) or absf(g.y - p.y) >= ps.y \
			or absf(end.x - g.x) > gs.x or absf(end.y - g.y) > gs.y:
		return []
	return [Vector3(start.x, NAN, start.y), Vector3(end.x, y, end.y), Vector3(g.x, y, g.y),
		Vector3(seam, y, g.y), Vector3(seam + 1.0, y, g.y)]


static func approach_path(terrain: Dictionary, start: Vector2, outside: Vector2) -> Array[Vector2]:
	var under := trail_points(terrain, "loops", "warren_undertrail")
	var band2 := trail_points(terrain, "bands", "band2_stone_and_root")
	var band3 := trail_points(terrain, "bands", "band3_the_river_lock")
	var relay := trail_points(terrain, "loops", "relay_approach_loop")
	if under.is_empty() or band2.is_empty() or band3.is_empty() or relay.is_empty():
		return []
	var out: Array[Vector2] = []
	for i in range(nearest_index(under, start), under.size()):
		out.append(under[i])
	for i in range(nearest_index(band2, under[-1]) + 1, band2.size()):
		out.append(band2[i])
	for i in range(1, nearest_index(band3, relay[0]) + 1):
		out.append(band3[i])
	for i in range(1, nearest_index(relay, outside) + 1):
		out.append(relay[i])
	return out


static func mill_path(terrain: Dictionary, outside: Vector2) -> Array[Vector2]:
	var band := trail_points(terrain, "bands", "band3_the_river_lock")
	var relay := trail_points(terrain, "loops", "relay_approach_loop")
	var crossing := mill_config(terrain)
	if band.is_empty() or relay.is_empty() or crossing.is_empty():
		return []
	var road: Array = crossing.get("road", [])
	if road.is_empty():
		return []
	var out: Array[Vector2] = []
	for i in range(nearest_index(relay, outside), relay.size()):
		out.append(relay[i])
	for i in range(nearest_index(band, relay[-1]) + 1, nearest_index(band, _v2(road[0])) + 1):
		out.append(band[i])
	return out


static func mill_config(terrain: Dictionary) -> Dictionary:
	for crossing: Dictionary in terrain.get("crossings", []):
		if str(crossing.get("id", "")) == "old_mill_crossing":
			return crossing
	return {}


func _receipt(beat: String, detail: Dictionary) -> void:
	detail["beat"] = beat
	_receipts.append(detail)
	print("EARNED RELAY — ", detail)


func _fail(message: String) -> bool:
	_failures.append(message)
	print("EARNED RELAY FAIL — ", message)
	return false

extends "res://tests/helpers/meadows_earned_warrens_segment.gd"

## Retained-world continuation. Only the inherited walking, wild combat, care
## and controller seams are used; the Warrens run/setup is never entered.
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const RELAY_CONFIG := "res://data/config/tether_relay.json"
const CAPTAIN := "relay_captain"
const TRAINER_FRAMES := 9000  # Existing earned bridge/tournament round deadline.
const GEAR := "mill_bridge_gear"
## A player reading a victory line before pressing on (same pace as the Hall helper).
const VICTORY_READ_FRAMES := 120
## Optional saved cut; ordinary full Relay callers retain the existing route.
var preparation_only := false
var resume_prepared := false
var prepared_character: Dictionary = {}
var _preparation_caps: Dictionary = {}
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
var _xp_cap_room: Dictionary = {}
var _xp_identity: Dictionary = {}
var _dialogue_finished := ""
var _activated_id := 0
var _activated_name := ""
var _supported_y := NAN
var _relay_capture_probe: RefCounted


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


## The Lockwater Overlook's props (rocks, a rope, a log, a bag; x -132..-124,
## z 3446-3455) sit on the road leg (-160,3420) -> (-60,3520). Seed 15 froze
## there, standing on the rope's collider between two rocks. Rows z 3444 and
## below are open; go round the south-east side.
const OVERLOOK_KNOT := Vector2(-129.0, 3451.0)
const OVERLOOK_CLEAR_M := 6.0
const OVERLOOK_BYPASS: Array[Vector2] = [Vector2(-122.0, 3443.0)]


func _travel() -> bool:
	var terrain := _read(TERRAIN)
	var gate := gate_path(_config)
	if gate.size() != 3:
		return _fail("The authored Relay arch has no supported route")
	var outside: Vector2 = _relay.call("world_of", gate[0])
	var approach := approach_path(terrain, Vector2(_player.global_position.x, _player.global_position.z), outside)
	var relay_road := trail_points(terrain, "loops", "relay_approach_loop")
	if resume_prepared:
		if preparation_only or prepared_character.is_empty() or relay_road.is_empty():
			return _fail("Prepared Relay continuation requires its imported character and authored join")
		for member: RefCounted in _game.get("party").call("members"):
			var id := str(member.get("uid"))
			_preparation_caps[id] = ESSENCE.creature_cap(prepared_character, id)
		if not _preparation_join_ready(relay_road[0]): return false
		_receipt("relay_preparation_loaded", {"join": relay_road[0], "party": _party_hp()})
		# Continue the identical authored suffix after the saved recovery join.
		for index in range(1, nearest_index(relay_road, outside) + 1):
			var point := relay_road[index]
			if not await _around("overlook_bypass", OVERLOOK_KNOT, OVERLOOK_CLEAR_M, OVERLOOK_BYPASS, _v2p(), point) \
					or not await _walk_ground(point):
				return false
	else:
		if approach.is_empty() or not await _prepare():
			return _fail("The current Warrens-to-Relay trail or actual care is unavailable")
		var recovered := false
		for point: Vector2 in approach:
			if not await _around("overlook_bypass", OVERLOOK_KNOT, OVERLOOK_CLEAR_M, OVERLOOK_BYPASS, _v2p(), point) \
					or not await _walk_ground(point):
				return false
			if not relay_road.is_empty() and point == relay_road[0]:
				if recovered or not await _recover_at_riverwatch(point):
					return false
				recovered = true
				if preparation_only:
					if not _preparation_join_ready(point): return false
					_receipt("relay_prepared", {"join": point, "player": _player.global_position,
						"party": _party_hp(), "caps": _preparation_caps.duplicate(), "safe_join": true})
					return true
		if not recovered:
			return _fail("The earned Relay approach missed its authored recovery junction")
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
	if not await _capture_relay_frame("sela-rescued", func() -> bool: return rescue_receipt(_has("relay_captain_defeated"), _has("captive_rescued"), _count(GEAR))): return false
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
	if not await _capture_relay_frame("console-before", func() -> bool: return int(_relay.call("lit_conduit_count")) == lit and not _has("relay_disabled")): return false
	if lit <= 0 or not await _press_prompt(console):
		return _fail("The live lit Relay console could not be activated by ordinary input")
	if not _has("relay_disabled") or not bool(_relay.call("is_disabled")) or int(_relay.call("lit_conduit_count")) != 0:
		return _fail("The exact console press did not disable the real relay and its conduits")
	_receipt("relay_disabled", {"lit_before": lit, "lit_after": 0, "player": _player.global_position})
	if not await _capture_relay_frame("console-aftermath", func() -> bool: return _has("relay_disabled") and bool(_relay.call("is_disabled")) and int(_relay.call("lit_conduit_count")) == 0): return false
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
	if not await _capture_relay_frame("mill-far-bank", func() -> bool: return mill_paid_receipt(_count(GEAR), _has("mill_crossing_restored"), bool(_mill.call("is_open"))) and float(_mill.call("depth_past_crossing", _v2p())) >= bank - 0.6 and not _fighting()): return false
	return true


## Test-local native pixels only. No pose, camera, state or render override.
func _capture_relay_frame(label: String, phase_guard: Callable) -> bool:
	if not OS.get_cmdline_user_args().has("--capture-relay"): return true
	if DisplayServer.get_name() == "headless" or not RenderingServer.render_loop_enabled:
		return _fail("Relay frames require the actual native drawing display")
	if _relay_capture_probe == null:
		_relay_capture_probe = load("res://tests/helpers/f20_ending_probe.gd").new()
	var cid := str(_game.get("local").get("character_id"))
	var owner := INPUT_OWNER.current(_tree)
	var captures_before := int(_relay_capture_probe.get("_capture_index"))
	var stable := func() -> bool:
		return _tree.current_scene == _world and str(_game.get("current_realm")) == "meadows" \
			and str(_game.get("local").get("character_id")) == cid and retained_five(_initial_ids, _party_ids()) \
			and INPUT_OWNER.current(_tree) == owner and phase_guard.call() == true
	if not await _relay_capture_probe.capture(_tree, "relay-" + label, stable) or not stable.call() \
			or int(_relay_capture_probe.get("_capture_index")) != captures_before + 1:
		return _fail("Relay native frame lost its actual phase, owner or retained five: " + label)
	_receipt("relay_visual_capture", {"label": label, "character_id": cid, "party_ids": _party_ids(),
		"completed_native_frame": true, "presentation_overrides": false, "blind_verdict": "pending"})
	return true


func preparation_ready() -> bool:
	var road := trail_points(_read(TERRAIN), "loops", "relay_approach_loop")
	return not road.is_empty() and _preparation_join_ready(road[0])


func _preparation_join_ready(join: Vector2) -> bool:
	var camp := _world.find_child("riverwatch_rest_Rest", true, false) as Node3D
	var bed := camp.get_node_or_null("CampCreatureBed") as Node3D if camp != null else null
	if _tree.current_scene != _world or str(_game.get("current_realm")) != "meadows" \
			or _tree.paused or not _player.is_on_floor() or _v2p().distance_to(join) > 1.5 \
			or _fighting() or INPUT_OWNER.current(_tree) != null \
			or bed == null or int(bed.call("build_index")) != -13 or int(bed.call("occupant_index")) >= 0 \
			or not retained_five(_initial_ids, _party_ids()) or _preparation_caps.size() != 5 \
			or _count(GEAR) != 0 or bool(_relay.call("is_disabled")) or bool(_mill.call("is_open")):
		return _fail("Prepared Relay requires its actual safe join, empty bed and unchanged retained-five world input")
	for flag: String in ["relay_captain_defeated", "captive_rescued", "relay_disabled", "mill_crossing_restored"]:
		if _has(flag): return _fail("Prepared Relay already contains a Captain/Mill departure fact: " + flag)
	for member: RefCounted in _game.get("party").call("members"):
		var id := str(member.get("uid"))
		if bool(member.get("resting")) or bool(member.get("fainted")) \
				or float(member.get("hp")) < float(member.get("max_hp")) - 0.01 \
				or _preparation_caps.get(id, -1) != ESSENCE.creature_cap(_game.get("local").get("redesign_character"), id):
			return _fail("Prepared Relay must retain all five awake at full HP with their exact recovery caps")
	return true


## Use the advertised bed before the first picket. Recover injured members
## serially over real time; Wake early supplies no overnight/rested credit.
func _recover_at_riverwatch(join: Vector2) -> bool:
	var camp := _world.find_child("riverwatch_rest_Rest", true, false) as Node3D
	var bed := camp.get_node_or_null("CampCreatureBed") as Node3D if camp != null else null
	if camp == null or bed == null or int(bed.call("build_index")) != -13 \
			or Vector2(camp.global_position.x, camp.global_position.z).distance_to(Vector2(211.0, 3700.0)) > 0.01 \
			or Vector2(bed.global_position.x, bed.global_position.z).distance_to(Vector2(212.4, 3701.3)) > 0.01 \
			or absf(bed.global_position.y - float(_world.call("ground_height_at", 212.4, 3701.3))) > 0.01 \
			or int(bed.call("occupant_index")) >= 0 or _fighting() or INPUT_OWNER.current(_tree) != null \
			or bool(_mill.call("is_open")) or not retained_five(_initial_ids, _party_ids()):
		return _fail("Ordinary Relay preparation needs the actual grounded, available Riverwatch bed before the closed Mill")
	var care := CARE.new()
	care._tree = _tree
	care._world = _world
	care._game = _game
	care._player = _player
	care._rig = _rig
	care._combat = _combat
	care._arbiter = _arbiter
	care._nav = CARE.NAV.new(_tree, _player, _rig, care._stick, true)
	var party: RefCounted = _game.get("party")
	var inventory_before := care._inventory_snapshot()
	var xp_before := _xp_snapshot()
	var personal: Dictionary = _game.get("local").get("redesign_character")
	var caps_before := {}
	for member: RefCounted in party.call("members"):
		caps_before[str(member.get("uid"))] = ESSENCE.creature_cap(personal, str(member.get("uid")))
	var day_before := int(_game.get("day"))
	var carried_clock_before := float(_game.get("clock_elapsed_seconds"))
	# Observe the actual scene clock, whose elapsed and roll counters receive
	# the same _process delta; a carried save value is not the running clock.
	var look := _world.get_node_or_null("WorldLook")
	var cycle: RefCounted = look.get("_cycle") as RefCounted if look != null else null
	var clock_binding_before: bool = _tree.current_scene == _world \
		and _tree.root.get_node_or_null("Game") == _game and look != null \
		and look.get_parent() == _world and look.get_script() == preload("res://scripts/world/world_look.gd") \
		and look.is_in_group("day_cycle") and cycle != null \
		and cycle.get_script() == preload("res://scripts/world/day_cycle.gd")
	var clock_live_before: bool = clock_binding_before and look.is_processing() \
		and look.process_mode == Node.PROCESS_MODE_ALWAYS and look.get("_clock_frozen") == false
	var elapsed_before: float = float(look.get("_elapsed_seconds")) if clock_binding_before else NAN
	var accum_before: float = float(look.get("_auto_day_accum")) if clock_binding_before else NAN
	var length_before: float = float(cycle.get("day_length_seconds")) if clock_binding_before else NAN
	var clock_values_before: bool = is_finite(elapsed_before) and elapsed_before >= 0.0 \
		and is_finite(accum_before) and is_finite(length_before) and length_before > 0.0 \
		and accum_before >= 0.0 and accum_before < length_before
	var clock_before := {"day": day_before, "elapsed": elapsed_before,
		"accumulator": accum_before, "day_length": length_before}
	if not clock_live_before or not clock_values_before:
		_receipt("riverwatch_recovery_guard_refusal", {"clock_binding": clock_binding_before,
			"clock_live": clock_live_before, "clock_values": clock_values_before, "clock_before": clock_before})
		return _fail("Riverwatch recovery requires its actual live, finite WorldLook clock")
	var recovered_indices: Array[int] = []
	for index in int(party.call("size")):
		var member: RefCounted = party.call("at", index)
		if not bool(member.get("fainted")) and float(member.get("hp")) >= float(member.get("max_hp")) - 0.01:
			continue
		if not await care._recover_at_home_bed(index, bed):
			return _fail("Riverwatch controller recovery failed: " + str(care.result().failures))
		recovered_indices.append(index)
	var awake_full_hp: bool = true
	var caps_unchanged: bool = true
	for member: RefCounted in party.call("members"):
		awake_full_hp = awake_full_hp and not bool(member.get("resting")) and not bool(member.get("fainted")) \
			and float(member.get("hp")) >= float(member.get("max_hp")) - 0.01
		caps_unchanged = caps_unchanged and caps_before.get(str(member.get("uid")), -1) \
			== ESSENCE.creature_cap(_game.get("local").get("redesign_character"), str(member.get("uid")))
	var clock_binding_after: bool = is_instance_valid(look) and _tree.current_scene == _world \
		and _tree.root.get_node_or_null("Game") == _game and _world.get_node_or_null("WorldLook") == look \
		and look.get_parent() == _world and look.get_script() == preload("res://scripts/world/world_look.gd") \
		and look.is_in_group("day_cycle") and look.get("_cycle") == cycle \
		and cycle.get_script() == preload("res://scripts/world/day_cycle.gd")
	var clock_live_after: bool = clock_binding_after and look.is_processing() \
		and look.process_mode == Node.PROCESS_MODE_ALWAYS and look.get("_clock_frozen") == false
	var elapsed_after: float = float(look.get("_elapsed_seconds")) if clock_binding_after else NAN
	var accum_after: float = float(look.get("_auto_day_accum")) if clock_binding_after else NAN
	var length_after: float = float(cycle.get("day_length_seconds")) if clock_binding_after else NAN
	var elapsed_delta := elapsed_after - elapsed_before
	var clock_values_after: bool = is_finite(elapsed_after) and is_finite(accum_after) \
		and is_finite(length_after) and length_after == length_before and is_finite(elapsed_delta) \
		and accum_after >= 0.0 and accum_after < length_before and elapsed_delta >= 0.0 \
		and (recovered_indices.is_empty() or elapsed_delta > 0.0)
	var natural_rolls: int = int(floor((accum_before + elapsed_delta) / length_before)) if clock_values_after else -1
	var expected_accum: float = fposmod(accum_before + elapsed_delta, length_before) if clock_values_after else NAN
	var day_after := int(_game.get("day"))
	var day_accounted: bool = clock_values_after and day_after == day_before + natural_rolls
	var accumulator_accounted: bool = clock_values_after and absf(accum_after - expected_accum) <= 0.000001
	var clock_after := {"day": day_after, "elapsed": elapsed_after,
		"accumulator": accum_after, "day_length": length_after}
	var checks := {"identity_unchanged": retained_five(_initial_ids, _party_ids()),
		"inventory_unchanged": inventory_before == care._inventory_snapshot(), "xp_unchanged": xp_before == _xp_snapshot(),
		"caps_unchanged": caps_unchanged, "awake_full_hp": awake_full_hp,
		"bed_empty": int(bed.call("occupant_index")) < 0, "not_fighting": not _fighting(),
		"ordinary_input": INPUT_OWNER.current(_tree) == null, "clock_binding": clock_binding_after,
		"clock_live": clock_live_after, "clock_values": clock_values_after,
		"day_accounted": day_accounted, "accumulator_accounted": accumulator_accounted}
	if checks.values().has(false):
		# Retain the exact failing boundary, not a guessed cause from the
		# compound label. Only naturally accounted day rolls are permitted.
		_receipt("riverwatch_recovery_guard_refusal", {"identity_unchanged":retained_five(_initial_ids, _party_ids()),
			"party_before":_initial_ids.duplicate(),"party_after":_party_ids(),
			"inventory_unchanged":inventory_before == care._inventory_snapshot(),
			"inventory_before":inventory_before,"inventory_after":care._inventory_snapshot(),
			"xp_unchanged":xp_before == _xp_snapshot(),"xp_before":xp_before,"xp_after":_xp_snapshot(),
			"checks":checks,"day_accounted":day_accounted,"natural_day_rolls":natural_rolls,
			"day_before":day_before,"day_after":day_after,
			"clock_before":clock_before,"clock_after":clock_after,"expected_accumulator":expected_accum,
			"carried_clock_before":carried_clock_before,"carried_clock_after":float(_game.get("clock_elapsed_seconds")),
			"bed_occupant":int(bed.call("occupant_index")),"fighting":_fighting(),
			"input_owner":str(INPUT_OWNER.current(_tree)),"recovered_indices":recovered_indices,
			"care_receipts":care.result().receipts,"scope":"Read-only operands; HP-only and natural-clock guard FAIL"})
		return _fail("Riverwatch HP-only recovery violated retained state, ordinary input or its accounted natural clock")
	_receipt("pre_relay_riverwatch_recovery", {"party": _party_hp(), "recovered_indices": recovered_indices,
		"care_receipts": care.result().receipts, "bed": str(bed.global_position), "join": join,
		"inventory_unchanged": true, "xp_caps_unchanged": true, "natural_day_rolls": natural_rolls,
		"clock_before": clock_before, "clock_after": clock_after,
		"overnight_rest": false, "full_rest_bonus": false})
	_nav.reset()
	_preparation_caps = caps_before.duplicate()
	return await _walk_ground(join)


func _walk(target: Vector3, radius: float = 1.5, budget: int = -1, best_effort := false) -> bool:
	if is_nan(_supported_y):
		return await super._walk(target, radius, budget, best_effort)
	# Once on the gantry, a fall followed by recovery is not a supported deck
	# crossing. Keep the inherited minimum leg budget and watch every frame.
	if budget < 0:
		budget = maxi(1800, int(_player.global_position.distance_to(target) / 2.5 * 60.0) + 600)
	_nav.reset()
	for _frame in budget:
		var owner := INPUT_OWNER.current(_tree)
		if not _failures.is_empty() or _fighting() or owner != null \
				or _player.global_position.y < _supported_y - 0.6:
			_stick(0.0, 0.0)
			return _fail("The supported Relay deck walk was interrupted: player=%s target=%s supported_y=%.2f fighting=%s input_owner=%s"
				% [_player.global_position, target, _supported_y, _fighting(), str(owner)])
		if _player.global_position.distance_to(target) <= radius and _player.is_on_floor():
			_stick(0.0, 0.0)
			return true
		_nav.step(target)
		await _tree.physics_frame
	_stick(0.0, 0.0)
	if best_effort:
		return false
	return _fail("Ordinary movement did not complete the supported Relay deck leg: player=%s target=%s supported_y=%.2f confined_resets=%d"
		% [_player.global_position, target, _supported_y, _nav.confined_resets()])


func _fight_captain() -> bool:
	var body := _trainers.call("body_for", CAPTAIN) as Node3D
	if not is_instance_valid(body) or not await _prepare_for_trainer():
		return _fail("The living captain or earned preparation is unavailable")
	# Walking can encounter ordinary wilds. Open the exact reward window only
	# after arriving at the real trainer's actionable prompt.
	var prompt := body.get_node_or_null("Interactable") as Node3D
	if not await _approach_prompt(prompt):
		return false
	var reward: Dictionary = _captain_spec.get("reward", {})
	var before_items := _captain_stock()
	var before_xp := _xp_snapshot()
	if not _bind_xp_window(before_xp):
		return false
	_captain_active = true
	if not await _talk(prompt, str(_captain_spec.get("challenge", ""))):
		return false
	if not bool(_director.call("trainer_battle_active")) or str(_director.call("trainer_battle_id")) != CAPTAIN:
		return _fail("The actual captain dialogue did not admit the exact trainer")
	var pilot := LIVE.CampaignPilot.new(_tree, _combat, _director, _rig)
	pilot.use_switching = false
	pilot.switch_input = true
	var fight_captured := false
	while bool(_director.call("trainer_battle_active")) and captain_within_deadline(Engine.get_physics_frames() - _captain_start):
		if not _failures.is_empty():
			break
		if bool(_combat.call("is_fighting")):
			var ally := _director.call("ally_body") as Node3D
			var foe := _combat.call("enemy_body") as Node3D
			if is_instance_valid(ally) and is_instance_valid(foe):
				if not fight_captured:
					if not await _capture_relay_frame("captain-fight", func() -> bool: return _fighting() and bool(_director.call("trainer_battle_active")) and str(_director.call("trainer_battle_id")) == CAPTAIN and _combat.call("enemy_body") == foe): return false
					fight_captured = true
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
		# Preserve the exact gate, but expose the rejecting operand on failure.
		# A Captain flag alone is never an earned Relay handoff.
		_receipt("captain_verification_failed", {
			"elapsed_frames": Engine.get_physics_frames() - _captain_start,
			"within_deadline": captain_within_deadline(Engine.get_physics_frames() - _captain_start),
			"fighting": _fighting(), "prior_failures": _failures.duplicate(),
			"required_rounds": team_size, "rounds": _captain_rounds, "wins": _captain_wins,
			"kills": _captain_kills.size(), "hits": _captain_hits,
			"defeat_flag": _has("relay_captain_defeated"),
			"retained_five": retained_five(_initial_ids, _party_ids()), "gear": _count(GEAR),
			"items_match": exact_item_reward(before_items, _captain_stock(), reward),
			"items_before": before_items, "items_after": _captain_stock(), "configured_reward": reward,
			"xp_match": exact_captain_xp(before_xp, _xp_snapshot(), _expected_xp),
			"xp_before": before_xp, "xp_after": _xp_snapshot(), "expected_xp": _expected_xp.duplicate(),
			"xp_identity": _xp_identity.duplicate(true), "xp_cap_room": _xp_cap_room.duplicate()})
		return _fail("Captain victory lacks exact admitted opponents, landed kills, configured items/XP or retained-five receipts")
	_receipt("relay_captain_defeated", {"rounds": _captain_rounds, "wins": _captain_wins, "hits": _captain_hits,
		"items_before": before_items, "items_after": _captain_stock(), "xp_before": before_xp,
		"xp_after": _xp_snapshot(), "expected_xp": _expected_xp.duplicate(), "gear": _count(GEAR)})
	# The captain's `victory_conversation` (F04#1/#6, d541cb04) opens a deferred
	# frame after the win; read it through with Interact at the Hall helper's
	# reader pace before world input is expected back.
	var victory := not str(_captain_spec.get("victory_conversation", "")).is_empty()
	var read := not victory
	for frame in 120 + (VICTORY_READ_FRAMES * 8 if victory else 0):
		if bool(_panel.call("is_open")):
			read = true
			if frame % VICTORY_READ_FRAMES == VICTORY_READ_FRAMES - 1:
				await _input._tap("interact")
		elif INPUT_OWNER.current(_tree) == null and (read or frame >= 30):
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


## A wandering wild's "Call out" offer can win the same Interact frame (seed
## 15, at the relay). A press that activated nothing, or that started a wild
## fight, is fought through and pressed again as a player would; any other
## provider is still a failure, and is named.
const PRESS_ATTEMPTS := 3


func _press_prompt(prompt: Node3D) -> bool:
	# A player talks to whoever stands at that spot now. Keep the prompt's
	# world-relative path and re-find it before each press: seed 15 twice
	# activated `RelayNPCs/Sela/Interactable` as a different instance from the
	# one approached, right after the captain fell.
	var relative := _world.get_path_to(prompt) if is_instance_valid(prompt) and prompt.is_inside_tree() else NodePath()
	for attempt in PRESS_ATTEMPTS:
		if not relative.is_empty():
			var live := _world.get_node_or_null(relative) as Node3D
			if live != null and live != prompt:
				_receipt("press_prompt_refound", {"path": str(relative),
					"old_id": prompt.get_instance_id() if is_instance_valid(prompt) else 0,
					"old_in_tree": is_instance_valid(prompt) and prompt.is_inside_tree(),
					"new_id": live.get_instance_id()})
				prompt = live
		if not await _approach_prompt(prompt):
			return false
		var expected := prompt.get_instance_id()
		var expected_path := str(prompt.get_path())
		_activated_id = 0
		_activated_name = ""
		await _input._tap("interact")
		if _activated_id == expected:
			return true
		var live_now := _world.get_node_or_null(relative) if not relative.is_empty() else null
		if _activated_name == expected_path or (live_now != null and _activated_id == live_now.get_instance_id()):
			# The same prompt at the same place in the tree, as a new instance
			# (seed 15: Sela's, right after the captain fell).
			_receipt("press_same_prompt_new_instance", {"path": expected_path,
				"approached_id": expected, "activated_id": _activated_id})
			return true
		for _frame in 30:
			if _fighting() or _activated_id == expected:
				break
			await _tree.physics_frame
		if _activated_id == expected:
			# The exact offered target, activated after the tap returned (seed 15,
			# Captain Vance, full-run attempt 1): the same provider, just late.
			_receipt("press_late_activation", {"path": expected_path, "id": expected})
			return true
		var wild_took_it := _fighting() and not _captain_active \
				and not bool(_director.call("trainer_battle_active"))
		if _activated_id != 0 and not wild_took_it:
			break
		_receipt("press_retry", {"attempt": attempt + 1, "wanted": str(prompt.name),
			"activated": _activated_name, "wild_fight": wild_took_it})
		if wild_took_it and not await _fight():
			return false
	return _fail("Physical Interact activated a different provider than the exact offered target (wanted %s id=%d in_tree=%s path='%s', got '%s' id=%d)" % [
		str(prompt.name) if is_instance_valid(prompt) else "<freed>",
		prompt.get_instance_id() if is_instance_valid(prompt) else 0,
		str(is_instance_valid(prompt) and prompt.is_inside_tree()),
		str(prompt.get_path()) if is_instance_valid(prompt) and prompt.is_inside_tree() else "",
		_activated_name, _activated_id])


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
	if expected == "relay_captive_freed":
		if not await _capture_relay_frame("sela-exchange", func() -> bool: return bool(_panel.call("is_open")) and _activated_id == prompt.get_instance_id()): return false
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
	var personal: Variant = _game.get("local").get("redesign_character")
	if not personal is Dictionary:
		_fail("Trainer XP lost the actual personal cap record")
		return
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		var member_id := member.get_instance_id()
		if not _xp_identity.has(member_id) \
			or _xp_identity[member_id].uid != str(member.get("uid")) \
			or _xp_identity[member_id].cap != ESSENCE.creature_cap(personal, str(member.get("uid"))):
			_fail("Trainer XP changed its original creature identity or admitted cap")
			return
		if not bool(member.get("fainted")):
			survivors.append(member.get_instance_id())
	var owner_id := str(_combat.get("_ordinary_reward_owned_id"))
	var hybrid := not owner_id.is_empty()
	if hybrid and owner_id != str(_combat.call("encounter_id")):
		_fail("Trainer XP owner no longer binds the actual encounter")
		return
	if not accumulate_xp(_expected_xp, active.get_instance_id(), survivors, int(_fight_enemy.get("level")),
		TRAINERS.reward_xp_bonus(_captain_spec) if _captain_kills.size() == TRAINERS.team_of(_captain_spec).size() else 0,
		PROGRESSION.config(), hybrid, ESSENCE.config(), _xp_cap_room):
		_fail("Trainer XP has invalid configured awards or original cap room")


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
	_activated_name = str(provider.get_path()) if provider is Node else str(provider)


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


func _bind_xp_window(before: Dictionary) -> bool:
	_expected_xp.clear()
	_xp_cap_room.clear()
	_xp_identity.clear()
	var personal: Variant = _game.get("local").get("redesign_character")
	if not personal is Dictionary or before.size() != 5:
		return _fail("Trainer XP requires the actual five-member baseline and personal caps")
	var cfg := PROGRESSION.config()
	var seen := {}
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		var id := member.get_instance_id()
		var uid := str(member.get("uid"))
		var cap := ESSENCE.creature_cap(personal, uid)
		if uid.is_empty() or seen.has(uid) or not before.has(id) or cap < int(member.get("level")) \
			or int(before[id]) != total_xp(int(member.get("level")), int(member.get("xp")), cfg):
			return _fail("Trainer XP baseline does not bind five distinct owned creatures and valid caps")
		var room := total_xp(cap, 0, cfg) - int(before[id])
		if room < 0:
			return _fail("Trainer XP baseline already exceeds its admitted cap")
		seen[uid] = true
		_xp_identity[id] = {"uid": uid, "cap": cap}
		_xp_cap_room[id] = room
		_expected_xp[id] = 0
	return _xp_identity.size() == 5 or _fail("Trainer XP baseline lost an original member")


static func accumulate_xp(expected: Dictionary, active: int, survivors: Array[int], level: int, bonus: int,
		cfg: Dictionary, hybrid: bool = false, essence_cfg: Dictionary = {}, cap_room: Dictionary = {}) -> bool:
	var award := PROGRESSION.scaled_combat_xp(level, cfg, essence_cfg) if hybrid else PROGRESSION.xp_award_for(level, cfg)
	var share := PROGRESSION.scaled_party_combat_xp(level, cfg, essence_cfg) if hybrid else PROGRESSION.party_share(award, cfg)
	if award <= 0 or share <= 0 or bonus < 0:
		return false
	if not cap_room.is_empty():
		for id: int in survivors:
			if not expected.has(id) or not cap_room.has(id) or int(cap_room[id]) < 0:
				return false
	for id: int in survivors:
		var cumulative := int(expected.get(id, 0)) + bonus + (award if id == active else share)
		expected[id] = mini(cumulative, int(cap_room[id])) if not cap_room.is_empty() else cumulative
	return true


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

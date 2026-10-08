extends "res://tests/helpers/meadows_earned_relay_segment.gd"

## On-foot continuation after the earned Mill crossing. The Relay entrypoint
## is not called: only its physical prompt, care, walking and combat observers
## are reused. Warden combat, riding and the legendary choice are later work.
const HALL_CONFIG := "res://data/config/stronghold.json"
const MATERIAL_GATHER := preload("res://tests/helpers/meadows_earned_material_segment.gd")
const HOME_TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const CAMP_INPUT := preload("res://tests/helpers/meadows_earned_camp_segment.gd")
const BUILD_INPUT := preload("res://tests/helpers/gate_a_build_segment.gd")
const HOME_STATIONS := preload("res://scripts/build/station_rules.gd")
const CAPTAIN_IDS := ["captain_riverwatch", "captain_field", "captain_ridge"]
const SIGILS := ["field_sigil", "ridge_sigil", "river_sigil"]
const HALL_FLAGS := ["defeated_stronghold_patrol", "defeated_stronghold_courtyard", "defeated_stronghold_elite"]
const ROOM_FRAMES := 600  # smoke_stronghold's existing chamber-hop budget.
## VICTORY_READ_FRAMES (a player reading a victory line, F04#6) is inherited from the relay segment.
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
	_collect(world)
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
	_hook()
	_completed = await _travel()
	_stick(0.0, 0.0)
	_unhook()
	return result()


## M2 "save/reload at ... Sigils": an optional reload with all three earned
## Sigils carried, between the last captain and the Sigil Gate. The caller's
## hook saves, frees the world and loads it back; the segment then binds to
## the rebuilt world. Unset (the default) changes nothing.
var before_gate: Callable


func _collect(world: Node) -> void:
	_world = world as Node3D
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_mill = world.get_node_or_null("MillCrossing") as Node3D
	_hold = world.get_node_or_null("Stronghold") as Node3D
	_sigil_gate = world.get_node_or_null("SigilGate") as Node3D
	_trainers = world.get_node_or_null("Trainers") as Node3D
	_panel = world.get_node_or_null("DialoguePanel")
	_director = world.get_node_or_null("EncounterDirector")
	_combat = world.get_node_or_null("CombatManager")
	_arbiter = _tree.get_first_node_in_group("interaction_arbiter")


func _hook() -> void:
	_nav = NAV.new(_tree, _player, _rig, _stick)
	_combat.connect("entered", _on_entered)
	_combat.connect("hit_landed", _on_hit)
	_combat.connect("exited", _on_exit)
	_panel.connect("finished", _on_dialogue_finished)
	_arbiter.connect("activated", _on_activated)


func _unhook() -> void:
	for pair: Array in [[_combat, "entered", _on_entered], [_combat, "hit_landed", _on_hit],
			[_combat, "exited", _on_exit], [_panel, "finished", _on_dialogue_finished],
			[_arbiter, "activated", _on_activated]]:
		var node: Object = pair[0]
		if is_instance_valid(node) and node.is_connected(str(pair[1]), pair[2]):
			node.disconnect(str(pair[1]), pair[2])


func _reload_with_sigils() -> bool:
	if not before_gate.is_valid():
		return true
	if not all_sigils(_sigil_stock(), 1):
		return _fail("The Sigil reload was reached without the three earned Sigils")
	_stick(0.0, 0.0)
	_unhook()
	var ok: bool = await before_gate.call()
	if not ok:
		return _fail("The save/reload with the three Sigils carried failed")
	_collect(_tree.current_scene)
	# The retained-five checks compare creature instance ids, which a load
	# replaces; the caller's reload has already required the saved party UIDs
	# to be identical, so re-baseline on the reloaded instances.
	_initial_ids = _party_ids()
	if _player == null or _sigil_gate == null or _combat == null or _panel == null or _arbiter == null:
		return _fail("The reloaded world lacks the Sigil Gate route dependencies")
	_hook()
	if not all_sigils(_sigil_stock(), 1):
		return _fail("The three earned Sigils did not survive the reload")
	return true


## A spine point that is only a bend in the road (not a captain's junction or
## the gate's) counts as passed within this radius: the points are 60-150 m
## apart, and a wild pack plus a villager standing on the (-152,4235) bend
## held the walker 8.7 m short of it after two real wild wins (seed 15).
const SPINE_BEND_RADIUS := 10.0


func _travel() -> bool:
	var road := departure_spine(_read(TERRAIN))
	if road.is_empty() or not await _prepare():
		return _fail("The current on-foot departure spine or earned care is unavailable")
	if not await _earn_master_t1():
		return false
	var previous := 0
	for id: String in CAPTAIN_IDS:
		var body := _trainers.call("body_for", id) as Node3D
		if not is_instance_valid(body):
			return _fail("The actual Upper Meadows captain is absent: " + id)
		var join := nearest_index(road, Vector2(body.global_position.x, body.global_position.z))
		if join < previous:
			return _fail("The current captain positions no longer follow the authored road order")
		for index in range(previous, join + 1):
			if not await _walk_ground(road[index], 1.5 if index == join else SPINE_BEND_RADIUS):
				return false
		if not await _fight_named(body, id):
			return false
		# Return through the actual road junction before following its next leg.
		if not await _walk_ground(road[join]):
			return false
		previous = join + 1
	if not await _reload_with_sigils():
		return false
	var gate_at := Vector2(_sigil_gate.global_position.x, _sigil_gate.global_position.z)
	var gate_join := nearest_index(road, gate_at)
	if gate_join < previous or gate_join + 1 >= road.size():
		return _fail("The current Sigil Gate does not lie after the three captains on the spine")
	for index in range(previous, gate_join + 1):
		if not await _walk_ground(road[index], 1.5 if index == gate_join else SPINE_BEND_RADIUS):
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


## The L10 quest is earned through Orin's actual chooser, solo duel and chest.
## This does not lift a cap: the Kitchen and chosen Altar spend follow it.
func _earn_master_t1() -> bool:
	var session: Node = _game.get("session")
	var service: Node = session.call("homestead_breakthrough_service") if session != null else null
	if service == null or not bool(session.call("is_host")):
		return _fail("Earned Master preparation requires the actual solo-host producer")
	var retained: Dictionary = service.call("retained_site", _world, "master_t1")
	if retained.get("status") != "owned":
		return _fail("The installed, producer-owned Orin site is unavailable")
	var site: Node3D = retained.site
	var definition: Dictionary = site.get("_definition")
	var master_prompt := site.get_node_or_null("Master/Interactable") as Node3D
	var chest := site.get_node_or_null("RecipeChest")
	var chest_prompt: Node3D
	if chest != null:
		for child: Node in chest.get_children():
			if child.get_script() == preload("res://scripts/world/interactable.gd"):
				if chest_prompt != null:
					return _fail("Orin's chest has ambiguous interaction providers")
				chest_prompt = child as Node3D
	if master_prompt == null or chest_prompt == null or definition.get("id") != "master_t1" \
			or int(definition.get("participants", 0)) != 1:
		return _fail("The authored one-creature Master or chest provider is missing")
	var terrain := _read(TERRAIN)
	var crossing := mill_config(terrain)
	var channel: Dictionary = crossing.get("channel", {})
	var bank := float(channel.get("half_width", 0.0)) + float(channel.get("rim", 0.0)) + 3.0
	var band2 := trail_points(terrain, "bands", "band2_stone_and_root")
	var band3 := trail_points(terrain, "bands", "band3_the_river_lock")
	var relay := trail_points(terrain, "loops", "relay_approach_loop")
	var rim := trail_points(terrain, "loops", "quarry_rim_overlook")
	if channel.is_empty() or band2.is_empty() or band3.is_empty() or relay.is_empty() \
			or rim.is_empty() or not bool(_mill.call("is_open")):
		return _fail("The already-paid Mill and authored return roads are unavailable")
	var departure := _v2p()
	var route: Array[Vector2] = [_mill.call("far_point", bank), _mill.call("near_point", bank)]
	var river := mill_path(terrain, relay[0])
	if river.is_empty():
		return _fail("The Relay approach loop cannot be retraced")
	river.reverse()
	route.append_array(river)
	for index in range(nearest_index(band3, relay[0]) - 1, -1, -1):
		route.append(band3[index])
	var quarry_join := nearest_index(band2, rim[-1])
	var master_join := nearest_index(rim, Vector2(site.global_position.x, site.global_position.z))
	if quarry_join < 0 or master_join < 0:
		return _fail("The authored quarry rim has no Master junction")
	for index in range(band2.size() - 2, quarry_join - 1, -1):
		route.append(band2[index])
	for index in range(rim.size() - 2, master_join - 1, -1):
		route.append(rim[index])
	for point: Vector2 in route:
		if not await _around("overlook_bypass", OVERLOOK_KNOT, OVERLOOK_CLEAR_M,
				OVERLOOK_BYPASS, _v2p(), point) or not await _walk_ground(point):
			return false
	if not await _prepare_for_trainer() or not await _approach_prompt(master_prompt):
		return false
	var view: Dictionary = service.call("view")
	var cid := str(_game.get("local").get("character_id"))
	var cards: Array = view.get("party", [])
	var personal: Dictionary = view.get("redesign_character", {})
	var win_receipt := "master_recipe:master_t1:%s:win" % cid
	var chest_receipt := "master_recipe:master_t1:%s" % cid
	if view.get("character_id") != cid or cards.size() != 5 or not retained_five(_initial_ids, _party_ids()) \
			or personal.get("master_wins", []).has("master_t1") or personal.get("feast_recipes", []).has("feast_t1") \
			or personal.get("transaction_receipts", []).has(win_receipt) \
			or personal.get("transaction_receipts", []).has(chest_receipt):
		return _fail("Master preparation lacks five retained creatures or starts after its personal reward")
	var chosen := -1
	var uids: Array[String] = []
	var caps := {}
	for index in cards.size():
		var card: Dictionary = cards[index]
		var card_uid := str(card.get("uid", ""))
		if card_uid.is_empty() or uids.has(card_uid):
			return _fail("The Master chooser has an ambiguous creature identity")
		uids.append(card_uid)
		caps[card_uid] = ESSENCE.creature_cap(personal, card_uid)
		if bool(card.get("fainted", true)) or bool(card.get("resting", false)) or float(card.get("hp", 0.0)) <= 0.0:
			continue
		if chosen < 0 or int(card.level) > int(cards[chosen].level) \
				or (int(card.level) == int(cards[chosen].level) and float(card.hp) > float(cards[chosen].hp)):
			chosen = index
	if chosen < 0:
		return _fail("No conscious owned creature is available for Orin")
	var uid := uids[chosen]
	var pilot := LIVE.CampaignPilot.new(_tree, _combat, _director, _rig)
	pilot.use_switching = false
	pilot.switch_input = false
	var scope: Dictionary = session.call("personal_tm_scope")
	var observed := {"error": ""}
	var completed := func(action: String, original: Dictionary, result: Dictionary) -> void:
		if action not in ["master_win", "master_chest"] or original.get("master_id") != "master_t1":
			return
		if session.call("personal_tm_scope") != scope:
			observed.error = "Master reward changed character/session scope"
		elif result.get("terminal_refusal") == true:
			observed.error = str(result.get("reason", result.get("code", "Master reward refused")))
		elif result.get("ok") == true and result.get("resolved") == true and result.get("settled") == true \
				and result.get("durable") == true and result.get("saved") == true \
				and result.get("owner_saved") == true and result.get("owner_acknowledged") == true:
			observed[action] = {"original": original.duplicate(true), "result": result.duplicate(true)}
	session.connect("homestead_action_completed", completed)
	var finish := func(reason: String) -> bool:
		pilot._move_toward(Vector3.ZERO)
		if session.is_connected("homestead_action_completed", completed):
			session.disconnect("homestead_action_completed", completed)
		return true if reason.is_empty() else _fail(reason)
	_activated_id = 0
	await pilot.press("interact")
	await _tree.process_frame
	var chooser: Node
	for frame in 90:
		chooser = service.get("_panel")
		if _activated_id == master_prompt.get_instance_id() and is_instance_valid(chooser) and chooser.call("is_open") == true:
			break
		await _tree.physics_frame
	if not is_instance_valid(chooser) or chooser.call("is_open") != true or chooser.get("_mode") != "duel" \
			or chooser.get("_master") != "master_t1" or chooser.get("_source") != site or INPUT_OWNER.current(_tree) != chooser:
		return finish.call("Physical Master interaction did not open the exact duel chooser")
	var buttons: Array[Button] = []
	for child: Node in chooser.get("_list").get_children():
		if child is Button:
			buttons.append(child)
	if buttons.size() != cards.size() + 1:
		return finish.call("The Master chooser does not contain five party rows and Back")
	for index in cards.size():
		var label := "%s · Lv %d" % [str(cards[index].get("nickname", cards[index].species_id)), int(cards[index].level)]
		if buttons[index].text != label:
			return finish.call("The Master chooser order no longer matches its canonical party view")
	if buttons[chosen].disabled:
		return finish.call("The chosen owned creature is disabled in the actual chooser")
	for step in buttons.size() * 2:
		if chooser.get_viewport().gui_get_focus_owner() == buttons[chosen]:
			break
		await pilot.press("ui_down")
		await _tree.process_frame
	if chooser.get_viewport().gui_get_focus_owner() != buttons[chosen]:
		return finish.call("Physical d-pad input could not select the intended creature")
	var started := Engine.get_physics_frames()
	await pilot.press("ui_accept")
	var binding := {}
	var foe: RefCounted
	for frame in 90:
		if _fighting() and str(_director.call("trainer_battle_id")) == "master_t1":
			binding = (_director.get("_master_duel") as Dictionary).duplicate(true)
			foe = _combat.call("enemy")
			break
		await _tree.physics_frame
	if binding.get("character_id") != cid or binding.get("creature_uid") != uid or binding.get("master_id") != "master_t1" \
			or str(binding.get("encounter_id", "")).is_empty() or not binding.get("participants") is Dictionary \
			or binding.participants.size() != 1 or foe == null or str(foe.get("species_id")) != str(definition.species_id) \
			or int(foe.get("level")) != int(definition.cap_level):
		return finish.call("Master admission lacks the chosen UID, one participant and configured opponent")
	var encounter := str(binding.encounter_id)
	while captain_within_deadline(Engine.get_physics_frames() - started):
		if not str(observed.error).is_empty():
			return finish.call(str(observed.error))
		if _fighting():
			var combat_party: Array = _combat.get("_party")
			var active: RefCounted = _combat.call("active_creature")
			if _combat.call("enemy") != foe or str(_combat.call("encounter_id")) != encounter \
					or combat_party.size() != 1 or combat_party[0] != active or str(active.get("uid")) != uid:
				return finish.call("The Master fight changed opponent, encounter or sole chosen creature")
			await pilot._act(_director.call("ally_body"), _combat.call("enemy_body"))
			pilot._move_toward(Vector3.ZERO)
		elif not bool(_director.call("trainer_battle_active")) and observed.has("master_win"):
			break
		else:
			await _tree.physics_frame
	pilot._move_toward(Vector3.ZERO)
	if not captain_within_deadline(Engine.get_physics_frames() - started) or _fighting() \
			or bool(_director.call("trainer_battle_active")) or _combat.call("outcome") != "won" \
			or float(foe.get("hp")) > 0.0 or _fight_hits <= 0 or not observed.has("master_win"):
		return finish.call("The actual one-creature Master fight lacks victory and saved personal ACK")
	var win: Dictionary = observed.master_win
	if win.original != {"master_id": "master_t1", "creature_uid": uid, "encounter_id": encounter} \
			or win.result.get("receipt") != win_receipt:
		return finish.call("The durable Master win does not bind this exact duel")
	if not await _approach_prompt(chest_prompt):
		return finish.call("The earned recipe chest could not be approached")
	var candy_before := _count("tether_candy")
	_activated_id = 0
	started = Engine.get_physics_frames()
	await pilot.press("interact")
	while captain_within_deadline(Engine.get_physics_frames() - started) \
			and not observed.has("master_chest") and str(observed.error).is_empty():
		await _tree.physics_frame
	if not str(observed.error).is_empty():
		return finish.call(str(observed.error))
	if _activated_id != chest_prompt.get_instance_id() or not observed.has("master_chest"):
		return finish.call("Physical chest interaction lacks its durable personal completion")
	var claim: Dictionary = observed.master_chest
	personal = _game.get("local").get("redesign_character")
	if claim.original != {"master_id": "master_t1"} or claim.result.get("receipt") != chest_receipt \
			or personal.get("master_wins", []).count("master_t1") != 1 or personal.get("feast_recipes", []).count("feast_t1") != 1 \
			or personal.get("transaction_receipts", []).count(win_receipt) != 1 \
			or personal.get("transaction_receipts", []).count(chest_receipt) != 1 \
			or _count("tether_candy") != candy_before + int(definition.candy) or not retained_five(_initial_ids, _party_ids()):
		return finish.call("The chest lacks exactly one learned feast, configured Candy and retained five")
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		var actual_uid := str(member.get("uid"))
		if not caps.has(actual_uid) or ESSENCE.creature_cap(personal, actual_uid) != caps[actual_uid]:
			return finish.call("Winning or opening the chest changed an owned creature's cap")
	_receipt("master_t1_earned", {"character_id": cid, "chosen_uid": uid, "encounter_id": encounter,
		"win": win, "chest": claim, "candy_before": candy_before, "candy_after": _count("tether_candy"),
		"party_uids": uids, "caps_unchanged": true})
	finish.call("")
	# The learned recipe is only the beginning of a breakthrough. Fund the
	# actual home stations and one matching feast with ordinary gathering.
	# Cooking, feeding and chosen training remain separate production steps.
	if not await _gather_first_feast_stock(band2, rim, quarry_join, master_join):
		return false
	route.reverse()
	for point: Vector2 in route:
		if not await _around("overlook_bypass", OVERLOOK_KNOT, OVERLOOK_CLEAR_M,
				OVERLOOK_BYPASS, _v2p(), point) or not await _walk_ground(point):
			return false
	return await _walk_ground(departure, 0.6)


func _gather_first_feast_stock(band2: Array[Vector2], rim: Array[Vector2],
		quarry_join: int, master_join: int) -> bool:
	var inventory: RefCounted = _game.get("inventory")
	var personal: Dictionary = _game.get("local").get("redesign_character")
	if inventory == null or bool(_game.get("free_build")) \
			or personal.get("feast_recipes", []).count("feast_t1") != 1:
		return _fail("Earned feast materials require the actual learned recipe and paid inventory")
	var needed := {}
	for id: String in ["forge", "kitchen", "altar", "kitchen_meadows"]:
		var costs: Array = _game.call("build_cost_for", id)
		if costs.is_empty():
			return _fail("The actual homestead catalogue has no paid cost for " + id)
		for cost: Dictionary in costs:
			var item := str(cost.get("id", ""))
			var amount := int(cost.get("n", 0))
			if item.is_empty() or amount <= 0:
				return _fail("The homestead catalogue exposes an invalid material cost")
			needed[item] = int(needed.get(item, 0)) + amount
	var refining: Dictionary = _read("res://data/recipes/recipes_forge.json").get("recipes", {}).get("rootiron_ingot", {})
	var output: Dictionary = refining.get("output", {})
	if str(output.get("id", "")) != "rootiron_ingot" or int(output.get("n", 0)) <= 0 \
			or int(needed.get("rootiron_ingot", 0)) <= 0:
		return _fail("The Kitchen attachment lacks its real intermediate refining recipe")
	var units := ceili(float(needed.rootiron_ingot) / float(output.n))
	needed.erase("rootiron_ingot")
	for cost: Dictionary in refining.get("cost", []):
		var item := str(cost.get("id", ""))
		if item.is_empty() or int(cost.get("n", 0)) <= 0:
			return _fail("The refining recipe has an invalid paid input")
		needed[item] = int(needed.get(item, 0)) + units * int(cost.n)
	var feast: Dictionary = BREAKTHROUGH.feasts().get("recipes", {}).get("feast_t1_ground", {})
	if feast.get("feast_id") != "feast_t1" or feast.get("attuned_type") != "ground" \
			or feast.get("station_id") != "kitchen" or int(feast.get("station_tier", 0)) != 1:
		return _fail("The learned first Ground feast lacks its actual Kitchen recipe")
	for item: String in feast.get("cost", {}):
		var amount := int(feast.cost[item])
		if amount <= 0:
			return _fail("The Ground feast has an invalid paid input")
		needed[item] = int(needed.get(item, 0)) + amount
	var attuned_required := int(needed.get("attuned_ground", 0))
	var attuned_before := _count("attuned_ground")
	var node_spec := {}
	for row: Dictionary in _read("res://data/config/essence_nodes.json").get("nodes", []):
		if row.get("id") == "essence_meadows_ground_01":
			node_spec = row
	if node_spec.get("item") != "essence_ground" or node_spec.get("realm") != "meadows" \
			or int(node_spec.get("outputs", {}).get("attuned_ground", 0)) <= 0 \
			or int(node_spec.get("outputs", {}).get("essence_ground", 0)) <= 0:
		return _fail("The actual Ground source does not expose both primary essence and attuned yield")
	needed.erase("attuned_ground")
	if attuned_before < attuned_required:
		var harvests := ceili(float(attuned_required - attuned_before) / float(node_spec.outputs.attuned_ground))
		needed["essence_ground"] = _count("essence_ground") + harvests * int(node_spec.outputs.essence_ground)
	var retained: Array[String] = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		retained.append(str(member.get("uid")))
	var cid := str(_game.get("local").get("character_id"))
	_nav.reset()
	_unhook()
	var home := HOME_TRAVEL.new(_tree, _game)
	if not await home._with_navigation_lessons(Callable(home, "home_key")):
		return _fail("The ordinary Master-to-homestead Home Key return failed: " + str(home.failures))
	_collect(_tree.current_scene)
	var after: Array[String] = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		after.append(str(member.get("uid")))
	if after != retained or str(_game.get("local").get("character_id")) != cid \
			or after.size() != 5 or _player == null or _rig == null:
		return _fail("The actual homestead return changed its stable character or original five")
	_initial_ids = _party_ids()
	_hook()
	var house := _world.find_child("GrandpaHouse", true, false)
	if house == null or not house.has_method("marker"):
		return _fail("The actual farmhouse has no authored exterior marker")
	var door: Vector3 = house.call("marker", "door")
	var inside: Vector3 = house.call("marker", "inside")
	if door.distance_to(inside) <= 0.1:
		return _fail("The farmhouse exterior direction is undefined")
	var exterior := door + (door - inside).normalized() * 2.0
	var gather := MATERIAL_GATHER.new()
	var observation := {}
	var gather_step := func() -> bool:
		var actual: Dictionary = await gather.run(_tree, _world, _game, _player, _rig, false,
			needed, Vector2(exterior.x, exterior.z))
		observation["gathering"] = actual
		return bool(actual.get("passed", false))
	var gathered: bool = await home._with_navigation_lessons(gather_step)
	var result: Dictionary = observation.get("gathering", {})
	if not gathered or _count("attuned_ground") < attuned_required:
		return _fail("The paid feast bill lacks actual harvests or secondary attuned yield: " + str(result))
	if OS.get_cmdline_user_args().has("--lesson-replay-witness"):
		# Home Key's own reader can finish this card before the gathering
		# wrapper resets its local Help cache. Retain the actual observed card
		# across both real walks; an ACK flag alone never supplies its witness.
		if not home.observed_lesson_history().has("homestead"):
			return _fail("First earned farm return did not observe its actual Homestead lesson")
		if not await home.replay_observed_lesson("homestead"):
			return _fail("First Homestead Settings Help replay failed: " + str(home.failures))
		_receipt("first_homestead_lesson_help", {"character_id": cid, "party_uids": retained,
			"lesson": "homestead", "actual_home_return": true, "whole_f46_proven": false})
	for item: String in needed:
		if _count(item) < int(needed[item]):
			return _fail("The gathered homestead bill no longer covers " + item)
	_receipt("first_feast_stock_gathered", {"character_id": cid, "party_uids": retained,
		"needed": needed, "refining_units": units, "attuned_before": attuned_before,
		"attuned_after": _count("attuned_ground"), "gathering": result,
		"stations_built": false, "feast_cooked": false, "cap_lifted": false})
	if not await _place_first_home_stations():
		return false
	if not await _cook_first_ground_feast():
		return false
	if not await _train_first_breakthrough():
		return false
	# Return by the existing earned roads, including the already-open Bridge;
	# the Home Key never poses the trainer back at the Master or Mill.
	var first := trail_points(_read(TERRAIN), "bands", "band1_lower_meadows")
	var lower_join := nearest_index(band2, rim[0]) if not rim.is_empty() else -1
	if first.is_empty() or quarry_join < 0 or lower_join < 0 or master_join < 0:
		return _fail("The ordinary homestead departure lacks its authored return spine")
	if not await gather._walk_target(Vector3(first[0].x,
		float(_world.call("ground_height_at", first[0].x, first[0].y)), first[0].y),
		gather._travel_budget(Vector3(first[0].x, _player.global_position.y, first[0].y))):
		return _fail("The ordinary farmhouse departure could not reach its authored road through open gates")
	for point: Vector2 in first.slice(1):
		if not await _walk_ground(point):
			return false
	# The farm return enters the rim from below. The upper quarry junction
	# belongs to the previous reverse route; it passes the obstructed main
	# road vertex at (400, 1800) and would then double back to this entrance.
	for index in range(1, lower_join + 1):
		if not await _walk_ground(band2[index]):
			return false
	for index in range(master_join + 1):
		if not await _walk_ground(rim[index]):
			return false
	return true


func _place_first_home_stations() -> bool:
	var camp := CAMP_INPUT.new()
	camp._tree = _tree
	camp._world = _world
	camp._game = _game
	camp._player = _player
	camp._rig = _rig
	camp._progression = _game.get("progression")
	camp._party = _game.get("party")
	if not camp._collect_nodes():
		return _fail("The paid station catalogue lacks its existing controller context: " + str(camp.failures))
	camp._resolve_move_bindings()
	var builder := BUILD_INPUT.new()
	builder._tree = _tree
	builder._world = _world
	builder._game = _game
	builder._player = _player
	builder._camera_rig = _rig
	builder._resolve_move_bindings()
	var placer := _tree.get_first_node_in_group(&"build_placer")
	if placer == null or bool(_game.get("free_build")):
		return _fail("Ordinary home stations require the actual paid build placer")
	# These are requested anchors on the existing farmhouse pad. Only a real
	# green ghost and paid producer record may establish that they are usable.
	var plans: Array[Dictionary] = [{"id": "forge", "at": Vector2(-6, 12)},
		{"id": "kitchen", "at": Vector2(-6, 20)}, {"id": "altar", "at": Vector2(-6, 8)},
		{"id": "kitchen_meadows", "at": Vector2.ZERO}]
	for plan: Dictionary in plans:
		var id := str(plan.id)
		var parent_uid := ""
		if id == "kitchen_meadows":
			if not await _refine_first_rootiron(): return false
			var parent: Dictionary = {}
			for row: Dictionary in _game.get("placed_buildings"):
				if row.get("id") == "kitchen" and row.get("removed", false) != true:
					if not parent.is_empty(): return _fail("The actual Kitchen rack parent is ambiguous")
					parent = row.duplicate(true)
			parent_uid = str(parent.get("uid", ""))
			if parent_uid.is_empty(): return _fail("The paid Kitchen has no canonical parent UID")
			var socket := HOME_STATIONS.socket(HOME_STATIONS.config(), parent, 1)
			plan.at = Vector2(socket.x, socket.z)
		var before: Array = _game.get("placed_buildings")
		for record: Dictionary in before:
			if record.get("id") == id:
				return _fail("The earned first-station step started with an existing " + id)
		var before_count := before.size()
		var cost: Dictionary = camp._cost_snapshot(id)
		var previous_nodes: Array[Node] = _tree.get_nodes_in_group(&"placed_building")
		if not await camp._stow_piece() or not await camp._select_piece(id):
			return _fail("Physical station catalogue selection failed: " + str(camp.failures))
		var ghost := placer.get("_ghost") as Node3D
		if ghost == null:
			return _fail("The real catalogue did not arm a station preview")
		var target := Vector3(plan.at.x, ghost.global_position.y, plan.at.y)
		if not await builder._move_ghost_to(target):
			return _fail("The existing controller could not aim the paid station: " + str(builder.failures))
		ghost = placer.get("_ghost") as Node3D
		if ghost == null or not bool(placer.get("_ghost_ok")) \
				or Vector2(ghost.global_position.x, ghost.global_position.z).distance_to(plan.at) > builder.MOVE_EPSILON:
			return _fail("The requested home anchor lacks its actual legal green ghost: " + str(placer.get("_ghost_reason")))
		var placed: Variant = await builder._place_current(id)
		var records: Array = _game.get("placed_buildings")
		if not placed is Vector3 or records.size() != before_count + 1 \
				or not camp._paid_exactly(id, cost):
			return _fail("Physical station placement lacks its exact cost and one new record: " + str(builder.failures) + str(camp.failures))
		var record: Dictionary = records.back()
		var actual: Node3D
		for node: Node in _tree.get_nodes_in_group(&"placed_building"):
			if not previous_nodes.has(node) and int(node.get_meta("placed_index", -1)) == before_count \
					and str(node.get_meta("building_id", "")) == id:
				actual = node as Node3D
		if actual == null or not camp._paid_record(actual, id) or str(record.get("uid", "")).is_empty() \
				or absf(float(record.get("yaw_deg", INF))) > 0.01 \
				or not retained_five(_initial_ids, _party_ids()):
			return _fail("The paid station lacks its real node, stable UID, requested yaw or original five")
		if id == "kitchen_meadows":
			var tier := HOME_STATIONS.effective_tier(HOME_STATIONS.config(), records, parent_uid)
			if record.get("parent_uid") != parent_uid or int(record.get("slot", 0)) != 1 \
					or tier.get("ok") != true or int(tier.get("effective_tier", 0)) != 1:
				return _fail("The paid Kitchen rack lacks its actual parent, slot and derived tier")
		if not await camp._stow_piece() or not await camp._stow_hammer():
			return _fail("The station controller did not return ordinary world input")
		_receipt("first_home_station_paid", {"id": id, "record": record.duplicate(true),
			"actual_node": str(actual.get_path()), "exact_cost": cost,
			"parent_uid": parent_uid, "controller_ghost_and_place": true, "free_build": false})
	return true


## Pay the rack's ingots at the real Forge, using its ordinary tap-start UI.
## The existing Forge smoke's 900-frame completion bound is shared by the
## whole amount here; canonical callbacks, not elapsed time, prove payment.
func _refine_first_rootiron() -> bool:
	var required := 0
	for cost: Dictionary in _game.call("build_cost_for", "kitchen_meadows"):
		if cost.get("id") == "rootiron_ingot": required += int(cost.get("n", 0))
	var units := maxi(0, required - _count("rootiron_ingot"))
	if required <= 0:
		return _fail("The actual Kitchen rack has no Rootiron requirement")
	if units == 0:
		return true
	var forge: Node3D
	for node: Node in _tree.get_nodes_in_group(&"placed_building"):
		if str(node.get_meta("building_id", "")) == "forge" and _world.is_ancestor_of(node):
			if forge != null: return _fail("The earned Forge is ambiguous")
			forge = node as Node3D
	var prompt := forge.get_node_or_null(^"StationInteractable") as Node3D if forge != null else null
	var manual := forge.get_node_or_null(^"ManualForge") if forge != null else null
	var cfg := _read("res://data/config/stations.json")
	var recipe: Dictionary = _read("res://data/recipes/recipes_forge.json").get("recipes", {}).get("rootiron_ingot", {})
	if prompt == null or manual == null or manual.get_script() != preload("res://scripts/build/station_forge.gd") \
			or units > int(cfg.get("forge", {}).get("maximum_manual_units", 0)) or recipe.is_empty():
		return _fail("The actual Forge actor, recipe or manual amount is unavailable")
	var before := {"rootiron_ingot": _count("rootiron_ingot")}
	for cost: Dictionary in recipe.get("cost", []):
		before[str(cost.id)] = _count(str(cost.id))
	var personal: Dictionary = _game.get("local").get("redesign_character")
	var caps := {}
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		caps[str(member.get("uid"))] = ESSENCE.creature_cap(personal, str(member.get("uid")))
	if not await _approach_prompt(prompt):
		return false
	var pilot := LIVE.CampaignPilot.new(_tree, _combat, _director, _rig)
	_activated_id = 0
	await pilot.press("interact")
	var panel: Node
	for frame in 90:
		var owner := INPUT_OWNER.current(_tree)
		if owner != null and owner.get_script() == preload("res://scripts/ui/craft_panel.gd"):
			panel = owner
			break
		await _tree.physics_frame
	if panel == null or panel.get("_station") != forge or panel.get("_producer") != _game.get("session") \
			or _activated_id != prompt.get_instance_id() or int(panel.get("_refining_amount")) != 1:
		return _fail("Physical Forge interaction did not open its canonical one-unit panel")
	for amount in range(1, units):
		if not await _station_focus(panel, "More refining units", pilot): return false
		await pilot.press("ui_accept")
		if int(panel.get("_refining_amount")) != amount + 1:
			return _fail("Physical Forge amount input did not choose the next unit")
	if not await _station_focus(panel, "refine:rootiron_ingot", pilot): return false
	var observed := {"units": [], "stopped": []}
	var completed := func(id: String, count: int) -> void: observed.units.append([id, count])
	var stopped := func(code: String, reason: String) -> void: observed.stopped.append([code, reason])
	manual.connect("unit_completed", completed)
	manual.connect("channel_stopped", stopped)
	var started := Engine.get_physics_frames()
	await pilot.press("ui_accept")
	while Engine.get_physics_frames() - started < 900:
		if not observed.stopped.is_empty(): break
		if observed.units.size() == units and manual.get("_running") != true and manual.get("_pending").is_empty(): break
		await _tree.physics_frame
	manual.disconnect("unit_completed", completed)
	manual.disconnect("channel_stopped", stopped)
	var expected: Array = []
	for count in range(1, units + 1): expected.append(["rootiron_ingot", count])
	if not observed.stopped.is_empty() or observed.units != expected or manual.get("_running") == true \
			or not manual.get("_pending").is_empty() or panel.call("is_open") or INPUT_OWNER.current(_tree) != null \
			or _fighting() or not retained_five(_initial_ids, _party_ids()):
		return _fail("The present Forge lacks exactly its saved units and ordinary world input: " + str(observed))
	for cost: Dictionary in recipe.get("cost", []):
		if _count(str(cost.id)) != int(before[str(cost.id)]) - units * int(cost.n):
			return _fail("Canonical refining did not debit its exact gathered " + str(cost.id))
	var output: Dictionary = recipe.get("output", {})
	if output.get("id") != "rootiron_ingot" or _count("rootiron_ingot") != int(before.rootiron_ingot) + units * int(output.get("n", 0)):
		return _fail("Canonical refining lacks its exact Rootiron output")
	personal = _game.get("local").get("redesign_character")
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		if ESSENCE.creature_cap(personal, str(member.get("uid"))) != caps.get(str(member.get("uid")), -1):
			return _fail("Refining altered an original creature's cap")
	_receipt("first_rootiron_refined", {"source": str(forge.get_path()), "units": units,
		"completed": observed.units, "inventory_before": before, "rootiron_after": _count("rootiron_ingot"),
		"elapsed_frames": Engine.get_physics_frames() - started, "budget_frames": 900,
		"controller_tap_start": true, "canonical_saved_callbacks": true, "caps_unchanged": true})
	return true


func _cook_first_ground_feast() -> bool:
	var session: Node = _game.get("session")
	if not is_instance_valid(session): return _fail("The earned Kitchen has no actual Session")
	var service: Node = session.call("homestead_breakthrough_service")
	if not is_instance_valid(service): return _fail("The earned Kitchen has no actual breakthrough producer")
	var cached_panel: Node = service.get("_panel")
	var kitchen: Node3D
	for node: Node in _tree.get_nodes_in_group(&"placed_building"):
		if str(node.get_meta("building_id", "")) == "kitchen" and _world.is_ancestor_of(node):
			if kitchen != null: return _fail("The earned Kitchen is ambiguous")
			kitchen = node as Node3D
	var prompt := kitchen.get_node_or_null(^"StationInteractable") as Node3D if kitchen != null else null
	var recipe: Dictionary = BREAKTHROUGH.feasts().get("recipes", {}).get("feast_t1_ground", {})
	if prompt == null or recipe.is_empty() or _count("feast_t1_ground") != 0 \
			or (is_instance_valid(cached_panel) and not str(cached_panel.get("_pending_action")).is_empty()):
		return _fail("First feast cooking requires the actual learned Kitchen and no pending craft or prior feast")
	var before := {}
	for item: String in recipe.get("cost", {}): before[item] = _count(item)
	var scope: Dictionary = session.call("personal_tm_scope")
	var personal: Dictionary = _game.get("local").get("redesign_character")
	var caps := {}
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		caps[str(member.get("uid"))] = ESSENCE.creature_cap(personal, str(member.get("uid")))
	if not await _approach_prompt(prompt): return false
	var pilot := LIVE.CampaignPilot.new(_tree, _combat, _director, _rig)
	_activated_id = 0
	await pilot.press("interact")
	var craft: Node
	for frame in 90:
		var owner := INPUT_OWNER.current(_tree)
		if owner != null and owner.get_script() == preload("res://scripts/ui/craft_panel.gd"):
			craft = owner
			break
		await _tree.physics_frame
	if craft == null or craft.get("_station") != kitchen or _activated_id != prompt.get_instance_id():
		return _fail("Physical Kitchen interaction did not open its actual station panel")
	if not await _station_focus(craft, "Cook learned Ascension Feasts", pilot): return false
	await pilot.press("ui_accept")
	var chooser: Node = service.get("_panel")
	for frame in 90:
		if is_instance_valid(chooser) and chooser.call("is_open") and chooser.get("_mode") == "cook": break
		await _tree.physics_frame
		chooser = service.get("_panel")
	if not is_instance_valid(chooser) or chooser.call("is_open") != true or INPUT_OWNER.current(_tree) != chooser \
			or chooser.get("_mode") != "cook" or chooser.get("_source") != kitchen or chooser.get("_service") != service:
		return _fail("The Kitchen handoff did not open its bound learned-feast chooser")
	var label := str(recipe.name) + " · " + str(recipe.cost)
	if not await _breakthrough_focus(chooser, label, pilot): return false
	var observed := {"completed": [], "error": ""}
	var completed := func(action: String, original: Dictionary, reply: Dictionary) -> void:
		if action != "feast_cook" or original.get("recipe_id") != "feast_t1_ground": return
		if session.call("personal_tm_scope") != scope:
			observed.error = "The feast changed its actual character/session scope"
		elif reply.get("terminal_refusal") == true:
			observed.error = str(reply.get("reason", reply.get("code", "Feast refused")))
		elif reply.get("ok") == true and reply.get("resolved") == true and reply.get("settled") == true \
				and reply.get("durable") == true and reply.get("saved") == true \
				and reply.get("owner_saved") == true and reply.get("owner_acknowledged") == true:
			observed.completed.append({"original": original.duplicate(true), "result": reply.duplicate(true)})
	session.connect("homestead_action_completed", completed)
	var started := Engine.get_physics_frames()
	await pilot.press("ui_accept")
	# Same bounded personal completion wait used by this segment's Master chest.
	while captain_within_deadline(Engine.get_physics_frames() - started) \
			and observed.completed.is_empty() and str(observed.error).is_empty():
		await _tree.physics_frame
	session.disconnect("homestead_action_completed", completed)
	if not str(observed.error).is_empty() or observed.completed.size() != 1:
		return _fail("The physical feast tap lacks one saved canonical completion: " + str(observed))
	var claim: Dictionary = observed.completed[0]
	var id := str(claim.original.get("craft_id", ""))
	var receipt := "craft:%s:%s" % [str(_game.get("local").get("character_id")), id]
	personal = _game.get("local").get("redesign_character")
	if id.length() != 32 or not id.is_valid_hex_number(false) or claim.result.get("receipt") != receipt \
			or personal.get("transaction_receipts", []).count(receipt) != 1 \
			or _count("feast_t1_ground") != int(recipe.get("output", {}).get("feast_t1_ground", 0)) \
			or not retained_five(_initial_ids, _party_ids()) or chooser.call("is_open") != true \
			or not str(chooser.get("_pending_action")).is_empty():
		return _fail("The cooked feast lacks its exact item, once-only receipt and settled real chooser")
	for item: String in before:
		if _count(item) != int(before[item]) - int(recipe.cost[item]):
			return _fail("Feast cooking did not debit its exact gathered " + item)
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		if ESSENCE.creature_cap(personal, str(member.get("uid"))) != caps.get(str(member.get("uid")), -1):
			return _fail("Cooking itself lifted an original creature's cap")
	_receipt("first_ground_feast_cooked", {"source": str(kitchen.get_path()), "completion": claim,
		"inventory_before": before, "feast_count": _count("feast_t1_ground"), "caps_unchanged": true,
		"controller_recipe_tap": true, "elapsed_frames": Engine.get_physics_frames() - started})
	if not await _feed_first_ground_feast(chooser, service, pilot): return false
	await pilot.press("menu_cancel")
	return true if not chooser.call("is_open") and INPUT_OWNER.current(_tree) == null \
		else _fail("The settled Kitchen chooser did not return ordinary world input")


## Prefer the first eligible original companion (the starter remains first).
## When its authored row offers evolution, choose its visible Stay option to
## preserve this earned team's species. No cap, choice, level or receipt is set.
func _feed_first_ground_feast(chooser: Node, service: Node, pilot: RefCounted) -> bool:
	var session: Node = _game.get("session")
	var scope: Dictionary = session.call("personal_tm_scope")
	var view: Dictionary = service.call("view")
	var cards: Array = view.get("party", [])
	var personal: Dictionary = view.get("redesign_character", {})
	var definition: Dictionary = BREAKTHROUGH.feasts().get("items", {}).get("feast_t1_ground", {})
	var chosen := {}
	var caps := {}
	if cards.size() != 5 or _count("feast_t1_ground") != 1 or not retained_five(_initial_ids, _party_ids()):
		return _fail("Feeding requires one actually cooked feast and the original five")
	for card: Dictionary in cards:
		var uid := str(card.get("uid", ""))
		caps[uid] = ESSENCE.creature_cap(personal, uid)
		var mirror: Dictionary = personal.get("creatures", {}).get(uid, {})
		if chosen.is_empty() and ESSENCE._species_types(card).has("ground") \
				and preload("res://scripts/masters/breakthrough_panel.gd").feast_matches_current_cap(card, mirror, definition):
			chosen = card.duplicate(true)
	if chosen.is_empty():
		return _fail("No original Ground companion has actually reached the first locked cap; chosen Altar training is still needed")
	var uid := str(chosen.uid)
	var planning := chosen.duplicate(true)
	planning.evolution_choices = personal.creatures[uid].get("evolution_choices", {}).duplicate(true)
	var offer := preload("res://scripts/creatures/evolution.gd").feast_offer(planning, 1)
	if offer.get("ok") != true: return _fail("The chosen companion's actual feast offer is unavailable")
	var choice := "stay" if offer.get("choice_required", false) else ""
	var label := "%s · %s · %s" % [str(chosen.get("nickname", chosen.species_id)),
		BREAKTHROUGH.status(chosen, personal.creatures[uid]), str(definition.name)]
	if not choice.is_empty(): label += " · Stay (permanent this tier)"
	if not await _breakthrough_focus(chooser, "Feed creatures", pilot): return false
	await pilot.press("ui_accept")
	if chooser.call("is_open") != true or chooser.get("_mode") != "feed" or chooser.get("_service") != service \
			or chooser.get("_source") != service or INPUT_OWNER.current(_tree) != chooser:
		return _fail("Physical Feed creatures input did not open the actual personal feast chooser")
	if not await _breakthrough_focus(chooser, label, pilot): return false
	var intent := {"creature_uid": uid, "feast_item": "feast_t1_ground", "choice": choice}
	var observed := {"completed": [], "error": ""}
	var completed := func(action: String, original: Dictionary, reply: Dictionary) -> void:
		if action != "feast_feed" or original != intent: return
		if session.call("personal_tm_scope") != scope:
			observed.error = "Feast feeding changed its character/session scope"
		elif reply.get("terminal_refusal") == true:
			observed.error = str(reply.get("reason", reply.get("code", "Feast feed refused")))
		elif reply.get("ok") == true and reply.get("resolved") == true and reply.get("settled") == true \
				and reply.get("durable") == true and reply.get("saved") == true \
				and reply.get("owner_saved") == true and reply.get("owner_acknowledged") == true:
			observed.completed.append(reply.duplicate(true))
	session.connect("homestead_action_completed", completed)
	var started := Engine.get_physics_frames()
	await pilot.press("ui_accept")
	while captain_within_deadline(Engine.get_physics_frames() - started) \
			and observed.completed.is_empty() and str(observed.error).is_empty():
		await _tree.physics_frame
	session.disconnect("homestead_action_completed", completed)
	if not str(observed.error).is_empty() or observed.completed.size() != 1:
		return _fail("The chosen feast lacks its exact saved personal completion: " + str(observed))
	var after: Dictionary = service.call("view")
	var receipt := "feast_feed:%s:1" % uid
	var next_cap := int(BREAKTHROUGH.master("master_t1").get("next_cap", -1))
	var completed_reply: Dictionary = observed.completed[0]
	personal = after.get("redesign_character", {})
	if completed_reply.get("receipt") != receipt or personal.get("transaction_receipts", []).count(receipt) != 1 \
			or _count("feast_t1_ground") != 0 or not retained_five(_initial_ids, _party_ids()) \
			or after.get("party", []).size() != cards.size() or next_cap <= int(caps[uid]) \
			or chooser.call("is_open") != true or not str(chooser.get("_pending_action")).is_empty():
		return _fail("Feeding lacks exact consumption, once-only receipt and its retained settled chooser")
	for index in cards.size():
		var before: Dictionary = cards[index]
		var actual: Dictionary = after.party[index]
		var member_uid := str(before.uid)
		var expected_cap: int = next_cap if member_uid == uid else int(caps[member_uid])
		if actual.get("uid") != member_uid or actual.get("species_id") != before.get("species_id") \
				or actual.get("level") != before.get("level") or actual.get("xp") != before.get("xp") \
				or ESSENCE.creature_cap(personal, member_uid) != expected_cap:
			return _fail("The feast changed identity, species, level or XP, or lifted an unchosen cap")
	_receipt("first_ground_feast_fed", {"intent": intent, "result": completed_reply,
		"cap_before": caps[uid], "cap_after": next_cap, "level_before": chosen.level,
		"no_level_bonus": true, "original_five_retained": true, "other_caps_unchanged": true,
		"controller_choice": label, "elapsed_frames": Engine.get_physics_frames() - started})
	return true


## One chosen level uses the Candy actually earned from Orin's chest. The
## real Altar quote, controller payment and accepted saved row own the level.
func _train_first_breakthrough() -> bool:
	var session: Node = _game.get("session")
	var before: Dictionary = session.call("homestead_personal_view")
	var cards: Array = before.get("party", [])
	var personal: Dictionary = before.get("redesign_character", {})
	var chosen := {}
	var caps := {}
	var master := BREAKTHROUGH.master("master_t1")
	for card: Dictionary in cards:
		var uid := str(card.get("uid", ""))
		caps[uid] = ESSENCE.creature_cap(personal, uid)
		if int(caps[uid]) == int(master.get("next_cap", -1)) \
				and personal.get("transaction_receipts", []).count("feast_feed:%s:1" % uid) == 1:
			if not chosen.is_empty(): return _fail("The first chosen breakthrough is ambiguous")
			chosen = card.duplicate(true)
	var candy_before := _count("tether_candy")
	if cards.size() != 5 or chosen.is_empty() or candy_before < 1 or not retained_five(_initial_ids, _party_ids()):
		return _fail("Chosen Altar growth requires the actual first breakthrough and earned Candy")
	var uid := str(chosen.uid)
	var altar: Node3D
	for node: Node in _tree.get_nodes_in_group(&"placed_building"):
		if str(node.get_meta("building_id", "")) == "altar" and _world.is_ancestor_of(node):
			if altar != null: return _fail("The earned Altar is ambiguous")
			altar = node as Node3D
	var prompt := altar.get_node_or_null(^"AltarInteraction/TrainingInteractable") as Node3D if altar != null else null
	if prompt == null or not await _approach_prompt(prompt):
		return _fail("The paid Altar lacks its real training provider or ordinary approach")
	var pilot := LIVE.CampaignPilot.new(_tree, _combat, _director, _rig)
	_activated_id = 0
	await pilot.press("interact")
	var panel: Node
	for frame in 90:
		var owner := INPUT_OWNER.current(_tree)
		if owner != null and owner.get_script() == preload("res://scripts/ui/altar_panel.gd"):
			panel = owner
			break
		await _tree.physics_frame
	var key := "altar:meadows:" + str(altar.get_meta("building_uid", ""))
	if panel == null or panel.get("_station_key") != key or _activated_id != prompt.get_instance_id() \
			or not str(panel.get("_pending_id")).is_empty():
		return _fail("Physical Altar interaction did not open its exact station-bound chooser")
	if not await _altar_focus(panel, "creature:" + uid, "ui_down", pilot): return false
	await pilot.press("ui_accept")
	var quote: Dictionary = {}
	for frame in 90:
		quote = (panel.get("_quote") as Dictionary).duplicate(true)
		if panel.get("_creature_uid") == uid and quote.get("creature_uid") == uid and not quote.is_empty(): break
		await _tree.physics_frame
	if quote.get("creature_uid") != uid or int(quote.get("level", -1)) != int(chosen.level) \
			or int(quote.get("cap", -1)) != int(caps[uid]) or int(quote.level) >= int(quote.cap):
		return _fail("The actual selected Altar quote changed UID, level or opened cap")
	var permitted := false
	for payment: Dictionary in quote.get("payments", []):
		if payment.get("id") == "tether_candy" and int(payment.get("cost", 0)) == 1 \
				and int(payment.get("available", 0)) == candy_before: permitted = true
	if not permitted: return _fail("The real Altar quote does not offer the chest's actual Candy")
	await pilot.press("ui_right")
	if not await _altar_focus(panel, "payment:tether_candy", "ui_down", pilot): return false
	var service: Node = panel.get("_service")
	var scope: Dictionary = session.call("personal_tm_scope")
	var observed := {"completed": [], "submitted": {}, "error": ""}
	var completed := func(id: String, reply: Dictionary) -> void:
		var row: Dictionary = session.call("_owner_training_row")
		var intent: Dictionary = row.get("intent", {})
		if row.get("action") != "altar_spend" or intent.get("spend_id") != id \
				or intent.get("creature_uid") != uid or intent.get("payment_item") != "tether_candy" \
				or int(intent.get("expected_level", -1)) != int(chosen.level) \
				or service.call("_intent_valid", intent) != true: return
		# The host refreshes passive-care revision before freezing its first
		# submission. Observe that real intent; never reuse the displayed quote.
		if observed.submitted.is_empty(): observed.submitted = intent.duplicate(true)
		elif intent != observed.submitted:
			observed.error = "Altar completion changed its original submitted intent"
			return
		if session.call("personal_tm_scope") != scope:
			observed.error = "Altar payment changed its actual character/session scope"
		elif reply.get("resolved") == true and reply.get("ok") != true:
			observed.error = str(reply.get("reason", reply.get("code", "Altar payment refused")))
		elif reply.get("ok") == true and reply.get("resolved") == true \
				and reply.get("saved") == true and reply.get("durable") == true:
			var decision: Dictionary = session.call("_training_decision", session.call("local_peer_id"), row)
			if decision.get("ok") == true and decision.get("saved") == true and decision.get("durable") == true:
				observed.completed.append({"intent": intent.duplicate(true), "result": reply.duplicate(true)})
	service.connect("essence_spend_completed", completed)
	var started := Engine.get_physics_frames()
	await pilot.press("ui_accept")
	while captain_within_deadline(Engine.get_physics_frames() - started) \
			and observed.completed.is_empty() and str(observed.error).is_empty():
		await _tree.physics_frame
	service.disconnect("essence_spend_completed", completed)
	if not str(observed.error).is_empty() or observed.completed.size() != 1:
		return _fail("The chosen Altar tap lacks one actual saved payment: " + str(observed))
	var claim: Dictionary = observed.completed[0]
	var spend_id := str(claim.intent.get("spend_id", ""))
	var receipt := "essence_spend:%s:%s:%s:%d:tether_candy:1:%d" % [str(before.character_id), spend_id,
		uid, int(chosen.level), int(observed.submitted.expected_character_revision)]
	var after: Dictionary = session.call("homestead_personal_view")
	personal = after.get("redesign_character", {})
	if spend_id.length() != 32 or not spend_id.is_valid_hex_number(false) or claim.result.get("receipt") != receipt \
			or personal.get("transaction_receipts", []).count(receipt) != 1 or _count("tether_candy") != candy_before - 1 \
			or not retained_five(_initial_ids, _party_ids()) or after.get("party", []).size() != cards.size() \
			or not str(panel.get("_pending_id")).is_empty():
		return _fail("Chosen Altar growth lacks its exact Candy debit and once-only saved receipt")
	for index in cards.size():
		var old: Dictionary = cards[index]
		var actual: Dictionary = after.party[index]
		var member_uid := str(old.uid)
		var expected_level := int(old.level) + (1 if member_uid == uid else 0)
		var expected_xp := 0 if member_uid == uid else int(old.get("xp", 0))
		if actual.get("uid") != member_uid or actual.get("species_id") != old.get("species_id") \
				or int(actual.get("level", -1)) != expected_level or int(actual.get("xp", -1)) != expected_xp \
				or ESSENCE.creature_cap(personal, member_uid) != caps[member_uid]:
			return _fail("Altar payment altered identity/species/caps or an unchosen creature's level/XP")
	_receipt("first_breakthrough_chosen_level", {"station_key": key, "quote": quote,
		"completion": claim, "candy_before": candy_before, "candy_after": _count("tether_candy"),
		"chosen_uid": uid, "level_before": chosen.level, "level_after": int(chosen.level) + 1,
		"other_levels_unchanged": true, "caps_unchanged": true, "controller_payment_tap": true})
	await pilot.press("menu_cancel")
	return true if not panel.call("is_open") and INPUT_OWNER.current(_tree) == null \
		else _fail("The saved Altar payment did not return ordinary world input")


func _altar_focus(panel: Node, key: String, action: String, pilot: RefCounted) -> bool:
	for step in 20:
		if panel.call("is_open") != true or INPUT_OWNER.current(_tree) != panel:
			return _fail("Altar selection lost its actual input owner")
		var focus: Control = panel.get_viewport().gui_get_focus_owner()
		if focus is Button and panel.is_ancestor_of(focus) and str(focus.get_meta("altar_focus_key", "")) == key:
			return true if not focus.disabled else _fail("The actual Altar row is disabled: " + key)
		await pilot.press(action)
	return _fail("Physical Altar navigation did not select the requested row: " + key)


func _breakthrough_focus(panel: Node, label: String, pilot: RefCounted) -> bool:
	var buttons: Array[Button] = []
	for child: Node in panel.get("_list").get_children():
		if child is Button: buttons.append(child)
	for step in buttons.size() * 2:
		if panel.call("is_open") != true or INPUT_OWNER.current(_tree) != panel:
			return _fail("Learned-feast focus lost the real chooser owner")
		var focus: Control = panel.get_viewport().gui_get_focus_owner()
		if focus is Button and buttons.has(focus) and focus.text == label:
			return true if not focus.disabled else _fail("The actual learned-feast row is disabled")
		await pilot.press("ui_down")
	return _fail("Physical d-pad input did not reach the learned-feast row: " + label)


func _station_focus(panel: Node, key: String, pilot: RefCounted) -> bool:
	var buttons: Array = panel.get("_station_buttons")
	var rows: Array = panel.get("_rows")
	for step in (buttons.size() + rows.size()) * 2:
		if panel.call("is_open") != true or INPUT_OWNER.current(_tree) != panel:
			return _fail("Station focus lost its actual panel owner")
		var focus: Control = panel.get_viewport().gui_get_focus_owner()
		if focus is Button and buttons.has(focus) and str(focus.get_meta("station_focus_key", "")) == key:
			return true if not focus.disabled else _fail("The actual station row is disabled: " + key)
		await pilot.press("ui_down")
	return _fail("Physical d-pad input did not reach the station row: " + key)


func _walk_marker(id: String, budget: int) -> bool:
	if not bool(_hold.call("has_marker", id)):
		return _fail("The actual Hall route marker is missing: " + id)
	return await _walk(_hold.call("marker", id), 0.6, budget)


func _fight_named(body: Node3D, id: String) -> bool:
	_captain_spec = TRAINERS.trainer(id)
	var flag := str(_captain_spec.get("defeat_flag", ""))
	if _captain_spec.is_empty() or flag.is_empty() or _has(flag) or not await _prepare_for_trainer():
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
	if not _bind_xp_window(before_xp):
		return false
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
	# A row's `victory_conversation` (the captains' Sigil handover, F04#6) opens
	# a deferred frame after the win; it is read through with Interact at a
	# reader's pace (one line per VICTORY_READ_FRAMES) before world input is
	# expected back.
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

extends "res://tools/net/peer_runner.gd"

## Stormwood F11 peer process: the shared net-harness peer
## (`tools/net/peer_runner.gd`, unchanged) plus the few Stormheart arms the
## live two-peer offers smoke needs. Every arm below drives shipping objects:
## the Dynamo's own fighter admission and completion, the ending's own offer
## Interactable, the real DialoguePanel (Yes is the runner's confirm, No is a
## real `menu_cancel` press), the real Team tab release ceremony handlers and
## the ending's own Waterward view/gate Interactables. What this file supplies
## instead of a controller is only which prompt was chosen; see each arm.
##
## Launched only by `tests/smoke_net_stormwood_stormheart_offers.gd`, which
## overrides the harness spawner to point here instead of the shared runner.

const SH_ENDING := preload("res://scripts/world/stormwood_ending.gd")
const SH_WATER_GATE := preload("res://scripts/world/stormwood_water_gate.gd")

## Every Stormwood ending event this process's Session delivered, by kind.
var _sh_events: Dictionary = {}
var _sh_offer_uids: Array = []
var _sh_listening := false
var _sh_messages: Array = []
## The largest party this process has held since the last counter reset,
## sampled every physics frame: a sixth creature at any frame would show here.
var _sh_max_party := 0


func _on_physics_frame() -> void:
	super._on_physics_frame()
	var game := root.get_node_or_null(^"Game")
	var party: Variant = game.get("party") if game != null else null
	if party is RefCounted:
		_sh_max_party = maxi(_sh_max_party, int((party as RefCounted).call("size")))


func _execute_step(msg: Dictionary) -> Dictionary:
	_sh_listen()
	var action := str(msg.get("action", ""))
	var args: Dictionary = (msg.get("args", {}) as Dictionary)
	var before := _physics_count
	var out: Dictionary
	match action:
		"sh_stage_dynamo":
			out = await _sh_stage_dynamo(args)
		"sh_go":
			out = await _sh_go(args)
		"sh_offer":
			out = await _sh_offer(args)
		"sh_answer":
			out = await _sh_answer(args)
		"sh_ceremony":
			out = await _sh_ceremony(args)
		"sh_intent":
			out = await _sh_intent(args)
		"sh_prompt":
			out = await _sh_prompt(args)
		"sh_production_load":
			out = await _sh_production_load(args)
		"sh_reset_offer_counters":
			_sh_events.clear()
			_sh_offer_uids.clear()
			_sh_messages.clear()
			_sh_max_party = 0
			out = {"verdict": "PASS", "detail": "offer counters cleared"}
		"sh_shrine":
			out = await _sh_shrine(args)
		"sh_drain":
			out = await _sh_drain(args)
		_:
			return await super._execute_step(msg)
	out["frames_used"] = _physics_count - before
	return out


func _execute_probe(msg: Dictionary) -> Variant:
	_sh_listen()
	match str(msg.get("what", "")):
		"sh_state":
			return _sh_state()
		"sh_expr":
			return _sh_expr(str((msg.get("args", {}) as Dictionary).get("expr", "")))
	return await super._execute_probe(msg)


func _sh_listen() -> void:
	if _sh_listening:
		return
	var sess := _session()
	if sess == null or not sess.has_signal("stormwood_encounter_message"):
		return
	_sh_listening = true
	sess.connect("stormwood_encounter_message", func(event: Dictionary) -> void:
		var kind := str(event.get("kind", ""))
		if not kind.begins_with("ending_"):
			return
		_sh_events[kind] = int(_sh_events.get(kind, 0)) + 1
		if kind == "ending_offer":
			var claim: Variant = event.get("claim", {})
			if claim is Dictionary:
				_sh_offer_uids.append(SH_ENDING.claim_id(claim as Dictionary))
		elif kind == "ending_refused":
			_sh_messages.append(str(event.get("reason", ""))))


## Exploration only: evaluate one expression against this runner.
func _sh_expr(text: String) -> Variant:
	var expression := Expression.new()
	if expression.parse(text, ["game", "scene"]) != OK:
		return "parse error: " + expression.get_error_text()
	var value: Variant = expression.execute([root.get_node_or_null(^"Game"), current_scene], self)
	if expression.has_execute_failed():
		return "execute failed: " + expression.get_error_text()
	return var_to_str(value) if typeof(value) in [TYPE_OBJECT, TYPE_VECTOR3, TYPE_VECTOR2] else value


func _sh_game() -> Node:
	return root.get_node_or_null(^"Game")


func _sh_world() -> Node:
	var scene := current_scene
	return scene if scene != null and scene.get_node_or_null(^"StormwoodEnding") != null else null


func _sh_ending() -> Node:
	var world := _sh_world()
	return world.get_node_or_null(^"StormwoodEnding") if world != null else null


## This peer's own view of the Stormheart, the world facts and its character.
func _sh_state() -> Dictionary:
	var game := _sh_game()
	var out := {"realm": str(game.get("current_realm")) if game != null else ""}
	if game == null:
		return out
	var local: Variant = game.get("local")
	out["character_id"] = str((local as Object).get("character_id")) if local is Object else ""
	var party: RefCounted = game.get("party")
	var members: Array = []
	var hearts: Array = []
	for creature: RefCounted in (party.call("members") if party != null else []):
		var row := {"species": str(creature.get("species_id")), "uid": str(creature.get("uid")),
			"level": int(creature.get("level"))}
		members.append(row)
		if row.species == SH_ENDING.LEGENDARY_SPECIES:
			hearts.append(row.uid)
	out["party"] = members
	out["party_size"] = members.size()
	out["stormheart_uids"] = hearts
	var pending: Variant = game.get("pending_catch")
	out["pending_catch"] = {"species": str((pending as Object).get("species_id")),
		"uid": str((pending as Object).get("uid"))} if pending is Object else {}
	var player_flags: RefCounted = game.call("player_flags")
	var answers: Array = []
	for id: Variant in (player_flags.call("all_set") if player_flags != null and player_flags.has_method("all_set") else []):
		if str(id).begins_with(SH_ENDING.ANSWER_PREFIX):
			answers.append(str(id))
	answers.sort()
	out["answers"] = answers
	out["accepted_flag"] = player_flags != null and bool(player_flags.call("has", SH_ENDING.ACCEPTED_FLAG))
	out["receipt_flag"] = player_flags != null and bool(player_flags.call("has", SH_ENDING.PERSONAL_RECEIPT_FLAG))
	var progression: RefCounted = game.get("progression")
	var world_flags := {}
	var resolutions: Array = []
	for flag: String in ["stormwood:marrow_defeated", "stormwood:legendary_freed",
			"stormwood:legendary_offer_made", "stormwood:long_storm_ended",
			"realm_heart_stormwood_earned", "stormwood:waterward_revealed", "realm_key_water",
			"realm_gate_water_unlocked", "waterward_route_revealed", "stormwood:chapter_complete"]:
		world_flags[flag] = progression != null and bool(progression.call("has", flag))
	var world_store: RefCounted = game.call("world_flags")
	if world_store != null and world_store.has_method("all_set"):
		for id: Variant in world_store.call("all_set"):
			if str(id).begins_with(SH_ENDING.RESOLUTION_PREFIX):
				resolutions.append(str(id))
	resolutions.sort()
	out["world_flags"] = world_flags
	out["resolutions"] = resolutions
	var environment: Dictionary = game.get("realm_environment")
	var stormwood: Variant = environment.get("stormwood", {})
	var ending_saved: Dictionary = {}
	if stormwood is Dictionary and (stormwood as Dictionary).get("ending", {}) is Dictionary:
		ending_saved = SH_ENDING.migrate_state((stormwood as Dictionary).get("ending", {}))
	var claims := {}
	for character: Variant in (ending_saved.get("claims", {}) as Dictionary):
		var claim: Dictionary = (ending_saved.get("claims", {}) as Dictionary)[character]
		claims[str(character)] = {"uid": SH_ENDING.claim_id(claim),
			"settled": bool(claim.get("settled", false)), "kept": bool(claim.get("kept", false))}
	out["claims"] = claims
	out["participants"] = (ending_saved.get("participants", []) as Array).duplicate()
	var ending := _sh_ending()
	if ending != null:
		var local_claim: Dictionary = ending.get("_local_claim")
		out["local_claim"] = SH_ENDING.claim_id(local_claim)
		out["waiting_for_dialogue"] = bool(ending.get("_waiting_for_offer_dialogue"))
		var prompt: Node = ending.get_node_or_null(^"StormheartOffer")
		out["offer_prompt_enabled"] = prompt != null and bool(prompt.get("enabled"))
		var legendary: Node3D = ending.get("_legendary")
		out["captive_visible"] = legendary != null and legendary.visible
		var cage: Node3D = ending.get("_cage")
		out["cage_visible"] = cage != null and cage.visible
		var sea: Node3D = ending.get("_waterward_sea")
		out["waterward_sea_visible"] = sea != null and sea.visible
	var world := _sh_world()
	var panel: Node = world.get_node_or_null(^"DialoguePanel") if world != null else null
	out["panel_open"] = panel != null and bool(panel.call("is_open"))
	out["panel_conversation"] = str(panel.call("runner").call("conversation_id")) \
		if panel != null and bool(panel.call("is_open")) else ""
	var actors := {}
	var lightning: Node = world.get_node_or_null(^"StormwoodLightning") if world != null else null
	var offer_at: Node3D = ending.get_node_or_null(^"StormheartOffer") as Node3D if ending != null else null
	if lightning != null and offer_at != null:
		var seen: Dictionary = lightning.call("_actors")
		for peer: Variant in seen:
			var actor := seen[peer] as Node3D
			if is_instance_valid(actor):
				actors[str(peer)] = snappedf(actor.global_position.distance_to(offer_at.global_position), 0.01)
	out["actor_offer_distance"] = actors
	var remotes: Array = []
	for remote: Node in get_nodes_in_group("remote_trainer"):
		var gp: Vector3 = (remote as Node3D).global_position
		var np: Vector3 = remote.get("net_position")
		remotes.append({"peer": int(remote.get("peer_id")), "realm": str(remote.get("net_realm")),
			"path": str(remote.get_path()), "net": [snappedf(np.x, 0.1), snappedf(np.y, 0.1), snappedf(np.z, 0.1)],
			"at": [snappedf(gp.x, 0.1), snappedf(gp.y, 0.1), snappedf(gp.z, 0.1)]})
	out["remote_trainers"] = remotes
	var gate: Node = world.get_node_or_null(^"WaterwardRealmGate") if world != null else null
	out["water_gate_state"] = str(gate.call("current_state")) if gate != null and gate.has_method("current_state") else ""
	var realm_hearts: RefCounted = game.get("realm_hearts")
	out["spark_earned"] = realm_hearts != null and bool(realm_hearts.call("is_earned", "stormwood", progression))
	out["spark_placed"] = realm_hearts != null and bool(realm_hearts.call("is_placed", "stormwood", progression))
	var shrine := _sh_spark_slot()
	out["spark_shrine_state"] = str(shrine.call("current_state")) if shrine != null else ""
	out["max_party_seen"] = _sh_max_party
	out["events"] = _sh_events.duplicate()
	out["offer_uids"] = _sh_offer_uids.duplicate()
	out["refusals"] = _sh_messages.duplicate()
	var player := _probe.call("player") as Node3D
	out["position"] = [player.global_position.x, player.global_position.y, player.global_position.z] \
		if player != null else []
	var sess := _session()
	out["peer_id"] = int(sess.call("local_peer_id")) if sess != null else 0
	out["session_active"] = sess != null and bool(sess.call("is_active"))
	var saver: RefCounted = game.get("save_system")
	var world_state: RefCounted = game.get("world")
	out["world_id"] = str(world_state.get("world_id")) if world_state != null else ""
	var characters: RefCounted = saver.call("characters") if saver != null else null
	out["character_on_disk"] = characters != null and not str(out.character_id).is_empty() \
		and bool(characters.call("has", str(out.character_id)))
	return out


## Host only. Staged at the fourth conduit (disclosed in the smoke header):
## each named peer is admitted as a captain-fight fighter through the Dynamo's
## own `_add_participant()` (which records its stable character id from the
## live registry), the Break is marked complete, and the Dynamo's own
## `_complete_marrow()` commits Marrow through the real chapter event. The
## ending's own `_process()` then records participants and releases.
func _sh_stage_dynamo(args: Dictionary) -> Dictionary:
	var world := _sh_world()
	var dynamo: Node = world.get_node_or_null(^"StormwoodDynamo") if world != null else null
	if dynamo == null:
		return {"verdict": "ERROR", "detail": "no StormwoodDynamo in the current scene"}
	for peer: Variant in args.get("peers", []):
		dynamo.call("_add_participant", int(peer))
	var rules: RefCounted = dynamo.get("rules")
	rules.set("phase", "released")
	dynamo.set("phase", "released")
	dynamo.call("_persist_state")
	dynamo.call("_complete_marrow")
	var game := _sh_game()
	var progression: RefCounted = game.get("progression")
	for _i in 600:
		await physics_frame
		if bool(progression.call("has", SH_ENDING.FREED_FLAG)):
			break
	var state := _sh_state()
	var freed := bool(progression.call("has", SH_ENDING.FREED_FLAG))
	return {"verdict": "PASS" if freed else "FAIL", "data": state,
		"detail": "fighters=%s freed=%s participants=%s" % [str(dynamo.get("fighter_characters")),
			str(freed), str(state.get("participants", []))]}


## Stand this trainer beside one of the ending's prompts (StormheartOffer,
## WaterwardView) or the Waterward gate, then settle on the real collision.
func _sh_go(args: Dictionary) -> Dictionary:
	var world := _sh_world()
	var ending := _sh_ending()
	var player := _probe.call("player") as CharacterBody3D
	if world == null or ending == null or player == null:
		return {"verdict": "ERROR", "detail": "no Stormwood ending/player here"}
	var target_name := str(args.get("target", "StormheartOffer"))
	var target: Node3D
	if target_name == "WaterwardRealmGate":
		var gate := world.get_node_or_null(^"WaterwardRealmGate") as Node3D
		target = gate.get_node_or_null(^"Interactable") as Node3D if gate != null else null
	else:
		target = ending.get_node_or_null(NodePath(target_name)) as Node3D
	if target == null:
		return {"verdict": "ERROR", "detail": "no target '%s'" % target_name}
	var offset: Array = args.get("offset", [0.0, 0.0, 2.0]) as Array
	var at := target.global_position + Vector3(float(offset[0]), float(offset[1]), float(offset[2]))
	player.global_position = at + Vector3(0.0, 0.6, 0.0)
	player.velocity = Vector3.ZERO
	for _i in int(args.get("settle", 90)):
		await physics_frame
	var distance := player.global_position.distance_to(target.global_position)
	return {"verdict": "PASS" if distance <= float(args.get("within", 6.0)) else "FAIL",
		"data": {"distance": distance, "on_floor": player.is_on_floor(),
			"position": [player.global_position.x, player.global_position.y, player.global_position.z]},
		"detail": "at %s, %.2f m from %s (on_floor=%s)" % [str(player.global_position), distance,
			target_name, str(player.is_on_floor())]}


## Activate the ending's own offer Interactable (what the arbiter's Interact
## does), then report what the host answered: an offer (dialogue opens) or a
## refusal.
func _sh_offer(args: Dictionary) -> Dictionary:
	var ending := _sh_ending()
	var prompt: Node = ending.get_node_or_null(^"StormheartOffer") if ending != null else null
	if prompt == null:
		return {"verdict": "ERROR", "detail": "no StormheartOffer prompt"}
	var offers_before := int(_sh_events.get("ending_offer", 0))
	var refusals_before := _sh_messages.size()
	prompt.call("interaction_activate")
	var state := {}
	for _i in int(args.get("wait", 240)):
		await physics_frame
		state = _sh_state()
		if bool(state.get("panel_open", false)) and str(state.get("panel_conversation", "")) == SH_ENDING.OFFER_CONVERSATION:
			break
		if _sh_messages.size() > refusals_before and not bool(args.get("expect_offer", true)):
			break
	state = _sh_state()
	var opened := bool(state.get("panel_open", false)) and str(state.get("panel_conversation", "")) == SH_ENDING.OFFER_CONVERSATION
	var refused := _sh_messages.size() > refusals_before
	var expect_offer := bool(args.get("expect_offer", true))
	var ok := opened if expect_offer else (refused and not opened)
	return {"verdict": "PASS" if ok else "FAIL", "data": state,
		"detail": "offer dialogue open=%s, offers +%d, refusal=%s" % [str(opened),
			int(_sh_events.get("ending_offer", 0)) - offers_before,
			_sh_messages.back() if refused else "none"]}


## Answer the open Stormheart offer through the real DialoguePanel: advance to
## its Yes/No line, then Yes (the runner's confirm, what Interact does on that
## line) or No (a real `menu_cancel` press read by the panel's own tick).
func _sh_answer(args: Dictionary) -> Dictionary:
	var world := _sh_world()
	var panel: Node = world.get_node_or_null(^"DialoguePanel") if world != null else null
	if panel == null or not bool(panel.call("is_open")) \
			or str(panel.call("runner").call("conversation_id")) != SH_ENDING.OFFER_CONVERSATION:
		return {"verdict": "FAIL", "detail": "the Stormheart offer is not open on this peer"}
	var runner: RefCounted = panel.call("runner")
	var reached := false
	for _i in 12:
		if bool((runner.call("line") as Dictionary).get("confirmation", false)):
			reached = true
			break
		runner.call("advance")
		await process_frame
	if not reached:
		return {"verdict": "FAIL", "detail": "the offer never reached its Yes/No line"}
	if bool(args.get("accept", true)):
		runner.call("advance")
	else:
		await _sh_tap("menu_cancel")
	for _i in int(args.get("settle", 60)):
		await physics_frame
	var state := _sh_state()
	return {"verdict": "PASS", "data": state,
		"detail": "answered %s; party=%d pending=%s answers=%s" % ["Yes" if bool(args.get("accept", true)) else "No",
			int(state.party_size), str(state.pending_catch), str(state.answers)]}


func _sh_tap(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	await physics_frame
	await physics_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await physics_frame


## The five-slot ceremony a Yes at five opens (Game opens the Team tab on
## `pending_catch`). `release` is the extended row the player lets go: 0-4 a
## belt member (the Stormheart takes that holder), 5 the newcomer itself. The
## tab's own row handler, its "Let them go" and "Back to belt" Buttons run.
func _sh_ceremony(args: Dictionary) -> Dictionary:
	var game := _sh_game()
	var menu: Node = game.call("menu") if game != null else null
	if menu == null or game.get("pending_catch") == null:
		return {"verdict": "FAIL", "detail": "no pending newcomer/menu for a ceremony"}
	var tab: Node
	for index in (menu.get("_tabs") as Array).size():
		if str((menu.get("_tabs")[index] as Dictionary).get("id", "")) == "creatures":
			tab = menu.get("_bodies")[index]
	if tab == null:
		return {"verdict": "ERROR", "detail": "no creatures tab"}
	for _i in 180:
		if bool(menu.call("is_open")) and str(tab.get("_release_stage")) == "choose":
			break
		await process_frame
	if str(tab.get("_release_stage")) != "choose":
		return {"verdict": "FAIL", "detail": "the release ceremony never reached its choice (stage '%s', open=%s)"
			% [str(tab.get("_release_stage")), str(menu.call("is_open"))]}
	var before := _sh_state()
	var release := int(args.get("release", 5))
	tab.call("_begin_farewell", release)
	if str(tab.get("_release_stage")) != "confirm":
		return {"verdict": "FAIL", "detail": "farewell did not open for row %d" % release}
	var mid_size := int((game.get("party") as RefCounted).call("size"))
	(tab.get("_farewell_release") as Button).pressed.emit()
	await process_frame
	(tab.get("_farewell_done") as Button).pressed.emit()
	await process_frame
	menu.call("close")
	for _i in int(args.get("settle", 120)):
		await physics_frame
	var after := _sh_state()
	return {"verdict": "PASS", "data": {"before": before, "after": after, "size_during": mid_size},
		"detail": "released row %d; party %d -> %d (never above %d); stormhearts=%s" % [release,
			int(before.party_size), int(after.party_size), mid_size, str(after.stormheart_uids)]}


## Send one raw Stormwood ending intent (a replayed or duplicated submit) the
## way the ending's own client code does, through Session.
func _sh_intent(args: Dictionary) -> Dictionary:
	var sess := _session()
	var intent: Dictionary = (args.get("intent", {}) as Dictionary).duplicate(true)
	var times := maxi(1, int(args.get("times", 1)))
	for _i in times:
		sess.call("request_stormwood_encounter", intent)
	for _i in int(args.get("settle", 90)):
		await physics_frame
	return {"verdict": "PASS", "data": _sh_state(),
		"detail": "sent %s x%d" % [str(intent.get("kind", "")), times]}


## Activate the ending's WaterwardView or the Waterward gate's Interactable
## (the same `interaction_activate` the arbiter's Interact calls).
func _sh_prompt(args: Dictionary) -> Dictionary:
	var world := _sh_world()
	var ending := _sh_ending()
	if world == null or ending == null:
		return {"verdict": "ERROR", "detail": "no Stormwood ending here"}
	var target_name := str(args.get("target", "WaterwardView"))
	var prompt: Node
	if target_name == "WaterwardRealmGate":
		var gate := world.get_node_or_null(^"WaterwardRealmGate")
		prompt = gate.get_node_or_null(^"Interactable") if gate != null else null
	else:
		prompt = ending.get_node_or_null(NodePath(target_name))
	if prompt == null:
		return {"verdict": "ERROR", "detail": "no prompt '%s'" % target_name}
	var enabled := bool(prompt.get("enabled"))
	prompt.call("interaction_activate")
	var wait := int(args.get("settle", 120))
	var game := _sh_game()
	for _i in wait:
		await physics_frame
		if str(args.get("until_realm", "")) != "" and str(game.get("current_realm")) == str(args.until_realm) \
				and current_scene != null and current_scene != world:
			break
	var panel: Node = current_scene.get_node_or_null(^"DialoguePanel") if current_scene != null else null
	if panel != null and bool(panel.call("is_open")):
		panel.call("close")
	return {"verdict": "PASS", "data": {"enabled_before": enabled, "realm": str(game.get("current_realm")),
		"scene": current_scene.name if current_scene != null else ""},
		"detail": "activated %s (enabled=%s); realm now %s scene %s" % [target_name, str(enabled),
			str(game.get("current_realm")), current_scene.name if current_scene != null else "none"]}


## A restarted host: the real title screen's Load of the autosave slot, which
## runs `Game.load_game()` and its ordinary `_enter_world()` (hosting the
## session on the harness-assigned port and changing to the saved realm's
## scene). The runner must have booted `--scene=title`.
func _sh_production_load(args: Dictionary) -> Dictionary:
	var game := _sh_game()
	var sess := _session()
	var title := current_scene
	if game == null or sess == null or title == null or not title.is_in_group(&"title_screen"):
		return {"verdict": "FAIL", "detail": "production load needs the real title screen"}
	var slot := int(args.get("slot", int(game.call("autosave_slot"))))
	if not bool(game.call("has_save", slot)):
		return {"verdict": "FAIL", "detail": "no save in slot %d on disk" % slot}
	title.set("_host_port", int(args.get("port", _enet_port)))
	title.call("_load_slot", slot)
	for i in int(args.get("budget_frames", 6000)):
		await physics_frame
		var scene := current_scene
		if bool(sess.call("is_active")) and bool(sess.call("is_host")) and scene != null \
				and not scene.is_in_group(&"title_screen") \
				and (not scene.has_method("shell_build_complete") or bool(scene.call("shell_build_complete"))):
			for _j in int(args.get("settle", DEFAULT_SETTLE_FRAMES)):
				await physics_frame
			_scene_name = "stormwood" if scene.name == "Stormwood" else "world"
			return {"verdict": "PASS", "data": _sh_state(),
				"detail": "title Load slot %d entered /root/%s, hosting, after %d frames" % [slot, scene.name, i]}
	return {"verdict": "FAIL", "detail": "title Load slot %d never reached a hosted world" % slot}


## The Spark's socket in the Meadows home circle, when this peer stands in
## Meadows: the only production Spark shrine (`playground_world.gd` builds the
## four-relic circle; Stormwood's own masonry shrine is not placed in a world).
func _sh_spark_slot() -> Node:
	var scene := current_scene
	if scene == null:
		return null
	return scene.get_node_or_null(^"MeadowsRealmHeartShrine/RelicSlot_stormwood")


## Stand at the Spark socket and use its own Interactable (Place the Spark).
func _sh_shrine(args: Dictionary) -> Dictionary:
	var slot := _sh_spark_slot() as Node3D
	var player := _probe.call("player") as CharacterBody3D
	if slot == null or player == null:
		return {"verdict": "FAIL", "detail": "no Spark socket/player in this scene"}
	player.global_position = slot.global_position + Vector3(0.0, 0.8, 1.6)
	player.velocity = Vector3.ZERO
	for _i in 60:
		await physics_frame
	var before := str(slot.call("current_state"))
	var prompt: Node = null
	for child: Node in slot.get_children():
		if child.has_method("interaction_activate"):
			prompt = child
	if prompt == null:
		return {"verdict": "FAIL", "detail": "the Spark socket has no Interactable"}
	if bool(args.get("activate", true)):
		prompt.call("interaction_activate")
	for _i in int(args.get("settle", 120)):
		await physics_frame
	var after := str(slot.call("current_state"))
	return {"verdict": "PASS", "data": {"before": before, "after": after},
		"detail": "Spark socket %s -> %s" % [before, after]}


## Read an open conversation (the freeing's release lines) through to its
## end, as Interact on each line does, so the offer can take the panel.
func _sh_drain(args: Dictionary) -> Dictionary:
	var wanted := str(args.get("conversation", ""))
	for _i in int(args.get("wait", 240)):
		var world := _sh_world()
		var panel: Node = world.get_node_or_null(^"DialoguePanel") if world != null else null
		if panel != null and bool(panel.call("is_open")):
			break
		await physics_frame
	var world2 := _sh_world()
	var panel2: Node = world2.get_node_or_null(^"DialoguePanel") if world2 != null else null
	if panel2 == null or not bool(panel2.call("is_open")):
		return {"verdict": "FAIL", "detail": "no conversation opened to drain"}
	var runner: RefCounted = panel2.call("runner")
	var id := str(runner.call("conversation_id"))
	if not wanted.is_empty() and id != wanted:
		return {"verdict": "FAIL", "detail": "open conversation is '%s', not '%s'" % [id, wanted]}
	var lines := 0
	while bool(panel2.call("is_open")) and str(runner.call("conversation_id")) == id and lines < 64:
		runner.call("advance")
		lines += 1
		await process_frame
	for _i in 10:
		await physics_frame
	return {"verdict": "PASS" if lines < 64 else "FAIL", "detail": "read '%s' through %d lines" % [id, lines]}

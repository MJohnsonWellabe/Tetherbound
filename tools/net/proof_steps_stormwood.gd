extends RefCounted

## Stormwood peer-side steps for the two-peer proof command
## (`tools/net/run_two_peer_proof.sh`), handed over by `proof_peer_runner.gd`
## beside the shared `proof_steps.gd`. Kept in their own file so the Stormwood
## lane's F11#3 steps never collide with other lanes' edits there.
## `proof_peer_runner.gd` dispatches these; the F11#3 scenario also uses the
## coordinator's own `restart_peer` and `hashes_agree` (tests/smoke_net_proof_two_peer.gd).
##
##   title_load      {slot?, budget_frames?, settle?}   the title screen's own Load
##                                        of a slot already on this peer's disk
##                                        (`title_screen.gd::_load_slot` ->
##                                        `Game.load_game` -> `_enter_world`, which
##                                        hosts): what a player does after quitting
##                                        and restarting the game
##   aftermath_state {require?, watch_frames?}   read-only: this peer's view of the
##                                        Long Storm aftermath, the Spark of the
##                                        Stormwood (earned/placed world facts, this
##                                        character's own active relic, the Meadows
##                                        socket when it stands in the Meadows), the
##                                        Waterward gate/key and the Stormheart
##                                        receipts. `require` is a subset of `data`
##                                        that must hold or the step FAILS (so a
##                                        negative control can expect FAIL).
##                                        `watch_frames` watches strike warnings
##                                        reaching this peer for that long.
##   spark_socket    {press?, settle?}    stand where the Meadows home circle's Spark
##                                        socket (RelicSlot_stormwood) offers its
##                                        prompt; with `press` true press interact
##                                        once through the peer runner's own input
##                                        edge. Reports the socket state before/after.
##
## Nothing here writes game state: the load, the press and every grant go
## through the game's own code.

const ACTIONS := ["title_load", "aftermath_state", "spark_socket"]
const ENDING_PATH := "res://scripts/world/stormwood_ending.gd"
const SURGE_PATH := "res://scripts/world/stormwood_surge.gd"
const SPARK_ID := "stormwood"
const SPARK_SLOT_PATH := ^"MeadowsRealmHeartShrine/RelicSlot_stormwood"
const LEGENDARY_SPECIES := "fulgocobra"
const WORLD_FACTS := ["stormwood:long_storm_ended", "stormwood:legendary_freed",
	"stormwood:legendary_offer_made", "realm_heart_stormwood_earned", "realm_heart_stormwood_placed",
	"stormwood:waterward_revealed", "realm_gate_water_unlocked", "realm_key_water"]


static func handles(action: String) -> bool:
	return ACTIONS.has(action)


static func run(tree: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"title_load":
			return await _title_load(tree, args)
		"aftermath_state":
			return await _aftermath_state(tree, args)
		"spark_socket":
			return await _spark_socket(tree, args)
	return {"verdict": "ERROR", "detail": "proof_steps_stormwood: unknown action '%s'" % action}


static func _game(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null(^"Game")


# --- the restarted process's Load ----------------------------------------------------

static func _title_load(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	var sess: Node = tree.call("_session")
	var title := tree.current_scene
	if game == null or sess == null or title == null or not title.is_in_group(&"title_screen"):
		return {"verdict": "FAIL", "detail": "title_load needs the real title screen (current scene %s)"
			% (str(title.name) if title != null else "none")}
	var slot := int(args.get("slot", int(game.call("autosave_slot"))))
	if not bool(game.call("has_save", slot)):
		return {"verdict": "FAIL", "detail": "no save in slot %d on this peer's disk" % slot}
	title.set("_host_port", int(tree.get("_enet_port")))
	title.call("_load_slot", slot)
	var budget := int(args.get("budget_frames", 10000))
	for i in budget:
		await tree.physics_frame
		var scene := tree.current_scene
		if bool(sess.call("is_active")) and bool(sess.call("is_host")) and scene != null \
				and not scene.is_in_group(&"title_screen") \
				and (not scene.has_method("shell_build_complete") or bool(scene.call("shell_build_complete"))):
			for _j in int(args.get("settle", 120)):
				await tree.physics_frame
			var realm := str(game.get("current_realm"))
			tree.set("_scene_name", "world" if realm == "meadows" else realm)
			var local: Variant = game.get("local")
			return {"verdict": "PASS",
				"detail": "title Load slot %d -> /root/%s (realm '%s'), hosting on port %d after %d frames"
					% [slot, scene.name, realm, int(tree.get("_enet_port")), i],
				"data": {"realm": realm, "hosting": true,
					"character_id": str((local as RefCounted).get("character_id")) if local != null else "",
					"world_id": str(game.get("world").get("world_id")) if game.get("world") != null else ""}}
	return {"verdict": "FAIL", "detail": "title Load slot %d never reached a hosted world in %d frames" % [slot, budget]}


# --- the aftermath, the Spark and the receipts, as this peer sees them --------------

static func _aftermath_state(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	if game == null or game.get("world") == null:
		return {"verdict": "ERROR", "detail": "no /root/Game world"}
	var sess: Node = tree.call("_session")
	var strikes: Array = []
	var watch := int(args.get("watch_frames", 0))
	if watch > 0 and sess != null and sess.has_signal("stormwood_strike_received"):
		var listener := func(event: Dictionary) -> void:
			strikes.append(str(event.get("kind", "")))
		sess.connect("stormwood_strike_received", listener)
		for _i in watch:
			await tree.physics_frame
		sess.disconnect("stormwood_strike_received", listener)
	var world_flags: RefCounted = game.get("world").get("flags")
	var set_ids: Array = world_flags.call("all_set") as Array
	var ending: Variant = load(ENDING_PATH)
	var data := {"realm": str(game.get("current_realm")),
		"character_id": _character_id(game)}
	for flag: String in WORLD_FACTS:
		data[flag] = set_ids.has(flag)
	data["long_storm_ended"] = bool(data["stormwood:long_storm_ended"])
	# Receipts: one world resolution per character, and this character's own
	# portable answer(s). A duplicate would show as a second row here.
	var resolutions: Array = []
	for id: Variant in set_ids:
		if str(id).begins_with(str(ending.RESOLUTION_PREFIX)):
			resolutions.append(str(id))
	resolutions.sort()
	data["world_resolutions"] = resolutions
	var answers: Array = []
	var player_flags: RefCounted = game.call("player_flags")
	if player_flags != null:
		for id: Variant in (player_flags.call("all_set") as Array):
			if str(id).begins_with(str(ending.ANSWER_PREFIX)):
				answers.append(str(id))
	answers.sort()
	data["own_answers"] = answers
	var stormhearts := 0
	var party: RefCounted = game.get("party")
	if party != null:
		for member: Variant in (party.call("members") as Array):
			if str((member as RefCounted).get("species_id")) == LEGENDARY_SPECIES:
				stormhearts += 1
	data["stormhearts_in_party"] = stormhearts
	# The Spark of the Stormwood: earned/placed are the world's, active is this
	# character's own (realm_heart_shrine.gd's split).
	var hearts: RefCounted = game.get("realm_hearts")
	var progression: RefCounted = game.get("progression")
	data["spark_earned"] = hearts != null and bool(hearts.call("is_earned", SPARK_ID, progression))
	data["spark_placed"] = hearts != null and bool(hearts.call("is_placed", SPARK_ID, progression))
	data["active_relic"] = str(hearts.call("active_id")) if hearts != null else ""
	var scene := tree.current_scene
	var slot := scene.get_node_or_null(SPARK_SLOT_PATH) if scene != null else null
	data["spark_socket"] = str(slot.call("current_state")) if slot != null else "(not in the Meadows)"
	# The Stormwood presentation, when this peer stands in Stormwood.
	var surge := scene.find_child("StormwoodSurge", true, false) if scene != null else null
	var player := (tree.get("_probe") as Object).call("player") as Node3D
	if surge != null and player != null and not bool(surge.get("world").get("simulation_only")):
		var info: Dictionary = surge.call("phase_info_at", player.global_position)
		var phase := str(info.get("phase", ""))
		var aftermath := bool(surge.get("_aftermath"))
		data["surge"] = {
			"presentation_key": str(surge.call("presentation_key")),
			"aftermath": aftermath,
			"phase": phase,
			"cycle_seconds": snappedf(float(info.get("cycle_seconds", 0.0)), 0.01),
			"flashes": bool((surge.call("presentation_for", phase, aftermath) as Dictionary).get("flashes", true)),
			"sky_lightning_visible": bool(surge.call("sky_lightning_visible")),
			"region": str(surge.call("region_at", player.global_position)),
		}
	else:
		data["surge"] = "(not in Stormwood)"
	var ending_node := scene.find_child("StormwoodEnding", true, false) if scene != null else null
	if ending_node != null:
		var view := ending_node.get("_view_prompt") as Node
		var cage := ending_node.get("_cage") as Node3D
		data["ending"] = {
			"view_label": str(view.get("label")) if view != null else "",
			"cage_visible": cage.visible if cage != null else false,
		}
	var panel: Node = scene.find_child("DialoguePanel", true, false) if scene != null else null
	var open := panel != null and bool(panel.call("is_open"))
	var runner: RefCounted = panel.call("runner") if open else null
	data["dialogue_open"] = open
	data["dialogue"] = str(runner.call("conversation_id")) if runner != null else ""
	if watch > 0:
		data["strike_events_seen"] = strikes.size()
		data["watched_frames"] = watch
	var env: Dictionary = game.get("realm_environment")
	var storm: Variant = env.get("stormwood", {})
	data["strike_serial"] = int((storm as Dictionary).get("strike_serial", 0)) if storm is Dictionary else 0
	# The realm-transition epoch each process stamps on a host move
	# (`realm_transition.gd`); reported so a stalled host crossing can be read.
	var transition: Node = sess.get("realm_transition") as Node if sess != null else null
	data["transition_epoch"] = int(transition.get("epoch")) if transition != null else -1
	var require: Dictionary = args.get("require", {}) as Dictionary
	var mismatched: Array = []
	for key: Variant in require.keys():
		if not _matches(require[key], data.get(key)):
			mismatched.append("%s: want %s, got %s" % [str(key), JSON.stringify(require[key]), JSON.stringify(data.get(key))])
	return {"verdict": "PASS" if mismatched.is_empty() else "FAIL",
		"detail": ("" if mismatched.is_empty() else "MISMATCH %s; " % "; ".join(mismatched)) + JSON.stringify(data),
		"data": data}


static func _matches(want: Variant, got: Variant) -> bool:
	if want is Dictionary:
		if not (got is Dictionary):
			return false
		for k: Variant in (want as Dictionary).keys():
			if not _matches((want as Dictionary)[k], (got as Dictionary).get(k)):
				return false
		return true
	if typeof(want) in [TYPE_INT, TYPE_FLOAT] and typeof(got) in [TYPE_INT, TYPE_FLOAT]:
		return is_equal_approx(float(want), float(got))
	return want == got


static func _character_id(game: Node) -> String:
	var local: Variant = game.get("local")
	return str((local as RefCounted).get("character_id")) if local != null else ""


# --- the Spark's socket in the Meadows home circle -----------------------------------

static func _spark_socket(tree: SceneTree, args: Dictionary) -> Dictionary:
	var scene := tree.current_scene
	var slot := scene.get_node_or_null(SPARK_SLOT_PATH) as Node3D if scene != null else null
	var player := (tree.get("_probe") as Object).call("player") as Node3D
	if slot == null or player == null:
		return {"verdict": "FAIL", "detail": "no Spark socket (%s) or player in this scene" % str(SPARK_SLOT_PATH)}
	var prompt: Node = slot.get("_prompt") as Node
	if prompt == null:
		return {"verdict": "FAIL", "detail": "the Spark socket has no Interactable"}
	# Stand where the socket's prompt is the one the interaction arbiter would
	# fire: another trainer standing at the socket offers its own prompt, and a
	# press there would go to that player instead.
	var arbiter := tree.get_first_node_in_group(&"interaction_arbiter")
	var standing := ""
	var winners: Array = []
	for offset: Vector3 in [Vector3(0, 0.6, 1.6), Vector3(1.2, 0.6, 1.2), Vector3(-1.2, 0.6, 1.2),
			Vector3(0, 0.8, 2.2), Vector3(1.6, 0.6, 0), Vector3(-1.6, 0.6, 0), Vector3(0, 0.6, -1.6)]:
		var at := slot.global_position + offset
		await tree.call("_step_teleport", {"at": [at.x, at.y, at.z], "settle": int(args.get("settle", 60))})
		if (prompt.call("interaction_offer", player.global_position) as Dictionary).is_empty():
			continue
		var winner: Variant = arbiter.call("winning_provider") if arbiter != null else prompt
		if winner == prompt:
			standing = str(offset)
			break
		winners.append(str((winner as Node).name) if winner is Node and is_instance_valid(winner) else str(winner))
	var before := str(slot.call("current_state"))
	var label := str(prompt.get("label"))
	if standing.is_empty():
		return {"verdict": "FAIL", "detail": "the Spark socket's prompt never won the interaction arbiter (state %s, label '%s'; won instead: %s)"
			% [before, label, str(winners)]}
	var pressed := ""
	if bool(args.get("press", false)):
		var press: Dictionary = await tree.call("_step_press", {"action": "interact"})
		pressed = "; press: %s" % str(press.get("detail", ""))
		if str(press.get("verdict", "")) != "PASS":
			return {"verdict": "FAIL", "detail": "standing %s, '%s' (%s)%s" % [standing, label, before, pressed]}
		for _i in int(args.get("after_frames", 120)):
			await tree.physics_frame
	var after := str(slot.call("current_state"))
	return {"verdict": "PASS",
		"detail": "standing %s at the Spark socket, prompt '%s'; state %s -> %s%s" % [standing, label, before, after, pressed],
		"data": {"before": before, "after": after, "label": label}}

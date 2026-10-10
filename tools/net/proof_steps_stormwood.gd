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
##                                        Stormwood (personal held/hung and active,
##                                        shared Shrine Room display), and Stormheart
##                                        receipts. `require` is a subset of `data`
##                                        that must hold or the step FAILS (so a
##                                        negative control can expect FAIL).
##                                        `watch_frames` watches strike warnings
##                                        reaching this peer for that long.
##   spark_socket    {press?, settle?}    stand where the Shrine Room Stormwood
##                                        pedestal offers its
##                                        prompt; with `press` true press interact
##                                        once through the peer runner's own input
##                                        edge. Reports the socket state before/after.
##
## Only spark_start supplies a disclosed initial entitlement; subsequent state writes go
## through the game's own code.

const ACTIONS := ["title_load", "aftermath_state", "spark_socket", "spark_start", "spark_power"]
const ENDING_PATH := "res://scripts/world/stormwood_ending.gd"
const SURGE_PATH := "res://scripts/world/stormwood_surge.gd"
const SPARK_ID := "stormwood"
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SPARK_RECIPES := ["forge_biome5", "kitchen_biome5", "altar_biome5", "den_biome5"]
const LEGENDARY_SPECIES := "fulgocobra"
const WORLD_FACTS := ["stormwood:long_storm_ended", "stormwood:legendary_freed",
	"stormwood:legendary_offer_made", "realm_heart_stormwood_earned", "realm_heart_stormwood_placed",
	"stormwood:waterward_revealed", "realm_gate_water_unlocked", "realm_key_water"]


static func handles(action: String) -> bool:
	return ACTIONS.has(action)


static func run(tree: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"spark_start":
			return _spark_start(tree, args)
		"spark_power":
			return await _spark_power(tree, args)
		"title_load":
			return await _title_load(tree, args)
		"aftermath_state":
			return await _aftermath_state(tree, args)
		"spark_socket":
			return await _spark_socket(tree, args)
	return {"verdict": "ERROR", "detail": "proof_steps_stormwood: unknown action '%s'" % action}


static func _game(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null(^"Game")


## Declared start entitlement only, before admission. The release, hang,
## selection, restart and rejoin remain production writes. Boss reward delivery
## is F19#2's separate witness; this fixture cannot certify that grant.
static func _spark_start(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	var session: Node = game.get("session") if game != null else null
	if args.get("disclosure") != "initial_personal_spark_entitlement_no_boss_grant_credit" \
		or session == null or session.call("is_active") == true:
		return {"verdict": "FAIL", "detail": "Spark start fixture requires declared isolated pre-admission character"}
	var personal: Dictionary = game.local.redesign_character.duplicate(true)
	if personal.get("relics_hung", []).has(SPARK_ID):
		return {"verdict": "FAIL", "detail": "The Spark must start unhung"}
	for id: String in SPARK_RECIPES:
		if personal.get("attachment_recipes", []).has(id):
			return {"verdict": "FAIL", "detail": "The initial fixture must not grant reserved Stormwood hang recipes"}
	if not personal.relics_held.has(SPARK_ID): personal.relics_held.append(SPARK_ID)
	if not preload("res://scripts/data/redesign_state.gd").validate("character", personal).is_empty():
		return {"verdict": "FAIL", "detail": "Invalid initial Spark entitlement"}
	game.local.redesign_character = personal
	return {"verdict": "PASS", "detail": "Disclosed initial personal Spark held, not hung; no boss grant credit"}


static func _spark_hall(tree: SceneTree) -> Node3D:
	for node: Node in tree.get_nodes_in_group("crossing_halls"):
		if tree.current_scene != null and tree.current_scene.is_ancestor_of(node):
			return node as Node3D
	return null


## Read the original owner's actual portable file; never synthesize a saved ACK.
static func _spark_disk(game: Node, character: String) -> Dictionary:
	var path: String = game.get("save_system").call("characters").call("path_for", character)
	var raw: Variant = preload("res://scripts/save/save_document.gd").parse(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not raw is Dictionary or raw.get("character_id") != character: return {}
	var personal: Dictionary = raw.get("redesign_character", {})
	var recipes := {}
	for id: String in SPARK_RECIPES: recipes[id] = personal.get("attachment_recipes", []).count(id)
	return {"character_id": character, "held": personal.get("relics_held", []).count(SPARK_ID),
		"hung": personal.get("relics_hung", []).count(SPARK_ID),
		"hang_receipts": personal.get("transaction_receipts", []).count("relic_hang:%s:%s" % [SPARK_ID, character]),
		"active_relic": raw.get("realm_hearts", {}).get("active_id", ""), "recipes": recipes}


static func _spark_binding(tree: SceneTree) -> Dictionary:
	var game := _game(tree)
	var session: Node = game.get("session") if game != null else null
	if session == null or session.call("is_active") != true: return {}
	return {"scene": tree.current_scene, "hall": _spark_hall(tree), "local": game.get("local"),
		"world": game.get("world"), "session": session, "character": _character_id(game),
		"epoch": session.call("_altar_current_epoch"), "namespace": game.world.reward_delivery_namespace}


static func _spark_panel_ready(tree: SceneTree, original: Dictionary, disk: Dictionary) -> bool:
	if original.is_empty() or original.epoch == "" or _spark_binding(tree) != original: return false
	var hall: Node = original.hall
	var panel: Node = hall.get("_power_panel") if is_instance_valid(hall) else null
	var personal: Dictionary = _game(tree).local.redesign_character
	return panel != null and panel.call("is_open") == true and INPUT_OWNER.current(tree) == panel \
		and hall.get("_relic_pending") == "" and (hall.get("_queued_power") as Dictionary).is_empty() \
		and personal.relics_held.count(SPARK_ID) == 0 and personal.relics_hung.count(SPARK_ID) == 1 \
		and personal.transaction_receipts.count("relic_hang:%s:%s" % [SPARK_ID, original.character]) == 1 \
		and disk.get("held") == 0 and disk.get("hung") == 1 and disk.get("hang_receipts") == 1


## Wait for this saved hang's actual panel, then use ordinary accept/Cancel edges.
static func _spark_power(tree: SceneTree, args: Dictionary) -> Dictionary:
	var original := _spark_binding(tree)
	if original.is_empty(): return {"verdict": "FAIL", "detail": "Spark power needs the original admitted owner"}
	var deadline := Engine.get_physics_frames() + int(args.get("budget_frames", 600))
	var disk := _spark_disk(_game(tree), original.character)
	while not _spark_panel_ready(tree, original, disk) and Engine.get_physics_frames() < deadline:
		if _spark_binding(tree) != original: return {"verdict": "FAIL", "detail": "Spark power owner/session changed while waiting"}
		await tree.physics_frame
		disk = _spark_disk(_game(tree), original.character)
	if not _spark_panel_ready(tree, original, disk): return {"verdict": "FAIL", "detail": "Saved hang never settled with the exact Shrine Room panel owning input"}
	var panel: Node = original.hall.get("_power_panel")
	var active_before: String = _game(tree).realm_hearts.active_id()
	var cancel_only := bool(args.get("cancel_only", false))
	if not cancel_only:
		var rows: Array = panel.get("_rows")
		var choices: Array = panel.call("choices", _game(tree).realm_hearts, _game(tree).local.redesign_character.relics_hung)
		var index := choices.find(SPARK_ID)
		if index < 0 or index >= rows.size(): return {"verdict": "FAIL", "detail": "The character has no hung Spark row"}
		(rows[index] as Button).grab_focus()
		var accept: Dictionary = await tree.call("_step_press", {"action": "ui_accept"})
		if accept.get("verdict") != "PASS": return accept
		while Engine.get_physics_frames() < deadline:
			if _spark_binding(tree) != original: return {"verdict": "FAIL", "detail": "Spark selection owner/session changed"}
			disk = _spark_disk(_game(tree), original.character)
			if _spark_panel_ready(tree, original, disk) and disk.get("active_relic") == SPARK_ID \
				and _game(tree).realm_hearts.active_id() == SPARK_ID and panel.get("_pending_heart") == "": break
			await tree.physics_frame
		if disk.get("active_relic") != SPARK_ID or _game(tree).realm_hearts.active_id() != SPARK_ID \
			or panel.get("_pending_heart") != "" or not _spark_panel_ready(tree, original, disk):
			return {"verdict": "FAIL", "detail": "Spark power selection never saved/applied on the original owner"}
	var cancel: Dictionary = await tree.call("_step_press", {"action": "menu_cancel"})
	if cancel.get("verdict") != "PASS": return cancel
	while Engine.get_physics_frames() < deadline:
		if _spark_binding(tree) != original: return {"verdict": "FAIL", "detail": "Spark Cancel owner/session changed"}
		if panel.call("is_open") == false and panel.get("_pending_heart") == "" \
			and panel.get("_pending_character") == "" and panel.get("_pending_session") == null \
			and INPUT_OWNER.current(tree) == null and not tree.paused:
			disk = _spark_disk(_game(tree), original.character)
			var expected := active_before if cancel_only else SPARK_ID
			if disk.get("active_relic") != expected or _game(tree).realm_hearts.active_id() != expected:
				return {"verdict": "FAIL", "detail": "Spark Cancel changed the original saved power"}
			return {"verdict": "PASS", "detail": "Actual power panel closed, pending choice cleared and world input released",
				"data": {"active_relic": expected, "cancel_only": cancel_only, "disk": disk}}
		await tree.physics_frame
	return {"verdict": "FAIL", "detail": "Spark Cancel failed to close the exact panel and release world input"}


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
	# Spark ownership and selection belong to this character. The Hall display
	# is a world presentation fact, independent of another character's hung set.
	var hearts: RefCounted = game.get("realm_hearts")
	var personal: Dictionary = game.local.redesign_character
	var displayed: Dictionary = game.world.redesign_world.get("shrine_display", {})
	data["spark_earned"] = personal.get("relics_held", []).has(SPARK_ID) or personal.get("relics_hung", []).has(SPARK_ID)
	data["spark_placed"] = displayed.get(SPARK_ID) == true
	data["spark_hung"] = personal.get("relics_hung", []).has(SPARK_ID)
	data["spark_held"] = personal.get("relics_held", []).has(SPARK_ID)
	data["spark_hang_receipts"] = personal.get("transaction_receipts", []).count("relic_hang:%s:%s" % [SPARK_ID, _character_id(game)])
	data["spark_disk"] = _spark_disk(game, _character_id(game))
	data["active_relic"] = str(hearts.call("active_id")) if hearts != null else ""
	data["spark_socket"] = "active" if data.spark_hung and data.active_relic == SPARK_ID else ("placed_inactive" if data.spark_hung else "earned_unplaced")
	var scene := tree.current_scene
	var hall := _spark_hall(tree)
	var pedestal: Node = hall.get_node_or_null("Pedestal_stormwood") if hall != null else null
	data["spark_pedestal_displayed"] = pedestal.get_meta("relic_displayed", false) if pedestal != null else null
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


# --- the Spark's pedestal in the Crossing Hall Shrine Room -----------------------------------

static func _spark_socket(tree: SceneTree, args: Dictionary) -> Dictionary:
	var scene := tree.current_scene
	var original := _spark_binding(tree)
	var hall := _spark_hall(tree)
	var slot := hall.get_node_or_null("Pedestal_stormwood") as Node3D if hall != null else null
	var player := (tree.get("_probe") as Object).call("player") as Node3D
	if slot == null or player == null:
		return {"verdict": "FAIL", "detail": "no Shrine Room Spark pedestal or player in this scene"}
	var prompt: Node
	for child: Node in slot.get_children():
		if child.get_script() == preload("res://scripts/world/interactable.gd"):
			prompt = child
			break
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
	var before := "hung" if _game(tree).local.redesign_character.relics_hung.has(SPARK_ID) else "held"
	var label := str(prompt.get("label"))
	if standing.is_empty():
		return {"verdict": "FAIL", "detail": "the Spark socket's prompt never won the interaction arbiter (state %s, label '%s'; won instead: %s)"
			% [before, label, str(winners)]}
	var pressed := ""
	var disk := {}
	var disk_before := {}
	if bool(args.get("press", false)):
		if original.is_empty() or original.epoch == "" or _spark_binding(tree) != original:
			return {"verdict": "FAIL", "detail": "Spark interaction needs the original admitted owner/session"}
		disk = _spark_disk(_game(tree), original.character)
		disk_before = disk.duplicate(true)
		if before == "held":
			if disk.get("held") != 1 or disk.get("hung") != 0 or disk.get("hang_receipts") != 0:
				return {"verdict": "FAIL", "detail": "Original character disk does not prove the initial unspent held Spark", "data": {"disk": disk}}
			for id: String in SPARK_RECIPES:
				if disk.get("recipes", {}).get(id) != 0:
					return {"verdict": "FAIL", "detail": "Reserved Stormwood recipe was already present before the actual hang", "data": {"disk": disk}}
		var press: Dictionary = await tree.call("_step_press", {"action": "interact"})
		pressed = "; press: %s" % str(press.get("detail", ""))
		if str(press.get("verdict", "")) != "PASS":
			return {"verdict": "FAIL", "detail": "standing %s, '%s' (%s)%s" % [standing, label, before, pressed]}
		for _i in int(args.get("after_frames", 120)):
			if _spark_binding(tree) != original:
				return {"verdict": "FAIL", "detail": "Spark hang owner/session changed"}
			disk = _spark_disk(_game(tree), original.character)
			if _spark_panel_ready(tree, original, disk): break
			await tree.physics_frame
		disk = _spark_disk(_game(tree), original.character)
		if not _spark_panel_ready(tree, original, disk):
			return {"verdict": "FAIL", "detail": "Spark hang did not save and settle with the exact power panel owning input", "data": {"disk": disk}}
		for id: String in SPARK_RECIPES:
			if disk.get("recipes", {}).get(id) != 1 or _game(tree).local.redesign_character.attachment_recipes.count(id) != 1:
				return {"verdict": "FAIL", "detail": "Actual hang did not install/save exactly one reserved recipe: " + id, "data": {"disk": disk}}
	var after := "hung" if _game(tree).local.redesign_character.relics_hung.has(SPARK_ID) else "held"
	return {"verdict": "PASS",
		"detail": "standing %s at the Spark socket, prompt '%s'; state %s -> %s%s" % [standing, label, before, after, pressed],
		"data": {"before": before, "after": after, "label": label, "disk_before": disk_before, "disk": disk}}

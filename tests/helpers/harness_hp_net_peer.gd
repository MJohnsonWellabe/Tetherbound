extends "res://tools/net/peer_runner.gd"

## Peer for tests/smoke_net_harness_max_hp.gd (F33 Harness maximum HP). The
## ordinary tools/net/peer_runner.gd plus three harness_* actions. DISCLOSED
## FIXTURES (test-only; none touches the decision or apply path under test):
##   * `harness_wear` (before join): writes a Harness into this peer's own
##     record row for its first creature, so the join snapshot the host admits
##     carries it (gear is the subject, not the Den transaction).
##   * `harness_host_hit` (host): swings the host's live opponent once at the
##     named participant's deployed body from 1.5 m away with a narrow cone,
##     through the PRODUCTION combat_manager._host_resolve_enemy_strike_for_a_
##     participant (host pick -> admitted geared card -> host_deliver_enemy_hit
##     -> RPC -> the guest's apply_host_enemy_hit).
##   * `harness_unwear`: removes that Harness from this peer's own record
##     again (after join), so only the host's s can explain the raised bar.
##   * `harness_read` also reports the last rolled incoming hit this peer's
##     CombatManager announced (its production `hit_landed(false, amount)`),
##     and the running total of every such hit since it started listening (the
##     live wild may land its own strike inside the measured window).
##   * `harness_flee`: the production combat_manager.try_flee (what the flee
##     button calls), so the fight ends by the ordinary exit.
##   * `harness_read`: this peer's active creature as stored, as displayed by
##     combat_manager.display_hp, and as the save writes its party row.

const SAVE := preload("res://scripts/save/save_game.gd")

var _last_incoming := -1.0
var _incoming_total := 0.0
var _incoming_listening := false


func _on_hit_landed(on_enemy: bool, amount: float) -> void:
	if not on_enemy:
		_last_incoming = amount
		_incoming_total += amount


func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if not action.begins_with("harness_"):
		return await super._execute_step(msg)
	if action == "harness_wear":
		# Disclosed fixture: it writes the record directly, so it must respect
		# the owner fence a player's equip would (no change inside a frozen
		# checkpoint, which the next leave could then not write).
		var session: Node = root.get_node_or_null(^"Game/Session")
		for _frame in 1200:
			if session == null or session.call("_owner_training_mutation_blocked", root.get_node(^"Game").get("local")) != true: break
			await physics_frame
	if action == "harness_host_hit":
		# The wild stays live and lands its own strikes; the host refuses any
		# strike while that hit's saved vitals are pending (product rule). Like
		# the enemy's own next swing, the explicit strike waits for settlement.
		var director := _encounter_director()
		var manager := _combat_manager()
		for _frame in 600:
			if director == null or manager == null or director.call("ordinary_actor_vitals_pending",
				str(manager.get("_encounter_id"))) != true: break
			await physics_frame
	# The runner forwards only verdict/detail/data: every other key rides in data.
	var raw: Dictionary = _harness_dispatch(action, msg.get("args", {}))
	var data: Dictionary = {}
	for key: Variant in raw:
		if not str(key) in ["verdict", "detail", "data"]: data[key] = raw[key]
	return {"verdict": raw.get("verdict", "ERROR"), "detail": raw.get("detail", ""), "data": data}


func _harness_dispatch(action: String, args: Dictionary) -> Dictionary:
	var game: Node = root.get_node_or_null(^"Game")
	if game == null: return {"verdict": "ERROR", "detail": "no Game"}
	var local: RefCounted = game.get("local")
	if action == "harness_record": return _harness_record(game, str(args.get("item", "")))
	if action == "harness_admitted": return _harness_admitted(game, int(args.get("peer_id", 0)), str(args.get("uid", "")))
	var members: Array = local.get("party").call("members") if local != null else []
	if members.is_empty(): return {"verdict": "ERROR", "detail": "no party creature"}
	match action:
		"harness_wear":
			var uid := str((members[0] as RefCounted).get("uid"))
			var character: Dictionary = local.get("redesign_character")
			var creatures: Dictionary = character.get("creatures", {})
			var row: Dictionary = creatures.get(uid, {})
			row["gear"] = {"harness": str(args.get("item", "")), "charm": ""}
			creatures[uid] = row
			character["creatures"] = creatures
			return {"verdict": "PASS", "detail": "%s wears %s" % [uid, str(args.get("item", ""))], "uid": uid}
		"harness_host_hit":
			var director := _encounter_director()
			var manager := _combat_manager()
			if director == null or manager == null or not manager.call("is_fighting"):
				return {"verdict": "ERROR", "detail": "the host is not fighting"}
			var peer := int(args.get("peer_id", 0))
			var body: Node3D = director.call("deployed_body_for", peer)
			if body == null: return {"verdict": "ERROR", "detail": "no deployed body for peer %d" % peer}
			var target: Vector3 = body.call("centre")
			var origin := target + Vector3(1.5, 0.0, 0.0)
			var cfg := {"range": 3.0, "cone_degrees": 20.0, "power": 8.0, "lunge": 0.0,
				"move_id": str((manager.get("_enemy") as RefCounted).get("move_quick"))}
			var host_s := float(director.call("_host_hp_scale", peer))
			var handled: bool = manager.call("_host_resolve_enemy_strike_for_a_participant", cfg, origin, (target - origin).normalized())
			return {"verdict": "PASS" if handled and bool(manager.get("_enemy_strike_connected")) else "FAIL",
				"detail": "host s %.4f, connected %s" % [host_s, str(manager.get("_enemy_strike_connected"))],
				"host_s": host_s}
		"harness_unwear":
			var uid := str((members[0] as RefCounted).get("uid"))
			var row: Dictionary = (local.get("redesign_character") as Dictionary).get("creatures", {}).get(uid, {})
			row.erase("gear")
			return {"verdict": "PASS", "detail": "%s wears nothing locally" % uid}
		"harness_flee":
			var manager := _combat_manager()
			if manager == null: return {"verdict": "ERROR", "detail": "no CombatManager"}
			var fled: bool = manager.call("try_flee")
			return {"verdict": "PASS" if fled else "FAIL", "detail": "try_flee %s (%s)" % [str(fled), str(manager.call("flee_refusal"))]}
		"harness_read":
			var manager := _combat_manager()
			if manager != null and not _incoming_listening:
				manager.connect("hit_landed", _on_hit_landed)
				_incoming_listening = true
			var creature: RefCounted = manager.call("active_creature") if manager != null and manager.call("is_fighting") else members[0]
			var shown: Vector2 = manager.call("display_hp", creature) if manager != null else Vector2.ZERO
			var row: Dictionary = SAVE.new("user://harness_hp_probe")._party_to_array(local.get("party"))[0]
			return {"verdict": "PASS", "detail": "hp %.2f/%.2f shown %.2f/%.2f saved max %.2f incoming %.6f last %.6f" % [
				float(creature.get("hp")), float(creature.get("max_hp")), shown.x, shown.y, float(row.max_hp),
				_incoming_total, _last_incoming],
				"hp": float(creature.get("hp")), "max_hp": float(creature.get("max_hp")),
				"shown_hp": shown.x, "shown_max": shown.y, "saved_max": float(row.max_hp),
				"fighting": manager != null and bool(manager.call("is_fighting")), "last_incoming": _last_incoming,
				"incoming_total": _incoming_total}
	return {"verdict": "ERROR", "detail": "unknown action " + action}


## F33#4 rejoin round trip (coordinator ruling 2026-10-11): this peer's first
## creature's gear and the bag count of `item`, live and in its own
## `user://characters/<id>` file, side by side and never merged. Read-only.
func _harness_record(game: Node, item: String) -> Dictionary:
	var local: RefCounted = game.get("local")
	if local == null: return {"verdict": "ERROR", "detail": "no Game.local"}
	var gear_script := preload("res://scripts/creatures/creature_gear.gd")
	var character_id := str(local.get("character_id"))
	var members: Array = local.get("party").call("members")
	var uid := str((members[0] as RefCounted).get("uid")) if not members.is_empty() else ""
	var live_gear: Dictionary = gear_script.gear_for({"redesign_character": local.get("redesign_character")}, uid) if not uid.is_empty() else {}
	var live_count := int(game.get("inventory").call("count", item))
	var file: Dictionary = {}
	var save: Variant = game.get("save_system")
	if save != null and not character_id.is_empty():
		var characters: Variant = (save as RefCounted).call("characters")
		if characters != null and bool((characters as RefCounted).call("has", character_id)):
			file = (characters as RefCounted).call("state", character_id) as Dictionary
	var file_uid := ""
	for card: Variant in file.get("party", []):
		if card is Dictionary:
			file_uid = str(card.get("uid", ""))
			break
	var file_gear: Dictionary = gear_script.gear_for(file, file_uid) if not file_uid.is_empty() else {}
	var file_count := 0
	for stack: Variant in file.get("inventory", []):
		if stack is Dictionary and str(stack.get("id", "")) == item: file_count += int(stack.get("n", 0))
	return {"verdict": "PASS", "detail": "live %s %s bag %d | file %s %s bag %d" % [uid, str(live_gear), live_count,
		file_uid, str(file_gear), file_count],
		"character_id": character_id, "uid": uid, "live_harness": str(live_gear.get("harness", "")),
		"live_count": live_count, "file_exists": not file.is_empty(), "file_uid": file_uid,
		"file_harness": str(file_gear.get("harness", "")), "file_count": file_count,
		"party_size": members.size()}


## Host side: the gear the host's ADMITTED record of `peer_id` gives creature
## `uid`, the s the host's director would roll that peer's hits with, and the
## host's own creatures' gear and s. Read-only.
func _harness_admitted(game: Node, peer_id: int, uid: String) -> Dictionary:
	var gear_script := preload("res://scripts/creatures/creature_gear.gd")
	var session: Node = _session()
	var director := _encounter_director()
	if session == null or director == null: return {"verdict": "ERROR", "detail": "no session/director"}
	var admitted: Dictionary = session.call("admitted_character_state", peer_id)
	var admitted_harness := str(gear_script.gear_for(admitted, uid).get("harness", ""))
	var own: Array = []
	var local: RefCounted = game.get("local")
	for creature: RefCounted in local.get("party").call("members"):
		own.append(str(gear_script.gear_for({"redesign_character": local.get("redesign_character")}, str(creature.get("uid"))).get("harness", "")))
	var guest_s := float(director.call("_host_hp_scale", peer_id))
	var own_s := float(director.call("_host_hp_scale", int(session.call("local_peer_id"))))
	return {"verdict": "PASS", "detail": "admitted %s harness '%s' s %.4f | host own harnesses %s s %.4f" % [
		uid, admitted_harness, guest_s, str(own), own_s],
		"admitted_harness": admitted_harness, "guest_s": guest_s, "own_harnesses": own, "own_s": own_s,
		"admitted_empty": admitted.is_empty()}

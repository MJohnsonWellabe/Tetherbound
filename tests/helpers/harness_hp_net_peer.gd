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

extends "res://tools/net/proof_peer_runner.gd"

## PEER process for `tests/smoke_net_owner_passive_rejoin.gd`. Not a smoke on
## its own: no `# peers:` header, never discovered by CI.
##
## Exactly the proof peer runner plus one read-only probe and one fixture:
##  * probe `op_state`     this peer's owner-passive stream (`local`), and on
##                         the host every stream it holds per character.
##  * step `op_diverge`    FIXTURE (disclosed): before a rejoin, raise one owned
##                         creature's level in this peer's live character, so
##                         the portable state it declares no longer matches the
##                         host's admitted authority -- a real conflict.


func _execute_step(msg: Dictionary) -> Dictionary:
	if str(msg.get("action", "")) != "op_diverge":
		return await super(msg)
	var game := root.get_node_or_null(^"Game")
	var party: RefCounted = game.get("party") if game != null else null
	var member: RefCounted = party.call("at", 0) if party != null else null
	if member == null:
		return {"verdict": "ERROR", "detail": "no owned creature to diverge"}
	var before := int(member.get("level"))
	member.call("set_level", before + 1, preload("res://scripts/creatures/progression.gd").config())
	return {"verdict": "PASS", "detail": "owned creature 0 level %d -> %d on this peer only" % [before, int(member.get("level"))],
		"frames_used": 0}


func _execute_probe(msg: Dictionary) -> Variant:
	if str(msg.get("what", "")) != "op_state":
		return await super(msg)
	var game := root.get_node_or_null(^"Game")
	var session: Node = game.get_node_or_null(^"Session") if game != null else null
	if session == null:
		return {"error": "no session"}
	var service: RefCounted = session.call("_owner_passive_service")
	var local: Dictionary = service.get("local")
	var out := {
		"is_host": bool(session.call("is_host")),
		"character_id": str(game.get("local").character_id),
		"local": {
			"armed": not local.is_empty(),
			"id": str(local.get("id", "")),
			"admission_pending": bool(local.get("admission_pending", false)),
			"acked": int(local.get("acked", -1)),
			"sequence": int(local.get("sequence", -1)),
			"error": str(local.get("error", "")),
			"admission_refused": str(local.get("admission_refused", "")),
		},
		"hosts": {},
	}
	var hosts: Dictionary = service.get("hosts")
	for character: String in hosts:
		var stream: Dictionary = hosts[character]
		out.hosts[character] = {"id": str(stream.get("id", "")), "peer": int(stream.get("peer", 0)),
			"sequence": int((stream.get("cursor", {}) as Dictionary).get("sequence", -1)),
			"departed": stream.get("departed") == true, "error": str(stream.get("error", ""))}
	return out

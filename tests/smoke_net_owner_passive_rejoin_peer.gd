extends "res://tools/net/proof_peer_runner.gd"

## PEER process for `tests/smoke_net_owner_passive_rejoin.gd`. Not a smoke on
## its own: no `# peers:` header, never discovered by CI.
##
## Exactly the proof peer runner plus one read-only probe and one fixture:
##  * probe `op_state`     this peer's owner-passive stream (`local`), and on
##                         the host every stream it holds per character.
##  * step `op_diverge`    FIXTURE (disclosed): before a rejoin, raise one owned
##                         creature's level in this peer's live character -- an
##                         offline portable change (as a solo session's XP).
##  * step `op_hold`       FIXTURE (disclosed): pause (`hold`: true) or resume
##                         this owner's owner-passive send timer, standing in for
##                         "left before its inputs reached the host".
##  * step `op_corrupt`    FIXTURE (disclosed): make the live record invalid for
##                         admission (a creature's hp above its max), so the
##                         host must refuse it under the first-join rules;
##                         `op_corrupt {"restore": true}` puts it back.
##  * probe `op_state`     also reports the host's held authority per character
##                         (party levels, item counts) and this peer's counts.


var _corrupt_hp := -1.0


func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if action == "op_hold":
		var session: Node = root.get_node(^"Game").get_node_or_null(^"Session")
		var service: RefCounted = session.call("_owner_passive_service")
		var hold: bool = (msg.get("args", {}) as Dictionary).get("hold", true) == true
		service.set("_left", 1.0e9 if hold else 0.0)
		return {"verdict": "PASS", "detail": "owner-passive send %s" % ("held" if hold else "resumed"), "frames_used": 0}
	if action == "op_corrupt":
		var member0: RefCounted = root.get_node(^"Game").get("party").call("at", 0)
		if (msg.get("args", {}) as Dictionary).get("restore") == true:
			member0.set("hp", _corrupt_hp)
			return {"verdict": "PASS", "detail": "hp restored to %.1f" % _corrupt_hp, "frames_used": 0}
		_corrupt_hp = float(member0.get("hp"))
		member0.set("hp", float(member0.get("max_hp")) + 50.0)
		return {"verdict": "PASS", "detail": "hp above max on this peer only", "frames_used": 0}
	if action != "op_diverge":
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
	out["items"] = _counts((game.get("local").save_data() as Dictionary).get("inventory", []))
	out["levels"] = []
	for member: RefCounted in game.get("party").call("members"): out.levels.append(int(member.get("level")))
	out["authority"] = {}
	out["rejoin_codes"] = (session.get("last_rejoin_admission") as Dictionary).duplicate() if bool(session.call("is_host")) else {}
	if bool(session.call("is_host")):
		var authority: RefCounted = session.get("_character_authority")
		for character: String in authority.get("_records"):
			var held: Dictionary = authority.call("state", character)
			out.authority[character] = {"items": _counts(held.get("inventory", [])),
				"levels": (held.get("party", []) as Array).map(func(c: Dictionary) -> int: return int(c.get("level", 0))),
				"revision": int(authority.call("revision", character))}
	var hosts: Dictionary = service.get("hosts")
	for character: String in hosts:
		var stream: Dictionary = hosts[character]
		out.hosts[character] = {"id": str(stream.get("id", "")), "peer": int(stream.get("peer", 0)),
			"sequence": int((stream.get("cursor", {}) as Dictionary).get("sequence", -1)),
			"departed": stream.get("departed") == true, "error": str(stream.get("error", ""))}
	return out


static func _counts(slots: Variant) -> Dictionary:
	var out := {}
	if slots is Array:
		for slot: Variant in slots:
			if slot is Dictionary and not str(slot.get("id", "")).is_empty():
				out[str(slot.id)] = int(out.get(str(slot.id), 0)) + int(slot.get("n", 0))
	return out

extends RefCounted

const PROGRESSION := preload("res://scripts/creatures/progression.gd")

## The owning party is persistent even when the paying director's realm is
## retired. Both delivery routes use the same XP eligibility and message.
static func apply(party: RefCounted, game: Node, payload: Dictionary) -> void:
	var xp := int(payload.get("xp", 0))
	if xp > 0 and party != null:
		var cfg: Dictionary = PROGRESSION.config()
		for i in int(party.call("size")):
			var member: RefCounted = party.call("at", i)
			if member != null and not bool(member.get("fainted")):
				member.call("gain_xp", xp, cfg)
	var line := str(payload.get("line", ""))
	if not line.is_empty() and game != null:
		game.call("push_world_message", line)

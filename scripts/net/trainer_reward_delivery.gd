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
		# P2-111 (hud.json victory_focus.route_trainer_receipts, OFF by default):
		# the named fight's acknowledgement shows as the victory Moment receipt
		# rather than in the quickbar's message strip, where it read as part of
		# the quick items row.
		if victory_receipt_routed():
			var title := str(payload.get("trainer", ""))
			PROGRESSION_FEED_SCRIPT.push("reward_summary", null, {"name": "Team",
				"receipt": ("%s's reward: %s" % [title, line]) if not title.is_empty() else line})
			return
		game.call("push_world_message", line)


const PROGRESSION_FEED_SCRIPT := preload("res://scripts/creatures/progression_feed.gd")


static func victory_receipt_routed() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	var cfg: Variant = parsed.get("victory_focus", {}) if parsed is Dictionary else {}
	return cfg is Dictionary and cfg.get("enabled") == true and cfg.get("route_trainer_receipts") == true

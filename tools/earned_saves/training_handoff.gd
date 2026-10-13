extends RefCounted

## Evidence only. Never initializes or repairs creature mirrors. A missing
## legacy receipt remains disclosed, not proof of an earned training seam.
static func snapshot(game: Node) -> Dictionary:
	var personal: Dictionary = game.get("local").get("redesign_character")
	var party: Array = []
	for member: RefCounted in game.get("party").call("members"):
		var uid := str(member.get("uid"))
		var mirror: Dictionary = personal.get("creatures", {}).get(uid, {})
		party.append({"uid": uid, "species": str(member.get("species_id")),
			"level": int(member.get("level")), "xp": int(member.get("xp")),
			"cap_level": mirror.get("cap_level"),
			"breakthroughs": mirror.get("breakthroughs"),
			"evolution_choices": mirror.get("evolution_choices", {})})
	var wins: Array = personal.get("master_wins", []).duplicate()
	var recipes: Array = personal.get("feast_recipes", []).duplicate()
	wins.sort()
	recipes.sort()
	return {"version": 1, "party": party, "master_wins": wins, "feast_recipes": recipes}


static func compare(previous: Dictionary, loaded: Dictionary) -> Dictionary:
	if not previous.has("training"):
		return {"checked": false, "matches": false, "reason": "legacy input has no training snapshot"}
	if not loaded.has("training"):
		return {"checked": true, "matches": false, "reason": "loaded training snapshot missing"}
	var saved: Variant = JSON.parse_string(JSON.stringify(previous.training))
	var current: Variant = JSON.parse_string(JSON.stringify(loaded.training))
	return {"checked": true, "matches": saved == current,
		"reason": "" if saved == current else "levels, XP, caps, breakthroughs, Master wins or recipes differ"}

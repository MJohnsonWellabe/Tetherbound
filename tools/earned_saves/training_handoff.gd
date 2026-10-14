extends RefCounted
const HOME := preload("res://scripts/story/regional_homecoming.gd")

## Durable personal ending fields only; a new process has a new session epoch.
static func ending_snapshot(game: Node) -> Dictionary:
	var context := HOME.journey_context(game)
	if context.is_empty(): return {}
	var result := {}
	for key: String in ["character_id", "outcome_id", "home_return_receipt", "starter_uid",
			"party_signature", "chapter_choices", "homecoming_seen", "regional_credits_seen"]:
		result[key] = context.get(key)
	return result


static func compare_ending(previous: Dictionary, loaded: Dictionary) -> bool:
	if not previous.get("ending") is Dictionary or previous.ending.is_empty() \
			or not loaded.get("ending") is Dictionary or loaded.ending.is_empty(): return false
	return JSON.parse_string(JSON.stringify(previous.ending)) == JSON.parse_string(JSON.stringify(loaded.ending))

## Alias support is confined to shared chapter-training imports. Split Tidewake
## continuations still require their canonical fields and exact predecessor.
static func missing_route_fields(previous: Dictionary, aliases: bool = false) -> Array[String]:
	var missing: Array[String] = []
	for key: String in ["uids", "flags", "items", "realm"]:
		var saved_key := key
		if aliases and not previous.has(key):
			if key == "flags": saved_key = "world_flags"
			elif key == "items": saved_key = "inventory"
		if not previous.has(saved_key) or previous[saved_key] == null: missing.append(key)
	return missing

## Tidewake names aggregate inventory `items`; Cloudreach names it
## `inventory`. Compare the actual contents, never drop that seam check.
static func compare_route(previous: Dictionary, loaded: Dictionary) -> Array[String]:
	var mismatched: Array[String] = []
	for key: String in ["uids", "flags", "inventory", "realm"]:
		var alias := "items" if key == "inventory" else ("world_flags" if key == "flags" else "")
		if not alias.is_empty() and previous.has(key) and previous.has(alias) \
				and JSON.parse_string(JSON.stringify(previous[key])) != JSON.parse_string(JSON.stringify(previous[alias])):
			mismatched.append(key)
			continue
		var saved: Variant = previous.get(key)
		if key == "inventory" and not previous.has(key):
			saved = previous.get("items")
		if key == "flags" and not previous.has(key):
			saved = previous.get("world_flags")
		if saved == null or not loaded.has(key) \
				or JSON.parse_string(JSON.stringify(saved)) != JSON.parse_string(JSON.stringify(loaded[key])):
			mismatched.append(key)
	return mismatched

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

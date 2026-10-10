extends RefCounted

## Read only. Availability comes from this character's real state, never world
## ending markers, a host's progress, or synthetic opening completion.
const DATA := preload("res://scripts/data/redesign_data.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const PREFIX := "opening:lesson:"

static func config() -> Dictionary:
	var raw: Variant = DATA.json("res://data/config/onboarding.json")
	return raw if raw is Dictionary else {}

## No-copy read for this file's own per-frame checks; rows leave as copies.
static func _config_view() -> Dictionary:
	var raw: Variant = DATA.json_view("res://data/config/onboarding.json")
	return raw if raw is Dictionary else {}

static func available(id: String, player: RefCounted) -> bool:
	if player == null: return false
	var state: Dictionary = player.get("redesign_character")
	var inventory: RefCounted = player.get("inventory")
	var flags: RefCounted = player.get("flags")
	match id:
		"home_key":
			return flags.call("has", "home_key_given") == true and inventory.call("count", "home_key") == 1
		"homestead":
			return flags.call("has", PREFIX + "trigger:home_return") == true
		"altar":
			for essence: Dictionary in DATA.json_view("res://data/schema/essences.json"):
				if inventory.call("count", str(essence.id)) > 0: return true
		"masters":
			return not capped_master(player).is_empty()
		"feasts": return not state.get("feast_recipes", []).is_empty()
		"traits": return not state.get("release_receipts", []).is_empty()
		"portals":
			for key: String in ["tidewake_portal_key", "cloudreach_portal_key", "stormwood_portal_key"]:
				if inventory.call("count", key) > 0: return true
			return not state.get("portal_unlocks", []).is_empty()
		"shrines": return not state.get("relics_held", []).is_empty() or not state.get("relics_hung", []).is_empty()
	return false

static func due(player: RefCounted) -> Dictionary:
	for row: Dictionary in _config_view().get("lessons", []):
		if available(str(row.id), player) and player.get("flags").call("has", PREFIX + str(row.id)) != true:
			return lesson(row, player)
	return {}

## A returning character can first meet Tam at any of the five caps. The
## installed Master data and this character's own breakthrough mirror decide
## which lesson goal to show; the host's progress never supplies it.
static func capped_master(player: RefCounted) -> Dictionary:
	if player == null: return {}
	var state: Dictionary = player.get("redesign_character")
	var party: RefCounted = player.get("party")
	for index: int in party.call("size"):
		var creature: RefCounted = party.call("at", index)
		var mirror: Dictionary = state.get("creatures", {}).get(str(creature.get("uid")), {})
		var cap := BREAKTHROUGH.level_cap(mirror.get("breakthroughs", []))
		if int(creature.get("level")) != cap: continue
		for master: Dictionary in BREAKTHROUGH.masters().get("masters", []):
			if int(master.cap_level) == cap: return master.duplicate(true)
	return {}

static func lesson(authored: Dictionary, player: RefCounted) -> Dictionary:
	var row := authored.duplicate(true)
	if row.get("id") != "masters": return row
	var master := capped_master(player)
	if master.is_empty(): return row
	var state: Dictionary = player.get("redesign_character")
	row["goal_realm"] = preload("res://scripts/data/biome_order.gd").runtime_id(str(master.biome))
	row["goal_at"] = [master.position[0], master.position[2]]
	row["goal"] = "Challenge %s for the L%d feast recipe." % [str(master.name), int(master.cap_level)]
	if state.get("master_wins", []).has(master.id): row["goal"] = "Open %s's recipe chest." % str(master.name)
	if state.get("feast_recipes", []).has(master.feast_id):
		row["goal"] = "Cook the L%d feast at home, then feed your capped creature." % int(master.cap_level)
		row["goal_realm"] = "meadows"
		row["goal_at"] = [2, 14]
	return row

static func guidance(player: RefCounted) -> Dictionary:
	if _config_view().get("enabled") != true or player == null: return {}
	# Preserve the required opening's one next action. Tutorials don't replace
	# naming, real catch, Mira's kit or the tournament readiness chain.
	if player.get("flags").call("has", "tournament_entered") != true: return {}
	var state: Dictionary = player.get("redesign_character")
	if not capped_master(player).is_empty(): return lesson(_row("masters"), player)
	var inventory: RefCounted = player.get("inventory")
	for biome: String in ["tidewake", "cloudreach", "stormwood"]:
		if inventory.call("count", biome + "_portal_key") > 0 and not state.get("portal_unlocks", []).has(biome):
			var row := _row("portals")
			row["goal"] = "Use your %s key at its signed arch in the Crossing Hall." % biome.capitalize()
			return row
	for relic: String in state.get("relics_held", []):
		if not state.get("relics_hung", []).has(relic): return _row("shrines")
	return {}

static func _row(id: String) -> Dictionary:
	for row: Dictionary in _config_view().get("lessons", []):
		if row.id == id: return row.duplicate(true)
	return {}

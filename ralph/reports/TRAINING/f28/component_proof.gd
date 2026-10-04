extends SceneTree
## ROOT-only named arithmetic/composition proof. Requires composed F29 and the
## ItemDB activation patch. Does NOT prove real authority/save/ACK/co-op/player
## paths; those stay separately open in the single combined ticket.
const B := preload("res://scripts/creatures/breakthrough.gd")
const E := preload("res://scripts/creatures/evolution.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const PERSONAL := preload("res://scripts/data/redesign_state.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	if not BAG.db().has("feast_t1_ground") or not E.has_method("prepare_feast_choice"):
		print("F28 prerequisites unavailable; component proof NOT RUN")
		quit(2)
		return
	for entry: Array in [[[], 10], [[1], 20], [[1, 2], 30], [[1, 2, 3], 40],
		[[1, 2, 3, 4], 50], [[1, 2, 3, 4, 5], 60]]:
		check(B.level_cap(entry[0]) == int(entry[1]), "cap boundary " + str(entry[1]))
	check(B.level_cap([2]) == -1 and B.level_cap([1, 3]) == -1, "gapped imported tiers refuse")
	check(B.level_cap([1, 2, 3, 4, 5, 6]) == -1, "reserved tier never becomes live")
	check(B.caught_tiers(30) == [1, 2] and B.caught_tiers(31) == [1, 2, 3], "late catch boundary")
	var before := state()
	check(B.prepare_chest(before, "master_t1", before.character_id).get("ok") == false, "spectator/no win cannot claim")
	var win := B.prepare_win(before, "master_t1", before.character_id)
	check(win.get("ok") == true, "host win can stage")
	check(before.redesign_character.master_wins.is_empty(), "staging never changes original")
	var chest := B.prepare_chest(win.state, "master_t1", before.character_id)
	check(chest.get("ok") == true and chest.state.redesign_character.feast_recipes.has("feast_t1"), "chest recipe staged")
	check(B.prepare_chest(chest.state, "master_t1", before.character_id).get("code") == "reconcile_original_delivery", "receipt is never optimistic ACK")
	var cookbook := chest.state.duplicate(true)
	var bag := BAG.inventory_from(cookbook.inventory)
	var recipe: Dictionary = B.feasts().recipes.feast_t1_ground
	for id: String in recipe.cost: bag.add(id, int(recipe.cost[id]))
	cookbook.inventory = BAG.slots(bag)
	var frozen := cookbook.duplicate(true)
	var context := {"station_id": "kitchen", "homestead": true, "in_range": true,
		"in_combat": false, "effective_tier": 1, "owns_character": true}
	var cook := B.prepare_cook(cookbook, "feast_t1_ground", "0123456789abcdef0123456789abcdef", context)
	check(cook.get("ok") == true, "actual costs produce one typed feast")
	check(cookbook == frozen, "cook clone leaves original inventory unchanged")
	var camp := context.duplicate(true)
	camp.homestead = false
	check(B.prepare_cook(cookbook, "feast_t1_ground", "1123456789abcdef0123456789abcdef", camp).get("ok") == false, "camp refuses feast")
	if cook.get("ok") == true:
		var feed := B.prepare_feed(cook.state, str(before.party[0].uid), "feast_t1_ground", "", context,
			_types, E.prepare_feast_choice, B.refresh_feast_moves)
		check(feed.get("ok") == true, "composed actual F29 cap-only planner")
		if feed.get("ok") == true:
			check(feed.state.redesign_character.creatures[before.party[0].uid].cap_level == 20, "only matching cap lifts")
			for field: String in ["uid", "nickname", "level", "xp", "move_quick", "move_charged", "move_utility", "move_ultimate", "move_mastery_uses", "move_mastery_receipts"]:
				check(feed.state.party[0][field] == before.party[0][field], "no free gain/change " + field)
			check(BAG.inventory_from(feed.state.inventory).count("feast_t1_ground") == 0, "one cooked feast consumed")
			check(B.prepare_feed(feed.state, str(before.party[0].uid), "feast_t1_ground", "stay", context,
				_types, E.prepare_feast_choice, B.refresh_feast_moves).get("code") == "reconcile_original_delivery", "conflicting replay requires immutable original row")
		check(B.prepare_feed(cook.state, "creature-ffffffffffffffffffffffffffffffff", "feast_t1_ground", "", context,
			_types, E.prepare_feast_choice, B.refresh_feast_moves).get("ok") == false, "foreign UID refuses")
		check(B.prepare_feed(cook.state, str(before.party[0].uid), "feast_t1_water", "", context,
			_types, E.prepare_feast_choice, B.refresh_feast_moves).get("code") == "attuned_ingredient_must_match_creature", "wrong type refuses before debit")
	print(JSON.stringify({"checks": checks, "failures": failures, "scope": "component only; real transaction/player proofs still OPEN"}))
	quit(0 if failures.is_empty() else 1)

func state() -> Dictionary:
	var party: Array = [{"uid": "creature-00000000000000000000000000000001", "species_id": "terrapup",
		"nickname": "Old friend", "level": 10, "xp": 0, "hp": 100.0, "max_hp": 100.0,
		"known_moves": ["pebble_toss", "stone_rush"], "move_quick": "pebble_toss", "move_charged": "stone_rush",
		"move_utility": "", "move_ultimate": "", "move_mastery_uses": {}, "move_mastery_receipts": {}}]
	var personal := TEACHING.character_loadout_mirror(party, PERSONAL.defaults("character"))
	return {"character_id": "character-f28-component", "party": party, "redesign_character": personal,
		"inventory": BAG.slots(INVENTORY.new(BAG.db()))}

func _types(species: String) -> Array:
	var catalogue: Dictionary = B.DATA.json("res://data/creatures/species.json").get("species", {})
	var row: Dictionary = catalogue.get(species, {})
	var result: Array = [str(row.get("type", ""))]
	if row.has("type_secondary"): result.append(str(row.type_secondary))
	return result

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

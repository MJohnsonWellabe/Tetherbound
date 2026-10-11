extends "res://tests/test_case.gd"

## F46#0: each authored onboarding lesson becomes due only when its own system
## unlocks for THIS character (lesson_rules.available/due), in authored order,
## and an acknowledged lesson is never due again. The panel's per-line skip is
## proven separately by tests/smoke_modal_stacking.gd.
const RULES := preload("res://scripts/onboarding/lesson_rules.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")


func _player() -> RefCounted:
	var player: RefCounted = preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = "lesson-owner"
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	return player


## The state change that unlocks each lesson, exactly as lesson_rules reads it.
func _unlock(player: RefCounted, id: String) -> void:
	var state: Dictionary = player.redesign_character
	match id:
		"home_key":
			player.flags.set_flag("home_key_given")
			player.inventory.add("home_key", 1)
		"homestead": player.flags.set_flag(RULES.PREFIX + "trigger:home_return")
		"altar": player.inventory.add("essence_ground", 1)
		"masters": player.party.at(0).level = BREAKTHROUGH.level_cap([])
		"feasts": state.feast_recipes = ["feast_t1"]
		"traits": state.release_receipts = ["release:fixture"]
		"portals": player.inventory.add("tidewake_portal_key", 1)
		"shrines": state.relics_held = ["meadows"]


func test_every_authored_lesson_waits_for_its_own_unlock_then_is_due_once() -> void:
	var ids: Array = RULES.config().get("lessons", []).map(func(row: Dictionary) -> String: return str(row.id))
	assert_eq(ids, ["home_key", "homestead", "altar", "masters", "feasts", "traits", "portals", "shrines"], "authored lesson set")
	assert_true(RULES.config().get("enabled") == true, "onboarding is enabled")
	for id: String in ids:
		var player := _player()
		for other: String in ids: assert_false(RULES.available(other, player), "%s is not due before any unlock" % other)
		_unlock(player, id)
		for other: String in ids:
			assert_eq(RULES.available(other, player), other == id, "unlocking %s makes only %s available (checked %s)" % [id, id, other])
		assert_eq(str(RULES.due(player).get("id", "")), id, id + " is due once unlocked")
		player.flags.set_flag(RULES.PREFIX + id)
		assert_true(RULES.due(player).is_empty(), id + " is not due again after its lesson receipt")


func test_lessons_unlocking_together_are_offered_in_authored_order() -> void:
	var player := _player()
	for id: String in ["shrines", "portals", "altar"]: _unlock(player, id)
	for id: String in ["altar", "portals", "shrines"]:
		assert_eq(str(RULES.due(player).get("id", "")), id)
		player.flags.set_flag(RULES.PREFIX + id)
	assert_true(RULES.due(player).is_empty())


## F46#1: a capped team's Master line says where, and a held next-realm key
## stays visible as the secondary line (journal how and HUD hint).
func test_capped_master_names_its_place_and_keeps_the_held_key_visible() -> void:
	var player := _player()
	player.flags.set_flag("tournament_entered")
	_unlock(player, "masters")
	_unlock(player, "portals")
	var master := RULES.capped_master(player)
	var row := RULES.guidance(player)
	var place := str(master.author_reference).replace("_", " ").capitalize()
	assert_eq(str(row.get("id", "")), "masters", "the capped Master keeps priority")
	assert_true(str(row.goal).contains(str(master.name) + " at " + place), "goal names the place: " + str(row.goal))
	assert_eq(str(row.get("hint", "")), "Then: Use your Tidewake key at its signed arch in the Crossing Hall.")
	var keyless := _player()
	keyless.flags.set_flag("tournament_entered")
	_unlock(keyless, "masters")
	assert_false(RULES.guidance(keyless).has("hint"), "no key, no secondary line")

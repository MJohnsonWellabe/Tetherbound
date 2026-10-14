extends "res://tests/test_case.gd"
const CHECK := preload("res://tools/earned_saves/wip_fights/feast_receipts.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")

func _before() -> Dictionary:
	return {"character_id": "owner", "party": [{"uid": "mud", "species_id": "mudsnout", "level": 20, "xp": 0}],
		"inventory": [{"id": "feast_t2_ground", "n": 1}, {"id": "heartstone", "n": 1}],
		"redesign_character": {"transaction_receipts": ["existing"], "creatures": {
			"mud": {"breakthroughs": [1], "cap_level": 20, "evolution_choices": {}}}}}

func _after() -> Dictionary:
	var state := _before()
	state.inventory.remove_at(0)
	state.redesign_character.transaction_receipts.append("feast_feed:mud:2")
	state.redesign_character.creatures.mud = {"breakthroughs": [1,2], "cap_level": 30, "evolution_choices": {"2": "stay"}}
	return state

func test_saved_stay_requires_tier_cap_choice_receipt_and_unchanged_xp() -> void:
	var row := {"uid": "mud", "item": "feast_t2_ground", "choice": "stay", "target": "", "choice_required": true}
	assert_true(CHECK.feed_errors(_before(), _after(), row).is_empty())
	for field: String in ["cap_level", "evolution_choices", "breakthroughs"]:
		var changed := _after()
		changed.redesign_character.creatures.mud[field] = _before().redesign_character.creatures.mud[field]
		assert_false(CHECK.feed_errors(_before(), changed, row).is_empty(), field)
	var changed := _after()
	changed.party[0].xp = 1
	assert_false(CHECK.feed_errors(_before(), changed, row).is_empty())
	changed = _after()
	changed.redesign_character.transaction_receipts = ["existing"]
	assert_false(CHECK.feed_errors(_before(), changed, row).is_empty())
	changed = _after()
	changed.inventory = []
	assert_false(CHECK.feed_errors(_before(), changed, row).is_empty(), "feeding cannot charge a second catalyst")

func test_evolve_requires_exact_saved_destination_and_permanent_choice() -> void:
	var before := _before()
	before.inventory[0].id = "feast_t2_ground_heartstone"
	var after := _after()
	after.party[0].species_id = "tuskroot"
	after.redesign_character.creatures.mud.evolution_choices["2"] = "tuskroot"
	var row := {"uid": "mud", "item": "feast_t2_ground_heartstone", "choice": "evolve", "target": "tuskroot", "choice_required": true}
	assert_true(CHECK.feed_errors(before, after, row).is_empty())
	after.redesign_character.creatures.mud.evolution_choices["2"] = "stay"
	assert_false(CHECK.feed_errors(before, after, row).is_empty())

func test_cooking_requires_the_authored_bill_and_character_receipt() -> void:
	var recipe: Dictionary = BREAKTHROUGH.feasts().recipes.feast_t2_ground_heartstone
	var before := _before()
	before.inventory = []
	for id: String in recipe.cost:
		before.inventory.append({"id": id, "n": int(recipe.cost[id])})
	var after := before.duplicate(true)
	after.inventory = [{"id": "feast_t2_ground_heartstone", "n": 1}]
	after.redesign_character.transaction_receipts.append("craft:owner:0123456789abcdef0123456789abcdef")
	assert_true(CHECK.cook_errors(before, after, recipe).is_empty())
	after.inventory.append({"id": "heartstone", "n": 1})
	assert_false(CHECK.cook_errors(before, after, recipe).is_empty(), "catalyst is paid while cooking")
	after.inventory.pop_back()
	after.character_id = "other-owner"
	assert_false(CHECK.cook_errors(before, after, recipe).is_empty())

func test_feed_preserves_other_creatures_and_requires_the_old_cap() -> void:
	var row := {"uid": "mud", "item": "feast_t2_ground", "choice": "stay", "target": "", "choice_required": true}
	var before := _before()
	var after := _after()
	before.redesign_character.creatures.other = {"cap_level": 10, "breakthroughs": [], "evolution_choices": {}}
	after.redesign_character.creatures.other = before.redesign_character.creatures.other.duplicate(true)
	assert_true(CHECK.feed_errors(before, after, row).is_empty())
	after.redesign_character.creatures.other.cap_level = 20
	assert_false(CHECK.feed_errors(before, after, row).is_empty())
	before = _before()
	before.redesign_character.creatures.mud.cap_level = 30
	assert_false(CHECK.feed_errors(before, _after(), row).is_empty())

func test_refine_inventory_rejects_unpaid_or_extra_output() -> void:
	var before := {"inventory": [{"id": "rootstone", "n": 4}, {"id": "ironwood", "n": 2}]}
	var after := {"inventory": [{"id": "rootiron_ingot", "n": 2}]}
	assert_true(CHECK.inventory_matches(before, after, {"rootstone": 4, "ironwood": 2}, {"rootiron_ingot": 2}))
	after.inventory.append({"id": "ironwood", "n": 1})
	assert_false(CHECK.inventory_matches(before, after, {"rootstone": 4, "ironwood": 2}, {"rootiron_ingot": 2}))

func test_feed_compares_full_bystander_mirror_after_exact_authored_refresh() -> void:
	var row := {"uid": "mud", "item": "feast_t2_ground", "choice": "stay", "target": "", "choice_required": true}
	var before := _before()
	var after := _after()
	var bystander := {"uid": "other", "species_id": "mudsnout", "level": 10, "xp": 0, "known_moves": [], "move_mastery_uses": {}}
	before.party.append(bystander.duplicate(true))
	after.party.append(bystander.duplicate(true))
	before.redesign_character.creatures.other = {"cap_level": 10, "breakthroughs": [], "evolution_choices": {}, "taught_traits": {}, "best": false}
	var refreshed := BREAKTHROUGH.refresh_feast_moves([bystander.duplicate(true)], before.redesign_character.duplicate(true))
	after.redesign_character.creatures.other = refreshed.creatures.other.duplicate(true)
	assert_true(CHECK.feed_errors(before, after, row).is_empty(), "exact authored move refresh is legitimate")
	for injected: Dictionary in [{"taught_traits": {"attack": 1}}, {"best": true}, {"mastery": {"root_ram": {"uses": 999, "rank": 3}}}, {"future_progression": 1}]:
		var changed := after.duplicate(true)
		changed.redesign_character.creatures.other.merge(injected, true)
		assert_false(CHECK.feed_errors(before, changed, row).is_empty(), str(injected))
	var cooked := before.duplicate(true)
	cooked.redesign_character.creatures.other.best = true
	assert_false(CHECK.mirror_errors(before, cooked).is_empty(), "cooking cannot change an unselected progression field")

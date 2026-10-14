extends "res://tests/test_case.gd"
const PIECE := preload("res://tools/earned_saves/altar_training_piece.gd")

func _training(level: int = 8) -> Dictionary:
	var party: Array = []
	for index in 5:
		party.append({"uid": "owned%d" % index, "species": "mudsnout", "level": level, "xp": 7,
			"cap_level": 10, "breakthroughs": [], "evolution_choices": {}})
	return {"version": 1, "party": party, "master_wins": [], "feast_recipes": []}

func _case(level: int = 8) -> Dictionary:
	var before := _training(level)
	var after := before.duplicate(true)
	after.party[2].level += 1
	if level == 9: after.party[2].xp = 0
	var receipt := "essence_spend:hero:request:owned2:%d:essence_ground:3:41" % level
	return {"before": before, "after": after, "bag_before": {"essence_ground": 5, "wood": 8},
		"bag_after": {"essence_ground": 2, "wood": 8}, "old": [], "saved": [receipt],
		"event": {"spend_id": "request", "result": {"ok": true, "resolved": true, "saved": true, "durable": true, "receipt": receipt}},
		"intent": {"character_id": "hero", "uid": "owned2", "level": level, "item": "essence_ground", "cost": 3, "revision": 41}}

func _errors(row: Dictionary) -> Array[String]:
	return PIECE.payment_errors(row.before, row.after, row.bag_before, row.bag_after, row.old, row.saved, row.event, row.intent)

func test_payment_preserves_xp_until_cap_and_other_four() -> void:
	assert_true(_errors(_case()).is_empty())
	assert_true(_errors(_case(9)).is_empty())
	var row := _case()
	row.after.party[0].level += 1
	assert_false(_errors(row).is_empty())
	row = _case(9)
	row.after.party[2].xp = 7
	assert_false(_errors(row).is_empty())
	row = _case()
	row.after.party[2].xp = 0
	assert_false(_errors(row).is_empty())

func test_saved_decision_and_new_exact_receipt_are_required() -> void:
	for key: String in ["ok", "resolved", "saved", "durable"]:
		var row := _case()
		row.event.result[key] = false
		assert_false(_errors(row).is_empty(), key)
	for key: String in ["uid", "item", "character_id", "level", "cost", "revision"]:
		var row := _case()
		row.intent[key] = "wrong" if row.intent[key] is String else int(row.intent[key]) + 1
		assert_false(_errors(row).is_empty(), key)
	var row := _case()
	row.old = row.saved.duplicate()
	assert_false(_errors(row).is_empty(), "replayed receipt")
	row = _case()
	row.saved.clear()
	assert_false(_errors(row).is_empty(), "UI success without durable receipt")

func test_exact_inventory_and_training_history_are_required() -> void:
	for item: String in ["wood", "essence_ground"]:
		var row := _case()
		row.bag_after[item] += 1
		assert_false(_errors(row).is_empty(), item)
	for key: String in ["master_wins", "feast_recipes"]:
		var row := _case()
		row.after[key].append("unearned")
		assert_false(_errors(row).is_empty(), key)
	for key: String in ["uid", "species", "cap_level", "breakthroughs", "evolution_choices"]:
		var row := _case()
		row.after.party[2].erase(key)
		assert_false(_errors(row).is_empty(), key)

func test_preflight_refuses_missing_five_and_false_prior_feasts() -> void:
	assert_true(PIECE.preflight(_training(), 1, 2).is_empty())
	assert_false(PIECE.preflight(_training(), 2, 2).is_empty())
	for index in [-1, 5]: assert_false(PIECE.preflight(_training(), 1, index).is_empty())
	var state := _training()
	state.party[4].uid = state.party[0].uid
	assert_false(PIECE.preflight(state, 1, 0).is_empty())
	state = _training()
	state.party.pop_back()
	assert_false(PIECE.preflight(state, 1, 0).is_empty())
	state = _training()
	for card: Dictionary in state.party:
		card.level = 10
		card.xp = 0
		card.cap_level = 20
		card.breakthroughs = [1]
	assert_false(PIECE.preflight(state, 2, 0).is_empty())
	state.master_wins = ["master_t1"]
	state.feast_recipes = ["feast_t1"]
	assert_true(PIECE.preflight(state, 2, 0).is_empty())
	state.party[0].level = 9
	assert_false(PIECE.preflight(state, 2, 0).is_empty(), "prior feast cannot lower the creature below level10")

func test_storage_requests_one_shortfall_and_never_unneeded_alternatives() -> void:
	var payments := [{"id": "essence_ground", "cost": 3}, {"id": "essence_water", "cost": 3}, {"id": "tether_candy", "cost": 1}]
	assert_eq(PIECE.stored_payment(payments, {"essence_ground": 3}, {"tether_candy": 9}), {}, "full bag already funds payment")
	assert_eq(PIECE.stored_payment(payments, {"tether_candy": 1}, {"essence_ground": 9}), {}, "carried candy already funds payment")
	assert_eq(PIECE.stored_payment(payments, {"essence_ground": 1}, {"essence_ground": 2, "tether_candy": 9}), {"essence_ground": 3})
	assert_eq(PIECE.stored_payment(payments, {}, {"essence_ground": 2, "tether_candy": 1}), {"tether_candy": 1})
	assert_eq(PIECE.stored_payment(payments, {}, {"essence_ground": 2, "wood": 99}), {}, "no invented payment from unrelated items")

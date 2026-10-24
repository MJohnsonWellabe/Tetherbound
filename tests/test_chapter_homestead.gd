extends "res://tests/test_case.gd"
const PIECE := preload("res://tools/earned_saves/chapter_homestead.gd")

func _training(tier: int) -> Dictionary:
	var party: Array = []
	var prior: Array = []
	for value in range(1, tier): prior.append(value)
	for index in 5:
		party.append({"uid": "owned%d" % index, "level": tier * 10, "xp": 0,
			"cap_level": tier * 10, "breakthroughs": prior.duplicate()})
	return {"party": party, "master_wins": ["master_t%d" % tier], "feast_recipes": ["feast_t%d" % tier]}

func test_each_chapter_routes_to_its_actual_kitchen_tier() -> void:
	for tier in [3, 4, 5]:
		var job := PIECE.spec("training_t%d_kitchen" % tier)
		assert_eq(job.kitchen, tier - 1)
		assert_true(PIECE.preflight(_training(tier), job, "meadows").is_empty())
	assert_true(PIECE.spec("training_t6_feed").is_empty())
	assert_true(PIECE.spec("training_t3_unknown").is_empty())

func test_feed_refuses_unearned_or_incomplete_cap_preparation() -> void:
	var job := PIECE.spec("training_t3_feed")
	for field: String in ["uid", "level", "xp", "cap_level", "breakthroughs"]:
		var state := _training(3)
		state.party[0].erase(field)
		assert_false(PIECE.preflight(state, job, "meadows").is_empty(), field)
	var state := _training(3)
	state.feast_recipes.clear()
	assert_false(PIECE.preflight(state, job, "meadows").is_empty())
	assert_false(PIECE.preflight(_training(3), job, "water").is_empty())

func test_storage_can_prepare_room_before_recipe_but_requires_master_win() -> void:
	var state := _training(3)
	state.feast_recipes.clear()
	var job := PIECE.spec("training_t3_storage")
	assert_true(PIECE.preflight(state, job, "meadows").is_empty())
	state.master_wins.clear()
	assert_false(PIECE.preflight(state, job, "meadows").is_empty())

func test_feed_requires_exact_tier_for_every_retained_uid() -> void:
	var before := _training(3)
	var after := before.duplicate(true)
	for card: Dictionary in after.party:
		card.cap_level = 40
		card.breakthroughs.append(3)
	var job := PIECE.spec("training_t3_feed")
	assert_true(PIECE.postflight(before, after, job).is_empty())
	for field: String in ["uid", "level", "xp", "cap_level", "breakthroughs"]:
		var changed := after.duplicate(true)
		changed.party[4].erase(field)
		assert_false(PIECE.postflight(before, changed, job).is_empty(), field)
	after.master_wins.clear()
	assert_false(PIECE.postflight(before, after, job).is_empty())

func test_non_feed_steps_cannot_change_training() -> void:
	var before := _training(4)
	var after := before.duplicate(true)
	after.party[0].level += 1
	for phase: String in ["home", "storage", "kitchen", "return", "preparehome", "preparereturn"]:
		assert_false(PIECE.postflight(before, after, PIECE.spec("training_t4_" + phase)).is_empty())

func test_later_altar_slots_require_all_prior_history_and_actual_home() -> void:
	for tier in [3, 4, 5]:
		var state := _training(tier)
		state.master_wins = []
		state.feast_recipes = []
		for prior in range(1, tier):
			state.master_wins.append("master_t%d" % prior)
			state.feast_recipes.append("feast_t%d" % prior)
		for card: Dictionary in state.party:
			card.level = (tier - 1) * 10
		for slot in range(1, 6):
			var job := PIECE.spec("training_t%d_altar_%d" % [tier, slot])
			assert_eq(job.party_index, slot - 1)
			assert_true(PIECE.preflight(state, job, "meadows").is_empty())
			assert_false(PIECE.preflight(state, job, str(job.realm)).is_empty())
			for key: String in ["master_wins", "feast_recipes"]:
				for prior in range(1, tier):
					var missing := state.duplicate(true)
					missing[key].erase("%s_t%d" % ["master" if key == "master_wins" else "feast", prior])
					assert_false(PIECE.preflight(missing, job, "meadows").is_empty())
			var changed := state.duplicate(true)
			changed.party[4].breakthroughs.pop_back()
			assert_false(PIECE.preflight(changed, job, "meadows").is_empty())
	for segment: String in ["training_t3_altar", "training_t3_altar_0", "training_t3_altar_6",
			"training_t3_altar_01", "training_t3_feed_1", "training_t2_altar_1"]:
		assert_true(PIECE.spec(segment).is_empty(), segment)

func test_preparation_travel_precedes_current_master_but_requires_prior_history() -> void:
	for tier in [3, 4, 5]:
		var state := _training(tier)
		state.master_wins.clear()
		state.feast_recipes.clear()
		for prior in range(1, tier):
			state.master_wins.append("master_t%d" % prior)
			state.feast_recipes.append("feast_t%d" % prior)
		var home := PIECE.spec("training_t%d_preparehome" % tier)
		var outbound := PIECE.spec("training_t%d_preparereturn" % tier)
		assert_true(PIECE.preflight(state, home, str(home.realm)).is_empty())
		assert_true(PIECE.preflight(state, outbound, "meadows").is_empty())
		assert_false(PIECE.preflight(state, home, "meadows").is_empty())
		assert_false(PIECE.preflight(state, outbound, str(outbound.realm)).is_empty())
		assert_false(PIECE.preflight(state, PIECE.spec("training_t%d_home" % tier), str(home.realm)).is_empty())
		state.party[4].level -= 1
		assert_true(PIECE.preflight(state, home, str(home.realm)).is_empty())
		assert_false(PIECE.preflight(state, outbound, "meadows").is_empty())
		state.master_wins.erase("master_t1")
		assert_false(PIECE.preflight(state, home, str(home.realm)).is_empty())

func test_return_arch_requires_saved_open_state_not_a_second_key() -> void:
	var portal := preload("res://tests/helpers/f49_portal_travel.gd")
	assert_true(portal.return_view_valid({"ready": true, "open": true, "character_open": true, "has_key": false}))
	assert_true(portal.return_view_valid({"ready": true, "open": true, "character_open": true, "has_key": true}))
	assert_false(portal.return_view_valid({"ready": true, "character_open": false, "has_key": true}))
	assert_false(portal.return_view_valid({"ready": false, "character_open": true}))
	assert_false(portal.return_view_valid({"ready": true}))
	assert_false(portal.return_view_valid({"ready": true, "open": false, "character_open": true}))

func test_preparation_requires_exact_immediate_saved_piece() -> void:
	var source := "0123456789abcdef0123456789abcdef01234567"
	for tier in [3, 4, 5]:
		var prefix := "training_t%d_" % tier
		var sequence: Array[String] = [prefix + "preparehome"]
		for slot in range(1, 6): sequence.append(prefix + "altar_%d" % slot)
		sequence.append(prefix + "preparereturn")
		for index in range(1, sequence.size()):
			var segment := sequence[index]
			assert_eq(PIECE.predecessor(segment), sequence[index - 1])
			var prior := {"passed": true, "segment": sequence[index - 1], "commit": source,
				"after": {"uids": [], "flags": [], "items": {}, "realm": "meadows", "training": _training(tier)}}
			assert_eq(PIECE.predecessor_error(segment, prior, source), "")
			for wrong: String in [segment, "training_t2_feed", "training_t%d_altar_5" % (tier + 1)]:
				var changed := prior.duplicate(true)
				changed.segment = wrong
				assert_false(PIECE.predecessor_error(segment, changed, source).is_empty())
			if index > 1:
				var base := prior.duplicate(true)
				base.segment = sequence[0]
				assert_false(PIECE.predecessor_error(segment, base, source).is_empty(), "cannot reuse preparehome base")
			for key: String in ["uids", "flags", "items", "realm", "training"]:
				var changed := prior.duplicate(true)
				changed.after.erase(key)
				assert_false(PIECE.predecessor_error(segment, changed, source).is_empty())
			for invalid: Variant in [null, {}, {"passed": false}, {"passed": "true"}]:
				assert_false(PIECE.predecessor_error(segment, invalid, source).is_empty())
			for invalid: Variant in [null, {}, []]:
				var changed := prior.duplicate(true)
				changed.after.training = invalid
				assert_false(PIECE.predecessor_error(segment, changed, source).is_empty())
			for wrong: String in ["", "unknown", "f".repeat(40)]:
				assert_false(PIECE.predecessor_error(segment, prior, wrong).is_empty())
			var unbound := prior.duplicate(true)
			unbound.erase("commit")
			assert_false(PIECE.predecessor_error(segment, unbound, source).is_empty())
			# An unrelated PASS at the same state/source is not this edge.
			unbound = prior.duplicate(true)
			unbound.segment = "05_tidal"
			assert_false(PIECE.predecessor_error(segment, unbound, source).is_empty())
			prior["input_mode"] = "generated_ancestry"
			assert_eq(PIECE.predecessor_error(segment, prior, source), "")
			assert_eq(prior.input_mode, "generated_ancestry", "dependency validation must not promote ancestry")
			prior.after.realm = "cloudreach"
			assert_false(PIECE.predecessor_error(segment, prior, source).is_empty())
		assert_eq(PIECE.predecessor(prefix + "preparehome"), "")
		assert_eq(PIECE.predecessor(prefix + "storage"), "")

## Meadows T2 (coordinator ruling 23 Oct, generated meadows_t2_independent):
## Mira's chest ends north of the Old Mill Crossing; the Home Key brings the
## team home for a tier-1 Kitchen and the feast_t2 feed. No portal leg.
func test_meadows_t2_runs_home_kitchen_feed_without_a_portal_leg() -> void:
	var kitchen := PIECE.spec("training_t2_kitchen")
	assert_eq(kitchen.kitchen, 1)
	assert_eq(kitchen.realm, "meadows")
	assert_true(PIECE.preflight(_training(2), kitchen, "meadows").is_empty())
	assert_true(PIECE.preflight(_training(2), PIECE.spec("training_t2_home"), "meadows").is_empty())
	assert_true(PIECE.preflight(_training(2), PIECE.spec("training_t2_feed"), "meadows").is_empty())
	for phase: String in ["return", "preparehome", "preparereturn", "altar_1"]:
		assert_true(PIECE.spec("training_t2_" + phase).is_empty(), phase)

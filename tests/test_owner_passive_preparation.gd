extends "res://tests/test_case.gd"

## Pure exact-input replay and the real authority CAS. Fixtures disclose the
## retained source and trusted host context; no transport or actual save proof.
const PREP := preload("res://scripts/net/owner_passive_preparation.gd")
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const AUTH := preload("res://scripts/net/character_authority.gd")
const FIXTURE := preload("res://tests/test_research_passive_preparation.gd")
const GROOM := preload("res://tests/test_den_groom_saved_transaction.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const E := preload("res://scripts/creatures/essence.gd")

func _capture_event() -> Dictionary:
	var creature := preload("res://scripts/creatures/creature_species.gd").spawn("mosshell")
	var traits := preload("res://scripts/creatures/traits.gd").roll_spawn("resource-namespace", "checkpoint-caught-source", 1, true, false, false)
	var offer := {"offer_id": "checkpoint-catch", "source_key": "capture:checkpoint-catch",
		"world_namespace": "resource-namespace", "session_id": "original-epoch", "participants": [DATA.CHARACTER],
		"realm": "meadows", "creature": preload("res://scripts/save/water_capture_codec.gd").encode(creature), "capture_traits": traits}
	var duty := {"character_id": DATA.CHARACTER, "action": "capture_offer", "intent": {}, "context": offer}
	return preload("res://scripts/net/foundation_event.gd").make(DATA.new()._world(), "original-epoch", offer.source_key, [duty])

func _fixture() -> Dictionary:
	var before: Dictionary = GROOM.new()._before()
	var cursor := REPLAY.begin(before, {"meadows": ["admitted_history"]})
	var uids: Array = []
	for card: Dictionary in before.party: uids.append(card.uid)
	var replay := REPLAY.apply(cursor, {"version": 1, "sequence": 1, "op": "condition", "delta": 0.016666666666667, "uids": uids},
		{"max_elapsed": 1.0, "max_speed": 20.0, "realm": "meadows", "landmarks": {}})
	assert_true(replay.ok)
	var event: Dictionary = FIXTURE.new()._event()
	var prepared := PREP.make(event, event.duties[0], before, 0, "current-epoch", replay.cursor, DATA.TXN)
	assert_false(prepared.is_empty())
	var authority := AUTH.new()
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(authority.seed_discovered_landmarks(DATA.CHARACTER, cursor.discovered))
	return {"before": before, "cursor": replay.cursor, "event": event, "prepared": prepared, "authority": authority}

func test_owner_requires_full_exact_checkpoint_and_original_source() -> void:
	var f := _fixture()
	assert_true(PREP.make(f.event, f.event.duties[0], f.before, 0, "current-epoch", {"state": 4, "discovered": []}, DATA.TXN).is_empty())
	assert_true(PREP.valid_host(f.prepared, f.event, f.cursor))
	assert_true(PREP.owner_plan(f.prepared.after, f.prepared, f.event, f.prepared.discoveries).ok)
	assert_false(PREP.owner_plan(f.before, f.prepared, f.event, f.prepared.discoveries).ok, "owner must already match; preparation never installs care")
	var changed: Dictionary = f.prepared.after.duplicate(true)
	changed.party[0].distance_m_together += 0.000001
	assert_false(PREP.owner_plan(changed, f.prepared, f.event, f.prepared.discoveries).ok)
	assert_false(PREP.owner_plan(f.prepared.after, f.prepared, f.event, {}).ok, "discovery checkpoint is exact too")
	var other: Dictionary = f.event.duplicate(true)
	other.duties[0].context.species_id = "mudsnout"
	assert_false(PREP.valid(f.prepared, other))
	for field: String in ["final_sequence", "input_prefix_hash", "after"]:
		var candidate: Dictionary = f.prepared.duplicate(true)
		if field == "final_sequence": candidate.final_sequence += 1
		elif field == "input_prefix_hash": candidate.input_prefix_hash = "a".repeat(64)
		else: candidate.after.party[0].happiness -= 0.000001
		candidate.hash = PREP.preparation_hash(candidate)
		assert_false(PREP.valid_host(candidate, f.event, f.cursor), field)
	var large := {"landmarks_visited_together": 9007199254740992}
	var next := {"landmarks_visited_together": 9007199254740993}
	assert_false(PREP.exact(large, next), "full checkpoint preserves distinct int64 counters")

func test_reservation_requires_local_cursor_and_same_existing_lock() -> void:
	var f := _fixture()
	var authority: RefCounted = f.authority
	assert_false(authority.reserve_research_preparation(DATA.CHARACTER, f.prepared, f.event), "a valid owner packet has no host cursor capability")
	assert_false(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, f.event, {}))
	assert_false(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_true(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, f.event, f.cursor))
	assert_true(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, f.event, f.cursor))
	assert_true(authority.creature_training_is_pending(DATA.CHARACTER))
	assert_eq(authority.revision(DATA.CHARACTER), 0)
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), f.before))
	assert_eq(authority.stage_portal_debit(DATA.CHARACTER, "water", "unused").code, "transaction_busy")
	assert_false(authority.bind_world("another-world"))
	assert_false(authority.cancel_owner_passive_checkpoint(DATA.CHARACTER, "foreign"))
	for lock: String in ["_training_stages", "_training_pending", "_portal_stages", "_loadout_pending", "_vitals_pending", "_vitals_stages", "_groom_preparations"]:
		var separate := _fixture()
		separate.authority.set(lock, {DATA.CHARACTER: {"fixture": true}})
		assert_false(separate.authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, separate.prepared, separate.event, separate.cursor), lock)

func test_exact_cas_retry_after_failed_real_research_stage_and_stale_ack() -> void:
	var f := _fixture()
	var authority: RefCounted = f.authority
	assert_true(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, f.event, f.cursor))
	# Test models an authenticated successful owner save at this call boundary.
	assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_eq(authority.revision(DATA.CHARACTER), 1)
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), f.prepared.after))
	assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	var context: Dictionary = f.event.duties[0].context.duplicate(true)
	context.character_id = DATA.CHARACTER
	context.expected_revision = 1
	context.in_range = true
	var stage: Dictionary = authority.stage_character_action(DATA.CHARACTER, 1, "research_event", {}, context)
	assert_true(stage.get("ok") == true, str(stage))
	if stage.get("ok") != true: return
	assert_false(authority.retain_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_true(authority.finish_creature_training(stage, false))
	assert_true(authority.retain_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_eq(authority.revision(DATA.CHARACTER), 1, "original prefix applied only once")
	assert_true(authority.cancel_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_false(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), f.prepared.after), "cancel never rolls back saved checkpoint")

func test_capture_checkpoint_binds_original_offer_without_granting_its_creature() -> void:
	var f := _fixture()
	var capture := _capture_event()
	assert_false(capture.is_empty())
	var offer: Dictionary = capture.duties[0].context.duplicate(true)
	var original_offer := var_to_bytes(offer)
	var capture_rules := preload("res://scripts/net/foundation_capture_rules.gd")
	var original_catch: Dictionary = offer.creature.duplicate(true)
	original_catch.traits_initialized = true
	original_catch.rolled_traits = offer.capture_traits.rolled_traits.duplicate()
	original_catch.taught_traits = offer.capture_traits.taught_traits.duplicate(true)
	original_catch.captured_from = offer.capture_traits.captured_from.duplicate(true)
	assert_true(capture_rules.original_offer_matches(offer, original_catch, "resource-namespace", "original-epoch", "meadows", DATA.CHARACTER))
	for wrong: Array in [["wrong-world", "original-epoch", "meadows", DATA.CHARACTER],
		["resource-namespace", "wrong-epoch", "meadows", DATA.CHARACTER],
		["resource-namespace", "original-epoch", "water", DATA.CHARACTER],
		["resource-namespace", "original-epoch", "meadows", "another-character"]]:
		assert_false(capture_rules.original_offer_matches(offer, original_catch, wrong[0], wrong[1], wrong[2], wrong[3]), "ordinary offer cannot change its frozen owner/world/epoch/realm")
	var altered_catch := original_catch.duplicate(true)
	altered_catch.hp = float(altered_catch.hp) - 1.0
	assert_false(capture_rules.original_offer_matches(offer, altered_catch, "resource-namespace", "original-epoch", "meadows", DATA.CHARACTER), "ordinary offer retains every original caught-card field")
	altered_catch = original_catch.duplicate(true)
	altered_catch.captured_from.spawn_generation += 1
	assert_false(capture_rules.original_offer_matches(offer, altered_catch, "resource-namespace", "original-epoch", "meadows", DATA.CHARACTER), "ordinary offer retains its original spawn generation")
	assert_eq(var_to_bytes(offer), original_offer, "offer binding validation never rewrites the original")
	var context := offer.duplicate(true)
	context.merge({"character_id": DATA.CHARACTER, "expected_revision": 0, "in_range": true, "in_combat": false})
	var kept := preload("res://scripts/net/foundation_capture_rules.gd").stage(f.before,
		{"offer_id": offer.offer_id, "keep": true, "released_uid": ""}, context)
	assert_true(kept.get("ok") == true, "original capture stages on the admitted carrier")
	if kept.get("ok") == true:
		assert_false(kept.state.party.back().has("energy"), "newcomer uses the durable portable card")
		assert_true(PREP.exact(kept.state, preload("res://scripts/net/character_record_rules.gd").portable_projection(kept.state)),
			"capture after carrier agrees with the owner install projection")
	assert_eq(var_to_bytes(offer), original_offer, "staging never rewrites the original host offer")
	var prepared := PREP.make(capture, capture.duties[0], f.before, 0, "current-epoch", f.cursor, DATA.TXN)
	assert_false(prepared.is_empty())
	assert_true(PREP.valid_host(prepared, capture, f.cursor))
	assert_eq(prepared.after.party.size(), f.before.party.size(), "checkpoint changes no roster; original capture handler owns the later choice")
	assert_true(PREP.exact(prepared.after, f.cursor.state))
	assert_true(f.authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, prepared, capture, f.cursor))
	assert_true(f.authority.commit_owner_passive_checkpoint(DATA.CHARACTER, prepared.hash))
	assert_eq(f.authority.state(DATA.CHARACTER).party.size(), f.before.party.size())
	var substituted := capture.duplicate(true)
	substituted.duties[0].context.creature.nickname = "changed after preparation"
	assert_false(PREP.valid(prepared, substituted), "full retained creature offer remains immutable")
	var selected := capture.duplicate(true)
	selected.duties[0].intent = {"offer_id": "checkpoint-catch", "keep": true, "released_uid": ""}
	assert_true(PREP.make(selected, selected.duties[0], f.before, 0, "current-epoch", f.cursor, DATA.TXN).is_empty(),
		"capture choice must not rewrite the original empty-intent offer duty")
	var unsupported := capture.duplicate(true)
	unsupported.duties[0].action = "wild_capture"
	assert_true(PREP.make(unsupported, unsupported.duties[0], f.before, 0, "current-epoch", f.cursor, DATA.TXN).is_empty())
	# The original capture stays visible until its ACK, but replacing the
	# accepted journal with a later pending Altar must not present it again.
	# Reuse the existing detached Session seam; these are real row/ledger
	# transitions, not a disk-save or physical input proof.
	const RECORD := preload("res://scripts/net/character_record_rules.gd")
	const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
	const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
	const TEACHING := preload("res://scripts/creatures/teaching.gd")
	const PROGRESSION := preload("res://scripts/creatures/progression.gd")
	var game := preload("res://autoload/game_state.gd").new()
	game.local = GROOM.new()._player()
	game.world = DATA.new()._world()
	game.world.reward_deliveries[capture.delivery_id] = capture.duplicate(true)
	var cfg := E.config()
	game.local.inventory.add(str(cfg.tether_candy_item), int(cfg.tether_candy_cost))
	var session := preload("res://tests/test_foundation_resource_save.gd").FixtureSession.new()
	session.fixture = game
	game.add_child(session)
	var composition := Node.new()
	session.add_child(composition)
	var adapter := preload("res://scripts/net/foundation_capture.gd").new()
	composition.add_child(adapter)
	context.foundation_runtime_authorized = true
	var choice := {"offer_id": offer.offer_id, "keep": true, "released_uid": ""}
	var proposal := ACTIONS.stage(RECORD.portable_projection(game.local.save_data()), 0, "wild_capture", choice, context, RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	proposal.character_revision = 1
	var row := DELIVERY.make_record(game.world.world_id, game.world.reward_delivery_namespace, "current-epoch", proposal, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty():
		game.free()
		return
	var ledger := preload("res://scripts/net/world_ledger.gd").new(game.world)
	assert_true(ledger.commit_creature_training_delivery(row, 1).ok)
	assert_eq(adapter._offer(), offer, "the original unsaved capture remains offered")
	game.local.load_data(row.after)
	assert_eq(adapter._offer(), offer, "owner receipt alone never substitutes for original host ACK")
	assert_true(ledger.accept_creature_training_delivery(row.delivery_id, DATA.CHARACTER, int(row.journal_revision), row.receipt, 1).ok)
	row = game.world.reward_deliveries[row.delivery_id].duplicate(true)
	assert_true(adapter._offer().is_empty(), "the accepted original decision is hidden")
	var initial := RECORD.portable_projection(game.local.save_data())
	var spend := {"spend_id": "capture-later-altar", "creature_uid": initial.party[0].uid,
		"expected_level": initial.party[0].level, "payment_item": str(cfg.tether_candy_item), "expected_character_revision": 1}
	var altar := E.stage_core_spend(initial, DATA.CHARACTER, 1, spend, cfg,
		PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	assert_true(altar.get("ok") == true, str(altar))
	altar.merge({"character_id": DATA.CHARACTER, "character_revision": 2, "action": "altar_spend",
		"action_id": spend.spend_id, "intent": spend})
	var later := E.next_training_delivery(game.world.world_id, game.world.reward_delivery_namespace, "current-epoch", altar,
		row, cfg, PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	assert_false(later.is_empty())
	if later.is_empty():
		game.free()
		return
	assert_true(ledger.commit_creature_training_delivery(later, 1).ok)
	var frozen_journal := var_to_bytes(game.world.reward_deliveries)
	var frozen_owner := var_to_bytes(game.local.save_data())
	assert_true(adapter._offer().is_empty(), "a later pending Altar cannot resurrect an accepted catch")
	assert_eq(adapter._offer(offer.offer_id, true), offer, "original reconciliation still reads the retained offer")
	assert_eq(var_to_bytes(game.world.reward_deliveries), frozen_journal, "presentation never edits the journal")
	assert_eq(var_to_bytes(game.local.save_data()), frozen_owner, "presentation never grants or changes the owner")
	game.local.redesign_character.transaction_receipts.erase(row.receipt)
	assert_eq(adapter._offer(), offer, "the live owner's exact original receipt is required")
	game.local.redesign_character.transaction_receipts.append(row.receipt)
	for field: String in ["before", "after", "character_id", "world_id", "world_namespace", "journal_revision"]:
		var changed: Dictionary = later.duplicate(true)
		if field in ["before", "after"]: changed[field].redesign_character.transaction_receipts.erase(row.receipt)
		elif field == "journal_revision": changed[field] = 1
		else: changed[field] = "foreign"
		game.world.reward_deliveries[later.delivery_id] = changed
		assert_eq(adapter._offer(), offer, "changed/foreign pending history cannot hide the catch: " + field)
	game.world.reward_deliveries[later.delivery_id] = later.duplicate(true)
	assert_true(ledger.accept_creature_training_delivery(later.delivery_id, DATA.CHARACTER, int(later.journal_revision), later.receipt, 1).ok)
	assert_true(adapter._offer().is_empty(), "ordinary later ACK preserves original accepted suppression")
	assert_eq(var_to_bytes(capture.duties[0].context), original_offer)
	game.free()

func _action_fixture() -> Dictionary:
	var player: RefCounted = GROOM.new()._player()
	var cfg: Dictionary = E.config()
	player.inventory.add(str(cfg.tether_candy_item), int(cfg.tether_candy_cost))
	var before: Dictionary = preload("res://scripts/net/character_record_rules.gd").portable_projection(player.save_data())
	var cursor := REPLAY.begin(before, {})
	var applied := REPLAY.apply(cursor, {"version": 1, "sequence": 1, "op": "condition", "delta": 0.1,
		"uids": [before.party[0].uid]}, {"max_elapsed": 1.0, "max_speed": 20.0, "realm": "meadows", "landmarks": {}})
	assert_true(applied.ok)
	var request := {"op": "altar_spend", "session_epoch": "current-epoch", "world_namespace": "resource-namespace",
		"character_id": DATA.CHARACTER, "station_key": "altar:meadows:actual",
		"intent": {"spend_id": "checkpoint-spend", "creature_uid": before.party[0].uid,
			"expected_level": before.party[0].level, "payment_item": str(cfg.tether_candy_item), "expected_character_revision": 0}}
	var context := {"character_id": DATA.CHARACTER, "expected_revision": 0, "source_key": request.station_key,
		"station_id": "altar", "actual_altar": true, "in_range": true, "in_combat": false, "foundation_runtime_authorized": true}
	var prepared := PREP.make_action(request, context, before, 0, "current-epoch", "resource-slot", applied.cursor, DATA.TXN, "altar_spend")
	assert_false(prepared.is_empty())
	var authority := AUTH.new()
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	return {"before": before, "cursor": applied.cursor, "request": request, "context": context, "prepared": prepared, "authority": authority}

func test_request_codec_preserves_distinct_authenticated_source_kinds_and_exact_owner_state() -> void:
	var f := _action_fixture()
	assert_true(PREP.valid_action_host(f.prepared, f.cursor))
	assert_false(PREP.valid(f.prepared, {}), "a request never pretends to be a retained event")
	assert_true(PREP.owner_plan(f.cursor.state, f.prepared, {}, {}).ok)
	assert_false(PREP.owner_plan(f.before, f.prepared, {}, {}).ok)
	var changed: Dictionary = f.prepared.duplicate(true)
	changed.request.intent.expected_level += 1
	changed.hash = PREP.preparation_hash(changed)
	assert_false(PREP.valid_action(changed), "original request hash binds the full quote")
	changed = f.prepared.duplicate(true)
	changed.after.party[0].xp += 1
	changed.hash = PREP.preparation_hash(changed)
	assert_false(PREP.valid_action(changed), "request checkpoint cannot grant progression")
	var request: Dictionary = f.request.duplicate(true)
	request.op = "station_craft"
	request.revision = 0
	request.intent = {"recipe_id": "fixture-recipe", "craft_id": DATA.TXN}
	for action: String in ["station_craft", "feast_cook", "feast_feed", "relic_hang"]:
		request.op = action
		assert_false(PREP.make_action(request, f.context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN).is_empty(), action)
	request.op = "arbitrary_action"
	assert_true(PREP.make_action(request, f.context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN).is_empty())
	var chest := request.duplicate(true)
	chest.op = "master_chest"
	chest.station_key = "master:meadows_master"
	chest.intent = {"master_id": "meadows_master"}
	var chest_context: Dictionary = f.context.duplicate(true)
	chest_context.source_key = "master_chest:meadows_master"
	chest_context.master_id = "meadows_master"
	assert_false(PREP.make_action(chest, chest_context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN).is_empty(), "actual request station and canonical chest source have distinct exact prefixes")
	chest_context.master_id = "another_master"
	assert_true(PREP.make_action(chest, chest_context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN).is_empty())
	request.op = "refine_start"
	request.revision = -1
	request.intent = {"recipe_id": "fixture-recipe", "amount": 1}
	var context: Dictionary = f.context.duplicate(true)
	assert_true(PREP.make_action(request, context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "manual_refine").is_empty())
	context.merge({"completed_manual_refine": true, "manual_unit_ticket": DATA.TXN,
		"manual_unit_plan": {"recipe_id": "fixture-recipe", "fixture": "host-verified-completed-unit"}})
	assert_false(PREP.make_action(request, context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "manual_refine").is_empty())
	request = f.request.duplicate(true)
	request.op = "altar_trait"
	request.intent = {"action_id": DATA.TXN, "action": "release", "creature_uid": f.before.party[0].uid,
		"trait_id": "", "slot": -1, "payment_item": "", "expected_character_revision": 0}
	assert_false(PREP.make_action(request, f.context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "altar_traits").is_empty())
	request.intent.expected_character_revision = 1
	assert_true(PREP.make_action(request, f.context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "altar_traits").is_empty())
	var clock_context: Dictionary = preload("res://tests/test_bounty_board.gd").new()._context(f.before, 0, 1, "resource-namespace")
	clock_context.source_key = "halda_bounty_clock"
	var clock_source := PREP.bounty_rotation_source(clock_context, "resource-slot", "current-epoch")
	var clock_prepared := PREP.make_action(clock_source, clock_context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "bounty_rotation")
	assert_false(clock_prepared.is_empty())
	assert_true(PREP.valid_action_host(clock_prepared, f.cursor))
	assert_false(PREP.valid(clock_prepared, {}), "the clock never fabricates a retained reward")
	assert_true(PREP.owner_plan(f.cursor.state, clock_prepared, {}, {}).ok)
	assert_false(PREP.owner_plan(f.before, clock_prepared, {}, {}).ok, "care must be the complete exact replay")
	assert_true(PREP.make_action(clock_source, clock_context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN).is_empty(),
		"a host clock descriptor cannot be used as a player request")
	for field: String in ["session_epoch", "world_id", "world_namespace", "character_id", "host_day", "host_unlocks"]:
		var foreign: Dictionary = clock_source.duplicate(true)
		foreign[field] = 2 if field == "host_day" else (["tidewake"] if field == "host_unlocks" else "foreign")
		assert_true(PREP.make_action(foreign, clock_context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "bounty_rotation").is_empty(), field)
	var non_clock: Dictionary = clock_source.duplicate(true)
	non_clock["intent"] = {"elapsed": 100}
	assert_true(PREP.make_action(non_clock, clock_context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "bounty_rotation").is_empty())
	# Extend this existing codec proof with the real board's unchanged -1
	# request. Detached inventory/board setup is unit input, not gameplay proof.
	const BOARD := preload("res://scripts/world/bounty_board.gd")
	const BAG := preload("res://scripts/world/death_satchel_rules.gd")
	var board_before: Dictionary = f.before.duplicate(true)
	board_before.redesign_character.bounties = preload("res://tests/test_bounty_board.gd").new()._issued().redesign_character.bounties.duplicate(true)
	board_before.redesign_character.bounties.anchor_world = "resource-namespace"
	var material := BOARD.template("meadows_material_delivery")
	var bag := BAG.inventory_from(board_before.inventory)
	assert_true(BAG.give_stack(bag, {"id": material.item, "n": int(material.count)}))
	board_before.inventory = BAG.slots(bag)
	var board_cursor: Dictionary = REPLAY.apply(REPLAY.begin(board_before, {}), {"version": 1, "sequence": 1, "op": "condition", "delta": 0.1,
		"uids": [board_before.party[0].uid]}, {"max_elapsed": 1.0, "max_speed": 20.0, "realm": "meadows", "landmarks": {}}).cursor
	var claim := {"op": "bounty_claim", "session_epoch": "current-epoch", "world_namespace": "resource-namespace",
		"character_id": DATA.CHARACTER, "station_key": "halda_bounty_board", "intent": {"instance": "delivery".sha256_text()}, "revision": -1}
	var claim_bytes := var_to_bytes(claim)
	var claim_context: Dictionary = preload("res://tests/test_bounty_board.gd").new()._context(board_before, 0, 1, "resource-namespace")
	var claim_prepared := PREP.make_action(claim, claim_context, board_before, 0, "current-epoch", "resource-slot", board_cursor, DATA.TXN)
	assert_false(claim_prepared.is_empty())
	assert_true(PREP.valid_action_host(claim_prepared, board_cursor))
	assert_true(PREP.owner_plan(board_cursor.state, claim_prepared, {}, {}).ok)
	assert_false(PREP.owner_plan(board_before, claim_prepared, {}, {}).ok)
	assert_eq(var_to_bytes(claim), claim_bytes, "checkpoint never rewrites the original sentinel quote")
	for field: String in ["session_epoch", "world_namespace", "character_id", "station_key", "revision", "intent"]:
		var forged_claim: Dictionary = claim.duplicate(true)
		forged_claim[field] = 0 if field == "revision" else ({"instance": "foreign".sha256_text()} if field == "intent" else "foreign")
		assert_true(PREP.make_action(forged_claim, claim_context, board_before, 0, "current-epoch", "resource-slot", board_cursor, DATA.TXN).is_empty(), field)
	for field: String in ["character_id", "expected_revision", "source_key", "in_range", "in_combat", "world_namespace", "clock_confirmed"]:
		var forged_context: Dictionary = claim_context.duplicate(true)
		forged_context[field] = 1 if field == "expected_revision" else (true if field == "in_combat" else (false if field in ["in_range", "clock_confirmed"] else "foreign"))
		assert_true(PREP.make_action(claim, forged_context, board_before, 0, "current-epoch", "resource-slot", board_cursor, DATA.TXN).is_empty(), field)
	var extra_claim: Dictionary = claim.duplicate(true)
	extra_claim.intent["day"] = 1
	assert_true(PREP.make_action(extra_claim, claim_context, board_before, 0, "current-epoch", "resource-slot", board_cursor, DATA.TXN).is_empty(), "owner cannot add a clock to the one-field intent")
	var paid := BOARD.stage(board_cursor.state, 0, "bounty_claim", claim.intent, claim_context)
	assert_true(paid.ok)
	assert_true(PREP.make_action(claim, claim_context, paid.state, 0, "current-epoch", "resource-slot", REPLAY.begin(paid.state, {}), DATA.TXN).is_empty(), "paid instance cannot prepare a new claim")
	var poor: Dictionary = board_before.duplicate(true)
	poor.inventory = BAG.slots(BAG.inventory_from([]))
	assert_true(PREP.make_action(claim, claim_context, poor, 0, "current-epoch", "resource-slot", REPLAY.begin(poor, {}), DATA.TXN).is_empty(), "missing materials refuse before any checkpoint")

func test_request_cas_preserves_quote_then_original_altar_stage_advances_once_and_retries() -> void:
	const TEACHING := preload("res://scripts/creatures/teaching.gd")
	const PROGRESSION := preload("res://scripts/creatures/progression.gd")
	var f := _action_fixture()
	var authority: RefCounted = f.authority
	var original_request: PackedByteArray = var_to_bytes(f.request)
	assert_false(authority.reserve_research_preparation(DATA.CHARACTER, f.prepared, {}), "packet alone has no local replay capability")
	assert_true(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, {}, f.cursor))
	assert_eq(authority.stage_portal_debit(DATA.CHARACTER, "water", "unused").code, "transaction_busy")
	assert_false(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, "a".repeat(64)))
	assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_eq(authority.revision(DATA.CHARACTER), 0, "passive CAS preserves the original quoted transaction revision")
	assert_true(PREP.exact(authority.state(DATA.CHARACTER), f.cursor.state))
	for attempt: int in range(2):
		assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
		var proposal := E.stage_core_spend(authority.state(DATA.CHARACTER), DATA.CHARACTER, 0, f.request.intent,
			E.config(), PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
		assert_true(proposal.get("ok") == true, str(proposal))
		if proposal.get("ok") != true: return
		var stage: Dictionary = authority.stage_creature_training(DATA.CHARACTER, "altar_spend", f.request.intent.spend_id,
			0, f.request.intent, authority.state(DATA.CHARACTER), proposal.state, proposal.receipt)
		assert_true(stage.get("ok") == true, str(stage))
		if stage.get("ok") != true: return
		assert_eq(authority.revision(DATA.CHARACTER), 1)
		var row := E.next_training_delivery("resource-slot", "resource-namespace", "current-epoch", stage,
			null, E.config(), PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
		assert_false(row.is_empty(), "original immutable v1 journal validates unchanged quoted intent")
		assert_eq(var_to_bytes(f.request), original_request)
		if attempt == 0:
			assert_true(authority.finish_creature_training(stage, false))
			assert_eq(authority.revision(DATA.CHARACTER), 0)
			assert_true(PREP.exact(authority.state(DATA.CHARACTER), f.cursor.state))
			assert_true(authority.retain_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
		else:
			assert_true(authority.finish_creature_training(stage, true))
			assert_true(authority.cancel_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
			assert_false(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
			assert_eq(authority.revision(DATA.CHARACTER), 1)

func test_same_revision_request_checkpoint_rejects_stale_before_and_other_transaction_locks() -> void:
	var f := _action_fixture()
	assert_true(f.authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, {}, f.cursor))
	assert_true(f.authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_true(f.authority.cancel_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_eq(f.authority.revision(DATA.CHARACTER), 0)
	assert_false(f.authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, {}, f.cursor), "same revision never permits a stale full-record baseline")
	for lock: String in ["_training_stages", "_training_pending", "_portal_stages", "_loadout_pending", "_vitals_pending", "_vitals_stages", "_groom_preparations"]:
		var separate := _action_fixture()
		separate.authority.set(lock, {DATA.CHARACTER: {"fixture": true}})
		assert_false(separate.authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, separate.prepared, {}, separate.cursor), lock)

func _waystone_parts(f: Dictionary) -> Dictionary:
	var envelope := {"request_id": "current-epoch:7", "session_epoch": "current-epoch",
		"world_instance_id": "resource-namespace", "character_id": DATA.CHARACTER,
		"payload": {"kind": "waystone_touch", "waystone_id": "meadows_trail_camp"}}
	var context := {"character_id": DATA.CHARACTER, "expected_revision": 0, "in_range": true, "in_combat": false,
		"foundation_runtime_authorized": true, "validated_touch": true, "source_key": "waystone:meadows_trail_camp",
		"touch_id": DATA.TXN, "realm": "meadows", "world_namespace": "resource-namespace"}
	return {"request": PREP.waystone_request(envelope), "context": context}

func test_waystone_touch_request_binds_its_own_envelope_and_frozen_host_context() -> void:
	# F18: a guest's waystone touch is frozen/replayed like every other owner
	# request, so its staged before is the owner's own drifted baseline.
	var f := _action_fixture()
	var parts := _waystone_parts(f)
	var prepared := PREP.make_action(parts.request, parts.context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "waystone_touch")
	assert_false(prepared.is_empty(), "the exact touch envelope and host context prepare")
	assert_true(PREP.valid_action_host(prepared, f.cursor))
	assert_true(PREP.owner_plan(f.cursor.state, prepared, {}, {}).ok, "the owner's replayed state is the baseline")
	assert_false(PREP.owner_plan(f.before, prepared, {}, {}).ok, "a stale owner record is still refused")
	var conflicting: Dictionary = f.cursor.state.duplicate(true)
	conflicting.party[0].xp += 1
	assert_false(PREP.owner_plan(conflicting, prepared, {}, {}).ok, "a real conflicting edit is still refused")
	for mutate: Callable in [
		func(r: Dictionary, c: Dictionary) -> void: c.source_key = "waystone:another_stone",
		func(r: Dictionary, c: Dictionary) -> void: c.touch_id = "not-hex",
		func(r: Dictionary, c: Dictionary) -> void: c.validated_touch = false,
		func(r: Dictionary, c: Dictionary) -> void: c.expected_revision = 1,
		func(r: Dictionary, c: Dictionary) -> void: c.erase("realm"),
		func(r: Dictionary, c: Dictionary) -> void: r.envelope.payload = {"kind": "portal_enter", "arch_id": "tidewake"},
		func(r: Dictionary, c: Dictionary) -> void: r.envelope.request_id = "another-epoch:7",
		func(r: Dictionary, c: Dictionary) -> void: r.envelope.character_id = "someone-else",
	]:
		var request: Dictionary = parts.request.duplicate(true)
		var context: Dictionary = parts.context.duplicate(true)
		mutate.call(request, context)
		assert_true(PREP.make_action(request, context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "waystone_touch").is_empty(),
			"a changed touch binding never prepares")
	assert_true(PREP.make_action(parts.request, parts.context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "foundation_request").is_empty(),
		"a touch cannot masquerade as another request source")

func test_a_guest_relic_power_choice_is_a_frozen_owner_request() -> void:
	# F31#2 (render.yml 37388993811): a guest's relic power row staged straight
	# onto the admitted record while its care stream drifted, the same stale
	# base that stranded the Home Key reconcile. It freezes like relic_hang.
	assert_true(preload("res://scripts/net/owner_passive_sync.gd").REQUEST_ACTIONS.has("relic_power"))
	var f := _action_fixture()
	var request: Dictionary = f.request.duplicate(true)
	request.op = "relic_power"
	request.revision = 0
	request.intent = {"heart_id": "meadows", "edit_id": DATA.TXN}
	var prepared := PREP.make_action(request, f.context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN)
	assert_false(prepared.is_empty(), "the exact relic power request prepares")
	assert_true(PREP.owner_plan(f.cursor.state, prepared, {}, {}).ok, "the owner's replayed state is the baseline")
	request.revision = 1
	assert_true(PREP.make_action(request, f.context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN).is_empty(),
		"a request quoting another revision never prepares")

func _home_key_parts() -> Dictionary:
	var grant := preload("res://scripts/net/reward_delivery.gd").make_record("resource-slot", "resource-namespace",
		"home_key:grant:" + DATA.CHARACTER, DATA.CHARACTER, "home_key", 1, "home_key_given")
	var record := preload("res://scripts/net/home_key_action.gd").due(grant, DATA.CHARACTER)
	var envelope := {"character_id": DATA.CHARACTER, "world_instance_id": "resource-namespace", "session_epoch": "current-epoch",
		"delivery_id": grant.delivery_id, "origin_namespace": "resource-namespace"}
	var context := {"character_id": DATA.CHARACTER, "expected_revision": 0, "in_range": true, "in_combat": false,
		"foundation_runtime_authorized": true, "home_key_authorized": true, "home_key_record": record,
		"source_key": "opening_home_key:" + grant.delivery_id}
	return {"request": PREP.home_key_request(envelope), "context": context}

func test_home_key_request_binds_its_own_reconcile_request_and_frozen_host_context() -> void:
	# F18 (render.yml 37383201956): a guest's Home Key owe/deliver row staged
	# against a stale admitted record stranded its owner-passive stream. The
	# reconcile is frozen/replayed like every other owner request.
	var f := _action_fixture()
	var parts := _home_key_parts()
	var prepared := PREP.make_action(parts.request, parts.context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "home_key")
	assert_false(prepared.is_empty(), "the exact reconcile request and host context prepare")
	assert_true(PREP.valid_action_host(prepared, f.cursor))
	assert_true(PREP.owner_plan(f.cursor.state, prepared, {}, {}).ok, "the owner's replayed state is the baseline")
	assert_false(PREP.owner_plan(f.before, prepared, {}, {}).ok, "a stale owner record is still refused")
	for mutate: Callable in [
		func(r: Dictionary, c: Dictionary) -> void: c.source_key = "opening_home_key:" + "0".repeat(64),
		func(r: Dictionary, c: Dictionary) -> void: c.home_key_authorized = false,
		func(r: Dictionary, c: Dictionary) -> void: c.expected_revision = 1,
		func(r: Dictionary, c: Dictionary) -> void: c.home_key_record.character_id = "someone-else",
		func(r: Dictionary, c: Dictionary) -> void: c.home_key_record = {},
		func(r: Dictionary, c: Dictionary) -> void: r.envelope.delivery_id = "0".repeat(64),
		func(r: Dictionary, c: Dictionary) -> void: r.envelope.origin_namespace = "another-world",
		func(r: Dictionary, c: Dictionary) -> void: r.envelope.session_epoch = "another-epoch",
		func(r: Dictionary, c: Dictionary) -> void: r.envelope.character_id = "someone-else",
		func(r: Dictionary, c: Dictionary) -> void: r.envelope.extra = true,
		func(r: Dictionary, c: Dictionary) -> void: r.op = "waystone_touch",
	]:
		var request: Dictionary = parts.request.duplicate(true)
		var context: Dictionary = parts.context.duplicate(true)
		mutate.call(request, context)
		assert_true(PREP.make_action(request, context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "home_key").is_empty(),
			"a changed reconcile binding never prepares")
	assert_true(PREP.make_action(parts.request, parts.context, f.before, 0, "current-epoch", "resource-slot", f.cursor, DATA.TXN, "waystone_touch").is_empty(),
		"a reconcile cannot masquerade as another request source")

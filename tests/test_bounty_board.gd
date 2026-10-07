extends "res://tests/test_case.gd"

const BOARD := preload("res://scripts/world/bounty_board.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const DELIVERY := preload("res://scripts/net/character_action_delivery.gd")
const ACTIONS := preload("res://scripts/net/character_action_rules.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")

func _record(character: String = "character-f43-a") -> Dictionary:
	var inventory := RULES.inventory_from([])
	return {"character_id": character, "party": [], "redesign_character": STATE.defaults("character"),
		"inventory": RULES.slots(inventory), "portal_escrow": {}, "vitals_escrow": {},
		"equipment": RECORD.empty_equipment(), "realm_hearts": {"active_id": ""}}

func _context(current: Dictionary, revision: int = 0, day: int = 1, world: String = "world-f43-a") -> Dictionary:
	return {"character_id": current.character_id, "expected_revision": revision, "in_range": true,
		"source_key": "halda_bounty_board", "in_combat": false, "clock_confirmed": true,
		"world_namespace": world, "host_day": day, "host_unlocks": []}

func _issued() -> Dictionary:
	var current := _record()
	current.redesign_character.bounties = {"anchor_world": "world-f43-a", "anchor_day": 1, "cycle": 1,
		"slots": [{"instance": "catch".sha256_text(), "template": "meadows_catch_trait", "complete": false},
			{"instance": "alpha".sha256_text(), "template": "meadows_defeat_alpha", "complete": false},
			{"instance": "delivery".sha256_text(), "template": "meadows_material_delivery", "complete": false}]}
	return current

func test_empty_board_survives_character_json_reload_without_accepting_partial_state() -> void:
	var current := _record()
	var restored: Dictionary = JSON.parse_string(JSON.stringify(current))
	assert_true(STATE.validate("character", restored.redesign_character).is_empty())
	assert_true(BOARD.stage(restored, 0, "bounty_rotate", {}, _context(restored)).ok)
	for field: String in ["anchor_world", "anchor_day", "cycle", "slots"]:
		var malformed: Dictionary = restored.redesign_character.bounties.duplicate(true)
		match field:
			"anchor_world": malformed.anchor_world = "world-partial"
			"anchor_day": malformed.anchor_day = 1
			"cycle": malformed.cycle = 0.5
			"slots": malformed.slots = [{"partial": true}]
		assert_false(BOARD.board_errors(malformed).is_empty(), field)

func test_rotation_exactly_three_unlocked_deterministic_personal_and_no_reroll() -> void:
	var current := _record()
	var context := _context(current)
	var fresh_world := STATE.defaults("world")
	assert_eq(fresh_world.bounty_day, 0, "saved clock starts before the first rollover")
	context.host_day = BOARD.host_day(fresh_world)
	var first := BOARD.stage(current, 0, "bounty_rotate", {}, context)
	assert_true(first.get("ok") == true)
	if first.get("ok") != true: return
	assert_eq(first.state.redesign_character.bounties.slots.size(), 3)
	assert_eq(first.state, BOARD.stage(current, 0, "bounty_rotate", {}, context).state)
	for slot: Dictionary in first.state.redesign_character.bounties.slots:
		assert_eq(BOARD.template(slot.template).biome, "meadows")
	assert_false(BOARD.stage(first.state, 1, "bounty_rotate", {}, _context(first.state, 1)).ok)
	var other := _record("character-f43-b")
	var other_board: Dictionary = BOARD.stage(other, 0, "bounty_rotate", {}, _context(other)).state.redesign_character.bounties
	assert_ne(other_board.slots, first.state.redesign_character.bounties.slots)
	fresh_world.bounty_day += 1
	var tomorrow := BOARD.stage(first.state, 1, "bounty_rotate", {}, _context(first.state, 1, BOARD.host_day(fresh_world)))
	assert_true(tomorrow.ok)
	assert_ne(tomorrow.state.redesign_character.bounties.slots, first.state.redesign_character.bounties.slots)
	var unlocked := _context(current)
	unlocked.host_unlocks = ["tidewake"]
	assert_eq(BOARD.unlocked(current.redesign_character, unlocked.host_unlocks), ["meadows", "tidewake"])
	assert_false(BOARD.stage(current, 0, "bounty_rotate", {"day": 999}, context).ok)

func test_world_hop_reanchors_without_new_reward_instances_or_offline_day_catchup() -> void:
	var current := _issued()
	var switched := BOARD.stage(current, 0, "bounty_rotate", {}, _context(current, 0, 100, "world-f43-b"))
	assert_true(switched.ok)
	assert_eq(switched.state.redesign_character.bounties.slots, current.redesign_character.bounties.slots)
	assert_eq(switched.state.redesign_character.bounties.cycle, 1)
	assert_false(BOARD.stage(switched.state, 1, "bounty_rotate", {}, _context(switched.state, 1, 100, "world-f43-b")).ok)
	var morning := BOARD.stage(switched.state, 1, "bounty_rotate", {}, _context(switched.state, 1, 101, "world-f43-b"))
	assert_eq(morning.state.redesign_character.bounties.cycle, 2)
	var back := BOARD.stage(morning.state, 2, "bounty_rotate", {}, _context(morning.state, 2, 999))
	assert_eq(back.state.redesign_character.bounties.cycle, 2)
	assert_eq(back.state.redesign_character.bounties.slots, morning.state.redesign_character.bounties.slots)

func test_confirmed_participant_event_matches_trait_and_frozen_instances_only() -> void:
	var current := _issued()
	var context := _context(current)
	context.merge({"event_confirmed": true, "event_id": "host-catch:7", "kind": "catch_trait", "biome": "meadows",
		"traits": ["bold"], "participants": [current.character_id], "issued_instances": ["catch".sha256_text()]}, true)
	var completed := BOARD.stage(current, 0, "bounty_event", {}, context)
	assert_true(completed.ok)
	assert_true(completed.state.redesign_character.bounties.slots[0].complete)
	assert_false(completed.state.redesign_character.bounties.slots[1].complete)
	for field: String in ["event_confirmed", "participants", "issued_instances", "traits"]:
		var forged := context.duplicate(true)
		forged[field] = false if field == "event_confirmed" else []
		assert_false(BOARD.stage(current, 0, "bounty_event", {}, forged).ok, field)
	assert_false(BOARD.stage(current, 0, "bounty_event", {"progress": 1}, context).ok)
	var paid := BOARD.stage(completed.state, 1, "bounty_claim", {"instance": "catch".sha256_text()}, _context(completed.state, 1))
	assert_true(paid.ok)
	assert_eq(paid.state.redesign_character.bounty_receipts.size(), 1)
	assert_false(BOARD.stage(paid.state, 2, "bounty_claim", {"instance": "catch".sha256_text()}, _context(paid.state, 2)).ok)

func test_delivery_debit_reward_and_receipt_atomic_inventory_full_and_wrong_board_refuse() -> void:
	var current := _issued()
	var bag := RULES.inventory_from(current.inventory)
	bag.add("wood", 7)
	current.inventory = RULES.slots(bag)
	var intent := {"instance": "delivery".sha256_text()}
	var proposal := BOARD.stage(current, 0, "bounty_claim", intent, _context(current))
	assert_true(proposal.ok)
	assert_eq(RULES.inventory_from(current.inventory).count("wood"), 7)
	assert_eq(RULES.inventory_from(proposal.state.inventory).count("wood"), 1)
	assert_eq(RULES.inventory_from(proposal.state.inventory).count("essence_ground"), 8)
	var full := current.duplicate(true)
	for index: int in full.inventory.size(): full.inventory[index] = {"id": "wood", "n": RULES.db().stack_size("wood")}
	var before := full.duplicate(true)
	assert_eq(BOARD.stage(full, 0, "bounty_claim", intent, _context(full)).code, "reward_inventory_full")
	assert_eq(full, before)
	var context := _context(current)
	context.in_range = false
	assert_false(BOARD.stage(current, 0, "bounty_claim", intent, context).ok)
	context.in_range = true
	context.source_key = "client-invented-board"
	assert_false(BOARD.stage(current, 0, "bounty_claim", intent, context).ok)
	assert_false(BOARD.stage(current, 0, "bounty_claim", {"instance": intent.instance, "rewards": []}, _context(current)).ok)

func test_alpha_rematch_candy_and_trait_seed_paths_with_stale_event_refusal() -> void:
	for kind: String in ["defeat_alpha", "rematch", "catch_trait"]:
		var current := _issued()
		var selected: Dictionary = current.redesign_character.bounties.slots[0]
		selected.template = "cloudreach_" + kind
		var context := _context(current)
		context.merge({"event_confirmed": true, "event_id": "accepted-" + kind, "kind": kind,
			"biome": "cloudreach", "traits": ["calm"], "participants": [current.character_id],
			"issued_instances": [selected.instance]}, true)
		var earned := BOARD.stage(current, 0, "bounty_event", {}, context)
		assert_true(earned.ok, kind)
		if not earned.ok: continue
		var paid := BOARD.stage(earned.state, 1, "bounty_claim", {"instance": selected.instance}, _context(earned.state, 1))
		assert_true(paid.ok, kind)
		if not paid.ok: continue
		var bag := RULES.inventory_from(paid.state.inventory)
		if kind == "rematch": assert_eq(bag.count("tether_candy"), 1)
		if kind == "catch_trait": assert_eq(bag.count("trait_seed_calm"), 1)
		assert_false(BOARD.stage(paid.state, 2, "bounty_event", {}, _context(paid.state, 2)).ok)
		var tomorrow := BOARD.stage(current, 0, "bounty_rotate", {}, _context(current, 0, 2))
		context.expected_revision = 1
		assert_false(BOARD.stage(tomorrow.state, 1, "bounty_event", {}, context).ok, "old encounter cannot complete new instances")

func test_existing_journal_replays_exactly_and_registry_rolls_back_failed_world_write() -> void:
	# Existing interaction consumer retains its actual original claim while
	# the typed pre-payment checkpoint is pending; no second submit is made.
	var interaction := preload("res://scripts/world/bounty_interaction_adapter.gd").new()
	var issued := _issued()
	var submits: Array[Dictionary] = []
	var reconciles: Array[Dictionary] = []
	var emitted: Array[Dictionary] = []
	interaction.action_completed.connect(func(verdict: Dictionary) -> void: emitted.append(verdict.duplicate(true)))
	var pending_result := {"ok": false, "durable": false, "resolved": false, "code": "owner_passive_checkpoint_pending"}
	assert_true(interaction.bind_actions(func(intent: Dictionary) -> Dictionary:
		submits.append(intent.duplicate(true)); return pending_result.duplicate(true), func() -> Dictionary:
		var view := BOARD.view(issued.redesign_character, issued.character_id)
		view.world_namespace = "world-f43-a"; return view, func(original: Dictionary) -> Dictionary:
		reconciles.append(original.duplicate(true)); return pending_result.duplicate(true)))
	var instance := "delivery".sha256_text()
	assert_eq(interaction.claim(instance).code, "owner_passive_checkpoint_pending")
	var frozen := var_to_bytes(interaction.get("_pending"))
	assert_false((interaction.get("_pending") as Dictionary).is_empty())
	assert_eq(interaction.claim(instance).code, "board_busy_or_unavailable")
	assert_eq(submits, [{"instance": instance}])
	interaction.reconcile()
	assert_eq(reconciles, [{"instance": instance, "character_id": issued.character_id, "world_namespace": "world-f43-a"}])
	assert_eq(var_to_bytes(interaction.get("_pending")), frozen)
	var settled := {"ok": true, "durable": true, "resolved": true, "owner_saved": true,
		"owner_acknowledged": false, "receipt": "bounty:%s:%s" % [instance, issued.character_id]}
	interaction.settled(settled)
	assert_eq(var_to_bytes(interaction.get("_pending")), frozen, "BOOL alone does not release the original claim")
	settled.owner_acknowledged = true
	interaction.settled(settled)
	assert_true((interaction.get("_pending") as Dictionary).is_empty())
	interaction.claim(instance)
	var refusal := {"ok": false, "durable": false, "resolved": true, "terminal_refusal": true, "code": "owner_passive_source_changed"}
	var original_claim: Dictionary = interaction.get("_pending").duplicate(true)
	var foreign_claim: Dictionary = original_claim.duplicate(true)
	foreign_claim.instance = "foreign".sha256_text()
	interaction.settled(refusal, foreign_claim)
	assert_false((interaction.get("_pending") as Dictionary).is_empty(), "late foreign refusal cannot release this original")
	assert_false(emitted[-1].get("terminal", false), "foreign refusal is not normalized into a terminal panel verdict")
	interaction.settled(refusal, original_claim)
	assert_true((interaction.get("_pending") as Dictionary).is_empty(), "exact no-effect leaves no stuck pending consumer")
	assert_true(emitted[-1].get("terminal") == true, "bound no-effect also clears the existing panel's waiting state")
	assert_false(emitted[-1].durable)
	assert_false(emitted[-1].get("owner_saved", false))
	assert_false(emitted[-1].get("owner_acknowledged", false))
	assert_false(refusal.has("terminal"), "presentation normalization never mutates the original verdict")
	interaction.free()
	# Reuse the existing detached Session fixture for its actual envelope,
	# request correlation and reply receiver. No ENet or panel render claim.
	var view_game := preload("res://tests/test_altar_essence_quote_bridge.gd").FixtureGame.new()
	view_game.local = preload("res://autoload/player_state.gd").new()
	view_game.local.character_id = issued.character_id
	view_game.world = preload("res://autoload/world_state.gd").new()
	view_game.world.world_id = "slot-f43"
	view_game.world.reward_delivery_namespace = "world-f43-a"
	var view_session := preload("res://tests/test_altar_essence_quote_bridge.gd").FixtureSession.new()
	view_session.fixture = view_game
	view_session.fixture_host = false
	view_game.session = view_session
	view_game.add_child(view_session)
	var composition := preload("res://scripts/net/foundation_composition.gd").new()
	view_session.add_child(composition)
	var view_adapter := preload("res://scripts/world/bounty_interaction_adapter.gd").new()
	composition.add_child(view_adapter)
	composition.set("_interaction", view_adapter)
	view_session.foundation_reply_received.connect(composition._reply)
	var received_views: Array[Dictionary] = []
	view_adapter.view_changed.connect(func(snapshot: Dictionary) -> void: received_views.append(snapshot.duplicate(true)))
	assert_eq(composition.personal_view(), {}, "cold guest view sends once and awaits an authentic reply")
	assert_eq(view_session.get("_foundation_requests").size(), 1)
	var envelope: Dictionary = view_session.get("_foundation_requests").values()[0].duplicate(true)
	var board_view := BOARD.view(issued.redesign_character, issued.character_id)
	board_view.world_namespace = "world-f43-a"
	var uncorrelated := envelope.duplicate(true)
	uncorrelated.station_key = "foreign-board"
	view_session.call("_rpc_foundation_reply", uncorrelated, board_view)
	assert_true(received_views.is_empty(), "unsolicited reply never publishes board rows")
	for field: String in ["character_id", "world_namespace", "session_epoch"]:
		var foreign := envelope.duplicate(true)
		foreign[field] = "foreign"
		view_session.call("_rpc_foundation_reply", foreign, board_view)
		assert_true(received_views.is_empty(), "Session refuses foreign " + field)
	for field: String in ["character_id", "world_namespace"]:
		var foreign := board_view.duplicate(true)
		foreign[field] = "foreign"
		view_session.call("_rpc_foundation_reply", envelope, foreign)
		assert_true(received_views.is_empty(), "correlation cannot mislabel another owner's rows: " + field)
	view_session.call("_rpc_foundation_reply", envelope, board_view)
	assert_eq(received_views, [board_view], "one authentic asynchronous reply publishes the supplied snapshot")
	assert_eq(composition.get("_cached_view"), board_view)
	assert_eq(composition.get("_cached_view_scope"), view_session.call("_foundation_view_scope", envelope))
	received_views[0].rows.clear()
	assert_eq(composition.get("_cached_view"), board_view, "view observer cannot mutate the retained cache")
	view_session.epoch = "b".repeat(32)
	assert_eq(composition.personal_view(), {}, "same world and character in a new epoch starts cold")
	view_session.call("_rpc_foundation_reply", envelope, board_view)
	assert_eq(received_views.size(), 1, "old epoch cannot republish its cache")
	var current_envelope: Dictionary = view_session.get("_foundation_requests").values()[0].duplicate(true)
	view_session.call("_rpc_foundation_reply", current_envelope, board_view)
	assert_eq(received_views.size(), 2)
	view_game.world.reward_delivery_namespace = "world-f43-b"
	assert_eq(composition.personal_view(), {}, "changing host world clears the guest board")
	view_game.local.character_id = "character-f43-b"
	assert_eq(composition.personal_view(), {}, "changing owner keeps the guest board cold")
	view_session.call("_rpc_foundation_reply", current_envelope, board_view)
	assert_eq(received_views.size(), 2, "prior owner and host cannot republish their rows")
	view_game.free()
	var current := _record()
	assert_true(RECORD.errors(current, current.character_id).is_empty())
	var context := _context(current)
	var staged := ACTIONS.stage(current, 0, "bounty_rotate", {}, context, RECORD.errors)
	assert_true(staged.ok)
	if not staged.ok: return
	staged.character_revision = 1
	var journal := DELIVERY.make_record("slot-0", "world-f43-a", "session-f43", staged, null, RECORD.errors)
	assert_false(journal.is_empty())
	assert_true(DELIVERY.valid(journal, RECORD.errors))
	var owner := DELIVERY.owner_plan(current, journal, RECORD.errors)
	assert_true(owner.ok)
	var reload: Dictionary = JSON.parse_string(JSON.stringify(owner.state))
	assert_true(DELIVERY.owner_plan(reload, journal, RECORD.errors).duplicate)
	var forged := journal.duplicate(true)
	forged.after.redesign_character.bounties.slots[0].complete = true
	assert_false(DELIVERY.valid(forged, RECORD.errors))
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("world-f43-a"))
	assert_true(authority.seed_admitted_character(current, current.character_id).ok)
	var prepared := authority.stage_character_action(current.character_id, 0, "bounty_rotate", {}, context)
	assert_true(prepared.ok)
	assert_true(authority.finish_creature_training(prepared, false))
	assert_eq(authority.state(current.character_id), current)
	assert_eq(authority.revision(current.character_id), 0)
	var restarted := AUTHORITY.new()
	assert_true(restarted.bind_world("world-f43-a"))
	assert_true(restarted.seed_admitted_character(current, current.character_id).ok)
	var deliveries := {journal.delivery_id: journal}
	assert_true(restarted.recover_durable_training(current.character_id, deliveries).ok)
	assert_eq(restarted.state(current.character_id), owner.state)
	assert_true(restarted.creature_training_is_pending(current.character_id))
	assert_false(restarted.stage_character_action(current.character_id, 1, "bounty_rotate", {}, _context(owner.state, 1, 2)).ok)
	journal.status = "accepted"
	assert_true(restarted.acknowledge_creature_training(current.character_id, journal))
	assert_false(restarted.creature_training_is_pending(current.character_id))
	# Reuse the existing disk/BOOL fixtures for the missing consumer callback.
	# The physical board/request send is a double; stage, owner install, saves,
	# world acceptance, registry ACK and Session completion are production code.
	var save_fixture := preload("res://tests/test_foundation_resource_save.gd").new()
	var directory := "user://test_bounty_completion_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var claim_game := preload("res://tests/test_foundation_resource_save.gd").FixtureGame.new()
	claim_game.local = preload("res://autoload/player_state.gd").new()
	claim_game.local.configure(preload("res://autoload/item_db.gd").new())
	claim_game.local.character_id = issued.character_id
	claim_game.local.redesign_character = issued.redesign_character.duplicate(true)
	claim_game.local.inventory.add("wood", 6)
	claim_game.world = preload("res://autoload/world_state.gd").new()
	claim_game.world.world_id = "slot-0"
	claim_game.world.reward_delivery_namespace = "world-f43-a"
	var claim_session := preload("res://tests/test_foundation_resource_save.gd").FixtureSession.new()
	claim_session.fixture = claim_game
	claim_game.session = claim_session
	var claim_authority := AUTHORITY.new()
	claim_session.set("_character_authority", claim_authority)
	var claim_writer := preload("res://tests/test_foundation_resource_save.gd").BoolWriter.new()
	claim_writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	claim_writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	claim_game.save_system = claim_writer
	var claim_rpc := preload("res://tests/test_foundation_resource_save.gd").FixtureRpc.new()
	claim_rpc.fixture = claim_game
	claim_rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(claim_game.world)
	var claim_composition := preload("res://scripts/net/foundation_composition.gd").new()
	claim_session.add_child(claim_composition)
	var claim_adapter := preload("res://scripts/world/bounty_interaction_adapter.gd").new()
	claim_composition.add_child(claim_adapter)
	claim_composition.set("_interaction", claim_adapter)
	claim_session.homestead_action_completed.connect(claim_composition._bounty_completed)
	var completions: Array[Dictionary] = []
	claim_adapter.action_completed.connect(func(answer: Dictionary) -> void: completions.append(answer.duplicate(true)))
	claim_adapter.bind_actions(func(original: Dictionary) -> Dictionary:
		# Actual request retention; this detached source cannot dispatch a claim.
		claim_session.call("_foundation_send", "bounty_claim", "halda_bounty_board", original, -1)
		return pending_result.duplicate(true), func() -> Dictionary:
		var view := BOARD.view(claim_game.local.redesign_character, issued.character_id)
		view.world_namespace = "world-f43-a"; return view, func(_original: Dictionary) -> Dictionary:
		return pending_result.duplicate(true))
	assert_eq(claim_adapter.claim(instance).code, "owner_passive_checkpoint_pending")
	var claim_requests: Dictionary = claim_session.get("_foundation_requests").duplicate(true)
	var claim_before := RECORD.portable_projection(claim_game.local.save_data())
	assert_true(claim_authority.bind_world("world-f43-a"))
	assert_true(claim_authority.seed_admitted_character(claim_before, issued.character_id).ok)
	var claim_token := claim_authority.stage_character_action(issued.character_id, 0, "bounty_claim", {"instance": instance}, _context(claim_before))
	assert_true(claim_token.get("ok") == true, str(claim_token))
	if claim_token.get("ok") != true:
		save_fixture._close(claim_game, claim_rpc, directory); return
	var claim_journal: Dictionary = claim_rpc.journal_creature_training_prepared(1, issued.character_id, claim_authority.staged_creature_training(claim_token))
	assert_true(claim_journal.get("durable") == true, str(claim_journal))
	assert_true(claim_authority.finish_creature_training(claim_token, claim_journal.get("durable") == true))
	if claim_journal.get("durable") != true:
		save_fixture._close(claim_game, claim_rpc, directory); return
	var claim_row: Dictionary = claim_game.world.reward_deliveries[claim_journal.delivery_id].duplicate(true)
	var claimed: Dictionary = preload("res://scripts/net/character_action_owner.gd").apply_owner(claim_game, claim_row)
	assert_true(claimed.get("saved") == true, str(claimed))
	claim_session.call("_deliver_training_decision", 1, claim_row)
	assert_eq(completions.size(), 1, "owner BOOL alone leaves the original pending consumer")
	assert_true(claim_rpc.ledger.accept_creature_training_delivery(claim_row.delivery_id, issued.character_id,
		int(claim_row.journal_revision), claim_row.receipt, 1).get("ok") == true)
	assert_true(claim_writer.save_world_prepared(claim_game, "slot-0"))
	claim_row = claim_game.world.reward_deliveries[claim_row.delivery_id].duplicate(true)
	claim_session.call("_deliver_training_decision", 1, claim_row)
	assert_eq(completions.size(), 1, "accepted world still waits for the original registry ACK")
	claim_composition.call("_bounty_completed", "bounty_claim", claim_row.intent, settled)
	assert_eq(completions.size(), 1, "claimed success cannot replace the actual registry ACK")
	assert_true(claim_authority.acknowledge_creature_training(issued.character_id, claim_row))
	var claim_result: Dictionary = claim_session.call("_foundation_decision", 1, claim_row)
	assert_true(claim_result.get("owner_saved") == true and claim_result.get("owner_acknowledged") == true)
	for defect: String in ["session_epoch", "character_id", "world_namespace", "station_key", "revision", "intent", "receipt", "ack"]:
		var requests: Dictionary = claim_requests.duplicate(true)
		var request: Dictionary = requests.values()[0]
		var answer := claim_result.duplicate(true)
		match defect:
			"revision": request.revision = 0
			"intent": request.intent = {"instance": "foreign".sha256_text()}
			"receipt": answer.receipt = "foreign-receipt"
			"ack": answer.owner_acknowledged = false
			_: request[defect] = "foreign"
		claim_session.set("_foundation_requests", requests)
		claim_composition.call("_bounty_completed", "bounty_claim", claim_row.intent, answer)
		assert_eq(completions.size(), 1, "refuse mismatched original completion: " + defect)
		assert_false((claim_adapter.get("_pending") as Dictionary).is_empty())
	claim_session.set("_foundation_requests", claim_requests)
	var claim_row_bytes := var_to_bytes(claim_row)
	claim_session.call("_deliver_training_decision", 1, claim_row)
	assert_eq(completions.size(), 2, "actual saved Session completion reaches the original bounty consumer")
	assert_true((claim_adapter.get("_pending") as Dictionary).is_empty())
	assert_true(completions[-1].get("owner_saved") == true and completions[-1].get("owner_acknowledged") == true)
	assert_eq(completions[-1].get("receipt"), claim_row.receipt)
	claim_session.call("_deliver_training_decision", 1, claim_row)
	assert_eq(completions.size(), 2, "accepted redelivery does not repeat completion")
	assert_eq(var_to_bytes(claim_game.world.reward_deliveries[claim_row.delivery_id]), claim_row_bytes)
	assert_eq(claim_game.local.inventory.count("wood"), 0)
	assert_eq(claim_game.local.inventory.count("essence_ground"), 8)
	assert_eq(claim_game.local.inventory.count("stone"), 3)
	assert_eq(claim_writer.character_store.call("read", issued.character_id).redesign_character.bounty_receipts.count(claim_row.receipt), 1)
	save_fixture._close(claim_game, claim_rpc, directory)

func test_four_kinds_reward_catalog_and_additive_save_shape() -> void:
	assert_true(BOARD.configuration_errors(BOARD.config()).is_empty())
	var current := _record()
	current.redesign_character.erase("bounties")
	assert_true(STATE.validate("character", current.redesign_character).is_empty(), "pre-feature v28 remains readable")
	var issued := _issued()
	assert_true(STATE.validate("character", issued.redesign_character).is_empty())
	issued.redesign_character.bounties.slots.pop_back()
	assert_false(STATE.validate("character", issued.redesign_character).is_empty(), "partial board refuses")

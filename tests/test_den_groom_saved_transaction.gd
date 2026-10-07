extends "res://tests/test_case.gd"

## Actual care/shed staging, world/owner disk writes and authenticated local
## ACK. Physical Den presence and pre-write actor admission are disclosed
## fixtures; these tests do not claim a controller route or an ENet session.
const DATA := preload("res://tests/test_foundation_resources.gd")
const SAVE := preload("res://tests/test_foundation_resource_save.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const OWNER := preload("res://scripts/net/character_action_owner.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const E := preload("res://scripts/creatures/essence.gd")
const SECOND := "1123456789abcdef0123456789abcdef"

class GroomSession extends SAVE.FixtureSession:
	var actor_host := preload("res://scripts/combat/accepted_action_host.gd").new()
	func _training_actor_baseline_proposals(_peer: int, training: Dictionary) -> Dictionary:
		# Exercise the actual private actor handoff at ACK, with no encounters.
		var authority: RefCounted = get("_character_authority")
		var admitted: Dictionary = authority.call("state", DATA.CHARACTER)
		var revision: int = authority.call("revision", DATA.CHARACTER)
		var world: RefCounted = fixture.get("world")
		var stage := actor_host.stage_actor_training_baseline(training, admitted, revision,
			world.reward_delivery_namespace, world.world_id)
		return {"ok": stage.get("ok") == true, "proposals": [{"host": actor_host, "stage": stage}],
			"admitted": admitted, "revision": revision}

class QuoteSession extends GroomSession:
	var requests: Array[Dictionary] = []
	func homestead_personal_view() -> Dictionary:
		var authority: RefCounted = get("_character_authority")
		var player: RefCounted = fixture.get("local")
		var refreshed: Dictionary = authority.call("refresh_host_local", RECORD.portable_projection(player.save_data()), DATA.CHARACTER)
		return {"registry_revision": refreshed.revision} if refreshed.get("ok") == true else {}
	func homestead_submit_action(action: String, original: Dictionary, _station: Node3D, revision: int) -> Dictionary:
		# Transport refusal is the seam double; no saved success is synthesized.
		requests.append({"action": action, "intent": original.duplicate(true), "revision": revision})
		return _foundation_journal_refusal(action, {"code": "training_journal_failed"})

func _player(species: String = "mudsnout") -> RefCounted:
	var player := DATA.new()._player()
	player.party.clear()
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn(species))
	return player

func _before(species: String = "mudsnout") -> Dictionary:
	return RECORD.portable_projection(_player(species).save_data())

func _context(day: Variant = 1, revision: int = 0) -> Dictionary:
	return {"character_id": DATA.CHARACTER, "expected_revision": revision,
		"source_key": "den:meadows:b3", "source_id": "b3", "source_generation": "b3",
		"station_id": "den", "homestead": true, "paid_den": true,
		"world_id": "resource-slot", "world_namespace": "resource-namespace",
		"realm": "meadows", "actor_realm": "meadows", "host_day": day,
		"in_range": true, "in_combat": false, "modal_open": false,
		"registered_live_source": true, "resource_runtime_authorized": true,
		"foundation_runtime_authorized": true}

func _intent(before: Dictionary, action_id: String = DATA.TXN) -> Dictionary:
	return {"creature_uid": before.party[0].uid, "action_id": action_id}

func _panel_for(game: Node, session: Node, source: Node3D, original: Dictionary, revision: int) -> CanvasLayer:
	var panel := preload("res://scripts/ui/craft_panel.gd").new()
	var status := Label.new()
	panel.add_child(status)
	panel.set("_status", status)
	panel.set("game", game)
	panel.set("_producer", session)
	panel.set("_groom_scope", panel._current_groom_scope())
	panel.set("_station", source)
	panel.set("_station_operation", "groom")
	panel.set("_station_intent", original.duplicate(true))
	panel.set("_original_revision", revision)
	panel.set("_station_source", weakref(source))
	return panel

func _row(before: Dictionary, intent: Dictionary, context: Dictionary) -> Dictionary:
	var proposal := ACTIONS.stage(before, int(context.expected_revision), "groom", intent, context, RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true: return {}
	proposal.character_revision = int(context.expected_revision) + 1
	return DELIVERY.make_record("resource-slot", "resource-namespace", "resource-epoch", proposal, null, RECORD.errors)

func test_groom_combines_care_shed_and_empty_miss_once_per_owned_uid_day() -> void:
	var expected_outputs := {
		"mudsnout": {"essence": "essence_ground", "shed": "fiber"},
		"terrapup": {"essence": "essence_ground", "shed": ""},
		"galecrest": {"essence": "essence_air", "shed": "skyplume"},
		"sparkit": {"essence": "essence_electric", "shed": "sparkfur"},
		"staticub": {"essence": "essence_electric", "shed": "sparkfur"},
	}
	for species: String in ["mudsnout", "terrapup", "galecrest", "sparkit", "staticub"]:
		var expected: Dictionary = expected_outputs[species]
		var before := _before(species)
		var original := before.duplicate(true)
		var row := _row(before, _intent(before), _context())
		assert_false(row.is_empty())
		if row.is_empty(): continue
		assert_eq(before, original)
		assert_true(E._equivalent(row.after.party, before.party), "care does not replace or heal an owned creature")
		var bag := BAG.inventory_from(row.after.inventory)
		for essence: String in ["essence_ground", "essence_air", "essence_electric"]:
			assert_eq(bag.count(essence), 1 if essence == expected.essence else 0, species + " care essence: " + essence)
		for item: String in ["fiber", "reed_fiber", "skyplume", "sparkfur"]:
			assert_eq(bag.count(item), 1 if item == expected.shed else 0, species + " shed output: " + item)
		assert_eq(row.after.redesign_character.transaction_receipts.size(), before.redesign_character.transaction_receipts.size() + 3,
			"care, shed (including empty miss), and original transaction commit together")
		var decoded: Dictionary = JSON.parse_string(JSON.stringify(row))
		assert_true(DELIVERY.valid(decoded, RECORD.errors))
		assert_true(DELIVERY.owner_plan(row.after, decoded, RECORD.errors).get("duplicate") == true)
		assert_eq(ACTIONS.stage(row.after, 1, "groom", _intent(before, SECOND), _context(1, 1), RECORD.errors).get("code"), "already_groomed")
		var tomorrow := ACTIONS.stage(row.after, 1, "groom", _intent(before, SECOND), _context(2, 1), RECORD.errors)
		assert_true(tomorrow.get("ok") == true, str(tomorrow))
		if tomorrow.get("ok") == true:
			var tomorrow_bag := BAG.inventory_from(tomorrow.state.inventory)
			for essence: String in ["essence_ground", "essence_air", "essence_electric"]:
				assert_eq(tomorrow_bag.count(essence), 2 if essence == expected.essence else 0, species + " next-day care essence: " + essence)
			for item: String in ["fiber", "reed_fiber", "skyplume", "sparkfur"]:
				assert_eq(tomorrow_bag.count(item), 2 if item == expected.shed else 0, species + " next-day shed output: " + item)

func test_full_bag_refuses_before_consuming_care_or_shed_receipts() -> void:
	for care_stack_room: bool in [false, true]:
		var before := _before()
		for index: int in before.inventory.size(): before.inventory[index] = {"id": "wood", "n": BAG.db().stack_size("wood")}
		if care_stack_room: before.inventory[0] = {"id": "essence_ground", "n": 1}
		assert_true(RECORD.errors(before, DATA.CHARACTER).is_empty())
		var original := before.duplicate(true)
		var refusal := ACTIONS.stage(before, 0, "groom", _intent(before), _context(), RECORD.errors)
		assert_eq(refusal.get("code"), "inventory_full", str(refusal))
		assert_eq(before, original, "no care/day stamp is consumed even when care fits but shed does not")
		before.inventory[before.inventory.size() - 1] = null
		if not care_stack_room: before.inventory[before.inventory.size() - 2] = null
		assert_true(ACTIONS.stage(before, 0, "groom", _intent(before), _context(), RECORD.errors).get("ok") == true,
			"the exact original remains eligible after making actual room")

func test_foreign_uid_forged_context_and_care_cap_refuse_without_mutation() -> void:
	var before := _before()
	for defect: String in ["uid", "extra_world", "extra_day", "range", "combat", "modal", "owner", "paid", "registered", "realm", "namespace", "source", "generation"]:
		var context := _context()
		var intent := _intent(before)
		match defect:
			"uid": intent.creature_uid = "someone-elses-creature"
			"extra_world": intent.world_namespace = "client-world"
			"extra_day": intent.host_day = 100
			"range": context.in_range = false
			"combat": context.in_combat = true
			"modal": context.modal_open = true
			"owner": context.character_id = "other-owner"
			"paid": context.paid_den = false
			"registered": context.registered_live_source = false
			"realm": context.actor_realm = "water"
			"namespace": context.world_namespace = ""
			"source": context.source_key = "den:meadows:foreign"
			"generation": context.source_generation = ""
		var original := before.duplicate(true)
		assert_false(ACTIONS.stage(before, 0, "groom", intent, context, RECORD.errors).get("ok", false), defect)
		assert_eq(before, original)
	for invalid: Variant in [true, false, 0, -1, 0.5, NAN, INF, "1"]:
		assert_false(ACTIONS.stage(before, 0, "groom", _intent(before), _context(invalid), RECORD.errors).get("ok", false), str(invalid))
	for index: int in 5: before.redesign_character.transaction_receipts.append("care:%s:1:earlier-owned-%d:1" % [DATA.CHARACTER, index])
	assert_true(RECORD.errors(before, DATA.CHARACTER).is_empty())
	var capped_original := before.duplicate(true)
	assert_eq(ACTIONS.stage(before, 0, "groom", _intent(before), _context(), RECORD.errors).get("code"), "daily_care_cap")
	assert_eq(before, capped_original)

func test_groom_journal_rejects_a_different_world_even_with_same_slot_name() -> void:
	var before := _before()
	var row := _row(before, _intent(before), _context())
	assert_false(row.is_empty())
	if row.is_empty(): return
	for field: String in ["world_namespace", "world_id"]:
		var forged := row.duplicate(true)
		forged[field] = "foreign-" + str(row[field])
		forged.delivery_id = E.training_delivery_id(forged.world_namespace, DATA.CHARACTER)
		assert_false(DELIVERY.valid(forged, RECORD.errors), field)

func test_disk_failures_original_replay_and_real_saved_ack_never_pay_twice() -> void:
	var directory := "user://test_den_groom_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := SAVE.FixtureGame.new()
	game.local = _player()
	game.world = DATA.new()._world()
	var session := GroomSession.new()
	session.fixture = game
	session.set("_altar_epoch", "resource-epoch")
	game.session = session
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	var writer := SAVE.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := SAVE.FixtureRpc.new()
	rpc.fixture = game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	var before := RECORD.portable_projection(game.local.save_data())
	var original := _intent(before)
	var live_creature: RefCounted = game.local.party.at(0)
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).get("ok") == true)
	assert_true(writer.save_world_prepared(game, "resource-slot"))
	assert_true(writer.save_character_prepared(game, DATA.CHARACTER))
	var world_path: String = writer.world_store.call("path_for", "resource-slot")
	var owner_path: String = writer.character_store.call("path_for", DATA.CHARACTER)
	var old_world := FileAccess.get_file_as_bytes(world_path)
	var old_owner := FileAccess.get_file_as_bytes(owner_path)
	var token := authority.stage_character_action(DATA.CHARACTER, 0, "groom", original, _context())
	assert_true(token.get("ok") == true, str(token))
	if token.get("ok") != true:
		SAVE.new()._close(game, rpc, directory)
		return
	writer.refuse_world = true
	var failed := rpc.journal_creature_training_prepared(1, DATA.CHARACTER, authority.staged_creature_training(token))
	assert_eq(failed.get("code"), "training_journal_failed")
	assert_false(session._foundation_journal_refusal("groom", failed).terminal_refusal)
	assert_true(authority.finish_creature_training(token, false))
	assert_true(game.world.reward_deliveries.is_empty())
	assert_eq(authority.state(DATA.CHARACTER), before)
	assert_eq(FileAccess.get_file_as_bytes(world_path), old_world)
	assert_eq(FileAccess.get_file_as_bytes(owner_path), old_owner)
	writer.refuse_world = false
	token = authority.stage_character_action(DATA.CHARACTER, 0, "groom", original, _context())
	var journal := rpc.journal_creature_training_prepared(1, DATA.CHARACTER, authority.staged_creature_training(token))
	assert_true(journal.get("durable") == true, str(journal))
	assert_true(authority.finish_creature_training(token, journal.get("durable") == true))
	if journal.get("durable") != true:
		SAVE.new()._close(game, rpc, directory)
		return
	var row: Dictionary = game.world.reward_deliveries[journal.delivery_id]
	var source := Node3D.new()
	var panel := _panel_for(game, session, source, original, 0)
	panel.set("_groom_original_sent", true)
	assert_true(panel.call("station_source_departed", source))
	source.free()
	assert_eq(game.local.inventory.count("fiber"), 0)
	var recovered := DATA.new()._world()
	recovered.load_data(writer.world_store.call("read", "resource-slot"))
	assert_true(E._equivalent(recovered.reward_deliveries[row.delivery_id], row))
	var source_gone := session.homestead_submit_action("groom", original, null, 0)
	assert_eq(source_gone.get("receipt"), row.receipt, "durable original reconciles without a present Den")
	assert_false(source_gone.get("settled", true))
	panel.call("_station_completed", "groom", original, source_gone)
	assert_eq(panel.get("_station_intent"), original)
	assert_false(panel.is_queued_for_deletion())
	writer.refuse_owner = true
	var unsaved := OWNER.apply_owner(game, row)
	assert_eq(unsaved.get("code"), "owner_action_save_failed")
	panel.call("_station_completed", "groom", original, unsaved)
	assert_eq(panel.get("_station_intent"), original)
	assert_eq(FileAccess.get_file_as_bytes(owner_path), old_owner)
	assert_eq(game.local.inventory.count("fiber"), 1)
	assert_eq(game.local.inventory.count("essence_ground"), 1)
	assert_true(game.local.party.at(0) == live_creature)
	assert_true(session.owns_input())
	writer.refuse_owner = false
	var retry := OWNER.apply_owner(game, row)
	assert_true(retry.get("saved") == true and retry.get("duplicate") == true, str(retry))
	assert_true(E._equivalent(RECORD.portable_projection(writer.character_store.call("read", DATA.CHARACTER)), row.after))
	assert_true(session.owns_input(), "owner disk success alone cannot forge the host ACK")
	assert_false(rpc._accept_creature_training(row.delivery_id, int(row.journal_revision), row.receipt, 2), "unadmitted peer cannot ACK another owner")
	assert_false(rpc._accept_creature_training(row.delivery_id, int(row.journal_revision) + 1, row.receipt, 1))
	var pending_bytes := FileAccess.get_file_as_bytes(world_path)
	writer.refuse_world = true
	assert_false(rpc._accept_creature_training(row.delivery_id, int(row.journal_revision), row.receipt, 1))
	assert_eq(FileAccess.get_file_as_bytes(world_path), pending_bytes)
	assert_eq(game.world.reward_deliveries[row.delivery_id].status, "pending")
	assert_true(session.owns_input())
	writer.refuse_world = false
	assert_true(rpc._accept_creature_training(row.delivery_id, int(row.journal_revision), row.receipt, 1))
	assert_false(session.owns_input())
	assert_false(authority.creature_training_is_pending(DATA.CHARACTER))
	assert_true(rpc._accept_creature_training(row.delivery_id, int(row.journal_revision), row.receipt, 1), "lost ACK repeats only saved acceptance")
	var settled := session.homestead_submit_action("groom", original, null, 0)
	assert_true(settled.get("settled") == true and settled.get("durable") == true, str(settled))
	panel.call("_station_completed", "groom", {"creature_uid": original.creature_uid, "action_id": SECOND}, settled)
	assert_eq(panel.get("_station_intent"), original, "another original cannot consume this real saved result")
	panel.call("_station_completed", "groom", original, settled)
	assert_true(panel.get("_station_intent").is_empty())
	assert_true(panel.is_queued_for_deletion(), "accepted original releases its orphaned panel only after both real writes and ACK")
	assert_eq(game.local.inventory.count("fiber"), 1)
	assert_eq(game.local.inventory.count("essence_ground"), 1)
	assert_true(game.local.party.at(0) == live_creature)
	assert_eq(game.world.reward_deliveries.size(), 1)
	assert_false(rpc.ledger.commit_creature_training_delivery(row, 1).ok)
	panel.free()
	SAVE.new()._close(game, rpc, directory)

func test_unsent_source_deletion_keeps_original_until_real_missing_source_refusal() -> void:
	var game := SAVE.FixtureGame.new()
	game.local = _player()
	game.world = DATA.new()._world()
	var session := GroomSession.new()
	session.fixture = game
	session.set("_altar_epoch", "resource-epoch")
	game.session = session
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	assert_true(authority.bind_world("resource-namespace"))
	var before := RECORD.portable_projection(game.local.save_data())
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	game.save_system = SAVE.BoolWriter.new()
	var source := Node3D.new()
	var original := _intent(before)
	var panel := _panel_for(game, session, source, original, 0)
	assert_true(panel.call("station_source_departed", source), "source teardown retains the unsent original instead of freeing it")
	source.free()
	assert_eq(panel.get("_station_intent"), original)
	assert_true(panel.call("_original_station") == null)
	var refusal := session.homestead_submit_action("groom", original, null, 0)
	assert_true(refusal.get("terminal_refusal") == true and refusal.get("durable") == false, str(refusal))
	panel.call("_station_completed", "groom", original, refusal)
	assert_true(panel.get("_station_intent").is_empty())
	assert_true(panel.is_queued_for_deletion())
	assert_true(game.world.reward_deliveries.is_empty())
	assert_eq(RECORD.portable_projection(game.local.save_data()), before)
	panel.free()
	session.free()
	game.free()

func test_first_quote_follows_passive_tick_but_failed_original_never_rebases() -> void:
	var game := SAVE.FixtureGame.new()
	game.local = _player()
	game.world = DATA.new()._world()
	var session := QuoteSession.new()
	session.fixture = game
	game.session = session
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	assert_true(authority.bind_world("resource-namespace"))
	var before := RECORD.portable_projection(game.local.save_data())
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	var source := Node3D.new()
	for key: String in ["building_id", "realm", "building_uid"]:
		source.set_meta(key, {"building_id": "den", "realm": "meadows", "building_uid": "b3"}[key])
	var panel := _panel_for(game, session, source, {}, -1)
	panel.call("_station_action", "groom", {"creature_uid": before.party[0].uid})
	var original: Dictionary = panel.get("_station_intent").duplicate(true)
	assert_eq(session.requests.size(), 0, "the tap waits for physical release before the producer call")
	var condition := preload("res://scripts/creatures/creature_condition.gd")
	condition.tick(game.local.party.at(0), condition.config(), 1.0)
	assert_false(E._equivalent(RECORD.portable_projection(game.local.save_data()), before))
	# Enter the actual post-release send method without claiming controller proof.
	panel.set("_groom_waiting_release", false)
	panel.call("_submit_station_original")
	assert_eq(session.requests.size(), 1)
	assert_true(int(session.requests[0].revision) > 0, "first send adopts the actual newer admitted passive baseline")
	var sent_revision: int = session.requests[0].revision
	assert_eq(session.requests[0].intent, original)
	condition.tick(game.local.party.at(0), condition.config(), 1.0)
	session.homestead_personal_view()
	assert_true(authority.revision(DATA.CHARACTER) > sent_revision)
	panel.call("_submit_station_original")
	assert_eq(session.requests.size(), 2)
	assert_eq(session.requests[1].revision, sent_revision, "world-save failure preserves the sent revision")
	assert_eq(session.requests[1].intent, original)
	panel.free()
	source.free()
	session.free()
	game.free()

func test_guest_passive_drift_in_transit_is_merged_not_refused() -> void:
	var player := _player()
	var before := RECORD.portable_projection(player.save_data())
	var row := _row(before, _intent(before), _context())
	assert_false(row.is_empty())
	if row.is_empty(): return
	var condition := preload("res://scripts/creatures/creature_condition.gd")
	condition.tick(player.party.at(0), condition.config(), 1.0)
	var arrived := RECORD.portable_projection(player.save_data())
	assert_false(E._equivalent(arrived, before))
	# Formerly an outstanding shared-carrier gap (a refusal); passive care
	# accrued in transit is now merged at install (essence.merge_owner_passive).
	var plan := DELIVERY.owner_plan(arrived, row, RECORD.errors)
	assert_true(plan.get("ok") == true and plan.get("duplicate") == false, "packet-transit care drift is the owner's, not a conflict " + str(plan))
	var merged := E.merge_owner_passive(row.after, row.before, arrived)
	assert_true(E.owner_matches_after(merged, row.after), "the groom's decided result stands")
	# Exact either way (F01#6a): a field the groom left alone is the owner's
	# own value bit for bit; a field it decided carries the owner's drift.
	var expected_nourishment: float = arrived.party[0].nourishment \
		if E._equivalent(row.after.party[0].nourishment, row.before.party[0].nourishment) \
		else arrived.party[0].nourishment + row.after.party[0].nourishment - row.before.party[0].nourishment
	assert_eq(merged.party[0].nourishment, expected_nourishment, "with the owner's own drift kept")
	assert_eq(player.inventory.count("fiber"), 0)

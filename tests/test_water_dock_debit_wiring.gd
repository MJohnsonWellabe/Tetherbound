extends "res://tests/test_case.gd"

## F15 paid-debit crash/retry, end to end over the REAL host ledger
## (`world_ledger.gd` -> `water_dock_rules.gd`) and the client escrow
## (`water_dock_debit.gd`), exactly as `water_dock_actions.gd` wires them:
## escrow + persist before submit, receipts in the host's durable world flags,
## the guest settling/refunding from its replica of those flags. A "crash" is a
## JSON round trip of the last persisted character; a "lost delta" is a delta
## the client replica never applies; a "rejoin" is the host snapshot.

const DEBIT := preload("res://scripts/net/water_dock_debit.gd")
const RULES := preload("res://scripts/world/water_dock_rules.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")

const INSTANCE := "host-world-instance"
const ACTION := "reedhaven_repair"
const FLAG := "water_dock_reedhaven_repaired"
const GUEST := "character-guest"
const OTHER := "character-other"
const GUEST_PEER := 7
const OTHER_PEER := 9


class Bag extends RefCounted:
	var items: Dictionary = {}
	func count(id: String) -> int:
		return int(items.get(id, 0))
	func add(id: String, n: int) -> int:
		items[id] = count(id) + n
		return 0
	func remove(id: String, n: int) -> bool:
		if count(id) < n:
			return false
		items[id] = count(id) - n
		return true


var host: RefCounted
var cost: Dictionary
var position: Vector3


func before_each() -> void:
	var world: RefCounted = WORLD_STATE.new()
	world.flags.set_flag("water_swim_lesson_complete")
	world.reward_delivery_namespace = INSTANCE
	host = WORLD_LEDGER.new(world)
	var action := _action()
	cost = action.cost
	var field := FIELD.new()
	position = RULES.action_position(action, FIELD.load_config(), field.height_at)


func _action(id: String = ACTION) -> Dictionary:
	for row: Dictionary in RULES.load_data().actions:
		if str(row.id) == id:
			return row
	return {}


func _character(id: String, reed: int = 8, wood: int = 6) -> Dictionary:
	var bag := Bag.new()
	bag.items = {"reed_fiber": reed, "driftwood": wood}
	return {"character_id": id, "escrow": {}, "inventory": bag}


## A crash: everything in memory is gone; the character file is what remains.
func _reload(saved: Dictionary) -> Dictionary:
	var bag := Bag.new()
	bag.items = (JSON.parse_string(JSON.stringify(saved.inventory.items)) as Dictionary)
	return {"character_id": saved.character_id,
		"escrow": JSON.parse_string(JSON.stringify(saved.escrow)), "inventory": bag}


## The persisted copy (the escrow row is saved BEFORE the submit, P5).
func _save(state: Dictionary) -> Dictionary:
	return _reload(state)


func _intent(state: Dictionary, txn: String, peer: int, character: String) -> Dictionary:
	var row: Dictionary = state.escrow[txn]
	var counts: Dictionary = {}
	for item: String in cost:
		counts[item] = int(state.inventory.count(item)) + int((row.get("cost", {}) as Dictionary).get(item, 0))
	return {"kind": "water_dock_action", "realm": "water", "action_id": ACTION,
		"inventory": counts, "txn_id": txn, "world_instance_id": str(row.world_instance_id),
		"attempt": int(row.attempt), "_actor_character_id": character,
		"_water_actor": {"peer": peer, "character_id": character, "realm": "water",
			"position": position, "inventory": counts}}


func _begin(state: Dictionary, facts: Variant = null) -> String:
	var begun := DEBIT.begin(state, ACTION, cost, INSTANCE, facts)
	assert_true(bool(begun.ok), "escrow reserves: %s" % str(begun))
	return str(begun.txn_id)


func _replica_from_snapshot() -> RefCounted:
	var replica: RefCounted = WORLD_STATE.new()
	replica.load_data(host.world.save_data())
	return replica


func _facts(world: RefCounted) -> Dictionary:
	return RULES.world_facts(world.flags, INSTANCE)


func _item_takes(delta: Dictionary) -> int:
	var n := 0
	for op: Dictionary in delta.get("ops", []):
		if str(op.op) == "item_take":
			n += 1
	return n


# --- rules ------------------------------------------------------------------

func test_escrowed_intent_commits_a_receipt_and_no_item_take() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	assert_eq(guest.inventory.count("reed_fiber"), 2, "escrow debits the bag before anything is sent")
	var verdict: Dictionary = host.commit(_intent(guest, txn, GUEST_PEER, GUEST), GUEST_PEER)
	assert_true(bool(verdict.ok), str(verdict))
	assert_eq(_item_takes(verdict.delta), 0, "the escrow IS the debit (P7)")
	assert_true(host.world.flags.has(FLAG))
	assert_true(host.world.flags.has(RULES.receipt_flag(ACTION, GUEST, txn)),
		"the receipt lands in the same commit as the action flag")
	var receipt: Dictionary = RULES.receipt_for_txn(host.world.flags, txn, ACTION, GUEST, FLAG)
	assert_eq(str(receipt.payer_character_id), GUEST)
	assert_eq(str(receipt.action_id), ACTION)
	assert_eq(RULES.parse_receipt("water_claim:dock_paid:a:b", INSTANCE), {}, "malformed receipt ids never parse")
	assert_eq(RULES.parse_receipt("water_claim:character-x:pickup", INSTANCE), {}, "other water_claim facts are not receipts")


func test_resubmitted_committed_txn_is_answered_already_done_before_other_checks() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	var intent := _intent(guest, txn, GUEST_PEER, GUEST)
	assert_true(bool(host.commit(intent, GUEST_PEER).ok))
	var far := intent.duplicate(true)
	far._water_actor.position = position + Vector3(50, 0, 0)
	far._water_actor.realm = "stormwood"
	var again: Dictionary = host.commit(far, GUEST_PEER)
	assert_eq(str(again.code), "already_done", "P3: the txn's own receipt answers first")
	assert_eq(int(host.seq), 1, "nothing committed twice")


func test_host_refuses_a_txn_that_does_not_match_the_resolved_payer_or_attempt() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	var forged := _intent(guest, txn, OTHER_PEER, OTHER)
	assert_eq(str(host.commit(forged, OTHER_PEER).code), "malformed",
		"a txn minted for one character cannot be paid by another")
	var bumped := _intent(guest, txn, GUEST_PEER, GUEST)
	bumped.attempt = 2
	assert_eq(str(host.commit(bumped, GUEST_PEER).code), "malformed")
	var zero := _intent(guest, txn, GUEST_PEER, GUEST)
	zero.attempt = 0
	assert_eq(str(host.commit(zero, GUEST_PEER).code), "malformed")
	assert_false(host.world.flags.has(FLAG))


func test_host_world_instance_in_context_refuses_a_stale_world() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	var intent := _intent(guest, txn, GUEST_PEER, GUEST)
	# The request cannot vouch for its own world: the host's instance decides.
	intent._water_actor["world_instance_id"] = "some-other-world"
	host.world.reward_delivery_namespace = "some-other-world"
	assert_eq(str(host.commit(intent, GUEST_PEER).code), "wrong_world")
	host.world.reward_delivery_namespace = ""
	assert_eq(str(host.commit(intent, GUEST_PEER).code), "wrong_world",
		"no host instance to check against is refused, not waved through")
	assert_false(host.world.flags.has(FLAG))
	host.world.reward_delivery_namespace = INSTANCE
	assert_true(bool(host.commit(intent, GUEST_PEER).ok))


func test_legacy_unescrowed_intent_keeps_its_item_take() -> void:
	var intent := {"kind": "water_dock_action", "realm": "water", "action_id": ACTION,
		"inventory": {"reed_fiber": 6, "driftwood": 4}, "_water_actor": {"peer": GUEST_PEER,
			"character_id": GUEST, "realm": "water", "position": position,
			"inventory": {"reed_fiber": 6, "driftwood": 4}}}
	var verdict: Dictionary = host.commit(intent, GUEST_PEER)
	assert_true(bool(verdict.ok))
	assert_eq(_item_takes(verdict.delta), 2)


# --- the F15 crash/retry paths ------------------------------------------------

func test_crash_after_delta_settles_on_rejoin_and_charges_once() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	var saved := _save(guest)
	var replica: RefCounted = _replica_from_snapshot()
	var verdict: Dictionary = host.commit(_intent(guest, txn, GUEST_PEER, GUEST), GUEST_PEER)
	replica.apply_delta(verdict.delta)
	assert_eq(_item_takes(verdict.delta), 0)
	# Crash: the in-memory state is gone; the disk still holds the pending row
	# and the ALREADY debited bag. Before this fix the disk held 8/6 here.
	guest = _reload(saved)
	assert_eq(guest.inventory.count("reed_fiber"), 2)
	assert_eq(guest.inventory.count("driftwood"), 2)
	var rejoin := DEBIT.reconcile(guest, _facts(_replica_from_snapshot()), INSTANCE)
	assert_eq(rejoin.settled, [txn])
	assert_eq(str(guest.escrow[txn].status), "settled")
	assert_eq(str(DEBIT.begin(guest, ACTION, cost, INSTANCE, _facts(replica)).code), "already_paid",
		"a retry press cannot reserve again")
	assert_eq(guest.inventory.count("reed_fiber"), 2)
	assert_eq(guest.inventory.count("driftwood"), 2)


func test_host_commits_but_delta_never_arrives_then_resubmit_settles_once() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	var saved := _save(guest)
	var stale: RefCounted = _replica_from_snapshot()
	assert_true(bool(host.commit(_intent(guest, txn, GUEST_PEER, GUEST), GUEST_PEER).ok))
	# The delta is lost with the crash; the guest's replica never saw it.
	guest = _reload(saved)
	var before := DEBIT.reconcile(guest, _facts(stale), INSTANCE)
	assert_eq(before.needs_submit, [txn], "absence is never a refund: resubmit the same txn")
	assert_eq(guest.inventory.count("reed_fiber"), 2)
	# Resubmit the unchanged txn (begin hands back the pending row).
	var again := DEBIT.begin(guest, ACTION, cost, INSTANCE, _facts(stale))
	assert_eq(str(again.code), "already_pending")
	assert_eq(str(again.txn_id), txn)
	var verdict: Dictionary = host.commit(_intent(guest, txn, GUEST_PEER, GUEST), GUEST_PEER)
	assert_eq(str(verdict.code), "already_done")
	assert_eq(int(host.seq), 1, "the host committed exactly once")
	# The refusal is answered from the replica's durable receipts (rejoin snapshot).
	var after := DEBIT.reconcile(guest, _facts(_replica_from_snapshot()), INSTANCE)
	assert_eq(after.settled, [txn])
	assert_eq(guest.inventory.count("reed_fiber"), 2, "kept the debit: the txn DID commit")
	assert_eq(guest.inventory.count("driftwood"), 2)


func test_intent_lost_before_the_host_resubmits_and_commits_once() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	guest = _reload(_save(guest))
	assert_eq(DEBIT.reconcile(guest, _facts(_replica_from_snapshot()), INSTANCE).needs_submit, [txn])
	var verdict: Dictionary = host.commit(_intent(guest, txn, GUEST_PEER, GUEST), GUEST_PEER)
	assert_true(bool(verdict.ok))
	var replica := _replica_from_snapshot()
	assert_eq(DEBIT.reconcile(guest, _facts(replica), INSTANCE).settled, [txn])
	assert_true(replica.flags.has(FLAG))
	assert_eq(guest.inventory.count("reed_fiber"), 2)
	assert_eq(guest.inventory.count("driftwood"), 2)


func test_someone_else_repaired_first_refunds_the_pending_payment() -> void:
	var guest := _character(GUEST)
	var other := _character(OTHER)
	var mine := _begin(guest)
	var theirs := _begin(other)
	assert_true(bool(host.commit(_intent(other, theirs, OTHER_PEER, OTHER), OTHER_PEER).ok))
	assert_eq(str(host.commit(_intent(guest, mine, GUEST_PEER, GUEST), GUEST_PEER).code), "already_done")
	var result := DEBIT.reconcile(guest, _facts(_replica_from_snapshot()), INSTANCE)
	assert_eq(result.refunded, [mine], "another txn's receipt proves this one cannot commit")
	assert_eq(guest.inventory.count("reed_fiber"), 8)
	assert_eq(guest.inventory.count("driftwood"), 6)
	assert_eq(DEBIT.reconcile(other, _facts(_replica_from_snapshot()), INSTANCE).settled, [theirs])
	assert_eq(other.inventory.count("reed_fiber"), 2)


func test_flag_without_receipt_answers_the_legacy_receipt_and_refunds() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	host.world.flags.set_flag(FLAG)
	var facts := _facts(host.world)
	assert_eq(facts[ACTION], [DEBIT.legacy_receipt(INSTANCE, ACTION)])
	assert_eq(DEBIT.reconcile(guest, facts, INSTANCE).refunded, [txn])
	assert_eq(guest.inventory.count("reed_fiber"), 8)


## Deliberate design correction (not a weakening): water_dock_actions.gd
## cannot meet P1/P2 (refusals carry no action, no sticky host refusal), so it
## NEVER refunds on journal_failed. The row stays pending, the next press
## resends the SAME txn, the host commits it once and the payer is charged
## exactly once. The node-level wiring is covered by
## test_water_dock_actions_wiring.gd.
func test_journal_failed_keeps_the_row_pending_and_the_same_txn_commits_once() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	# journal_failed: the host rolled its commit back; the wiring refunds nothing.
	var world := _replica_from_snapshot()
	assert_eq(DEBIT.reconcile(guest, _facts(world), INSTANCE).needs_submit, [txn],
		"after journal_failed the row is still pending and resubmittable")
	assert_eq(guest.inventory.count("reed_fiber"), 2, "still escrowed, never refunded")
	var again := DEBIT.begin(guest, ACTION, cost, INSTANCE, _facts(world))
	assert_eq(str(again.code), "already_pending")
	assert_eq(str(again.txn_id), txn, "the resend is the same txn, never a fresh one")
	assert_true(bool(host.commit(_intent(guest, txn, GUEST_PEER, GUEST), GUEST_PEER).ok))
	assert_eq(str(host.commit(_intent(guest, txn, GUEST_PEER, GUEST), GUEST_PEER).code), "already_done")
	assert_eq(int(host.seq), 1, "committed exactly once")
	assert_eq(DEBIT.reconcile(guest, _facts(host.world), INSTANCE).settled, [txn])
	assert_eq(guest.inventory.count("reed_fiber"), 2, "charged exactly once, never free")
	assert_eq(guest.inventory.count("driftwood"), 2)
	assert_eq(guest.escrow.size(), 1, "one txn only")


# --- forged receipts (any guest can set_world_flag any world flag) ------------

func _forge(flag: String, peer: int = OTHER_PEER) -> void:
	var forged: Dictionary = host.commit({"kind": "set_world_flag", "realm": "water", "id": flag, "value": true}, peer)
	assert_true(bool(forged.ok), "the shared ledger lets a guest write the flag: %s" % str(forged))


func test_forged_own_receipt_without_action_flag_neither_blocks_nor_charges_for_nothing() -> void:
	var guest := _character(GUEST)
	# The victim's txn is computable from public inputs; the griefer forges its
	# receipt before (or while) the victim presses, without the action flag.
	var txn := DEBIT.txn_id(INSTANCE, ACTION, GUEST, 1)
	_forge(RULES.receipt_flag(ACTION, GUEST, txn))
	assert_false(_facts(host.world).has(ACTION), "a receipt without its action flag is no fact")
	assert_eq(_begin(guest, _facts(host.world)), txn)
	var verdict: Dictionary = host.commit(_intent(guest, txn, GUEST_PEER, GUEST), GUEST_PEER)
	assert_true(bool(verdict.ok), "the host commits the press normally: %s" % str(verdict))
	assert_true(host.world.flags.has(FLAG), "the action is done")
	assert_eq(DEBIT.reconcile(guest, _facts(host.world), INSTANCE).settled, [txn])
	assert_eq(guest.inventory.count("reed_fiber"), 2, "charged exactly once")
	assert_eq(guest.inventory.count("driftwood"), 2)
	assert_eq(str(DEBIT.begin(guest, ACTION, cost, INSTANCE, _facts(host.world)).code), "already_paid")


func test_forged_receipt_before_press_does_not_settle_the_victims_row() -> void:
	var guest := _character(GUEST)
	var txn := DEBIT.txn_id(INSTANCE, ACTION, GUEST, 1)
	_forge(RULES.receipt_flag(ACTION, GUEST, txn))
	assert_eq(_begin(guest, _facts(host.world)), txn)
	var before := DEBIT.reconcile(guest, _facts(host.world), INSTANCE, [txn])
	assert_eq(before.settled, [], "a forged receipt alone never settles the row")
	assert_eq(before.refunded, [])
	assert_eq(str(guest.escrow[txn].status), "pending")


func test_forged_foreign_receipt_while_in_flight_never_refunds_and_settles_once() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	# The copy is on the wire; the griefer forges ANOTHER payer's receipt.
	_forge(RULES.receipt_flag(ACTION, OTHER, DEBIT.txn_id(INSTANCE, ACTION, OTHER, 1)))
	var during := DEBIT.reconcile(guest, _facts(_replica_from_snapshot()), INSTANCE, [txn])
	assert_eq(during.refunded, [], "no refund while the victim's copy is in flight")
	assert_eq(guest.inventory.count("reed_fiber"), 2)
	assert_true(bool(host.commit(_intent(guest, txn, GUEST_PEER, GUEST), GUEST_PEER).ok))
	var after := DEBIT.reconcile(guest, _facts(_replica_from_snapshot()), INSTANCE)
	assert_eq(after.settled, [txn], "all receipts are kept: the victim's own one settles it")
	assert_eq(after.refunded, [])
	assert_eq(guest.inventory.count("reed_fiber"), 2, "charged exactly once, never free")
	assert_eq(guest.inventory.count("driftwood"), 2)


func test_forged_foreign_receipt_with_flag_set_refunds_only_when_not_in_flight() -> void:
	var guest := _character(GUEST)
	var txn := _begin(guest)
	_forge(RULES.receipt_flag(ACTION, OTHER, "forged-txn"))
	_forge(FLAG)
	# Forging the flag too is today's bound: the task is marked done and the
	# victim pays nothing. Never while its copy is still in flight, though.
	assert_eq(DEBIT.reconcile(guest, _facts(host.world), INSTANCE, [txn]).refunded, [])
	assert_eq(guest.inventory.count("reed_fiber"), 2)
	assert_eq(str(host.commit(_intent(guest, txn, GUEST_PEER, GUEST), GUEST_PEER).code), "already_done",
		"the host never commits the victim's txn after the flag is set")
	assert_eq(DEBIT.reconcile(guest, _facts(host.world), INSTANCE).refunded, [txn])
	assert_eq(guest.inventory.count("reed_fiber"), 8, "the victim pays nothing")
	assert_eq(guest.inventory.count("driftwood"), 6)


func test_host_receipt_lookup_needs_action_payer_and_flag() -> void:
	var txn := DEBIT.txn_id(INSTANCE, ACTION, GUEST, 1)
	host.world.flags.set_flag(RULES.receipt_flag(ACTION, GUEST, txn))
	assert_eq(RULES.receipt_for_txn(host.world.flags, txn, ACTION, GUEST, FLAG), {}, "no action flag, no receipt")
	host.world.flags.set_flag(FLAG)
	assert_eq(str(RULES.receipt_for_txn(host.world.flags, txn, ACTION, GUEST, FLAG).get("txn_id", "")), txn)
	assert_eq(RULES.receipt_for_txn(host.world.flags, txn, ACTION, OTHER, FLAG), {}, "payer must match")
	assert_eq(RULES.receipt_for_txn(host.world.flags, txn, "shellwatch_release", GUEST, FLAG), {},
		"action must match")

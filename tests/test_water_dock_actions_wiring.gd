extends "res://tests/test_case.gd"

## F15 wiring of the paid-dock escrow in `water_dock_actions.gd` itself (the
## node, not the pure module): refusal attribution and the journal_failed
## verdict, as a GUEST whose replica is the host's snapshot. The host is the
## real `world_ledger.gd`; the Game autoload is a minimal fixture exposing
## only what the node reads (local, world, session, is_host, messages).

const ACTIONS := preload("res://scripts/world/water_dock_actions.gd")
const DEBIT := preload("res://scripts/net/water_dock_debit.gd")
const RULES := preload("res://scripts/world/water_dock_rules.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")

const INSTANCE := "host-world-instance"
const ACTION := "reedhaven_repair"
const FLAG := "water_dock_reedhaven_repaired"
const GUEST := "character-guest"
const GUEST_PEER := 7


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


class Local extends RefCounted:
	var character_id := GUEST
	var satchel_escrow: Dictionary = {}
	var inventory := Bag.new()


class FakeGame extends Node:
	var local := Local.new()
	var world: RefCounted
	var session: Variant = null
	var save_system: Variant = null
	var messages: Array = []
	func is_host() -> bool:
		return false
	func push_world_message(message: String) -> void:
		messages.append(message)


## Stands in for the sibling F13 WaterLocalChains node.
class FakeChains extends Node:
	var steps: Array = []
	func pending_steps() -> Array:
		return steps


var host: RefCounted
var game: FakeGame
var parent: Node
var docks: Node
var chains: FakeChains
var cost: Dictionary
var position: Vector3


func before_each() -> void:
	var world: RefCounted = WORLD_STATE.new()
	world.flags.set_flag("water_swim_lesson_complete")
	world.reward_delivery_namespace = INSTANCE
	host = WORLD_LEDGER.new(world)
	var action: Dictionary = {}
	for row: Dictionary in RULES.load_data().actions:
		if str(row.id) == ACTION:
			action = row
	cost = action.cost
	var field := FIELD.new()
	position = RULES.action_position(action, FIELD.load_config(), field.height_at)
	game = FakeGame.new()
	game.local.inventory.items = {"reed_fiber": 8, "driftwood": 6}
	_sync_replica()
	parent = Node.new()
	docks = ACTIONS.new()
	parent.add_child(docks)
	chains = FakeChains.new()
	chains.name = "WaterLocalChains"
	parent.add_child(chains)
	docks.set("_game", game)
	docks.set("_data", RULES.load_data())


func after_each() -> void:
	parent.free()
	game.free()


## The guest's replica: the host's current durable world (a snapshot).
func _sync_replica() -> void:
	var replica: RefCounted = WORLD_STATE.new()
	replica.load_data(host.world.save_data())
	replica.world_id = ""
	replica.reward_delivery_namespace = INSTANCE
	game.world = replica


func _state() -> Dictionary:
	return {"character_id": GUEST, "escrow": game.local.satchel_escrow, "inventory": game.local.inventory}


## A paid press as the node makes it: escrow, then one copy in flight.
func _press() -> String:
	var begun := DEBIT.begin(_state(), ACTION, cost, INSTANCE, RULES.world_facts(game.world.flags, INSTANCE))
	assert_true(bool(begun.ok), str(begun))
	var txn := str(begun.txn_id)
	(docks.get("_pending") as Dictionary)[ACTION] = {"txn": txn, "link": 0}
	return txn


func _commit(txn: String) -> Dictionary:
	var row: Dictionary = game.local.satchel_escrow[txn]
	var counts: Dictionary = {}
	for item: String in cost:
		counts[item] = int(game.local.inventory.count(item)) + int((row.get("cost", {}) as Dictionary).get(item, 0))
	return host.commit({"kind": "water_dock_action", "realm": "water", "action_id": ACTION,
		"inventory": counts, "txn_id": txn, "world_instance_id": INSTANCE, "attempt": int(row.attempt),
		"_actor_character_id": GUEST, "_water_actor": {"peer": GUEST_PEER, "character_id": GUEST,
			"realm": "water", "position": position, "inventory": counts}}, GUEST_PEER)


func _in_flight() -> bool:
	return bool(docks.call("_in_flight", ACTION))


func test_refusal_for_a_local_chain_step_keeps_the_paid_copy_in_flight() -> void:
	var txn := _press()
	chains.steps = ["cradle_care_berries"]
	# Ledger refusals carry no action or txn: this one belongs to the F13 step.
	docks.call("_on_refused", "water_dock_action", "prerequisite", "Not yet.", {"code": "prerequisite"})
	assert_true(_in_flight(), "an unattributable refusal never releases the paid copy")
	assert_eq(str(game.local.satchel_escrow[txn].status), "pending")


func test_refusal_with_two_dock_copies_in_flight_releases_neither() -> void:
	_press()
	(docks.get("_pending") as Dictionary)["shellwatch_release"] = true
	docks.call("_on_refused", "water_dock_action", "too_far", "Move closer.", {"code": "too_far"})
	assert_true(_in_flight(), "paid copy stays in flight")
	assert_true((docks.get("_pending") as Dictionary).has("shellwatch_release"), "so does the other one")


func test_refusal_naming_another_txn_keeps_the_copy_in_flight() -> void:
	var txn := _press()
	docks.call("_on_refused", "water_dock_action", "journal_failed", "Could not save.",
		{"code": "journal_failed", "txn_id": "some-other-txn", "world_instance_id": INSTANCE})
	assert_true(_in_flight())
	assert_eq(str(game.local.satchel_escrow[txn].status), "pending")


func test_the_only_copy_in_flight_is_released_by_an_unattributed_refusal() -> void:
	var txn := _press()
	docks.call("_on_refused", "water_dock_action", "too_far", "Move closer.", {"code": "too_far"})
	assert_false(_in_flight(), "exactly one copy in flight: the refusal is its verdict")
	assert_eq(str(game.local.satchel_escrow[txn].status), "pending", "and the row stays pending to resubmit")


func test_journal_failed_keeps_the_row_pending_and_the_same_txn_resend_settles_once() -> void:
	var txn := _press()
	assert_eq(game.local.inventory.count("reed_fiber"), 2)
	# The host's durable world save failed and it rolled the commit back.
	docks.call("_on_refused", "water_dock_action", "journal_failed", "The world could not save.",
		{"code": "journal_failed", "txn_id": txn, "world_instance_id": INSTANCE})
	assert_false(_in_flight(), "the verdict for this txn releases its copy")
	assert_eq(str(game.local.satchel_escrow[txn].status), "pending", "journal_failed never refunds")
	assert_eq(game.local.inventory.count("reed_fiber"), 2, "items stay escrowed")
	assert_eq(str(docks.call("_pending_txn", ACTION, INSTANCE)), txn, "the next press resends the SAME txn")
	assert_true(bool(_commit(txn).ok))
	assert_eq(str(_commit(txn).code), "already_done", "a duplicate copy is deduped by its receipt")
	assert_eq(int(host.seq), 1, "committed exactly once")
	_sync_replica()
	assert_true(bool(docks.call("_reconcile")))
	assert_eq(str(game.local.satchel_escrow[txn].status), "settled")
	assert_eq(game.local.satchel_escrow.size(), 1, "one txn only")
	assert_eq(game.local.inventory.count("reed_fiber"), 2, "charged exactly once, never free")
	assert_eq(game.local.inventory.count("driftwood"), 2)

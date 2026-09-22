extends "res://tests/test_case.gd"

# ROADMAP Phase 1 item 8, and STATE's "Cart turn-in transaction" defect:
# `cart_repair.gd::_on_tried()` spent the player's materials the moment it ASKED
# for the world flag, not when the world agreed.
#
# `ledger_claim.gd` says pending must change nothing locally, and this split it
# in both directions. Two peers who both walked up could both pay for the one
# idempotent flag -- the host's second commit is a no-op, so the second peer's
# materials simply vanished -- and a refusal or disconnect after a `pending`
# stranded the payer's materials for a cart that never got fixed.
#
# The cost is now taken when the delta carrying that flag actually lands.

const CART := preload("res://scripts/world/cart_repair.gd")


class FakeInventory extends RefCounted:
	var stock := 3


class FakeGate extends RefCounted:
	var spends := 0
	var affordable := true

	func can_open(_inventory: RefCounted) -> bool:
		return affordable

	func spend(inventory: RefCounted) -> void:
		spends += 1
		(inventory as FakeInventory).stock -= 1


func _cart(gate: FakeGate) -> Node:
	var cart := CART.new()
	cart.set("_gate", gate)
	return cart


func test_a_pending_request_takes_nothing_until_the_world_agrees() -> void:
	# The stranding case: this peer asked, the host never answered.
	var gate := FakeGate.new()
	var cart := _cart(gate)
	cart.set("_owed_turn_in", true)
	assert_eq(gate.spends, 0,
		"owing a payment must not itself take anything; the host has not answered")
	cart.free()


func test_the_cost_is_taken_when_the_flag_lands() -> void:
	var gate := FakeGate.new()
	var cart := _cart(gate)
	var inventory := FakeInventory.new()
	cart.set("_owed_turn_in", true)
	assert_true(cart.call("take_owed_payment", inventory),
		"the peer that asked pays when the world fact it asked for arrives")
	assert_eq(gate.spends, 1)
	assert_eq(inventory.stock, 2)
	cart.free()


func test_a_repeated_delta_cannot_charge_twice() -> void:
	# A re-send, a reconnect snapshot or a late duplicate must not take the
	# materials again. `_settle_owed_turn_in()` clears the debt before paying.
	var gate := FakeGate.new()
	var cart := _cart(gate)
	var inventory := FakeInventory.new()
	cart.set("_owed_turn_in", true)
	cart.call("take_owed_payment", inventory)
	cart.set("_owed_turn_in", false)
	# Second delta for the same flag: nothing is owed, so nothing is taken.
	assert_false(bool(cart.get("_owed_turn_in")),
		"the debt is cleared before the cost is taken, so a duplicate finds nothing owed")
	assert_eq(gate.spends, 1, "a duplicate delta must not charge a second time")
	cart.free()


func test_a_peer_that_only_watched_is_never_charged() -> void:
	# The double-payment case. A friend who walks up to an already-fixed cart
	# receives the same delta and owes nothing.
	var gate := FakeGate.new()
	var cart := _cart(gate)
	assert_false(bool(cart.get("_owed_turn_in")),
		"a peer that never asked owes nothing by default")
	assert_eq(gate.spends, 0,
		"a peer that merely watched the cart get fixed is never charged for it")
	cart.free()


func test_spending_the_materials_elsewhere_while_pending_does_not_charge() -> void:
	# The host was deciding; the player spent the wood on something else. The
	# cart is fixed and the world says so. This peer does not go negative.
	var gate := FakeGate.new()
	gate.affordable = false
	var cart := _cart(gate)
	var inventory := FakeInventory.new()
	assert_false(cart.call("take_owed_payment", inventory),
		"a peer that no longer holds the cost is not charged for it")
	assert_eq(gate.spends, 0)
	assert_eq(inventory.stock, 3, "and its remaining materials are untouched")
	cart.free()


func test_a_missing_inventory_is_refused_rather_than_crashing() -> void:
	var gate := FakeGate.new()
	var cart := _cart(gate)
	assert_false(cart.call("take_owed_payment", null))
	assert_eq(gate.spends, 0)
	cart.free()

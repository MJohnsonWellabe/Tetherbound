extends "res://tests/test_case.gd"

## Deterministic fixture for smoke_playground's chop receipt. This does not
## claim to be the full playground smoke: it drives ToolHold's real
## _resolve_swing() callback path against a real Inventory so observer delay
## and false-positive signals remain covered without waiting on frame timing.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const TOOL_HOLD := preload("res://scripts/player/tool_hold.gd")
const PLAYGROUND_SMOKE := preload("res://tests/smoke_playground.gd")


class ControlledClock extends RefCounted:
	var now_msec := 0.0


	func read_msec() -> float:
		return now_msec


class HarvestFixture extends Node:
	var inventory: RefCounted
	var required_tool: String
	var wear_tool := true


	func gather(held_tool: String = "") -> Dictionary:
		if wear_tool and held_tool == required_tool:
			var slot := int(inventory.call("find_slot", required_tool))
			if slot >= 0:
				inventory.call("damage_tool", slot, 1)
		return {"gathered": wear_tool and held_tool == required_tool}


func test_delayed_frame_observer_cannot_move_the_durable_callback_receipt() -> void:
	var context := _fixture(true, 460.0)
	var receipt: RefCounted = context.receipt
	# Move the axe after the receipt was armed. Both the harvest fixture and
	# receipt must resolve the item again by identity rather than retain slot 0.
	(context.bag as RefCounted).call("move_slot", 0, 5)
	(context.hold as Node).call("_resolve_swing")

	assert_almost_eq(float(receipt.call("durable_wall_seconds")), 0.460, 0.0001,
		"the callback must capture the wall time at the actual durability decrease")
	assert_eq(int((receipt.get("observation") as Dictionary).durability_slot), 5,
		"the callback must re-resolve the required tool by identity")
	(context.clock as ControlledClock).now_msec = 526.0
	assert_eq(int((receipt.call("inventory_snapshot") as Dictionary).durability),
		int(context.durability_before) - 1,
		"the later frame must observe the same real Inventory wear")
	assert_almost_eq(float(receipt.call("durable_wall_seconds")), 0.460, 0.0001,
		"a delayed observer must not rewrite the durable callback receipt")
	assert_eq(PLAYGROUND_SMOKE.ChopImpactReceipt.impact_window_verdict(
		float(receipt.call("durable_wall_seconds")), 0.625, 0.6), "accepted")
	_free_fixture(context)


func test_toolhold_signal_without_durability_loss_is_rejected() -> void:
	var context := _fixture(false, 460.0)
	var receipt: RefCounted = context.receipt
	(context.hold as Node).call("_resolve_swing")

	assert_true(bool((receipt.get("observation") as Dictionary).get("signal_seen", false)),
		"the fixture must prove ToolHold really emitted its unconditional signal")
	assert_eq(float(receipt.call("durable_wall_seconds")), -1.0,
		"a signal without required-tool wear is not an impact receipt")
	assert_eq(PLAYGROUND_SMOKE.ChopImpactReceipt.impact_window_verdict(
		float(receipt.call("durable_wall_seconds")), 0.625, 0.6), "missing")
	_free_fixture(context)


func test_early_and_late_durable_receipts_fail_the_unchanged_window() -> void:
	var early := _fixture(true, 300.0)
	(early.hold as Node).call("_resolve_swing")
	assert_eq(PLAYGROUND_SMOKE.ChopImpactReceipt.impact_window_verdict(
		float((early.receipt as RefCounted).call("durable_wall_seconds")), 0.625, 0.6), "early",
		"0.48 remains below the unchanged 0.52 lower bound")
	_free_fixture(early)

	var late := _fixture(true, 510.0)
	(late.hold as Node).call("_resolve_swing")
	assert_eq(PLAYGROUND_SMOKE.ChopImpactReceipt.impact_window_verdict(
		float((late.receipt as RefCounted).call("durable_wall_seconds")), 0.625, 0.6), "late",
		"0.816 remains above the unchanged 0.80 upper bound")
	_free_fixture(late)


func _fixture(wear_tool: bool, impact_msec: float) -> Dictionary:
	var db := ITEM_DB.new()
	var bag := INVENTORY.new(db)
	bag.add("axe", 1)
	var slot := int(bag.find_slot("axe"))
	var durability_before := int(bag.durability_at(slot))
	var hold := TOOL_HOLD.new()
	hold.set("_equipped", "axe")
	hold.set("_swing_left", 0.625 - impact_msec / 1000.0)
	var harvest := HarvestFixture.new()
	harvest.name = "BoundedHarvestFixture"
	harvest.inventory = bag
	harvest.required_tool = "axe"
	harvest.wear_tool = wear_tool
	hold.set("_swing_target", harvest)
	var clock := ControlledClock.new()
	clock.now_msec = impact_msec
	var receipt := PLAYGROUND_SMOKE.ChopImpactReceipt.new(
		bag, hold, "axe", durability_before, 0.625, 0.0, clock.read_msec)
	hold.connect("swing_connected", receipt.on_swing_connected)
	return {
		"bag": bag,
		"clock": clock,
		"durability_before": durability_before,
		"harvest": harvest,
		"hold": hold,
		"receipt": receipt,
	}


func _free_fixture(context: Dictionary) -> void:
	(context.hold as Node).free()
	(context.harvest as Node).free()

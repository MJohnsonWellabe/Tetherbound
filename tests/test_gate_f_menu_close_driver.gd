extends TestCase

const DRIVER := preload("res://tools/gate_f/menu_close_driver.gd")

## Callback fixtures establish orchestration, not live campaign proof.
class Fixture extends RefCounted:
	var layers := 1
	var latch := 0
	var other_owner := false
	var stuck := false
	var refused := false
	var stopped := false
	var taps := 0
	var world_taps := 0
	var waits := 0
	func read() -> Dictionary:
		var owns := layers > 0 or latch > 0
		return {"menu_open": layers > 0, "menu_owns_input": owns,
			"owner_is_menu": owns and not other_owner,
			"context": "panel:other" if other_owner else ("menu:backpack" if owns else "world")}
	func press() -> Dictionary:
		if refused: return {"ok": false, "why": "guard refused"}
		taps += 1
		if layers == 0: world_taps += 1
		if not stuck:
			layers = maxi(0, layers - 1)
			if layers == 0: latch = 2
		return {"ok": true}
	func settle() -> Dictionary:
		waits += 1
		latch = maxi(0, latch - 1)
		return {"ok": true}
	func interrupted() -> bool: return stopped
	func run() -> Dictionary:
		return await DRIVER.execute(read, press, settle, 3, 12, interrupted)


func test_grid_picker_and_held_stack_close_without_world_cancel() -> void:
	for layers in [1, 2, 3]:
		var f := Fixture.new()
		f.layers = layers
		var result := await f.run()
		assert_true(result.ok, str(result.why))
		assert_eq(f.taps, layers)
		assert_eq(f.world_taps, 0)
		assert_eq(f.waits, layers + 1)


func test_already_world_is_idempotent_and_never_uses_hotbar() -> void:
	var f := Fixture.new()
	f.layers = 0
	var result := await f.run()
	assert_true(result.ok)
	assert_eq(f.taps, 0)
	assert_eq(f.waits, 0)


func test_closed_release_latch_only_waits() -> void:
	var f := Fixture.new()
	f.layers = 0
	f.latch = 3
	var result := await f.run()
	assert_true(result.ok)
	assert_eq(f.taps, 0)
	assert_eq(f.waits, 3)


func test_other_modal_is_not_closed_or_mistaken_for_world() -> void:
	for layers in [0, 1]:
		var f := Fixture.new()
		f.layers = layers
		f.other_owner = true
		var result := await f.run()
		assert_false(result.ok)
		assert_eq(f.taps, 0)


func test_unresponsive_menu_is_bounded() -> void:
	var f := Fixture.new()
	f.stuck = true
	var result := await f.run()
	assert_false(result.ok)
	assert_eq(f.taps, 3)
	assert_eq(f.waits, 3)


func test_stuck_release_latch_exhausts_waits_without_input() -> void:
	var f := Fixture.new()
	f.layers = 0
	f.latch = 100
	var result := await f.run()
	assert_false(result.ok)
	assert_eq(f.waits, 12)
	assert_eq(f.taps, 0)


func test_guard_and_cost_gate_refusals_do_not_inject() -> void:
	for fault: String in ["refused", "stopped"]:
		var f := Fixture.new()
		f.set(fault, true)
		var result := await f.run()
		assert_false(result.ok)
		assert_eq(f.taps, 0)
		assert_eq(f.waits, 0)

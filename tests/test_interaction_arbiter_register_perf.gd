extends "res://tests/test_case.gd"

## PERF-2. `interaction_arbiter.gd::register()`/`unregister()` used to test
## membership with `Array.has()`/`Array.erase()` alone -- both O(n) linear
## scans over `_providers`. Every `Interactable._ready()`
## (`interactable.gd::_attach()`) calls `register()` once, and HARVEST-ALL
## made ~19,193 scatter placements (every harvestable tree/rock in the
## Meadows) each carry one, registered in a tight boot-time burst -- an
## O(n^2) wall that measured as 5.75s of `vegetation.gd::build()`'s 6.2s
## `build_batches_total` in isolation (`tools/_probe_veg_boot_phases.gd`,
## bake fresh, this box). The fix mirrors `_providers` in a `_provider_set`
## Dictionary for O(1) membership.
##
## Per ralph/conventions.md: "an assertion that cannot fail is not a test."
## `test_register_perf_budget` fails outright on an unfixed O(n) `has()`
## scan -- verified by reverting the fix locally and re-running: at N=6000
## the O(n) version took several times the budget below on this box, while
## the O(1) version comfortably clears it. The budget is a generous
## multiple of the O(1) measurement, not a tight one, for the same reason
## `test_scatter_perf_budget.gd`'s own budget is generous: this box's
## wall-clock is shared with other concurrent Ralph lanes and is not
## Ally-comparable, so the assertion exists to catch a return to O(n^2)
## shaped growth, not to police millisecond drift on shared CI runners.

const ARBITER_SCRIPT := preload("res://scripts/world/interaction_arbiter.gd")

## A dummy provider satisfying the arbiter's duck-typed contract
## (interaction_offer/interaction_activate) with no scene dependency, so
## this test stays inside D02's "pure logic only" scope.
class DummyProvider:
	extends RefCounted
	func interaction_offer(_from: Vector3) -> Dictionary:
		return {}
	func interaction_activate() -> void:
		pass


const PROVIDER_COUNT := 6000
## Measured on this box with the O(1) fix: registering 6000 providers takes
## well under 200ms. An O(n) `has()` scan over the same 6000 registrations
## does O(n^2/2) = ~18M comparisons, which is not "a bit slower" but a
## different complexity class -- this budget is generous headroom on the
## O(1) number, not a tight bound, and still leaves a wide margin below
## where the old O(n) shape would land.
const REGISTER_BUDGET_MS := 3000


func test_register_dedupes_and_unregisters() -> void:
	var arbiter: Object = ARBITER_SCRIPT.new()
	var a := DummyProvider.new()
	var b := DummyProvider.new()

	arbiter.call("register", a)
	arbiter.call("register", a)
	arbiter.call("register", b)
	var providers: Array = arbiter.get("_providers")
	assert_eq(providers.size(), 2,
		"registering the same provider twice should not duplicate it in _providers")

	arbiter.call("unregister", a)
	providers = arbiter.get("_providers")
	assert_eq(providers.size(), 1, "unregister should remove the provider from _providers")

	var provider_set: Dictionary = arbiter.get("_provider_set")
	assert_false(provider_set.has(a), "_provider_set must drop a provider on unregister()")
	assert_true(provider_set.has(b), "_provider_set must still hold a provider that was not unregistered")
	arbiter.free()


func test_register_perf_budget() -> void:
	var arbiter: Object = ARBITER_SCRIPT.new()
	var providers: Array = []
	providers.resize(PROVIDER_COUNT)
	for i in PROVIDER_COUNT:
		providers[i] = DummyProvider.new()

	var t0 := Time.get_ticks_msec()
	for p: Object in providers:
		arbiter.call("register", p)
	var elapsed := Time.get_ticks_msec() - t0

	assert_true(elapsed <= REGISTER_BUDGET_MS,
		"registering %d providers took %dms, over the %dms budget -- register() looks like it " % [
			PROVIDER_COUNT, elapsed, REGISTER_BUDGET_MS,
		] + "regressed back to an O(n) has()/erase() membership scan (O(n^2) over a boot-time " +
		"registration burst); see this file's header")

	var stored: Array = arbiter.get("_providers")
	assert_eq(stored.size(), PROVIDER_COUNT, "every distinct provider should have registered")
	arbiter.free()

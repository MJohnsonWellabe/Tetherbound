extends "res://tests/test_case.gd"

## Realm-load profile (2026-10-12): sparse stable-id layers are ordered by
## slotting each placement at its unique order instead of a lambda sort. The
## result must equal the ascending sort; duplicates must defer to the sort.

const BAKE := preload("res://scripts/world/scatter_bake.gd")


func _entries(orders: Array) -> Array:
	var out: Array = []
	for order: int in orders:
		out.append({"order": order, "placement": {"id": order}})
	return out


func _sorted_ids(entries: Array) -> Array:
	var copy := entries.duplicate()
	copy.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["order"]) < int(b["order"]))
	return copy.map(func(e: Dictionary) -> int: return int(e["placement"]["id"]))


func test_unique_sparse_orders_slot_into_ascending_order() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var used := {}
	var orders: Array = []
	while orders.size() < 500:
		var order := rng.randi_range(-200, 2500)
		if not used.has(order):
			used[order] = true
			orders.append(order)
	var entries := _entries(orders)
	var slotted: Array = BAKE._slot_by_order(entries).map(func(p: Dictionary) -> int: return int(p["id"]))
	assert_eq(slotted, _sorted_ids(entries))
	var reordered: Array = BAKE._reorder(_entries(orders), true, 3000).map(func(p: Dictionary) -> int: return int(p["id"]))
	assert_eq(reordered, _sorted_ids(entries), "_reorder's sparse path gives the sorted order")


func test_duplicates_or_a_huge_span_defer_to_the_sort() -> void:
	assert_true(BAKE._slot_by_order(_entries([5, 9, 5])).is_empty(), "a duplicate order is not slotted")
	assert_true(BAKE._slot_by_order(_entries([0, 1000000])).is_empty(), "an enormous span is not slotted")
	var reordered: Array = BAKE._reorder(_entries([5, 9, 5, 1]), true, 10).map(func(p: Dictionary) -> int: return int(p["id"]))
	assert_eq(reordered.size(), 4)
	assert_eq(reordered[0], 1)
	assert_eq(reordered[3], 9)

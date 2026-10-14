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


func _column(entries: Array) -> BAKE.PlacementColumn:
	var column := BAKE.PlacementColumn.new()
	for row: Dictionary in entries:
		column.orders.append(int(row.order))
		column.placements.append(row.placement)
	return column


func _records(orders: Array) -> Array:
	var rows: Array = []
	for index in orders.size():
		var placement := {"model": "test://model_%d.gltf" % (index % 2),
			"position": Vector3(index * 0.25, -2.0, 12.5), "yaw": index * 0.125,
			"scale": 0.75 + index * 0.25}
		if index % 2 == 0:
			placement["normal"] = Vector3(0.0, 1.0, 0.0)
		rows.append({"order": int(orders[index]), "placement": placement})
	return rows


func test_compact_reorder_matches_legacy_records_and_identity_fields() -> void:
	# Distinct payloads for equal orders detect dropped/reassigned duplicates,
	# not just the same multiset of order numbers. Full uint32 values must not
	# wrap through a signed PackedInt32Array.
	for orders: Array in [[], [2, 0, 1], [9, 2, 5], [-5, 0, -2],
			[5, 9, 5, 1], [0, 1000000], [4294967295, 0, 2147483648]]:
		var records := _records(orders)
		var expected: Array = BAKE._reorder(records.duplicate(true), true, 4294967296)
		var column := _column(records.duplicate(true))
		var actual: Array = BAKE._reorder_column(column, true, 4294967296)
		assert_eq(actual, expected, "all payload fields and duplicate fallback match for %s" % str(orders))
		assert_eq(column.orders, PackedInt64Array(orders), "reordering does not detach orders from input records")
		for placement: Dictionary in actual:
			assert_eq(int(placement.harvest_identity_bound), 4294967296)
	# Legacy kept/drained rows must not gain stable identity fields.
	var old := _column(_records([1, 0]))
	var reordered: Array = BAKE._reorder_column(old)
	assert_eq(reordered[0].position.x, 0.25)
	assert_false(reordered[0].has("harvest_identity"))
	assert_false(reordered[0].has("harvest_identity_bound"))
	# The existing dictionary itself reaches consumers, not a narrowed copy.
	reordered[0]["consumer_annotation"] = "retained"
	assert_eq(old.placements[1].get("consumer_annotation"), "retained")


func test_compact_reorder_matches_legacy_over_deterministic_shuffles_and_duplicates() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 38013
	for trial in 128:
		var orders: Array = []
		var count := rng.randi_range(0, 96)
		for index in count:
			# Narrow spans force duplicates; wider spans exercise sparse slots
			# and sort fallback. Dense permutations are covered above.
			orders.append(rng.randi_range(-100, 100) if trial % 2 == 0 else rng.randi_range(0, 1000000))
		var records := _records(orders)
		var expected: Array = BAKE._reorder(records.duplicate(true), true, 1000001)
		var actual: Array = BAKE._reorder_column(_column(records.duplicate(true)), true, 1000001)
		assert_eq(actual, expected, "compact/legacy parity at trial %d" % trial)


func test_compact_region_reader_appends_regions_and_keeps_skip_drain_and_uint32_contracts() -> void:
	var path := "user://scatter-columns-%d.bin" % Time.get_ticks_usec()
	var compact := {}
	var compact_drained := {}
	var legacy := {}
	var legacy_drained := {}
	var compact_skipped := {}
	var legacy_skipped := {}
	var regions := [
		{"trees": {"kept": _records([4294967295, 2]), "drained": _records([1])},
			"grass": {"kept": _records([0, 1]), "drained": _records([0])},
			"empty": {"kept": [], "drained": []}},
		{"trees": {"kept": _records([0, 2147483648]), "drained": _records([0])},
			"rocks": {"kept": _records([0]), "drained": []},
			"grass": {"kept": _records([2]), "drained": []}},
	]
	for region: Dictionary in regions:
		assert_true(BAKE._write_region(path, region) > 0)
		var file := FileAccess.open(path, FileAccess.READ)
		BAKE._read_region(file, compact, compact_drained, {"grass": true}, compact_skipped, true)
		assert_eq(file.get_position(), file.get_length(), "optional normals/skips leave the file aligned")
		file.close()
		file = FileAccess.open(path, FileAccess.READ)
		BAKE._read_region(file, legacy, legacy_drained, {"grass": true}, legacy_skipped)
		assert_eq(file.get_position(), file.get_length())
		file.close()
	DirAccess.remove_absolute(path)
	assert_eq(compact.keys(), legacy.keys())
	assert_eq(compact_skipped, {"grass": 3}, "only skipped kept records are counted")
	assert_eq(compact_skipped, legacy_skipped)
	assert_eq(compact_drained.keys(), legacy_drained.keys())
	assert_eq(compact.trees.orders, PackedInt64Array([4294967295, 2, 0, 2147483648]))
	assert_eq(compact.trees.placements.size(), 4, "second region appends to the same column")
	assert_false(compact.has("grass"))
	assert_false(compact_drained.has("grass"))
	for layer: String in compact:
		assert_true(compact[layer] is BAKE.PlacementColumn)
		assert_eq(BAKE._reorder_column(compact[layer], true, 4294967296),
			BAKE._reorder(legacy[layer], true, 4294967296), "kept column parity for " + layer)
	for layer: String in compact_drained:
		var actual: Array = BAKE._reorder_column(compact_drained[layer])
		assert_eq(actual, BAKE._reorder(legacy_drained[layer]), "drained keeps legacy identity behavior")
		assert_false(actual[0].has("harvest_identity"))
	# A completely retired stable-ID layer remains in load_all's bounds map,
	# even with no surviving records in any column.
	assert_eq(BAKE.stable_identity_bounds({"stable_harvest_ids": true,
		"identity_high_water": {"retired": 19, "grass": 88}}, {"grass": true}), {"retired": 20})

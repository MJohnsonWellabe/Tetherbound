extends "res://tests/test_case.gd"

## HARVEST-ALL / D60. "Once it's chopped it should disappear and not
## regrow" — the persistence half. These exercise `vegetation.gd`'s bitset
## helpers and `harvest_permanently()`/`restore_from_game()`/
## `sync_state_to_game()` directly, at the data level, the same way
## `test_harvest.gd` exercises `_mark_harvestable()` without paying for a
## full mesh-loading `build()` (no live Terrain3D node is constructed here —
## `harvest_permanently()`'s render-removal call is guarded by `_instancer ==
## null` and is a no-op without one, which is exactly what lets this stay
## fast and still prove the bookkeeping half is correct).

const VEGETATION := preload("res://scripts/world/vegetation.gd")
const FELLED_RESOURCE := preload("res://scripts/world/felled_resource.gd")


func _veg() -> Node3D:
	return VEGETATION.new()


# --- bitset helpers ----------------------------------------------------


func test_bitset_bytes_rounds_up_to_the_nearest_byte() -> void:
	var veg := _veg()
	assert_eq(int(veg.call("_bitset_bytes", 0)), 0)
	assert_eq(int(veg.call("_bitset_bytes", 1)), 1)
	assert_eq(int(veg.call("_bitset_bytes", 8)), 1)
	assert_eq(int(veg.call("_bitset_bytes", 9)), 2)
	assert_eq(int(veg.call("_bitset_bytes", 2848)), 356)
	veg.free()


func test_new_bitset_starts_all_clear() -> void:
	var veg := _veg()
	var bytes: PackedByteArray = veg.call("_new_bitset", 20)
	assert_eq(bytes.size(), 3)
	for i in 20:
		assert_false(bool(veg.call("_bit_get", bytes, i)), "bit %d should start clear" % i)
	veg.free()


func test_bit_set_and_get_round_trip_every_bit_independently() -> void:
	var veg := _veg()
	var bytes: PackedByteArray = veg.call("_new_bitset", 17)
	veg.call("_bit_set", bytes, 0)
	veg.call("_bit_set", bytes, 8)
	veg.call("_bit_set", bytes, 16)
	for i in 17:
		var expected := i == 0 or i == 8 or i == 16
		assert_eq(bool(veg.call("_bit_get", bytes, i)), expected,
			"bit %d should be %s" % [i, expected])
	veg.free()


func test_bit_get_out_of_range_is_false_not_a_crash() -> void:
	var veg := _veg()
	var bytes: PackedByteArray = veg.call("_new_bitset", 4)
	assert_false(bool(veg.call("_bit_get", bytes, 999)))
	assert_false(bool(veg.call("_bit_get", bytes, -1)))
	veg.free()


# --- _mark_harvestable: every placement is now harvestable, and identifiable ---


## PERF, 2026-08-25: same fix as tests/test_harvest.gd's own header explains
## in full -- RULES.all_placements() walks all ten vegetation layers against
## the real corridor (~200s, measured with tools/_probe_placements_timing.gd)
## and the two tests below only ever read "trees" and "rocks" back out.
## _layer_placements() calls RULES.placements_for() directly for one named
## layer, using the same per-layer seed all_placements() itself derives, so
## it reproduces exactly what a full call would have produced for that layer.
func _layer_placements(name: String) -> Array[Dictionary]:
	const RULES := preload("res://scripts/world/scatter_rules.gd")
	const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
	var layers: Dictionary = RULES.config().get("layers", {})
	var offset := 0
	var layer: Dictionary = {}
	for key: String in layers.keys():
		if key == name:
			layer = layers[key]
			break
		offset += 1
	if layer.is_empty():
		return []
	var seed_value := int(RULES.config().get("seed", 1)) + offset * 7919 + int(layer.get("seed_offset", 0))
	var field: RefCounted = HEIGHTFIELD.new()
	var world_size: float = float(HEIGHTFIELD.load_config().get("world_size", 512))
	return RULES.placements_for(layer, field, world_size, seed_value)


func test_marking_stamps_a_stable_layer_and_index_on_every_harvestable_placement() -> void:
	var veg := _veg()
	var by_layer := {"trees": _layer_placements("trees")}
	veg.call("_mark_harvestable", by_layer)

	var trees: Array = by_layer.get("trees", [])
	assert_true(trees.size() > 0, "fixture has no trees to check")
	var seen_indices := {}
	for p: Dictionary in trees:
		assert_true(p.has("harvest_item"), "harvest_fraction is 1.0 -- every tree must be marked")
		assert_eq(str(p.get("harvest_layer", "")), "trees")
		var idx := int(p.get("harvest_index", -1))
		assert_true(idx >= 0 and idx < trees.size())
		assert_false(seen_indices.has(idx), "harvest_index %d used twice" % idx)
		seen_indices[idx] = true
	veg.free()


func test_marking_gives_every_tree_and_rock_a_harvest_point_at_full_density() -> void:
	# D60: harvest_fraction went to 1.0 for both layers -- this is the
	# directive's first, cheapest half, demonstrated failing against the OLD
	# config would have shown ~1-in-12/1-in-14; against today's config every
	# single placement in each layer must be marked.
	var veg := _veg()
	var by_layer := {"trees": _layer_placements("trees"), "rocks": _layer_placements("rocks")}
	veg.call("_mark_harvestable", by_layer)
	for layer_name in ["trees", "rocks"]:
		var placements: Array = by_layer.get(layer_name, [])
		assert_true(placements.size() > 0, "fixture has no %s to check" % layer_name)
		for p: Dictionary in placements:
			assert_true((p as Dictionary).has("harvest_item"),
				"'%s' layer is harvest_fraction 1.0 -- every placement must be marked" % layer_name)
	veg.free()


# --- harvest_permanently / restore_from_game: the bookkeeping, without a live terrain ---


class FakeHarvestGame:
	extends RefCounted
	var harvested_vegetation: Dictionary = {}
	var felled_vegetation: Dictionary = {}


## Manually wires the private state `harvest_permanently()`/`restore_from_game()`
## read and write, the same way `_mark_harvestable` is called directly above --
## skips `build()` entirely (no Terrain3D node), so `_remove_render_instance()`'s
## `_instancer == null` guard makes the render-removal call a safe no-op and
## this stays fast while still proving the bitset/lookup bookkeeping is right.
func _rigged_veg(layer_name: String, count: int) -> Node3D:
	var veg := _veg()
	veg.set("_harvested", {layer_name: veg.call("_new_bitset", count)})
	veg.set("_harvest_layer_counts", {layer_name: count})
	var lookup := {}
	var nodes := {}
	for i in count:
		var key := "%s#%d" % [layer_name, i]
		lookup[key] = {"mesh_id": -1, "position": Vector3.ZERO}
		var n := Node.new()
		nodes[key] = n
		veg.add_child(n)
	veg.set("_harvest_lookup", lookup)
	veg.set("_harvest_nodes", nodes)
	return veg


func after_each() -> void:
	pass


func test_harvest_permanently_sets_the_bit_and_forgets_the_lookup_entry() -> void:
	var veg := _rigged_veg("trees", 5)
	veg.call("harvest_permanently", "trees", 2)

	var bytes: PackedByteArray = (veg.get("_harvested") as Dictionary)["trees"]
	assert_true(bool(veg.call("_bit_get", bytes, 2)), "index 2 should be marked chopped")
	assert_false(bool(veg.call("_bit_get", bytes, 1)), "index 1 must be untouched")
	assert_false(bool(veg.call("_bit_get", bytes, 3)), "index 3 must be untouched")

	var lookup: Dictionary = veg.get("_harvest_lookup")
	assert_false(lookup.has("trees#2"), "a chopped placement's lookup entry must be forgotten")
	assert_true(lookup.has("trees#1"), "an untouched placement's lookup entry must survive")

	var nodes: Dictionary = veg.get("_harvest_nodes")
	assert_false(nodes.has("trees#2"), "a chopped placement's node entry must be forgotten")
	veg.free()


func test_harvest_permanently_twice_on_the_same_index_is_a_no_op_the_second_time() -> void:
	var veg := _rigged_veg("rocks", 3)
	veg.call("harvest_permanently", "rocks", 0)
	var lookup_after_first: Dictionary = (veg.get("_harvest_lookup") as Dictionary).duplicate()
	# A second call must not error, and must not touch anything further --
	# the entry is already gone, so a naive re-implementation that skipped
	# the "already set" guard would try to double-free the (already freed)
	# node here.
	veg.call("harvest_permanently", "rocks", 0)
	assert_eq(veg.get("_harvest_lookup"), lookup_after_first)
	veg.free()


func test_harvest_permanently_on_an_unknown_index_does_nothing() -> void:
	var veg := _rigged_veg("trees", 2)
	var before: Dictionary = (veg.get("_harvest_lookup") as Dictionary).duplicate()
	veg.call("harvest_permanently", "trees", 999)
	assert_eq(veg.get("_harvest_lookup"), before)
	veg.free()


func test_sync_state_to_game_writes_a_base64_bitset_per_layer() -> void:
	var veg := _rigged_veg("trees", 4)
	veg.call("harvest_permanently", "trees", 1)
	veg.call("harvest_permanently", "trees", 3)

	var game := FakeHarvestGame.new()
	veg.call("sync_state_to_game", game)
	assert_true(game.harvested_vegetation.has("trees"))
	var raw := Marshalls.base64_to_raw(str(game.harvested_vegetation["trees"]))
	assert_eq(raw.size(), 1)
	assert_eq(int(raw[0]), 0b00001010, "bits 1 and 3 set, nothing else")
	veg.free()


func test_restore_from_game_applies_saved_chops_on_top_of_a_fresh_build() -> void:
	var veg := _rigged_veg("trees", 4)
	var game := FakeHarvestGame.new()
	game.harvested_vegetation = {"trees": Marshalls.raw_to_base64(PackedByteArray([0b00000101]))}

	veg.call("restore_from_game", game)

	var bytes: PackedByteArray = (veg.get("_harvested") as Dictionary)["trees"]
	assert_true(bool(veg.call("_bit_get", bytes, 0)))
	assert_false(bool(veg.call("_bit_get", bytes, 1)))
	assert_true(bool(veg.call("_bit_get", bytes, 2)))
	var lookup: Dictionary = veg.get("_harvest_lookup")
	assert_false(lookup.has("trees#0"))
	assert_false(lookup.has("trees#2"))
	assert_true(lookup.has("trees#1"), "index 1 was never chopped in the save; must survive")
	veg.free()


## D60's own explicit rule: chopped stays chopped even across loading an
## OLDER save. A bit already set locally, but absent from the loaded save,
## must NOT be cleared -- restore_from_game only ever adds removals, never
## un-chops.
func test_restore_from_game_never_un_chops_something_already_removed_this_session() -> void:
	var veg := _rigged_veg("trees", 4)
	veg.call("harvest_permanently", "trees", 2)
	assert_false((veg.get("_harvest_lookup") as Dictionary).has("trees#2"))

	var game := FakeHarvestGame.new()
	game.harvested_vegetation = {"trees": Marshalls.raw_to_base64(PackedByteArray([0b00000000]))}
	veg.call("restore_from_game", game)

	var bytes: PackedByteArray = (veg.get("_harvested") as Dictionary)["trees"]
	assert_true(bool(veg.call("_bit_get", bytes, 2)), "already-chopped-this-session must stay chopped")
	assert_false((veg.get("_harvest_lookup") as Dictionary).has("trees#2"), "must not resurrect the lookup entry")
	veg.free()


func test_restore_from_game_ignores_a_layer_whose_bitset_size_no_longer_matches() -> void:
	# A config edit changed this layer's placement count under the save --
	# the saved bitset no longer lines up index-for-index, so it must be
	# discarded rather than misapplied to the wrong instances.
	var veg := _rigged_veg("trees", 4)
	var game := FakeHarvestGame.new()
	game.harvested_vegetation = {"trees": Marshalls.raw_to_base64(PackedByteArray([0b1, 0b1, 0b1]))}
	veg.call("restore_from_game", game)
	var bytes: PackedByteArray = (veg.get("_harvested") as Dictionary)["trees"]
	for i in 4:
		assert_false(bool(veg.call("_bit_get", bytes, i)), "a mismatched-size save must be discarded, not applied")
	veg.free()


func test_harvested_count_reports_only_what_is_actually_chopped() -> void:
	var veg := _rigged_veg("rocks", 6)
	assert_eq(int(veg.call("harvested_count")), 0)
	veg.call("harvest_permanently", "rocks", 0)
	veg.call("harvest_permanently", "rocks", 5)
	assert_eq(int(veg.call("harvested_count")), 2)
	veg.free()


# --- RG9: fell() / _felled / clear_felled -- the chop-then-gather split ---
#
# "You shouldn't be able to gather a standing tree. You should have to chop
# it. Then it becomes downed wood. Then you gather that." `fell()` wraps
# `harvest_permanently()` (unchanged, tested above) and additionally stands a
# `felled_resource.gd` pickup, tracked in `_felled` so a save can remember
# "chopped but not yet gathered" and restand the pile on load. `_rigged_veg`
# above wires bare `{"mesh_id": -1, "position": Vector3.ZERO}` lookup entries
# with no item -- these tests need `item`/`prop_offset` too, so they extend
# the rig directly rather than widening `_rigged_veg` for every OTHER test
# in this file that does not need it.


func _rig_lookup_for_fell(veg: Node3D, key: String, item: String, at: Vector3) -> void:
	var lookup: Dictionary = veg.get("_harvest_lookup")
	var entry: Dictionary = lookup.get(key, {}).duplicate()
	entry["item"] = item
	entry["position"] = at
	entry["prop_offset"] = Vector3.ZERO
	lookup[key] = entry
	veg.set("_harvest_lookup", lookup)


## `_rigged_veg` also parents one plain `Node.new()` per placement as its own
## `_harvest_nodes` stand-in, and `harvest_permanently()`'s `queue_free()` on
## a chopped one does not remove it from `get_children()` SYNCHRONOUSLY (no
## scene tree is stepping frames in this file) -- so a raw child count right
## after `fell()` is not the standing-vs-felled placeholders. Filtering by
## script is what actually finds "the felled pickup fell() stood", the same
## script-identity check `tests/smoke_playground.gd` uses live.
func _felled_children(veg: Node3D) -> Array[Node]:
	var out: Array[Node] = []
	for child in veg.get_children():
		if (child.get_script() as Script) == FELLED_RESOURCE:
			out.append(child)
	return out


func test_fell_removes_the_standing_placement_and_stands_a_felled_pickup() -> void:
	var veg := _rigged_veg("trees", 3)
	_rig_lookup_for_fell(veg, "trees#1", "wood", Vector3(5.0, 0.0, 5.0))
	veg.call("fell", "trees", 1, 3)

	assert_true(bool(veg.call("_bit_get", (veg.get("_harvested") as Dictionary)["trees"], 1)),
		"fell() must chop the standing placement the same way harvest_permanently() does")
	var felled := _felled_children(veg)
	assert_eq(felled.size(), 1, "fell() should stand exactly one felled_resource.gd child")
	if felled.size() == 1:
		assert_eq(str(felled[0].get("_item_id")), "wood")
		assert_eq(int(felled[0].get("_amount")), 3)
	veg.free()


func test_fell_pays_out_the_caller_supplied_amount_not_the_layer_default() -> void:
	# The whole point of taking `actual_amount` as a parameter: a bare-handed
	# chop (a reduced yield) must stand a SMALLER pile, not the layer's own
	# full configured amount re-derived from scratch.
	var veg := _rigged_veg("trees", 1)
	_rig_lookup_for_fell(veg, "trees#0", "wood", Vector3.ZERO)
	veg.call("fell", "trees", 0, 1)
	var felled := _felled_children(veg)
	assert_eq(felled.size(), 1)
	if felled.size() == 1:
		assert_eq(int(felled[0].get("_amount")), 1, "the felled pile must carry the chop's own reduced amount")
	veg.free()


func test_fell_tracks_the_placement_in_felled_for_persistence() -> void:
	var veg := _rigged_veg("rocks", 2)
	_rig_lookup_for_fell(veg, "rocks#0", "stone", Vector3(1.0, 2.0, 3.0))
	veg.call("fell", "rocks", 0, 2)
	var felled: Dictionary = veg.get("_felled")
	assert_true(felled.has("rocks#0"), "a chopped-but-not-yet-gathered placement must be tracked")
	var record: Dictionary = felled["rocks#0"]
	assert_eq(str(record.get("item")), "stone")
	assert_eq(int(record.get("amount")), 2)
	assert_eq(record.get("position"), [1.0, 2.0, 3.0])
	veg.free()


func test_fell_on_an_unknown_key_still_chops_but_stands_nothing() -> void:
	# `_harvest_lookup` for this key predates RG9 (no item/amount wired) or is
	# simply missing -- `harvest_permanently()`'s own half must still run
	# (the standing placement disappearing is never optional), but there is
	# nothing to stand a pile FOR.
	var veg := _rigged_veg("trees", 1)
	veg.call("fell", "trees", 0, 5)
	assert_true(bool(veg.call("_bit_get", (veg.get("_harvested") as Dictionary)["trees"], 0)))
	assert_eq(_felled_children(veg).size(), 0, "an unknown key must stand no felled pickup")
	assert_false((veg.get("_felled") as Dictionary).has("trees#0"))
	veg.free()


func test_clear_felled_forgets_the_tracking_entry() -> void:
	var veg := _rigged_veg("trees", 1)
	_rig_lookup_for_fell(veg, "trees#0", "wood", Vector3.ZERO)
	veg.call("fell", "trees", 0, 3)
	assert_true((veg.get("_felled") as Dictionary).has("trees#0"))
	veg.call("clear_felled", "trees#0")
	assert_false((veg.get("_felled") as Dictionary).has("trees#0"),
		"clear_felled must remove the tracking entry once the pile is actually gathered")
	veg.free()


func test_sync_state_to_game_writes_felled_vegetation_alongside_harvested() -> void:
	var veg := _rigged_veg("trees", 1)
	_rig_lookup_for_fell(veg, "trees#0", "wood", Vector3(4.0, 0.0, 0.0))
	veg.call("fell", "trees", 0, 3)
	var game := FakeHarvestGame.new()
	veg.call("sync_state_to_game", game)
	assert_true(game.felled_vegetation.has("trees#0"))
	assert_eq(str((game.felled_vegetation["trees#0"] as Dictionary).get("item")), "wood")
	veg.free()


## The save round trip a player would actually hit: chop a tree, never pick
## up the log, save, reload. Without `felled_vegetation`, the standing tree
## would come back gone (the bitset alone already proves that much, tested
## above) but the wood it owed would simply vanish -- nothing stands the pile
## back up. This is the test that proves it does.
func test_restore_from_game_restands_a_felled_pickup_the_save_still_owes() -> void:
	var chopper := _rigged_veg("trees", 1)
	_rig_lookup_for_fell(chopper, "trees#0", "wood", Vector3(7.0, 0.0, 2.0))
	chopper.call("fell", "trees", 0, 3)
	var game := FakeHarvestGame.new()
	chopper.call("sync_state_to_game", game)
	chopper.free()

	# A FRESH `vegetation.gd`, the way a real boot builds one before
	# `restore_from_game()` ever runs -- nothing chopped yet, no felled
	# pickup standing, `_harvest_lookup` populated exactly like a real
	# `_mark_harvestable()` pass would leave it (this placement never having
	# been touched this session).
	var fresh := _rigged_veg("trees", 1)
	fresh.call("restore_from_game", game)

	var bytes: PackedByteArray = (fresh.get("_harvested") as Dictionary)["trees"]
	assert_true(bool(fresh.call("_bit_get", bytes, 0)), "the loaded save's chop must be replayed")
	var felled := _felled_children(fresh)
	assert_eq(felled.size(), 1, "the loaded save's un-gathered pile must be restood")
	if felled.size() == 1:
		assert_eq(str(felled[0].get("_item_id")), "wood")
		assert_eq(int(felled[0].get("_amount")), 3)
		# `.position` (local), not `global_position`: `fresh` here is never
		# added to a live SceneTree (the same "no live Terrain3D node" shape
		# every other test in this file uses), and `fresh` itself never moves
		# from the origin, so local and global coincide for a correctly
		# behaving engine -- but `global_position`'s transform cache is only
		# reliably fresh for a node chain that has actually entered the tree,
		# and asserting against it here was measured flaky for exactly that
		# reason. `_spawn_felled()` sets `.position` directly; that is the
		# value actually under test.
		assert_almost_eq((felled[0] as Node3D).position.x, 7.0, 0.001)
	fresh.free()


## The other half of the same round trip: chop AND gather (the pile is
## already picked up) must NOT come back on load -- `felled_vegetation` no
## longer carries that key once `clear_felled()` ran, so `restore_from_game`
## has nothing telling it to restand anything, only `harvest_permanently()`'s
## ordinary "stays chopped" bit.
func test_restore_from_game_does_not_restand_an_already_gathered_chop() -> void:
	var chopper := _rigged_veg("trees", 1)
	_rig_lookup_for_fell(chopper, "trees#0", "wood", Vector3.ZERO)
	chopper.call("fell", "trees", 0, 3)
	chopper.call("clear_felled", "trees#0")
	var game := FakeHarvestGame.new()
	chopper.call("sync_state_to_game", game)
	chopper.free()

	assert_false(game.felled_vegetation.has("trees#0"))
	var fresh := _rigged_veg("trees", 1)
	fresh.call("restore_from_game", game)
	assert_eq(_felled_children(fresh).size(), 0, "an already-gathered chop must not restand a pickup")
	fresh.free()

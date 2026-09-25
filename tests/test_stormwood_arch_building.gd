extends "res://tests/test_case.gd"

## The runtime preview checks the same placement rule, but these tests prove the
## host ledger is the authority once two peers' intents are serialised.
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const BUILT := preload("res://scripts/world/stormwood_arch_build_rules.gd")

const PEER_A := 1
const PEER_B := 771240190

const VERGE := Vector3(-630.0, 0.0, 800.0)
const HOLLOWS := Vector3(-1050.0, 0.0, 1750.0)
const CAPACITOR := Vector3(-1040.0, 0.0, 3070.0)
const STILL_GROVE := Vector3(-160.0, 0.0, 2750.0)
const DEEPWOOD := Vector3(-400.0, 0.0, 4540.0)

const OFF_FOOTING := "A Stormglass arch stands only on a Rodfolk footing."
const OCCUPIED := "Another arch already occupies this footing."
const ROADS_FULL := "Three player roads are already standing. Dismantle an arch first."

## Off every footing, inside the forest and outside the island box: where a
## save made before footings were required could have raised its arches.
const LEGACY_PAIRS := [
	[Vector3(-800.0, 0.0, 1000.0), Vector3(-820.0, 0.0, 1200.0)],
	[Vector3(-300.0, 0.0, 600.0), Vector3(-320.0, 0.0, 900.0)],
	[Vector3(-900.0, 0.0, 2400.0), Vector3(-920.0, 0.0, 2600.0)],
]

var world: RefCounted
var ledger: RefCounted


func before_each() -> void:
	world = WORLD_STATE.new()
	ledger = WORLD_LEDGER.new(world)
	world.flags.set_flag("stormwood:arch_recipe_known")


func _place(at: Vector3, peer: int = PEER_A) -> Dictionary:
	return ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": at,
		"available_materials": {"stormglass": 100, "stormglass_crown": 100,
			"thunderwood_frame": 100, "conductor_vine": 100}}, peer)


func _record(uid: String) -> Dictionary:
	var index := int(world.building_index_of(uid))
	return world.placed_buildings[index] if index >= 0 else {}


func _assert_refused(verdict: Dictionary, reason: String, note: String) -> void:
	assert_false(bool(verdict.get("ok")), note)
	# The ledger refuses an occupied footing before placement() runs, with its
	# own code; every other placement refusal keeps arch_locked.
	var code := "arch_occupied" if reason == OCCUPIED else "arch_locked"
	assert_eq(str(verdict.get("code", "")), code, note)
	assert_eq(str(verdict.get("reason", "")), reason, note)


## An old save: arches committed by the ledger before a footing was required.
## The ops are exactly the ones `_place_building()` emitted for them -- the
## placer's `building_add`, its own link carrying the empty footing an
## off-footing plan returned, then the survivor's reciprocal link -- applied to
## a scratch world whose save file is then loaded into `world`. `solo` adds an
## unpaired legacy arch after the pairs.
func _load_legacy_save(pairs: Array, solo: Array = []) -> Array[String]:
	var scratch: RefCounted = WORLD_STATE.new()
	scratch.flags.set_flag("stormwood:arch_recipe_known")
	var uids: Array[String] = []
	var ends: Array = []
	for pair: Array in pairs:
		ends.append_array([[pair[0], ""], [pair[1], "pair"]])
	for at: Vector3 in solo:
		ends.append([at, ""])
	var waiting := ""
	for end: Array in ends:
		var at: Vector3 = end[0]
		var uid := "b%d" % int(scratch.next_building_uid)
		var twin := waiting if str(end[1]) == "pair" else ""
		var ops: Array = [
			{"op": "building_add", "scope": "world", "realm": "stormwood", "uid": uid,
				"id": "stormglass_arch", "position": [at.x, at.y, at.z], "yaw_deg": 0.0, "paid": true},
			{"op": "building_arch_link", "scope": "world", "realm": "stormwood",
				"uid": uid, "twin": twin, "footing": ""},
		]
		if not twin.is_empty():
			ops.append({"op": "building_arch_link", "scope": "world", "realm": "stormwood",
				"uid": twin, "twin": uid})
		assert_eq(int(scratch.apply_delta({"ops": ops})), ops.size(), "legacy fixture op applies")
		waiting = uid if twin.is_empty() else ""
		uids.append(uid)
	world.load_data(scratch.save_data())
	return uids


func test_first_and_second_arches_commit_one_stable_mutual_pair() -> void:
	var first := _place(VERGE)
	var first_uid := str(first.get("uid", ""))
	assert_true(bool(first.get("ok")))
	assert_false(first_uid.is_empty())
	assert_eq(str(_record(first_uid).get("arch_twin", "")), "",
		"the first endpoint waits for a second arch")

	var second := _place(HOLLOWS)
	var second_uid := str(second.get("uid", ""))
	assert_true(bool(second.get("ok")))
	assert_eq(str(_record(first_uid).get("arch_twin", "")), second_uid)
	assert_eq(str(_record(second_uid).get("arch_twin", "")), first_uid)
	assert_eq(str(_record(first_uid).get("uid", "")), first_uid,
		"linking never renumbers the first placed record")


func test_unrelated_removal_never_relinks_a_completed_arch_pair() -> void:
	var first := _place(VERGE)
	var second := _place(HOLLOWS)
	var first_uid := str(first.get("uid", ""))
	var second_uid := str(second.get("uid", ""))
	var fence: Dictionary = ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "fence", "position": Vector3(100.0, 0.0, 900.0)}, PEER_A)
	assert_true(bool(fence.get("ok")))
	assert_true(bool(ledger.commit({"kind": "dismantle", "realm": "stormwood",
		"uid": str(fence.get("uid", ""))}, PEER_B).get("ok")))
	assert_eq(str(_record(first_uid).get("arch_twin", "")), second_uid)
	assert_eq(str(_record(second_uid).get("arch_twin", "")), first_uid)


func test_dismantling_one_arch_clears_its_survivor_and_replacement_uses_it() -> void:
	var first := _place(VERGE)
	var second := _place(HOLLOWS)
	var first_uid := str(first.get("uid", ""))
	var survivor_uid := str(second.get("uid", ""))
	assert_true(bool(ledger.commit({"kind": "dismantle", "realm": "stormwood",
		"uid": first_uid}, PEER_B).get("ok")))
	assert_eq(str(_record(survivor_uid).get("arch_twin", "")), "",
		"the surviving endpoint cannot retain a dead identity")

	var replacement := _place(CAPACITOR)
	var replacement_uid := str(replacement.get("uid", ""))
	assert_true(bool(replacement.get("ok")))
	assert_eq(str(_record(survivor_uid).get("arch_twin", "")), replacement_uid)
	assert_eq(str(_record(replacement_uid).get("arch_twin", "")), survivor_uid)


func test_three_road_limit_includes_the_player_built_crown_pair() -> void:
	var crown := _place(STILL_GROVE)
	assert_true(bool(crown.get("ok")))
	assert_eq(str(_record(str(crown.get("uid", ""))).get("arch_twin", "")), "e_crown")

	# The four optional footings (Deepwood after the Rootgate) carry exactly
	# the two ordinary pairs the three-road cap leaves beside the Crown road.
	world.flags.set_flag("stormwood:rootgate_released")
	for at: Vector3 in [VERGE, HOLLOWS, CAPACITOR, DEEPWOOD]:
		assert_true(bool(_place(at).get("ok")), "two ordinary roads may stand beside the Crown road")
	for at: Vector3 in [VERGE, Vector3(-700.0, 0.0, 1600.0)]:
		var blocked := _place(at)
		assert_false(bool(blocked.get("ok")), "no fourth road once every footing carries an arch")
		# A carried footing is refused by the ledger's occupancy check; open
		# ground by placement().
		assert_eq(str(blocked.get("code", "")), "arch_occupied" if at == VERGE else "arch_locked")
	# Each refusal says why: the carried footing is occupied, the open ground
	# is no footing. Neither is the cap -- see the legacy-save cap tests.
	_assert_refused(_place(VERGE), OCCUPIED, "a carried footing refuses a second arch")
	_assert_refused(_place(Vector3(-700.0, 0.0, 1600.0)), OFF_FOOTING, "open ground is no footing")


func test_three_road_cap_refuses_a_free_legal_footing_in_an_old_save() -> void:
	# Three ordinary legacy roads fill the cap. VERGE is free and legal, so
	# only the cap can refuse it.
	var legacy := _load_legacy_save(LEGACY_PAIRS)
	assert_eq(BUILT.records(world.placed_buildings).size(), 6, "the old save loads all six arches")
	_assert_refused(_place(VERGE), ROADS_FULL, "a fourth ordinary road is refused by the cap")
	_assert_refused(_place(STILL_GROVE), ROADS_FULL, "the Crown road counts against the same cap")
	assert_eq(world.placed_buildings.size(), 6, "a capped placement commits nothing")
	# Dismantling one legacy arch frees a road; the free footing then accepts.
	assert_true(bool(ledger.commit({"kind": "dismantle", "realm": "stormwood",
		"uid": legacy[0]}, PEER_A).get("ok")))
	assert_true(bool(_place(VERGE).get("ok")), "below the cap the same footing accepts")


func test_crown_road_and_two_legacy_roads_fill_the_cap() -> void:
	_load_legacy_save(LEGACY_PAIRS.slice(0, 2))
	var crown := _place(STILL_GROVE)
	assert_true(bool(crown.get("ok")), "the Crown road is the third road")
	_assert_refused(_place(VERGE), ROADS_FULL, "no ordinary road beside the Crown and two others")


func test_an_arch_stands_only_on_a_legal_footing() -> void:
	# WORLD §5.3: free-build waives material cost only, never the legal footing.
	for at: Vector3 in [Vector3(-800.0, 0.0, 1000.0), VERGE + Vector3(6.0, 0.0, 0.0)]:
		var off := _place(at)
		assert_false(bool(off.get("ok")), "an arch off the Rodfolk footings is refused at %s" % at)
		assert_eq(str(off.get("code", "")), "arch_locked")
		assert_eq(str(off.get("reason", "")), OFF_FOOTING)
	assert_true(world.placed_buildings.is_empty(), "a refused footing commits nothing")
	assert_true(bool(_place(VERGE + Vector3(4.0, 0.0, 0.0)).get("ok")), "the footing accepts an arch within its 5 m seat")


func test_one_footing_carries_one_arch() -> void:
	# The seat is 5 m wide, so two arches 8 m apart can both sit on it.
	var first := _place(VERGE + Vector3(4.0, 0.0, 0.0))
	assert_true(bool(first.get("ok")))
	assert_eq(str(_record(str(first.get("uid", ""))).get("arch_footing", "")), "verge_road")
	_assert_refused(_place(VERGE + Vector3(-4.0, 0.0, 0.0), PEER_B), OCCUPIED,
		"a second arch on the far side of the same seat is refused")
	_assert_refused(_place(VERGE + Vector3(0.0, 0.0, 4.0)), OCCUPIED, "and on any side of it")
	assert_eq(world.placed_buildings.size(), 1)
	# Every footing takes one arch, so the mandatory Crown twin is never
	# crowded out by doubled optional footings.
	for at: Vector3 in [HOLLOWS + Vector3(4.0, 0.0, 0.0), CAPACITOR + Vector3(4.0, 0.0, 0.0)]:
		assert_true(bool(_place(at).get("ok")))
		_assert_refused(_place(at - Vector3(8.0, 0.0, 0.0)), OCCUPIED, "one arch per footing at %s" % at)
	assert_true(bool(_place(STILL_GROVE).get("ok")), "the Crown twin still fits under the cap")


func test_a_legacy_arch_without_a_saved_footing_still_occupies_its_seat() -> void:
	# A record saved without `arch_footing` is judged by where it stands.
	_load_legacy_save([], [VERGE + Vector3(4.0, 0.0, 0.0)])
	(world.placed_buildings[0] as Dictionary).erase("arch_footing")
	_assert_refused(_place(VERGE + Vector3(-4.0, 0.0, 0.0)), OCCUPIED,
		"a footing-less record inside the seat occupies it")
	assert_true(bool(_place(HOLLOWS).get("ok")), "it occupies no other footing")


func test_the_plan_names_the_footings_canonical_seat() -> void:
	var plan := BUILT.placement(VERGE + Vector3(3.0, 7.0, -2.0), "stormwood", world.flags, [])
	assert_true(bool(plan.get("ok")))
	assert_eq(str(plan.get("footing", "")), "verge_road")
	assert_eq(plan.get("at"), Vector3(VERGE.x, 7.0, VERGE.z), "the plan names the footing centre")


func test_free_build_is_still_refused_off_a_footing() -> void:
	# WORLD §5.3: free-build waives material cost only. `paid: false` is how
	# the placer marks a free-build intent; the ledger then skips materials.
	for at: Vector3 in [Vector3(-800.0, 0.0, 1000.0), VERGE + Vector3(6.0, 0.0, 0.0)]:
		var free: Dictionary = ledger.commit({"kind": "place_building", "realm": "stormwood",
			"id": "stormglass_arch", "position": at, "paid": false}, PEER_A)
		_assert_refused(free, OFF_FOOTING, "free-build does not waive the footing at %s" % at)
	assert_true(world.placed_buildings.is_empty(), "a refused free-build commits nothing")
	var legal: Dictionary = ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": VERGE, "paid": false}, PEER_A)
	assert_true(bool(legal.get("ok")), "free-build on a legal footing needs no materials")
	_assert_refused(ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": VERGE + Vector3(-4.0, 0.0, 0.0), "paid": false}, PEER_B),
		OCCUPIED, "free-build does not waive one arch per footing")


func test_a_legacy_unpaired_arch_never_becomes_a_legal_arch_twin() -> void:
	var legacy := _load_legacy_save(LEGACY_PAIRS.slice(0, 1), [Vector3(-300.0, 0.0, 600.0)])
	var stray := legacy[2]
	assert_eq(str(_record(stray).get("arch_twin", "")), "", "the legacy stray waits unpaired")
	var first := _place(VERGE)
	var first_uid := str(first.get("uid", ""))
	assert_true(bool(first.get("ok")))
	assert_eq(str(_record(first_uid).get("arch_twin", "")), "",
		"a legal arch waits for a legal partner instead of the off-footing stray")
	assert_eq(str(_record(stray).get("arch_twin", "")), "", "the stray is not captured")
	var second := _place(HOLLOWS)
	var second_uid := str(second.get("uid", ""))
	assert_true(bool(second.get("ok")))
	assert_eq(str(_record(first_uid).get("arch_twin", "")), second_uid, "two legal arches pair")
	assert_eq(str(_record(second_uid).get("arch_twin", "")), first_uid)
	# The legacy pair still loads as a road and still travels both ways.
	assert_eq(str(BUILT.linked_twin(legacy[0], world.flags, world.placed_buildings).get("id", "")), legacy[1])
	assert_eq(str(BUILT.linked_twin(legacy[1], world.flags, world.placed_buildings).get("id", "")), legacy[0])
	assert_true(BUILT.linked_twin(stray, world.flags, world.placed_buildings).is_empty(),
		"the unpaired stray still has no road")


func test_still_grove_can_only_raise_the_crowns_one_fixed_twin() -> void:
	var first := _place(STILL_GROVE)
	assert_true(bool(first.get("ok")))
	assert_eq(str(_record(str(first.get("uid", ""))).get("arch_twin", "")), "e_crown")
	var second := _place(STILL_GROVE, PEER_B)
	assert_false(bool(second.get("ok")))
	assert_eq(world.placed_buildings.size(), 1)


func test_wrong_realm_missing_recipe_locked_deepwood_and_island_are_refused() -> void:
	var wrong_realm: Dictionary = ledger.commit({"kind": "place_building", "realm": "meadows",
		"id": "stormglass_arch", "position": VERGE,
		"available_materials": {"stormglass": 100, "stormglass_crown": 100,
			"thunderwood_frame": 100, "conductor_vine": 100}}, PEER_A)
	assert_false(bool(wrong_realm.get("ok")))

	var untrained_world: RefCounted = WORLD_STATE.new()
	var untrained_ledger: RefCounted = WORLD_LEDGER.new(untrained_world)
	var no_recipe: Dictionary = untrained_ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": VERGE,
		"available_materials": {"stormglass": 100, "stormglass_crown": 100,
			"thunderwood_frame": 100, "conductor_vine": 100}}, PEER_A)
	assert_false(bool(no_recipe.get("ok")))

	var deepwood := _place(DEEPWOOD)
	assert_false(bool(deepwood.get("ok")))
	var island := _place(Vector3(485.0, 0.0, 2700.0))
	assert_false(bool(island.get("ok")))
	assert_true(world.placed_buildings.is_empty(), "every refused placement leaves no world record")


func test_crown_footing_refuses_the_ordinary_stormglass_grade() -> void:
	var verdict: Dictionary = ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": STILL_GROVE,
		"available_materials": {"stormglass": 6, "thunderwood_frame": 2, "conductor_vine": 4}}, PEER_A)
	assert_false(bool(verdict.get("ok")))
	assert_eq(str(verdict.get("code", "")), "arch_materials")
	assert_true(world.placed_buildings.is_empty())


func test_save_load_preserves_constructed_pair_metadata() -> void:
	var first := _place(VERGE)
	var second := _place(HOLLOWS)
	var saved: Dictionary = world.save_data()
	var restored: RefCounted = WORLD_STATE.new()
	restored.load_data(saved)
	var first_uid := str(first.get("uid", ""))
	var second_uid := str(second.get("uid", ""))
	var a := restored.placed_buildings[restored.building_index_of(first_uid)] as Dictionary
	var b := restored.placed_buildings[restored.building_index_of(second_uid)] as Dictionary
	assert_eq(str(a.get("arch_twin", "")), second_uid)
	assert_eq(str(b.get("arch_twin", "")), first_uid)
	assert_false(str(a.get("arch_footing", "")).is_empty())
	assert_eq(restored.save_data().get("placed_buildings"), saved.get("placed_buildings"))


func test_two_peers_placing_on_one_footing_are_serialised_to_one_winner() -> void:
	var first := _place(VERGE, PEER_A)
	var second := _place(VERGE, PEER_B)
	assert_true(bool(first.get("ok")), "the first request the host commits owns the footing")
	assert_false(bool(second.get("ok")), "the second serialised request is refused")
	assert_eq(world.placed_buildings.size(), 1)
	assert_eq(str(world.placed_buildings[0].get("uid", "")), str(first.get("uid", "")))

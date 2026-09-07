extends "res://tests/test_case.gd"

## The runtime preview checks the same placement rule, but these tests prove the
## host ledger is the authority once two peers' intents are serialised.
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")

const PEER_A := 1
const PEER_B := 771240190

const VERGE := Vector3(-630.0, 0.0, 800.0)
const HOLLOWS := Vector3(-1050.0, 0.0, 1750.0)
const CAPACITOR := Vector3(-1040.0, 0.0, 3070.0)
const STILL_GROVE := Vector3(-160.0, 0.0, 2750.0)
const DEEPWOOD := Vector3(-400.0, 0.0, 4540.0)

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

	for at: Vector3 in [VERGE, HOLLOWS, CAPACITOR, Vector3(-800.0, 0.0, 1000.0)]:
		assert_true(bool(_place(at).get("ok")), "two ordinary roads may stand beside the Crown road")
	var blocked := _place(Vector3(-700.0, 0.0, 1600.0))
	assert_false(bool(blocked.get("ok")))
	assert_eq(str(blocked.get("code", "")), "arch_locked")


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

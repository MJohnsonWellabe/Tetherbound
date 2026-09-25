extends "res://tests/test_case.gd"

## X05 work orders on the host world ledger:
## - F05 finding 6 (#221): an owned receipt such as
##   `legendary_resolution:accepted:<character_id>` can only be written by that
##   character (host-originated writes stay trusted);
## - Stormwood: a Stormglass arch commits at its footing centre.

const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const ARCH_BUILD := preload("res://scripts/world/stormwood_arch_build_rules.gd")

const HOST := 1
const GUEST := 771240190
const VERGE := Vector3(-630.0, 0.0, 800.0)

var world: RefCounted
var ledger: RefCounted


func before_each() -> void:
	world = WORLD_STATE.new()
	ledger = WORLD_LEDGER.new(world)


func _flag(id: String, actor: String) -> Dictionary:
	# `_actor_character_id` is what ledger_rpc.gd injects from the registry.
	return {"kind": "set_world_flag", "realm": "stormwood", "id": id, "_actor_character_id": actor}


func test_remote_peer_cannot_write_another_characters_legendary_receipt() -> void:
	for id: String in ["legendary_resolution:accepted:victim-char",
			"legendary_resolution:refused:victim-char",
			"stormwood:legendary_resolution:accepted:victim-char"]:
		var verdict: Dictionary = ledger.commit(_flag(id, "forger-char"), GUEST)
		assert_false(bool(verdict.get("ok")), "%s forged by another character" % id)
		assert_eq(str(verdict.get("code", "")), "not_your_character")
		assert_false(world.flags.has(id), "a refused receipt writes nothing")


func test_remote_peer_writes_only_its_own_receipt_and_host_stays_trusted() -> void:
	var own := "stormwood:legendary_resolution:accepted:guest-char"
	assert_true(bool(ledger.commit(_flag(own, "guest-char"), GUEST).get("ok")))
	assert_true(world.flags.has(own))
	var empty_actor: Dictionary = ledger.commit(
		_flag("legendary_resolution:refused:guest-char", ""), GUEST)
	assert_false(bool(empty_actor.get("ok")), "an unregistered sender owns no receipt")
	var for_guest := "legendary_resolution:accepted:guest-char"
	assert_true(bool(ledger.commit(_flag(for_guest, "host-char"), HOST).get("ok")),
		"host code records receipts for participants it validated")
	assert_true(bool(ledger.commit(_flag("stormwood:rootgate_released", "anyone"), GUEST).get("ok")),
		"ordinary world flags are unaffected")


func test_prefix_list_covers_all_chapters_and_matches_generically() -> void:
	var prefixes := WORLD_LEDGER.owned_flag_prefixes()
	for p: String in ["legendary_resolution:accepted:", "stormwood:legendary_resolution:refused:",
			"tidewake:legendary_resolution:accepted:"]:
		assert_true(prefixes.has(p), p)
	assert_true(WORLD_LEDGER.owned_flag_allowed("unowned:flag", GUEST, ""))
	assert_false(WORLD_LEDGER.owned_flag_allowed("legendary_resolution:accepted:", GUEST, ""),
		"a receipt with no character is never a remote peer's")


func test_stormglass_arch_commits_at_the_footing_centre() -> void:
	world.flags.set_flag("stormwood:arch_recipe_known")
	var socket: Dictionary = ARCH_BUILD.footing_at(VERGE)
	assert_false(socket.is_empty(), "VERGE is an authored arch footing")
	var off := Vector3(float(socket.at[0]) + 3.0, 4.25, float(socket.at[1]) - 2.0)
	assert_false(ARCH_BUILD.footing_at(off).is_empty(), "the request lands inside the footing radius")
	var verdict: Dictionary = ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": off,
		"available_materials": {"stormglass": 100, "stormglass_crown": 100,
			"thunderwood_frame": 100, "conductor_vine": 100}}, GUEST)
	assert_true(bool(verdict.get("ok")), str(verdict))
	var record: Dictionary = world.placed_buildings[int(world.building_index_of(str(verdict.uid)))]
	var at: Array = record.get("position", [])
	assert_almost_eq(float(at[0]), float(socket.at[0]), 0.001, "x snapped to the footing centre")
	assert_almost_eq(float(at[2]), float(socket.at[1]), 0.001, "z snapped to the footing centre")
	assert_almost_eq(float(at[1]), 4.25, 0.001, "height stays the request's ground height")


func test_other_intent_kinds_cannot_smuggle_a_forged_receipt() -> void:
	var id := "stormwood:legendary_resolution:accepted:victim-char"
	for intent: Dictionary in [
			{"kind": "claim_pickup", "realm": "stormwood", "flag": id, "item": "stick", "count": 1},
			{"kind": "harvest", "realm": "stormwood", "flag": id, "item": "stick", "amount": 1}]:
		intent["_actor_character_id"] = "forger-char"
		var verdict: Dictionary = ledger.commit(intent, GUEST)
		assert_false(bool(verdict.get("ok")), "%s must not write another character's receipt" % intent.kind)
		assert_false(world.flags.has(id))


func test_remote_peer_cannot_clear_another_characters_receipt() -> void:
	var id := "legendary_resolution:accepted:victim-char"
	assert_true(bool(ledger.commit(_flag(id, "host-char"), HOST).get("ok")))
	var clear := _flag(id, "forger-char")
	clear["value"] = false
	assert_false(bool(ledger.commit(clear, GUEST).get("ok")))
	assert_true(world.flags.has(id), "the victim's receipt survives")


func test_second_arch_at_the_footing_edge_cannot_snap_onto_an_occupied_footing() -> void:
	world.flags.set_flag("stormwood:arch_recipe_known")
	var socket: Dictionary = ARCH_BUILD.footing_at(VERGE)
	var centre := Vector3(float(socket.at[0]), 0.0, float(socket.at[1]))
	var materials := {"stormglass": 100, "stormglass_crown": 100, "thunderwood_frame": 100, "conductor_vine": 100}
	assert_true(bool(ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": centre, "available_materials": materials}, HOST).get("ok")))
	for edge: Vector3 in [centre + Vector3(5.0, 0.0, 0.0), centre + Vector3(4.0, 3.0, 0.0)]:
		var verdict: Dictionary = ledger.commit({"kind": "place_building", "realm": "stormwood",
			"id": "stormglass_arch", "position": edge, "available_materials": materials}, GUEST)
		assert_false(bool(verdict.get("ok")), "edge request %s refused" % str(edge))
		assert_eq(str(verdict.get("code", "")), "arch_occupied")
	assert_eq(ARCH_BUILD.records(world.placed_buildings).size(), 1, "still one arch on the footing")


func test_snapped_arch_takes_the_footing_facing() -> void:
	world.flags.set_flag("stormwood:arch_recipe_known")
	var socket: Dictionary = ARCH_BUILD.footing_at(VERGE)
	var verdict: Dictionary = ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": VERGE + Vector3(1.0, 0.0, 1.0), "yaw_deg": 137.0,
		"available_materials": {"stormglass": 100, "stormglass_crown": 100,
			"thunderwood_frame": 100, "conductor_vine": 100}}, GUEST)
	var record: Dictionary = world.placed_buildings[int(world.building_index_of(str(verdict.uid)))]
	assert_almost_eq(float(record.get("yaw_deg", -1.0)), float(socket.get("yaw_deg", 0.0)), 0.001)


func test_host_overwrites_a_claimed_identity_with_the_registry_answer() -> void:
	const LEDGER_RPC := preload("res://scripts/net/ledger_rpc.gd")
	const REGISTRY := preload("res://scripts/net/peer_registry.gd")
	var claimed := {"kind": "set_world_flag", "_actor_character_id": "victim-char"}
	var stamped: Dictionary = LEDGER_RPC.with_host_actor(claimed, "guest-char")
	assert_eq(stamped["_actor_character_id"], "guest-char")
	assert_eq(claimed["_actor_character_id"], "victim-char", "the request itself is not mutated")
	var roster := REGISTRY.new()
	roster.add(HOST, "host-char")
	roster.add(GUEST, "guest-char")
	assert_eq(LEDGER_RPC.registered_character(GUEST, HOST, "host-char", roster), "guest-char")
	assert_eq(LEDGER_RPC.registered_character(HOST, HOST, "host-char", roster), "host-char")
	assert_eq(LEDGER_RPC.registered_character(424242, HOST, "host-char", roster), "",
		"a transport peer outside the registry has no character")
	assert_eq(LEDGER_RPC.registered_character(GUEST, HOST, "host-char", null), "")


func test_actor_identity_does_not_outlive_its_commit() -> void:
	ledger.commit(_flag("stormwood:rootgate_released", "guest-char"), GUEST)
	assert_eq(str(ledger.get("_actor_character")), "", "no later _commit caller inherits it")


func test_arch_rules_are_judged_at_the_snapped_centre() -> void:
	# With today's footing data the reorder is observable only through the
	# refusal code: every request inside an occupied footing's radius is
	# judged at the centre and refused as arch_occupied, never by the raw
	# request position's own distance check (arch_locked).
	world.flags.set_flag("stormwood:arch_recipe_known")
	var socket: Dictionary = ARCH_BUILD.footing_at(VERGE)
	var centre := Vector3(float(socket.at[0]), 0.0, float(socket.at[1]))
	var materials := {"stormglass": 100, "stormglass_crown": 100, "thunderwood_frame": 100, "conductor_vine": 100}
	assert_true(bool(ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": centre, "available_materials": materials}, HOST).get("ok")))
	var near: Dictionary = ledger.commit({"kind": "place_building", "realm": "stormwood",
		"id": "stormglass_arch", "position": centre + Vector3(2.0, 0.0, 0.0),
		"available_materials": materials}, GUEST)
	assert_false(bool(near.get("ok")))
	assert_eq(str(near.get("code", "")), "arch_occupied")

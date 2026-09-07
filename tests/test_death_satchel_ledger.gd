extends "res://tests/test_case.gd"
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
func check(ok: bool, label: String) -> void:
	assert_true(ok, label)
func test_owned_transactions_and_reconnect_receipts() -> void:
	var world := WORLD.new()
	var ledger := LEDGER.new(world)
	var context := {"peer": 2, "character_id": "owner", "realm": "water", "position": Vector3(200, 0.15, 260)}
	var create := {"kind": "death_satchel_create", "realm": "water", "txn_id": "create-1",
		"_satchel_actor": context, "owner": "forged", "position": [200, 0.15, 260], "state": [{"id": "wood", "n": 3}]}
	var result := ledger.commit(create, 2)
	check(result.ok and world.death_satchels.size() == 1 and world.death_satchels[0].owner == "owner", "Host actor owns created satchel; requested owner is ignored")
	check(not ledger.commit(create, 2).ok and world.death_satchels.size() == 1, "Creation replay cannot duplicate bag")
	var uid: String = world.death_satchels[0].uid
	var transfer := {"kind": "death_satchel_transfer", "realm": "water", "txn_id": "take-1", "uid": uid,
		"expected_revision": 0, "direction": "withdraw", "item": "wood", "count": 2, "personal": [], "_satchel_actor": context}
	var wrong := transfer.duplicate(true)
	wrong._satchel_actor.character_id = "intruder"
	check(ledger.commit(wrong, 2).code == "not_owner", "Host refuses forged owner before any move")
	wrong = transfer.duplicate(true)
	wrong._satchel_actor.position += Vector3(10, 0, 0)
	check(ledger.commit(wrong, 2).code == "too_far", "Host proximity required")
	wrong = transfer.duplicate(true)
	wrong.count = []
	check(ledger.commit(wrong, 2).code == "malformed", "Malformed numeric count refuses without script error")
	check(ledger.commit(transfer, 2).ok and ledger.storage_revision("satchel:" + uid) == 1, "Owned transfer commits revision")
	check(world.death_satchels[0].state[0].n == 1, "Host computes container result from authoritative contents")
	wrong = transfer.duplicate(true)
	wrong.txn_id = "stale-new-id"
	check(ledger.commit(wrong, 2).code == "stale_revision", "Concurrent stale write cannot win twice")
	var reloaded := WORLD.new()
	reloaded.load_data(JSON.parse_string(JSON.stringify(world.save_data())))
	var new_ledger := LEDGER.new(reloaded)
	check(new_ledger.storage_revision("satchel:" + uid) == 1, "Container revision survives host save and new ledger")
	check(new_ledger.commit(transfer, 2).code == "duplicate", "Reconnecting stale request cannot replay after host reload")
	check(new_ledger.commit(create, 2).code == "duplicate", "Creation receipt survives host reload")
	var legacy := WORLD.new()
	legacy.load_data({"death_satchels": [{"realm": "water", "position": [200, 0, 260], "state": []}]})
	check(legacy.death_satchel_index_of("legacy_satchel_0") == 0 and not legacy.death_satchels[0].has("owner"), "Legacy unowned bag gains stable identity without changing ownership")

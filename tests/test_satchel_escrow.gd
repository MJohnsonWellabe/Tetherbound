extends "res://tests/test_case.gd"
const ESCROW := preload("res://scripts/net/satchel_escrow.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")


class SaverFixture extends RefCounted:
	var writes := 0
	func save_character(_game: Object, _character_id: String) -> bool:
		writes += 1
		return true


class GameFixture extends Node:
	var world: RefCounted = preload("res://autoload/world_state.gd").new()
	var local: RefCounted = preload("res://autoload/player_state.gd").new()
	var save_system: RefCounted = SaverFixture.new()
	var current_realm := "water"
	var messages: Array = []
	func is_host() -> bool: return false
	func is_multi_peer() -> bool: return false
	func push_world_message(message: String) -> void: messages.append(message)
	func apply_world_snapshot(data: Dictionary) -> void: world.load_data(data)


class RpcFixture extends "res://scripts/net/ledger_rpc.gd":
	var fixture_game: Node
	var submit_calls := 0
	func _game() -> Node: return fixture_game
	func submit(intent: Dictionary) -> Dictionary:
		submit_calls += 1
		return {"ok": false, "pending": true, "kind": str(intent.get("kind", ""))}


var player: RefCounted
var world: RefCounted
var ledger: RefCounted
func before_each() -> void:
	player = PLAYER.new()
	player.configure(ESCROW.RULES.db())
	player.character_id = "escrow-owner"
	player.realm = "water"
	world = WORLD.new()
	world.world_id = "escrow-world"
	world.reward_delivery_namespace = "world-instance-a"
	ledger = LEDGER.new(world)
func reload_character() -> void:
	var saved: Dictionary = JSON.parse_string(JSON.stringify(player.save_data()))
	player = PLAYER.new()
	player.configure(ESCROW.RULES.db())
	player.load_data(saved)
func request(txn: String, peer: int = 2) -> Dictionary:
	var intent: Dictionary = player.satchel_escrow[txn].intent.duplicate(true)
	intent._satchel_actor = {"peer": peer, "character_id": player.character_id, "realm": "water", "position": Vector3(200, 0.15, 260)}
	return intent
func container(stacks: Array = []) -> String:
	var index: int = world.register_death_satchel(Vector3(200, 0.15, 260), player.character_id, "water", "owned")
	world.death_satchels[index].state = stacks
	return "owned"
func fill_inventory() -> void:
	for i in player.inventory.slot_count():
		player.inventory.set_slot(i, {"id": "stone", "n": 99})
func test_death_disconnect_before_and_after_host_commit() -> void:
	player.inventory.add("wood", 3)
	var txn := ESCROW.begin_drop(player, world, Vector3(200, 0.15, 260), "water", false)
	assert_eq(player.inventory.count("wood"), 0, "Escrow is not usable inventory")
	reload_character()
	assert_eq(player.satchel_escrow[txn].status, "pending", "Scene/character teardown retains uncommitted death")
	assert_eq(player.satchel_escrow[txn].stacks[0].n, 3)
	assert_true(ledger.commit(request(txn, 9), 9).ok, "Changed peer ID may retry same character transaction")
	# Host committed while disconnected: no scene callback is present.
	reload_character()
	ESCROW.reconcile(player, world)
	assert_eq(player.satchel_escrow[txn].status, "settled")
	assert_eq(player.inventory.count("wood"), 0)
	assert_eq(world.death_satchels.size(), 1)
	assert_eq(world.death_satchels[0].state[0].n, 3)
	ESCROW.reconcile(player, world)
	assert_eq(world.death_satchels.size(), 1, "Repeated reconciliation creates no second bag")
func test_withdraw_disconnect_capacity_race_and_duplicate_delta() -> void:
	var uid := container([{"id": "wood", "n": 3}])
	var txn := ESCROW.begin_transfer(player, world, uid, "withdraw", "wood", 3, 0, false)
	var intent := request(txn)
	fill_inventory()
	reload_character()
	var verdict: Dictionary = ledger.commit(intent, 2)
	assert_true(verdict.ok)
	ESCROW.reconcile(player, world)
	assert_eq(player.inventory.count("wood"), 0)
	assert_eq(player.satchel_escrow[txn].status, "grant_due", "Full inventory cannot discard committed withdrawal")
	assert_eq(player.satchel_escrow[txn].stacks[0].n, 3)
	reload_character()
	player.inventory.set_slot(0, null)
	ESCROW.reconcile(player, world)
	assert_eq(player.inventory.count("wood"), 3, "Making room delivers durable pending recovery")
	assert_eq(player.satchel_escrow[txn].status, "settled")
	ledger.apply(verdict.delta)
	ESCROW.reconcile(player, world)
	assert_eq(player.inventory.count("wood"), 3, "Repeated delta and reconciliation grant exactly once")
func test_deposit_refusal_is_targeted_and_keeps_tool_metadata_when_full() -> void:
	var uid := container()
	player.inventory.set_slot(0, {"id": "pickaxe", "n": 1, "durability": 4, "durability_bonus": 9})
	var txn := ESCROW.begin_transfer(player, world, uid, "deposit", "pickaxe", 1, 0, false)
	assert_eq(player.inventory.count("pickaxe"), 0, "Pending deposit owns its inaccessible tool")
	fill_inventory()
	assert_false(ESCROW.refuse(player, world, "unrelated-txn"))
	assert_eq(player.satchel_escrow[txn].status, "pending")
	assert_true(ESCROW.refuse(player, world, txn))
	assert_eq(player.satchel_escrow[txn].status, "refund_due", "Full inventory retains refused deposit in escrow")
	reload_character()
	player.inventory.set_slot(0, null)
	ESCROW.reconcile(player, world)
	var tool: Dictionary = player.inventory.stack_at(0)
	assert_eq(tool.id, "pickaxe")
	assert_eq(tool.durability, 4)
	assert_eq(tool.durability_bonus, 9)
	assert_false(ESCROW.refuse(player, world, txn), "Repeated refusal cannot duplicate refund")
func test_two_pending_deaths_refuse_only_the_addressed_one_and_scope_world() -> void:
	player.inventory.add("wood", 3)
	var first := ESCROW.begin_drop(player, world, Vector3(200, 0.15, 260), "water", false)
	player.inventory.add("wood", 5)
	var second := ESCROW.begin_drop(player, world, Vector3(200, 0.15, 260), "water", false)
	assert_true(ESCROW.refuse(player, world, first))
	assert_eq(player.inventory.count("wood"), 3)
	assert_eq(player.satchel_escrow[second].status, "pending")
	assert_true(ledger.commit(request(second), 2).ok)
	var other := WORLD.new()
	other.world_id = "other-world"
	ESCROW.reconcile(player, other)
	assert_eq(player.satchel_escrow[second].status, "pending", "Other world cannot settle or refund escrow")
	ESCROW.reconcile(player, world)
	assert_eq(player.inventory.count("wood"), 3)
	assert_eq(world.death_satchels[0].state[0].n, 5)


func test_pending_death_does_not_retry_in_other_host_with_same_slot_locator() -> void:
	player.inventory.add("wood", 3)
	var txn := ESCROW.begin_drop(player, world, Vector3(200, 0.15, 260), "water", false)
	assert_false(txn.is_empty())
	var other := WORLD.new()
	other.world_id = world.world_id
	other.reward_delivery_namespace = "world-instance-b"
	assert_false(ESCROW.belongs(player.satchel_escrow[txn], player, other),
		"slot names are reused by independent hosts; a pending death belongs only to its world instance")
	assert_true(ESCROW.belongs(player.satchel_escrow[txn], player, world),
		"the same durable row still belongs to its exact originating world")
	player.satchel_escrow[txn].intent.world_instance_id = "tampered-instance"
	assert_false(ESCROW.intent_matches(player.satchel_escrow[txn], player, world),
		"submission also binds the nested durable intent to the same world instance")


func test_missing_world_identity_refuses_before_inventory_mutation() -> void:
	world.reward_delivery_namespace = ""
	player.inventory.add("wood", 3)
	assert_eq(ESCROW.begin_drop(player, world, Vector3.ZERO, "water", false), "")
	assert_eq(player.inventory.count("wood"), 3)
	var uid := container()
	assert_eq(ESCROW.begin_transfer(player, world, uid, "deposit", "wood", 2, 0, false), "")
	assert_eq(player.inventory.count("wood"), 3)
	assert_true(player.satchel_escrow.is_empty())
	world.reward_delivery_namespace = "world-instance-a"
	world.death_satchels[world.death_satchel_index_of(uid)].owner = ""
	player.character_id = ""
	assert_eq(ESCROW.begin_drop(player, world, Vector3.ZERO, "water", false), "")
	assert_eq(ESCROW.begin_transfer(player, world, uid, "deposit", "wood", 2, 0, false), "")
	assert_eq(player.inventory.count("wood"), 3,
		"missing character identity refuses before either operation can drain items")
	assert_true(player.satchel_escrow.is_empty())


func test_foreign_pending_transfer_does_not_block_same_uid_in_this_world() -> void:
	var uid := container([{"id": "wood", "n": 3}])
	var foreign_txn := ESCROW.begin_transfer(player, world, uid, "withdraw", "wood", 1, 0, false)
	assert_false(foreign_txn.is_empty())
	var current := WORLD.new()
	current.world_id = world.world_id
	current.reward_delivery_namespace = "world-instance-b"
	var index: int = current.register_death_satchel(Vector3(200, 0.15, 260),
		player.character_id, "water", uid)
	current.death_satchels[index].state = [{"id": "wood", "n": 3}]
	var current_txn := ESCROW.begin_transfer(player, current, uid, "withdraw", "wood", 1, 0, false)
	assert_false(current_txn.is_empty(),
		"a pending move from another world instance cannot reserve this world's same UID")


func test_legacy_pending_requires_exact_nonempty_owner_receipt() -> void:
	var txn := "legacy-create-proof"
	var legacy := {"status": "pending", "kind": "death_satchel_create",
		"world_id": world.world_id, "character_id": player.character_id,
		"stacks": [{"id": "wood", "n": 3}], "intent": {"kind": "death_satchel_create"}}
	player.satchel_escrow[txn] = legacy
	var before := legacy.duplicate(true)
	ESCROW.reconcile(player, world)
	assert_eq(player.satchel_escrow[txn], before,
		"an unproven legacy row is preserved without replay or refund")
	var empty_owner_index: int = world.register_death_satchel(Vector3.ZERO, "", "water",
		"death_" + txn)
	world.death_satchels[empty_owner_index].state = [{"id": "wood", "n": 3}]
	ESCROW.reconcile(player, world)
	assert_eq(player.satchel_escrow[txn].status, "pending",
		"an owner-empty bag is not proof for a portable legacy character")
	world.death_satchels[empty_owner_index].owner = player.character_id
	ESCROW.reconcile(player, world)
	assert_eq(player.satchel_escrow[txn].status, "settled",
		"the exact owner-bound persisted receipt resolves without resubmission")
	var transfer_txn := "legacy-transfer-proof"
	var uid := "legacy-owned-satchel"
	player.satchel_escrow[transfer_txn] = {"status": "pending", "kind": "death_satchel_transfer",
		"world_id": world.world_id, "character_id": player.character_id, "uid": uid,
		"direction": "withdraw", "stacks": [{"id": "stone", "n": 2}],
		"intent": {"kind": "death_satchel_transfer"}}
	var transfer_index: int = world.register_death_satchel(Vector3.ZERO,
		player.character_id, "water", uid)
	world.death_satchels[transfer_index]["transactions"] = []
	ESCROW.reconcile(player, world)
	assert_eq(player.satchel_escrow[transfer_txn].status, "pending",
		"ownership alone cannot prove that a legacy transfer committed")
	world.death_satchels[transfer_index].transactions.append(transfer_txn)
	ESCROW.reconcile(player, world)
	assert_eq(player.inventory.count("stone"), 2)
	assert_eq(player.satchel_escrow[transfer_txn].status, "settled",
		"the exact owner and transaction receipt resolve a legacy withdrawal once")


func test_known_personal_outcome_settles_outside_origin_world_once() -> void:
	var txn := "known-refund"
	player.satchel_escrow[txn] = {"status": "refund_due", "kind": "death_satchel_transfer",
		"world_id": "old-slot", "character_id": player.character_id,
		"stacks": [{"id": "wood", "n": 3}]}
	ESCROW.reconcile(player, world)
	assert_eq(player.inventory.count("wood"), 3)
	assert_eq(player.satchel_escrow[txn].status, "settled")
	ESCROW.reconcile(player, world)
	assert_eq(player.inventory.count("wood"), 3, "known personal settlement stays idempotent")


func test_transport_quarantines_unproven_verdicts_and_nested_intents() -> void:
	var game := GameFixture.new()
	game.world.world_id = "escrow-world"
	game.world.reward_delivery_namespace = "world-instance-a"
	game.local.configure(ESCROW.RULES.db())
	game.local.character_id = "trainer-a"
	game.local.realm = "water"
	game.local.inventory.add("wood", 3)
	var txn := ESCROW.begin_drop(game.local, game.world, Vector3.ZERO, "water", false)
	var rpc: Node = RpcFixture.new()
	rpc.set("fixture_game", game)
	rpc.set("ledger", LEDGER.new(game.world))
	var row: Dictionary = game.local.satchel_escrow[txn]
	row.intent.world_instance_id = "tampered-instance"
	var submit_result: Dictionary = rpc.call("_submit_satchel_escrow", txn)
	assert_true(bool(submit_result.get("pending")))
	assert_eq(int(rpc.get("submit_calls")), 0,
		"a nested world mismatch is quarantined before transport submission")
	assert_eq(int(game.save_system.writes), 0,
		"an unprovable request is refused before a durable send boundary")
	row.intent.world_instance_id = "world-instance-a"
	var before_row: Dictionary = row.duplicate(true)
	var before_world: Dictionary = game.world.save_data()
	for verdict_instance: Variant in [null, "foreign-instance"]:
		var verdict := {"kind": "death_satchel_create", "code": "wrong_world", "txn_id": txn}
		if verdict_instance != null:
			verdict["world_instance_id"] = verdict_instance
		assert_false(bool(rpc.call("_handle_satchel_verdict", verdict)))
		assert_eq(game.local.satchel_escrow[txn], before_row,
			"a missing or foreign verdict cannot refund or consume the durable row")
		assert_eq(game.local.inventory.count("wood"), 0,
			"a missing or foreign verdict cannot duplicate the drained stack")
	var foreign_snapshot: Dictionary = before_world.duplicate(true)
	foreign_snapshot.reward_delivery_namespace = "foreign-instance"
	foreign_snapshot.flags["foreign_snapshot_marker"] = true
	assert_false(bool(rpc.call("_handle_satchel_verdict", {"kind": "death_satchel_create",
		"code": "duplicate", "txn_id": txn, "world_instance_id": "world-instance-a",
		"satchel_recovery_snapshot": {"seq": 4, "world": foreign_snapshot}})))
	assert_eq(game.world.save_data(), before_world,
		"a recovery snapshot with another world instance cannot replace the current world")
	row.world_id = "another-locator"
	assert_false(bool(rpc.call("_handle_satchel_verdict", {"kind": "death_satchel_create",
		"code": "journal_failed", "txn_id": txn, "world_instance_id": "world-instance-a"})),
		"matching namespace alone cannot authorize a verdict for another locator")
	assert_eq(game.local.inventory.count("wood"), 0)
	rpc.free()
	game.free()


func test_replayed_older_world_delta_cannot_resurrect_contents() -> void:
	var uid := container()
	var older := {"ops": [{"scope": "world", "op": "satchel_set", "uid": uid, "state": [{"id": "wood", "n": 3}], "revision": 1, "txn_id": "old"}]}
	var newer := {"ops": [{"scope": "world", "op": "satchel_set", "uid": uid, "state": [], "revision": 2, "txn_id": "new"}]}
	world.apply_delta(older)
	world.apply_delta(newer)
	assert_eq(world.apply_delta(older), 0)
	assert_eq(world.death_satchels[0].revision, 2)
	assert_eq(world.death_satchels[0].state, [])

func test_real_character_file_preserves_pending_and_settled_escrow() -> void:
	player.inventory.add("wood", 3)
	var txn := ESCROW.begin_drop(player, world, Vector3(200, 0.15, 260), "water", false)
	var root_dir := "user://test_satchel_escrow_%d/" % Time.get_ticks_usec()
	var store := preload("res://scripts/save/character_save.gd").new(root_dir)
	assert_true(store.write(player.character_id, player.save_data()))
	var character_id: String = player.character_id
	player = PLAYER.new()
	player.configure(ESCROW.RULES.db())
	player.load_data(store.read(character_id))
	assert_eq(player.inventory.count("wood"), 0)
	assert_eq(player.satchel_escrow[txn].stacks[0].n, 3)
	assert_true(ledger.commit(request(txn), 2).ok)
	ESCROW.reconcile(player, world)
	assert_true(store.write(character_id, player.save_data()))
	player.load_data(store.read(character_id))
	assert_eq(player.satchel_escrow[txn].status, "settled")
	assert_false(player.satchel_escrow[txn].has("stacks"), "Settled receipt retains no extra items")
	DirAccess.remove_absolute(store.path_for(character_id))
	DirAccess.remove_absolute(store.dir_for(character_id))
	DirAccess.remove_absolute(root_dir)

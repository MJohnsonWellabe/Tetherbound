extends "res://tests/test_case.gd"
const ESCROW := preload("res://scripts/net/satchel_escrow.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
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

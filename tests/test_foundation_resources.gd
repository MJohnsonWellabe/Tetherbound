extends "res://tests/test_case.gd"

## Canonical staging, world CAS and JSON save/reload controls. Frozen live-source
## authorization is a fixture here; these do not claim a physical route or ENet.
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const SITES := preload("res://scripts/world/renewable_site_catalog.gd")
const ADAPTER := preload("res://scripts/net/foundation_resources.gd")
const E := preload("res://scripts/creatures/essence.gd")
const CHARACTER := "resource-owner"
const TXN := "0123456789abcdef0123456789abcdef"

func _player() -> RefCounted:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = CHARACTER
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	player.inventory.add("hoe", 1)
	player.inventory.add("berry_seeds", 2)
	return player

func _before() -> Dictionary:
	return RECORD.portable_projection(_player().save_data())

func _world() -> RefCounted:
	var world := WORLD.new()
	world.world_id = "resource-slot"
	world.reward_delivery_namespace = "resource-namespace"
	return world

func _intent() -> Dictionary:
	return {"operation": "node", "request": {"site_id": "essence_meadows_ground_01", "expected_stock_revision": 0, "action_id": TXN}}

func _context() -> Dictionary:
	var site := SITES.by_id("meadows", "essence_meadows_ground_01")
	return {"character_id": CHARACTER, "expected_revision": 0, "source_key": "resource:meadows:" + str(site.get("id", "")),
		"source_id": site.get("id", ""), "world_id": "resource-slot", "world_namespace": "resource-namespace",
		"realm": "meadows", "actor_realm": "meadows", "host_day": 1, "in_range": true, "in_combat": false,
		"modal_open": false, "registered_live_source": true, "source_generation": "1", "source_definition": site,
		"stock": {"revision": 0, "next_ready_day": 1, "generation": 1}, "source_available": true,
		"retained_seed_roll": 0.0, "equipped_tool": "", "resource_runtime_authorized": true, "foundation_runtime_authorized": true}

func _row(before: Dictionary, intent: Dictionary, context: Dictionary) -> Dictionary:
	var proposal := ACTIONS.stage(before, int(context.expected_revision), "resource", intent, context, RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true: return {}
	proposal.character_revision = int(context.expected_revision) + 1
	return DELIVERY.make_record("resource-slot", "resource-namespace", "resource-epoch", proposal, null, RECORD.errors)

func test_host_stock_and_inventory_share_one_journal_and_survive_json_reload_without_repaying() -> void:
	assert_true(SITES.validation_errors().is_empty(), str(SITES.validation_errors()))
	var before := _before()
	var original := before.duplicate(true)
	var row := _row(before, _intent(), _context())
	assert_false(row.is_empty())
	if row.is_empty(): return
	var world := _world()
	var ledger := LEDGER.new(world)
	var verdict := ledger.commit_creature_training_delivery(row, 1)
	assert_true(verdict.get("ok") == true, str(verdict))
	assert_eq(before, original, "planning leaves admitted record untouched")
	assert_eq(world.renewable_stock_state("meadows", "essence_meadows_ground_01"), {"revision": 1, "next_ready_day": 4, "generation": 2})
	assert_eq(verdict.delta.ops.size(), 3, "journal, world stock and owner settlement are one delta")
	var owner := DELIVERY.owner_plan(before, row, RECORD.errors)
	assert_true(owner.ok and owner.requires_owner_save)
	var bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(owner.state.inventory)
	assert_eq(bag.count("essence_ground"), 3)
	assert_eq(bag.count("attuned_ground"), 1)
	assert_eq(bag.count("seed_ground"), 1)
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(row))
	assert_true(DELIVERY.valid(decoded, RECORD.errors), "JSON number representation must retain exact canonical semantics")
	assert_true(ACTIONS.resource_plan(decoded.before, 0, decoded.intent, decoded.host_context).get("ok") == true,
		str(ACTIONS.resource_plan(decoded.before, 0, decoded.intent, decoded.host_context)))
	var loaded := _world()
	loaded.load_data(JSON.parse_string(JSON.stringify(world.save_data())))
	assert_true(E._equivalent(loaded.renewable_stock_state("meadows", "essence_meadows_ground_01"),
		world.renewable_stock_state("meadows", "essence_meadows_ground_01")))
	assert_false(LEDGER.new(loaded).commit_creature_training_delivery(row, 1).ok, "replay cannot consume stock twice")
	assert_true(DELIVERY.owner_plan(owner.state, row, RECORD.errors).duplicate, "lost owner ACK does not grant twice")
	assert_false(ADAPTER.saved_decision({"ok": true, "resolved": true, "owner_saved": false, "owner_acknowledged": false}))
	assert_true(ADAPTER.saved_decision({"ok": true, "resolved": true, "owner_saved": true, "owner_acknowledged": true}))

func test_resource_refusals_and_forged_stock_ops_leave_both_records_unchanged() -> void:
	var before := _before()
	assert_false(_context().source_definition.is_empty())
	if _context().source_definition.is_empty(): return
	for defect: String in ["range", "combat", "modal", "foreign", "stock", "definition", "generation", "unavailable", "extra_intent"]:
		var context := _context()
		var intent := _intent()
		match defect:
			"range": context.in_range = false
			"combat": context.in_combat = true
			"modal": context.modal_open = true
			"foreign": context.character_id = "other"
			"stock": intent.request.expected_stock_revision = 1
			"definition": context.source_definition.outputs.essence_ground = 999
			"generation": context.source_generation = "2"
			"unavailable": context.source_available = false
			"extra_intent": intent.request.outputs = {"essence_ground": 999}
		var original := before.duplicate(true)
		assert_false(ACTIONS.stage(before, 0, "resource", intent, context, RECORD.errors).get("ok", false), defect)
		assert_eq(before, original)
	var world := _world()
	var saved: Dictionary = world.save_data()
	assert_eq(world.apply_delta({"ops": [{"op": "renewable_stock_set", "scope": "world", "realm": "meadows", "site_id": "essence_meadows_ground_01", "state": {"revision": 9, "next_ready_day": 1, "generation": 9}}]}), 0)
	assert_eq(world.save_data(), saved)
	var row := _row(before, _intent(), _context())
	if row.is_empty(): return
	row.host_context.world_namespace = "foreign"
	assert_false(DELIVERY.valid(row, RECORD.errors))

func test_authored_farm_till_uses_same_world_and_owner_commit() -> void:
	var world := _world()
	var before := _before()
	var context := _context()
	context.source_id = "authored:2"
	context.source_key = "resource:meadows:authored:2"
	context.source_generation = "0"
	context.plot = world.resource_plot_state("meadows", "authored:2")
	context.greenhouse_built = false
	var intent := {"operation": "farm", "request": {"plot_id": "authored:2", "action": "till", "crop_id": "", "expected_stock_revision": 0, "action_id": TXN}}
	var row := _row(before, intent, context)
	if row.is_empty(): return
	assert_true(LEDGER.new(world).commit_creature_training_delivery(row, 1).ok)
	assert_eq(world.resource_plot_state("meadows", "authored:2").state, "tilled")
	assert_eq(world.resource_plot_state("meadows", "authored:2").revision, 1)
	assert_eq(world.resource_plot_state("meadows", "authored:0").state, "fallow")
	var source_bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(before.inventory)
	var after_bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(row.after.inventory)
	assert_eq(after_bag.durability_at(after_bag.find_slot("hoe")), source_bag.durability_at(source_bag.find_slot("hoe")) - 1)
	assert_false(LEDGER.new(world).commit_creature_training_delivery(row, 1).ok)

func test_legacy_depletion_wait_is_saved_once_and_does_not_move_when_reloaded() -> void:
	var world := _world()
	world.day = 8
	world.flags.set_flag("harvest_node:order:0", true)
	var loaded := _world()
	loaded.load_data(world.save_data())
	assert_false(loaded.renewable_stock_state("meadows", "order:0").is_empty())
	if loaded.renewable_stock_state("meadows", "order:0").is_empty(): return
	assert_eq(loaded.renewable_stock_state("meadows", "order:0").next_ready_day, 10)
	loaded.day = 9
	var again := _world()
	again.load_data(JSON.parse_string(JSON.stringify(loaded.save_data())))
	assert_eq(again.renewable_stock_state("meadows", "order:0").next_ready_day, 10)

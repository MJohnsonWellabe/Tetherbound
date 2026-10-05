extends "res://tests/test_case.gd"

## Coordinator ruling: a character must never stop gathering after 4096 F32
## gathers. Only the newest f32_receipt_window F32 receipts are kept; each F32
## op's own revision/ticket guard makes an evicted receipt unreplayable.
##
## Disclosed fixtures: the crop harness of test_f32_type_crops.gd (detached
## WorldState with the authored Meadows plot, ordinary PlayerState projection
## with a hoe, frozen host context). The character starts with 4095 prior F32
## receipts, i.e. one gather short of the old refusal. Production staging,
## the ledger commit and DELIVERY.owner_plan are not mocked.
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const F32 := preload("res://scripts/world/f32_source_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const FARM := preload("res://scripts/world/farm_logic.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const CHARACTER := "receipt-window-owner"
const PLOT_ID := "authored:0"

var _txn_counter := 0


func _window() -> int:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/f32_runtime.json"))
	return int((parsed as Dictionary).get("f32_receipt_window", 0))


func _txn() -> String:
	_txn_counter += 1
	return ("window-%d-%d" % [_txn_counter, Time.get_ticks_usec()]).md5_text()


func _f32_receipts(state: Dictionary) -> int:
	var n := 0
	for raw: Variant in state.redesign_character.transaction_receipts:
		if str(raw).begins_with("craft:%s:f32:" % CHARACTER): n += 1
	return n


func _character(prior_f32: int) -> Dictionary:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(ITEM_DB.new())
	player.character_id = CHARACTER
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	for i in 6: player.inventory.add("hoe", 1)
	var record := RECORD.portable_projection(player.save_data())
	for i in prior_f32:
		record.redesign_character.transaction_receipts.append("craft:%s:f32:%s" % [CHARACTER, str(i).sha256_text()])
	return record


func _world() -> RefCounted:
	var world := WORLD.new()
	world.world_id = "receipt-window-slot"
	world.reward_delivery_namespace = "receipt-window-namespace"
	world.day = 1
	world.set_farm_plot(WORLD.resource_plot_index("meadows", PLOT_ID), {"state": FARM.FALLOW, "ripe_on_day": 0, "revision": 1})
	return world


## One real till through Foundation staging, the ledger and the owner plan.
func _till(before: Dictionary, revision: int) -> Dictionary:
	var world := _world()
	var plot: Dictionary = world.resource_plot_state("meadows", PLOT_ID)
	var context := {"character_id": CHARACTER, "expected_revision": revision,
		"source_key": "resource:meadows:" + PLOT_ID, "source_id": PLOT_ID,
		"world_id": world.world_id, "world_namespace": world.reward_delivery_namespace,
		"realm": "meadows", "actor_realm": "meadows", "host_day": int(world.day),
		"in_range": true, "in_combat": false, "modal_open": false,
		"registered_live_source": true, "source_generation": str(int(plot.revision)),
		"plot": plot, "equipped_tool": "hoe", "resource_runtime_authorized": true,
		"foundation_runtime_authorized": true}
	var intent := {"operation": "farm", "request": {"plot_id": PLOT_ID, "action": "till", "crop_id": "",
		"expected_stock_revision": int(plot.revision), "action_id": _txn()}}
	var proposal := ACTIONS.stage(before, revision, "resource", intent, context, RECORD.errors)
	if proposal.get("ok") != true:
		return {"refused": str(proposal.get("code", ""))}
	proposal.character_revision = revision + 1
	var row := DELIVERY.make_record(world.world_id, world.reward_delivery_namespace, "window-epoch",
		proposal, null, RECORD.errors)
	if row.is_empty():
		return {"refused": "row_invalid"}
	var verdict: Dictionary = LEDGER.new(world).commit_creature_training_delivery(row, 1)
	if verdict.get("ok") != true:
		return {"refused": "ledger:" + str(verdict.get("code", ""))}
	var owner := DELIVERY.owner_plan(before, row, RECORD.errors)
	if owner.get("ok") != true:
		return {"refused": "owner:" + str(owner.get("code", ""))}
	return {"state": owner.state}


func test_compaction_keeps_only_the_newest_window_across_five_thousand_gathers() -> void:
	var window := _window()
	assert_true(window >= 2, "the window is configured")
	var receipts: Array = ["care:other:1"]
	for i in 5000:
		receipts = F32.compact_f32_receipts(receipts, CHARACTER, window)
		receipts.append("craft:%s:f32:%d" % [CHARACTER, i])
	var kept: Array = receipts.filter(func(r: Variant) -> bool: return str(r).begins_with("craft:%s:f32:" % CHARACTER))
	assert_eq(kept.size(), window, "bounded at the window")
	assert_eq(str(kept[0]), "craft:%s:f32:%d" % [CHARACTER, 5000 - window], "the oldest are the ones dropped")
	assert_eq(str(kept[-1]), "craft:%s:f32:4999" % CHARACTER)
	assert_true(receipts.has("care:other:1"), "other receipt kinds are never compacted")


func test_gathering_continues_past_4096_receipts_through_the_real_stage() -> void:
	var state := _character(4095)
	var revision := 0
	for i in 4:
		var result := _till(state, revision)
		assert_false(result.has("refused"), "gather %d past the old cap is not refused: %s" % [4096 + i, str(result)])
		if result.has("refused"): return
		state = result.state
		revision += 1
		assert_true(_f32_receipts(state) <= _window(), "receipts stay bounded (%d)" % _f32_receipts(state))
	assert_eq(_f32_receipts(state), _window(), "the newest window is kept")

extends "res://tests/test_case.gd"

## Pure canonical starter/seed and actual tools compilation coverage. No
## engine process, controller action, journal/receipt, save or ACK is claimed.
const DIAGNOSTIC := preload("res://tools/net/f48_diagnostic_steps.gd")
const ADAPTER := preload("res://tools/net/f48_diagnostic_via_render.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const WORLD := preload("res://autoload/world_state.gd")
const RECORDS := preload("res://scripts/net/character_record_rules.gd")
const PROOF := preload("res://tools/net/proof_steps_f48.gd")
const DEEP_WATCH := preload("res://tests/smoke_net_water_deep_watch_chart.gd")
const DEEP_WATCH_PEER := preload("res://tests/fixtures/water_deep_watch_peer.gd")
const FIRST_REALM := preload("res://tests/smoke_net_session_host_first_realm.gd")

func _starter() -> Dictionary:
	var player: RefCounted = PLAYER.new()
	player.call("configure",ITEMS.new())
	player.set("character_id","diagnostic-component-owner")
	player.get("party").call("add",SPECIES.spawn("terrapup"))
	return player.call("save_data")

func test_actual_tools_compile_and_unknown_prerequisite_refuses() -> void:
	var helper: Script = DIAGNOSTIC
	var adapter: Script = ADAPTER
	assert_eq(helper.resource_path,"res://tools/net/f48_diagnostic_steps.gd")
	assert_eq(adapter.resource_path,"res://tools/net/f48_diagnostic_via_render.gd")
	var deep_watch: Script = DEEP_WATCH
	var deep_watch_peer: Script = DEEP_WATCH_PEER
	var first_realm: Script = FIRST_REALM
	assert_eq(deep_watch.resource_path,"res://tests/smoke_net_water_deep_watch_chart.gd")
	assert_eq(deep_watch_peer.resource_path,"res://tests/fixtures/water_deep_watch_peer.gd")
	assert_eq(first_realm.resource_path,"res://tests/smoke_net_session_host_first_realm.gd")
	var before: Dictionary = _starter()
	assert_true(RECORDS.errors(RECORDS.portable_projection(before)).is_empty(),"Actual configured canonical starter")
	var unchanged: PackedByteArray = var_to_bytes(before)
	assert_true(DIAGNOSTIC._seed(before,"invented_checkpoint").is_empty())
	assert_eq(var_to_bytes(before),unchanged)
	assert_true(PROOF._json_equal(DIAGNOSTIC._seed(before,"none"),before))

func test_disclosed_seeds_preserve_original_identity_namespace_journal_and_receipts() -> void:
	var before: Dictionary = _starter()
	var world: RefCounted = WORLD.new()
	world.set("world_id","diagnostic-component-world")
	world.set("reward_delivery_namespace","diagnostic-component-namespace")
	var world_before: Dictionary = world.call("save_data")
	var protected: Dictionary = DIAGNOSTIC._protected(before,world_before)
	var original: PackedByteArray = var_to_bytes(before)
	for seed: String in ["feast_ready","key_ready","relic_ready","round_ready"]:
		var candidate: Dictionary = DIAGNOSTIC._seed(before,seed)
		assert_false(candidate.is_empty(),seed)
		if candidate.is_empty(): continue
		assert_true(RECORDS.errors(RECORDS.portable_projection(candidate)).is_empty(),seed+" remains canonical")
		var installed: RefCounted = PLAYER.new()
		installed.call("configure",ITEMS.new())
		installed.call("load_data",candidate)
		assert_true(PROOF._json_equal(installed.call("save_data"),candidate),seed+" actual owner codec full roundtrip")
		assert_true(PROOF._json_equal(DIAGNOSTIC._protected(candidate,world_before),protected),seed+" exact protected original source")
		assert_eq(var_to_bytes(before),original,seed+" never edits source")
		assert_true(PROOF._json_equal(world.call("save_data"),world_before),seed+" never edits world")
	var changed: Dictionary = before.duplicate(true)
	changed.party[0].uid = "foreign-owned-uid"
	assert_false(PROOF._json_equal(DIAGNOSTIC._protected(changed,world_before),protected))
	var changed_world: Dictionary = world_before.duplicate(true)
	changed_world.reward_delivery_namespace = "foreign-namespace"
	assert_false(PROOF._json_equal(DIAGNOSTIC._protected(before,changed_world),protected))
	changed_world = world_before.duplicate(true)
	changed_world.reward_deliveries = {"foreign":"not-an-accepted-row"}
	assert_false(PROOF._json_equal(DIAGNOSTIC._protected(before,changed_world),protected))
	changed = before.duplicate(true)
	changed.redesign_character.transaction_receipts.append("foreign-receipt")
	assert_false(PROOF._json_equal(DIAGNOSTIC._protected(changed,world_before),protected))

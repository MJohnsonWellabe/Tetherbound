extends "res://tests/test_case.gd"

## Pending engine queue. Policy fixtures do not prove earned placement/play.
const RULES := preload("res://scripts/build/forward_camp_rules.gd")
const HOST := preload("res://scripts/build/forward_camp_host.gd")
const ACTIONS := preload("res://scripts/build/forward_camp_actions.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")

func _row(realm: String = "meadows", owner: String = "owner") -> Dictionary:
	return {"id":"forward_camp","uid":"b1","realm":realm,"position":[0,0,0],"yaw_deg":0,
		"paid":true,"character_id":owner,"txn_id":"0123456789abcdef0123456789abcdef"}

func test_record_rejects_duplicate_removed_unpaid_and_bad_identity() -> void:
	var row := _row()
	assert_true(RULES.record([row],"b1").ok)
	assert_false(RULES.record([row,row],"b1").ok)
	for field: String in ["paid","character_id","txn_id","position"]:
		var broken := row.duplicate(true)
		broken.erase(field)
		assert_false(RULES.record([broken],"b1").ok,field)
	row.removed=true
	assert_false(RULES.record([row],"b1").ok)
	assert_false(RULES.record([_row()],"b01").ok)

func test_one_camp_per_stable_character_per_biome() -> void:
	var cfg := RULES.config()
	assert_true(cfg.get("runtime_enabled") is bool and cfg.runtime_enabled,"F34 enables canonical forward camps")
	for biome: String in RULES.LIVE:
		assert_true(RULES.placement(cfg,[],"owner",biome,Vector3.ZERO,0).ok)
		assert_eq(RULES.placement(cfg,[_row(biome)],"owner",biome,Vector3.ZERO,0).code,"camp_limit")
		assert_true(RULES.placement(cfg,[_row(biome)],"guest",biome,Vector3.ZERO,0).ok)
	assert_false(RULES.placement(cfg,[],"owner","biome5",Vector3.ZERO,0).ok)
	assert_false(RULES.placement(cfg,[],"owner","meadows",Vector3.INF,0).ok)

func test_disabled_forward_camp_refuses_placement_and_source_context() -> void:
	var cfg := RULES.config().duplicate(true)
	cfg.runtime_enabled = false
	assert_eq(RULES.placement(cfg,[],"owner","meadows",Vector3.ZERO,0).code,"camp_disabled")
	assert_true(RULES.source_context(cfg,[_row()],"b1",Vector3.ZERO,"meadows","owner",0,false,"bed").is_empty())
	assert_eq(RULES.placement({},[],"owner","meadows",Vector3.ZERO,0).code,"camp_disabled")

func test_saved_world_preflight_preserves_old_worlds_and_rejects_duplicate_slots() -> void:
	assert_true(RULES.saved_errors([]).is_empty())
	var row := _row()
	assert_true(RULES.saved_errors([row]).is_empty())
	var second := row.duplicate(true)
	second.uid="b2"
	assert_false(RULES.saved_errors([row,second]).is_empty())
	second.removed=true
	assert_true(RULES.saved_errors([row,second]).is_empty())
	second.paid=false
	assert_false(RULES.saved_errors([row,second]).is_empty())

func test_feasts_power_gear_and_refining_fail_even_on_allowlisted_id() -> void:
	assert_eq(RULES.recipe("ascension_meadows",{}).reason,"Needs the homestead — use the Kitchen.")
	assert_false(RULES.recipe("orb_basic",{"personal_gear_tier":1}).ok)
	assert_false(RULES.recipe("orb_basic",{"reinforce":{"tool":"axe","bonus":5}}).ok)
	assert_false(RULES.recipe("orb_basic",{"refine":{}}).ok)
	assert_true(RULES.recipe("orb_basic",{"output":{"id":"orb_basic","n":1}},"workbench").ok)
	assert_false(RULES.recipe("orb_basic",{"output":{"id":"orb_basic","n":1}},"cookpot").ok)
	assert_true(RULES.recipe("potion_small",{"output":{"id":"potion_small","n":1}},"cookpot").ok)

func test_source_context_is_realm_and_reach_bound() -> void:
	var cfg := RULES.config()
	cfg.runtime_enabled=true
	var near := RULES.source_context(cfg,[_row()],"b1",Vector3.ZERO,"meadows","guest",0,false,"bed")
	assert_true(near.in_range)
	assert_eq(near.station_kind,"forward_camp")
	assert_eq(near.camp_index,0)
	assert_true(RULES.source_context(cfg,[_row()],"b1",Vector3.ZERO,"tidewake","guest",0,false,"bed").is_empty())
	assert_false(RULES.source_context(cfg,[_row()],"b1",Vector3(50,0,0),"meadows","guest",0,false,"bed").in_range)

func test_commit_reconciles_original_before_removed_source_and_never_publishes_failed_save() -> void:
	var calls := {"stage":0,"publish":0}
	var replay := HOST.commit({},func(_i: Dictionary) -> Dictionary: return {"ok":true,"found":true,"durable":true},
		func(_i: Dictionary) -> Dictionary: calls.stage+=1; return {"ok":true},
		func(_s: Dictionary,_i: Dictionary) -> Dictionary: return {"ok":true,"durable":true},
		func(_s: Dictionary) -> Dictionary: calls.publish+=1; return {"ok":true})
	assert_true(replay.durable)
	assert_eq(calls.stage,0)
	var failed := HOST.commit({},func(_i: Dictionary) -> Dictionary: return {"ok":true,"found":false},
		func(_i: Dictionary) -> Dictionary: calls.stage+=1; return {"ok":true},
		func(_s: Dictionary,_i: Dictionary) -> Dictionary: return {"ok":false,"durable":false},
		func(_s: Dictionary) -> Dictionary: calls.publish+=1; return {"ok":true})
	assert_false(failed.ok)
	assert_eq(calls.publish,0)

func test_atomic_kit_place_pack_replay_and_stale_revision() -> void:
	var cfg := RULES.config()
	cfg.runtime_enabled=true
	var current := {"character_id":"owner","party":[],"redesign_character":STATE.defaults("character"),
		"inventory":[{"id":"forward_camp_kit","n":1}]}
	var before := current.duplicate(true)
	var context := {"character_id":"owner","expected_revision":0,"in_range":true,
		"in_combat":false,"host_ground_valid":true,"realm":"meadows"}
	var place := {"action":"place","action_id":"0123456789abcdef0123456789abcdef",
		"realm":"meadows","position":[0,0,0],"yaw_deg":0}
	var stage := ACTIONS._stage_build(cfg,current,0,[],1,place,context)
	assert_true(stage.ok)
	if not stage.ok: return
	assert_eq(current,before,"preflight never mutates admitted live state")
	assert_eq(stage.placed_buildings.size(),1)
	assert_eq(stage.record.character_id,"owner")
	assert_eq(stage.next_building_uid,2)
	assert_eq(ACTIONS.BAG.inventory_from(stage.state.inventory).call("count","forward_camp_kit"),0)
	assert_false(ACTIONS._stage_build(cfg,stage.state,0,stage.placed_buildings,2,place,context).ok,"same ID requires journal reconciliation")
	context.expected_revision=1
	assert_false(ACTIONS._stage_build(cfg,current,0,[],1,place,context).ok,"stale character revision")
	context.expected_revision=0
	context.camp_uid="b1"
	context.all_parties_awake=true
	var pack := {"action":"pack","action_id":"1123456789abcdef0123456789abcdef","uid":"b1"}
	var packed := ACTIONS._stage_build(cfg,stage.state,0,stage.placed_buildings,2,pack,context)
	assert_true(packed.ok)
	if not packed.ok: return
	assert_true(packed.placed_buildings[0].removed)
	assert_eq(ACTIONS.BAG.inventory_from(packed.state.inventory).call("count","forward_camp_kit"),1)
	context.all_parties_awake=false
	assert_false(ACTIONS._stage_build(cfg,stage.state,0,stage.placed_buildings,2,pack,context).ok)
	var guest: Dictionary = stage.state.duplicate(true)
	guest.character_id="guest"
	context.character_id="guest"
	context.all_parties_awake=true
	assert_eq(ACTIONS._stage_build(cfg,guest,0,stage.placed_buildings,2,pack,context).code,"camp_owner")

func test_real_recipe_book_splits_travel_tier_from_homestead_only() -> void:
	# F34#1 over the shipped recipe book (ItemDB): the field allowlist crafts at
	# the camp part its route names; every feast, Forge ingot, tool reinforcement
	# or bracing, and tier-gear recipe is refused naming the homestead station.
	var db: RefCounted = preload("res://autoload/item_db.gd").new()
	var allowed: Array = RULES.STATIONS.config().recipe_routes.field_allowed
	var crafted := 0
	var refused := 0
	for id: Variant in db.call("recipe_ids"):
		var canonical: Dictionary = db.call("recipe", str(id))
		var route := RULES.recipe(str(id), canonical)
		var home_only: bool = canonical.has("feast_id") or str(id).begins_with("feast_") \
			or str(id).ends_with("_ingot") or str(id) == "stormglass_plate" or canonical.has("reinforce") \
			or canonical.has("personal_gear_tier") or canonical.has("gear_id") or str(id).contains("bracing") \
			or str(id).ends_with("_harness") or str(id).contains("_harness_plus") or str(id).contains("_charm")
		if allowed.has(id) and not home_only:
			assert_true(route.get("ok") == true, "%s crafts at a forward camp" % str(id))
			if route.get("ok") == true:
				assert_true(route.part in ["cookpot", "workbench"], "%s names a camp part" % str(id))
				crafted += 1
		elif home_only:
			assert_false(route.get("ok") == true, "%s is homestead-only" % str(id))
			assert_true(str(route.get("reason", "")).begins_with("Needs the homestead — use the "),
				"%s says why: %s" % [str(id), str(route.get("reason", ""))])
			refused += 1
	assert_true(crafted >= 20, "travel-tier recipes craft at camp (%d)" % crafted)
	assert_true(refused >= 30, "ingots, reinforcement, bracing and gear are refused (%d)" % refused)

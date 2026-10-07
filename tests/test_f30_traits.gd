extends "res://tests/test_case.gd"

## Named whole-feature logic batch. Queued for ROOT on integrated source.
## No engine invocation by this lane. Required per-trait witnesses use actual
## combat/traversal dispatch, not a duplicate implementation of the formula.
const TRAITS := preload("res://scripts/creatures/traits.gd")
const COMBAT := preload("res://scripts/combat/trait_effects.gd")
const TRAVERSAL := preload("res://scripts/world/trait_traversal.gd")
const SPAWN := preload("res://scripts/creatures/trait_spawn_hooks.gd")

func _one(id: String) -> Dictionary:
	return {"traits_initialized":true,"rolled_traits":[id],"taught_traits":{},"trait_secondary":""}

func test_real_json_config_numeric_gates_and_strict_activation() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRAITS.CONFIG_PATH))
	assert_true(raw is Dictionary,"real trait JSON did not parse")
	if not raw is Dictionary: return
	var cfg: Dictionary = raw
	assert_true(TRAITS.configuration_errors(cfg).is_empty(),str(TRAITS.configuration_errors(cfg)))
	assert_true(TRAITS.runtime_enabled(cfg),"shipped F30 consumers are active")
	var disabled := cfg.duplicate(true)
	disabled.runtime_enabled = false
	assert_false(TRAITS.runtime_enabled(disabled))
	var enabled := cfg.duplicate(true)
	enabled.runtime_enabled = true
	assert_true(TRAITS.runtime_enabled(enabled))
	var authored := enabled.duplicate(true)
	authored.slot_breakthrough_tiers = [1,3,5]
	assert_true(TRAITS.configuration_errors(authored).is_empty())
	assert_true(TRAITS.runtime_enabled(authored))
	assert_eq(TRAITS.unlocked_slots({"breakthroughs":[1,2,3,4,5]},enabled),[1,2,3])
	assert_eq(TRAITS.unlocked_slots({"breakthroughs":[1.0,2.0,3.0,4.0,5.0]},enabled),[1,2,3])
	assert_true(TRAITS.unlocked_slots({"breakthroughs":[true,3,5]},enabled).is_empty())
	for invalid: Variant in [null,true,"1,3,5",[],[1,3],[1,3,5,7],[1,2,5],[5,3,1],[true,3,5],["1",3,5],[1,3.5,5],[1,NAN,5],[1,INF,5]]:
		var broken := enabled.duplicate(true)
		broken.slot_breakthrough_tiers = invalid
		assert_false(TRAITS.configuration_errors(broken).is_empty(),"malformed tiers accepted: %s" % str(invalid))
		assert_false(TRAITS.runtime_enabled(broken),"invalid config enabled runtime")
	for field: String in ["maximum_rolled","bond_reveal_nodes"]:
		var broken := enabled.duplicate(true)
		broken[field] = true
		assert_false(TRAITS.configuration_errors(broken).is_empty())
	for invalid: Variant in [null,0,1,0.0,1.0,"true",[],{}]:
		var broken := enabled.duplicate(true)
		broken.runtime_enabled = invalid
		assert_false(TRAITS.configuration_errors(broken).is_empty(),"nonboolean activation accepted")
		assert_false(TRAITS.runtime_enabled(broken))
	var missing := enabled.duplicate(true)
	missing.erase("runtime_enabled")
	assert_false(TRAITS.configuration_errors(missing).is_empty())
	assert_false(TRAITS.runtime_enabled(missing))
	# Pure rules remain available with valid runtime_enabled:false config.
	assert_almost_eq(TRAITS.apply_value(_one("gentle"),"healing",100.0,disabled),105.0)

func test_each_trait_applies_actual_consumer() -> void:
	var cfg := TRAITS.config()
	assert_true(TRAITS.configuration_errors(cfg).is_empty())
	for id: String in cfg.traits:
		var row: Dictionary = cfg.traits[id]
		var creature := _one(id)
		var actual := 100.0
		match str(row.effect):
			"quick_power": actual = COMBAT.damage(creature,"quick",100.0)
			"charged_power": actual = COMBAT.damage(creature,"charged",100.0)
			"ultimate_power": actual = COMBAT.damage(creature,"ultimate",100.0)
			"cooldown": actual = COMBAT.move_profile(creature,{"cooldown":100.0}).cooldown
			"burst_cost": actual = COMBAT.wind_cost(creature,"burst",100.0)
			"ride_speed": actual = TRAVERSAL.speed(creature,"ride",100.0)
			"swim_speed": actual = TRAVERSAL.speed(creature,"swim",100.0)
			"fly_speed": actual = TRAVERSAL.speed(creature,"fly",100.0)
			_: actual = COMBAT.stat(creature,row.effect,100.0)
		assert_true(is_equal_approx(actual,100.0*(1.0+float(row.magnitude))),"trait %s did not apply" % id)

func test_spawn_identity_distribution_and_bonus() -> void:
	var cfg := TRAITS.config()
	var profiles := [[false,false,false],[false,true,false],[false,false,true],[true,false,false],[true,true,true]]
	var totals: Array[float] = []
	var epics: Array[int] = []
	for flags: Array in profiles:
		var total := 0.0
		var epic := 0
		var counts: Dictionary = {}
		for i: int in 4096:
			var roll := TRAITS.roll_spawn("proof-world","spawn-%d" % i,1,flags[0],flags[1],flags[2],cfg)
			assert_true(roll == TRAITS.roll_spawn("proof-world","spawn-%d" % i,1,flags[0],flags[1],flags[2],cfg))
			assert_true(roll.rolled_traits.size() >= 0 and roll.rolled_traits.size() <= 3)
			assert_true(TRAITS.trait_state_errors(roll,cfg).is_empty())
			total += roll.rolled_traits.size()
			counts[roll.rolled_traits.size()] = true
			for id: String in roll.rolled_traits:
				if cfg.traits[id].rarity == "epic": epic += 1
		assert_true(counts.size() == 4)
		totals.append(total)
		epics.append(epic)
	assert_true(totals[1] > totals[0] and totals[2] > totals[0] and totals[3] > totals[1] and totals[4] > totals[3])
	assert_true(epics[1] > epics[0] and epics[2] > epics[0] and epics[3] > epics[1] and epics[4] > epics[3])

func test_slots_use_breakthroughs_and_persistence_identity() -> void:
	assert_true(TRAITS.unlocked_slots({"level":60,"breakthroughs":[]}).is_empty())
	assert_true(TRAITS.unlocked_slots({"breakthroughs":[1,2,3,4,5]}) == [1,2,3])
	var roll := TRAITS.roll_spawn("world-a","alpha-1",9,true,true,true)
	var restored: Dictionary = JSON.parse_string(JSON.stringify(roll))
	assert_true(TRAITS.trait_state_errors(restored).is_empty())
	var caught := SPAWN.prepare_catch({"world_namespace":"world-a","spawn_id":"alpha-1","spawn_generation":9},restored,{"cap_level":10,"breakthroughs":[]})
	assert_true(caught.rolled_traits == roll.rolled_traits)
	assert_true(SPAWN.prepare_catch({"world_namespace":"world-a","spawn_id":"alpha-1","spawn_generation":10},restored,{}).is_empty())
	assert_true(SPAWN.prepare_catch({"world_namespace":"world-b","spawn_id":"alpha-1","spawn_generation":9},restored,{}).is_empty())
	var fresh: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn("bramblebun")
	var identity := {"world_namespace":"world-a","spawn_id":"ordinary-1","spawn_generation":1,
		"alpha":false,"night":false,"weather":false}
	var packet := SPAWN.initialize_host_instance(fresh, identity)
	assert_false(packet.is_empty(), "actual fresh instance consumes the host-spawn helper")
	assert_eq(fresh.get("rolled_traits"), packet.get("rolled_traits"))
	assert_true(fresh.get("traits_initialized"))
	assert_almost_eq(float(fresh.call("hp_fraction")), 1.0, 0.00001, "fresh trait max-HP effects preserve a full-health spawn")
	var retained: Array = fresh.get("rolled_traits").duplicate()
	identity.spawn_generation = 2
	assert_true(SPAWN.initialize_host_instance(fresh, identity).is_empty(), "streaming/retry cannot reroll an initialized individual")
	assert_eq(fresh.get("rolled_traits"), retained)

func test_bond_secondary_and_iv_no_double_count() -> void:
	var creature := _one("sturdy")
	var bond_rules: Dictionary = preload("res://scripts/creatures/bond_milestones.gd").config()
	for milestone: Dictionary in bond_rules.milestones: creature[milestone.task] = milestone.target
	creature.trait_secondary = "sturdy"
	creature.iv_defence = 0.73
	assert_true(TRAITS.effective_ids(creature).size() == 1)
	assert_true(is_equal_approx(COMBAT.stat(creature,"defence",123.0),129.15))
	assert_true(creature.iv_defence == 0.73)
	creature.trait_secondary = "bold"
	assert_true(TRAITS.effective_ids(creature).size() == 2)
	creature.taught_traits = {"1":"sturdy"}
	assert_true(not TRAITS.trait_state_errors(creature).is_empty())
	var zero := {"traits_initialized":true,"rolled_traits":[],"taught_traits":{},"trait_primary":"bold"}
	assert_true(TRAITS.effective_ids(zero).is_empty())

func _record() -> Dictionary:
	return {"cap_level":60,"breakthroughs":[1,2,3,4,5],"evolution_choices":{},
		"rolled_traits":["bold","swift"],"taught_traits":{},"known_moves":[],
		"loadout":{"quick":"","charged":"","utility":"","ultimate":""},
		"mastery":{},"best":false,"traits_initialized":true,
		"captured_from":{"kind":"wild","world_namespace":"world","spawn_id":"wild-a","spawn_generation":1}}

func _admitted() -> Dictionary:
	var state := preload("res://scripts/data/redesign_state.gd").defaults("character")
	state.creatures = {"caught-a":_record(),"kept-b":_record()}
	var bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from([])
	bag.add("essence_ground",100)
	bag.add("trait_seed_hardy",2)
	return {"character_id":"owner-a","redesign_character":state,
		"inventory":preload("res://scripts/world/death_satchel_rules.gd").slots(bag),
		"party":[{"uid":"caught-a","species_id":"bramblebun","creature_type":"ground","secondary_type":"","level":10,
			"base_hp":95.0,"iv_hp":0.5,"boost_hp":0,"max_hp":100.0,"hp":50.0},
			{"uid":"kept-b","species_id":"mudsnout","creature_type":"ground","secondary_type":"","level":10}]}

func _request(action: String, trait_id: String = "hardy") -> Dictionary:
	return {"action_id":"action-a","action":action,"creature_uid":"caught-a",
		"trait_id":trait_id,"slot":1 if action == "teach" else -1,
		"payment_item":"essence_ground" if action == "teach" else "","expected_character_revision":0}

func test_release_uses_f27_same_uid_receipt_chosen_seed_once() -> void:
	var before := _admitted()
	var frozen := before.duplicate(true)
	var essence: GDScript = load("res://scripts/creatures/essence.gd")
	assert_true(essence != null,"ROOT must integrate F27 producer before this batch")
	if essence == null: return
	var result := TRAITS.stage_action(before,"owner-a",_request("release","bold"),0,essence.config())
	assert_true(result.get("ok") == true,str(result))
	if result.get("ok") != true: return
	assert_eq(before,frozen,"planning mutated admitted record")
	assert_eq(result.state.party.size(),1)
	assert_false(result.state.redesign_character.creatures.has("caught-a"))
	assert_eq(result.receipt,"release:caught-a")
	assert_eq(result.state.redesign_character.release_receipts,["release:caught-a"])
	assert_eq(result.state.redesign_character.transaction_receipts,["release:caught-a"])
	var bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(result.state.inventory)
	assert_eq(bag.count("trait_seed_bold"),1)
	assert_eq(bag.count("trait_seed_swift"),0)
	assert_false(TRAITS.stage_action(result.state,"owner-a",_request("release","swift"),1,essence.config()).get("ok",false))
	var foreign := _request("release","bold")
	assert_false(TRAITS.stage_action(before,"other-owner",foreign,0,essence.config()).get("ok",false))

func test_teach_debit_slots_overwrite_and_hardy_fraction_atomically() -> void:
	var before := _admitted()
	before.redesign_character.creatures["caught-a"].taught_traits = {"1":"gentle"}
	var essence: GDScript = load("res://scripts/creatures/essence.gd")
	assert_true(essence != null)
	if essence == null: return
	var frozen := before.duplicate(true)
	var result := TRAITS.stage_action(before,"owner-a",_request("teach"),0,essence.config())
	assert_true(result.get("ok") == true,str(result))
	if result.get("ok") != true: return
	assert_eq(before,frozen)
	var bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(result.state.inventory)
	assert_eq(bag.count("essence_ground"),90)
	assert_eq(bag.count("trait_seed_hardy"),1)
	assert_eq(result.state.redesign_character.creatures["caught-a"].taught_traits,{"1":"hardy"})
	var replaced: Dictionary = result.state.party[0].duplicate(true)
	replaced.merge(result.state.redesign_character.creatures["caught-a"],true)
	assert_false(TRAITS.effective_ids(replaced).has("gentle"),"overwritten trait remained active")
	assert_almost_eq(result.state.party[0].hp/result.state.party[0].max_hp,0.5)
	var duplicate := _request("teach")
	duplicate.action_id = "action-b"
	assert_false(TRAITS.stage_action(result.state,"owner-a",duplicate,0,essence.config()).get("ok",false))
	var locked := before.duplicate(true)
	locked.redesign_character.creatures["caught-a"].breakthroughs = []
	assert_false(TRAITS.stage_action(locked,"owner-a",_request("teach"),0,essence.config()).get("ok",false))
	var no_money := before.duplicate(true)
	var no_money_bag := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(no_money.inventory)
	no_money_bag.remove("essence_ground",100)
	no_money.inventory = preload("res://scripts/world/death_satchel_rules.gd").slots(no_money_bag)
	var untouched := no_money.duplicate(true)
	assert_false(TRAITS.stage_action(no_money,"owner-a",_request("teach"),0,essence.config()).get("ok",false))
	assert_eq(no_money,untouched,"refusal partially consumed seed or essence")

func test_missing_v28_fields_normalize_before_admission_without_reroll() -> void:
	var portable := _admitted()
	portable.party[0]["trait_primary"] = "calm"
	portable.redesign_character.creatures["caught-a"].erase("traits_initialized")
	portable.redesign_character.creatures["caught-a"].rolled_traits = []
	var result := TRAITS.normalize_admitted(portable)
	assert_eq(result.redesign_character.creatures["caught-a"].rolled_traits,["calm"])
	assert_false(portable.redesign_character.creatures["caught-a"].has("traits_initialized"))
	assert_eq(TRAITS.normalize_admitted(result),result)
	var malformed := portable.duplicate(true)
	malformed.redesign_character.creatures["caught-a"].rolled_traits = "forged"
	var unchanged := TRAITS.normalize_admitted(malformed)
	assert_false(TRAITS.trait_state_errors(unchanged.redesign_character.creatures["caught-a"]).is_empty())

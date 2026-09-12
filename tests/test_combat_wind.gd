extends "res://tests/test_case.gd"

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const HUD := preload("res://scripts/ui/combat_hud.gd")
const ENCOUNTER_HOST := preload("res://scripts/net/encounter_host.gd")
const ENCOUNTER_DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const WATER_ALPHA := preload("res://scripts/combat/water_alpha.gd")
const STORMWOOD_TRAINER := preload("res://scripts/combat/stormwood_hosted_trainer.gd")


func _manager_with(species_id: String = "terrapup") -> Array:
	var creature: RefCounted = SPECIES.spawn(species_id)
	creature.nourishment = 100.0
	var manager := MANAGER.new()
	var party: Array[RefCounted] = [creature]
	manager.set("_party", party)
	manager.set("_active_index", 0)
	manager.call("_initialize_wind")
	return [manager, creature]


func test_wind_tuning_has_every_ordered_cost_and_penalty() -> void:
	assert_true(HUD != null, "the Wind HUD script must parse with the resource contract")
	assert_true(ENCOUNTER_DIRECTOR != null and WATER_ALPHA != null and STORMWOOD_TRAINER != null,
		"every hosted combat transport must parse with the authority contract")
	var wind: Dictionary = MATH.config().get("wind", {})
	assert_true(float(wind.get("max", 0.0)) > 0.0)
	assert_true(float(wind.get("quick_cost", 0.0)) > 0.0)
	assert_true(float(wind.get("charged_cost", 0.0)) > float(wind.get("quick_cost", 0.0)))
	assert_true(float(wind.get("skill_cost", 0.0)) > float(wind.get("quick_cost", 0.0)))
	assert_true(float(wind.get("burst_cost", 0.0)) > 0.0)
	assert_almost_eq(float(wind.get("regen_delay", 0.0)), 0.6, 0.001)
	assert_almost_eq(float(wind.get("exhausted_windup_scale", 0.0)), 2.0, 0.001)
	assert_almost_eq(float(wind.get("exhausted_power_scale", 0.0)), 0.6, 0.001)


func test_species_profiles_are_safe_and_inverse() -> void:
	var normal := _manager_with("terrapup")
	var gale := _manager_with("galewisp")
	var moss := _manager_with("mosshell")
	assert_true(float(gale[0].wind_capacity_for(gale[1])) < float(normal[0].wind_capacity_for(normal[1])))
	assert_true(float(gale[0].wind_regen_for(gale[1])) > float(normal[0].wind_regen_for(normal[1])))
	assert_true(float(moss[0].wind_capacity_for(moss[1])) > float(normal[0].wind_capacity_for(normal[1])))
	assert_true(float(moss[0].wind_regen_for(moss[1])) < float(normal[0].wind_regen_for(normal[1])))
	for row in [normal, gale, moss]:
		row[0].free()


func test_satiety_fed_and_bond_change_capacity_and_regen() -> void:
	var row := _manager_with()
	var manager: Node = row[0]
	var creature: RefCounted = row[1]
	creature.nourishment = 0.0
	var hungry_cap := float(manager.wind_capacity_for(creature))
	creature.nourishment = 100.0
	var fed_cap := float(manager.wind_capacity_for(creature))
	var unbonded_regen := float(manager.wind_regen_for(creature))
	creature.battles_fought = 50
	assert_true(fed_cap > hungry_cap, "low satiety must reduce the usable cap")
	assert_true(float(manager.wind_capacity_for(creature)) > fed_cap, "a completed bond node adds cap")
	assert_true(float(manager.wind_regen_for(creature)) > unbonded_regen, "a completed bond node adds regen")
	manager.free()


func test_costs_spend_once_and_exhausted_attacks_still_start_slow_and_weak() -> void:
	var row := _manager_with()
	var manager: Node = row[0]
	var quick_cost := float(manager.wind_cost("quick"))
	var before := float(manager.wind_value())
	assert_true(bool(manager.consume_wind("quick")))
	assert_almost_eq(float(manager.wind_value()), before - quick_cost, 0.001)
	while float(manager.wind_value()) > 0.0:
		manager.consume_wind("burst")
	manager.call("_start_action", {"windup": 0.2, "power": 10.0}, "quick")
	var pending: Dictionary = manager.get("_pending_move")
	assert_eq(int(manager.get("_action")), MANAGER.Action.WINDUP, "exhaustion penalizes, never refuses")
	assert_true(bool(pending.get("wind_exhausted", false)))
	assert_almost_eq(float(pending.get("windup", 0.0)), 0.4, 0.001)
	assert_almost_eq(float(pending.get("power", 0.0)), 6.0, 0.001)
	manager.free()


func test_regen_waits_for_delay_and_pauses_during_commitment() -> void:
	var row := _manager_with()
	var manager: Node = row[0]
	while float(manager.wind_value()) > 0.0:
		manager.consume_wind("burst")
	manager.set("_action", MANAGER.Action.READY)
	manager.call("_tick_wind", 0.5)
	assert_almost_eq(float(manager.wind_value()), 0.0, 0.001)
	manager.call("_tick_wind", 0.2)
	assert_true(float(manager.wind_value()) > 0.0, "regen begins after 0.6 seconds without an attack")
	var recovered := float(manager.wind_value())
	manager.set("_action", MANAGER.Action.WINDUP)
	manager.call("_tick_wind", 1.0)
	assert_almost_eq(float(manager.wind_value()), recovered, 0.001)
	manager.set("_action", MANAGER.Action.RECOVERY)
	manager.call("_tick_wind", 1.0)
	assert_almost_eq(float(manager.wind_value()), recovered, 0.001)
	manager.free()


func test_stamina_shroom_truthfully_accelerates_wind_regen() -> void:
	var file := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	assert_true(file != null)
	if file == null:
		return
	var items: Dictionary = (JSON.parse_string(file.get_as_text()) as Dictionary).get("items", {})
	var shroom: Dictionary = items.get("stamina_mushroom", {})
	var buff: Dictionary = shroom.get("creature_buff", {})
	assert_eq(str(buff.get("stat", "")), "wind_regen")
	assert_true(float(buff.get("scale", 0.0)) > 1.0)
	assert_true(str(shroom.get("description", "")).contains("Wind"))
	var row := _manager_with()
	var manager: Node = row[0]
	var creature: RefCounted = row[1]
	var baseline := float(manager.wind_regen_for(creature))
	assert_true(creature.apply_buff(str(buff.id), str(buff.stat), float(buff.scale), float(buff.duration_s)))
	assert_almost_eq(float(manager.wind_regen_for(creature)), baseline * float(buff.scale), 0.001)
	manager.free()


func test_host_owns_wind_spend_quiet_timing_and_exhaustion() -> void:
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(2, "meadows", "wild", {
		"species_id": "bramblebun", "hp": 100.0, "hp_max": 100.0})
	var encounter_id := str(record.get("encounter_id", ""))
	var profile := {"max": 100.0, "regen_per_second": 10.0,
		# A peer-authored hint in a profile is deliberately irrelevant.
		"wind_exhausted": true}
	var preview: Dictionary = host.preview_wind(encounter_id, 2, profile, 35.0, 1000)
	assert_false(bool(preview.get("wind_exhausted", true)), "the full host pool overrules any peer hint")
	var spent: Dictionary = host.commit_wind(encounter_id, 2, 1, profile, 35.0,
		1000, 0.2, 0.6)
	assert_almost_eq(float(spent.get("wind", -1.0)), 65.0, 0.001)
	assert_almost_eq(float(host.preview_wind(encounter_id, 2, profile, 35.0, 1700).wind),
		65.0, 0.001, "wind cannot regenerate during recovery plus quiet delay")
	assert_almost_eq(float(host.preview_wind(encounter_id, 2, profile, 35.0, 2300).wind),
		70.0, 0.001, "the host clock regenerates only time after the eligibility edge")
	var exhausted: Dictionary = host.commit_wind(encounter_id, 2, 2, profile, 90.0,
		2300, 0.2, 0.6)
	assert_true(bool(exhausted.get("wind_exhausted", false)))
	assert_almost_eq(float(exhausted.get("wind", -1.0)), 0.0, 0.001)
	var observer_row: Dictionary = (host.record(encounter_id).participants as Dictionary)[2]
	assert_almost_eq(float(observer_row.get("wind", -1.0)), 0.0, 0.001,
		"the replicated participant row carries the absolute host pool")


func test_host_wind_commit_is_action_idempotent() -> void:
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(7, "meadows", "wild", {
		"species_id": "bramblebun", "hp": 100.0, "hp_max": 100.0})
	var encounter_id := str(record.encounter_id)
	var profile := {"max": 100.0, "regen_per_second": 18.0}
	host.commit_wind(encounter_id, 7, 4, profile, 12.0, 1000, 0.2, 0.6)
	var duplicate: Dictionary = host.commit_wind(encounter_id, 7, 4, profile,
		12.0, 1000, 0.2, 0.6)
	assert_true(bool(duplicate.get("wind_duplicate", false)))
	assert_almost_eq(float(duplicate.get("wind", -1.0)), 88.0, 0.001,
		"replaying an accepted action cannot double-drain")


func test_authoritative_absolute_wind_is_safe_to_apply_twice() -> void:
	var row := _manager_with()
	var manager: Node = row[0]
	manager.call("_sync_authoritative_wind", {"wind": 42.0, "wind_max": 110.0})
	manager.call("_sync_authoritative_wind", {"wind": 42.0, "wind_max": 110.0})
	assert_almost_eq(float(manager.wind_value()), 42.0, 0.001,
		"record plus verdict writes an absolute value instead of draining twice")
	var penalized: Dictionary = MANAGER.with_wind_exhaustion(
		{"windup": 0.25, "power": 20.0}, true)
	assert_almost_eq(float(penalized.windup), 0.5, 0.001)
	assert_almost_eq(float(penalized.power), 12.0, 0.001)
	manager.free()
